# Blast Radius Analysis

## Impact Assessment Framework for Identity Incidents

> **Definition**: Blast radius is the total scope of impact from an identity failure—direct, indirect, and cascading—translated into business terms.

---

## The Blast Radius Principle

```
Every identity failure has three circles of impact:

            ┌─────────────────────────────────────┐
            │         TERTIARY IMPACT             │
            │    (Cascading business effects)     │
            │  ┌─────────────────────────────┐    │
            │  │     SECONDARY IMPACT        │    │
            │  │  (Dependent systems/teams)  │    │
            │  │  ┌─────────────────────┐    │    │
            │  │  │   PRIMARY IMPACT    │    │    │
            │  │  │ (Direct auth failure)│    │    │
            │  │  └─────────────────────┘    │    │
            │  └─────────────────────────────┘    │
            └─────────────────────────────────────┘
```

---

## Impact Classification Matrix

### Primary Impact (Direct)

| Category | Questions to Answer | Metrics |
|----------|---------------------|---------|
| **Users Affected** | How many users cannot authenticate? | Count, percentage of workforce |
| **Systems Affected** | What systems are directly failing? | List of systems, criticality |
| **Geographic Scope** | Which locations are impacted? | Sites, regions, global |
| **Time Scope** | How long has this been ongoing? | Duration, business hours affected |

### Secondary Impact (Dependent)

| Category | Questions to Answer | Metrics |
|----------|---------------------|---------|
| **Dependent Services** | What relies on the failing identity? | Service dependencies |
| **Team Impact** | Which teams are blocked? | Teams, headcount |
| **Integration Failures** | What SaaS/apps are broken? | Application list |
| **Automation Failures** | What scheduled jobs are failing? | Jobs, business processes |

### Tertiary Impact (Cascading)

| Category | Questions to Answer | Metrics |
|----------|---------------------|---------|
| **Revenue Impact** | Is this affecting sales/transactions? | $/hour, $/day |
| **Customer Impact** | Are external customers affected? | Customer count, SLA breach |
| **Regulatory Impact** | Any compliance implications? | Regulations, audit flags |
| **Reputational Impact** | External visibility? | Public-facing, media risk |

---

## Blast Radius Assessment Framework

### Step 1: Immediate Impact Quantification

```
PRIMARY BLAST RADIUS:

┌────────────────────────────────────────────────────────────────┐
│ AUTHENTICATION SCOPE                                           │
├────────────────────────────────────────────────────────────────┤
│ □ Single user affected                    Impact: MINIMAL      │
│ □ Small group (<10 users)                 Impact: LOW          │
│ □ Department/Team (10-100 users)          Impact: MEDIUM       │
│ □ Site/Building (100-1000 users)          Impact: HIGH         │
│ □ Multiple sites (1000+ users)            Impact: CRITICAL     │
│ □ All users globally                      Impact: CATASTROPHIC │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│ SYSTEM SCOPE                                                   │
├────────────────────────────────────────────────────────────────┤
│ □ Single application                      Impact: LOW          │
│ □ Multiple applications                   Impact: MEDIUM       │
│ □ Core business application               Impact: HIGH         │
│ □ Authentication infrastructure           Impact: CRITICAL     │
│ □ All domain-joined systems               Impact: CATASTROPHIC │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│ TIME SCOPE                                                     │
├────────────────────────────────────────────────────────────────┤
│ □ < 15 minutes                            Urgency: MONITOR     │
│ □ 15 min - 1 hour                         Urgency: ELEVATED    │
│ □ 1 - 4 hours                             Urgency: HIGH        │
│ □ 4+ hours                                Urgency: CRITICAL    │
│ □ Overnight/weekend (accumulated)         Urgency: ASSESS      │
└────────────────────────────────────────────────────────────────┘
```

### Step 2: Dependency Mapping

```
DEPENDENCY IMPACT TREE:

Failing Component: [e.g., Domain Controller Authentication]
│
├── Direct Dependencies
│   ├── Windows Logon → [X users blocked]
│   ├── LDAP Applications → [List apps]
│   ├── Kerberos Services → [List services]
│   └── Group Policy → [Settings not applied]
│
├── Indirect Dependencies
│   ├── VPN (depends on auth) → [Remote users blocked]
│   ├── Email (depends on auth) → [Email unavailable]
│   ├── SharePoint (depends on auth) → [Collaboration blocked]
│   └── Line-of-Business Apps → [Business process stopped]
│
└── Cascading Effects
    ├── Customer Portal (if auth-dependent) → [Customer impact]
    ├── Partner Integrations → [B2B impact]
    ├── Scheduled Jobs → [Batch processing failed]
    └── Monitoring (if auth-dependent) → [Blind spots]
```

### Step 3: Business Impact Translation

```
BUSINESS IMPACT CALCULATOR:

┌─────────────────────────────────────────────────────────────────┐
│ FINANCIAL IMPACT                                                │
├─────────────────────────────────────────────────────────────────┤
│ Users affected:           [    X    ] users                     │
│ Average productivity:     [  $ Y    ] per hour                  │
│ Duration:                 [    Z    ] hours                     │
│ ─────────────────────────────────────────────────────────────── │
│ Productivity Loss:        $[X × Y × Z]                          │
│                                                                 │
│ Transaction Systems Down: [Yes/No]                              │
│ Revenue per hour:         [  $ R    ]                           │
│ ─────────────────────────────────────────────────────────────── │
│ Revenue Loss:             $[R × Z hours]                        │
│                                                                 │
│ TOTAL ESTIMATED IMPACT:   $[Combined]                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ OPERATIONAL IMPACT                                              │
├─────────────────────────────────────────────────────────────────┤
│ □ Users working from home blocked                               │
│ □ Critical meetings cannot occur                                │
│ □ Customer-facing staff offline                                 │
│ □ Development/deployment blocked                                │
│ □ Support cannot access systems                                 │
│ □ Security team cannot investigate                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ COMPLIANCE/REGULATORY IMPACT                                    │
├─────────────────────────────────────────────────────────────────┤
│ □ SLA breach pending (threshold: [X hours])                     │
│ □ Audit logs unavailable                                        │
│ □ Access controls not enforced                                  │
│ □ PCI/HIPAA/SOX systems affected                               │
│ □ Customer data access issues                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Common Identity Failure Blast Radii

### Scenario: Single DC Failure (Multi-DC Site)

```
BLAST RADIUS: LOW-MEDIUM

Primary Impact:
├── Users configured for this DC only: AFFECTED
├── Other users: NOT AFFECTED (will fail to other DCs)
└── Estimated user impact: 0-10% depending on DC locator

Secondary Impact:
├── Services with hardcoded DC: INVESTIGATE
├── Replication partnerships: MONITOR
└── FSMO roles if held: ASSESS

Business Translation:
"One domain controller is offline. Most users are unaffected as
they're automatically using other DCs. We're monitoring for any
services that were specifically configured to use this DC."
```

### Scenario: All DCs in Site Offline

```
BLAST RADIUS: HIGH-CRITICAL

Primary Impact:
├── All users in site: CANNOT AUTHENTICATE
├── All domain-joined computers: AFFECTED
└── Estimated user impact: 100% of site

Secondary Impact:
├── Remote users authenticating to this site: AFFECTED
├── WAN replication to other sites: STOPPED
├── Site-local services: ALL DOWN
└── VPN terminating in site: BLOCKED

Business Translation:
"The [Site Name] office is completely unable to access any
systems that require Windows authentication. This affects
approximately [X] employees. Remote workers who normally
connect through this site are also impacted."
```

### Scenario: Azure AD Connect Sync Failure

```
BLAST RADIUS: MEDIUM (Initially) → HIGH (If Prolonged)

Primary Impact:
├── New users: CANNOT ACCESS CLOUD
├── Password changes: NOT SYNCING
├── Group changes: NOT REFLECTED IN CLOUD
└── Immediate user impact: LOW (existing users work)

Secondary Impact (After 4+ Hours):
├── Password resets accumulating
├── New hire onboarding blocked
├── License assignments failing
└── Conditional Access with group conditions: STALE

Business Translation:
"New employees cannot access Microsoft 365 or cloud
applications. Existing employees are working normally,
but anyone who changed their password cannot access
cloud resources with their new password."
```

### Scenario: Kerberos Failure (KDC Issue)

```
BLAST RADIUS: CRITICAL-CATASTROPHIC

Primary Impact:
├── All Kerberos authentication: FAILING
├── NTLM fallback: MAY WORK (if enabled)
├── SSO: BROKEN
└── User impact: WIDESPREAD

Secondary Impact:
├── All Kerberized applications: DOWN
├── File server access: DEGRADED OR DOWN
├── SQL Server Windows Auth: FAILING
├── SharePoint: DOWN
└── Virtually all internal apps: AFFECTED

Business Translation:
"Core Windows authentication is failing across the
enterprise. Users cannot access file shares, internal
applications, or single sign-on. This is a critical
outage affecting all employees."
```

---

## Blast Radius Communication Templates

### Template: Initial Assessment (5 Minutes)

```
BLAST RADIUS ASSESSMENT - INITIAL

Incident: [Brief description]
Assessment Time: [Timestamp]
Assessed By: [Name]

CURRENT SCOPE:
├── Users Impacted: [Number or percentage]
├── Systems Impacted: [List critical systems]
├── Geographic Scope: [Sites/regions]
└── Duration So Far: [Time]

IMMEDIATE BUSINESS IMPACT:
[2-3 sentences in business terms]

TRAJECTORY:
□ Stable - Impact not growing
□ Expanding - More systems/users being affected
□ Unknown - Need more data

NEXT UPDATE: [Time]
```

### Template: Executive Summary

```
EXECUTIVE INCIDENT SUMMARY

Status: [ONGOING / MITIGATED / RESOLVED]
Started: [Time]
Duration: [Hours/Minutes]

WHO IS AFFECTED:
• [Number] employees cannot [do what]
• [Locations/departments] are impacted
• [Customer impact, if any]

BUSINESS IMPACT:
• Estimated productivity impact: [$ or qualitative]
• Critical business processes affected: [List]
• Customer-facing impact: [Yes/No, details]

WHAT WE'RE DOING:
• [Current action]
• [Next step]

ESTIMATED RESOLUTION:
• [Time estimate if known, or "investigating"]

NEXT UPDATE:
• [Time] or sooner if significant change
```

### Template: Post-Incident Impact Summary

```
INCIDENT IMPACT SUMMARY

Incident: [Name/Number]
Duration: [Start] to [End]
Total Downtime: [Hours:Minutes]

FINAL IMPACT METRICS:
├── Total Users Affected: [Number]
├── Peak Concurrent Impact: [Number at worst point]
├── Geographic Scope: [Locations]
└── Systems Affected: [List]

BUSINESS IMPACT:
├── Estimated Productivity Loss: [$ or hours]
├── Revenue Impact: [$ if applicable]
├── SLA Breach: [Yes/No, details]
└── Customer Communications Required: [Yes/No]

ROOT CAUSE:
[Brief description]

PREVENTION:
[What will prevent recurrence]
```

---

## Blast Radius Monitoring During Incident

### Key Metrics to Track

```
REAL-TIME BLAST RADIUS METRICS:

Track Every 15 Minutes:
├── Authentication Success Rate: [Current %] vs [Baseline %]
├── Failed Authentication Count: [Current] vs [Normal]
├── User Complaints: [Count, trending up/down]
├── System Alerts: [Count by severity]
└── Geographic Distribution: [Sites reporting issues]

Track Every Hour:
├── Cumulative User Impact: [Total unique users affected]
├── Duration by Severity: [How long at each level]
├── Resolution Progress: [% of impact mitigated]
└── New Systems Affected: [Any expansion?]
```

### Escalation Triggers Based on Blast Radius

```
ESCALATION MATRIX:

LEVEL 1 (Team Lead):
├── > 10 users affected for > 15 minutes
├── Any critical system affected
└── Any customer-facing impact suspected

LEVEL 2 (Department Head):
├── > 100 users affected for > 30 minutes
├── Multiple critical systems
├── Confirmed customer impact
└── Revenue-affecting systems

LEVEL 3 (Executive):
├── > 1000 users or entire site
├── > 2 hours duration
├── Customer escalation received
├── Media/reputational risk
└── Regulatory implications

LEVEL 4 (Crisis):
├── Enterprise-wide outage
├── Multiple regions
├── > 4 hours duration
├── Security breach suspected
└── External communication required
```

---

## Related Documents

- [Executive Translation](executive_translation.md) - How to communicate impact
- [P0 Incident Commander](p0_incident_commander_prompt.md) - Overall incident approach
- [Timeline Reconstruction](timeline_reconstruction.md) - When did impact start
