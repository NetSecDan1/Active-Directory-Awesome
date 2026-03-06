# Ownership Matrix

## Cross-Team Dependencies and Escalation Paths for Identity Issues

> **Purpose**: Identity failures often involve multiple teams. This matrix defines who owns what, how to engage them, and what evidence they need.

---

## Team Ownership Map

### Primary Identity Team Ownership

```
IDENTITY TEAM OWNS:

Active Directory
├── Domain Controllers
├── AD Replication
├── FSMO Roles
├── AD Schema
├── AD Sites and Services
├── Group Policy (infrastructure)
└── AD Certificate Services

Entra ID / Azure AD
├── User and Group management
├── Azure AD Connect
├── Conditional Access
├── MFA configuration
├── App registrations (identity aspects)
└── PIM / Identity Governance

Hybrid Identity
├── Directory sync
├── Pass-through Authentication
├── Password Hash Sync
├── Seamless SSO
└── Federation (AD FS)

Authentication
├── Kerberos
├── NTLM
├── Certificate authentication
├── Smart cards
└── Service account management
```

### Shared Ownership (Identity + Other Team)

```
SHARED OWNERSHIP:

DNS ──────────────────────────────────────────────────────
│ Identity owns: AD-integrated DNS zones, SRV records
│ Network owns: DNS infrastructure, forwarders, external DNS
│ Engage Network if: Non-AD DNS issues, forwarding problems
│ Engage Identity if: SRV records, AD zone issues

PKI/Certificates ─────────────────────────────────────────
│ Identity owns: AD CS, domain controller certs, user certs
│ Security owns: CA security, PKI policy
│ App teams own: Application certificates
│ Engage Security if: CA compromise, policy decisions
│ Engage Identity if: Auto-enrollment, KDC certs

Network ──────────────────────────────────────────────────
│ Identity owns: Nothing (pure network)
│ Network owns: Firewalls, routing, VPN, load balancers
│ Engage Network if: Connectivity issues, port blocks
│ What they need: Source/dest IPs, ports, timestamps

Security Monitoring ──────────────────────────────────────
│ Identity owns: AD security events, identity-specific alerts
│ Security owns: MDI/MDE, SIEM, security policies
│ Engage Security if: Compromise suspected, unusual activity
│ What they need: Account names, timestamps, suspicious events

Applications ─────────────────────────────────────────────
│ Identity owns: Service accounts, SPNs, delegation
│ App teams own: Application configuration, app-level auth
│ Engage App team if: App-specific errors post-authentication
│ What they need: User context, authentication proof, timestamps
```

---

## Escalation Decision Tree

```
WHEN TO ESCALATE TO OTHER TEAMS:

Authentication Failure
│
├── Can user get Kerberos ticket? (klist)
│   ├── NO → Identity team continues
│   └── YES → Can user reach the target service?
│       ├── NO → Engage NETWORK
│       └── YES → Does service accept the ticket?
│           ├── NO → Check SPN → Identity
│           └── YES → Access denied?
│               ├── NO → APPLICATION issue
│               └── YES → Check permissions
│                   ├── AD permissions → Identity
│                   └── App permissions → APPLICATION

Connectivity Failure
│
├── Can client resolve DNS? → NO → NETWORK (unless AD-integrated DNS)
├── Can client reach DC? → NO → NETWORK
├── Are ports open? → NO → NETWORK (firewall team)
└── Is latency acceptable? → NO → NETWORK

Security Alert
│
├── Is this an identity attack pattern? → YES → SECURITY + Identity
├── Is credential theft suspected? → YES → SECURITY + Identity
├── Is it anomalous but not clearly malicious? → SECURITY review first
└── Is it a false positive from config? → Identity can tune
```

---

## Team Contact Template

### Information Each Team Needs

```
NETWORK TEAM ENGAGEMENT
────────────────────────────────────────────────
Provide:
□ Source IP/hostname
□ Destination IP/hostname
□ Ports required (e.g., 88, 389, 636, 445, 135)
□ Protocol (TCP/UDP)
□ Timestamp of failure
□ Error message or timeout details
□ What changed recently (if known)

Example:
"User workstation (10.1.1.50) cannot reach DC1 (10.2.1.10)
on TCP port 389. Connection times out. Started at 09:15 UTC.
Need firewall rule verification."

SECURITY TEAM ENGAGEMENT
────────────────────────────────────────────────
Provide:
□ Account(s) involved
□ Timestamps (UTC)
□ Event IDs observed
□ Source systems
□ Why you suspect security issue
□ Current containment status
□ Business impact

Example:
"Detecting unusual Kerberos ticket requests for admin accounts
from workstation WKS-123 (10.1.1.99). Event 4769 with RC4
encryption for 15 different service accounts in 2 minutes.
Possible Kerberoasting. Account not yet disabled, awaiting
guidance."

APPLICATION TEAM ENGAGEMENT
────────────────────────────────────────────────
Provide:
□ User identity verified
□ Authentication succeeded (proof: how verified)
□ Authorization in AD verified (group membership)
□ Error message from application
□ What user was trying to do
□ Timestamp of failure

Example:
"User jsmith is receiving 'Access Denied' in AppX. Confirmed:
- Kerberos TGT obtained (klist verified)
- Service ticket for AppX obtained
- User is member of AppX-Users group
- Token contains expected SIDs
Application is returning HTTP 403 with message 'Insufficient
privileges for operation X'. This appears to be app-level
authorization, not AD."
```

---

## SLA and Response Expectations

### By Team and Severity

```
RESPONSE TIME EXPECTATIONS:

P0 (Critical - Widespread Outage)
├── Identity: Immediate (on-call)
├── Network: Immediate (on-call)
├── Security: Immediate (on-call)
├── Application: Immediate (critical apps only)
└── Management: Notified within 15 minutes

P1 (High - Significant Impact)
├── Identity: < 30 minutes
├── Network: < 30 minutes
├── Security: < 1 hour
├── Application: < 1 hour
└── Management: Notified within 1 hour

P2 (Medium - Limited Impact)
├── Identity: < 4 hours
├── Network: < 4 hours
├── Security: < 4 hours
├── Application: Next business day
└── Management: As needed

P3 (Low - Minimal Impact)
├── All teams: Next business day
└── Management: Weekly summary
```

---

## Handoff Documentation Template

### When Transferring to Another Team

```
INCIDENT HANDOFF

From: Identity Team
To: [Team Name]
Date/Time: [UTC]
Incident: [Number]

SUMMARY:
[2-3 sentences describing issue]

IDENTITY INVESTIGATION COMPLETED:
□ AD authentication verified working
□ Kerberos functioning normally
□ Account status verified
□ Group membership verified
□ Replication current
□ DNS resolution working (AD DNS)

EVIDENCE SUPPORTING HANDOFF:
1. [Evidence point 1]
2. [Evidence point 2]
3. [Evidence point 3]

WHY THIS IS [TEAM'S] ISSUE:
[Clear explanation of why identity is ruled out]

RECOMMENDED INVESTIGATION:
[Suggestions for receiving team]

IDENTITY TEAM CONTACT:
[Name/contact for questions]

IDENTITY TEAM STATUS: RELEASED / STANDBY
```

---

## Common Handoff Scenarios

### "It's the Network" Handoff

```
Evidence required before handoff:
□ Authentication to DC works from another network path
□ Same user can authenticate from different location
□ Network trace shows connection failure or timeout
□ Identity components verified healthy

Handoff statement:
"Identity investigation complete. User can authenticate normally
from [other location]. Issue appears when user is on [network/
subnet]. Connectivity test shows [specific failure]. Handing
off to Network team for firewall/routing investigation."
```

### "It's the Application" Handoff

```
Evidence required before handoff:
□ Kerberos authentication succeeds (ticket obtained)
□ User has correct group memberships
□ Same user can access OTHER services
□ Application returns non-identity error

Handoff statement:
"Identity investigation complete. User successfully
authenticates (Kerberos TGT and service ticket verified).
User has required group memberships for [app]. User can
access [other services]. Application is returning [specific
error]. Handing off to [App] team for application-level
troubleshooting."
```

### "It's Security" Escalation

```
Evidence required before escalation:
□ Suspicious activity pattern identified
□ Timestamps documented
□ Affected accounts listed
□ Current containment status noted

Escalation statement:
"Potential security incident detected. Observing [specific
pattern] affecting [accounts] starting at [time]. Pattern
suggests [attack type]. Current status: [contained/monitoring/
active]. Requesting Security team engagement for [specific ask:
investigation/containment decision/forensics]."
```

---

## Anti-Patterns to Avoid

```
DON'T DO THIS:

✗ "It's not our problem" without evidence
✗ Handoff without documentation
✗ Escalate to security without specific concern
✗ Blame network without connectivity proof
✗ Blame application without auth verification
✗ Handoff during active P0 without warm transfer
✗ Close your involvement without confirmation received

DO THIS INSTEAD:

✓ Document your investigation thoroughly
✓ Provide specific evidence for handoff
✓ Stay engaged until receiving team confirms
✓ Offer to assist even after handoff
✓ Be available for questions
✓ Follow up to ensure resolution
```

---

## Related Documents

- [Proving Not AD or Entra](../07_PROOF_AND_EXONERATION/proving_not_ad_or_entra.md) - Evidence for exoneration
- [Blast Radius Analysis](../01_IDENTITY_P0_COMMAND/blast_radius_analysis.md) - Impact assessment
- [Executive Translation](../01_IDENTITY_P0_COMMAND/executive_translation.md) - Communication templates
