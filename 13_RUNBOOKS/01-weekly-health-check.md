# Runbook: Weekly Active Directory Health Check
**Risk**: READ-ONLY | **Estimated Time**: 45-60 minutes
**Requires**: AD read access, event log read access
**Frequency**: Weekly (Mondays recommended) | **Owner**: AD Engineering
**Version**: 2.0

---

## Overview
Establish and track your AD health baseline. Catch problems before they become incidents. All commands are read-only — safe to run any time, including production hours.

**Output**: Save results to a shared drive. Compare week-over-week for trend detection.

---

## Phase 1 — Domain Controller Inventory & Reachability (10 min)

```powershell
# Step 1.1 — All DCs with site and role info
Get-ADDomainController -Filter * |
    Select-Object Name, Site, IPv4Address, IsGlobalCatalog, IsReadOnly,
                  OperatingSystem, Enabled |
    Sort-Object Site, Name | Format-Table -AutoSize

# Step 1.2 — FSMO role holders (document changes week-over-week)
netdom query fsmo

# Step 1.3 — DC reachability + key port connectivity
Get-ADDomainController -Filter * | ForEach-Object {
    [PSCustomObject]@{
        DC       = $_.Name
        Site     = $_.Site
        Ping     = (Test-Connection $_.HostName -Count 1 -Quiet -ErrorAction SilentlyContinue)
        LDAP     = (Test-NetConnection $_.HostName -Port 389 -WA SilentlyContinue).TcpTestSucceeded
        Kerberos = (Test-NetConnection $_.HostName -Port 88  -WA SilentlyContinue).TcpTestSucceeded
        DNS      = (Test-NetConnection $_.HostName -Port 53  -WA SilentlyContinue).TcpTestSucceeded
    }
} | Format-Table -AutoSize

# Step 1.4 — Services on all DCs
Get-ADDomainController -Filter * | ForEach-Object {
    $dc = $_.Name
    try {
        Get-Service -ComputerName $dc -Name NTDS,NETLOGON,KDC,DNS,DFSR -ErrorAction Stop |
            Select-Object @{N='DC';E={$dc}}, Name, Status
    } catch { }
} | Where-Object { $_.Status -ne 'Running' } | Format-Table -AutoSize
# Expected: No output (all services Running)
```

**Health check**: ✅ All DCs reachable | ✅ All services Running | ✅ FSMO unchanged from last week

---

## Phase 2 — Replication Health (10 min)

```powershell
# Step 2.1 — Summary (the key number: should be 0 failures)
repadmin /replsummary

# Step 2.2 — Errors only (should produce no output)
repadmin /showrepl * /errorsonly

# Step 2.3 — Replication lag per site
repadmin /showvector /latency

# Step 2.4 — Queue depth (should clear quickly)
repadmin /queue
```

**Record**: Failure count this week vs last week. Any new errors = open Jira + see [07-replication-recovery.md](07-replication-recovery.md)

---

## Phase 3 — DNS Health (5 min)

```powershell
$domain = (Get-ADDomain).DNSRoot

# Step 3.1 — SRV records (DC locator foundation)
@(
    "_ldap._tcp.dc._msdcs.$domain",
    "_kerberos._tcp.dc._msdcs.$domain",
    "_ldap._tcp.pdc._msdcs.$domain",
    "_gc._tcp.$domain"
) | ForEach-Object {
    $r = Resolve-DnsName $_ -Type SRV -ErrorAction SilentlyContinue
    Write-Host "$_ : $(if($r){"✅ $($r.Count) records"}else{"❌ MISSING"})"
}

# Step 3.2 — All DCs registered in DNS
Get-ADDomainController -Filter * | ForEach-Object {
    $ip = (Resolve-DnsName $_.HostName -Type A -ErrorAction SilentlyContinue).IPAddress
    [PSCustomObject]@{
        DC = $_.Name; Expected = $_.IPv4Address
        Resolved = $ip; Match = $ip -contains $_.IPv4Address
    }
} | Where-Object { -not $_.Match } | Format-Table
# Expected: No output (all match)
```

---

## Phase 4 — Account Health (10 min)

```powershell
# Step 4.1 — Current lockout count (track trend)
$locked = Search-ADAccount -LockedOut
Write-Host "Locked accounts: $($locked.Count)"
$locked | Select-Object SamAccountName, LastLogonDate | Sort-Object LastLogonDate | Format-Table

# Step 4.2 — Expiring accounts (7-day warning)
Search-ADAccount -AccountExpiring -TimeSpan (New-TimeSpan -Days 7) |
    Select-Object Name, SamAccountName | Format-Table

# Step 4.3 — Changes to privileged groups this week
$since = (Get-Date).AddDays(-7)
foreach ($grp in @("Domain Admins","Enterprise Admins","Schema Admins","Administrators")) {
    $changes = Get-ADGroupMember $grp -Recursive |
               Get-ADObject -Properties WhenChanged |
               Where-Object { $_.WhenChanged -gt $since }
    if ($changes) {
        Write-Host "⚠️  CHANGES in ${grp}: $($changes.Count)" -ForegroundColor Yellow
        $changes | Select-Object Name, WhenChanged | Format-Table
    }
}

# Step 4.4 — New accounts created this week
Get-ADUser -Filter { Created -gt $since } -Properties Created |
    Select-Object Name, SamAccountName, Created | Sort-Object Created -Descending | Format-Table
```

---

## Phase 5 — Security Event Trends (10 min)

```powershell
$PDC = (Get-ADDomain).PDCEmulator
$since = (Get-Date).AddDays(-7)

# Step 5.1 — Lockout count trend
$lockouts = Get-WinEvent -ComputerName $PDC -FilterHashtable @{
    LogName='Security'; Id=4740; StartTime=$since
} -ErrorAction SilentlyContinue
Write-Host "Lockout events (7d): $($lockouts.Count)"

# Step 5.2 — Top lockout sources
$lockouts | ForEach-Object {
    [PSCustomObject]@{Username=$_.Properties[0].Value; Source=$_.Properties[1].Value}
} | Group-Object Username | Sort-Object Count -Descending |
    Select-Object -First 10 | Format-Table Name, Count

# Step 5.3 — Critical SYSTEM/Application errors on PDC (past 7 days)
Get-WinEvent -ComputerName $PDC -FilterHashtable @{
    LogName='System','Application'; Level=1,2; StartTime=$since
} -ErrorAction SilentlyContinue |
    Group-Object Id | Sort-Object Count -Descending |
    Select-Object -First 15 | Format-Table Name, Count
```

---

## Phase 6 — GPO Change Tracking (5 min)

```powershell
$since = (Get-Date).AddDays(-7)

# Step 6.1 — GPOs modified this week (should match known changes)
Get-GPO -All | Where-Object { $_.ModificationTime -gt $since } |
    Select-Object DisplayName, ModificationTime, GpoStatus |
    Sort-Object ModificationTime -Descending | Format-Table -AutoSize

# Step 6.2 — Total GPO count (track for unexpected additions)
Write-Host "Total GPOs: $((Get-GPO -All).Count)"
```

---

## Weekly Sign-Off Checklist

| Check | Status | Notes |
|-------|--------|-------|
| All DCs reachable | ✅ / ❌ | |
| All DC services running | ✅ / ❌ | |
| Replication: 0 failures | ✅ / ❌ | |
| DNS SRV records all resolving | ✅ / ❌ | |
| Lockout count within normal range | ✅ / ❌ | This week: ___ vs last week: ___ |
| No unexpected privileged group changes | ✅ / ❌ | |
| No unexpected GPO modifications | ✅ / ❌ | |
| Issues opened as Jira tickets | ✅ / N/A | |
| Report saved to team share | ✅ / ❌ | Path: ___ |

**Engineer**: _________________ **Date**: _________ **Next Check**: _________

> For a rich HTML version of this report, run: `.\14_HTML_POWERSHELL_REPORTS\Invoke-ADHealthReport.ps1`
