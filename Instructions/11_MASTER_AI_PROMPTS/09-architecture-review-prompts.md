# 09 — AD Architecture Review Prompts

> **What this is**: Prompts for reviewing, analyzing, and improving Active Directory architecture. These are the questions a Gartner analyst or Microsoft Architecture Review Board would ask — now available as AI prompts.

---

## PROMPT 1: Comprehensive AD Architecture Review

```
You are a Principal Active Directory Architect conducting a formal architecture review. Evaluate the following environment against Microsoft best practices, security frameworks, and enterprise operational standards.

REVIEW FRAMEWORK:

### 1. Forest & Domain Design
Assess:
- Is the number of forests/domains justified? (Microsoft recommends fewest possible)
- Is the domain functional level current? (Target: Windows Server 2016+)
- Is there a dedicated forest for privileged access (Red Forest/Enhanced Security Admin Environment)?
- Are domain names aligned with DNS naming best practices?
- Is the forest/domain structure documented and understood?

### 2. Domain Controller Architecture
Assess:
- DC count: Is there adequate redundancy per site? (Minimum 2 DCs per site with users)
- DC placement: Are DCs physically distributed to minimize WAN dependency?
- DC OS: Are all DCs on supported OS? (Server 2019+ preferred, 2022 for new)
- DC sizing: Are DCs appropriately sized? (RAM ≥ 8GB for small, ≥ 16GB for large)
- RODC deployment: Are branch offices using RODCs appropriately?
- GC placement: Are GC servers appropriate per site (consider Exchange, applications)?
- Virtualization: Are VMs following snapshot/checkpoint best practices? (NEVER snapshot AD DCs)

### 3. FSMO Role Placement
Assess:
- PDC Emulator: In most heavily populated/reliable site? Fastest DC?
- RID Master: In same domain as PDC Emulator (recommended)
- Infrastructure Master: NOT on a GC server (unless all DCs are GCs)
- Schema Master: In forest root domain, accessible for schema updates
- Domain Naming Master: In forest root domain
- Are roles documented and known to the team?

### 4. Site Topology & Replication
Assess:
- Site definitions: Do AD sites match physical network topology?
- Subnet assignments: Are all subnets assigned to a site?
- Site link costs: Do costs reflect WAN bandwidth/latency?
- Replication schedule: Is 24/7 replication appropriate, or are scheduled windows needed?
- Bridgehead servers: Are manual bridgeheads configured (only if ISTG behavior is problematic)?
- Replication monitoring: Are replication failures being alerted on?

### 5. DNS Architecture
Assess:
- AD-integrated zones: Are all AD zones AD-integrated? (Should be)
- DNS scavenging: Is scavenging enabled on all zones? (Should be with correct intervals)
- Forwarders: Are external DNS forwarders configured? (Avoid root hints in enterprise)
- Conditional forwarders: Are all trust partner zones forwarded?
- DNS on DCs: Is DNS running on ALL DCs? (Recommended)
- Split DNS: Is internal DNS separated from external? (Should be)

### 6. Security Architecture (Tiered Access Model)
Assess:
- Tier 0 separation: Are Domain Admins accounts separate from day-to-day use?
- Tier 0 assets: DCs, ADFS, AD CS, AAD Connect — are they isolated from Tier 1/2?
- Admin workstations: Do admins use PAWs (Privileged Access Workstations)?
- LAPS: Is LAPS (or Windows LAPS) deployed for local admin passwords?
- Credential Guard: Is Credential Guard enabled on workstations?
- Protected Users: Are Tier 0 accounts in the Protected Users security group?
- JIT: Is there a JIT (Just-in-Time) access solution for privileged access?
- Audit logging: Are all DCs collecting the right audit events?

### 7. Hybrid Identity Architecture
Assess:
- AAD Connect: Is it on current version? High availability (staging mode)?
- Sync scope: Is sync scope appropriate? (Don't sync Tier 0 accounts to cloud)
- Auth method: PHS vs PTA vs ADFS — is the choice right for your risk tolerance?
- Seamless SSO: Is it configured if using PHS/PTA?
- Password writeback: Is it secured? (Writes cloud password changes back to on-prem)
- Device writeback: Is it needed? Hybrid join vs pure Entra join strategy?

### 8. Certificate Services (AD CS)
Assess:
- CA hierarchy: Is there a proper two-tier hierarchy? (Offline root CA required for enterprise PKI)
- Online CRL: Is the CRL distribution point accessible and up to date?
- Templates: Are certificate templates following least-privilege design?
- Auto-enrollment: Is auto-enrollment working for all clients?
- Expiry monitoring: Are certificate expirations being monitored?

### 9. Operational Maturity
Assess:
- Backup: Is AD System State backed up on all DCs? Frequency? Tested?
- Monitoring: Are there alerts for: replication failures, DC offline, lockout storms, FSMO seizure?
- Documentation: Is the environment documented? Last updated?
- DR: Is there a tested DR procedure for domain controller loss?
- Change management: Are AD changes going through CAB?

---

OUTPUT FORMAT:
For each section, provide:
✅ COMPLIANT — what's good
⚠️ WARNING — what needs attention (with priority)
❌ CRITICAL GAP — what must be fixed (with business risk)

Then:
### Risk Register
[Table: Risk | Likelihood | Impact | Priority | Recommended Action]

### Recommended Roadmap
[Phased 90-day plan: Quick wins → Short-term → Long-term]

---

ENVIRONMENT DATA:
[Describe your AD environment — forest structure, DC count, sites, current tools, known pain points]
```

---

## PROMPT 2: Active Directory Security Architecture Review

```
Conduct a security-focused AD architecture review from an attacker's perspective. For each control area, describe:
1. The attack technique it's meant to stop
2. Whether typical configurations actually stop it
3. How to verify the control is working
4. How to test it safely (without impacting production)

CONTROL AREAS TO REVIEW:

### Credential Theft Prevention
- LAPS deployment and coverage
- Credential Guard enablement
- WDigest disabled (registry: HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest, UseLogonCredential=0)
- Protected Users group membership for admins
- Restricted Admin Mode for RDP

### Privilege Escalation Prevention
- AdminSDHolder and SDProp configuration
- ACL review on domain root (who has DCSync rights — DS-Replication-Get-Changes-All)
- Group nesting depth and privileged group membership
- AdminCount attribute audit (who has adminCount=1)
- Kerberos unconstrained delegation scope (who has TrustedForDelegation=TRUE)
- Service account privilege audit (SPN holders, their password age)

### Lateral Movement Prevention
- SMB signing enforcement (GPO: Microsoft network server: Digitally sign communications always)
- NTLMv1 disabled (Network security: LAN Manager authentication level = NTLMv2 only)
- Pass-the-Hash mitigation (Credential Guard, LAPS)
- Kerberoastable accounts (SPN holders with weak passwords)
- AS-REP Roastable accounts (accounts with pre-auth disabled)

### Persistence Prevention
- AdminSDHolder ACL review (no unexpected ACEs)
- Domain controller GPO review (what's applied to DCs?)
- Scheduled tasks on DCs
- WMI subscriptions on DCs
- SIDHistory audit (any accounts with populated SIDHistory?)
- Trust SID filtering status

### Detection Capability
- Event log audit policy configuration
- Log forwarding to SIEM
- MDI/MDE deployment and coverage
- Alert coverage for: DCSync, Golden Ticket, Kerberoasting, Lateral Movement
- Honey accounts (deception detection)

---

ENVIRONMENT CONTEXT:
[Tools available: MDI/MDE/Sentinel/Splunk, current known gaps, recent security incidents]

For each control, provide:
- Current risk level: 🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Acceptable
- Verification command (read-only)
- Remediation if gap found
- Detection query to alert on exploitation
```

---

## PROMPT 3: Migration Architecture Planning

```
Design an Active Directory modernization/migration plan for the following environment. Consider:

MODERNIZATION DIMENSIONS:
1. OS Currency — Getting DCs to Windows Server 2022
2. Functional Level — Raising DFL/FFL to take advantage of new features
3. Authentication — Modernizing away from NTLM and weak Kerberos
4. Hybrid — Optimizing the Entra ID integration
5. Security — Implementing Zero Trust principles for identity
6. Tooling — Replacing legacy management tools
7. PKI — Modernizing certificate infrastructure
8. Monitoring — Implementing enterprise-grade observability

FOR EACH DIMENSION, PRODUCE:
- Current State: [What typically exists]
- Target State: [Where we're going]
- Migration Path: [How to get there safely]
- Risk: [What could go wrong]
- Sequencing: [What must be done first]
- Rollback: [Can we undo if needed]
- Timeline: [Realistic timeframe]

THEN PRODUCE:
- Dependency map (what must be done before what)
- Risk-adjusted priority ranking
- 12-month milestone roadmap

CURRENT ENVIRONMENT:
[Describe your environment, constraints, known technical debt]
```
