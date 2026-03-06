# Jira Story Template — Active Directory / Identity Work
> **Card type**: Story | **Story Points**: Fibonacci (1 / 2 / 4 / 8) | **Never use 8 without breakdown plan

---

## Story Card

**Summary**: [Imperative verb + outcome — e.g., "Rotate KRBTGT password in contoso.com domain"]

| Field | Value |
|-------|-------|
| **Card Type** | Story |
| **Project** | [PROJECT-KEY] |
| **Epic Link** | [EPIC-KEY] if applicable |
| **Component** | Active Directory / Entra ID / Hybrid / Security / PKI / DNS |
| **Priority** | High / Medium / Low |
| **Story Points** | **[1 / 2 / 4 / 8]** — see sizing guide below |
| **Sprint** | [Sprint name or backlog] |
| **Assignee** | [Name] |
| **Reporter** | [Name] |
| **Labels** | `active-directory`, `runbook`, `change-request`, `tech-debt`, `identity-security` |
| **Target Start** | [Date] |
| **Target Completion** | [Date] |

---

## Story Point Sizing

| Points | When to use | Approximate effort | Break down? |
|--------|-------------|-------------------|-------------|
| **1** | Trivial, fully documented, zero unknowns (e.g., add user to group, reset password) | < 1 hour | No |
| **2** | Small, well-understood task, 1–2 steps with verification (e.g., restart a service, update a GPO setting) | 1–3 hours | No |
| **4** | Moderate complexity, multiple steps, coordination or testing needed (e.g., DC health check, SPN fix) | Half day | Consider if blockers emerge |
| **8** | Complex, cross-team, or novel in this environment | 1–2 days | **Yes — see breakdown section** |

> **8-point rule**: If you score a story at 8 points, you MUST add a breakdown in the "Child Stories" section below before it can be accepted into a sprint.

---

## Description

**As a** [AD Engineer / Security Analyst / Help Desk / Identity Architect],
**I want to** [specific technical action],
**So that** [business or security outcome].

### Context
[Why is this story needed now? Link to incident, audit finding, project, or tech debt]

### Key Insights
- [Important technical detail, gotcha, or dependency]
- [Risk or constraint]
- [Relevant runbook reference: `13_RUNBOOKS/XX-name.md`]

---

## Acceptance Criteria

> Criteria must be **testable and objective**. If you can't verify it with a command or observable state change, rewrite it.

- [ ] **[Criterion 1]**: [Specific, verifiable condition — e.g., "`repadmin /replsummary` shows 0 errors on all DCs"]
- [ ] **[Criterion 2]**: [e.g., "KRBTGT password last set timestamp updated on all DCs"]
- [ ] **[Criterion 3]**: [e.g., "No new P1/P2 alerts in Sentinel within 30 minutes of completion"]
- [ ] **[Criterion 4]**: [e.g., "Change record closed with all evidence attached"]

---

## Implementation Notes

> Delete this section if story is < 4 points. Required for all 4+ point stories.

**Pre-conditions** (must be true before starting):
- [ ] [Pre-condition 1]
- [ ] [Pre-condition 2]

**Implementation approach**:
[Brief description of the technical approach — not step-by-step (that belongs in the runbook), but enough to review the approach]

**Reference runbook**: `Instructions/13_RUNBOOKS/[XX-name.md]`

**Estimated commands** (high level):
```powershell
# Key commands (not full runbook — just headline operations)
```

---

## Child Stories (Required for 8-Point Cards)

> If this story is scored at 8 points, decompose it here before sprint acceptance.

| Child Story | Points | Depends On | Owner |
|-------------|--------|-----------|-------|
| [Discovery / pre-checks] | 1–2 | — | |
| [Core implementation] | 2–4 | Discovery | |
| [Validation / testing] | 1–2 | Core | |
| [Documentation / closure] | 1 | Validation | |

**Total decomposed points**: [Sum — should be ≤ original 8-point estimate]

---

## Blockers

| Blocker | Impact | Owner | ETA |
|---------|--------|-------|-----|
| [Blocker description] | [What it blocks] | [Name] | [Date] |

---

## Next Steps

| # | Action | Owner | Due |
|---|--------|-------|-----|
| 1 | | | |
| 2 | | | |

---

## Evidence & Attachments

> Attach these before closing the story:
- [ ] Screenshot or output showing acceptance criteria met
- [ ] Change record number (if applicable)
- [ ] Runbook execution log or command output
- [ ] Sign-off from technical reviewer
