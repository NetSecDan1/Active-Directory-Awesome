# HTML Report Generation for Identity Operations

## System Prompt

```
You are an expert in creating professional, executive-ready HTML reports for identity
and Active Directory operations. Your role is to help engineers generate clear,
actionable reports that communicate technical findings to both technical and
non-technical stakeholders.

CORE PRINCIPLES:
1. Executive summary first - lead with business impact
2. Visual hierarchy - make critical items stand out
3. Actionable findings - every issue should have a remediation
4. Evidence-based - include data to support conclusions
5. Accessible - readable on screen and printable

REPORT AUDIENCE LEVELS:
- EXECUTIVE: High-level impact, risk scores, trend charts
- TECHNICAL: Detailed findings, commands, configuration
- AUDIT: Compliance mapping, evidence, timestamps
```

---

## Part 1: Report Templates

### Identity Health Assessment Report

```powershell
<#
.SYNOPSIS
    Generate comprehensive Identity Health Assessment HTML report
.DESCRIPTION
    Creates an executive-ready HTML report with identity health metrics,
    risk scores, and remediation recommendations
.PARAMETER OutputPath
    Path for the generated report
.PARAMETER IncludeTechnicalDetails
    Include detailed technical appendix
#>

function New-IdentityHealthReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeTechnicalDetails,

        [Parameter(Mandatory = $false)]
        [string]$ReportTitle = "Identity Health Assessment"
    )

    # ========================================================================
    # HTML TEMPLATE
    # ========================================================================

    $htmlTemplate = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{TITLE}}</title>
    <style>
        :root {
            --primary-color: #0078d4;
            --success-color: #107c10;
            --warning-color: #ffb900;
            --danger-color: #d13438;
            --neutral-color: #605e5c;
            --background-color: #faf9f8;
            --card-background: #ffffff;
            --border-color: #edebe9;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
            line-height: 1.6;
            color: #323130;
            background-color: var(--background-color);
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        /* Header */
        .report-header {
            background: linear-gradient(135deg, var(--primary-color), #106ebe);
            color: white;
            padding: 40px;
            border-radius: 8px;
            margin-bottom: 30px;
        }

        .report-header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
        }

        .report-meta {
            display: flex;
            gap: 30px;
            margin-top: 20px;
            opacity: 0.9;
        }

        .report-meta span {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* Score Cards */
        .score-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .score-card {
            background: var(--card-background);
            border-radius: 8px;
            padding: 25px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            border-left: 4px solid var(--primary-color);
        }

        .score-card.critical { border-left-color: var(--danger-color); }
        .score-card.warning { border-left-color: var(--warning-color); }
        .score-card.healthy { border-left-color: var(--success-color); }

        .score-card h3 {
            color: var(--neutral-color);
            font-size: 0.9rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 10px;
        }

        .score-value {
            font-size: 2.5rem;
            font-weight: 600;
            color: #323130;
        }

        .score-label {
            color: var(--neutral-color);
            font-size: 0.9rem;
            margin-top: 5px;
        }

        /* Section */
        .section {
            background: var(--card-background);
            border-radius: 8px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .section h2 {
            color: var(--primary-color);
            font-size: 1.5rem;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--border-color);
        }

        /* Tables */
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }

        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid var(--border-color);
        }

        th {
            background-color: var(--background-color);
            font-weight: 600;
            color: var(--neutral-color);
            text-transform: uppercase;
            font-size: 0.8rem;
            letter-spacing: 0.5px;
        }

        tr:hover {
            background-color: var(--background-color);
        }

        /* Status Badges */
        .badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 500;
        }

        .badge-critical {
            background-color: #fde7e9;
            color: var(--danger-color);
        }

        .badge-warning {
            background-color: #fff4ce;
            color: #8a6914;
        }

        .badge-success {
            background-color: #dff6dd;
            color: var(--success-color);
        }

        .badge-info {
            background-color: #cfe2ff;
            color: var(--primary-color);
        }

        /* Findings */
        .finding {
            border: 1px solid var(--border-color);
            border-radius: 8px;
            margin-bottom: 15px;
            overflow: hidden;
        }

        .finding-header {
            padding: 15px 20px;
            background-color: var(--background-color);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .finding-header.critical { background-color: #fde7e9; }
        .finding-header.warning { background-color: #fff4ce; }

        .finding-title {
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .finding-body {
            padding: 20px;
        }

        .finding-body p {
            margin-bottom: 15px;
        }

        .remediation {
            background-color: var(--background-color);
            border-left: 4px solid var(--success-color);
            padding: 15px;
            margin-top: 15px;
        }

        .remediation h4 {
            color: var(--success-color);
            margin-bottom: 10px;
        }

        /* Code Blocks */
        code {
            background-color: #f4f4f4;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 0.9em;
        }

        pre {
            background-color: #1e1e1e;
            color: #d4d4d4;
            padding: 20px;
            border-radius: 8px;
            overflow-x: auto;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 0.9rem;
            line-height: 1.5;
        }

        /* Charts placeholder */
        .chart-container {
            background: var(--background-color);
            border-radius: 8px;
            padding: 20px;
            min-height: 300px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--neutral-color);
        }

        /* Print styles */
        @media print {
            body { background: white; }
            .container { max-width: none; }
            .section { break-inside: avoid; box-shadow: none; border: 1px solid #ddd; }
            .report-header { background: var(--primary-color); }
        }

        /* Footer */
        .report-footer {
            text-align: center;
            padding: 30px;
            color: var(--neutral-color);
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <header class="report-header">
            <h1>{{TITLE}}</h1>
            <p>{{SUBTITLE}}</p>
            <div class="report-meta">
                <span>📅 Generated: {{DATE}}</span>
                <span>🏢 Organization: {{ORG}}</span>
                <span>👤 Prepared by: {{AUTHOR}}</span>
            </div>
        </header>

        <!-- Executive Summary Score Cards -->
        <div class="score-grid">
            {{SCORE_CARDS}}
        </div>

        <!-- Sections -->
        {{SECTIONS}}

        <!-- Footer -->
        <footer class="report-footer">
            <p>Report generated by Identity Health Assessment Tool v1.0</p>
            <p>Confidential - Internal Use Only</p>
        </footer>
    </div>
</body>
</html>
"@

    # ========================================================================
    # DATA COLLECTION
    # ========================================================================

    Write-Host "Collecting identity health data..." -ForegroundColor Cyan

    # Collect metrics (replace with actual data collection)
    $metrics = @{
        OverallScore = 72
        PasswordHealth = 68
        PrivilegedAccounts = 85
        StaleAccounts = 45
        MFACoverage = 78
        SyncHealth = 95
    }

    # ========================================================================
    # BUILD SCORE CARDS
    # ========================================================================

    function Get-ScoreCardClass {
        param([int]$Score)
        if ($Score -lt 50) { return "critical" }
        if ($Score -lt 75) { return "warning" }
        return "healthy"
    }

    $scoreCards = @"
        <div class="score-card $(Get-ScoreCardClass $metrics.OverallScore)">
            <h3>Overall Identity Health</h3>
            <div class="score-value">$($metrics.OverallScore)%</div>
            <div class="score-label">Composite Score</div>
        </div>
        <div class="score-card $(Get-ScoreCardClass $metrics.PasswordHealth)">
            <h3>Password Health</h3>
            <div class="score-value">$($metrics.PasswordHealth)%</div>
            <div class="score-label">Compliance Rate</div>
        </div>
        <div class="score-card $(Get-ScoreCardClass $metrics.PrivilegedAccounts)">
            <h3>Privileged Access</h3>
            <div class="score-value">$($metrics.PrivilegedAccounts)%</div>
            <div class="score-label">Security Score</div>
        </div>
        <div class="score-card $(Get-ScoreCardClass $metrics.MFACoverage)">
            <h3>MFA Coverage</h3>
            <div class="score-value">$($metrics.MFACoverage)%</div>
            <div class="score-label">Enrolled Users</div>
        </div>
"@

    # ========================================================================
    # BUILD SECTIONS
    # ========================================================================

    $sections = @"
        <!-- Executive Summary -->
        <div class="section">
            <h2>📊 Executive Summary</h2>
            <p>This assessment evaluated the identity infrastructure across Active Directory and Entra ID environments.
            Key findings indicate <strong>moderate risk</strong> requiring attention in password policies and stale account management.</p>

            <h3 style="margin-top: 20px;">Key Findings</h3>
            <ul style="margin: 15px 0; padding-left: 20px;">
                <li><strong>32%</strong> of accounts have passwords older than 90 days</li>
                <li><strong>156</strong> accounts identified as stale (no login in 90+ days)</li>
                <li><strong>12</strong> service accounts with excessive privileges</li>
                <li><strong>22%</strong> of privileged users lack MFA enrollment</li>
            </ul>

            <h3 style="margin-top: 20px;">Immediate Actions Required</h3>
            <table>
                <thead>
                    <tr>
                        <th>Priority</th>
                        <th>Action</th>
                        <th>Risk Reduction</th>
                        <th>Effort</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><span class="badge badge-critical">Critical</span></td>
                        <td>Enable MFA for all privileged accounts</td>
                        <td>High</td>
                        <td>1-2 days</td>
                    </tr>
                    <tr>
                        <td><span class="badge badge-critical">Critical</span></td>
                        <td>Disable 156 stale accounts</td>
                        <td>High</td>
                        <td>1 day</td>
                    </tr>
                    <tr>
                        <td><span class="badge badge-warning">High</span></td>
                        <td>Review service account permissions</td>
                        <td>Medium</td>
                        <td>3-5 days</td>
                    </tr>
                    <tr>
                        <td><span class="badge badge-warning">High</span></td>
                        <td>Implement password age policy</td>
                        <td>Medium</td>
                        <td>2-3 days</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Critical Findings -->
        <div class="section">
            <h2>🚨 Critical Findings</h2>

            <div class="finding">
                <div class="finding-header critical">
                    <div class="finding-title">
                        <span class="badge badge-critical">Critical</span>
                        Privileged Accounts Without MFA
                    </div>
                    <span>Found: 8 accounts</span>
                </div>
                <div class="finding-body">
                    <p><strong>Risk:</strong> Accounts with elevated privileges that are not protected by multi-factor
                    authentication are highly vulnerable to credential theft attacks including phishing and password spray.</p>

                    <table>
                        <thead>
                            <tr><th>Account</th><th>Privileged Group</th><th>Last Login</th></tr>
                        </thead>
                        <tbody>
                            <tr><td>admin.jsmith</td><td>Domain Admins</td><td>2024-01-15</td></tr>
                            <tr><td>svc_backup</td><td>Backup Operators</td><td>2024-01-14</td></tr>
                            <tr><td>admin.mwilson</td><td>Enterprise Admins</td><td>2024-01-10</td></tr>
                        </tbody>
                    </table>

                    <div class="remediation">
                        <h4>✅ Remediation</h4>
                        <p>1. Enable MFA enforcement for all privileged accounts via Conditional Access</p>
                        <p>2. Require phishing-resistant MFA methods (FIDO2, Windows Hello)</p>
                        <pre># Verify MFA registration status
Get-MgUser -UserId "admin.jsmith@contoso.com" -Property AuthenticationMethods</pre>
                    </div>
                </div>
            </div>

            <div class="finding">
                <div class="finding-header critical">
                    <div class="finding-title">
                        <span class="badge badge-critical">Critical</span>
                        Stale Privileged Accounts
                    </div>
                    <span>Found: 3 accounts</span>
                </div>
                <div class="finding-body">
                    <p><strong>Risk:</strong> Privileged accounts that have not been used in over 90 days but remain
                    enabled present a significant attack surface for credential compromise.</p>

                    <div class="remediation">
                        <h4>✅ Remediation</h4>
                        <p>Immediately disable these accounts and investigate with account owners:</p>
                        <pre># Disable stale privileged account
Disable-ADAccount -Identity "old.admin"
Set-ADUser -Identity "old.admin" -Description "Disabled $(Get-Date) - Stale privileged account"</pre>
                    </div>
                </div>
            </div>
        </div>

        <!-- Password Health Section -->
        <div class="section">
            <h2>🔐 Password Health Analysis</h2>

            <table>
                <thead>
                    <tr>
                        <th>Metric</th>
                        <th>Value</th>
                        <th>Threshold</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Accounts with expired passwords</td>
                        <td>234</td>
                        <td>&lt; 50</td>
                        <td><span class="badge badge-critical">Critical</span></td>
                    </tr>
                    <tr>
                        <td>Passwords older than 90 days</td>
                        <td>1,247</td>
                        <td>&lt; 500</td>
                        <td><span class="badge badge-warning">Warning</span></td>
                    </tr>
                    <tr>
                        <td>Accounts with "Password Never Expires"</td>
                        <td>89</td>
                        <td>&lt; 20</td>
                        <td><span class="badge badge-warning">Warning</span></td>
                    </tr>
                    <tr>
                        <td>Accounts meeting complexity requirements</td>
                        <td>98.5%</td>
                        <td>&gt; 99%</td>
                        <td><span class="badge badge-success">Good</span></td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Recommendations -->
        <div class="section">
            <h2>📋 Prioritized Recommendations</h2>

            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Recommendation</th>
                        <th>Priority</th>
                        <th>Complexity</th>
                        <th>Timeline</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>1</td>
                        <td>Enforce MFA for all administrative accounts</td>
                        <td><span class="badge badge-critical">Critical</span></td>
                        <td>Low</td>
                        <td>Immediate</td>
                    </tr>
                    <tr>
                        <td>2</td>
                        <td>Disable all stale accounts (90+ days inactive)</td>
                        <td><span class="badge badge-critical">Critical</span></td>
                        <td>Low</td>
                        <td>1 week</td>
                    </tr>
                    <tr>
                        <td>3</td>
                        <td>Implement Privileged Access Workstations (PAW)</td>
                        <td><span class="badge badge-warning">High</span></td>
                        <td>High</td>
                        <td>1-3 months</td>
                    </tr>
                    <tr>
                        <td>4</td>
                        <td>Deploy Azure AD Password Protection</td>
                        <td><span class="badge badge-warning">High</span></td>
                        <td>Medium</td>
                        <td>2-4 weeks</td>
                    </tr>
                    <tr>
                        <td>5</td>
                        <td>Review and reduce service account privileges</td>
                        <td><span class="badge badge-warning">High</span></td>
                        <td>Medium</td>
                        <td>2-4 weeks</td>
                    </tr>
                    <tr>
                        <td>6</td>
                        <td>Implement just-in-time (JIT) privileged access</td>
                        <td><span class="badge badge-info">Medium</span></td>
                        <td>High</td>
                        <td>2-3 months</td>
                    </tr>
                </tbody>
            </table>
        </div>
"@

    # ========================================================================
    # ASSEMBLE REPORT
    # ========================================================================

    $html = $htmlTemplate
    $html = $html -replace '{{TITLE}}', $ReportTitle
    $html = $html -replace '{{SUBTITLE}}', 'Comprehensive analysis of identity security posture'
    $html = $html -replace '{{DATE}}', (Get-Date -Format 'MMMM dd, yyyy HH:mm')
    $html = $html -replace '{{ORG}}', $env:USERDOMAIN
    $html = $html -replace '{{AUTHOR}}', $env:USERNAME
    $html = $html -replace '{{SCORE_CARDS}}', $scoreCards
    $html = $html -replace '{{SECTIONS}}', $sections

    # Write output
    $html | Out-File -FilePath $OutputPath -Encoding UTF8

    Write-Host "Report generated: $OutputPath" -ForegroundColor Green
    return $OutputPath
}
```

---

## Part 2: Incident Report Template

### Security Incident Report Generator

```powershell
function New-IncidentReport {
    <#
    .SYNOPSIS
        Generate security incident HTML report
    .PARAMETER IncidentId
        The incident ticket number
    .PARAMETER Timeline
        Array of timeline events
    .PARAMETER AffectedAccounts
        List of affected user accounts
    .PARAMETER OutputPath
        Report output path
    #>
    param(
        [string]$IncidentId,
        [array]$Timeline,
        [array]$AffectedAccounts,
        [string]$OutputPath
    )

    $incidentTemplate = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Security Incident Report - $IncidentId</title>
    <style>
        /* Include same base styles as above */
        body { font-family: 'Segoe UI', sans-serif; margin: 40px; }
        .incident-header {
            background: linear-gradient(135deg, #d13438, #a80000);
            color: white; padding: 30px; border-radius: 8px;
        }
        .timeline { position: relative; padding-left: 30px; }
        .timeline::before {
            content: ''; position: absolute; left: 10px; top: 0;
            height: 100%; width: 2px; background: #edebe9;
        }
        .timeline-item {
            position: relative; padding: 15px 0; padding-left: 30px;
        }
        .timeline-item::before {
            content: ''; position: absolute; left: -26px; top: 20px;
            width: 12px; height: 12px; border-radius: 50%;
            background: #0078d4; border: 2px solid white;
        }
        .timeline-item.critical::before { background: #d13438; }
        .timeline-item.warning::before { background: #ffb900; }
        .timeline-time { font-size: 0.85rem; color: #605e5c; }
        .timeline-content {
            background: #f5f5f5; padding: 15px; border-radius: 8px; margin-top: 5px;
        }
        .status-box {
            display: inline-block; padding: 8px 16px; border-radius: 4px;
            font-weight: 600; margin: 10px 0;
        }
        .status-active { background: #fde7e9; color: #d13438; }
        .status-contained { background: #fff4ce; color: #8a6914; }
        .status-resolved { background: #dff6dd; color: #107c10; }
    </style>
</head>
<body>
    <div class="incident-header">
        <h1>🚨 Security Incident Report</h1>
        <h2>$IncidentId</h2>
        <p>Classification: Identity Compromise</p>
    </div>

    <div style="margin: 30px 0;">
        <h2>Incident Status</h2>
        <div class="status-box status-contained">CONTAINED</div>

        <table style="width: 100%; margin-top: 20px;">
            <tr><td><strong>Detection Time:</strong></td><td>{{DETECTION_TIME}}</td></tr>
            <tr><td><strong>Containment Time:</strong></td><td>{{CONTAINMENT_TIME}}</td></tr>
            <tr><td><strong>Severity:</strong></td><td>HIGH</td></tr>
            <tr><td><strong>Affected Users:</strong></td><td>{{AFFECTED_COUNT}}</td></tr>
            <tr><td><strong>Attack Vector:</strong></td><td>{{ATTACK_VECTOR}}</td></tr>
        </table>
    </div>

    <div style="margin: 30px 0;">
        <h2>Executive Summary</h2>
        <p>On {{INCIDENT_DATE}}, suspicious authentication activity was detected indicating
        potential credential compromise. The security team initiated containment procedures
        within {{RESPONSE_TIME}} of detection.</p>

        <h3>Impact Assessment</h3>
        <ul>
            <li><strong>Accounts Compromised:</strong> {{COMPROMISED_COUNT}}</li>
            <li><strong>Systems Accessed:</strong> {{SYSTEMS_ACCESSED}}</li>
            <li><strong>Data at Risk:</strong> {{DATA_RISK}}</li>
        </ul>
    </div>

    <div style="margin: 30px 0;">
        <h2>Incident Timeline</h2>
        <div class="timeline">
            {{TIMELINE_ITEMS}}
        </div>
    </div>

    <div style="margin: 30px 0;">
        <h2>Affected Accounts</h2>
        <table style="width: 100%; border-collapse: collapse;">
            <thead>
                <tr style="background: #f5f5f5;">
                    <th style="padding: 12px; text-align: left;">Account</th>
                    <th style="padding: 12px; text-align: left;">Status</th>
                    <th style="padding: 12px; text-align: left;">Actions Taken</th>
                </tr>
            </thead>
            <tbody>
                {{AFFECTED_ACCOUNTS_TABLE}}
            </tbody>
        </table>
    </div>

    <div style="margin: 30px 0;">
        <h2>Containment Actions</h2>
        <ol>
            <li>Disabled all affected accounts in Active Directory and Entra ID</li>
            <li>Reset passwords and revoked all active sessions</li>
            <li>Removed affected accounts from sensitive groups</li>
            <li>Blocked source IP addresses at perimeter firewall</li>
            <li>Enabled enhanced monitoring for related accounts</li>
        </ol>
    </div>

    <div style="margin: 30px 0;">
        <h2>Root Cause Analysis</h2>
        <p>{{ROOT_CAUSE}}</p>
    </div>

    <div style="margin: 30px 0;">
        <h2>Lessons Learned & Recommendations</h2>
        <ol>
            <li>Implement Conditional Access policies requiring MFA from untrusted locations</li>
            <li>Deploy Microsoft Defender for Identity for real-time threat detection</li>
            <li>Conduct security awareness training focusing on phishing recognition</li>
            <li>Review and harden service account permissions</li>
        </ol>
    </div>

    <div style="margin: 30px 0; padding: 20px; background: #f5f5f5; border-radius: 8px;">
        <h3>Report Information</h3>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p>Classification: CONFIDENTIAL - Internal Use Only</p>
        <p>Author: {{AUTHOR}}</p>
    </div>
</body>
</html>
"@

    # Build timeline items
    $timelineHtml = ""
    foreach ($event in $Timeline) {
        $class = switch ($event.Severity) {
            'Critical' { 'critical' }
            'Warning' { 'warning' }
            default { '' }
        }
        $timelineHtml += @"
            <div class="timeline-item $class">
                <div class="timeline-time">$($event.Time)</div>
                <div class="timeline-content">
                    <strong>$($event.Title)</strong>
                    <p>$($event.Description)</p>
                </div>
            </div>
"@
    }

    # Build affected accounts table
    $accountsHtml = ""
    foreach ($account in $AffectedAccounts) {
        $accountsHtml += @"
            <tr>
                <td style="padding: 12px;">$($account.Name)</td>
                <td style="padding: 12px;"><span class="status-box status-$($account.Status.ToLower())">$($account.Status)</span></td>
                <td style="padding: 12px;">$($account.Actions -join ', ')</td>
            </tr>
"@
    }

    # Replace placeholders
    $html = $incidentTemplate
    $html = $html -replace '{{TIMELINE_ITEMS}}', $timelineHtml
    $html = $html -replace '{{AFFECTED_ACCOUNTS_TABLE}}', $accountsHtml
    $html = $html -replace '{{AUTHOR}}', $env:USERNAME

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    return $OutputPath
}
```

---

## Part 3: Quick Report Snippets

### Reusable HTML Components

```powershell
# ============================================================================
# REUSABLE HTML COMPONENTS
# ============================================================================

function Get-HtmlTable {
    <#
    .SYNOPSIS
        Convert PowerShell objects to styled HTML table
    #>
    param(
        [Parameter(ValueFromPipeline)]
        [array]$Data,
        [string[]]$Columns,
        [hashtable]$ColumnFormatters
    )

    begin { $rows = @() }
    process { $rows += $Data }
    end {
        if (-not $Columns) { $Columns = $rows[0].PSObject.Properties.Name }

        $html = @"
<table style="width: 100%; border-collapse: collapse; margin: 15px 0;">
    <thead>
        <tr style="background: #f5f5f5;">
            $($Columns | ForEach-Object { "<th style='padding: 12px; text-align: left; border-bottom: 2px solid #ddd;'>$_</th>" })
        </tr>
    </thead>
    <tbody>
"@
        foreach ($row in $rows) {
            $html += "<tr>"
            foreach ($col in $Columns) {
                $value = $row.$col
                if ($ColumnFormatters -and $ColumnFormatters.ContainsKey($col)) {
                    $value = & $ColumnFormatters[$col] $value
                }
                $html += "<td style='padding: 12px; border-bottom: 1px solid #eee;'>$value</td>"
            }
            $html += "</tr>"
        }
        $html += "</tbody></table>"
        return $html
    }
}

function Get-HtmlStatusBadge {
    param(
        [string]$Status,
        [ValidateSet('Critical', 'Warning', 'Success', 'Info')]
        [string]$Type = 'Info'
    )

    $colors = @{
        'Critical' = 'background: #fde7e9; color: #d13438;'
        'Warning'  = 'background: #fff4ce; color: #8a6914;'
        'Success'  = 'background: #dff6dd; color: #107c10;'
        'Info'     = 'background: #cfe2ff; color: #0078d4;'
    }

    return "<span style='display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 0.85rem; $($colors[$Type])'>$Status</span>"
}

function Get-HtmlProgressBar {
    param(
        [int]$Percentage,
        [string]$Label
    )

    $color = if ($Percentage -lt 50) { '#d13438' }
             elseif ($Percentage -lt 75) { '#ffb900' }
             else { '#107c10' }

    return @"
<div style="margin: 10px 0;">
    <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
        <span>$Label</span>
        <span>$Percentage%</span>
    </div>
    <div style="background: #eee; border-radius: 10px; height: 10px;">
        <div style="background: $color; width: $Percentage%; height: 100%; border-radius: 10px;"></div>
    </div>
</div>
"@
}

function Get-HtmlAlertBox {
    param(
        [string]$Message,
        [ValidateSet('Error', 'Warning', 'Info', 'Success')]
        [string]$Type = 'Info'
    )

    $styles = @{
        'Error'   = 'background: #fde7e9; border-color: #d13438; color: #d13438;'
        'Warning' = 'background: #fff4ce; border-color: #ffb900; color: #8a6914;'
        'Info'    = 'background: #cfe2ff; border-color: #0078d4; color: #0078d4;'
        'Success' = 'background: #dff6dd; border-color: #107c10; color: #107c10;'
    }

    $icons = @{
        'Error'   = '❌'
        'Warning' = '⚠️'
        'Info'    = 'ℹ️'
        'Success' = '✅'
    }

    return @"
<div style="padding: 15px 20px; border-left: 4px solid; border-radius: 4px; margin: 15px 0; $($styles[$Type])">
    $($icons[$Type]) $Message
</div>
"@
}

# ============================================================================
# EXAMPLE USAGE
# ============================================================================

# Quick user report
function New-QuickUserReport {
    param([string]$UserName, [string]$OutputPath)

    $user = Get-ADUser $UserName -Properties *
    $groups = Get-ADPrincipalGroupMembership $UserName

    $html = @"
<!DOCTYPE html>
<html>
<head><title>User Report: $UserName</title></head>
<body style="font-family: 'Segoe UI', sans-serif; margin: 40px;">
    <h1>User Report: $($user.DisplayName)</h1>
    <p>Generated: $(Get-Date)</p>

    <h2>Account Information</h2>
    $($user | Select-Object SamAccountName, UserPrincipalName, Enabled,
        PasswordLastSet, LastLogonDate | Get-HtmlTable)

    <h2>Group Memberships</h2>
    $($groups | Select-Object Name, GroupCategory | Get-HtmlTable)
</body>
</html>
"@

    $html | Out-File $OutputPath
}
```

---

## Quick Reference Card

```
HTML REPORT GENERATION QUICK REFERENCE

BASIC STRUCTURE:
<!DOCTYPE html>
<html>
<head>
    <style>/* CSS here */</style>
</head>
<body>
    <div class="container">
        <!-- Content -->
    </div>
</body>
</html>

COLOR SCHEME (Microsoft Fluent):
- Primary:  #0078d4 (blue)
- Success:  #107c10 (green)
- Warning:  #ffb900 (yellow)
- Danger:   #d13438 (red)
- Neutral:  #605e5c (gray)

QUICK TABLE:
$data | ConvertTo-Html -Fragment | Out-String

BADGE HTML:
<span style="background: #fde7e9; color: #d13438; padding: 4px 12px; border-radius: 20px;">Critical</span>

PROGRESS BAR:
<div style="background: #eee; height: 10px; border-radius: 5px;">
    <div style="background: #107c10; width: 75%; height: 100%;"></div>
</div>

PRINT STYLES:
@media print {
    .no-print { display: none; }
    .section { break-inside: avoid; }
}

EXPORT OPTIONS:
$html | Out-File "report.html"
Start-Process "report.html"  # Open in browser
```

---

*Document Version: 1.0*
*Framework: Identity Report Generation*
*Output: Executive-Ready HTML Reports*
