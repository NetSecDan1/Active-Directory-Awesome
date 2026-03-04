# 06 — Jira Card Generator Prompts for Active Directory Work

> **What this is**: AI prompts that generate complete, high-quality Jira cards from AD incidents, change requests, projects, and tasks. Includes templates for: Incidents, Change Requests, Projects, Tasks, Security Findings, and Architecture Reviews.

---

## PROMPT 1: AD Incident Jira Card Generator

```
Generate a complete Jira incident card for the following Active Directory incident. Use the exact format below with rich detail.

OUTPUT FORMAT — Jira Story (use Markdown):

---

## 🚨 Incident: [SHORT DESCRIPTIVE TITLE]

**Type**: Incident
**Priority**: [Critical / High / Medium / Low]
**Components**: [AD Replication / Authentication / DNS / GPO / Hybrid Identity / PKI / Security / FSMO]
**Affects Version**: [Domain Functional Level, e.g., Windows Server 2019]
**Labels**: `active-directory` `identity` `[severity-p0/p1/p2]` `[on-prem/hybrid/cloud]`
**Assignee**: [Identity Team / AD Engineering / Security Operations]

---

### Summary
[One sentence that states the business impact, not the technical symptom]
Example: "Authentication failures blocking 2,400 users in the APAC region from accessing corporate resources"

---

### Business Impact
- **Users Affected**: [number and description]
- **Services Affected**: [list key services down]
- **Revenue Impact**: [if applicable]
- **SLA Breach**: [Yes/No — which SLA]
- **Regulatory Exposure**: [if applicable]

---

### Key Insights
- [Bullet 1: Most important finding]
- [Bullet 2: What is NOT the cause (exonerated hypotheses)]
- [Bullet 3: Current state of investigation]
- [Bullet 4: Any unusual patterns]

---

### Timeline
| Time (UTC) | Event |
|-----------|-------|
| HH:MM | [First indication of issue] |
| HH:MM | [Detection/alerting] |
| HH:MM | [Incident declared] |
| HH:MM | [Key diagnostic findings] |
| HH:MM | [Ongoing...] |

---

### Current Hypothesis
**Primary**: [Most likely root cause — X% confidence]
**Secondary**: [Backup hypothesis — X% confidence]

**Evidence For**:
- [Data point 1]
- [Data point 2]

**Evidence Against**:
- [Counter-evidence considered]

---

### Diagnostic Data Collected
- [ ] `repadmin /replsummary` — [status]
- [ ] Event logs from PDC Emulator — [status]
- [ ] `dcdiag /test:replications` — [status]
- [ ] Network connectivity tests — [status]
- [ ] DNS SRV record verification — [status]

---

### Next Steps
| # | Action | Owner | Target Completion | Status |
|---|--------|-------|-------------------|--------|
| 1 | [Immediate action] | [Name] | [Time] | 🔄 In Progress |
| 2 | [Second action] | [Name] | [Time] | ⏳ Pending |
| 3 | [Third action] | [Name] | [Time] | ⏳ Pending |

---

### Blockers
- [List any blockers to resolution — access needed, approvals, vendor support, etc.]

---

### Communication
- **Stakeholder Update Sent**: [Yes/No — Time]
- **Status Page Updated**: [Yes/No]
- **Bridge Call**: [Yes/No — Meeting ID]
- **Incident Commander**: [Name]
- **Subject Matter Expert (AD)**: [Name]

---

### Resolution (Complete after resolution)
**Root Cause**: [Detailed root cause description]
**Resolution**: [Exact steps taken to resolve]
**Resolution Time**: [When incident was resolved]
**MTTR**: [Time from detection to resolution]

---

### Post-Incident Review
**PIR Scheduled**: [Date]
**Action Items from PIR**: [Link to follow-up Jira cards]

---

INCIDENT DATA TO CONVERT:
[Paste your incident details here]
```

---

## PROMPT 2: AD Change Request Card Generator

```
Generate a complete Jira change request card for the following Active Directory change. This card will go to the CAB (Change Advisory Board) for approval.

OUTPUT FORMAT — Jira Change Request:

---

## 🔧 Change Request: [CHANGE TITLE]

**Type**: Change Request
**Change Category**: [Standard / Normal / Emergency]
**Risk Level**: [Low / Medium / High / Critical]
**Priority**: [P1 / P2 / P3 / P4]
**Components**: [affected AD components]
**Labels**: `change-request` `active-directory` `[risk-level]`

---

### Change Summary
[2-3 sentences: what is changing, why, and the expected outcome]

---

### Business Justification
[Why is this change necessary? What problem does it solve or what improvement does it deliver?]

---

### Technical Scope
**What is changing:**
- [Specific change 1]
- [Specific change 2]

**What is NOT changing:**
- [Explicit exclusions to reduce scope creep concerns]

**Affected Systems:**
- [ ] Domain Controllers (list names)
- [ ] Sites (list sites)
- [ ] Users affected (count and scope)
- [ ] Applications depending on this component

---

### Risk Assessment

**Risk Level**: [Low / Medium / High]

**Risk Factors:**
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| [Risk 1] | [H/M/L] | [H/M/L] | [Mitigation] |
| [Risk 2] | [H/M/L] | [H/M/L] | [Mitigation] |

**Blast Radius if Change Fails:**
[Describe the worst-case scenario if this change goes wrong]

---

### Pre-Change Checklist
- [ ] Change window confirmed with stakeholders
- [ ] Backups verified (AD System State backup — date: ___)
- [ ] Replication healthy pre-change (`repadmin /replsummary`)
- [ ] Event logs clear of critical errors
- [ ] Rollback procedure documented and tested
- [ ] Communication sent to affected teams
- [ ] Monitoring alerts configured
- [ ] War room bridge established (if High/Critical risk)

---

### Implementation Steps

**Step-by-step procedure:**

| Step | Action | Command/Detail | Verification | Rollback if Failed |
|------|--------|---------------|-------------|-------------------|
| 1 | [Action] | `[command]` | [how to verify] | [rollback step] |
| 2 | [Action] | `[command]` | [how to verify] | [rollback step] |
| 3 | [Action] | `[command]` | [how to verify] | [rollback step] |

**Estimated Duration**: [X hours]
**Change Window**: [Start datetime] to [End datetime UTC]

---

### Verification Steps (Post-Change)
- [ ] [Verify step 1 — what success looks like]
- [ ] [Verify step 2]
- [ ] [Verify step 3]
- [ ] Replication healthy post-change: `repadmin /replsummary`
- [ ] Test logon from each affected site
- [ ] Application team sign-off

---

### Rollback Plan

**Rollback Trigger**: [Conditions that would trigger rollback]
**Rollback Window**: [Time available before rollback becomes high-risk]

**Rollback Steps:**
| Step | Action | Command/Detail | Estimated Time |
|------|--------|---------------|----------------|
| 1 | [Step] | `[command]` | [X min] |

**Total Rollback Time**: [X minutes]

---

### Key Insights
- [Insight 1: Something important about this change the CAB should know]
- [Insight 2: Lesson learned from similar changes]
- [Insight 3: Dependencies or sequencing requirements]

---

### Target Completion
**Scheduled Change Date**: [Date]
**Target Go-Live**: [Date]
**PIR Date (if applicable)**: [Date]

---

### Approvals Required
- [ ] AD Engineering Lead
- [ ] Security Team (if security impact)
- [ ] Application Owner(s)
- [ ] CAB Approval
- [ ] CTO/VP sign-off (if Critical risk)

---

CHANGE DETAILS TO CONVERT:
[Describe the change you want to make]
```

---

## PROMPT 3: AD Project Epic Generator

```
Generate a complete Jira Epic card for the following Active Directory project. Include child story breakdown.

OUTPUT FORMAT:

---

## 📋 Epic: [PROJECT TITLE]

**Type**: Epic
**Priority**: [High / Medium / Low]
**Target Quarter**: [Q1 2026 / etc.]
**Team**: [Identity & Access Management / AD Engineering]
**Labels**: `epic` `active-directory` `identity` `[project-type]`

---

### Executive Summary
[3-5 sentences: business context, what we're doing, why now, expected outcome in business terms]

---

### Business Objectives
- **Primary Goal**: [One line]
- **Success Metrics**:
  - [ ] [Measurable outcome 1 — e.g., "Reduce lockout incidents by 80%"]
  - [ ] [Measurable outcome 2]
  - [ ] [Measurable outcome 3]
- **OKR Alignment**: [Which company OKR does this support]

---

### Key Insights & Context
- [Insight 1: Current state problem/opportunity]
- [Insight 2: Technical constraint or dependency]
- [Insight 3: Risk if we don't do this]
- [Insight 4: Quick win or proof of concept available]

---

### Scope & Exclusions
**In Scope:**
- [Item 1]
- [Item 2]

**Out of Scope (explicitly):**
- [Exclusion 1]
- [Exclusion 2]

---

### Child Stories Breakdown

| Story | Title | Points | Priority | Dependencies |
|-------|-------|--------|----------|--------------|
| [Eng-XXX] | [Discovery & Current State Assessment] | [5] | High | None |
| [Eng-XXX] | [Design & Architecture] | [8] | High | Discovery |
| [Eng-XXX] | [Pilot/Proof of Concept] | [13] | High | Design |
| [Eng-XXX] | [Rollout Phase 1] | [8] | Medium | Pilot |
| [Eng-XXX] | [Rollout Phase 2] | [8] | Medium | Phase 1 |
| [Eng-XXX] | [Testing & Validation] | [5] | High | Each phase |
| [Eng-XXX] | [Documentation & Runbooks] | [3] | Medium | Rollout |
| [Eng-XXX] | [PIR & Retrospective] | [2] | Low | Complete |

---

### Milestones & Target Completion
| Milestone | Target Date | Success Criteria |
|-----------|------------|-----------------|
| Discovery Complete | [Date] | Current state documented, gaps identified |
| Design Approved | [Date] | Architecture reviewed and CAB approved |
| Pilot Complete | [Date] | [X] environments migrated, no regressions |
| Full Rollout | [Date] | All environments complete |
| Project Close | [Date] | PIR complete, documentation published |

---

### Risks & Blockers
| Risk/Blocker | Severity | Status | Mitigation |
|-------------|---------|--------|-----------|
| [Risk 1] | High | Open | [Plan] |
| [Risk 2] | Medium | Mitigated | [How] |
| [Blocker 1] | High | Blocked | [Who needs to unblock] |

---

### Team & Stakeholders
| Role | Name | Responsibility |
|------|------|---------------|
| Project Lead | [Name] | Overall delivery |
| AD Architect | [Name] | Technical design |
| Security | [Name] | Security review |
| App Owners | [Names] | Testing & sign-off |
| Sponsor | [Name] | Budget & escalation |

---

PROJECT DESCRIPTION TO CONVERT:
[Describe the project]
```

---

## PROMPT 4: AD Security Finding Card (From Audit/Pentest)

```
Generate a Jira security finding card for the following Active Directory security issue. Format for security team tracking with clear remediation guidance.

OUTPUT FORMAT:

---

## 🔴 Security Finding: [TITLE]

**Type**: Security Finding
**Severity**: [Critical / High / Medium / Low / Informational]
**CVSS Score**: [X.X] (if applicable)
**Finding Source**: [Internal Audit / Pentest / MDI Alert / Threat Hunt / Configuration Review]
**Labels**: `security` `active-directory` `[severity]` `[finding-type]`

---

### Finding Summary
[One paragraph: what the vulnerability is, how it could be exploited, and business impact]

---

### Technical Detail
**Vulnerability**: [Technical description]
**Attack Vector**: [How an attacker would exploit this]
**MITRE ATT&CK**: [Technique ID — e.g., T1558.003 Kerberoasting]
**Exploit Complexity**: [Low / Medium / High]

**Affected Objects:**
```
[List of affected users, computers, GPOs, or configurations]
```

**Proof of Concept** (if from pentest):
```
[Command or method that demonstrated the vulnerability — redacted if needed]
```

---

### Key Insights
- **Why this matters**: [Business risk in plain language]
- **Exploitability**: [How realistic is exploitation? By whom?]
- **Existing controls**: [What, if anything, limits the risk today]
- **Detection**: [Would we know if this was exploited? Current log coverage]

---

### Remediation Steps

**Immediate (0-48 hours):**
- [ ] [Quick win or containment step]

**Short-term (1-2 weeks):**
- [ ] [Primary remediation]

**Long-term (1-3 months):**
- [ ] [Systemic fix or architectural improvement]

**Verification:**
```powershell
# Command to verify remediation is complete
[PowerShell command to confirm fixed]
```

---

### Next Steps
| # | Action | Owner | Target Completion | Blockers |
|---|--------|-------|-------------------|----------|
| 1 | [Immediate containment] | Security Ops | [Date] | None |
| 2 | [Notify app owners] | [Name] | [Date] | None |
| 3 | [Remediation] | AD Engineering | [Date] | [Any blockers] |
| 4 | [Verify & close] | Security | [Date] | Remediation |

---

### Target Completion
**Expected Remediation**: [Date]
**Retest Date**: [Date after remediation]
**Escalation if Not Fixed By**: [Date]

---

SECURITY FINDING DATA:
[Describe the security finding]
```

---

## PROMPT 5: Quick AD Task Card Generator

```
Generate a concise Jira task card for the following Active Directory operational task. Keep it precise and actionable.

OUTPUT FORMAT:

---

## ✅ Task: [TITLE]

**Type**: Task
**Priority**: [High / Medium / Low]
**Component**: [AD component]
**Estimate**: [Story Points or Hours]
**Sprint**: [Current / Next]

### Description
[What needs to be done and why in 2-3 sentences]

### Key Insights
- [Most important thing to know before starting]
- [Risk or gotcha to be aware of]
- [Dependency on another team or system]

### Acceptance Criteria
- [ ] [Specific, testable criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
- [ ] Documentation updated
- [ ] Change ticket created/closed

### Next Steps
| # | Action | Owner | Target |
|---|--------|-------|--------|
| 1 | [Step] | [Who] | [When] |
| 2 | [Step] | [Who] | [When] |

### Target Completion: [Date]

---

TASK TO CONVERT:
[Describe the task]
```
