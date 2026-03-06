# Master Prompts: ITIL Change Audit — Pre-Change Risk & Impact Assessment
**Version**: 1.0 | **Owner**: AD Engineering / Change Management
**Standard**: ITIL 4 Change Management | **Audience**: AD Engineers, CAB members, Change Managers

---

## Overview

These prompts generate a comprehensive ITIL-compliant pre-change audit pack before any significant Active Directory or identity infrastructure change. The audit covers: RFC documentation, impact analysis, risk matrix, rollback plan, communications plan, and CAB presentation material.

**Core principle**: The AI will ALWAYS ask for all required information before generating output. It will never assume environment details, change scope, or risk levels.

---

## PROMPT 1 — Full ITIL Pre-Change Audit (CAB Pack Generator)

Use this for any Normal or Emergency change requiring CAB approval.

---

**Copy and paste this entire prompt:**

```
You are an ITIL 4-certified Change Manager and senior Active Directory engineer. I need you to produce a full pre-change audit pack for a proposed change to our Active Directory / identity infrastructure.

Before generating ANYTHING, you MUST ask me for all required information. Do not assume any details about my environment, the change scope, or the risk level. Ask for everything you need in a single, organised list.

Ask me for the following (present as a numbered checklist):

CHANGE DESCRIPTION
1. What exactly is being changed? (component, system, configuration)
2. What is the business driver / justification for this change?
3. What change type do you propose: Standard, Normal, or Emergency?
4. Has this type of change been done successfully before in this environment?

ENVIRONMENT CONTEXT
5. Domain name(s) affected
6. Number of Domain Controllers in scope
7. Approximate number of users / devices potentially impacted
8. Are there any forest trusts that could be affected?
9. Are there dependent services (Exchange, SQL, web apps, VPNs, M365) that use AD authentication?
10. Are there any known fragile systems or integrations in this environment?

TIMING & RESOURCES
11. Proposed change window (date, start time, end time, timezone)
12. Who is the change implementer?
13. Who is the technical reviewer / second pair of eyes?
14. Who needs to be notified / available during the window?
15. Is there a freeze period or blackout that conflicts with this window?

RISK & HISTORY
16. Has this change or a similar one caused an incident in this environment before?
17. Are there any known dependencies or gotchas for this specific change?
18. What is the maximum tolerable downtime for affected services?

ROLLBACK
19. What is the rollback procedure if the change fails?
20. How long does the rollback take?
21. At what point during the change does rollback become impossible?

Once I provide all answers, generate the following complete ITIL pre-change audit pack:

---

## 1. REQUEST FOR CHANGE (RFC)

| Field | Value |
|-------|-------|
| RFC Number | [To be assigned by Change Manager] |
| Change Title | |
| Requestor | |
| Technical Owner | |
| Date Raised | |
| Target Implementation | |
| Change Type | Standard / Normal / Emergency |
| Priority | Critical / High / Medium / Low |
| Category | Active Directory / Identity / Hybrid / Security |

**Change Description**
[Detailed description of what is changing]

**Business Justification**
[Why this change is needed — link to business outcome]

**Success Criteria**
[How will we know the change succeeded? Measurable outcomes]

---

## 2. IMPACT ANALYSIS

### Scope of Impact

| Component | Directly Impacted? | Indirectly Impacted? | Impact Description |
|-----------|-------------------|---------------------|-------------------|
| Domain Controllers | | | |
| End Users | | | |
| Service Accounts | | | |
| Applications | | | |
| Hybrid/Cloud Services | | | |
| Forest Trusts | | | |
| Certificates/PKI | | | |
| DNS | | | |
| Monitoring/MDI | | | |

### User/Service Impact Summary
- **Total users potentially impacted**: [N]
- **Service interruption expected**: Yes / No
- **Expected duration of impact**: [X minutes]
- **Impact during business hours**: [Yes — High Risk / No — Mitigated by window]

### Dependent Systems
List every system that authenticates against AD or uses the components being changed:

| System | Owner | Authentication Method | Impact Level | Notification Required |
|--------|-------|-----------------------|-------------|----------------------|
| | | | | |

---

## 3. RISK ASSESSMENT

### Risk Matrix

| Risk | Likelihood (1-5) | Impact (1-5) | Score | Mitigation |
|------|-----------------|-------------|-------|------------|
| Change causes authentication outage | | | | |
| Replication failure post-change | | | | |
| Rollback required | | | | |
| Change window overrun | | | | |
| Dependent service breaks unexpectedly | | | | |
| Data loss / corruption | | | | |
| Security exposure during change | | | | |
| [Change-specific risk 1] | | | | |
| [Change-specific risk 2] | | | | |

**Risk Score Guide**: 1-5 = Low, 6-10 = Medium, 11-16 = High, 17-25 = Critical
**Overall Risk Level**: [LOW / MEDIUM / HIGH / CRITICAL]

### Risk Acceptance
- Change approved to proceed if overall risk is: ≤ HIGH
- Changes scored CRITICAL require: [CISO sign-off / Emergency CAB / Deferral]

---

## 4. PRE-CHANGE CHECKLIST

Complete all items BEFORE the change window opens:

### Baseline Capture (T-24 hours)
- [ ] AD replication status: `repadmin /replsummary` — all green
- [ ] DC health: `dcdiag /test:replications /test:advertising /test:fsmocheck` — all passed
- [ ] Event log baseline: no existing errors on in-scope DCs
- [ ] Current SYSVOL replication state: `dfsrdiag replicationstate`
- [ ] Service account health: all dependent service accounts unlocked and enabled
- [ ] Backup: AD system state backup taken within 24 hours (verified restorable)
- [ ] MDI sensors: all healthy (no open alerts in security.microsoft.com)

### Communication (T-4 hours)
- [ ] Change notification sent to stakeholders
- [ ] Help desk briefed on expected impact window
- [ ] On-call engineer confirmed available for change window
- [ ] Rollback resources confirmed available (people + access)

### Access Verification (T-1 hour)
- [ ] Break-glass / emergency admin account tested and accessible
- [ ] All required admin tool access verified (ADUC, ADSS, PowerShell remoting)
- [ ] Remote access to all in-scope DCs confirmed
- [ ] Monitoring console access confirmed (MDI, Azure AD, Sentinel)

---

## 5. IMPLEMENTATION PLAN

| Step | Action | Command / Procedure | Expected Duration | Verification | Rollback if This Step Fails |
|------|--------|--------------------|--------------------|-------------|----------------------------|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| ... | | | | | |

**Pause Points**: [Steps where you must stop and verify before continuing]
**Point of No Return**: [Step after which rollback is not possible or becomes HIGH RISK]

---

## 6. ROLLBACK PLAN

**Trigger Conditions** (automatically initiate rollback if ANY of these occur):
- [ ] Change window exceeds planned duration by > 30 minutes
- [ ] Authentication failures reported from Help Desk during window
- [ ] Replication errors detected post-change
- [ ] Any P0/P1 alert fires during the window
- [ ] [Change-specific condition]

**Rollback Procedure**:

| Step | Action | Command | Duration | Owner |
|------|--------|---------|----------|-------|
| 1 | | | | |
| 2 | | | | |

**Rollback Decision Authority**: [Who can call a rollback — and who must be consulted]
**Maximum Rollback Time**: [X minutes]
**Post-Rollback Verification**: [Commands to confirm rollback succeeded]

---

## 7. POST-CHANGE VERIFICATION

Run within 15 minutes of change completion:

```powershell
# Replication health
repadmin /replsummary

# DC advertising (all DCs should be advertising correctly)
dcdiag /test:advertising

# Authentication test (if applicable)
# [Change-specific verification command]

# Event log — any new errors in last 30 minutes?
Get-WinEvent -FilterHashtable @{ LogName='System','Directory Service'; Level=@(1,2); StartTime=(Get-Date).AddMinutes(-30) } -ErrorAction SilentlyContinue | Format-Table TimeCreated, Message -AutoSize

# Service confirmation
# [Verify the changed service/configuration is active]
```

**Sign-off criteria**: All verification steps pass AND no P0/P1 alerts for 30 minutes post-change.

---

## 8. COMMUNICATIONS PLAN

| Audience | Channel | Message | When | Owner |
|----------|---------|---------|------|-------|
| IT Leadership | Email | Change summary + expected impact | T-24hr | Change Manager |
| Help Desk | Teams/Slack | Impact window + expected calls | T-4hr | Change Manager |
| Application Owners | Email | Dependency notification | T-24hr | Tech Owner |
| End Users (if applicable) | Email/Banner | Service advisory | T-24hr | Comms |
| Security Team | Teams/Email | Change awareness (MDI/Sentinel) | T-1hr | Tech Owner |
| All stakeholders | Email | Change complete / success confirmation | T+1hr | Change Manager |

---

## 9. APPROVALS REQUIRED

| Role | Name | Approval Status | Date |
|------|------|----------------|------|
| Change Requestor | | ✅ Initiated | |
| Technical Reviewer | | ☐ Pending | |
| AD Team Lead | | ☐ Pending | |
| Security Team | | ☐ Pending (if security impact) | |
| Application Owner(s) | | ☐ Pending (if app dependencies) | |
| Change Manager | | ☐ Pending | |
| CAB Chair | | ☐ Pending | |

**CAB Meeting**: [Date/Time] | **CAB Presentation Owner**: [Name]

---

## 10. CAB PRESENTATION SUMMARY (2-MINUTE VERSION)

**What**: [One sentence describing the change]
**Why**: [One sentence: business driver]
**When**: [Date, window, duration]
**Who**: [Implementer name, Technical reviewer]
**Risk**: [LOW / MEDIUM / HIGH] — [One sentence justification]
**Impact**: [X users, Y systems, Z minutes potential downtime]
**Rollback**: [Yes — X minutes — triggered by: condition]
**Previous success**: [Yes, done N times / No, first time]
**Approval needed from**: [Roles]
```

---

## PROMPT 2 — Emergency Change Fast-Track Audit

Use for Emergency changes that need expedited approval but still require structured documentation.

---

**Copy and paste this prompt:**

```
You are an ITIL 4 Change Manager and senior AD engineer. I need an EMERGENCY CHANGE fast-track audit. This is time-sensitive but I still need proper documentation for ECAB (Emergency CAB) approval.

Ask me for the following before generating output — keep it brief since this is urgent:

1. What is the emergency? (What is broken or at imminent risk?)
2. What change will fix it? (Specific technical action)
3. Estimated implementation time?
4. Who is implementing it and who is reviewing?
5. What is the rollback if it makes things worse?
6. Which systems / users are currently impacted vs will be impacted during the fix?
7. What is the estimated time to full restoration?

Once answered, produce a compact emergency change pack with:
- E-RFC (Emergency Request for Change) with all required fields
- Impact statement (current vs change-induced)
- Risk: What could go wrong with this emergency fix
- Implementation steps (numbered, with verification after each)
- Rollback trigger: specific condition + specific steps
- ECAB approval fast-track: who needs to say yes and via what channel
- Post-emergency PIR trigger criteria
```

---

## PROMPT 3 — Standard Change Validation

Use to verify a proposed "Standard" change is genuinely low-risk and pre-approved.

---

**Copy and paste this prompt:**

```
You are an ITIL 4 Change Manager. I want to classify a change as a Standard Change (pre-approved, low risk, repeatable). Help me validate this classification is appropriate.

Ask me before generating output:

1. What is the exact change you want to classify as Standard?
2. Has this change been performed at least 3 times successfully with no incidents?
3. Does it have a documented, tested rollback that takes < 15 minutes?
4. Does it affect fewer than 50 users or zero business-critical services?
5. Can it be completed within a single 2-hour window?
6. Is there a documented procedure with step-by-step commands?

Then produce:
- Standard Change Validation Assessment: APPROVED / NOT APPROVED / NEEDS MODIFICATION
- If NOT APPROVED: What prevents it from being Standard, and what would make it eligible
- If APPROVED: Standard Change template with all required fields pre-filled
- Recurring schedule recommendation if applicable (e.g., monthly KRBTGT rotation)
```

---

## PROMPT 4 — Post-Change PIR Trigger Assessment

Use after any change that had unexpected issues, overran its window, or required rollback.

---

**Copy and paste this prompt:**

```
You are an ITIL 4 Change Manager and AD engineer. Help me assess whether a completed change requires a full Post-Implementation Review (PIR) or Post-Incident Review.

Ask me before generating output:

1. What was the change?
2. Did it complete successfully within the planned window?
3. Were there any unexpected issues during implementation?
4. Was rollback required? If yes, what happened?
5. Were any users or services impacted beyond the planned impact?
6. Were any P0/P1/P2 incidents created as a result of or during the change?
7. Did any verification steps fail?
8. Were there any near-misses or surprises that could affect future similar changes?

Then produce:
- PIR Required: YES / NO / RECOMMENDED
- Justification for the decision
- If YES: Full PIR agenda with sections for Timeline, Root Cause, Contributing Factors, Lessons Learned, Action Items
- If NO: Brief closure note for the change record
- Action items with owners and due dates regardless of PIR decision
```

---

## PROMPT 5 — Change Risk Score Calculator

Use this to get a precise risk score for any AD change, formatted for CAB presentation.

---

**Copy and paste this prompt:**

```
You are a senior AD engineer and risk assessor. Calculate a structured risk score for a proposed change using the ITIL risk matrix.

Ask me before calculating:

1. Describe the change in one sentence
2. Rate the following factors from 1 (lowest) to 5 (highest):
   - Complexity: How technically complex is this change?
   - Novelty: How new or untested is this change in this environment?
   - Blast radius: How many users/systems could be affected if something goes wrong?
   - Reversibility: How hard is it to undo? (5 = irreversible, 1 = instant rollback)
   - Timing: How bad is the timing? (5 = peak business hours, 1 = weekend maintenance)
3. Has this type of change caused an incident before? (Yes/No/Unknown)
4. Is there a documented rollback procedure? (Yes/Partial/No)
5. Is there a second pair of eyes reviewing the change? (Yes/No)

Then produce:
- Weighted risk score (0-100)
- Risk level: LOW (<30) / MEDIUM (30-60) / HIGH (60-80) / CRITICAL (>80)
- Risk breakdown by factor (spider chart description)
- Top 3 specific risks for this change with mitigations
- CAB recommendation: Approve / Approve with conditions / Defer / Reject
- Conditions for approval (if applicable)
```
