# TASK JIRA TEMPLATE
> For operational AD tasks. Fast, focused, actionable.

---

**Summary**: [Action verb] + [Object] + [Scope/Context]
*Example: "Rotate KRBTGT password in corp.contoso.com — Phase 1 of 2"*
*Example: "Investigate account lockout storm — sarah.jones@corp.com"*
*Example: "Decommission DC03 from Chicago site"*

**Issue Type**: Task
**Priority**: [High / Medium / Low]
**Labels**: `active-directory` `[component]` `[operational/security/maintenance]`
**Component**: [AD component]
**Estimate**: [Story Points or Hours]
**Sprint**: [Current Sprint / Next Sprint / Backlog]

---

## Description

### What & Why
[2-3 sentences: what needs to be done, why it's needed, and what "done" looks like]

---

### Key Insights
- **[INSIGHT 1]**: [Most important thing to know before starting this task]
- **[INSIGHT 2]**: [Risk or gotcha specific to this task]
- **[INSIGHT 3]**: [Dependency — what must be true before starting]

---

### Prerequisites
- [ ] [Access required — e.g., "Domain Admin rights on DC03"]
- [ ] [Tool required — e.g., "AD module installed, access to PDC Emulator"]
- [ ] [Pre-condition — e.g., "Replication must be healthy before starting"]
- [ ] [Knowledge required — e.g., "Review KRBTGT rotation runbook in 13_RUNBOOKS/"]

---

### Acceptance Criteria
- [ ] [Specific, testable criterion 1 — how we know it's done]
- [ ] [Criterion 2]
- [ ] [Criterion 3]
- [ ] Change ticket created and linked (if applicable)
- [ ] Runbook updated (if procedure changed)
- [ ] Documentation updated

---

### Implementation Notes
[Any specific commands, flags, or approach details relevant to THIS specific task instance]

```powershell
# Relevant commands for this task
[Commands]
```

---

### Verification
```powershell
# Read-only commands to verify task completed successfully
[Verification commands]
```
**Expected output**: [What success looks like]

---

### Next Steps
| # | Action | Owner | Target |
|---|--------|-------|--------|
| 1 | [Immediate next action] | [Who] | [When] |
| 2 | [Follow-up] | [Who] | [When] |

---

### Target Completion: [Date]
### Linked To: [Epic / Incident / Change Request — Jira key]
