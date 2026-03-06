#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Active Directory Health Report — Read-Only, Rich HTML Output
.DESCRIPTION
    Collects AD health data and generates a professional HTML report.
    ALL operations are read-only. Safe for production use.
.PARAMETER Domain
    Target domain (defaults to current domain)
.PARAMETER OutputPath
    Output HTML file path (defaults to Desktop)
.PARAMETER IncludeSecurityEvents
    Include security event log analysis (requires event log access)
.EXAMPLE
    .\Invoke-ADHealthReport.ps1
    .\Invoke-ADHealthReport.ps1 -Domain corp.contoso.com -OutputPath C:\Reports\AD_Health.html
#>
[CmdletBinding()]
param(
    [string]$Domain = (Get-ADDomain).DNSRoot,
    [string]$OutputPath = "$env:USERPROFILE\Desktop\ADHealth_$(Get-Date -Format 'yyyyMMdd-HHmmss').html",
    [switch]$IncludeSecurityEvents
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$StartTime = Get-Date

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting AD Health Collection for: $Domain" -ForegroundColor Cyan

# ============================================================
# DATA COLLECTION (ALL READ-ONLY)
# ============================================================

$Report = [ordered]@{
    CollectionTime = $StartTime
    Domain         = $Domain
    Collector      = "$env:COMPUTERNAME\$env:USERNAME"
    DCs            = @()
    Replication    = @()
    DNS            = @()
    Accounts       = @{}
    GPO            = @{}
    Security       = @{}
    Issues         = @()
    HealthScore    = 0
}

# Domain Controllers
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Collecting DC inventory..." -ForegroundColor Gray
try {
    $Report.DCs = Get-ADDomainController -Filter * -Server $Domain | ForEach-Object {
        $dc = $_
        $services = @{}
        $pingOk = Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet -ErrorAction SilentlyContinue

        if ($pingOk) {
            try {
                $svcList = Get-Service -ComputerName $dc.HostName -Name NTDS,NETLOGON,DNS,KDC,DFSR -ErrorAction SilentlyContinue
                foreach ($svc in $svcList) {
                    $services[$svc.Name] = $svc.Status.ToString()
                }
            } catch { }
        }

        [PSCustomObject]@{
            Name         = $dc.Name
            Site         = $dc.Site
            IP           = $dc.IPv4Address
            IsGC         = $dc.IsGlobalCatalog
            IsRODC       = $dc.IsReadOnly
            OS           = $dc.OperatingSystem
            Online       = $pingOk
            Services     = $services
            FSMORoles    = @()
        }
    }
} catch {
    Write-Warning "DC collection failed: $_"
}

# FSMO Roles
try {
    $domainObj = Get-ADDomain -Server $Domain
    $forestObj = Get-ADForest -Server $Domain
    $fsmoMap = @{
        $domainObj.PDCEmulator          = 'PDC Emulator'
        $domainObj.RIDMaster            = 'RID Master'
        $domainObj.InfrastructureMaster = 'Infrastructure Master'
        $forestObj.SchemaMaster         = 'Schema Master'
        $forestObj.DomainNamingMaster   = 'Domain Naming Master'
    }
    foreach ($dc in $Report.DCs) {
        $dc.FSMORoles = $fsmoMap.Keys | Where-Object { $_ -like "$($dc.Name)*" } | ForEach-Object { $fsmoMap[$_] }
    }
} catch { }

# Replication
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking replication status..." -ForegroundColor Gray
try {
    $replOutput = repadmin /replsummary /bysrc /bydest 2>&1
    $Report.Replication = repadmin /showrepl * /csv 2>&1 |
        ConvertFrom-Csv -ErrorAction SilentlyContinue |
        Where-Object { $_ -ne $null } |
        Select-Object 'Destination DSA Site', 'Destination DSA', 'Naming Context',
                      'Source DSA Site', 'Source DSA', 'Number of Failures',
                      'Last Failure Time', 'Last Success Time', 'Last Failure Status'
} catch {
    Write-Warning "Replication check failed: $_"
}

# Accounts
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Analyzing account health..." -ForegroundColor Gray
try {
    $cutoff90 = (Get-Date).AddDays(-90)
    $cutoff30 = (Get-Date).AddDays(-30)
    $cutoff7  = (Get-Date).AddDays(-7)

    $Report.Accounts = @{
        LockedOut       = @(Search-ADAccount -LockedOut -Server $Domain |
                            Select-Object Name, SamAccountName, LastLogonDate)
        PasswordExpired = @(Search-ADAccount -PasswordExpired -Server $Domain |
                            Select-Object Name, SamAccountName, PasswordLastSet)
        Stale90         = @(Get-ADUser -Filter {LastLogonDate -lt $cutoff90 -and Enabled -eq $true} `
                            -Server $Domain -Properties LastLogonDate |
                            Select-Object Name, SamAccountName, LastLogonDate)
        ExpiringIn7     = @(Search-ADAccount -AccountExpiring -TimeSpan (New-TimeSpan -Days 7) `
                            -Server $Domain | Select-Object Name, SamAccountName)
        NewAccounts7d   = @(Get-ADUser -Filter {Created -gt $cutoff7} -Server $Domain -Properties Created |
                            Select-Object Name, SamAccountName, Created)
        TotalEnabled    = (Get-ADUser -Filter {Enabled -eq $true} -Server $Domain).Count
        TotalDisabled   = (Get-ADUser -Filter {Enabled -eq $false} -Server $Domain).Count
    }
} catch {
    Write-Warning "Account analysis failed: $_"
}

# GPO
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Collecting GPO information..." -ForegroundColor Gray
try {
    $allGPOs = Get-GPO -All -Domain $Domain
    $cutoff7  = (Get-Date).AddDays(-7)
    $Report.GPO = @{
        Total            = $allGPOs.Count
        Disabled         = @($allGPOs | Where-Object {$_.GpoStatus -eq 'AllSettingsDisabled'})
        RecentlyModified = @($allGPOs | Where-Object {$_.ModificationTime -gt $cutoff7} |
                             Select-Object DisplayName, ModificationTime | Sort-Object ModificationTime -Descending)
        Unlinked         = @($allGPOs | Where-Object {
                                (Get-GPOReport -Guid $_.Id -ReportType Xml -Domain $Domain |
                                 Select-Xml -XPath "//LinksTo") -eq $null
                            } | Select-Object DisplayName, Id)
    }
} catch {
    Write-Warning "GPO collection failed: $_"
}

# Issue Detection & Health Score
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Calculating health score..." -ForegroundColor Gray
$score = 100
$issues = @()

# DC Issues
$offlineDCs = $Report.DCs | Where-Object { -not $_.Online }
if ($offlineDCs) {
    $issues += [PSCustomObject]@{Severity='CRITICAL'; Category='DC Health'; Message="$($offlineDCs.Count) DC(s) unreachable: $($offlineDCs.Name -join ', ')"}
    $score -= (30 * $offlineDCs.Count)
}

# Replication Issues
$replFails = $Report.Replication | Where-Object { [int]$_.'Number of Failures' -gt 0 }
if ($replFails) {
    $issues += [PSCustomObject]@{Severity='HIGH'; Category='Replication'; Message="$($replFails.Count) replication failure(s) detected"}
    $score -= (10 * [Math]::Min($replFails.Count, 5))
}

# Account Issues
if ($Report.Accounts.LockedOut.Count -gt 10) {
    $issues += [PSCustomObject]@{Severity='HIGH'; Category='Accounts'; Message="$($Report.Accounts.LockedOut.Count) accounts currently locked out"}
    $score -= 15
}
if ($Report.Accounts.Stale90.Count -gt 50) {
    $issues += [PSCustomObject]@{Severity='MEDIUM'; Category='Accounts'; Message="$($Report.Accounts.Stale90.Count) stale accounts (90+ days no logon)"}
    $score -= 10
}

$Report.HealthScore = [Math]::Max(0, [Math]::Min(100, $score))
$Report.Issues = $issues

# ============================================================
# HTML GENERATION
# ============================================================
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Generating HTML report..." -ForegroundColor Gray

$healthColor = if ($Report.HealthScore -ge 80) { '#27ae60' } elseif ($Report.HealthScore -ge 60) { '#f39c12' } else { '#e74c3c' }

function Get-StatusBadge($value, $goodThreshold = 0, $warnThreshold = 5) {
    if ($value -le $goodThreshold) { return "<span class='badge badge-green'>✓ $value</span>" }
    elseif ($value -le $warnThreshold) { return "<span class='badge badge-yellow'>⚠ $value</span>" }
    else { return "<span class='badge badge-red'>✗ $value</span>" }
}

function Get-ServiceBadge($status) {
    if ($status -eq 'Running') { return "<span class='svc-running'>●</span>" }
    else { return "<span class='svc-stopped'>● $status</span>" }
}

$dcRows = ($Report.DCs | ForEach-Object {
    $dc = $_
    $onlineStatus = if ($dc.Online) { "<span class='badge badge-green'>Online</span>" } else { "<span class='badge badge-red'>Offline</span>" }
    $gcStatus = if ($dc.IsGC) { "✓" } else { "" }
    $rodcStatus = if ($dc.IsRODC) { "<span class='badge badge-yellow'>RODC</span>" } else { "" }
    $fsmoStr = if ($dc.FSMORoles) { "<small>$($dc.FSMORoles -join ', ')</small>" } else { "" }
    $ntdsSvc = if ($dc.Services['NTDS']) { Get-ServiceBadge $dc.Services['NTDS'] } else { "<span class='svc-unknown'>?</span>" }
    $netlogSvc = if ($dc.Services['NETLOGON']) { Get-ServiceBadge $dc.Services['NETLOGON'] } else { "<span class='svc-unknown'>?</span>" }
    "<tr><td><strong>$($dc.Name)</strong><br>$fsmoStr</td><td>$onlineStatus</td><td>$($dc.Site)</td><td>$($dc.IP)</td><td>$gcStatus</td><td>$rodcStatus</td><td>$ntdsSvc NTDS $netlogSvc NETL</td></tr>"
}) -join "`n"

$issueRows = if ($Report.Issues) {
    ($Report.Issues | ForEach-Object {
        $sevClass = if ($_.Severity -eq 'CRITICAL') { 'badge-red' } elseif ($_.Severity -eq 'HIGH') { 'badge-orange' } else { 'badge-yellow' }
        "<tr><td><span class='badge $sevClass'>$($_.Severity)</span></td><td>$($_.Category)</td><td>$($_.Message)</td></tr>"
    }) -join "`n"
} else {
    "<tr><td colspan='3'><span class='badge badge-green'>✓ No issues detected</span></td></tr>"
}

$HTML = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AD Health Report — $Domain</title>
<style>
  :root {
    --green: #27ae60; --yellow: #f39c12; --red: #e74c3c;
    --orange: #e67e22; --blue: #2980b9; --dark: #2c3e50; --light: #ecf0f1;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f6fa; color: #333; }
  .header { background: var(--dark); color: white; padding: 24px 32px; display: flex; justify-content: space-between; align-items: center; }
  .header h1 { font-size: 1.6em; }
  .header .meta { font-size: 0.85em; opacity: 0.8; text-align: right; }
  .health-score { background: $healthColor; color: white; border-radius: 50%; width: 80px; height: 80px; display: flex; align-items: center; justify-content: center; font-size: 1.8em; font-weight: bold; flex-shrink: 0; }
  .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; padding: 24px 32px; }
  .stat-card { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,.08); border-left: 4px solid var(--blue); }
  .stat-card.warn { border-left-color: var(--yellow); }
  .stat-card.crit { border-left-color: var(--red); }
  .stat-card .number { font-size: 2.2em; font-weight: bold; color: var(--dark); }
  .stat-card .label { font-size: 0.85em; color: #666; margin-top: 4px; }
  .section { background: white; margin: 0 32px 24px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,.08); overflow: hidden; }
  .section-header { background: var(--dark); color: white; padding: 12px 20px; font-size: 1em; font-weight: 600; }
  .section-body { padding: 0; }
  table { width: 100%; border-collapse: collapse; font-size: 0.9em; }
  th { background: #f8f9fa; padding: 10px 16px; text-align: left; border-bottom: 2px solid #e0e0e0; font-weight: 600; color: var(--dark); }
  td { padding: 10px 16px; border-bottom: 1px solid #f0f0f0; vertical-align: middle; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: #f8f9ff; }
  .badge { display: inline-block; padding: 2px 10px; border-radius: 12px; font-size: 0.78em; font-weight: 600; }
  .badge-green { background: #d5f5e3; color: #1e8449; }
  .badge-yellow { background: #fef9e7; color: #9a7d0a; }
  .badge-orange { background: #fdebd0; color: #ca6f1e; }
  .badge-red { background: #fadbd8; color: #922b21; }
  .svc-running { color: var(--green); }
  .svc-stopped { color: var(--red); font-size: 0.85em; }
  .svc-unknown { color: #aaa; }
  .footer { text-align: center; padding: 24px; color: #888; font-size: 0.85em; }
  .no-issues { color: var(--green); padding: 20px; text-align: center; font-size: 1.1em; }
</style>
</head>
<body>

<div class="header">
  <div>
    <h1>Active Directory Health Report</h1>
    <div style="margin-top:4px;opacity:.8">Domain: <strong>$Domain</strong></div>
  </div>
  <div class="meta">
    Generated: $($Report.CollectionTime.ToString('yyyy-MM-dd HH:mm:ss UTC'))<br>
    Collector: $($Report.Collector)<br>
    Collection Time: $([int]((Get-Date) - $StartTime).TotalSeconds)s
  </div>
  <div class="health-score" title="Health Score (100 = perfect)">$($Report.HealthScore)</div>
</div>

<div class="dashboard">
  <div class="stat-card $(if($offlineDCs){'crit'}else{''})">
    <div class="number">$($Report.DCs.Count)</div>
    <div class="label">Domain Controllers<br><small>$($($Report.DCs | Where-Object Online).Count) Online / $($offlineDCs.Count) Offline</small></div>
  </div>
  <div class="stat-card $(if($replFails){'crit'}else{''})">
    <div class="number">$($replFails.Count)</div>
    <div class="label">Replication Failures</div>
  </div>
  <div class="stat-card $(if($Report.Accounts.LockedOut.Count -gt 0){'warn'}else{''})">
    <div class="number">$($Report.Accounts.LockedOut.Count)</div>
    <div class="label">Locked Accounts</div>
  </div>
  <div class="stat-card">
    <div class="number">$($Report.Accounts.TotalEnabled)</div>
    <div class="label">Enabled User Accounts</div>
  </div>
  <div class="stat-card $(if($Report.Accounts.Stale90.Count -gt 50){'warn'}else{''})">
    <div class="number">$($Report.Accounts.Stale90.Count)</div>
    <div class="label">Stale Accounts (90d)</div>
  </div>
  <div class="stat-card">
    <div class="number">$($Report.GPO.Total)</div>
    <div class="label">Total GPOs<br><small>$($Report.GPO.RecentlyModified.Count) modified this week</small></div>
  </div>
</div>

<!-- Issues Summary -->
<div class="section">
  <div class="section-header">⚠️ Issues Requiring Attention ($($Report.Issues.Count))</div>
  <div class="section-body">
    <table>
      <thead><tr><th>Severity</th><th>Category</th><th>Issue</th></tr></thead>
      <tbody>$issueRows</tbody>
    </table>
  </div>
</div>

<!-- Domain Controllers -->
<div class="section">
  <div class="section-header">🖥️ Domain Controllers ($($Report.DCs.Count))</div>
  <div class="section-body">
    <table>
      <thead><tr><th>Domain Controller</th><th>Status</th><th>Site</th><th>IP Address</th><th>GC</th><th>RODC</th><th>Services</th></tr></thead>
      <tbody>$dcRows</tbody>
    </table>
  </div>
</div>

<!-- Accounts -->
<div class="section">
  <div class="section-header">👤 Account Health</div>
  <div class="section-body">
    <table>
      <thead><tr><th>Metric</th><th>Count</th><th>Status</th></tr></thead>
      <tbody>
        <tr><td>Locked Out Accounts</td><td>$($Report.Accounts.LockedOut.Count)</td><td>$(Get-StatusBadge $Report.Accounts.LockedOut.Count 0 5)</td></tr>
        <tr><td>Password Expired</td><td>$($Report.Accounts.PasswordExpired.Count)</td><td>$(Get-StatusBadge $Report.Accounts.PasswordExpired.Count 0 10)</td></tr>
        <tr><td>Stale Accounts (90+ days)</td><td>$($Report.Accounts.Stale90.Count)</td><td>$(Get-StatusBadge $Report.Accounts.Stale90.Count 0 50)</td></tr>
        <tr><td>Accounts Expiring (7 days)</td><td>$($Report.Accounts.ExpiringIn7.Count)</td><td>$(Get-StatusBadge $Report.Accounts.ExpiringIn7.Count 0 5)</td></tr>
        <tr><td>New Accounts (7 days)</td><td>$($Report.Accounts.NewAccounts7d.Count)</td><td><span class='badge badge-green'>Info</span></td></tr>
        <tr><td>Total Enabled Users</td><td>$($Report.Accounts.TotalEnabled)</td><td><span class='badge badge-green'>✓</span></td></tr>
        <tr><td>Total Disabled Users</td><td>$($Report.Accounts.TotalDisabled)</td><td><span class='badge badge-green'>Info</span></td></tr>
      </tbody>
    </table>
  </div>
</div>

<div class="footer">
  Active Directory Health Report | Generated by Invoke-ADHealthReport.ps1 | Read-Only Collection | $($Report.CollectionTime.ToString('yyyy-MM-dd'))
</div>
</body>
</html>
"@

$HTML | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Report saved to: $OutputPath" -ForegroundColor Green
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Health Score: $($Report.HealthScore)/100" -ForegroundColor $(if($Report.HealthScore -ge 80){'Green'}elseif($Report.HealthScore -ge 60){'Yellow'}else{'Red'})
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Issues Found: $($Report.Issues.Count)" -ForegroundColor $(if($Report.Issues.Count -eq 0){'Green'}else{'Yellow'})

# Open in browser
Start-Process $OutputPath
