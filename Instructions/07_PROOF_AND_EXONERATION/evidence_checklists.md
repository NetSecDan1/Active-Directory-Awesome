# Evidence Checklists

## Standardized Evidence Collection for Identity Incidents

> **Purpose**: Ensure consistent, complete evidence collection that supports confident conclusions—whether diagnosing an issue or exonerating identity systems.

---

## Master Evidence Collection Framework

### Evidence Hierarchy

```
EVIDENCE QUALITY TIERS:

TIER 1: Direct Evidence (Strongest)
├── Log entries with timestamps
├── Error codes from systems
├── Reproducible test results
├── Network captures
└── Configuration exports

TIER 2: Corroborating Evidence
├── Multiple users reporting same symptom
├── Monitoring alerts
├── Pattern analysis
└── Timeline correlations

TIER 3: Circumstantial Evidence
├── Recent changes
├── Similar past incidents
├── Environmental factors
└── Third-party reports

TIER 4: Inference (Weakest)
├── "Should have worked"
├── "Usually works"
├── Absence of errors
└── Assumptions
```

---

## Active Directory Evidence Checklist

### Authentication Failure Investigation

```
AD AUTHENTICATION EVIDENCE COLLECTION

□ CLIENT-SIDE EVIDENCE
  □ Exact error message (screenshot if possible)
  □ Kerberos ticket status: klist output
  □ Client event logs:
    - Security (4625, 4771, 4768, 4769)
    - System (time sync, network)
  □ Client time: w32tm /query /status
  □ Client DNS settings: ipconfig /all
  □ Client computer object: Get-ADComputer

□ DC-SIDE EVIDENCE (PDC Emulator + Local DC)
  □ Security event log filtered for user/time
  □ NTDS diagnostic logging (if enabled)
  □ Time sync status: w32tm /query /status
  □ Netlogon logs: nltest output

□ ACCOUNT EVIDENCE
  □ Account status: Get-ADUser -Properties *
  □ Password last set time
  □ Account lockout status
  □ Account expiration
  □ Group memberships
  □ userAccountControl flags
  □ Bad password count

□ INFRASTRUCTURE EVIDENCE
  □ DC health: dcdiag /v
  □ Replication status: repadmin /showrepl
  □ DNS resolution: SRV record queries
  □ Site assignment verification

COLLECTION TIMESTAMP: _______________
COLLECTED BY: _______________
```

### Replication Failure Investigation

```
AD REPLICATION EVIDENCE COLLECTION

□ REPLICATION STATUS
  □ repadmin /replsummary output
  □ repadmin /showrepl for affected DCs
  □ repadmin /showrepl * /csv (enterprise-wide)
  □ repadmin /queue status

□ DC HEALTH
  □ dcdiag /v /c for affected DCs
  □ Service status (NTDS, Netlogon, DNS, DFSR)
  □ Event logs (Directory Service, DNS Server, DFS Replication)

□ NETWORK EVIDENCE
  □ Connectivity tests between DCs
  □ DNS resolution DC to DC
  □ Firewall logs if available
  □ Port connectivity (135, 389, 636, 3268, 445)

□ CONFIGURATION
  □ Site topology export
  □ Site link configuration
  □ Connection objects: repadmin /showconn

□ TIMING
  □ When did replication last succeed?
  □ What changed since then?
  □ Any maintenance or updates?

COLLECTION TIMESTAMP: _______________
COLLECTED BY: _______________
```

### Account Lockout Investigation

```
ACCOUNT LOCKOUT EVIDENCE COLLECTION

□ LOCKOUT DETAILS (from PDC Emulator)
  □ Event 4740 for affected account
  □ Caller Computer Name from event
  □ Time of lockout
  □ Bad password count before lockout

□ SOURCE IDENTIFICATION
  □ Event 4625 leading up to lockout
  □ Source workstation/IP
  □ Logon type
  □ Process name (if available)

□ ACCOUNT CONFIGURATION
  □ Lockout threshold setting
  □ Lockout duration setting
  □ Account lockout history (if tracked)
  □ Service accounts using this credential

□ CLIENT INVESTIGATION (on source computer)
  □ Mapped drives with credentials
  □ Scheduled tasks with credentials
  □ Services running as account
  □ Credential Manager entries
  □ Browser saved passwords

□ PATTERN ANALYSIS
  □ Is lockout recurring?
  □ Same time each occurrence?
  □ Same source each time?
  □ Correlates with any schedule?

COLLECTION TIMESTAMP: _______________
COLLECTED BY: _______________
```

---

## Entra ID Evidence Checklist

### Sign-In Failure Investigation

```
ENTRA ID SIGN-IN EVIDENCE COLLECTION

□ SIGN-IN LOG ENTRY
  □ Correlation ID
  □ Request ID
  □ Timestamp (UTC)
  □ User Principal Name
  □ Application ID and name
  □ IP address
  □ Location
  □ Device info
  □ Error code (AADSTS*)
  □ Error description

□ CONDITIONAL ACCESS DETAILS
  □ Policies evaluated
  □ Policies applied
  □ Policy result (success/failure)
  □ Grant controls required
  □ Session controls applied

□ MFA DETAILS (if applicable)
  □ MFA method attempted
  □ MFA result
  □ MFA provider (if external)
  □ Authentication strength required

□ USER CONFIGURATION
  □ Account enabled
  □ Account type (member/guest)
  □ Directory synced (if hybrid)
  □ License assignment
  □ Authentication methods registered

□ APPLICATION CONFIGURATION
  □ App registration status
  □ Required permissions
  □ Consent status
  □ Token configuration

COLLECTION TIMESTAMP: _______________
COLLECTED BY: _______________
```

### Sync Failure Investigation

```
AZURE AD CONNECT EVIDENCE COLLECTION

□ SYNC STATUS
  □ Get-ADSyncScheduler output
  □ Last sync time
  □ Sync interval
  □ Staging mode status

□ CONNECTOR STATUS
  □ Connector space statistics
  □ Pending exports
  □ Export errors

□ SYNC ERRORS
  □ Export errors list
  □ Sync errors from portal
  □ Specific object errors

□ RUN HISTORY
  □ Recent run profiles
  □ Success/failure status
  □ Object counts (adds/updates/deletes)

□ OBJECT-SPECIFIC (if specific object failing)
  □ On-prem object attributes
  □ Connector space object
  □ Metaverse object
  □ Azure AD object

□ SERVICE HEALTH
  □ AAD Connect service status
  □ SQL database connectivity (if using SQL)
  □ Azure AD service health

COLLECTION TIMESTAMP: _______________
COLLECTED BY: _______________
```

---

## Network Evidence Checklist

### Connectivity Investigation

```
NETWORK EVIDENCE FOR IDENTITY ISSUES

□ BASIC CONNECTIVITY
  □ Ping results (if ICMP allowed)
  □ Traceroute/tracert
  □ DNS resolution tests

□ PORT CONNECTIVITY
  □ TCP 88 (Kerberos)
  □ TCP/UDP 389 (LDAP)
  □ TCP 636 (LDAPS)
  □ TCP 445 (SMB)
  □ TCP 3268/3269 (Global Catalog)
  □ TCP 443 (HTTPS/Azure)
  □ TCP 135 + dynamic (RPC)

□ DNS EVIDENCE
  □ SRV record queries
  □ A record resolution
  □ DNS server configuration
  □ DNS response times

□ FIREWALL EVIDENCE
  □ Relevant allow/deny logs
  □ Recent rule changes
  □ Policy verification

□ LOAD BALANCER EVIDENCE (if applicable)
  □ Health check status
  □ Session persistence config
  □ Backend server status

COLLECTION TIMESTAMP: _______________
COLLECTED BY: _______________
```

---

## Evidence Documentation Standards

### Required Metadata for All Evidence

```
EVIDENCE METADATA TEMPLATE

Source: [System/log name]
Collection Time: [UTC timestamp]
Collected By: [Name/role]
Collection Method: [Manual/automated/export]
Time Range of Evidence: [Start - End UTC]
Hash (if file): [SHA256 if applicable]
Chain of Custody: [Who has had access]

CONTEXT:
- Why was this collected?
- What incident/ticket?
- What hypothesis does this support/refute?
```

### Evidence Preservation Rules

```
EVIDENCE PRESERVATION REQUIREMENTS

DO:
✓ Collect with timestamps
✓ Export to immutable format when possible
✓ Note collection methodology
✓ Preserve original format
✓ Document any filtering applied
✓ Store securely with access log

DON'T:
✗ Modify original logs
✗ Filter without documenting
✗ Rely on memory
✗ Paraphrase error messages
✗ Collect without timestamps
✗ Delay collection (logs may rotate)
```

---

## Evidence Correlation Template

```
EVIDENCE CORRELATION MATRIX

Incident: [Name/Number]
Hypothesis: [What we're trying to prove/disprove]

TIME          | SOURCE           | EVIDENCE                    | SUPPORTS | CONTRADICTS
--------------|------------------|-----------------------------|---------|-----------
[Timestamp]   | [System/Log]     | [Specific finding]          | □       | □
[Timestamp]   | [System/Log]     | [Specific finding]          | □       | □
[Timestamp]   | [System/Log]     | [Specific finding]          | □       | □
[Timestamp]   | [System/Log]     | [Specific finding]          | □       | □

CORRELATION ANALYSIS:
- Evidence supporting hypothesis: [Count]
- Evidence contradicting hypothesis: [Count]
- Evidence neutral/unclear: [Count]

CONCLUSION: [Support/Refute/Inconclusive]
CONFIDENCE: [High/Medium/Low]
```

---

## Quick Collection Commands

### Active Directory

```powershell
# Collect AD evidence for specific user
$user = "username"
$dc = "DC1.domain.com"
$output = "C:\Evidence\$user_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

New-Item -ItemType Directory -Path $output -Force

# Account details
Get-ADUser $user -Properties * -Server $dc | Export-Clixml "$output\user.xml"

# Group membership
Get-ADPrincipalGroupMembership $user -Server $dc | Export-Clixml "$output\groups.xml"

# Security events for user (last 24 hours)
Get-WinEvent -ComputerName $dc -FilterHashtable @{
    LogName='Security'
    StartTime=(Get-Date).AddHours(-24)
} | Where-Object {$_.Message -match $user} | Export-Clixml "$output\security_events.xml"

# DC health
dcdiag /s:$dc /v > "$output\dcdiag.txt"

# Replication status
repadmin /showrepl $dc > "$output\showrepl.txt"
```

### Entra ID (Requires Appropriate Permissions)

```powershell
# Collect Entra evidence for specific user
$upn = "user@domain.com"
$output = "C:\Evidence\$($upn.Split('@')[0])_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

New-Item -ItemType Directory -Path $output -Force

# User details
Get-MgUser -UserId $upn -Property * | Export-Clixml "$output\user.xml"

# Group membership
Get-MgUserMemberOf -UserId $upn | Export-Clixml "$output\groups.xml"

# Recent sign-ins (last 7 days)
Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$upn'" -Top 100 | Export-Clixml "$output\signins.xml"
```

---

## Related Documents

- [Proving Not AD or Entra](proving_not_ad_or_entra.md) - Exoneration framework
- [Confidence Scoring](confidence_scoring.md) - Quantifying certainty
- [Truth and Confidence](../00_GLOBAL_GUARDRAILS/truth_and_confidence.md) - Evidence standards
