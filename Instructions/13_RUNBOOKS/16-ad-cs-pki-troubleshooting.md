# Runbook: Active Directory Certificate Services (AD CS) / PKI Troubleshooting
**Risk**: READ-ONLY (investigation) / MEDIUM-HIGH (CA changes) | **Estimated Time**: 45-120 minutes
**Requires**: Local Admin on CA server, AD read access | **Change Type**: Normal (most fixes)
**Version**: 1.0 | **Owner**: AD Engineering / PKI Team

---

## Phase 0 — Information Gathering

**Before proceeding, I need the following:**

- [ ] **Symptom**: Certificate enrollment failing? CA offline? Certificates not trusted? CRL unreachable? OCSP failing?
- [ ] **CA type**: Enterprise CA or Standalone CA? Root CA or Subordinate CA?
- [ ] **CA server hostname**: `[HOSTNAME]`
- [ ] **Affected clients**: Specific machines / users, or all? What OS?
- [ ] **Certificate template** (if enrollment failing): `[TEMPLATE NAME]`
- [ ] **Error message**: Exact text or event ID from the Certificate Services log or client
- [ ] **Recent changes**: New server, domain change, CA moved, template modified, CRL schedule changed?

Do not proceed with any phase until these are answered.

---

## Overview

AD CS failures split into five categories:
1. **CA service / database** — CA won't start, database corrupt
2. **Certificate enrollment** — clients can't request certs, template issues, permission denied
3. **Trust chain** — certs issued but not trusted, root CA not in trusted store
4. **CRL / OCSP** — revocation checking fails, CRL expired or unreachable
5. **Template misconfiguration** — wrong permissions, deprecated CSP, version mismatch

---

## Decision Tree

```
START: PKI/Certificate issue
    │
    ├─ CA service not running / won't start? ────────────────────► Phase 1: CA Service Health
    │
    ├─ Clients can't enroll (error during request)? ─────────────► Phase 2: Enrollment Failures
    │
    ├─ Certificate issued but not trusted? ──────────────────────► Phase 3: Trust Chain
    │
    ├─ "Revocation check failed" / CRL errors? ──────────────────► Phase 4: CRL and OCSP
    │
    ├─ Template issues (not visible, permission denied)? ────────► Phase 5: Certificate Templates
    │
    └─ Certificate expiry audit needed? ─────────────────────────► Phase 6: Expiry Audit
```

---

## Phase 1 — CA Service Health

```powershell
$caServer = "PKI-CA01"   # Replace with your CA server name

# ── Check CA service status ────────────────────────────────────────────────
Get-Service -ComputerName $caServer -Name CertSvc |
    Select-Object MachineName, Status, StartType | Format-Table -AutoSize

# ── Check CA service event log (most diagnostic info lives here) ──────────
Get-WinEvent -ComputerName $caServer -FilterHashtable @{
    LogName   = 'Application'
    Source    = 'Microsoft-Windows-CertificationAuthority'
    StartTime = (Get-Date).AddHours(-24)
    Level     = @(1, 2, 3)   # Critical, Error, Warning
} -ErrorAction SilentlyContinue | Format-Table TimeCreated, Id, LevelDisplayName, Message -AutoSize -Wrap

# ── Check CA database integrity ───────────────────────────────────────────
# Run on the CA server:
Invoke-Command -ComputerName $caServer -ScriptBlock {
    # Check CA database files exist
    $caDbPath = "C:\Windows\System32\CertLog"  # Default — may differ
    Get-ChildItem $caDbPath -ErrorAction SilentlyContinue | Format-Table Name, Length, LastWriteTime -AutoSize

    # Check CA configuration
    certutil -getconfig
    certutil -ping   # Tests if CA is responding
}

# ── Verify CA is reachable from a client ─────────────────────────────────
certutil -ping $caServer\CANAME   # Replace CANAME with the CA's CN
# Expected: "Server "<CANAME>" ICertRequest2 interface is alive (0ms)"
```

**Common CA service start failures**:
| Symptom | Cause | Fix |
|---------|-------|-----|
| Event 100: CA service failed to start | CA database corrupt or locked | Run `certutil -dbstatus`; restore from backup |
| Event 22: Certificate chain build failed | CA certificate expired or root CA cert missing | Renew CA cert; re-issue CA cert |
| HSM/KSP error at startup | Hardware Security Module offline | Check HSM device, driver, connectivity |
| CAPI2 errors | Cryptographic service provider issue | Check CAPI2 event log: Applications and Services Logs → Microsoft → Windows → CAPI2 |

---

## Phase 2 — Certificate Enrollment Failures

```powershell
$caServer   = "PKI-CA01"
$template   = "WorkstationAuth"  # Replace with failing template name

# ── Check CAPI2 log on the CLIENT machine (most enrollment errors appear here) ──
# On the client:
Get-WinEvent -FilterHashtable @{
    LogName   = 'Microsoft-Windows-CAPI2/Operational'
    StartTime = (Get-Date).AddHours(-2)
    Level     = @(2, 3)  # Error and Warning
} -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, Message |
    Format-Table -AutoSize -Wrap

# ── Verify the certificate template is published to the CA ───────────────
Invoke-Command -ComputerName $caServer -ScriptBlock {
    param($tmpl)
    certutil -catemplates | Select-String $tmpl
} -ArgumentList $template

# ── Check template permissions (who can enroll?) ─────────────────────────
# Get the template object from AD
$domainDN = (Get-ADDomain).DistinguishedName
$templateObj = Get-ADObject `
    -SearchBase "CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainDN" `
    -Filter { Name -eq $template } `
    -Properties * -ErrorAction SilentlyContinue

if ($templateObj) {
    Write-Host "Template found: $($templateObj.DistinguishedName)"
    $acl = Get-Acl "AD:\$($templateObj.DistinguishedName)"
    $acl.Access | Where-Object {
        $_.ActiveDirectoryRights -match "ExtendedRight" -or
        $_.ActiveDirectoryRights -match "GenericAll"
    } | Format-Table IdentityReference, ActiveDirectoryRights, AccessControlType -AutoSize
} else {
    Write-Host "Template '$template' NOT FOUND in AD Configuration partition" -ForegroundColor Red
}

# ── Check auto-enrollment GPO applies to the client ──────────────────────
# On the client:
gpresult /R | Select-String -Pattern "Certificate|autoenroll" -CaseSensitive:$false

# ── Common enrollment error codes ────────────────────────────────────────
# 0x80094011 = The permissions on the certificate template do not allow current user to enroll
# 0x80094800 = Template not published to CA
# 0x8009480f = CA is not operational
# 0x80070005 = Access denied (check DCOM/RPC permissions to CA)
# CERTSRV_E_TEMPLATE_DENIED = Template explicitly denies enrollment
```

---

## Phase 3 — Trust Chain Validation

```powershell
# ── Check if the Root CA is in the Trusted Root store ────────────────────
# On the affected client:
Get-ChildItem Cert:\LocalMachine\Root | Where-Object {
    $_.Subject -like "*Root CA*" -or $_.Subject -like "*PKI*"   # Adjust to your CA name
} | Select-Object Subject, Thumbprint, NotAfter | Format-Table -AutoSize

# ── Validate the full chain for a specific certificate ────────────────────
# Export a certificate from the affected machine, then:
# certutil -verify -urlfetch "C:\path\to\cert.cer"
# This tests the entire chain including CRL download

# ── Check if Root CA cert is in GPO-distributed store ────────────────────
# Computer Config → Windows Settings → Security Settings → Public Key Policies
# → Trusted Root Certification Authorities
# If the Root CA cert isn't in GPO, clients in new OUs may not trust it

# ── Check chain via PowerShell ────────────────────────────────────────────
$certThumbprint = "AABBCCDD..."  # Replace with the cert thumbprint to check
$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $certThumbprint }
if ($cert) {
    $chain = New-Object Security.Cryptography.X509Certificates.X509Chain
    $chain.Build($cert) | Out-Null
    Write-Host "Chain status: $($chain.ChainStatus.Status)"
    $chain.ChainElements | ForEach-Object {
        Write-Host "  $($_.Certificate.Subject) — $($_.ChainElementStatus.Status)"
    }
}
```

---

## Phase 4 — CRL and OCSP Health

A failed or expired CRL breaks all certificate validation domain-wide.

```powershell
$caServer = "PKI-CA01"

# ── Check CRL validity and next publish ───────────────────────────────────
Invoke-Command -ComputerName $caServer -ScriptBlock {
    # List current CRL status
    certutil -CRL
    # Or get from the CA database:
    certutil -view -out "ThisUpdate,NextPublish,NextUpdate" -restrict "RequestType=CRL"
}

# ── Test CRL distribution point reachability ──────────────────────────────
# Find the CDP URLs in a certificate or CA config:
# certutil -dump <cert.cer> | Select-String "CDP"
# Then test each URL:
$cdpUrl = "http://pki.domain.com/CRL/CANAME.crl"   # Replace with actual CDP URL
try {
    $response = Invoke-WebRequest $cdpUrl -UseBasicParsing -TimeoutSec 10
    Write-Host "CRL download: OK ($($response.StatusCode)) — size: $($response.Content.Length) bytes)"
} catch {
    Write-Host "CRL download FAILED: $_" -ForegroundColor Red
}

# ── Check if CRL is expired ───────────────────────────────────────────────
# Download and inspect the CRL:
# certutil -URL http://pki.domain.com/CRL/CANAME.crl
# certutil -dump CANAME.crl | Select-String "Next Update"

# ── OCSP status check ─────────────────────────────────────────────────────
# If using OCSP (Online Certificate Status Protocol):
# certutil -URL -urlfetch <cert.cer>   # Tests both CRL and OCSP

# ── Manually republish CRL (WRITE — LOW RISK — run on CA) ─────────────────
# certutil -crl
# Or via ADCS MMC: CA → Revoked Certificates → right-click → All Tasks → Publish
```

**CRL quick reference**:
| Symptom | Cause | Fix |
|---------|-------|-----|
| CRL expired | Scheduled task failed, CA offline during publish time | Republish CRL: `certutil -crl` on CA |
| CRL download fails (HTTP 404) | CDP URL wrong, IIS not serving CRL, file missing | Check IIS virtual directory and CRL file exists |
| OCSP timeout | OCSP responder offline or firewall blocking | Test OCSP URL; check OCSP responder service |
| `The revocation function was unable to check revocation because the revocation server was offline` | Client can't reach CDP/OCSP | Check network path; temporary: allow "no check" via Group Policy |

---

## Phase 5 — Certificate Template Issues

```powershell
$domainDN  = (Get-ADDomain).DistinguishedName
$template  = "WorkstationAuth"

# ── Full template audit ───────────────────────────────────────────────────
$templateObj = Get-ADObject `
    -SearchBase "CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,$domainDN" `
    -Filter { Name -eq $template } `
    -Properties * -ErrorAction SilentlyContinue

$templateObj | Select-Object Name,
    @{N='SchemaVersion'; E={ $_.'msPKI-Template-Schema-Version' }},
    @{N='MinorVersion';  E={ $_.'msPKI-Minor-Template-Version' }},
    @{N='EnrollFlags';   E={ $_.'msPKI-Enrollment-Flag' }},
    @{N='RaSignature';   E={ $_.'msPKI-RA-Signature' }} | Format-List

# ── Check for deprecated Cryptographic Service Providers ─────────────────
# Templates using "Microsoft Enhanced Cryptographic Provider v1.0" (CNG v1)
# on modern Windows should be upgraded to use CNG key storage providers
$templateObj | Select-Object @{N='pKIDefaultCSPs'; E={ $_.'pKIDefaultCSPs' }} | Format-List

# ── Common template problems ─────────────────────────────────────────────
# Schema version 1 templates → upgrade to v2 or v4 for SHA-256 support
# "Supply in request" Subject Name → requires CA Manager approval unless PKIEE_ENROLL_ONLINE_PER_DEVICE set
# "Signature required" without proper RA setup → enrollment always fails
# Template duplicated and not re-published → clients see old template

# ── Check all templates published to all Enterprise CAs ──────────────────
Get-ADObject `
    -SearchBase "CN=Enrollment Services,CN=Public Key Services,CN=Services,CN=Configuration,$domainDN" `
    -Filter { ObjectClass -eq 'pKIEnrollmentService' } `
    -Properties certificateTemplates | ForEach-Object {
    [PSCustomObject]@{
        CA        = $_.Name
        Templates = $_.certificateTemplates -join ", "
    }
} | Format-List
```

---

## Phase 6 — Certificate Expiry Audit

```powershell
# ── Find all certificates expiring within 60 days on this machine ─────────
Get-ChildItem Cert:\LocalMachine\ -Recurse | Where-Object {
    $_.NotAfter -lt (Get-Date).AddDays(60) -and $_.NotAfter -gt (Get-Date)
} | Select-Object Subject, Thumbprint, NotAfter, FriendlyName,
    @{N='DaysLeft'; E={ [math]::Round(($_.NotAfter - (Get-Date)).TotalDays) }} |
    Sort-Object DaysLeft | Format-Table -AutoSize

# ── Find expired certificates (should be removed) ─────────────────────────
Get-ChildItem Cert:\LocalMachine\ -Recurse | Where-Object {
    $_.NotAfter -lt (Get-Date)
} | Select-Object Subject, Thumbprint, NotAfter | Format-Table -AutoSize

# ── Audit CA-issued certificates expiring in 90 days (run on CA) ──────────
Invoke-Command -ComputerName $caServer -ScriptBlock {
    $90days = (Get-Date).AddDays(90).ToString("MM/dd/yyyy")
    certutil -view -out "RequesterName,CommonName,NotAfter,SerialNumber" `
        -restrict "NotAfter<=$90days,Disposition=20" `
        | Select-Object -First 50
    # Disposition=20 = issued (not revoked or expired)
}

# ── Check CA certificate expiry ───────────────────────────────────────────
Invoke-Command -ComputerName $caServer -ScriptBlock {
    certutil -CAInfo | Select-String "CA cert expiration|Valid thru"
}
```

---

## Fix Summary

| Issue | Severity | Fix | Risk |
|-------|----------|-----|------|
| CA service won't start | CRITICAL | Restore CA DB from backup; rebuild CA if needed | HIGH |
| CRL expired | HIGH | `certutil -crl` on CA server to republish | LOW |
| Template not published to CA | MEDIUM | Add template via CA MMC → Certificate Templates | LOW |
| Clients lack enroll permission | MEDIUM | Add security group to template ACL with `Read` + `Enroll` | LOW |
| Root CA not trusted by clients | MEDIUM | Add root CA cert to GPO → Trusted Root CAs | LOW |
| CRL CDP URL unreachable | MEDIUM | Fix IIS virtual directory or DNS for CDP URL | MEDIUM |
| CA certificate expiring | HIGH | Renew CA certificate before expiry | MEDIUM |

---

## Documentation

Record in Jira ticket:
- CA server: `[NAME]`
- Symptom category: `[Service / Enrollment / Trust / CRL / Template]`
- Error code/event: `[CODE or EVENT ID]`
- Root cause: `[DESCRIPTION]`
- Fix applied: `[COMMAND OR CHANGE]`
- Verification: `[certutil -ping / enrollment test result]`
