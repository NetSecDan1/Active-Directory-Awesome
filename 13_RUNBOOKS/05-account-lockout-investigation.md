# Runbook: Account Lockout Investigation
**Risk**: READ-ONLY | **Estimated Time**: 30-60 minutes
**Requires**: Event log read access, AD read access
**Version**: 2.0 | **Owner**: AD Engineering / Help Desk L2+

---

## Overview

Account lockouts are one of the most common AD issues. The goal of this runbook is to identify the **exact source** of lockout attempts — not just unlock the account. Unlocking without finding the source guarantees re-lockout.

**Tools**: PowerShell + AD Module, Event Viewer, optional: Microsoft Account Lockout and Management Tools

---

## Phase 0 — Gather Information

Before running any commands, collect from the user:

- [ ] **Username**: [SamAccountName or UPN]
- [ ] **Domain**: [Which domain]
- [ ] **When**: [First reported / how long happening]
- [ ] **Frequency**: [How often locking out — every hour? Every day?]
- [ ] **Pattern**: [Any time-of-day pattern?]
- [ ] **Recent changes**: [Password change? New device? New software?]

---

## Phase 1 — Confirm Lockout & Get Baseline

```powershell
$username = "jdoe"  # Replace with actual username
$domain = (Get-ADDomain).DNSRoot

# Step 1: Confirm account is actually locked
Get-ADUser $username -Properties * | Select-Object `
    SamAccountName, Enabled, LockedOut, BadPwdCount, BadPasswordTime,
    LastLogonDate, PasswordExpired, PasswordLastSet, PasswordNeverExpires,
    LastBadPasswordAttempt | Format-List

# Step 2: Get the lockout policy that applies to this user
# Check for Fine-Grained Password Policies first
$pso = Get-ADUserResultantPasswordPolicy $username -ErrorAction SilentlyContinue
if ($pso) {
    Write-Host "Fine-Grained PSO applies: $($pso.Name)" -ForegroundColor Yellow
    Write-Host "Lockout Threshold: $($pso.LockoutThreshold)"
    Write-Host "Lockout Window: $($pso.LockoutObservationWindow)"
} else {
    Write-Host "Default Domain Policy applies" -ForegroundColor Green
    $ddo = Get-ADDefaultDomainPasswordPolicy
    Write-Host "Lockout Threshold: $($ddo.LockoutThreshold)"
    Write-Host "Lockout Window: $($ddo.LockoutObservationWindow)"
}
```

---

## Phase 2 — Find the Source (PDC Emulator Event Logs)

The PDC Emulator receives Event 4740 (lockout) from all DCs in the domain. This is the single most important place to look.

```powershell
# Get PDC Emulator (lockout authority)
$PDC = (Get-ADDomain).PDCEmulator
Write-Host "PDC Emulator: $PDC"

# Event 4740 = Account Lockout — Contains CallerComputerName (THE SOURCE)
$lockouts = Get-WinEvent -ComputerName $PDC -FilterHashtable @{
    LogName = 'Security'
    Id = 4740
    StartTime = (Get-Date).AddDays(-3)  # Last 3 days
} -ErrorAction SilentlyContinue

$userLockouts = $lockouts | Where-Object {
    $_.Properties[0].Value -like "*$username*"
} | ForEach-Object {
    [PSCustomObject]@{
        Time            = $_.TimeCreated
        LockedAccount   = $_.Properties[0].Value
        CallerComputer  = $_.Properties[1].Value  # <-- THIS IS YOUR SOURCE
        DC              = $_.MachineName
    }
} | Sort-Object Time -Descending

Write-Host "`nLockout events found: $($userLockouts.Count)"
$userLockouts | Format-Table -AutoSize

# Summary: Which source computer is causing the most lockouts?
Write-Host "`nLockout sources (most frequent first):"
$userLockouts | Group-Object CallerComputer | Sort-Object Count -Descending | Format-Table Name, Count
```

**What CallerComputerName tells you**:
| Value | Meaning |
|-------|---------|
| `WORKSTATION01` | Lockout originated from that specific computer |
| `SERVER-APP01` | Lockout from application server — check services/apps |
| `(empty)` | NTLM auth failure from unknown source — check Credential Manager |
| `LOCALHOST` | Lockout happening on the DC itself — check DC services |

---

## Phase 3 — Investigate the Source Computer

Once you have a `CallerComputerName`, investigate that machine:

```powershell
$sourceMachine = "WORKSTATION01"  # Replace with actual CallerComputerName

# Check if machine is online
Test-Connection $sourceMachine -Count 1 -Quiet

# Check Event 4625 on SOURCE machine (bad password attempts)
Get-WinEvent -ComputerName $sourceMachine -FilterHashtable @{
    LogName = 'Security'
    Id = 4625
    StartTime = (Get-Date).AddDays(-1)
} -ErrorAction SilentlyContinue | ForEach-Object {
    [PSCustomObject]@{
        Time        = $_.TimeCreated
        Username    = $_.Properties[5].Value
        Domain      = $_.Properties[6].Value
        LogonType   = $_.Properties[10].Value
        Process     = $_.Properties[18].Value  # <-- What process caused this
        Workstation = $_.Properties[13].Value
    }
} | Where-Object { $_.Username -like "*$username*" } | Format-Table -AutoSize
```

**Logon Type tells you what's making the attempts**:
| Type | Meaning | Common Source |
|------|---------|---------------|
| 2 | Interactive | User typing at keyboard (typo?) |
| 3 | Network | Mapped drive, shared resource |
| 7 | Unlock | Screen unlock with stale cached password |
| 8 | NetworkCleartext | IIS basic auth, old apps |
| 10 | RemoteInteractive | RDP with stale password |

---

## Phase 4 — Check Common Sources on Source Machine

```powershell
# Run these on the SOURCE MACHINE (or have someone run them there)

# 1. Scheduled tasks using this account
Get-ScheduledTask | Where-Object { $_.Principal.UserId -like "*$username*" } |
    Select-Object TaskName, TaskPath, @{N='RunAs';E={$_.Principal.UserId}} | Format-Table

# 2. Services running as this account
Get-WmiObject Win32_Service | Where-Object { $_.StartName -like "*$username*" } |
    Select-Object Name, DisplayName, StartName, State | Format-Table

# 3. Windows Credential Manager (list stored credentials)
cmdkey /list
# Look for: any credentials stored for this username that might be stale

# 4. Mapped drives (can store stale credentials)
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -like "\\*" } | Format-Table

# 5. IIS Application Pools (if it's a server)
# Run in IIS module if available:
# Import-Module WebAdministration
# Get-WebConfiguration system.applicationHost/applicationPools/add |
#     Where-Object { $_.processModel.userName -like "*$username*" }
```

---

## Phase 5 — Domain-Wide Check (If Source is Unknown)

If `CallerComputerName` is empty or you need a broader view:

```powershell
# Check ALL DCs for Event 4776 (NTLM auth failure — includes workstation name)
Get-ADDomainController -Filter * | ForEach-Object {
    $dc = $_.HostName
    Get-WinEvent -ComputerName $dc -FilterHashtable @{
        LogName = 'Security'
        Id = 4776
        StartTime = (Get-Date).AddDays(-1)
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.Properties[1].Value -like "*$username*"
    } | ForEach-Object {
        [PSCustomObject]@{
            DC           = $dc
            Time         = $_.TimeCreated
            Account      = $_.Properties[1].Value
            Workstation  = $_.Properties[2].Value
            ErrorCode    = $_.Properties[3].Value
        }
    }
} | Sort-Object Time -Descending | Format-Table -AutoSize
```

---

## Phase 6 — Resolution

**After identifying the source**, follow the appropriate fix:

| Root Cause | Fix |
|-----------|-----|
| Stale cached credentials on workstation | Clear Credential Manager on source machine |
| Scheduled task with old password | Update task with new credentials |
| Service account with old password | Update service and restart |
| Old mobile device (Exchange/EAS) | Remove/update device profile |
| Mapped drive with saved password | Remove and re-map with current credentials |
| Old Outlook profile | Update password in Outlook profile |
| User typo at login | User education + unlock account |
| Duplicate SPN causing Kerberos failure | `setspn -X` to find and fix duplicates |

**Unlock the account** (only AFTER finding and fixing the source):
```powershell
# WRITE OPERATION — only after root cause is addressed
Unlock-ADAccount -Identity $username
```

---

## Documentation

Record in your Jira ticket:
- Source computer identified: `[MACHINE NAME]`
- Root cause: `[What was causing bad password attempts]`
- Fix applied: `[What was changed on the source]`
- Account unlocked at: `[Timestamp]`
- Re-lock occurred after fix: `[Yes/No]`
