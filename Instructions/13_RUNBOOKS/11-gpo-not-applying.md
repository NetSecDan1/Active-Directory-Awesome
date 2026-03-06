# Runbook: Group Policy Not Applying — Triage
**Risk**: READ-ONLY (investigation) / LOW-MEDIUM (fixes) | **Estimated Time**: 30-75 minutes
**Requires**: AD read access, GPMC, target machine access | **Change Type**: Normal
**Version**: 1.0 | **Owner**: AD Engineering / Desktop Engineering

---

## Overview

GPO failures are consistently misdiagnosed. The most common mistake is editing a GPO when the real problem is **replication lag**, **WMI filter misconfiguration**, **security filtering**, or **slow link detection**. Always run `gpresult` and read the **Denied/Not Applied** section before making any changes.

**Key principle**: If a setting was applied before and stopped working, start with replication. If it was never applied, start with security filtering and WMI filters.

---

## Decision Tree

```
START: GPO setting not taking effect on target
    │
    ├─ gpresult shows GPO as "Denied (Security Filtering)"? ────► Phase 3: Security Filtering
    │
    ├─ gpresult shows GPO as "Denied (WMI Filter)"? ─────────────► Phase 4: WMI Filters
    │
    ├─ GPO not listed at all in gpresult? ────────────────────────► Phase 2: OU / Link Scope
    │
    ├─ GPO listed but setting not applied (reason = "Unknown")? ──► Phase 5: SYSVOL / Policy File
    │
    ├─ GPO was working, stopped recently? ───────────────────────► Phase 6: Replication
    │
    ├─ Loopback processing involved? ────────────────────────────► Phase 7: Loopback
    │
    └─ Slow link or VPN users affected only? ────────────────────► Phase 8: Slow Link
```

---

## Phase 0 — Gather Information

Before touching anything:

- [ ] **Target**: Specific user? Specific computer? Both?
- [ ] **GPO name**: Which policy should be applying?
- [ ] **Setting**: Exactly what setting, in which section (Computer/User)?
- [ ] **OU**: Where is the user/computer object in AD?
- [ ] **Working scope**: Is it failing for everyone in the OU, or just some?
- [ ] **When**: Was this ever working? When did it stop?

---

## Phase 1 — Run gpresult (Most Important First Step)

**Always start here.** Run on the target machine, as or for the affected user.

```powershell
# ── Run on target machine ─────────────────────────────────────────────────

# HTML report — most detail, best for complex analysis
gpresult /H C:\Temp\gpresult.html /F
# Open C:\Temp\gpresult.html in a browser

# Quick summary to console
gpresult /R

# For a specific user (run as admin):
gpresult /USER domain\jdoe /R

# For a remote machine:
gpresult /S WORKSTATION01 /USER domain\jdoe /R

# ── Read the output — key sections ────────────────────────────────────────
# Look for:
#   "Applied GPOs"          — what actually applied
#   "Denied GPOs"           — what was blocked and WHY
#   "The following GPOs were not applied because they were filtered out"
#
# Denial reasons:
#   "Security Filtering"    → User/computer not in security group
#   "WMI Filter"            → WMI query returned false
#   "Empty"                 → GPO has no settings configured
#   "Disabled"              → GPO link or GPO itself is disabled
#   "Not Applicable"        → GPO is user-side only, applied to computer scope (or vice versa)
```

---

## Phase 2 — OU Linking and Scope

```powershell
$gpoName = "MyGPO-Name"   # Replace with actual GPO name

# ── Find where the GPO is linked ──────────────────────────────────────────
Import-Module GroupPolicy
$gpo = Get-GPO -Name $gpoName
$gpoId = $gpo.Id

# Show all links for this GPO
Get-GPOReport -Name $gpoName -ReportType Xml | Select-String -Pattern "SOMPath|LinkEnabled|NoOverride"

# All links across domain (requires GPMC module)
$domain = (Get-ADDomain).DNSRoot
[xml]$gpoReport = Get-GPOReport -Name $gpoName -ReportType Xml -Domain $domain
$gpoReport.GPO.LinksTo | Format-Table SOMPath, Enabled, NoOverride -AutoSize

# ── Verify the target object is in the linked OU ──────────────────────────
$username = "jdoe"
$userOU = (Get-ADUser $username).DistinguishedName
Write-Host "User DN: $userOU"
# Is this OU (or a parent OU) in the GPO link list above?

$computer = "WORKSTATION01"
$compOU = (Get-ADComputer $computer).DistinguishedName
Write-Host "Computer DN: $compOU"

# ── Check if GPO link is enabled ──────────────────────────────────────────
Get-GPInheritance -Target "OU=Workstations,DC=domain,DC=com" |
    Select-Object -ExpandProperty GpoLinks |
    Format-Table DisplayName, GpoId, Enabled, Enforced, Order -AutoSize
```

---

## Phase 3 — Security Filtering

Default: "Authenticated Users" must have **Read** + **Apply Group Policy**. If removed and replaced with a specific group, the user/computer must be a member.

```powershell
$gpoName = "MyGPO-Name"

# ── Check security filtering (who can read/apply this GPO) ────────────────
$gpo = Get-GPO -Name $gpoName
$acl = Get-GPPermissions -Name $gpoName -All

$acl | Where-Object { $_.Permission -in @('GpoApply','GpoRead','GpoEditDeleteModifySecurity') } |
    Format-Table Trustee, TrusteeType, Permission -AutoSize

# Key: Look for whether "Authenticated Users" has GpoApply
# If it's been removed, which GROUP has GpoApply instead?

# ── Verify the affected user is in that group ─────────────────────────────
$username = "jdoe"
$group = "GPO-Apply-Workstation-Group"   # Replace with actual security group

# Direct membership
(Get-ADUser $username -Properties MemberOf).MemberOf -contains (Get-ADGroup $group).DistinguishedName

# Nested membership (tokenGroups — most accurate)
$userGroups = (Get-ADUser $username -Properties TokenGroups).TokenGroups |
    ForEach-Object { Get-ADGroup -Filter { objectSid -eq $_ } -ErrorAction SilentlyContinue } |
    Select-Object -ExpandProperty SamAccountName
$userGroups -contains $group

# ── Fix: Add user/computer to the security group (WRITE — LOW RISK) ───────
# Add-ADGroupMember -Identity $group -Members $username
```

---

## Phase 4 — WMI Filters

WMI filters evaluate a WMI query on the target machine. If the query returns false (or errors), the entire GPO is denied.

```powershell
# ── Find the WMI filter attached to a GPO ─────────────────────────────────
$gpoName = "MyGPO-Name"
[xml]$report = Get-GPOReport -Name $gpoName -ReportType Xml
$wmiFilter = $report.GPO.FilterName
Write-Host "WMI Filter: $wmiFilter"

# ── Get all WMI filters in the domain ──────────────────────────────────────
Get-ADObject -SearchBase "CN=SOM,CN=WMIPolicy,CN=System,$((Get-ADDomain).DistinguishedName)" `
    -Filter { ObjectClass -eq 'msWMI-Som' } `
    -Properties msWMI-Name, msWMI-Parm2 |
    Select-Object 'msWMI-Name', 'msWMI-Parm2' | Format-List

# ── Manually test the WMI query on the target machine ─────────────────────
# Extract the query from msWMI-Parm2 above, then test on target:
# Example WMI filter query for Windows 10:
$wmiQuery = "SELECT * FROM Win32_OperatingSystem WHERE Version LIKE '10.%' AND ProductType = 1"

$result = Get-WmiObject -Query $wmiQuery
if ($result) {
    Write-Host "WMI filter would PASS on this machine" -ForegroundColor Green
} else {
    Write-Host "WMI filter would FAIL on this machine — GPO would be denied" -ForegroundColor Red
}
```

---

## Phase 5 — SYSVOL / GPO Template Missing or Corrupt

Each GPO has a template folder in SYSVOL. If it's missing or not replicated, settings can't be read.

```powershell
$gpoName = "MyGPO-Name"
$gpo = Get-GPO -Name $gpoName
$gpoGuid = $gpo.Id.ToString().ToUpper()
$domain = (Get-ADDomain).DNSRoot

# ── Verify the GPO template exists in SYSVOL ──────────────────────────────
$sysvolPath = "\\$domain\SYSVOL\$domain\Policies\{$gpoGuid}"
Write-Host "SYSVOL path: $sysvolPath"
Test-Path $sysvolPath

# Should have subfolders: Machine, User
# Machine folder contains Registry.pol for computer settings
# User folder contains Registry.pol for user settings
$machinePol = "$sysvolPath\Machine\Registry.pol"
$userPol    = "$sysvolPath\User\Registry.pol"

Write-Host "Machine\Registry.pol exists: $(Test-Path $machinePol)"
Write-Host "User\Registry.pol exists:    $(Test-Path $userPol)"

# ── Check SYSVOL content on all DCs (replication lag) ─────────────────────
Get-ADDomainController -Filter * | ForEach-Object {
    $dc = $_.HostName
    $path = "\\$dc\SYSVOL\$domain\Policies\{$gpoGuid}"
    [PSCustomObject]@{
        DC        = $dc
        PathExists = Test-Path $path
    }
} | Format-Table -AutoSize

# ── Check SYSVOL replication health ───────────────────────────────────────
# DFSR-based SYSVOL (2008+):
Get-WinEvent -FilterHashtable @{ LogName='DFS Replication'; Level=@(1,2,3) } `
    -MaxEvents 20 -ErrorAction SilentlyContinue | Format-Table TimeCreated, Message -AutoSize
```

---

## Phase 6 — Replication (GPO Changed Recently)

If a GPO was edited and hasn't replicated to all DCs yet, some clients may get old settings.

```powershell
# ── Check GPO version on each DC ──────────────────────────────────────────
$gpoName = "MyGPO-Name"
$gpo = Get-GPO -Name $gpoName
$gpoId = $gpo.Id.ToString()

# Version in AD (from GPO object)
Write-Host "Expected Computer version: $($gpo.Computer.DSVersion)"
Write-Host "Expected User version:     $($gpo.User.DSVersion)"

# Check version stored in SYSVOL on each DC (should match)
Get-ADDomainController -Filter * | ForEach-Object {
    $dc = $_.HostName
    $gptIniPath = "\\$dc\SYSVOL\$((Get-ADDomain).DNSRoot)\Policies\{$gpoId}\GPT.INI"
    try {
        $content = Get-Content $gptIniPath -ErrorAction Stop
        $sysvolVersion = ($content | Where-Object { $_ -like "Version=*" }) -replace "Version=", ""
        [PSCustomObject]@{
            DC             = $dc
            SYSVOLVersion  = $sysvolVersion
            ExpectedComputer = $gpo.Computer.DSVersion
            ExpectedUser   = $gpo.User.DSVersion
        }
    } catch {
        [PSCustomObject]@{ DC = $dc; SYSVOLVersion = "UNREADABLE" }
    }
} | Format-Table -AutoSize

# Version mismatch = replication lag. Force replication:
# repadmin /syncall /AdeP
```

---

## Phase 7 — Loopback Processing

Loopback applies USER settings from GPOs linked to the COMPUTER's OU, not the user's OU.

```powershell
# ── Check if loopback is configured ───────────────────────────────────────
# The GPO enabling loopback:
# Computer Configuration → Administrative Templates → System → Group Policy
#   → Configure user Group Policy loopback processing mode

# Check via RSOP what loopback mode is active:
Invoke-Command -ComputerName TARGETCOMPUTER -ScriptBlock {
    $key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\GPExtensions"
    # Or use gpresult /H to see loopback mode in effect
    gpresult /R | Select-String -Pattern "loopback"
}

# ── Common loopback gotchas ────────────────────────────────────────────────
# - Replace mode: ONLY user GPOs from computer OU apply (ignores user OU GPOs)
# - Merge mode: Computer OU user GPOs + User OU GPOs (computer OU wins conflicts)
# - GPO must be linked to the COMPUTER's OU (not user OU) to apply in loopback
```

---

## Phase 8 — Slow Link Detection

By default, connections < 500 Kbps trigger slow link mode. Certain CSEs (Software Install, Folder Redirect) are disabled on slow links.

```powershell
# ── Check if slow link was detected for a user ────────────────────────────
# In gpresult /H or /R output, look for:
#   "The user is on a slow link"
#   "The computer is on a slow link"

# ── Check slow link threshold GPO settings ────────────────────────────────
# Computer Configuration → Administrative Templates → System → Group Policy
#   → Configure Group Policy slow link detection
#   Default: 500 Kbps = slow link

# ── Which CSEs run on slow links? ─────────────────────────────────────────
# These CSEs are DISABLED on slow links by default:
# - Software Installation
# - Folder Redirection
# - Scripts (startup/logon)
# - Disk Quota
# You can override per-CSE via GPO settings
```

---

## Common GPO Fix Summary

| Problem | Fix | Risk |
|---------|-----|------|
| User/computer not in security group | `Add-ADGroupMember` | LOW |
| GPO link disabled | Enable link in GPMC | LOW |
| GPO not linked to correct OU | Link GPO to OU in GPMC | LOW |
| SYSVOL not replicated | `repadmin /syncall /AdeP` | LOW |
| WMI filter query wrong | Edit WMI filter in GPMC | MEDIUM |
| GPO missing SYSVOL template | Recreate GPO or force SYSVOL replication | MEDIUM |
| Wrong GPO order/precedence | Adjust link order in GPMC | LOW |
| Block Inheritance on child OU | Remove block or use Enforced | MEDIUM |

---

## Documentation

Record in Jira ticket:
- Target user/computer: `[NAME]`
- GPO being investigated: `[NAME / GUID]`
- `gpresult` denial reason: `[REASON]`
- Root cause: `[DESCRIPTION]`
- Fix applied: `[CHANGE]`
- Verification: `[gpresult output confirms applied]`
