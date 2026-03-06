#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Stale Account Report — Read-Only, Rich HTML Output
.DESCRIPTION
    Identifies stale user and computer accounts for cleanup review.
    ALL operations are READ-ONLY. Never deletes or disables accounts.
.PARAMETER Domain
    Target domain (defaults to current domain)
.PARAMETER UserStaleDays
    Days since last logon to consider a user stale (default: 90)
.PARAMETER ComputerStaleDays
    Days since last logon to consider a computer stale (default: 60)
.PARAMETER OutputPath
    HTML output file path
.EXAMPLE
    .\Invoke-StaleAccountReport.ps1
    .\Invoke-StaleAccountReport.ps1 -UserStaleDays 60 -ComputerStaleDays 30
#>
[CmdletBinding()]
param(
    [string]$Domain = (Get-ADDomain).DNSRoot,
    [int]$UserStaleDays     = 90,
    [int]$ComputerStaleDays = 60,
    [string]$OutputPath = "$env:USERPROFILE\Desktop\StaleAccounts_$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
)

$ErrorActionPreference = 'Continue'
$StartTime = Get-Date
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Collecting stale account data for $Domain..." -ForegroundColor Cyan

$userCutoff     = (Get-Date).AddDays(-$UserStaleDays)
$computerCutoff = (Get-Date).AddDays(-$ComputerStaleDays)

# Collect data
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Querying stale users..." -ForegroundColor Gray
$staleUsers = Get-ADUser -Filter {
    Enabled -eq $true -and LastLogonDate -lt $userCutoff
} -Server $Domain -Properties LastLogonDate, PasswordLastSet, Created, Description, Department, Manager |
    Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet, Created, Description, Department,
                  @{N='Manager';E={ if($_.Manager){(Get-ADUser $_.Manager -ErrorAction SilentlyContinue).Name}else{""} }} |
    Sort-Object LastLogonDate

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Querying never-logged-in users..." -ForegroundColor Gray
$neverLoggedIn = Get-ADUser -Filter {
    Enabled -eq $true -and LastLogonDate -notlike "*"
} -Server $Domain -Properties LastLogonDate, Created |
    Where-Object { $_.Created -lt (Get-Date).AddDays(-30) } |  # Created 30+ days ago
    Select-Object Name, SamAccountName, Created | Sort-Object Created

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Querying stale computers..." -ForegroundColor Gray
$staleComputers = Get-ADComputer -Filter {
    Enabled -eq $true -and LastLogonDate -lt $computerCutoff
} -Server $Domain -Properties LastLogonDate, OperatingSystem, Created |
    Select-Object Name, SamAccountName, LastLogonDate, OperatingSystem, Created |
    Sort-Object LastLogonDate

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Querying disabled accounts..." -ForegroundColor Gray
$disabledUsers = Get-ADUser -Filter { Enabled -eq $false } -Server $Domain -Properties LastLogonDate, WhenChanged |
    Select-Object Name, SamAccountName, LastLogonDate, WhenChanged | Sort-Object WhenChanged -Descending

# Password never expires (security risk)
$pwdNeverExpires = Get-ADUser -Filter {
    Enabled -eq $true -and PasswordNeverExpires -eq $true
} -Server $Domain -Properties PasswordNeverExpires, PasswordLastSet, LastLogonDate |
    Select-Object Name, SamAccountName, PasswordLastSet, LastLogonDate | Sort-Object PasswordLastSet

function Get-AgeClass($date, $warnDays, $critDays) {
    if (-not $date) { return "badge-red" }
    $days = ((Get-Date) - $date).Days
    if ($days -ge $critDays) { return "badge-red" }
    elseif ($days -ge $warnDays) { return "badge-yellow" }
    else { return "badge-green" }
}

function Format-Age($date) {
    if (-not $date) { return "<em>Never</em>" }
    $days = [int]((Get-Date) - $date).Days
    if ($days -gt 365) { return "$([int]($days/365))yr $([int](($days%365)/30))mo ago" }
    elseif ($days -gt 30) { return "$([int]($days/30))mo ago" }
    else { return "$days days ago" }
}

$staleUserRows = ($staleUsers | Select-Object -First 100 | ForEach-Object {
    $cls = Get-AgeClass $_.LastLogonDate 90 180
    "<tr><td>$($_.Name)</td><td>$($_.SamAccountName)</td><td>$($_.Department)</td><td><span class='badge $cls'>$(Format-Age $_.LastLogonDate)</span></td><td>$(if($_.PasswordLastSet){$_.PasswordLastSet.ToString('yyyy-MM-dd')}else{'Never'})</td><td>$($_.Manager)</td></tr>"
}) -join "`n"

$staleCompRows = ($staleComputers | Select-Object -First 100 | ForEach-Object {
    $cls = Get-AgeClass $_.LastLogonDate 60 120
    "<tr><td>$($_.Name)</td><td>$($_.OperatingSystem)</td><td><span class='badge $cls'>$(Format-Age $_.LastLogonDate)</span></td><td>$(if($_.Created){$_.Created.ToString('yyyy-MM-dd')}else{'?'})</td></tr>"
}) -join "`n"

$pwdNeverRows = ($pwdNeverExpires | Select-Object -First 100 | ForEach-Object {
    "<tr><td>$($_.Name)</td><td>$($_.SamAccountName)</td><td>$(if($_.PasswordLastSet){$_.PasswordLastSet.ToString('yyyy-MM-dd')}else{'Never Set'})</td><td>$(Format-Age $_.LastLogonDate)</td></tr>"
}) -join "`n"

$HTML = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<title>Stale Account Report — $Domain</title>
<style>
  body{font-family:'Segoe UI',Arial,sans-serif;background:#f5f6fa;color:#333;margin:0;}
  .hdr{background:#2c3e50;color:white;padding:20px 32px;display:flex;justify-content:space-between;align-items:center;}
  .hdr h1{font-size:1.5em;margin:0;}
  .meta{font-size:.8em;opacity:.8;text-align:right;}
  .stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:16px;padding:24px 32px;}
  .stat{background:white;border-radius:8px;padding:18px;box-shadow:0 2px 8px rgba(0,0,0,.08);border-left:4px solid #2980b9;}
  .stat.warn{border-left-color:#f39c12;}.stat.crit{border-left-color:#e74c3c;}
  .stat .num{font-size:2em;font-weight:bold;color:#2c3e50;}.stat .lbl{font-size:.8em;color:#666;margin-top:4px;}
  .sec{background:white;margin:0 32px 20px;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,.08);overflow:hidden;}
  .sh{background:#2c3e50;color:white;padding:10px 20px;font-weight:600;}
  table{width:100%;border-collapse:collapse;font-size:.88em;}
  th{background:#f8f9fa;padding:9px 16px;text-align:left;border-bottom:2px solid #e0e0e0;font-weight:600;}
  td{padding:9px 16px;border-bottom:1px solid #f0f0f0;}tr:last-child td{border-bottom:none;}tr:hover td{background:#f8f9ff;}
  .badge{display:inline-block;padding:2px 9px;border-radius:12px;font-size:.76em;font-weight:600;}
  .badge-green{background:#d5f5e3;color:#1e8449;}.badge-yellow{background:#fef9e7;color:#9a7d0a;}
  .badge-red{background:#fadbd8;color:#922b21;}.footer{text-align:center;padding:20px;color:#888;font-size:.82em;}
  .note{padding:12px 20px;background:#fff8e1;border-left:4px solid #f39c12;font-size:.88em;}
</style></head><body>
<div class="hdr">
  <div><h1>🧹 Stale Account Report</h1><div style="margin-top:4px;opacity:.8">Domain: <strong>$Domain</strong></div></div>
  <div class="meta">Generated: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))<br>User threshold: ${UserStaleDays}d | Computer: ${ComputerStaleDays}d</div>
</div>
<div class="stats">
  <div class="stat $(if($staleUsers.Count -gt 50){'crit'}elseif($staleUsers.Count -gt 0){'warn'}else{''})">
    <div class="num">$($staleUsers.Count)</div><div class="lbl">Stale Users (${UserStaleDays}d+)</div></div>
  <div class="stat $(if($neverLoggedIn.Count -gt 0){'warn'}else{''})">
    <div class="num">$($neverLoggedIn.Count)</div><div class="lbl">Never Logged In (30d+)</div></div>
  <div class="stat $(if($staleComputers.Count -gt 20){'warn'}else{''})">
    <div class="num">$($staleComputers.Count)</div><div class="lbl">Stale Computers (${ComputerStaleDays}d+)</div></div>
  <div class="stat $(if($pwdNeverExpires.Count -gt 0){'warn'}else{''})">
    <div class="num">$($pwdNeverExpires.Count)</div><div class="lbl">Password Never Expires</div></div>
  <div class="stat"><div class="num">$($disabledUsers.Count)</div><div class="lbl">Disabled Accounts</div></div>
</div>
<div class="note">⚠️ This report is READ-ONLY. No accounts have been modified. Review with account owners before taking any cleanup action.</div>
<div class="sec"><div class="sh">👤 Stale User Accounts (Top 100 of $($staleUsers.Count))</div>
  <table><thead><tr><th>Name</th><th>Username</th><th>Department</th><th>Last Logon</th><th>Pwd Last Set</th><th>Manager</th></tr></thead>
  <tbody>$staleUserRows</tbody></table></div>
<div class="sec"><div class="sh">🖥️ Stale Computer Accounts (Top 100 of $($staleComputers.Count))</div>
  <table><thead><tr><th>Computer</th><th>OS</th><th>Last Logon</th><th>Created</th></tr></thead>
  <tbody>$staleCompRows</tbody></table></div>
<div class="sec"><div class="sh">🔑 Password Never Expires — Enabled Users ($($pwdNeverExpires.Count))</div>
  <table><thead><tr><th>Name</th><th>Username</th><th>Pwd Last Set</th><th>Last Logon</th></tr></thead>
  <tbody>$pwdNeverRows</tbody></table></div>
<div class="footer">Stale Account Report | Read-Only | $Domain | $(Get-Date -Format 'yyyy-MM-dd')</div>
</body></html>
"@

$HTML | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Report saved: $OutputPath" -ForegroundColor Green
Write-Host "  Stale Users: $($staleUsers.Count) | Stale Computers: $($staleComputers.Count) | Pwd Never Expires: $($pwdNeverExpires.Count)"
Start-Process $OutputPath
