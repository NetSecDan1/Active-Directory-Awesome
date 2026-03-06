# Runbook: DNS Failure Triage for AD Environments
**Risk**: READ-ONLY (investigation) / LOW (fixes) | **Estimated Time**: 30-90 minutes
**Requires**: AD read access, access to DNS infrastructure | **Change Type**: Normal
**Version**: 1.0 | **Owner**: AD Engineering / Network / DNS Team

---

## Overview

This runbook covers DNS triage **from the AD perspective** — validating that clients and DCs can resolve the records AD depends on. It is DNS-provider agnostic (works whether your DNS is hosted on AD-integrated, BIND, Infoblox, BlueCat, NS1, or any other platform).

**AD depends on DNS for**: DC location, Kerberos KDC discovery, replication partner resolution, LDAP, Global Catalog, and site-aware authentication. A DNS gap cascades into authentication failures, replication breaks, and GPO failures.

**Note**: This runbook uses `nslookup`, `Resolve-DnsName`, and `Test-NetConnection` — not DNS server management tools. Work with your DNS team for any changes to DNS records or forwarder configuration.

---

## Decision Tree

```
START: AD symptom with suspected DNS root cause
    │
    ├─ Client can't find a DC to log in? ─────────────────────────► Phase 2: DC Locator SRV Records
    │
    ├─ Replication failing — DCs can't reach each other? ─────────► Phase 3: DC A Record Resolution
    │
    ├─ Cross-forest auth failing? ────────────────────────────────► Phase 4: Cross-Forest DNS
    │
    ├─ Site-aware DC location not working (wrong site DC)? ───────► Phase 5: Site SRV Records
    │
    └─ DCs can't reach external services (licensing, NTP, cloud)? ► Phase 6: External Resolution
```

---

## Phase 0 — Gather Information

Before running commands, collect:

- [ ] **Symptom**: What's failing? (Login, replication, app, all auth?)
- [ ] **Scope**: All users? Specific subnet? Specific DC? Specific site?
- [ ] **DNS servers in use**: What DNS server IPs are configured on affected machines?
- [ ] **DNS provider**: Who manages DNS records (Infoblox, BlueCat, BIND, AD-integrated, etc.)?
- [ ] **Recent changes**: New DC added? DC decommissioned? DHCP change? IP address change?

---

## Phase 1 — Baseline: Which DNS Server Is the Client Hitting?

```powershell
# ── What DNS server is this machine using? ────────────────────────────────
# Run on the affected client or DC
Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq 2 } |  # 2 = IPv4
    Format-Table InterfaceAlias, ServerAddresses -AutoSize

# Legacy equivalent (works on older OS):
ipconfig /all | Select-String -Pattern "DNS Servers"

# ── Flush DNS cache and re-test ───────────────────────────────────────────
# If you suspect stale cached DNS answers:
ipconfig /flushdns
Write-Host "DNS cache flushed"

# ── Test basic DNS connectivity to the configured DNS server ──────────────
$dnsServers = (Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq 2 }).ServerAddresses
foreach ($dns in $dnsServers) {
    $result = Test-NetConnection -ComputerName $dns -Port 53 -WarningAction SilentlyContinue
    Write-Host "DNS server $dns port 53: $(if ($result.TcpTestSucceeded) { 'REACHABLE' } else { 'BLOCKED/DOWN' })"
}
```

---

## Phase 2 — DC Locator SRV Records (Most Critical AD DNS Records)

SRV records are how AD clients find Domain Controllers. If these are missing or wrong, no one can log in.

```powershell
$domain = (Get-ADDomain).DNSRoot   # e.g., contoso.com

# ── Test AD-critical SRV records ──────────────────────────────────────────
$criticalRecords = @(
    @{Record="_ldap._tcp.$domain";              Desc="LDAP — all DCs"},
    @{Record="_kerberos._tcp.$domain";          Desc="Kerberos — all KDCs"},
    @{Record="_ldap._tcp.dc._msdcs.$domain";    Desc="LDAP — DCs (RFC 2782)"},
    @{Record="_kerberos._tcp.dc._msdcs.$domain";Desc="Kerberos — DCs (RFC 2782)"},
    @{Record="_ldap._tcp.pdc._msdcs.$domain";   Desc="LDAP — PDC Emulator"},
    @{Record="_ldap._tcp.gc._msdcs.$domain";    Desc="LDAP — Global Catalog"},
    @{Record="_gc._tcp.$domain";                Desc="Global Catalog"},
    @{Record="_kerberos._udp.$domain";          Desc="Kerberos UDP"}
)

foreach ($rec in $criticalRecords) {
    try {
        $result = Resolve-DnsName $rec.Record -Type SRV -ErrorAction Stop
        Write-Host "OK   $($rec.Record) [$($rec.Desc)] — $($result.Count) record(s)" -ForegroundColor Green
        $result | ForEach-Object {
            Write-Host "      → $($_.NameTarget):$($_.Port) [priority=$($_.Priority) weight=$($_.Weight)]"
        }
    } catch {
        Write-Host "FAIL $($rec.Record) [$($rec.Desc)] — NOT RESOLVING" -ForegroundColor Red
    }
}
```

```cmd
:: nslookup equivalent — use on older machines or when PowerShell module isn't available
nslookup -type=SRV _ldap._tcp.contoso.com
nslookup -type=SRV _kerberos._tcp.contoso.com
nslookup -type=SRV _ldap._tcp.dc._msdcs.contoso.com
nslookup -type=SRV _ldap._tcp.pdc._msdcs.contoso.com
nslookup -type=SRV _ldap._tcp.gc._msdcs.contoso.com
```

**What to look for in SRV results**:
| Field | Expected | Problem if... |
|-------|----------|---------------|
| NameTarget | FQDN of a DC (e.g., dc01.contoso.com) | Missing or wrong FQDN → DC not registered |
| Port | 389 (LDAP), 88 (Kerberos), 3268 (GC) | Wrong port → DC misconfigured |
| Priority | 0 (same site preferred) or higher | All same priority → site routing not working |
| Count | ≥ 1 record per record type | 0 records → DC not registered in DNS |

---

## Phase 3 — DC A Record Resolution

If a DC's A record is missing, wrong IP, or stale — replication fails, Kerberos ticket validation fails.

```powershell
# ── Verify each DC resolves to its correct IP ─────────────────────────────
Get-ADDomainController -Filter * | ForEach-Object {
    $dc = $_.HostName
    $expectedIP = $_.IPv4Address

    try {
        $resolved = Resolve-DnsName $dc -Type A -ErrorAction Stop
        $resolvedIPs = $resolved.IPAddress
        $match = $resolvedIPs -contains $expectedIP

        [PSCustomObject]@{
            DC         = $dc
            Site       = $_.Site
            Expected   = $expectedIP
            Resolved   = $resolvedIPs -join ", "
            Status     = if ($match) { "OK" } elseif ($resolvedIPs) { "IP MISMATCH" } else { "NO A RECORD" }
        }
    } catch {
        [PSCustomObject]@{ DC=$dc; Site=$_.Site; Expected=$expectedIP; Resolved="FAILED"; Status="RESOLUTION FAILED" }
    }
} | Format-Table -AutoSize

# ── Reverse DNS check — does the IP resolve back to the DC hostname? ───────
# Important for some Kerberos and replication scenarios
Get-ADDomainController -Filter * | ForEach-Object {
    $dc = $_.HostName
    $ip = $_.IPv4Address
    try {
        $reverse = Resolve-DnsName $ip -Type PTR -ErrorAction Stop
        [PSCustomObject]@{
            DC       = $dc
            IP       = $ip
            PTR      = $reverse.NameHost
            Match    = if ($reverse.NameHost -like "*$dc*") { "OK" } else { "MISMATCH" }
        }
    } catch {
        [PSCustomObject]@{ DC=$dc; IP=$ip; PTR="NONE"; Match="NO PTR RECORD" }
    }
} | Format-Table -AutoSize
```

```cmd
:: nslookup A record check
nslookup dc01.contoso.com
:: Should return the correct IP

:: Reverse PTR check
nslookup 10.0.0.5
:: Should return dc01.contoso.com
```

---

## Phase 4 — Cross-Forest DNS Resolution

For forest trusts and cross-forest authentication, each side must resolve the other's domain names.

```powershell
$remoteForestDomain = "fabrikam.com"   # Replace with remote forest

# ── Can we resolve the remote forest's DCs at all? ────────────────────────
Write-Host "Testing DNS resolution for remote forest: $remoteForestDomain"

# Basic A record for the remote domain
try {
    $result = Resolve-DnsName $remoteForestDomain -Type A -ErrorAction Stop
    Write-Host "OK   $remoteForestDomain resolves" -ForegroundColor Green
} catch {
    Write-Host "FAIL $remoteForestDomain does NOT resolve — conditional forwarder may be missing" -ForegroundColor Red
}

# SRV records for the remote forest
$remoteSRVs = @(
    "_ldap._tcp.dc._msdcs.$remoteForestDomain",
    "_kerberos._tcp.dc._msdcs.$remoteForestDomain"
)

foreach ($rec in $remoteSRVs) {
    try {
        $result = Resolve-DnsName $rec -Type SRV -ErrorAction Stop
        Write-Host "OK   $rec ($($result.Count) DCs found)" -ForegroundColor Green
    } catch {
        Write-Host "FAIL $rec — NOT RESOLVING (trust authentication will fail)" -ForegroundColor Red
    }
}
```

```cmd
:: nslookup for cross-forest — explicitly test via a specific DNS server
nslookup -type=SRV _ldap._tcp.dc._msdcs.fabrikam.com
nslookup fabrikam.com

:: If you need to test via a SPECIFIC DNS server (bypass default):
nslookup fabrikam.com 10.0.0.5
:: Where 10.0.0.5 is the DNS server to query
```

**If cross-forest DNS fails**: A conditional forwarder for the remote domain needs to be added to your DNS infrastructure, pointing to the remote forest's DNS servers. Work with your DNS team.

---

## Phase 5 — Site-Aware DC Location (Wrong DC Selected)

AD uses DNS to find site-specific DCs. If site SRV records are wrong, clients use distant DCs.

```powershell
$domain = (Get-ADDomain).DNSRoot
$siteName = (nltest /dsgetsite 2>&1 | Where-Object { $_ -notmatch "^The command" }) -replace ".*: ", ""
Write-Host "Current machine's AD site: $siteName"

# ── Check site-specific SRV records ───────────────────────────────────────
$siteSRVs = @(
    "_ldap._tcp.$siteName._sites.$domain",
    "_kerberos._tcp.$siteName._sites.$domain",
    "_ldap._tcp.$siteName._sites.dc._msdcs.$domain",
    "_gc._tcp.$siteName._sites.$domain"
)

foreach ($rec in $siteSRVs) {
    try {
        $result = Resolve-DnsName $rec -Type SRV -ErrorAction Stop
        Write-Host "OK   $rec — $($result.Count) record(s)" -ForegroundColor Green
    } catch {
        Write-Host "FAIL $rec — NOT FOUND (clients may use out-of-site DCs)" -ForegroundColor Yellow
    }
}

# ── Force DC locator to find a site-aware DC ──────────────────────────────
nltest /dsgetdc:(Get-ADDomain).DNSRoot /site:$siteName /force
# Should return a DC in your site
# If it falls back to a remote site DC — site SRV records are missing or the DC
# in that site isn't registering its site-specific records

# ── Trigger Netlogon to re-register SRV records on a specific DC ──────────
# (Run on the DC that should have the site records — LOW RISK)
# nltest /dsregdns
# net stop netlogon && net start netlogon
```

---

## Phase 6 — External DNS Resolution from DCs

DCs need to resolve external names for: Windows activation, NTP sync (time.windows.com), Azure AD Connect (if hybrid), and OCSP/CRL validation for certificates.

```powershell
# ── External DNS resolution from a DC ─────────────────────────────────────
$externalTargets = @(
    "microsoft.com",
    "login.microsoftonline.com",
    "time.windows.com",
    "crl.microsoft.com",
    "ocsp.msocsp.com"
)

foreach ($target in $externalTargets) {
    try {
        $result = Resolve-DnsName $target -Type A -ErrorAction Stop
        Write-Host "OK   $target → $($result[0].IPAddress)" -ForegroundColor Green
    } catch {
        Write-Host "FAIL $target — NOT RESOLVING" -ForegroundColor Red
    }
}

# ── Test DNS on a specific port / server ──────────────────────────────────
# Confirm the DNS server port is open and responding
$dnsServer = "10.0.0.5"   # Your DNS server IP
Test-NetConnection $dnsServer -Port 53
```

```cmd
:: nslookup with explicit server — useful for diagnosing forwarder issues
nslookup microsoft.com 10.0.0.5
:: If this works but nslookup microsoft.com fails → default DNS server not forwarding

nslookup time.windows.com
:: Should resolve — if not, NTP may fail for DCs
```

---

## Phase 7 — DCDiag DNS Tests

`dcdiag /test:dns` runs a comprehensive suite of DNS checks from a DC's perspective. It's the single best tool for AD DNS health.

```powershell
# ── Run dcdiag DNS test (READ-ONLY, run on any DC) ────────────────────────
dcdiag /test:dns /v
# /v = verbose — shows every test pass/fail

# Key tests dcdiag runs:
# - Basic connectivity: Can DC reach DNS servers?
# - Forwarders: Are forwarders configured and responding?
# - Delegations: Are AD zone delegations correct?
# - Dynamic registration: Did this DC successfully register its SRV/A records?
# - Record registration: Are all expected records in DNS?

# Run against a specific DC:
dcdiag /test:dns /v /s:dc01.contoso.com

# Run against ALL DCs (comprehensive, may take minutes):
dcdiag /test:dns /v /e
```

**Reading dcdiag DNS output**:
```
Starting test: DNS
   DNS Tests are running and not hung.
   Starting test: Forwarders ........... PASS (forwarders working)
   Starting test: Delegations .......... PASS
   Starting test: DynamicRegistration .. FAIL  ← This is a problem
       ERROR: Dynamic registration of DC record failed
```

Any FAIL line needs investigation. The test name tells you exactly which component failed.

---

## Quick Fix Reference (Work with DNS Team)

| Symptom | Cause | Resolution |
|---------|-------|-----------|
| SRV records missing for a DC | DC failed to register; DC re-joined recently | Restart Netlogon on that DC: `net stop netlogon && net start netlogon` |
| A record resolves to wrong IP | Stale or duplicate record in DNS | Ask DNS team to delete stale record; DC will re-register |
| Cross-forest SRV lookup fails | No conditional forwarder for remote forest | Ask DNS team to add conditional forwarder → remote forest DNS servers |
| Site SRV records missing | DC in that site not registering site records | Restart Netlogon on the site's DC |
| PTR record missing | No reverse zone or DC didn't register PTR | Ask DNS team to create PTR record |
| External names not resolving from DCs | Forwarder missing or blocked | Ask DNS team to verify forwarder chain to external DNS |

---

## Documentation

Record in Jira ticket:
- DNS servers tested: `[LIST]`
- SRV records status: `[ALL OK / MISSING: list]`
- A record mismatches: `[LIST]`
- dcdiag /test:dns result: `[PASS / FAIL — which tests]`
- Root cause: `[DESCRIPTION]`
- Action taken: `[Requested DNS team change / Restarted Netlogon / etc.]`
- Verification: `[Resolution tests after fix]`
