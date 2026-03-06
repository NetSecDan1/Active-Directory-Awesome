# Runbook: Kerberos Authentication Failure Triage
**Risk**: READ-ONLY (investigation) / LOW-MEDIUM (fixes) | **Estimated Time**: 45-90 minutes
**Requires**: AD read access, Event log access | **Change Type**: Normal
**Version**: 1.0 | **Owner**: AD Engineering

---

## Overview

Kerberos failures manifest as: login failures, "Access Denied" on servers, applications breaking after password changes, delegation failures, or service outages. Most Kerberos failures fall into five root causes: **clock skew**, **SPN issues**, **delegation misconfiguration**, **encryption type mismatch**, or **ticket/token bloat**.

**Never guess** — Kerberos error codes are precise. Match the error code, follow the procedure.

---

## Error Code Quick Reference

| Error Code | Name | Most Common Cause |
|------------|------|------------------|
| `0xC000006D` | STATUS_LOGON_FAILURE | Wrong password or disabled account |
| `0xC0000064` | STATUS_NO_SUCH_USER | Account doesn't exist in that domain |
| `0xC000006A` | STATUS_WRONG_PASSWORD | Correct user, wrong password |
| `0xC0000234` | STATUS_ACCOUNT_LOCKED_OUT | Account locked — see lockout runbook |
| `0xC000015B` | STATUS_LOGON_TYPE_NOT_GRANTED | GPO denying logon type |
| `0x6` | KDC_ERR_C_PRINCIPAL_UNKNOWN | User not found in Kerberos realm |
| `0x7` | KDC_ERR_S_PRINCIPAL_UNKNOWN | **SPN not found** — most common |
| `0xC` | KDC_ERR_ETYPE_NOTSUPP | Encryption type mismatch (RC4 vs AES) |
| `0x12` | KDC_ERR_CLIENT_REVOKED | Account disabled or expired |
| `0x17` | KDC_ERR_KEY_EXPIRED | Password expired |
| `0x18` | KDC_ERR_PREAUTH_FAILED | Bad password at pre-auth |
| `0x1F` | KRB_AP_ERR_SKEW | **Clock skew > 5 minutes** |
| `0x22` | KDC_ERR_TGT_REVOKED | Logoff or KRBTGT reset invalidated ticket |
| `0x32` | KDC_ERR_BADMATCH | No matching account for SPN |

---

## Decision Tree

```
START: Kerberos/auth failure reported
    │
    ├─ Error 0x1F (SKEW)? ───────────────────────────► Phase 2: Clock Skew
    │
    ├─ Error 0x7 (S_PRINCIPAL_UNKNOWN)? ─────────────► Phase 3: SPN Audit
    │
    ├─ Error 0x32 (BADMATCH) or SPN conflict? ───────► Phase 3: Duplicate SPN
    │
    ├─ Error 0xC (ETYPE_NOTSUPP)? ───────────────────► Phase 4: Encryption Types
    │
    ├─ Delegation failures ("double-hop" broken)? ───► Phase 5: Delegation
    │
    ├─ Intermittent failures after password change? ─► Phase 6: Service Ticket Refresh
    │
    └─ Token too large / access denied on some apps? ─► Phase 7: Token Bloat
```

---

## Phase 0 — Gather Information

- [ ] **Error code** from event log or application error message
- [ ] **Affected user(s)**: Specific account or all users?
- [ ] **Affected resource**: Specific server, app, share, or all?
- [ ] **Client OS**: Windows version
- [ ] **Authentication path**: Direct to server? Through a web app? Through delegation?
- [ ] **Recent changes**: Password change? SPN add? Account move? New server?

---

## Phase 1 — Baseline: Confirm Authentication Is Kerberos and Failing

```powershell
# ── Check current Kerberos tickets on client machine ──────────────────────
klist               # Show current Kerberos TGT and service tickets
klist tgt           # TGT only — check expiry and KDC
klist purge         # Clear ticket cache (forces re-auth — useful during testing)

# ── Check recent Kerberos failures on the KDC (PDC Emulator) ──────────────
$PDC = (Get-ADDomain).PDCEmulator

# Event 4771 = Kerberos pre-authentication failure (at the KDC)
# Event 4768 = Kerberos TGT request (success or failure)
# Event 4769 = Kerberos service ticket request (success or failure)

Get-WinEvent -ComputerName $PDC -FilterHashtable @{
    LogName   = 'Security'
    Id        = @(4768, 4769, 4771)
    StartTime = (Get-Date).AddHours(-2)
} -ErrorAction SilentlyContinue | ForEach-Object {
    [PSCustomObject]@{
        Time        = $_.TimeCreated
        EventId     = $_.Id
        Account     = $_.Properties[0].Value
        ServiceName = if ($_.Id -eq 4769) { $_.Properties[2].Value } else { "N/A" }
        ClientIP    = $_.Properties[6].Value
        ResultCode  = $_.Properties[4].Value.ToString("X")
        FailReason  = switch ($_.Properties[4].Value) {
            0x7  { "SPN_NOT_FOUND" }
            0xC  { "ETYPE_MISMATCH" }
            0x1F { "CLOCK_SKEW" }
            0x12 { "ACCT_DISABLED" }
            0x18 { "BAD_PASSWORD" }
            0x32 { "SPN_CONFLICT" }
            default { $_.Properties[4].Value.ToString("X") }
        }
    }
} | Where-Object { $_.ResultCode -ne "0" } | Sort-Object Time -Descending |
    Select-Object -First 30 | Format-Table -AutoSize
```

---

## Phase 2 — Clock Skew (Error 0x1F: KRB_AP_ERR_SKEW)

Kerberos requires all participants within 5 minutes of each other. This is non-negotiable.

```powershell
# ── Check time on all DCs relative to authoritative source ────────────────
$refDC = (Get-ADDomain).PDCEmulator
$refTime = (Get-Date -ComputerName $refDC)

Get-ADDomainController -Filter * | ForEach-Object {
    $dc = $_.HostName
    try {
        $dcTime = Invoke-Command -ComputerName $dc -ScriptBlock { Get-Date } -ErrorAction Stop
        $skew = [math]::Abs(($dcTime - $refTime).TotalSeconds)
        [PSCustomObject]@{
            DC      = $dc
            DCTime  = $dcTime.ToString("yyyy-MM-dd HH:mm:ss")
            RefTime = $refTime.ToString("yyyy-MM-dd HH:mm:ss")
            SkewSec = [math]::Round($skew, 1)
            Status  = if ($skew -lt 30) { "OK" } elseif ($skew -lt 300) { "WARNING" } else { "CRITICAL" }
        }
    } catch {
        [PSCustomObject]@{ DC = $dc; Status = "UNREACHABLE" }
    }
} | Format-Table -AutoSize

# ── Check W32TM configuration on PDC Emulator ──────────────────────────────
# PDC Emulator should sync from an external NTP source
Invoke-Command -ComputerName $refDC -ScriptBlock {
    w32tm /query /source        # What is it syncing from?
    w32tm /query /status        # Sync status and stratum
    w32tm /query /configuration # Full config
}

# ── Fix: Resync time on a specific machine (LOW RISK) ─────────────────────
# Run on the machine with clock skew:
# w32tm /resync /force
# If it's a client/member server, ensure it's pointed at a DC:
# w32tm /config /manualpeerlist:"dc01.domain.com" /syncfromflags:manual /reliable:no /update
# net stop w32tm && net start w32tm
```

---

## Phase 3 — SPN Issues (Errors 0x7, 0x32)

Error 0x7 = SPN not registered. Error 0x32 = SPN registered on wrong/multiple accounts.

```powershell
# ── Find an SPN — determine what account owns it ──────────────────────────
$spnToFind = "HTTP/webserver.domain.com"   # Replace with actual SPN from error
Get-ADObject -Filter { ServicePrincipalName -like "*webserver*" } -Properties ServicePrincipalName |
    Select-Object Name, DistinguishedName, ServicePrincipalName | Format-List

# ── Detect ALL duplicate SPNs in the domain (the most dangerous state) ────
setspn -X -F
# Output lists any SPN registered on more than one account — THESE MUST BE FIXED

# ── Audit all SPNs for a specific service account ────────────────────────
$accountName = "svc-webapp"   # Replace with actual service account
setspn -L $accountName

# ── Full SPN audit — all service accounts ─────────────────────────────────
Get-ADUser -Filter { ServicePrincipalName -like "*" } -Properties ServicePrincipalName |
    ForEach-Object {
        $user = $_
        foreach ($spn in $user.ServicePrincipalName) {
            [PSCustomObject]@{
                Account = $user.SamAccountName
                SPN     = $spn
                Enabled = $user.Enabled
            }
        }
    } | Format-Table -AutoSize

# ── Fix: Register a missing SPN (WRITE OPERATION — LOW RISK) ──────────────
# Verify no other account has this SPN first (run setspn -X above)
# setspn -S "HTTP/webserver.domain.com" "domain\svc-webapp"
# setspn -S "HTTP/webserver" "domain\svc-webapp"
# Both short name and FQDN typically needed

# ── Fix: Remove a duplicate SPN (WRITE OPERATION — MEDIUM RISK) ───────────
# Confirm which account should own the SPN, then remove from the wrong account:
# setspn -D "HTTP/webserver.domain.com" "domain\wrongaccount"
```

---

## Phase 4 — Encryption Type Mismatch (Error 0xC: KDC_ERR_ETYPE_NOTSUPP)

```powershell
# ── Check supported encryption types for a user account ──────────────────
$accountName = "svc-webapp"
Get-ADUser $accountName -Properties msDS-SupportedEncryptionTypes |
    Select-Object SamAccountName,
    @{N='EncryptionTypes'; E={
        $val = $_.'msDS-SupportedEncryptionTypes'
        $types = @()
        if ($val -band 0x4)  { $types += "RC4-HMAC" }
        if ($val -band 0x8)  { $types += "AES128" }
        if ($val -band 0x10) { $types += "AES256" }
        if ($val -eq 0)      { $types += "Not set (uses domain default)" }
        $types -join ", "
    }} | Format-List

# ── Check domain-wide supported encryption types ──────────────────────────
# Look at Default Domain Policy or Fine-Grained PSOs
# RSOP or Group Policy: Computer Config → Windows Settings → Security Settings
#   → Account Policies → Kerberos Policy → Supported encryption types

# ── Find accounts with RC4-only restriction (causes AES failures) ─────────
Get-ADUser -Filter { msDS-SupportedEncryptionTypes -eq 4 } -Properties msDS-SupportedEncryptionTypes |
    Select-Object SamAccountName, DistinguishedName | Format-Table -AutoSize

# ── Fix: Set encryption types (WRITE OPERATION — MEDIUM RISK) ─────────────
# Enable AES128 + AES256 + RC4 for compatibility:
# Set-ADUser $accountName -Replace @{'msDS-SupportedEncryptionTypes' = 28}
# 28 = 0x4 (RC4) + 0x8 (AES128) + 0x10 (AES256)
# After change: reset the account password so new key material is generated
```

---

## Phase 5 — Kerberos Delegation Failures (Double-Hop)

When a middle-tier server needs to access a back-end on behalf of a user.

```powershell
# ── Check delegation configuration for a service account ─────────────────
$svcAccount = "svc-webapp"
Get-ADUser $svcAccount -Properties TrustedForDelegation,
    TrustedToAuthForDelegation, msDS-AllowedToDelegateTo |
    Select-Object SamAccountName,
    @{N='DelegationType'; E={
        if ($_.TrustedForDelegation) { "Unconstrained (RISKY)" }
        elseif ($_.TrustedToAuthForDelegation) { "Protocol Transition (S4U2Self+S4U2Proxy)" }
        elseif ($_.'msDS-AllowedToDelegateTo') { "Constrained (KCD)" }
        else { "None" }
    }},
    @{N='DelegateTo'; E={ $_.'msDS-AllowedToDelegateTo' -join "`n" }} | Format-List

# ── Find ALL accounts with unconstrained delegation (security audit) ───────
Get-ADUser -Filter { TrustedForDelegation -eq $true } -Properties TrustedForDelegation |
    Select-Object SamAccountName, DistinguishedName | Format-Table -AutoSize
Get-ADComputer -Filter { TrustedForDelegation -eq $true } -Properties TrustedForDelegation |
    Select-Object Name, DistinguishedName | Format-Table -AutoSize

# ── Verify the SPN that KCD is delegating TO is correctly registered ───────
$svcAccount = "svc-webapp"
$delegateTo = (Get-ADUser $svcAccount -Properties msDS-AllowedToDelegateTo).'msDS-AllowedToDelegateTo'
foreach ($spn in $delegateTo) {
    $found = Get-ADObject -Filter { ServicePrincipalName -eq $spn } -Properties ServicePrincipalName
    if ($found) {
        Write-Host "OK  $spn -> $($found.Name)" -ForegroundColor Green
    } else {
        Write-Host "FAIL $spn NOT FOUND in directory" -ForegroundColor Red
    }
}
```

---

## Phase 6 — Service Ticket Staleness (Post-Password-Change Failures)

Service tickets survive password changes for their lifetime (default 10 hours). After a service account password changes, clients hold valid tickets that then fail at the server.

```powershell
# ── Check Kerberos policy (ticket lifetime) ────────────────────────────────
$policy = Get-ADDefaultDomainPasswordPolicy
Write-Host "Max Ticket Age:       $($policy.MaxTicketAge)"
Write-Host "Max Service Ticket:   $($policy.MaxServiceTicketAge)"
Write-Host "Max Renewal Age:      $($policy.MaxRenewableTicketAge)"
Write-Host "Max Clock Skew:       $($policy.MaxClockSkew)"

# ── Purge stale tickets on client (run on affected machine) ───────────────
# klist purge              # Clear all cached tickets — user/service must re-auth
# Restart-Service <ServiceName>  # Services need restart to pick up new tickets

# ── For IIS app pools or services: force re-authentication ────────────────
# Invoke-Command -ComputerName $serverName -ScriptBlock {
#     klist -li 0x3e7 purge   # Purge machine account tickets
#     gpupdate /force
# }
```

---

## Phase 7 — Token Size / Kerberos Bloat (MaxTokenSize)

Users with many group memberships can exceed the Kerberos token size limit, causing random access failures.

```powershell
# ── Calculate token size for a user ────────────────────────────────────────
function Get-TokenSize {
    param([string]$Username)

    $user = Get-ADUser $Username -Properties MemberOf, TokenGroups
    $groupCount = $user.TokenGroups.Count

    # Rough calculation: SID header (1200 bytes) + 40 bytes per group
    $estimatedSize = 1200 + ($groupCount * 40)

    [PSCustomObject]@{
        User            = $Username
        GroupCount      = $groupCount
        EstimatedBytes  = $estimatedSize
        MaxTokenDefault = 12000
        MaxTokenKerberos = 65535
        Status = if ($estimatedSize -gt 48000) { "BLOAT — KERBEROS FAILURE RISK" }
                 elseif ($estimatedSize -gt 12000) { "WARNING — May exceed MaxTokenSize" }
                 else { "OK" }
    }
}

Get-TokenSize -Username "jdoe" | Format-List

# ── Find all users likely to have token bloat ─────────────────────────────
Get-ADUser -Filter * -Properties TokenGroups | Where-Object {
    $_.TokenGroups.Count -gt 300  # ~12000 bytes threshold
} | Select-Object SamAccountName,
    @{N='Groups'; E={ $_.TokenGroups.Count }} |
    Sort-Object Groups -Descending | Format-Table -AutoSize

# ── Fix: Increase MaxTokenSize on domain members (MEDIUM RISK, requires GPO) ─
# Registry path: HKLM\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters
# Value: MaxTokenSize = 65535 (DWORD)
# Deploy via GPO: Computer Config → Preferences → Registry
```

---

## Quick Fix Summary

| Error | Cause | Fix | Risk |
|-------|-------|-----|------|
| 0x1F SKEW | Clock drift > 5 min | `w32tm /resync /force` on affected machine | LOW |
| 0x7 SPN_NOT_FOUND | SPN not registered | `setspn -S <spn> <account>` | LOW |
| 0x32 SPN_CONFLICT | Duplicate SPN | `setspn -D <spn> <wrongaccount>` | MEDIUM |
| 0xC ETYPE | RC4 vs AES mismatch | Set `msDS-SupportedEncryptionTypes` = 28 | MEDIUM |
| Double-hop fails | KCD not configured | Set constrained delegation with correct SPNs | MEDIUM |
| Stale tickets | Service ticket age | `klist purge` + restart service | LOW |
| Token bloat | Too many groups | Increase MaxTokenSize via GPO | MEDIUM |

---

## Documentation

Record in Jira ticket:
- Error code observed: `[CODE]`
- Affected account: `[USER/SERVICE]`
- Root cause: `[DESCRIPTION]`
- Commands run: `[LIST]`
- Fix applied: `[CHANGE MADE]`
- Verification: `[How confirmed fixed]`
