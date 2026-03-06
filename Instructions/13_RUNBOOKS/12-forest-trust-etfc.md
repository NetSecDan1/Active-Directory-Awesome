# Runbook: Forest Trust — End-to-End Functional Check (ETFC)
**Risk**: READ-ONLY | **Estimated Time**: 45-90 minutes
**Requires**: Enterprise Admin or Domain Admin in both forests | **Change Type**: N/A (checks only)
**Version**: 1.0 | **Owner**: AD Engineering / Identity Architecture

---

## Overview

This runbook validates a forest trust is **fully functional** end-to-end. Use it:
- After provisioning a new forest trust
- After a forest trust health alert
- Before/after major identity changes (Entra Connect, domain migration)
- As a scheduled quarterly ETFC

A forest trust failure is rarely a single point — it usually involves DNS name suffix routing, SID filtering, authentication policies, and Netlogon channel health all in combination.

---

## Trust Architecture Reference

```
Forest A (contoso.com)  ←══════════════════════════════════►  Forest B (fabrikam.com)
   DC: dc01.contoso.com                                          DC: dc01.fabrikam.com
         │                                                              │
   [Trust Object]                                              [Trust Object]
   [Trusted Domain Object]                                     [Trusted Domain Object]
   [Name Suffix Routing]                                       [Name Suffix Routing]
         │                                                              │
   PDC Emulator ←─── Secure Channel (Netlogon) ───────────► PDC Emulator
         │                                                              │
   DFS/SYSVOL                                                   DFS/SYSVOL
```

**What must work for cross-forest auth**:
1. DNS resolution for the other forest's domain suffix
2. Network connectivity (ports 88, 135, 389, 445, 464, 3268, 49152-65535)
3. Trust objects healthy on both sides
4. Name suffix routing configured correctly
5. Netlogon secure channel established
6. SID filtering not blocking required groups (if cross-forest group memberships used)

---

## Phase 0 — Gather Information

- [ ] **Local forest**: `[DNS name]` — Forest A
- [ ] **Remote forest**: `[DNS name]` — Forest B
- [ ] **Trust type**: Forest trust? External trust? Selective auth?
- [ ] **Trust direction**: Two-way? One-way (inbound/outbound)?
- [ ] **What's broken**: Authentication? Group policy? Application access?
- [ ] **Who is affected**: All users in Forest A trying to reach Forest B? Specific groups?

---

## Phase 1 — Trust Object Baseline

```powershell
# ── List all trusts in local forest ────────────────────────────────────────
Get-ADTrust -Filter * | Select-Object Name, Direction, TrustType,
    TrustAttributes, IntraForest, SelectiveAuthentication |
    Format-Table -AutoSize

# Attribute meanings:
# Direction: BiDirectional | Inbound | Outbound
# TrustType: Forest (forest trust) | External | Realm
# SelectiveAuthentication: if True, specific users must be explicitly granted auth rights

# ── Detailed view of a specific trust ─────────────────────────────────────
$remoteDomain = "fabrikam.com"   # Replace with remote forest domain name
Get-ADTrust -Filter { Name -eq $remoteDomain } | Format-List *

# ── Verify trust from both sides using nltest ──────────────────────────────
# Local side:
nltest /domain_trusts /all_trusts
# Look for: FOREST_TRANSITIVE, DIRECT_OUTBOUND, DIRECT_INBOUND, etc.

# Remote DC (run this from a DC in the remote forest):
# nltest /domain_trusts /all_trusts
```

---

## Phase 2 — Trust Health Verification (Secure Channel)

```powershell
$remoteDomain = "fabrikam.com"

# ── Test the trust (verifies Netlogon secure channel across trust) ─────────
# This is the definitive trust health check
nltest /sc_verify:$remoteDomain
# Expected output:
#   Flags: b0 HAS_IP  HAS_TIMESERV
#   Trusted DC Name \\dc01.fabrikam.com
#   Trusted DC Connection Status = 0  0x0 NERR_Success
# If you see NERR_NsNotFound or error codes — trust channel is down

# ── Check trust relationship using PowerShell ──────────────────────────────
netdom trust $remoteDomain /domain:(Get-ADDomain).DNSRoot /verify
# Returns: "The trust password for this trust with the specified domain is OK"

# ── Get trust details including last password change ──────────────────────
# Trust passwords are rotated every 30 days — if they fall out of sync, trust breaks
nltest /sc_query:$remoteDomain
# Look for: "Trusted DC Connection Status = 0 NERR_Success"

# ── Force trust password reset (WRITE — MEDIUM RISK, only if trust broken) ─
# netdom trust $remoteDomain /domain:(Get-ADDomain).DNSRoot /resetoneside
# Run on PDC Emulator of the trusting domain
# NOTE: Must run on both sides if fully broken
```

---

## Phase 3 — DNS Name Resolution Across Trust

For forest trusts to work, each forest's DNS servers must be able to resolve the other forest's names.

```powershell
$localDomain  = (Get-ADDomain).DNSRoot        # e.g., contoso.com
$remoteDomain = "fabrikam.com"                # Replace

# ── Test DNS resolution from local DC to remote forest ────────────────────
# Can we resolve the remote forest's DC SRV records?
nslookup -type=SRV _ldap._tcp.dc._msdcs.$remoteDomain
nslookup -type=SRV _kerberos._tcp.dc._msdcs.$remoteDomain

# Can we resolve the remote PDC specifically?
$remotePDC = nltest /dcname:$remoteDomain 2>&1 | Select-String "PDC" | ForEach-Object { $_ -replace ".*\\\\", "" }
nslookup $remotePDC

# PowerShell equivalent resolution tests
Resolve-DnsName "_ldap._tcp.dc._msdcs.$remoteDomain" -Type SRV -ErrorAction SilentlyContinue |
    Format-Table Name, NameTarget, Port, Priority, Weight

# ── Verify the Name Suffix Routing table ──────────────────────────────────
# Name Suffix Routing tells DC which trust to use for a given UPN/domain suffix
# If a suffix is disabled or not listed, authentication to that suffix will fail

# View in ADUC: right-click domain trust → Properties → Name Suffix Routing tab
# Via PowerShell:
$domainDN = (Get-ADDomain).DistinguishedName
$trustObj = Get-ADObject -Filter { ObjectClass -eq 'trustedDomain' -and Name -eq $remoteDomain } `
    -Properties * -SearchBase "CN=System,$domainDN"
$trustObj | Select-Object Name, msDS-TrustForestTrustInfo | Format-List

# View routing via netdom:
netdom trust $remoteDomain /domain:$localDomain /namesuffixes
# Look for: "ENABLED" next to each suffix you expect to route
```

---

## Phase 4 — Network Connectivity Check

Forest trust auth requires multiple ports. A firewall change can silently break things.

```powershell
$remoteDCIP = "10.10.10.5"   # Replace with a DC IP in the remote forest

# ── Test all required AD auth ports ───────────────────────────────────────
$requiredPorts = @(
    @{Port=53;  Name="DNS"},
    @{Port=88;  Name="Kerberos"},
    @{Port=135; Name="RPC Endpoint Mapper"},
    @{Port=389; Name="LDAP"},
    @{Port=445; Name="SMB/NetBIOS"},
    @{Port=464; Name="Kerberos Password Change"},
    @{Port=636; Name="LDAPS"},
    @{Port=3268; Name="Global Catalog"},
    @{Port=3269; Name="Global Catalog SSL"}
)

foreach ($p in $requiredPorts) {
    $result = Test-NetConnection -ComputerName $remoteDCIP -Port $p.Port -WarningAction SilentlyContinue
    [PSCustomObject]@{
        Port    = $p.Port
        Service = $p.Name
        Open    = if ($result.TcpTestSucceeded) { "OPEN" } else { "BLOCKED" }
        Latency = "$($result.PingReplyDetails.RoundtripTime)ms"
    }
} | Format-Table -AutoSize

# ── Note: Dynamic RPC ports (49152-65535) must also be open ───────────────
# Test a dynamic RPC connection:
portqry -n $remoteDCIP -e 135 -p TCP
# Or: Test-NetConnection $remoteDCIP -Port 49200  (spot check a dynamic port range)
```

---

## Phase 5 — Selective Authentication Check

If the trust uses Selective Authentication, users need explicit "Allowed to authenticate" permission on target resources.

```powershell
$remoteDomain = "fabrikam.com"

# ── Is selective auth enabled on this trust? ──────────────────────────────
$trust = Get-ADTrust -Filter { Name -eq $remoteDomain }
if ($trust.SelectiveAuthentication) {
    Write-Host "Selective Authentication is ENABLED" -ForegroundColor Yellow
    Write-Host "Users from $remoteDomain must have 'Allowed to Authenticate' on target computers" -ForegroundColor Yellow
} else {
    Write-Host "Selective Authentication is DISABLED — all forest users can authenticate" -ForegroundColor Green
}

# ── If selective auth enabled: verify the permission on a target server ────
$targetServer = "APPSERVER01"   # Replace with target resource server name
$targetServerADObj = Get-ADComputer $targetServer

# Check who has "Allowed to authenticate" on this computer object
$acl = (Get-ADComputer $targetServer -Properties nTSecurityDescriptor).nTSecurityDescriptor
$acl.Access | Where-Object {
    $_.ObjectType -eq [GUID]"68b1d179-0d15-4d4f-ab71-46152e79a7bc"  # Allowed-To-Authenticate
} | Format-Table IdentityReference, ActiveDirectoryRights, AccessControlType -AutoSize

# ── Grant selective auth permission (WRITE — MEDIUM RISK) ─────────────────
# In ADUC: Computer Object → Properties → Security → Advanced
# Or via PowerShell dsacls / Set-ACL — requires specific GUID for that extended right
```

---

## Phase 6 — SID Filtering Validation

SID filtering prevents cross-forest privilege escalation but can block legitimate group memberships.

```powershell
$remoteDomain = "fabrikam.com"

# ── Check if SID filtering is enabled (it should be for forest trusts) ────
nltest /domain_trusts /all_trusts | Select-String $remoteDomain
# Look for: FILTER_SIDS — means SID filtering is active (normal/expected for forest trusts)

# ── Check trust attributes for quarantine/SID filtering flags ─────────────
$trustAttr = (Get-ADTrust -Filter { Name -eq $remoteDomain }).TrustAttributes
Write-Host "Trust Attributes value: $trustAttr (0x$($trustAttr.ToString('X')))"
# Bit 0x4 = QUARANTINED_DOMAIN (SID filtering enforced — normal for external trusts)
# Bit 0x20 = FOREST_TRANSITIVE (forest trust)
# Bit 0x40 = CROSS_ORGANIZATION (selective authentication)

# ── If groups from remote forest aren't working in local resources ─────────
# Verify the cross-forest group is being evaluated correctly
# Option 1: Check if SID history is being filtered (blocks migrated accounts)
$user = "fabrikam\jdoe"    # Remote user
# On a local DC, check if the cross-forest SID resolves:
([System.Security.Principal.NTAccount]"$user").Translate([System.Security.Principal.SecurityIdentifier])

# ── Disable SID filtering (WRITE — HIGH RISK — security implication) ──────
# Only do this if SID history migration is required AND you accept the risk
# netdom trust $remoteDomain /domain:$localDomain /quarantine:No
# CAUTION: This allows remote admins to potentially escalate into local forest
```

---

## Phase 7 — Authentication Test (End-to-End Validation)

```powershell
$remoteForestDC = "dc01.fabrikam.com"
$testUser       = "fabrikam\testuser"

# ── Test 1: Can we reach the remote forest's KDC? ─────────────────────────
klist get krbtgt/$remoteForestDC
# Should return a cross-realm TGT referral ticket

# ── Test 2: Cross-forest LDAP query ───────────────────────────────────────
# From local DC, query remote DC's LDAP
$remoteLDAP = New-Object DirectoryServices.DirectoryEntry("LDAP://$remoteForestDC")
$searcher = New-Object DirectoryServices.DirectorySearcher($remoteLDAP)
$searcher.Filter = "(objectClass=domainDNS)"
try {
    $result = $searcher.FindOne()
    Write-Host "Cross-forest LDAP query: SUCCESS — $($result.Properties.name)" -ForegroundColor Green
} catch {
    Write-Host "Cross-forest LDAP query: FAILED — $($_.Exception.Message)" -ForegroundColor Red
}

# ── Test 3: nltest cross-forest DC locator ────────────────────────────────
nltest /dsgetdc:$remoteForestDC /kdc /force
# Should return: \\dc01.fabrikam.com with flags including KDC, DS, LDAP

# ── Test 4: Validate trust password is in sync ────────────────────────────
nltest /sc_verify:$remoteForestDC
```

---

## ETFC Checklist — Copy to Jira

```
□ Trust objects exist on both sides (nltest /domain_trusts)
□ Trust direction is correct (BiDirectional or per design)
□ Trust secure channel is healthy (nltest /sc_verify)
□ DNS resolution works for remote forest SRV records (nslookup _ldap._tcp.dc._msdcs)
□ Name suffix routing enabled for all required suffixes (netdom trust /namesuffixes)
□ All required ports open (88, 135, 389, 445, 464, 3268 + dynamic RPC)
□ Selective authentication status matches design intent
□ SID filtering status matches design intent
□ Cross-forest LDAP query succeeds
□ Cross-forest Kerberos TGT referral succeeds (klist get)
□ Test user can authenticate to cross-forest resource
□ Trust password last changed within 30 days
```

---

## Trust Troubleshooting Quick Reference

| Symptom | Root Cause | Fix | Risk |
|---------|-----------|-----|------|
| `nltest /sc_verify` fails | Trust password out of sync | `netdom trust /resetoneside` | MEDIUM |
| SRV records not resolving | DNS conditional forwarder missing | Add conditional forwarder for remote domain | LOW |
| "Access denied" to remote resource | Selective auth, user not granted | Add "Allowed to Authenticate" on target | LOW |
| Cross-forest groups not working | SID filtering blocking SID history | Review SID filtering policy | HIGH |
| Intermittent trust failures | Firewall blocking dynamic RPC | Open ports 49152-65535 | MEDIUM |
| UPN suffix not routing correctly | Name suffix routing disabled/missing | Enable suffix in trust routing table | LOW |

---

## Documentation

Record in Jira ticket:
- Trust surveyed: `[Local forest → Remote forest]`
- Trust type and direction: `[Forest / External, BiDirectional / etc.]`
- ETFC result: `[PASS / FAIL per check above]`
- Issues found: `[LIST]`
- Fixes applied: `[COMMANDS]`
- Verification: `[Final nltest /sc_verify output]`
