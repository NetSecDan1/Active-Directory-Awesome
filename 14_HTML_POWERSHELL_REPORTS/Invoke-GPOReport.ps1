#Requires -Modules ActiveDirectory,GroupPolicy
<#
.SYNOPSIS
    Group Policy Inventory & Change Tracking Report — Read-Only, Rich HTML
.DESCRIPTION
    Comprehensive GPO inventory: all GPOs, link status, recent changes, unlinked GPOs,
    disabled GPOs, and WMI filter usage. Tracks changes over time.
    ALL operations are READ-ONLY.
.PARAMETER Domain
    Target domain (defaults to current domain)
.PARAMETER OutputPath
    HTML output path
.PARAMETER ChangedInDays
    Highlight GPOs modified in the last N days (default: 7)
.EXAMPLE
    .\Invoke-GPOReport.ps1
    .\Invoke-GPOReport.ps1 -ChangedInDays 30
#>
[CmdletBinding()]
param(
    [string]$Domain = (Get-ADDomain).DNSRoot,
    [string]$OutputPath = "$env:USERPROFILE\Desktop\GPOReport_$(Get-Date -Format 'yyyyMMdd-HHmmss').html",
    [int]$ChangedInDays = 7
)

$ErrorActionPreference = 'Continue'
$StartTime = Get-Date
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Collecting GPO data for: $Domain" -ForegroundColor Cyan

$cutoff = (Get-Date).AddDays(-$ChangedInDays)

# Collect all GPOs
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Enumerating GPOs..." -ForegroundColor Gray
$allGPOs = Get-GPO -All -Domain $Domain | Sort-Object DisplayName

# Categorize
$recentlyModified = @($allGPOs | Where-Object { $_.ModificationTime -gt $cutoff })
$disabledGPOs     = @($allGPOs | Where-Object { $_.GpoStatus -eq 'AllSettingsDisabled' })
$userDisabled     = @($allGPOs | Where-Object { $_.GpoStatus -eq 'UserSettingsDisabled' })
$computerDisabled = @($allGPOs | Where-Object { $_.GpoStatus -eq 'ComputerSettingsDisabled' })

# Get link status for each GPO
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking GPO links (may take a few minutes)..." -ForegroundColor Gray
$gpoLinks = @{}
$unlinkedGPOs = @()

foreach ($gpo in $allGPOs) {
    try {
        $xml = [xml](Get-GPOReport -Guid $gpo.Id -ReportType Xml -Domain $Domain -ErrorAction Stop)
        $links = $xml.GPO.LinksTo
        $gpoLinks[$gpo.Id.ToString()] = if ($links) { @($links) } else { @() }
        if (-not $links) { $unlinkedGPOs += $gpo }
    } catch {
        $gpoLinks[$gpo.Id.ToString()] = @()
    }
}

# WMI Filters
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Collecting WMI filters..." -ForegroundColor Gray
$wmiFilters = @()
try {
    $wmiFilters = Get-ADObject -SearchBase "CN=SOM,CN=WMIPolicy,CN=System,$(([adsi]"LDAP://$Domain").distinguishedName)" `
        -Filter { ObjectClass -eq 'msWMI-Som' } `
        -Properties Name, Description, 'msWMI-Parm2' -Server $Domain -ErrorAction SilentlyContinue
} catch { }

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Generating HTML..." -ForegroundColor Gray

# Build table rows
$allGPORows = ($allGPOs | ForEach-Object {
    $gpo = $_
    $links = $gpoLinks[$gpo.Id.ToString()]
    $linkCount = $links.Count
    $isRecent = $gpo.ModificationTime -gt $cutoff
    $recentBadge = if ($isRecent) { "<span class='badge badge-orange'>MODIFIED</span>" } else { "" }

    $statusColor = switch ($gpo.GpoStatus) {
        'AllSettingsEnabled'      { 'badge-green' }
        'AllSettingsDisabled'     { 'badge-red' }
        'UserSettingsDisabled'    { 'badge-yellow' }
        'ComputerSettingsDisabled'{ 'badge-yellow' }
        default                   { 'badge-green' }
    }
    $linkBadge = if ($linkCount -eq 0) { "<span class='badge badge-red'>Unlinked</span>" } else { "<span class='badge badge-green'>$linkCount link$(if($linkCount -ne 1){'s'})</span>" }

    "<tr$(if($isRecent){" class='recent-row'"})>
        <td>$($gpo.DisplayName)$recentBadge</td>
        <td>$($gpo.ModificationTime.ToString('yyyy-MM-dd HH:mm'))</td>
        <td><span class='badge $statusColor'>$($gpo.GpoStatus)</span></td>
        <td>$linkBadge</td>
        <td><small>$($gpo.Id)</small></td>
    </tr>"
}) -join "`n"

$recentRows = ($recentlyModified | Sort-Object ModificationTime -Descending | ForEach-Object {
    "<tr><td><strong>$($_.DisplayName)</strong></td><td>$($_.ModificationTime.ToString('yyyy-MM-dd HH:mm'))</td><td>$($_.GpoStatus)</td></tr>"
}) -join "`n"

$unlinkedRows = ($unlinkedGPOs | ForEach-Object {
    "<tr><td>$($_.DisplayName)</td><td>$($_.ModificationTime.ToString('yyyy-MM-dd'))</td><td>$($_.GpoStatus)</td></tr>"
}) -join "`n"

$wmiRows = if ($wmiFilters) {
    ($wmiFilters | ForEach-Object {
        "<tr><td>$($_.Name)</td><td>$($_.Description)</td></tr>"
    }) -join "`n"
} else { "<tr><td colspan='2'><em>No WMI filters found</em></td></tr>" }

$HTML = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<title>GPO Report — $Domain</title>
<style>
  body{font-family:'Segoe UI',Arial,sans-serif;background:#f5f6fa;color:#333;margin:0;}
  .hdr{background:#2c3e50;color:white;padding:20px 32px;display:flex;justify-content:space-between;align-items:center;}
  .hdr h1{font-size:1.5em;margin:0;}
  .stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:16px;padding:24px 32px;}
  .stat{background:white;border-radius:8px;padding:18px;box-shadow:0 2px 8px rgba(0,0,0,.08);border-left:4px solid #2980b9;}
  .stat.warn{border-left-color:#f39c12;}.stat.crit{border-left-color:#e74c3c;}.stat.ok{border-left-color:#27ae60;}
  .stat .num{font-size:2em;font-weight:bold;color:#2c3e50;}.stat .lbl{font-size:.8em;color:#666;margin-top:4px;}
  .sec{background:white;margin:0 32px 20px;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,.08);overflow:hidden;}
  .sh{background:#2c3e50;color:white;padding:10px 20px;font-weight:600;}
  table{width:100%;border-collapse:collapse;font-size:.86em;}
  th{background:#f8f9fa;padding:9px 16px;text-align:left;border-bottom:2px solid #ddd;font-weight:600;}
  td{padding:8px 16px;border-bottom:1px solid #f0f0f0;vertical-align:middle;}tr:last-child td{border-bottom:none;}
  tr:hover td{background:#f8f9ff;} .recent-row td{background:#fff8e1;}
  .badge{display:inline-block;padding:2px 8px;border-radius:12px;font-size:.75em;font-weight:600;margin-left:6px;}
  .badge-green{background:#d5f5e3;color:#1e8449;}.badge-yellow{background:#fef9e7;color:#9a7d0a;}
  .badge-orange{background:#fdebd0;color:#ca6f1e;}.badge-red{background:#fadbd8;color:#922b21;}
  .footer{text-align:center;padding:20px;color:#888;font-size:.82em;}
</style></head><body>
<div class="hdr">
  <div><h1>📋 Group Policy Report</h1><div style="margin-top:4px;opacity:.8">Domain: <strong>$Domain</strong> &nbsp;|&nbsp; Generated: $($StartTime.ToString('yyyy-MM-dd HH:mm'))</div></div>
  <div style="font-size:.8em;opacity:.8;text-align:right;color:white">Highlight window: ${ChangedInDays} days<br>Total GPOs: $($allGPOs.Count)</div>
</div>
<div class="stats">
  <div class="stat"><div class="num">$($allGPOs.Count)</div><div class="lbl">Total GPOs</div></div>
  <div class="stat $(if($recentlyModified.Count -gt 0){'warn'}else{'ok'})"><div class="num">$($recentlyModified.Count)</div><div class="lbl">Modified (${ChangedInDays}d)</div></div>
  <div class="stat $(if($unlinkedGPOs.Count -gt 0){'warn'}else{'ok'})"><div class="num">$($unlinkedGPOs.Count)</div><div class="lbl">Unlinked GPOs</div></div>
  <div class="stat $(if($disabledGPOs.Count -gt 0){'warn'}else{'ok'})"><div class="num">$($disabledGPOs.Count)</div><div class="lbl">Fully Disabled</div></div>
  <div class="stat"><div class="num">$($wmiFilters.Count)</div><div class="lbl">WMI Filters</div></div>
  <div class="stat"><div class="num">$(($userDisabled.Count + $computerDisabled.Count))</div><div class="lbl">Partially Disabled</div></div>
</div>
$(if($recentlyModified.Count -gt 0){
"<div class='sec'><div class='sh'>🕐 Recently Modified GPOs (last ${ChangedInDays} days — $($recentlyModified.Count))</div>
<table><thead><tr><th>GPO Name</th><th>Modified</th><th>Status</th></tr></thead><tbody>$recentRows</tbody></table></div>"
})
$(if($unlinkedGPOs.Count -gt 0){
"<div class='sec'><div class='sh'>⚠️ Unlinked GPOs — Not Applied Anywhere ($($unlinkedGPOs.Count))</div>
<table><thead><tr><th>GPO Name</th><th>Last Modified</th><th>Status</th></tr></thead><tbody>$unlinkedRows</tbody></table></div>"
})
<div class="sec"><div class="sh">📦 All GPOs ($($allGPOs.Count)) — Yellow rows = recently modified</div>
<table><thead><tr><th>GPO Name</th><th>Last Modified</th><th>Status</th><th>Links</th><th>GUID</th></tr></thead><tbody>$allGPORows</tbody></table></div>
<div class="sec"><div class="sh">🔍 WMI Filters ($($wmiFilters.Count))</div>
<table><thead><tr><th>Filter Name</th><th>Description</th></tr></thead><tbody>$wmiRows</tbody></table></div>
<div class="footer">GPO Report | Read-Only | $Domain | $(Get-Date -Format 'yyyy-MM-dd')</div>
</body></html>
"@

$HTML | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Report saved: $OutputPath" -ForegroundColor Green
Write-Host "  Total: $($allGPOs.Count) | Modified: $($recentlyModified.Count) | Unlinked: $($unlinkedGPOs.Count) | Disabled: $($disabledGPOs.Count)"
Start-Process $OutputPath
