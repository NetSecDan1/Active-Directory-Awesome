# Runbook: Cross-Forest Authentication Troubleshooting
**Risk**: READ-ONLY (investigation) / LOW-MEDIUM (fixes) | **Estimated Time**: 45-120 minutes
**Requires**: Domain Admin in local forest, read access to remote forest | **Change Type**: Normal
**Version**: 1.0 | **Owner**: AD Engineering / Identity Architecture

---

## Overview

Cross-forest authentication failures are the most complex identity issues to diagnose because they involve **two forests, two DNS namespaces, multiple trust components, and often firewall rules** across org boundaries. A structured approach is essential — ad-hoc investigation wastes hours.

**Authentication flow for cross-forest access**:
```
1. Client in Forest A requests access to server in Forest B
2. Client → KDC in Forest A: "I need a ticket for server in Forest B"
3. KDC Forest A → returns a referral (cross-realm TGT) for Forest B
4. Client → KDC in Forest B: "I have a referral, give me a service ticket"
5. Forest B KDC validates referral and issues service ticket
6. Client → Server in Forest B: presents service ticket
7. Server validates ticket → access granted
```

Any of these 7 steps can fail. This runbook identifies which step is failing and why.

---

## Decision Tree

```
START: User from Forest A can't access resource in Forest B
    │
    ├─ User can't even get a TGT in their own forest? ──────────► Own forest auth problem (not trust)
    │
    ├─ klist shows TGT but NO cross-realm referral ticket? ──────► Phase 2: Trust Channel / DNS
    │
    ├─ Cross-realm referral exists but no service ticket? ───────► Phase 3: Remote KDC Issue
    │
    ├─ Service ticket exists but "Access Denied"? ───────────────► Phase 4: Authorization / Selective Auth
    │
    ├─ Selective authentication suspected? ──────────────────────► Phase 5: Selective Auth
    │
    ├─ Works for some users, not others? ────────────────────────► Phase 6: SID Filtering / Groups
    │
    └─ Token too large? (works on some resources, not others) ───► Phase 7: Token Bloat
```

---

## Phase 0 — Gather Information

Critical to gather BEFORE investigating:

- [ ] **Source user**: `[UPN: user@forest-a.com]` — which forest?
- [ ] **Target resource**: `[server.forest-b.com]` — which forest? App or file share?
- [ ] **Error message**: Exact text and event ID if available
- [ ] **Scope**: All users from Forest A failing, or specific user? All servers in Forest B or specific?
- [ ] **Regression**: Was this ever working? What changed?
- [ ] **Trust type**: Forest trust or external trust? Selective auth enabled?
- [ ] **User's logon location**: Logging in from a machine in Forest A? Forest B? DMZ?

---

## Phase 1 — Verify the User's Own Authentication Works

```powershell
# Run on the affected user's machine (or ask user to run)

# Step 1: Do they have a valid TGT in their own forest?
klist
# Look for: krbtgt/FOREST-A.COM ticket with valid expiry
# If NO TGT: local auth is broken — stop here, fix local auth first

# Step 2: Has a cross-realm referral been issued?
klist
# Look for: krbtgt/FOREST-B.COM@FOREST-A.COM
# This is the inter-realm ticket — issued by Forest A's KDC
# If missing: see Phase 2 (trust channel / DNS)

# Step 3: Is there a service ticket for the target server?
klist
# Look for: <servicetype>/targetserver.forest-b.com@FOREST-B.COM
# If referral exists but no service ticket: see Phase 3

# Purge and force re-authentication for clean test:
klist purge
# Re-attempt access, then run klist again to see what tickets are being issued
```

---

## Phase 2 — Trust Channel and DNS (No Cross-Realm Referral)

If the user has a TGT but Forest A's KDC isn't issuing a cross-realm referral, either the trust is down or DNS routing is broken.

```powershell
$localDomain  = (Get-ADDomain).DNSRoot
$remoteDomain = "forest-b.com"   # Replace with actual remote forest

# ── Test 1: Verify trust channel is up ────────────────────────────────────
nltest /sc_verify:$remoteDomain
# Expected: "The command completed successfully"
# If error: trust secure channel is down → run Runbook 12 (Forest Trust ETFC)

# ── Test 2: Verify DNS name suffix routing ────────────────────────────────
netdom trust $remoteDomain /domain:$localDomain /namesuffixes
# All suffixes that need to route cross-forest must show as ENABLED
# If a UPN suffix isn't listed: add it via GPMC → Domains and Trusts → Trust Properties

# ── Test 3: DNS resolution of the remote forest ───────────────────────────
nslookup -type=SRV _ldap._tcp.dc._msdcs.$remoteDomain
nslookup -type=SRV _kerberos._tcp.dc._msdcs.$remoteDomain
# Both must resolve to remote DCs
# If failing: DNS conditional forwarder is missing or incorrect

# ── Test 4: DC locator — can local DC find a remote KDC? ──────────────────
nltest /dsgetdc:$remoteDomain /kdc /force
# Expected: Returns a remote KDC with IP address and flags

# ── Fix: Add missing DNS conditional forwarder (WRITE — LOW RISK) ─────────
# On each DC acting as DNS server:
# Add-DnsServerConditionalForwarderZone -Name "forest-b.com" -MasterServers @("10.20.0.5","10.20.0.6")
# (Replace IPs with actual remote DNS server IPs)
```

---

## Phase 3 — Remote KDC Cannot Issue Service Ticket

Cross-realm referral exists, but Forest B's KDC won't issue a service ticket.

```powershell
$remoteForestDC = "dc01.forest-b.com"  # Replace
$targetSPN      = "HTTP/appserver.forest-b.com"  # Replace — the SPN for the target service

# ── Check remote KDC event logs for Event 4769 failures ───────────────────
# (Run on a DC in Forest B, or ask Forest B admin)
Get-WinEvent -ComputerName $remoteForestDC -FilterHashtable @{
    LogName   = 'Security'
    Id        = 4769
    StartTime = (Get-Date).AddHours(-2)
} -ErrorAction SilentlyContinue | ForEach-Object {
    [PSCustomObject]@{
        Time       = $_.TimeCreated
        Account    = $_.Properties[0].Value
        Service    = $_.Properties[2].Value
        ClientIP   = $_.Properties[6].Value
        ResultCode = $_.Properties[4].Value.ToString("X")
    }
} | Where-Object { $_.ResultCode -ne "0" } | Format-Table -AutoSize

# ── Common result codes at this stage ─────────────────────────────────────
# 0x7 = SPN not found — service not registered in Forest B's KDC
# 0xC = Encryption type mismatch between forests
# 0x12 = Account disabled (the computer account of the target server?)
# 0x32 = SPN registered to multiple accounts in Forest B

# ── Verify the target SPN exists in Forest B ──────────────────────────────
# Run in Forest B:
setspn -Q $targetSPN
# Expected: "Checking domain DC=forest-b,DC=com — Existing SPN found!"

# If no SPN: target server's account may not have the right SPN registered
# SPN is typically auto-registered by the Kerberos client service on the server
# Restart the server (if lab) or run: setspn -S <spn> <computeraccount>

# ── Encryption type compatibility across forests ───────────────────────────
# If Forest A uses AES only and Forest B allows RC4 (or vice versa):
# Check both domains' "Network security: Configure encryption types" GPO
# Both forests must have overlapping encryption type support
```

---

## Phase 4 — Service Ticket Exists But "Access Denied"

The Kerberos exchange succeeded. The failure is authorization, not authentication.

```powershell
$targetServer  = "appserver.forest-b.com"
$remoteForestDC = "dc01.forest-b.com"

# ── Check if it's truly authZ (event 4625 / 4648 on target server) ─────────
Get-WinEvent -ComputerName $targetServer -FilterHashtable @{
    LogName   = 'Security'
    Id        = @(4625, 4648)
    StartTime = (Get-Date).AddHours(-1)
} -ErrorAction SilentlyContinue | ForEach-Object {
    [PSCustomObject]@{
        Time       = $_.TimeCreated
        EventId    = $_.Id
        User       = $_.Properties[5].Value
        Domain     = $_.Properties[6].Value
        LogonType  = $_.Properties[10].Value
        FailureReason = $_.Properties[8].Value
    }
} | Format-Table -AutoSize

# ── Check if logon type is allowed (GPO may restrict cross-forest logon) ───
# Computer Configuration → Windows Settings → Security Settings → Local Policies
# → User Rights Assignment → "Allow log on locally" / "Access this computer from network"
# Cross-forest users may be excluded from these rights

# ── Check local share / NTFS permissions on target ────────────────────────
# The cross-forest user or their group must be in the ACL
# If using groups: the group must exist in Forest B (not Forest A), OR
# Forest B must accept Forest A's security principals in ACLs
```

---

## Phase 5 — Selective Authentication

When selective authentication is enabled, users must be explicitly granted access to each target computer.

```powershell
$remoteForestDomain = "forest-b.com"
$targetComputer     = "APPSERVER01"   # In Forest B

# ── Check if selective auth is enabled ────────────────────────────────────
# Check from Forest B (trust inbound side for B):
# Get-ADTrust -Filter { Name -eq "forest-a.com" } | Select-Object SelectiveAuthentication

# From Forest A (outbound):
$trust = Get-ADTrust -Filter { Name -eq $remoteForestDomain }
Write-Host "Selective Auth: $($trust.SelectiveAuthentication)"

# ── Verify the user has "Allowed to Authenticate" on the target computer ───
# Run on Forest B (requires access):
# This is an extended right on the COMPUTER object in Forest B's AD
# ADUC: Computer object → Properties → Security → Advanced
# Look for: cross-forest user or group with "Allowed to Authenticate" allow ACE
# If missing — user gets Access Denied even with valid tickets

# ── Check for the right via ADSI (in Forest B) ────────────────────────────
$computerDN = (Get-ADComputer $targetComputer -Server "dc01.forest-b.com").DistinguishedName
$acl = Get-Acl "AD:\$computerDN"
$acl.Access | Where-Object {
    $_.ObjectType -eq [System.Guid]"68b1d179-0d15-4d4f-ab71-46152e79a7bc"
} | Format-Table IdentityReference, AccessControlType

# ── Grant "Allowed to Authenticate" (WRITE — MEDIUM RISK) ─────────────────
# Must be done in Forest B by Forest B admin:
# dsacls "$computerDN" /G "forest-a\cross-forest-users:CA;Allowed to Authenticate"
```

---

## Phase 6 — SID Filtering Blocking Group Memberships

Forest trusts have SID filtering enabled by default. This blocks cross-forest accounts that use SID history from having their old SIDs honored.

```powershell
# ── Determine if SID filtering is preventing group resolution ─────────────
# Scenario: User from Forest A is in a group that grants access to Forest B resource
# SID filtering may strip the group SID if it has SID history attributes

# Check trust attributes for quarantine flag:
$trust = Get-ADTrust -Filter { Name -eq "forest-b.com" }
$quarantined = [bool]($trust.TrustAttributes -band 0x4)
Write-Host "SID filtering (quarantine): $quarantined"
# True = SID filtering is active = SID history won't cross the trust

# ── If cross-forest group membership is the design ────────────────────────
# Use "Universal" groups in each forest
# Forest B resource group should contain the Forest A universal group
# This is the supported design — group SIDs are honored, SID history is separate

# ── Check event 4675 on remote DC ─────────────────────────────────────────
# Event 4675 = SIDs were filtered — logged when cross-forest SID is stripped
Get-WinEvent -ComputerName "dc01.forest-b.com" -FilterHashtable @{
    LogName   = 'Security'
    Id        = 4675
    StartTime = (Get-Date).AddHours(-2)
} -ErrorAction SilentlyContinue | Format-Table TimeCreated, Message -AutoSize

# ── Verify cross-forest universal groups are resolving ────────────────────
# From a machine that has access to Forest B's DC:
Get-ADGroupMember "Forest-A-Users" -Server "dc01.forest-a.com" -Recursive |
    Where-Object { $_.objectClass -eq 'user' } | Select-Object Name, SamAccountName |
    Format-Table -AutoSize
```

---

## Phase 7 — Token Bloat (Cross-Forest)

Cross-forest users accumulate SIDs from both forests. This doubles the token size risk.

```powershell
$crossForestUser = "forest-a\jdoe"

# ── Estimate token size for a cross-forest user ────────────────────────────
# User has: their own domain's group SIDs + cross-forest group SIDs
# Rough estimate: count their group memberships in BOTH forests

# Forest A memberships:
$userA = Get-ADUser "jdoe" -Server "dc01.forest-a.com" -Properties TokenGroups
$forestAGroupCount = $userA.TokenGroups.Count

# Forest B memberships (if user is also in Forest B groups):
$userB = Get-ADUser "jdoe" -Server "dc01.forest-b.com" -Properties TokenGroups -ErrorAction SilentlyContinue
$forestBGroupCount = if ($userB) { $userB.TokenGroups.Count } else { 0 }

$totalGroups = $forestAGroupCount + $forestBGroupCount
$estimatedTokenSize = 1200 + ($totalGroups * 40)

Write-Host "Forest A groups: $forestAGroupCount"
Write-Host "Forest B groups: $forestBGroupCount"
Write-Host "Estimated token size: $estimatedTokenSize bytes"
if ($estimatedTokenSize -gt 48000) {
    Write-Host "WARNING: Token bloat risk — cross-forest access may fail on some resources" -ForegroundColor Red
}

# ── Fix: Increase MaxTokenSize on target servers via GPO ──────────────────
# HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters
# MaxTokenSize = 65535 (DWORD)
# Deploy via Computer GPO on Forest B resource servers
```

---

## End-to-End Cross-Forest Auth Validation Script

Run this summary script from the source forest client:

```powershell
param(
    [string]$TargetForest = "forest-b.com",
    [string]$TargetServer = "appserver.forest-b.com",
    [string]$TestSharePath = "\\appserver.forest-b.com\TestShare"
)

Write-Host "=== Cross-Forest Auth ETFC ===" -ForegroundColor Cyan

# Test 1: TGT present
$tgt = klist | Select-String "krbtgt"
Write-Host "TGT in own forest: $(if ($tgt) { 'OK' } else { 'MISSING' })"

# Test 2: DNS resolution
$srv = Resolve-DnsName "_ldap._tcp.dc._msdcs.$TargetForest" -Type SRV -ErrorAction SilentlyContinue
Write-Host "DNS resolution for $TargetForest`: $(if ($srv) { "OK ($($srv.Count) SRV records)" } else { 'FAILED' })"

# Test 3: Trust channel
$nltest = nltest /sc_verify:$TargetForest 2>&1
$trustOK = $nltest -match "NERR_Success"
Write-Host "Trust channel: $(if ($trustOK) { 'OK' } else { 'FAILED' })"

# Test 4: DC locator
$dcFound = nltest /dsgetdc:$TargetForest /kdc /force 2>&1
$dcOK = $dcFound -match "PDC"
Write-Host "Remote KDC locator: $(if ($dcOK) { 'OK' } else { 'FAILED' })"

# Test 5: Share access
$shareOK = Test-Path $TestSharePath -ErrorAction SilentlyContinue
Write-Host "Share access ($TestSharePath): $(if ($shareOK) { 'OK' } else { 'DENIED/FAILED' })"

# Test 6: Cross-realm ticket
$crossTicket = klist | Select-String "krbtgt/$TargetForest"
Write-Host "Cross-realm ticket: $(if ($crossTicket) { 'ISSUED' } else { 'NOT ISSUED' })"
```

---

## Documentation

Record in Jira ticket:
- Source user: `[UPN]` / Forest: `[NAME]`
- Target resource: `[FQDN]` / Forest: `[NAME]`
- Failure point in flow (step 1-7): `[STEP]`
- Root cause: `[DESCRIPTION]`
- Ticket state before fix: `[klist output summary]`
- Fix applied: `[CHANGE]`
- Verification: `[Share/app accessible after fix]`
