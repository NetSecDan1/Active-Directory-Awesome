#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Privileged Access Membership Report — Read-Only, Rich HTML Output
.DESCRIPTION
    Reports on all privileged group memberships in Active Directory.
    Highlights: new members, stale members, nested groups, service accounts in admin groups.
    ALL operations are READ-ONLY. Safe for daily production execution.
.PARAMETER Domain
    Target domain (defaults to current domain)
.PARAMETER OutputPath
    HTML output file path
.PARAMETER AlertOnNewMembers
    If set, highlights accounts added in the last N days (default: 7)
.EXAMPLE
    .\Invoke-PrivilegedAccessReport.ps1
    .\Invoke-PrivilegedAccessReport.ps1 -Domain corp.contoso.com -AlertOnNewMembers 30
#>
[CmdletBinding()]
param(
    [string]$Domain = (Get-ADDomain).DNSRoot,
    [string]$OutputPath = "$env:USERPROFILE\Desktop\PrivilegedAccess_$(Get-Date -Format 'yyyyMMdd-HHmmss').html",
    [int]$AlertOnNewMembers = 7,
    [int]$StaleThresholdDays = 90
)

$ErrorActionPreference = 'Continue'
$StartTime = Get-Date
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Collecting privileged access data for: $Domain" -ForegroundColor Cyan

# Tier 0 groups — highest privilege
$Tier0Groups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Administrators",
    "Group Policy Creator Owners",
    "DNSAdmins"
)

# Tier 1 groups — elevated privilege
$Tier1Groups = @(
    "Account Operators",
    "Backup Operators",
    "Print Operators",
    "Server Operators",
    "Remote Desktop Users",
    "Network Configuration Operators"
)

$staleDate    = (Get-Date).AddDays(-$StaleThresholdDays)
$newMemberDate = (Get-Date).AddDays(-$AlertOnNewMembers)
$allFindings  = @()
$groupData    = @()

foreach ($groupName in ($Tier0Groups + $Tier1Groups)) {
    $tier = if ($groupName -in $Tier0Groups) { "Tier 0" } else { "Tier 1" }
    try {
        $group = Get-ADGroup -Identity $groupName -Server $Domain -ErrorAction Stop
        $members = Get-ADGroupMember -Identity $groupName -Server $Domain -Recursive -ErrorAction Stop

        $memberDetails = foreach ($m in $members) {
            if ($m.objectClass -eq 'user') {
                $user = Get-ADUser $m -Server $Domain -Properties LastLogonDate, PasswordLastSet,
                        Enabled, WhenCreated, adminCount, ServicePrincipalName -ErrorAction SilentlyContinue
                if ($user) {
                    $isNew   = $user.WhenCreated -gt $newMemberDate
                    $isStale = $user.LastLogonDate -lt $staleDate -and $user.LastLogonDate -ne $null
                    $isSvc   = $user.ServicePrincipalName.Count -gt 0 -or $user.SamAccountName -like "svc*"

                    if ($isNew)   { $allFindings += "NEW MEMBER: $($user.SamAccountName) added to $groupName" }
                    if ($isStale) { $allFindings += "STALE MEMBER: $($user.SamAccountName) in $groupName — last logon $($user.LastLogonDate)" }
                    if ($isSvc)   { $allFindings += "SERVICE ACCOUNT: $($user.SamAccountName) is a member of $groupName" }

                    [PSCustomObject]@{
                        Group         = $groupName
                        Tier          = $tier
                        SamAccount    = $user.SamAccountName
                        Type          = "User"
                        Enabled       = $user.Enabled
                        LastLogon     = $user.LastLogonDate
                        PwdLastSet    = $user.PasswordLastSet
                        WhenCreated   = $user.WhenCreated
                        IsNew         = $isNew
                        IsStale       = $isStale
                        IsServiceAcct = $isSvc
                        AdminCount    = $user.adminCount
                    }
                }
            } elseif ($m.objectClass -eq 'computer') {
                [PSCustomObject]@{
                    Group=''; Tier=$tier; SamAccount=$m.SamAccountName; Type="Computer"
                    Enabled=$null; LastLogon=$null; PwdLastSet=$null; WhenCreated=$null
                    IsNew=$false; IsStale=$false; IsServiceAcct=$false; AdminCount=0
                }
            }
        }

        $groupData += [PSCustomObject]@{
            GroupName   = $groupName
            Tier        = $tier
            MemberCount = ($memberDetails | Where-Object { $_.Type -eq 'User' }).Count
            Members     = $memberDetails
            NewMembers  = ($memberDetails | Where-Object { $_.IsNew }).Count
            StaleMembers= ($memberDetails | Where-Object { $_.IsStale }).Count
            SvcAccounts = ($memberDetails | Where-Object { $_.IsServiceAcct }).Count
        }
    } catch {
        Write-Warning "Could not query group '$groupName': $_"
        $groupData += [PSCustomObject]@{
            GroupName=$groupName; Tier=$tier; MemberCount=0; Members=@()
            NewMembers=0; StaleMembers=0; SvcAccounts=0
        }
    }
}

# Generate HTML
$totalPrivUsers = ($groupData | ForEach-Object { $_.Members } |
    Where-Object { $_.Type -eq 'User' } | Select-Object -ExpandProperty SamAccount -Unique).Count
$totalFindings  = $allFindings.Count

$findingRows = if ($allFindings) {
    ($allFindings | ForEach-Object {
        $cls = if ($_ -like "NEW*") { "badge-orange" } elseif ($_ -like "STALE*") { "badge-yellow" } else { "badge-red" }
        "<tr><td><span class='badge $cls'>$(($_ -split ':')[0])</span></td><td>$($_ -split ': ',2 | Select-Object -Last 1)</td></tr>"
    }) -join "`n"
} else {
    "<tr><td colspan='2'><span class='badge badge-green'>✓ No findings</span></td></tr>"
}

$groupTableRows = ($groupData | ForEach-Object {
    $tierClass = if ($_.Tier -eq "Tier 0") { "badge-red" } else { "badge-orange" }
    $newBadge   = if ($_.NewMembers -gt 0)   { "<span class='badge badge-orange'>$($_.NewMembers) new</span>" } else { "" }
    $staleBadge = if ($_.StaleMembers -gt 0) { "<span class='badge badge-yellow'>$($_.StaleMembers) stale</span>" } else { "" }
    $svcBadge   = if ($_.SvcAccounts -gt 0)  { "<span class='badge badge-red'>$($_.SvcAccounts) svc</span>" } else { "" }
    "<tr><td><strong>$($_.GroupName)</strong></td><td><span class='badge $tierClass'>$($_.Tier)</span></td><td>$($_.MemberCount)</td><td>$newBadge $staleBadge $svcBadge</td></tr>"
}) -join "`n"

$memberRows = ($groupData | ForEach-Object {
    $grp = $_.GroupName
    $_.Members | Where-Object { $_.Type -eq 'User' } | ForEach-Object {
        $flags = @()
        if ($_.IsNew)         { $flags += "<span class='badge badge-orange'>NEW</span>" }
        if ($_.IsStale)       { $flags += "<span class='badge badge-yellow'>STALE</span>" }
        if ($_.IsServiceAcct) { $flags += "<span class='badge badge-red'>SVC ACCT</span>" }
        if (-not $_.Enabled)  { $flags += "<span class='badge badge-red'>DISABLED</span>" }
        $flagStr = if ($flags) { $flags -join " " } else { "<span class='badge badge-green'>✓</span>" }
        $lastLogon = if ($_.LastLogon) { $_.LastLogon.ToString("yyyy-MM-dd") } else { "<em>Never</em>" }
        "<tr><td>$($_.SamAccount)</td><td>$grp</td><td>$(($_.Tier))</td><td>$lastLogon</td><td>$flagStr</td></tr>"
    }
}) -join "`n"

$HTML = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<title>Privileged Access Report — $Domain</title>
<style>
  body { font-family: 'Segoe UI',Arial,sans-serif; background:#f5f6fa; color:#333; margin:0; }
  .header { background:#2c3e50; color:white; padding:20px 32px; display:flex; justify-content:space-between; align-items:center; }
  .header h1 { font-size:1.5em; margin:0; }
  .meta { font-size:.8em; opacity:.8; text-align:right; }
  .stats { display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:16px; padding:24px 32px; }
  .stat { background:white; border-radius:8px; padding:20px; box-shadow:0 2px 8px rgba(0,0,0,.08); border-left:4px solid #2980b9; }
  .stat.warn { border-left-color:#f39c12; }
  .stat.crit { border-left-color:#e74c3c; }
  .stat .num { font-size:2em; font-weight:bold; color:#2c3e50; }
  .stat .lbl { font-size:.8em; color:#666; margin-top:4px; }
  .section { background:white; margin:0 32px 20px; border-radius:8px; box-shadow:0 2px 8px rgba(0,0,0,.08); overflow:hidden; }
  .sh { background:#2c3e50; color:white; padding:10px 20px; font-weight:600; }
  table { width:100%; border-collapse:collapse; font-size:.88em; }
  th { background:#f8f9fa; padding:9px 16px; text-align:left; border-bottom:2px solid #e0e0e0; font-weight:600; }
  td { padding:9px 16px; border-bottom:1px solid #f0f0f0; vertical-align:middle; }
  tr:last-child td { border-bottom:none; }
  tr:hover td { background:#f8f9ff; }
  .badge { display:inline-block; padding:2px 9px; border-radius:12px; font-size:.76em; font-weight:600; }
  .badge-green  { background:#d5f5e3; color:#1e8449; }
  .badge-yellow { background:#fef9e7; color:#9a7d0a; }
  .badge-orange { background:#fdebd0; color:#ca6f1e; }
  .badge-red    { background:#fadbd8; color:#922b21; }
  .footer { text-align:center; padding:20px; color:#888; font-size:.82em; }
</style></head><body>
<div class="header">
  <div><h1>🔐 Privileged Access Report</h1><div style="margin-top:4px;opacity:.8">Domain: <strong>$Domain</strong></div></div>
  <div class="meta">Generated: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))<br>Collector: $env:USERNAME<br>Alert window: $AlertOnNewMembers days</div>
</div>
<div class="stats">
  <div class="stat $(if($totalFindings -gt 0){'crit'}else{''})">
    <div class="num">$totalFindings</div><div class="lbl">Total Findings</div>
  </div>
  <div class="stat">
    <div class="num">$totalPrivUsers</div><div class="lbl">Unique Privileged Users</div>
  </div>
  <div class="stat $(if(($groupData|Where-Object{$_.NewMembers -gt 0}).Count -gt 0){'warn'}else{''})">
    <div class="num">$(($groupData|ForEach-Object{$_.NewMembers}|Measure-Object -Sum).Sum)</div><div class="lbl">New Members (${AlertOnNewMembers}d)</div>
  </div>
  <div class="stat $(if(($groupData|Where-Object{$_.StaleMembers -gt 0}).Count -gt 0){'warn'}else{''})">
    <div class="num">$(($groupData|ForEach-Object{$_.StaleMembers}|Measure-Object -Sum).Sum)</div><div class="lbl">Stale Members (${StaleThresholdDays}d)</div>
  </div>
</div>
<div class="section"><div class="sh">⚠️ Findings ($totalFindings)</div>
  <table><thead><tr><th>Type</th><th>Detail</th></tr></thead><tbody>$findingRows</tbody></table>
</div>
<div class="section"><div class="sh">👥 Privileged Group Summary</div>
  <table><thead><tr><th>Group</th><th>Tier</th><th>Members</th><th>Flags</th></tr></thead><tbody>$groupTableRows</tbody></table>
</div>
<div class="section"><div class="sh">📋 All Privileged Members</div>
  <table><thead><tr><th>Account</th><th>Group</th><th>Tier</th><th>Last Logon</th><th>Status</th></tr></thead><tbody>$memberRows</tbody></table>
</div>
<div class="footer">Privileged Access Report | Read-Only | $Domain | $(Get-Date -Format 'yyyy-MM-dd')</div>
</body></html>
"@

$HTML | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Report saved: $OutputPath" -ForegroundColor Green
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Findings: $totalFindings | Privileged Users: $totalPrivUsers" -ForegroundColor $(if($totalFindings -gt 0){'Yellow'}else{'Green'})
Start-Process $OutputPath
