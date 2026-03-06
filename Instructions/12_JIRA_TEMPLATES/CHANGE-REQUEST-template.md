# CHANGE REQUEST JIRA TEMPLATE
> For CAB submission. Fill in all `[BRACKETED]` fields. Every write command needs a rollback.

---

**Summary**: CR-[AUTO] | [Standard/Normal/Emergency] | [What is changing — one line]
*Example: "Normal | Raise Domain Functional Level from 2016 to 2019 in corp.contoso.com"*

**Issue Type**: Change Request
**Priority**: [High / Medium / Low]
**Labels**: `active-directory` `change-request` `[risk-low/medium/high/critical]`
**Component**: [AD component being changed]
**Risk Level**: 🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low

---

## Description

### Change Summary
[2-3 sentences: what is changing, why now, and the expected outcome]

### Business Justification
[Why is this necessary? What happens if we don't do it?]

---

### Technical Scope
**What IS changing:**
- [Specific item 1]
- [Specific item 2]

**What is NOT changing (explicitly out of scope):**
- [Exclusion 1 — prevents scope creep]

**Affected Systems:**
- DCs: [List names or "All DCs in [domain]"]
- Sites: [List]
- Users impacted: [Count + how]
- Applications depending on this: [List]
- Hybrid/Entra ID impact: [Yes/No + detail]

---

### Risk Assessment
| Risk | Likelihood | Impact | Mitigation | Residual |
|------|-----------|--------|-----------|---------|
| [Risk 1] | H/M/L | H/M/L | [Plan] | H/M/L |
| [Risk 2] | H/M/L | H/M/L | [Plan] | H/M/L |
| Replication disruption | [H/M/L] | [H/M/L] | [Verify repl healthy pre-change] | [L] |

**Worst Case Scenario**: [What happens if this goes completely wrong]
**Blast Radius**: [Who/what is affected if it fails]

---

### Key Insights
- **[INSIGHT 1]**: [Something the CAB should know about this change]
- **[INSIGHT 2]**: [Lesson learned from similar previous changes]
- **[INSIGHT 3]**: [Critical dependency or sequencing requirement]
- **[INSIGHT 4]**: [Risk that was explicitly evaluated and accepted]

---

### Pre-Change Checklist
- [ ] AD System State backup verified — Date of last backup: `[DATE]`
- [ ] `repadmin /replsummary` — 0 failures confirmed
- [ ] All DCs online and services healthy
- [ ] Event logs clean (no critical errors in last 24h)
- [ ] Change window confirmed with stakeholders
- [ ] Communication sent to affected teams
- [ ] Rollback procedure documented and tested in lab
- [ ] Monitoring alerts configured for duration
- [ ] War room bridge established: [Meeting ID]
- [ ] Rollback engineer standing by: [Name]

---

### Implementation Steps

**Change Window**: [Start UTC] → [End UTC]
**Estimated Duration**: [X hours]
**Rollback Window Closes**: [UTC — after this point, rollback may be more complex]

| Step | Action | Command / Detail | Risk | Expected Result | Rollback if Failed |
|------|--------|-----------------|------|----------------|-------------------|
| 1 | [Pre-check] | `[command]` | READ-ONLY | [Expected output] | N/A |
| 2 | [First change] | `[command]` | [LOW/MED/HIGH] | [Expected output] | `[undo command]` |
| 3 | [Verify step 2] | `[command]` | READ-ONLY | [Success criteria] | Rollback step 2 |
| 4 | [Next change] | `[command]` | [LOW/MED/HIGH] | [Expected output] | `[undo command]` |
| 5 | [Verify step 4] | `[command]` | READ-ONLY | [Success criteria] | Rollback step 4 |

---

### Verification Steps (Post-Change)
- [ ] [Test 1 — exactly what success looks like]
- [ ] [Test 2]
- [ ] `repadmin /replsummary` — 0 failures post-change
- [ ] Test authentication from each affected site
- [ ] Application team confirms no regression
- [ ] Monitoring shows no new alerts

---

### Rollback Plan
**Rollback Trigger**: [Specific conditions that trigger rollback — be precise]
**Rollback Decision Owner**: [Name/Role]

| Step | Rollback Action | Command | Est. Time |
|------|----------------|---------|----------|
| 1 | [Step] | `[command]` | [X min] |
| 2 | [Step] | `[command]` | [X min] |

**Total Rollback Time**: [X minutes]

---

### Next Steps (Pre-Change)
| # | Action | Owner | Target Completion |
|---|--------|-------|-----------------|
| 1 | Lab test of procedure | [Name] | [Date] |
| 2 | CAB submission | [Name] | [Date] |
| 3 | Stakeholder notification | [Name] | [Date] |
| 4 | Execute change | [Name] | [Change window date] |

---

### Target Completion
**Change Window Date**: [Date]
**CAB Submission Deadline**: [Date — typically 5-10 business days before window]
**PIR Date (if High/Critical)**: [Date]

---

### Approvals Required
- [ ] AD Engineering Lead
- [ ] Security Team (if security impact)
- [ ] Application Owner(s): [Names]
- [ ] Change Advisory Board (CAB)
- [ ] [VP/CTO if Critical risk]
