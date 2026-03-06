# 08 — Runbook Generator Prompts for Active Directory Operations

> **What this is**: AI prompts that generate complete, production-ready operational runbooks for AD tasks. From DC promotion to disaster recovery — generate expert-level runbooks on demand.

---

## MASTER RUNBOOK GENERATION PROMPT

```
Generate a complete operational runbook for the following Active Directory task. The runbook must be:

QUALITY BAR:
- Executable by an L2 engineer following it step-by-step
- Reviewed and approved-level for a P1 environment
- Complete: no "refer to documentation" shortcuts
- Safe: every write operation has a rollback
- Verified: every major step has a success check

REQUIRED SECTIONS:
1. Overview & Purpose
2. Prerequisites (access, tools, pre-checks)
3. Pre-Change Baseline Capture (read-only)
4. Step-by-Step Procedure
5. Verification Steps
6. Rollback Procedure
7. Post-Change Tasks
8. Troubleshooting (common issues during this runbook)

FORMAT:
- Numbered steps
- Each step: Action | Command (if applicable) | Expected Result | Rollback if failed
- Risk level on every write command: [LOW] [MEDIUM] [HIGH] [CRITICAL]
- Time estimate per step

TASK:
[Describe the AD task you need a runbook for]

ENVIRONMENT:
[Domain name, DC count, tools, constraints]
```

---

## PRE-BUILT RUNBOOK: DC Health Check (Weekly)

```markdown
# Runbook: Weekly Active Directory Health Check
**Version**: 2.0 | **Risk Level**: READ-ONLY | **Estimated Time**: 45-60 minutes
**Frequency**: Weekly | **Owner**: AD Engineering Team
**Last Updated**: [Date]

---

## Overview
Weekly baseline health check of the Active Directory environment. All commands are read-only. No changes are made.

## Prerequisites
- [ ] PowerShell 5.1+ with ActiveDirectory module
- [ ] Domain Admin or equivalent read access
- [ ] Network access to all DCs
- [ ] 1 hour of uninterrupted time
- [ ] Access to Splunk/SIEM (if available)

---

## PHASE 1: Domain Controller Status (10 minutes)

### Step 1.1 — Get all DC status
```powershell
# Run from any DC or management station
Get-ADDomainController -Filter * |
    Select-Object Name, Site, IPv4Address, IsGlobalCatalog, IsReadOnly, OperatingSystem, Enabled |
    Sort-Object Site, Name | Format-Table -AutoSize
```
**Expected**: All DCs listed, Enabled = True for all operational DCs
**Action if issue**: Investigate any DC showing Enabled = False or not appearing

### Step 1.2 — Test DC reachability
```powershell
$DCs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName
$results = foreach ($dc in $DCs) {
    [PSCustomObject]@{
        DC = $dc
        Ping = (Test-Connection $dc -Count 1 -Quiet)
        LDAP = (Test-NetConnection $dc -Port 389 -WarningAction SilentlyContinue).TcpTestSucceeded
        Kerberos = (Test-NetConnection $dc -Port 88 -WarningAction SilentlyContinue).TcpTestSucceeded
    }
}
$results | Format-Table -AutoSize
```
**Expected**: All True across all DCs
**Action if issue**: Alert and begin DC troubleshooting runbook for any failures

### Step 1.3 — Check FSMO role holders
```powershell
netdom query fsmo
```
**Expected**: Roles assigned to appropriate DCs per your architecture
**Record**: Document any changes from last week's check

### Step 1.4 — Run DCDiag
```powershell
# Run on PDC Emulator for most comprehensive check
dcdiag /test:replications /test:ncsecdesc /test:netlogons /test:advertising /test:fsmocheck /v 2>&1 |
    Where-Object { $_ -match "fail|error|warning|pass" } |
    Tee-Object -FilePath "C:\Temp\DCDiag_$(Get-Date -Format yyyyMMdd).txt"
```
**Expected**: All tests show "passed"
**Action if issue**: Document all failures, cross-reference with known issues list

---

## PHASE 2: Replication Health (10 minutes)

### Step 2.1 — Replication summary
```powershell
repadmin /replsummary
```
**Expected**: 0 failures, 0 errors, all DCs listed
**Red flags**: Any "Fails" column > 0, "Delta" > expected replication interval

### Step 2.2 — Replication errors detail
```powershell
repadmin /showrepl * /errorsonly
```
**Expected**: No output (no errors)
**Action if output exists**: Document error codes, begin replication troubleshooting

### Step 2.3 — Check replication queue
```powershell
repadmin /queue
```
**Expected**: Empty queue or small queue that clears within minutes
**Red flag**: Queue growing or items stuck

---

## PHASE 3: DNS Health (10 minutes)

### Step 3.1 — Verify SRV records
```powershell
$domain = (Get-ADDomain).DNSRoot
$srvTests = @(
    "_ldap._tcp.dc._msdcs.$domain",
    "_kerberos._tcp.dc._msdcs.$domain",
    "_ldap._tcp.pdc._msdcs.$domain"
)
foreach ($srv in $srvTests) {
    $result = Resolve-DnsName -Name $srv -Type SRV -ErrorAction SilentlyContinue
    Write-Host "$srv : $(if($result){"OK ($($result.Count) records)"}else{"MISSING"})" -ForegroundColor $(if($result){"Green"}else{"Red"})
}
```
**Expected**: Each SRV resolves with multiple records

### Step 3.2 — Verify all DCs registered
```powershell
Get-ADDomainController -Filter * | ForEach-Object {
    $resolve = Resolve-DnsName $_.HostName -Type A -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        DC = $_.Name
        Hostname = $_.HostName
        DNS_IP = if($resolve){$resolve.IPAddress -join ','}else{"UNRESOLVED"}
        AD_IP = $_.IPv4Address
        Match = $resolve.IPAddress -contains $_.IPv4Address
    }
} | Format-Table -AutoSize
```
**Expected**: Match = True for all DCs

---

## PHASE 4: Account Health (10 minutes)

### Step 4.1 — Locked accounts
```powershell
$locked = Search-ADAccount -LockedOut | Select-Object Name, SamAccountName, LastLogonDate
Write-Host "Locked accounts: $($locked.Count)"
$locked | Format-Table -AutoSize
```
**Expected**: < 5 locked accounts is normal; investigate spikes

### Step 4.2 — Expiring soon
```powershell
Search-ADAccount -AccountExpiring -TimeSpan (New-TimeSpan -Days 7) |
    Select-Object Name, SamAccountName | Format-Table -AutoSize
```
**Expected**: Any expiring accounts should be expected (service accounts, temp accounts)

### Step 4.3 — Recent admin changes
```powershell
# Check for changes to privileged groups in last 7 days
$since = (Get-Date).AddDays(-7)
$privGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators")
foreach ($grp in $privGroups) {
    $members = Get-ADGroupMember -Identity $grp -Recursive |
               Get-ADUser -Properties WhenChanged |
               Where-Object {$_.WhenChanged -gt $since}
    if ($members) {
        Write-Host "RECENT CHANGES to $($grp): $($members.Count) accounts modified" -ForegroundColor Yellow
        $members | Select-Object Name, SamAccountName, WhenChanged | Format-Table
    }
}
```
**Expected**: No unexpected changes to privileged groups

---

## PHASE 5: Event Log Review (10 minutes)

### Step 5.1 — Critical errors on PDC Emulator
```powershell
$PDC = (Get-ADDomain).PDCEmulator
Get-WinEvent -ComputerName $PDC -FilterHashtable @{
    LogName = 'System','Application'
    Level = 1,2  # Critical and Error only
    StartTime = (Get-Date).AddDays(-7)
} -ErrorAction SilentlyContinue |
Select-Object TimeCreated, LogName, Id, Message |
Sort-Object TimeCreated -Descending |
Select-Object -First 20 |
Format-List
```

### Step 5.2 — Account lockout trends
```powershell
$PDC = (Get-ADDomain).PDCEmulator
$lockouts = Get-WinEvent -ComputerName $PDC -FilterHashtable @{
    LogName = 'Security'
    Id = 4740
    StartTime = (Get-Date).AddDays(-7)
} -ErrorAction SilentlyContinue
Write-Host "Lockout events (7d): $($lockouts.Count)"
$lockouts | ForEach-Object {
    [PSCustomObject]@{
        Time = $_.TimeCreated
        Username = $_.Properties[0].Value
        Source = $_.Properties[1].Value
    }
} | Group-Object Username | Sort-Object Count -Descending | Select-Object -First 10 |
Format-Table Name, Count -AutoSize
```

---

## PHASE 6: Health Report Generation (5 minutes)

```powershell
# Generate timestamped health check report
$reportDate = Get-Date -Format "yyyy-MM-dd"
$reportPath = "C:\ADHealthReports\Weekly_$reportDate.txt"

# This file should have been capturing output with Tee-Object throughout
# Final summary:
Write-Output "=== AD Weekly Health Check — $reportDate ===" | Out-File $reportPath
Write-Output "Completed by: $env:USERNAME on $env:COMPUTERNAME" | Out-File $reportPath -Append
Write-Output "Next check due: $((Get-Date).AddDays(7).ToString('yyyy-MM-dd'))" | Out-File $reportPath -Append
```

---

## Sign-Off Checklist

- [ ] All DCs reachable and services running
- [ ] Replication healthy (0 failures)
- [ ] DNS SRV records resolving
- [ ] Account lockout count within normal range
- [ ] No critical events in System/Application logs
- [ ] No unexpected changes to privileged groups
- [ ] Report saved to [share path]
- [ ] Any issues opened as Jira tickets

**Engineer**: _________________ **Date**: _______ **Signature**: _________________
```

---

## PROMPT: Emergency Runbook Generator

```
Generate an emergency response runbook for the following Active Directory crisis scenario. This will be used in a war room with multiple engineers. It must be:

- Executable under pressure without prior reading
- Decision-tree based (if X then Y, else Z)
- Role-assigned (who does each step)
- Time-boxed (each step has a time limit before escalating)
- Safety-gated (explicit approval gates before risky actions)
- Communication-integrated (what to communicate at each milestone)

SCENARIO:
[Describe the emergency scenario]

OUTPUT FORMAT:
1. Situation Assessment (5 minutes)
2. Immediate Containment (15 minutes)
3. Diagnosis Phase (30 minutes)
4. Remediation Decision Gate (who approves, what's the go/no-go)
5. Remediation Execution
6. Verification
7. Communication at each phase
8. Escalation triggers and contacts
```

---

## PROMPT: Custom Runbook Template

```
Create a runbook template for [task name] that my team can reuse. Make it:

TEMPLATE REQUIREMENTS:
- Fill-in-the-blank placeholders for environment-specific values
- Checkbox-based (can be printed and checked off)
- Time-estimated per section
- Clear owner assignment for each step
- Version-controlled friendly (minimal prose, maximum structure)
- Bilingual: Steps in plain English AND exact commands

SECTIONS I NEED:
[List the sections you want]

TASK:
[Describe what the runbook is for]
```
