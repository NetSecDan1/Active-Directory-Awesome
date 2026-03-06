#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Active Directory Security Posture Report — Read-Only, Executive HTML Dashboard
.DESCRIPTION
    Generates a CISO-ready security posture report across 7 identity security domains.
    Color-coded RAG status, risk score, and top recommendations.
    ALL operations are READ-ONLY. Safe for production use.
.PARAMETER Domain
    Target domain (defaults to current domain)
.PARAMETER OutputPath
    HTML output path
.EXAMPLE
    .\Invoke-ADSecurityPostureReport.ps1
    .\Invoke-ADSecurityPostureReport.ps1 -Domain corp.contoso.com
#>
[CmdletBinding()]
param(
    [string]$Domain = (Get-ADDomain).DNSRoot,
    [string]$OutputPath = "$env:USERPROFILE\Desktop\ADSecurityPosture_$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
)

$ErrorActionPreference = 'Continue'
$StartTime = Get-Date
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Collecting security posture data for: $Domain" -ForegroundColor Cyan

# ============================================================
# COLLECT SECURITY INDICATORS (ALL READ-ONLY)
# ============================================================

$Findings = @()
$Scores   = @{}

function Add-Finding($Domain, $Severity, $Control, $Detail, $Recommendation) {
    $script:Findings += [PSCustomObject]@{
        Severity       = $Severity
        Control        = $Control
        Detail         = $Detail
        Recommendation = $Recommendation
    }
}

# ----------------------------------------------------------
# DOMAIN 1: PRIVILEGED ACCESS MANAGEMENT
# ----------------------------------------------------------
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking privileged access..." -ForegroundColor Gray
$score1 = 100

$domainAdmins = Get-ADGroupMember "Domain Admins" -Recursive -Server $Domain -ErrorAction SilentlyContinue |
    Where-Object { $_.objectClass -eq 'user' }
$daCount = ($domainAdmins | Measure-Object).Count

if ($daCount -gt 5) {
    Add-Finding $Domain "HIGH" "Privileged Access" "Domain Admins has $daCount members (recommended: ≤5)" "Reduce Domain Admins membership — implement JIT access"
    $score1 -= [Math]::Min(40, ($daCount - 5) * 5)
}

# Check for stale Domain Admins
$staleDAs = $domainAdmins | ForEach-Object {
    Get-ADUser $_ -Properties LastLogonDate -Server $Domain -ErrorAction SilentlyContinue
} | Where-Object { $_.LastLogonDate -lt (Get-Date).AddDays(-90) -or $_.LastLogonDate -eq $null }

if ($staleDAs) {
    Add-Finding $Domain "MEDIUM" "Privileged Access" "$($staleDAs.Count) Domain Admin(s) have not logged in for 90+ days" "Review and remove stale privileged accounts"
    $score1 -= 20
}

# Check Protected Users group
$protectedUsers = Get-ADGroupMember "Protected Users" -Recursive -Server $Domain -ErrorAction SilentlyContinue
$puCount = ($protectedUsers | Measure-Object).Count
if ($puCount -eq 0) {
    Add-Finding $Domain "HIGH" "Privileged Access" "Protected Users group is empty — Tier 0 accounts are not hardened" "Add all Tier 0 accounts to Protected Users group"
    $score1 -= 30
}

$Scores["Privileged Access"] = @{Score=[Math]::Max(0,$score1); Members=$daCount; ProtectedUsers=$puCount; StaleDAs=($staleDAs | Measure-Object).Count}

# ----------------------------------------------------------
# DOMAIN 2: ACCOUNT SECURITY
# ----------------------------------------------------------
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking account security..." -ForegroundColor Gray
$score2 = 100

$pwdNeverExpires = (Get-ADUser -Filter {Enabled -eq $true -and PasswordNeverExpires -eq $true} -Server $Domain | Measure-Object).Count
if ($pwdNeverExpires -gt 10) {
    Add-Finding $Domain "MEDIUM" "Account Security" "$pwdNeverExpires enabled accounts have Password Never Expires set" "Audit and remove PasswordNeverExpires from non-service accounts"
    $score2 -= [Math]::Min(25, $pwdNeverExpires)
}

# Kerberoastable accounts (SPN + enabled + not computer)
$kerberoastable = Get-ADUser -Filter {Enabled -eq $true} -Server $Domain `
    -Properties ServicePrincipalName, PasswordLastSet |
    Where-Object { $_.ServicePrincipalName.Count -gt 0 }
$kerbCount = ($kerberoastable | Measure-Object).Count
if ($kerbCount -gt 0) {
    $weakPwd = $kerberoastable | Where-Object { $_.PasswordLastSet -lt (Get-Date).AddDays(-365) }
    Add-Finding $Domain "HIGH" "Account Security" "$kerbCount Kerberoastable service accounts found ($($weakPwd.Count) with password >1yr old)" "Use gMSA for service accounts; ensure strong passwords (20+ chars) on SPNs"
    $score2 -= [Math]::Min(30, $kerbCount * 5)
}

# AS-REP Roastable (pre-auth disabled)
$asrepRoastable = (Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true -and Enabled -eq $true} -Server $Domain | Measure-Object).Count
if ($asrepRoastable -gt 0) {
    Add-Finding $Domain "CRITICAL" "Account Security" "$asrepRoastable account(s) have Kerberos pre-authentication DISABLED (AS-REP Roastable)" "Enable Kerberos pre-authentication on all accounts unless specifically required"
    $score2 -= 40
}

$Scores["Account Security"] = @{Score=[Math]::Max(0,$score2); PwdNeverExpires=$pwdNeverExpires; Kerberoastable=$kerbCount; ASREPRoastable=$asrepRoastable}

# ----------------------------------------------------------
# DOMAIN 3: INFRASTRUCTURE HEALTH
# ----------------------------------------------------------
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking infrastructure health..." -ForegroundColor Gray
$score3 = 100

$replFails = (repadmin /showrepl * /errorsonly 2>&1 | Where-Object { $_ -match "error" } | Measure-Object).Count
if ($replFails -gt 0) {
    Add-Finding $Domain "HIGH" "Infrastructure" "Active replication failures detected" "Investigate and resolve per 13_RUNBOOKS/07-replication-recovery.md"
    $score3 -= 30
}

$offlineDCs = (Get-ADDomainController -Filter * -Server $Domain | Where-Object {
    -not (Test-Connection $_.HostName -Count 1 -Quiet -ErrorAction SilentlyContinue)
} | Measure-Object).Count
if ($offlineDCs -gt 0) {
    Add-Finding $Domain "CRITICAL" "Infrastructure" "$offlineDCs DC(s) unreachable" "Investigate immediately"
    $score3 -= 40
}

$Scores["Infrastructure"] = @{Score=[Math]::Max(0,$score3); ReplFails=$replFails; OfflineDCs=$offlineDCs}

# ----------------------------------------------------------
# DOMAIN 4: DELEGATION RISKS
# ----------------------------------------------------------
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking delegation configuration..." -ForegroundColor Gray
$score4 = 100

# Unconstrained delegation (highest risk — excludes DCs which legitimately have this)
$unconstrained = Get-ADComputer -Filter {TrustedForDelegation -eq $true} -Server $Domain -Properties TrustedForDelegation |
    Where-Object { $_.Name -notlike "*DC*" }
$unconstrainedCount = ($unconstrained | Measure-Object).Count
if ($unconstrainedCount -gt 0) {
    Add-Finding $Domain "CRITICAL" "Delegation" "$unconstrainedCount non-DC computer(s) have unconstrained Kerberos delegation" "Migrate to constrained or resource-based constrained delegation"
    $score4 -= 40
}

# User accounts with unconstrained delegation
$unconstrainedUsers = (Get-ADUser -Filter {TrustedForDelegation -eq $true -and Enabled -eq $true} -Server $Domain | Measure-Object).Count
if ($unconstrainedUsers -gt 0) {
    Add-Finding $Domain "CRITICAL" "Delegation" "$unconstrainedUsers user account(s) have unconstrained delegation" "Remove unconstrained delegation from all user accounts"
    $score4 -= 40
}

$Scores["Delegation"] = @{Score=[Math]::Max(0,$score4); UnconstrainedComputers=$unconstrainedCount; UnconstrainedUsers=$unconstrainedUsers}

# ----------------------------------------------------------
# DOMAIN 5: PASSWORD POLICY
# ----------------------------------------------------------
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking password policy..." -ForegroundColor Gray
$score5 = 100

$ddp = Get-ADDefaultDomainPasswordPolicy -Server $Domain
if ($ddp.MinPasswordLength -lt 12) {
    Add-Finding $Domain "HIGH" "Password Policy" "Default minimum password length is $($ddp.MinPasswordLength) characters (recommended: ≥14)" "Raise minimum password length to 14+ or enforce passphrase policy"
    $score5 -= 25
}
if ($ddp.LockoutThreshold -eq 0) {
    Add-Finding $Domain "HIGH" "Password Policy" "Account lockout is DISABLED in default domain policy" "Enable lockout policy (threshold: 5-10, duration: 15+ minutes)"
    $score5 -= 30
}
if ($ddp.MaxPasswordAge -gt [TimeSpan]::FromDays(365) -or $ddp.PasswordNeverExpires) {
    Add-Finding $Domain "MEDIUM" "Password Policy" "Password max age is too long or disabled" "Set password expiration (365 days max; consider NIST guidance)"
    $score5 -= 15
}

$Scores["Password Policy"] = @{
    Score=[Math]::Max(0,$score5)
    MinLength=$ddp.MinPasswordLength
    LockoutThreshold=$ddp.LockoutThreshold
    MaxAge=$ddp.MaxPasswordAge.Days
}

# ----------------------------------------------------------
# DOMAIN 6: AUDIT & MONITORING
# ----------------------------------------------------------
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking audit configuration..." -ForegroundColor Gray
$score6 = 70  # Start lower — monitoring is often a gap

$PDC = (Get-ADDomain -Server $Domain).PDCEmulator
try {
    $auditPol = auditpol /get /category:* 2>&1 | Out-String
    if ($auditPol -match "Account Logon.*No Auditing") {
        Add-Finding $Domain "HIGH" "Monitoring" "Account Logon events are not audited on DCs" "Enable Success+Failure audit for Account Logon in Default Domain Controllers Policy"
        $score6 -= 30
    }
    if ($auditPol -match "Account Management.*No Auditing") {
        Add-Finding $Domain "HIGH" "Monitoring" "Account Management events are not audited" "Enable Success+Failure audit for Account Management"
        $score6 -= 20
    }
} catch { }

$Scores["Audit & Monitoring"] = @{Score=[Math]::Max(0,$score6)}

# ----------------------------------------------------------
# DOMAIN 7: STALE OBJECTS
# ----------------------------------------------------------
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking for stale objects..." -ForegroundColor Gray
$score7 = 100

$staleUsers    = (Get-ADUser -Filter {Enabled -eq $true -and LastLogonDate -lt (Get-Date).AddDays(-90)} -Server $Domain -Properties LastLogonDate | Measure-Object).Count
$staleComputers= (Get-ADComputer -Filter {Enabled -eq $true -and LastLogonDate -lt (Get-Date).AddDays(-60)} -Server $Domain -Properties LastLogonDate | Measure-Object).Count

if ($staleUsers -gt 100) {
    Add-Finding $Domain "MEDIUM" "Stale Objects" "$staleUsers enabled user accounts inactive for 90+ days" "Run stale account cleanup process quarterly"
    $score7 -= 20
}
if ($staleComputers -gt 50) {
    Add-Finding $Domain "MEDIUM" "Stale Objects" "$staleComputers enabled computer accounts inactive for 60+ days" "Review and disable stale computer accounts"
    $score7 -= 15
}

$Scores["Stale Objects"] = @{Score=[Math]::Max(0,$score7); StaleUsers=$staleUsers; StaleComputers=$staleComputers}

# ============================================================
# OVERALL RISK SCORE
# ============================================================
$overallScore = [int](($Scores.Values | ForEach-Object { $_.Score } | Measure-Object -Average).Average)
$criticalCount = ($Findings | Where-Object { $_.Severity -eq 'CRITICAL' } | Measure-Object).Count
$highCount     = ($Findings | Where-Object { $_.Severity -eq 'HIGH'     } | Measure-Object).Count
$medCount      = ($Findings | Where-Object { $_.Severity -eq 'MEDIUM'   } | Measure-Object).Count

# ============================================================
# HTML GENERATION
# ============================================================
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Generating HTML report..." -ForegroundColor Gray

function Get-RAG($score) {
    if ($score -ge 80) { return @{Label="LOW RISK"; Class="rag-green"; Icon="✅"} }
    elseif ($score -ge 55) { return @{Label="MEDIUM RISK"; Class="rag-amber"; Icon="⚠️"} }
    else { return @{Label="HIGH RISK"; Class="rag-red"; Icon="🔴"} }
}

$scoreColor = if ($overallScore -ge 80) { '#27ae60' } elseif ($overallScore -ge 55) { '#f39c12' } else { '#e74c3c' }

$domainRows = ($Scores.GetEnumerator() | ForEach-Object {
    $rag = Get-RAG $_.Value.Score
    "<tr><td><strong>$($_.Key)</strong></td><td class='$($rag.Class)'>$($rag.Icon) $($rag.Label)</td><td>$($_.Value.Score)/100</td></tr>"
}) -join "`n"

$findingRows = ($Findings | Sort-Object @{E={switch($_.Severity){'CRITICAL'{0}'HIGH'{1}'MEDIUM'{2}default{3}}}}, Control | ForEach-Object {
    $sevClass = switch ($_.Severity) { 'CRITICAL' { 'sev-critical' } 'HIGH' { 'sev-high' } 'MEDIUM' { 'sev-medium' } default { 'sev-low' } }
    "<tr><td><span class='sev $sevClass'>$($_.Severity)</span></td><td>$($_.Control)</td><td>$($_.Detail)</td><td>$($_.Recommendation)</td></tr>"
}) -join "`n"

$HTML = @"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<title>AD Security Posture — $Domain</title>
<style>
  body{font-family:'Segoe UI',Arial,sans-serif;background:#f5f6fa;color:#333;margin:0;}
  .hdr{background:#1a252f;color:white;padding:22px 32px;display:flex;justify-content:space-between;align-items:center;}
  .hdr h1{font-size:1.5em;margin:0;}
  .risk-score{width:90px;height:90px;border-radius:50%;background:$scoreColor;color:white;display:flex;align-items:center;justify-content:center;font-size:1.9em;font-weight:bold;flex-shrink:0;}
  .stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:16px;padding:24px 32px;}
  .stat{background:white;border-radius:8px;padding:18px;box-shadow:0 2px 8px rgba(0,0,0,.08);border-left:4px solid #c0392b;}
  .stat.ok{border-left-color:#27ae60;}.stat.warn{border-left-color:#f39c12;}
  .stat .num{font-size:2em;font-weight:bold;color:#1a252f;}.stat .lbl{font-size:.8em;color:#666;margin-top:4px;}
  .sec{background:white;margin:0 32px 20px;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,.08);overflow:hidden;}
  .sh{background:#1a252f;color:white;padding:10px 20px;font-weight:600;}
  table{width:100%;border-collapse:collapse;font-size:.88em;}
  th{background:#f8f9fa;padding:9px 16px;text-align:left;border-bottom:2px solid #ddd;font-weight:600;}
  td{padding:9px 16px;border-bottom:1px solid #f0f0f0;vertical-align:middle;}tr:last-child td{border-bottom:none;}tr:hover td{background:#f8f9ff;}
  .rag-green{color:#1e8449;font-weight:600;}.rag-amber{color:#9a6e0a;font-weight:600;}.rag-red{color:#922b21;font-weight:600;}
  .sev{display:inline-block;padding:2px 9px;border-radius:12px;font-size:.76em;font-weight:700;}
  .sev-critical{background:#922b21;color:white;}.sev-high{background:#ca6f1e;color:white;}
  .sev-medium{background:#9a7d0a;color:white;}.sev-low{background:#1e8449;color:white;}
  .footer{text-align:center;padding:20px;color:#888;font-size:.82em;}
  .meta{font-size:.8em;opacity:.8;text-align:right;}
</style></head><body>
<div class="hdr">
  <div><h1>🛡️ Active Directory Security Posture</h1><div style="margin-top:4px;opacity:.8">Domain: <strong>$Domain</strong> &nbsp;|&nbsp; Generated: $($StartTime.ToString('yyyy-MM-dd HH:mm'))</div></div>
  <div style="display:flex;gap:20px;align-items:center">
    <div class="meta" style="text-align:right;color:white;opacity:.8">$criticalCount Critical &nbsp;|&nbsp; $highCount High &nbsp;|&nbsp; $medCount Medium<br>$($Findings.Count) total findings</div>
    <div class="risk-score" title="Security Score (100=perfect)">$overallScore</div>
  </div>
</div>
<div class="stats">
  <div class="stat $(if($criticalCount -gt 0){''}else{'ok'})"><div class="num">$criticalCount</div><div class="lbl">🔴 Critical Findings</div></div>
  <div class="stat $(if($highCount -gt 0){'warn'}else{'ok'})"><div class="num">$highCount</div><div class="lbl">🟠 High Findings</div></div>
  <div class="stat ok"><div class="num">$medCount</div><div class="lbl">🟡 Medium Findings</div></div>
  <div class="stat $(if($Scores['Privileged Access'].Members -gt 5){'warn'}else{'ok'})">
    <div class="num">$($Scores['Privileged Access'].Members)</div><div class="lbl">Domain Admin Members</div></div>
  <div class="stat $(if($Scores['Account Security'].Kerberoastable -gt 0){'warn'}else{'ok'})">
    <div class="num">$($Scores['Account Security'].Kerberoastable)</div><div class="lbl">Kerberoastable Accounts</div></div>
  <div class="stat $(if($Scores['Account Security'].ASREPRoastable -gt 0){''}else{'ok'})">
    <div class="num">$($Scores['Account Security'].ASREPRoastable)</div><div class="lbl">AS-REP Roastable</div></div>
</div>
<div class="sec"><div class="sh">📊 Security Domain Summary (RAG Status)</div>
<table><thead><tr><th>Security Domain</th><th>Risk Level</th><th>Score</th></tr></thead><tbody>$domainRows</tbody></table></div>
<div class="sec"><div class="sh">⚠️ All Findings ($($Findings.Count)) — Sorted by Severity</div>
<table><thead><tr><th>Severity</th><th>Control Area</th><th>Finding</th><th>Recommendation</th></tr></thead><tbody>$findingRows</tbody></table></div>
<div class="footer">AD Security Posture Report | Read-Only Assessment | $Domain | $(Get-Date -Format 'yyyy-MM-dd')<br>
<small>Score reflects current configuration state. Consult security team for remediation prioritization.</small></div>
</body></html>
"@

$HTML | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Report saved: $OutputPath" -ForegroundColor Green
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Security Score: $overallScore/100 | Critical: $criticalCount | High: $highCount | Medium: $medCount" `
    -ForegroundColor $(if($criticalCount -gt 0){'Red'}elseif($highCount -gt 0){'Yellow'}else{'Green'})
Start-Process $OutputPath
