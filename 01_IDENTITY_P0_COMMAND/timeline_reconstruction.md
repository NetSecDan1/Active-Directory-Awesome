# Timeline Reconstruction

## Time-Based Reasoning for Identity P0 Incidents

> **Key Insight**: P0s are about sequence, not just facts. Understanding WHEN things happened—and in what order—is often the key to root cause.

---

## The Timeline Principle

```
TIMELINE TRUTH:

Identity failures don't happen in a vacuum.
Something changed. Something triggered. Something cascaded.

Your job: Find the inflection point.
                    ↓
         ──────────●──────────
            Before │ After
            Worked │ Failed
```

---

## Standard Timeline Windows

### Critical Investigation Windows

| Window | Use Case | What Changed? |
|--------|----------|---------------|
| **T-5 minutes** | Immediate trigger | User action, automated task, reboot |
| **T-30 minutes** | Recent change | Config change, restart, failover |
| **T-2 hours** | Same-shift change | Deployment, maintenance, update |
| **T-24 hours** | Daily pattern | Scheduled tasks, batch jobs, patching |
| **T-7 days** | Weekly pattern | Maintenance windows, certificate rotation |
| **T-30 days** | Monthly pattern | Password expiration, certificate expiry |
| **T-90 days** | Quarterly pattern | Tombstone, stale accounts, license renewal |

---

## Data Sources for Timeline

### Identity-Specific Sources

```
ACTIVE DIRECTORY TIMELINE SOURCES:

1. Security Event Log (DCs)
   - 4624/4625: Logon success/failure
   - 4768/4769: Kerberos TGT/Service ticket
   - 4771: Kerberos pre-auth failure
   - 4740: Account lockout
   - 4776: NTLM authentication
   - 4662: DCSync detection
   - 5136/5137: Object modification/creation

2. Directory Service Event Log
   - Replication events
   - Database events
   - KCC events

3. System Event Log
   - Service start/stop
   - Time sync changes
   - Driver issues

4. Replication Metadata
   - repadmin /showrepl (last success times)
   - repadmin /showchanges (recent changes)
   - Object whenChanged attributes
```

```
ENTRA ID TIMELINE SOURCES:

1. Sign-in Logs
   - Timestamp
   - User
   - Application
   - Status (success/failure)
   - Conditional Access results
   - MFA details

2. Audit Logs
   - Configuration changes
   - Application registrations
   - Group changes
   - User management

3. Provisioning Logs
   - Sync operations
   - Failures
   - Object changes

4. Risk Events
   - Risky sign-ins
   - Risky users
   - Detection timestamps
```

```
HYBRID IDENTITY TIMELINE SOURCES:

1. Azure AD Connect
   - Sync cycle timestamps
   - Export errors
   - Run history

2. PTA Agents
   - Agent health
   - Authentication pass-through times

3. Password Sync
   - Last sync time per user
   - Sync errors

4. Federation (ADFS)
   - Token issuance times
   - Authentication failures
```

### Correlated Sources

```
CROSS-TEAM TIMELINE SOURCES:

1. Security Telemetry
   - MDI (Microsoft Defender for Identity)
     └── Lateral movement detection times
     └── Credential access alerts
     └── Recon activity

   - MDE (Microsoft Defender for Endpoint)
     └── Process execution times
     └── Network connections
     └── Credential dumps detected

2. Network
   - Firewall logs (allow/deny by time)
   - DNS query logs
   - Load balancer health
   - VPN connection logs

3. Infrastructure
   - Server reboots
   - Patch installations
   - Certificate changes
   - Backup/restore operations

4. Monitoring
   - Alert timestamps
   - Metric anomalies
   - Threshold breaches

5. Change Management
   - Change tickets with timestamps
   - Deployment records
   - Maintenance windows
```

---

## Timeline Construction Process

### Step 1: Establish the Failure Point

```
DEFINE T-ZERO:

T-0 = The exact moment the failure was FIRST observed
     (Not when reported—when it actually started)

How to determine T-0:
1. First user report timestamp
2. First monitoring alert
3. First error in logs
4. First authentication failure pattern change

Document: "Issue began at [exact timestamp] as evidenced by [source]"
```

### Step 2: Work Backwards

```
BACKWARD TIMELINE CONSTRUCTION:

T-0: Failure observed
│
├── T-5min: What was happening?
│   └── Check: Event logs, active sessions, recent authentications
│
├── T-30min: Any changes?
│   └── Check: Service restarts, config changes, deployments
│
├── T-2hr: What was the environment state?
│   └── Check: Replication status, sync status, service health
│
├── T-24hr: Yesterday at this time?
│   └── Check: Was it working? Same behavior pattern?
│
├── T-7d: Last week at this time?
│   └── Check: Maintenance windows? Weekly patterns?
│
└── T-30d: Monthly patterns?
    └── Check: Certificate expiry? Password expiry? License?
```

### Step 3: Correlate Events

```
CORRELATION MATRIX:

Create a time-ordered list of events from all sources:

TIME            | SOURCE     | EVENT                           | RELEVANT?
----------------|------------|--------------------------------|----------
09:15:23        | DC1 SecLog | 4625 - Failed logon user1      | YES
09:15:24        | DC1 SecLog | 4625 - Failed logon user1      | YES
09:15:25        | DC1 SecLog | 4740 - Account lockout user1   | YES
09:15:30        | Monitoring | Alert: Auth failure spike      | YES
09:14:55        | DC2 SysLog | Service restart: Netlogon      | INVESTIGATE
09:10:00        | Network    | Firewall rule change           | INVESTIGATE
09:00:00        | Change Mgmt| Ticket #1234 - DNS update      | INVESTIGATE

CORRELATIONS IDENTIFIED:
- Lockout happened after failed logons (expected)
- Netlogon restart on DC2 30 seconds before failures
- Firewall change 5 minutes before failures
- DNS change 15 minutes before failures
```

### Step 4: Identify the Inflection Point

```
INFLECTION POINT ANALYSIS:

Question: What is the LAST moment everything was working normally?

Working State (T-X):
- Authentication successful
- Replication current
- No errors in logs

Transition Event (T-inflection):
- This is what changed
- This is the likely root cause trigger

Failed State (T-0 to present):
- Authentication failing
- Errors present
- Impact ongoing

INFLECTION POINT: [Timestamp] [Event] [Source]
```

---

## Timeline Visualization Template

```
INCIDENT TIMELINE: [Issue Name]
Generated: [Timestamp]
Incident Duration: [Start] to [End or Ongoing]

─────────────────────────────────────────────────────────────────────
TIMELINE VIEW (Most Recent First)
─────────────────────────────────────────────────────────────────────

[NOW]     ┃ Current state: [Description]
          ┃
09:45     ┃ ★ MITIGATION: [Action taken]
          ┃   Result: [Outcome]
          ┃
09:30     ┃ ○ Investigation: [Finding]
          ┃   Source: [Log/Tool]
          ┃
09:20     ┃ ○ Investigation: [Finding]
          ┃   Source: [Log/Tool]
          ┃
09:15:30  ┃ ◆ ALERT: Monitoring detected issue
          ┃   Source: [Monitoring system]
          ┃
09:15:25  ┃ ✗ FAILURE: First authentication failure pattern
          ┃   Source: DC1 Security Log
          ┃
───────── ┃ ═══════════════════════════════════════════════
          ┃ ▲▲▲ T-ZERO: INCIDENT START ▲▲▲
───────── ┃ ═══════════════════════════════════════════════
          ┃
09:14:55  ┃ ⚠ CHANGE: Netlogon service restarted on DC2
          ┃   Source: DC2 System Log
          ┃   *** LIKELY TRIGGER ***
          ┃
09:10:00  ┃ ⚠ CHANGE: Firewall rule modified
          ┃   Source: Firewall admin log
          ┃   Investigating relevance
          ┃
09:00:00  ┃ ○ Scheduled: DNS update per Change #1234
          ┃   Source: Change Management
          ┃
08:45     ┃ ✓ BASELINE: Last confirmed working authentication
          ┃   Source: Security log review
          ┃
─────────────────────────────────────────────────────────────────────
```

---

## Automated Timeline Queries

### Active Directory - Last 24 Hours

```powershell
# Collect authentication timeline from DC
$StartTime = (Get-Date).AddHours(-24)

# Failed authentications
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4625, 4771, 4776
    StartTime = $StartTime
} | Select-Object TimeCreated, Id, Message |
Sort-Object TimeCreated |
Export-Csv "FailedAuth_Timeline.csv"

# Account lockouts
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4740
    StartTime = $StartTime
} | Select-Object TimeCreated, @{N='Account';E={$_.Properties[0].Value}}, @{N='Source';E={$_.Properties[1].Value}} |
Sort-Object TimeCreated

# Service changes
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ID = 7036, 7040  # Service state changes
    StartTime = $StartTime
} | Sort-Object TimeCreated
```

### Entra ID - Recent Sign-ins (Requires Graph API)

```powershell
# Using Microsoft Graph
$signIns = Get-MgAuditLogSignIn -Filter "createdDateTime ge $StartTime" -Top 1000

# Failed sign-ins
$signIns | Where-Object {$_.Status.ErrorCode -ne 0} |
Select-Object CreatedDateTime, UserPrincipalName, AppDisplayName, Status |
Sort-Object CreatedDateTime
```

---

## Timeline Communication Template

### For Technical Team

```
TIMELINE SUMMARY - TECHNICAL

Incident: [Name]
Duration: [Start] to [End/Ongoing]
Impact: [Scope]

KEY TIMESTAMPS:
• T-0 (Failure Start): [Exact time] - [What happened]
• T-inflection (Trigger): [Exact time] - [What changed]
• T-detection: [When we knew]
• T-mitigation: [When we acted]
• T-resolution: [When fixed]

ROOT CAUSE TIMELINE:
1. [Time]: [Event] → 2. [Time]: [Event] → 3. [Time]: [Failure]

EVIDENCE:
- [Log source]: [Specific entry]
- [Log source]: [Specific entry]
```

### For Executive Team

```
TIMELINE SUMMARY - EXECUTIVE

What Happened:
At [time], [system/service] began failing, affecting [scope].

Root Cause:
At [time], [change/event] occurred, which caused [effect].

Response:
Issue detected at [time], team engaged at [time], resolved at [time].

Impact Window: [X hours/minutes]
Users Affected: [Number]
```

---

## Common Timeline Patterns

### Pattern: Certificate Expiration

```
T-30 days:  Certificate expiration warning (often ignored)
T-7 days:   Warning reminder
T-0:        Certificate expires at exactly midnight
T+1 minute: First authentication failures
T+5 min:    User reports begin
T+15 min:   Widespread failures recognized
```

### Pattern: Password/Credential Change

```
T-X:        Password changed on service account
T-0:        Cached credential expires
T+1 min:    Service fails to authenticate
T+5 min:    Dependent services begin failing
T+15 min:   Cascade effect fully realized
```

### Pattern: Replication Failure

```
T-X:        Replication failure begins (often silent)
T-X+hours:  Partition divergence grows
T-0:        User created/modified on DC1
T+5 min:    User tries to authenticate to DC2 (fails)
T+10 min:   "Works sometimes" reports begin
```

### Pattern: DNS Failure

```
T-0:        DNS change implemented
T+5 min:    DNS cache still valid (no impact)
T+15 min:   DNS cache begins expiring
T+30 min:   Clients querying new (broken) DNS
T+1 hour:   Widespread failures as caches expire
```

---

## Related Documents

- [P0 Incident Commander](p0_incident_commander_prompt.md) - Main incident prompt
- [Blast Radius Analysis](blast_radius_analysis.md) - Impact assessment
- [Evidence Checklists](../07_PROOF_AND_EXONERATION/evidence_checklists.md) - What to collect
