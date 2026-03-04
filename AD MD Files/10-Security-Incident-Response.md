# Active Directory Security & Incident Response

## AI Prompts for AD Security Monitoring and Incident Response

---

## Overview

Active Directory is a prime target for attackers due to its central role in enterprise authentication and authorization. Detecting, responding to, and recovering from AD security incidents requires specialized knowledge and rapid action. This module provides AI prompts for security monitoring, threat detection, and incident response.

---

## Section 1: Security Assessment

### Prompt 1.1: AD Security Posture Assessment

```
I need to assess the security posture of my Active Directory environment.

ENVIRONMENT:
- Forest/domain structure: [Describe]
- Number of DCs: [X]
- Domain functional level: [Level]
- Admin accounts: [Approximate count]
- Service accounts: [Approximate count]

CURRENT SECURITY MEASURES:
[Describe existing security controls]

COMPLIANCE REQUIREMENTS:
[If applicable - PCI, HIPAA, etc.]

Please provide:
1. Comprehensive AD security assessment checklist
2. Privileged access audit areas
3. Attack surface analysis points
4. Configuration weaknesses to check
5. Trust and delegation review
6. Service account security audit
7. Priority remediation recommendations
```

### Prompt 1.2: Privileged Account Audit

```
I need to audit privileged accounts in Active Directory.

CURRENT KNOWLEDGE:
- Domain Admins count: [If known]
- Enterprise Admins count: [If known]
- Schema Admins count: [If known]
- Local admin access: [Managed/Unknown]

Please provide:
1. Commands to enumerate all privileged accounts
2. Identifying nested group memberships
3. Finding accounts with dangerous rights
4. Service accounts with excessive privileges
5. Dormant privileged accounts
6. Accounts with non-expiring passwords
7. Delegation and impersonation rights audit
8. Recommendations for privilege reduction
```

---

## Section 2: Attack Detection

### Prompt 2.1: Detecting Active Directory Attacks

```
I want to monitor for common AD attacks in my environment.

AVAILABLE MONITORING:
- SIEM: [Product or none]
- Windows Event Forwarding: [Configured/Not]
- Advanced auditing: [Enabled/Not]

ATTACKS TO DETECT:
[List specific concerns or "comprehensive coverage"]

Please provide:
1. Event IDs for detecting common AD attacks
2. Kerberoasting detection
3. Pass-the-Hash / Pass-the-Ticket detection
4. DCSync attack detection
5. Golden Ticket / Silver Ticket indicators
6. Reconnaissance detection (enumeration)
7. LDAP-based attack detection
8. SIEM queries or detection rules
```

### Prompt 2.2: Suspicious Activity Investigation

```
I've detected suspicious activity that may indicate AD compromise.

SUSPICIOUS INDICATORS:
[Describe what was observed - events, behaviors, alerts]

AFFECTED ACCOUNTS/SYSTEMS:
[List if known]

TIMELINE:
- First observed: [Date/time]
- Ongoing: [Yes/No]

Please provide:
1. Immediate containment considerations
2. Investigation scope determination
3. Evidence collection procedures
4. Related events to search for
5. Lateral movement analysis
6. Persistence mechanism check
7. Escalation criteria
8. Documentation requirements
```

### Prompt 2.3: Kerberos Attack Investigation

```
I suspect Kerberos-based attacks in my environment.

ATTACK TYPE SUSPECTED: [Kerberoasting, Golden Ticket, Silver Ticket, AS-REP Roasting]

INDICATORS:
[Describe what triggered this investigation]

EVENT LOG DATA:
[Paste relevant Security event log entries]

Please provide:
1. Confirm attack type from indicators
2. Scope of potential compromise
3. Identifying targeted accounts
4. Detection queries for this attack type
5. Immediate response actions
6. Long-term remediation
7. Monitoring improvements
```

---

## Section 3: Incident Response

### Prompt 3.1: AD Compromise Response Framework

```
INCIDENT: Active Directory compromise confirmed or strongly suspected.

SEVERITY ASSESSMENT:
- Scope: [Single account, multiple accounts, domain admin, forest]
- Persistence suspected: [Yes/No]
- Data exfiltration suspected: [Yes/No]
- Business impact: [Describe]

CURRENT STATUS:
- Attacker still active: [Yes/No/Unknown]
- Containment actions taken: [List]

Please provide:
1. Incident response priority actions
2. Evidence preservation requirements
3. Containment strategies by compromise level
4. Eradication procedures
5. Recovery planning
6. Communication requirements
7. Post-incident activities
```

### Prompt 3.2: Domain Admin Compromise Response

```
CRITICAL: Domain Administrator credentials have been compromised.

COMPROMISED ACCOUNT: [Account name if known]
COMPROMISE METHOD: [If known - phishing, credential theft, etc.]
ATTACKER ACTIVITY OBSERVED: [Describe known actions]

ENVIRONMENT:
- Number of Domain Admins: [X]
- Forest scope: [Single domain/Multi-domain]

Please provide:
1. Immediate containment actions
2. Disabling without alerting attacker (if still active)
3. Identifying attacker's activities
4. Checking for persistence mechanisms
5. Golden Ticket consideration
6. Password reset strategy
7. Krbtgt reset requirements
8. Recovery and hardening steps
```

### Prompt 3.3: Krbtgt Account Reset Procedure

```
I need to reset the krbtgt account password.

REASON: [Suspected compromise, routine security, incident response]
URGENCY: [Immediate/Planned]

ENVIRONMENT:
- Domain functional level: [Level]
- Number of DCs: [X]
- Read-Only DCs: [Yes/No, count]
- Replication health: [Status]

Please provide:
1. Krbtgt reset implications
2. Pre-reset preparations
3. Single reset vs. double reset decision
4. Step-by-step reset procedure
5. Timing between resets
6. Monitoring for issues after reset
7. RODC krbtgt considerations
8. Verification of successful reset
```

---

## Section 4: Credential Theft Response

### Prompt 4.1: Pass-the-Hash Attack Response

```
Pass-the-Hash attack has been detected.

INDICATORS:
[Describe detection - NTLM events, lateral movement patterns]

AFFECTED ACCOUNTS:
[List if known]

LATERAL MOVEMENT OBSERVED:
[Describe movement patterns]

Please provide:
1. Confirm PtH attack indicators
2. Scope the compromise
3. Identify source of stolen hashes
4. Containment actions
5. Password reset requirements
6. Protected Users group consideration
7. Credential Guard deployment
8. Long-term mitigations
```

### Prompt 4.2: DCSync Attack Response

```
CRITICAL: DCSync attack detected or suspected.

EVIDENCE:
[Describe - Event 4662 with specific rights, unusual replication]

ACCOUNT PERFORMING DCSYNC:
[Account name if identified]

TIMEFRAME:
[When activity occurred]

Please provide:
1. Confirm DCSync activity
2. Full scope assessment
3. Immediate containment
4. Identify all extracted credentials
5. Mass password reset considerations
6. Krbtgt reset decision
7. Remove replication rights from compromised account
8. Monitoring for continued activity
```

---

## Section 5: Persistence Detection and Removal

### Prompt 5.1: AD Persistence Mechanism Hunt

```
I need to check for attacker persistence mechanisms in AD.

CONTEXT:
[Describe incident or concern that prompted this]

AREAS TO CHECK:
[Specific concerns or "comprehensive"]

Please provide:
1. Common AD persistence mechanisms
2. AdminSDHolder tampering detection
3. Skeleton Key detection
4. SID History abuse detection
5. Malicious GPO detection
6. DCShadow indicators
7. Golden Ticket persistence
8. Scheduled task and service abuse
9. Remediation for each persistence type
```

### Prompt 5.2: AdminSDHolder Investigation

```
I need to investigate AdminSDHolder for tampering.

CONCERN:
[What triggered this investigation]

Please provide:
1. AdminSDHolder function explained
2. Normal vs. suspicious ACL entries
3. How to check AdminSDHolder permissions
4. SDProp process verification
5. Detecting permission backdoors
6. Protected groups membership audit
7. Remediation if tampering found
8. Monitoring going forward
```

### Prompt 5.3: SID History Abuse Detection

```
I need to check for SID History abuse.

ENVIRONMENT:
- Recent migrations: [Yes/No, when]
- Legitimate SID History expected: [Yes/No]
- Trust relationships: [List]

Please provide:
1. SID History explained and legitimate uses
2. How to enumerate SID History on accounts
3. Identifying suspicious SID History values
4. Detecting privileged SIDs in history
5. Remediation procedure
6. SID filtering on trusts
7. Monitoring for SID History abuse
```

---

## Section 6: Hardening and Prevention

### Prompt 6.1: Privileged Access Hardening

```
I want to implement privileged access security improvements.

CURRENT STATE:
- Admin workstation strategy: [None/In progress/Implemented]
- Tiered admin model: [None/Partial/Full]
- PAM solution: [None/Product name]

GOALS:
[Describe security objectives]

Please provide:
1. Tiered administration model design
2. Privileged Access Workstations (PAWs)
3. Protected Users group implementation
4. Fine-grained password policies for admins
5. Just-In-Time / Just-Enough-Administration
6. Admin forest considerations
7. Credential Guard deployment
8. Implementation roadmap
```

### Prompt 6.2: Authentication Security Hardening

```
I want to improve authentication security in AD.

CURRENT STATE:
- NTLMv1 status: [Allowed/Blocked/Unknown]
- NTLMv2 enforced: [Yes/No]
- Kerberos AES: [Enabled/Not]
- Protected Users: [In use/Not]

Please provide:
1. NTLM restriction strategy
2. Kerberos security improvements
3. Protected Users group deployment
4. Authentication Policies and Silos
5. Credential caching controls
6. Smart card/MFA implementation
7. Monitoring authentication events
8. Staged implementation plan
```

---

## Section 7: Forensics and Evidence

### Prompt 7.1: AD Forensic Data Collection

```
I need to collect forensic evidence from Active Directory.

INCIDENT TYPE: [Describe]
LEGAL/HR INVOLVED: [Yes/No]
EVIDENCE REQUIREMENTS: [Court admissible, internal only]

SYSTEMS TO COLLECT FROM:
[List DCs, member servers, etc.]

Please provide:
1. Evidence collection priorities
2. Chain of custody requirements
3. AD database snapshot collection
4. Event log collection and preservation
5. Registry evidence
6. Memory acquisition considerations
7. Timeline construction
8. Documentation requirements
```

### Prompt 7.2: Attack Timeline Construction

```
I need to construct a timeline of attacker activity in AD.

KNOWN INDICATORS:
[List known events, accounts, times]

DATA SOURCES AVAILABLE:
- Security logs: [Retention period]
- Other logs: [List]
- SIEM data: [Available/Not]

Please provide:
1. Key events to search for
2. Correlating events across systems
3. Building activity timeline
4. Identifying initial access
5. Mapping lateral movement
6. Identifying persistence establishment
7. Determining scope of access
8. Timeline documentation format
```

---

## Section 8: Security Monitoring

### Prompt 8.1: AD Security Monitoring Setup

```
I want to implement comprehensive AD security monitoring.

CURRENT MONITORING:
[Describe existing capabilities]

AVAILABLE TOOLS:
- SIEM: [Product]
- Log collection: [Method]
- Alerting: [Capabilities]

Please provide:
1. Essential events to monitor
2. Audit policy configuration
3. Windows Event Forwarding setup
4. SIEM use cases for AD
5. Alert tuning to reduce noise
6. Baseline establishment
7. Alerting thresholds
8. Response procedures for alerts
```

### Prompt 8.2: Advanced Threat Detection

```
I want to detect advanced AD attacks.

CURRENT DETECTION CAPABILITIES:
[Describe]

SPECIFIC THREATS OF CONCERN:
[List or "comprehensive"]

Please provide:
1. Advanced attack detection strategies
2. Behavioral analysis approaches
3. Honey tokens and deception
4. Canary accounts and objects
5. Anomaly detection rules
6. Threat hunting queries
7. Integration with threat intelligence
8. Detection validation (testing)
```

---

## Section 9: Recovery from Compromise

### Prompt 9.1: Post-Compromise Forest Recovery

```
CRITICAL: Full forest recovery from compromise is needed.

COMPROMISE LEVEL: [Domain Admin / Enterprise Admin / Full forest]
ATTACKER ACCESS DURATION: [Known/Estimated timeframe]
PERSISTENCE CONFIRMED: [Yes/No/Unknown]

AVAILABLE RESOURCES:
- Clean backups: [Yes/No, dates]
- Isolated environment: [Available/Not]

Please provide:
1. Decision: Recover vs. rebuild
2. Forest recovery procedure
3. Removing all attacker persistence
4. Password reset strategy (all accounts)
5. Krbtgt double reset timing
6. Trust relationship handling
7. Validation of clean state
8. Enhanced security implementation
```

### Prompt 9.2: Tactical Account Reset

```
I need to perform mass password resets after a security incident.

SCOPE: [All users, privileged only, specific groups]
INCLUDE SERVICE ACCOUNTS: [Yes/No/Separate plan]
URGENCY: [Immediate/Scheduled]

Please provide:
1. Password reset strategy
2. Communication plan
3. Technical procedure for mass reset
4. Service account handling
5. gMSA password refresh
6. Kerberos ticket invalidation
7. User impact mitigation
8. Verification of completion
```

---

## Quick Reference: Security Event IDs

```
# Critical Security Events to Monitor

4624  - Successful logon
4625  - Failed logon
4648  - Explicit credential logon
4662  - Object operation (DCSync detection)
4672  - Special privileges assigned
4673  - Privileged service called
4674  - Privileged object operation
4688  - Process creation
4720  - User account created
4724  - Password reset attempted
4728  - Member added to security group
4732  - Member added to local group
4738  - User account changed
4740  - Account locked out
4756  - Member added to universal group
4768  - Kerberos TGT requested
4769  - Kerberos service ticket requested
4771  - Kerberos pre-auth failed
4776  - NTLM authentication
4946  - Firewall rule added
5136  - Directory object modified
5137  - Directory object created
5141  - Directory object deleted
```

---

## Attack Detection Quick Reference

| Attack | Key Indicators |
|--------|---------------|
| Kerberoasting | 4769 with RC4 encryption, high volume |
| Pass-the-Hash | 4624 type 9 with NTLM, no 4768 |
| Golden Ticket | 4769 without prior 4768 |
| DCSync | 4662 with replication rights |
| Password Spray | Multiple 4771/4625 across accounts |
| AS-REP Roasting | 4768 with pre-auth disabled accounts |
| AdminSDHolder | 5136 on AdminSDHolder object |

---

## Related Modules

- [Authentication & Kerberos](02-Authentication-Kerberos.md) - Authentication security
- [AD Database & Recovery](08-AD-Database-Recovery.md) - Recovery procedures
- [Account Management & Lockouts](13-Account-Management-Lockouts.md) - Account security

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
