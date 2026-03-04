# EPIC JIRA TEMPLATE
> For multi-week AD projects. Attach child Stories/Tasks to this Epic.

---

**Summary**: EPIC-[AUTO] | [Project Title — clear and specific]
*Example: "Active Directory Tier Model Implementation — Privileged Access Separation"*

**Issue Type**: Epic
**Priority**: [High / Medium / Low]
**Labels**: `active-directory` `epic` `identity` `[project-type]`
**Target Quarter**: [Q1 2026 / Q2 2026 / etc.]
**Team**: [Identity Engineering / AD Engineering / IAM Team]

---

## Description

### Executive Summary
[3-5 sentences: business context, what we're doing, why now, expected business outcome. Readable by a VP in 30 seconds.]

### Business Objectives
- **Primary Goal**: [One sentence — the "why we're doing this"]
- **Success Metrics**:
  - [ ] [Measurable outcome 1 — quantified, e.g., "Reduce privileged account exposure by 90%"]
  - [ ] [Measurable outcome 2]
  - [ ] [Measurable outcome 3]
- **OKR Alignment**: [Which company/team OKR this supports]
- **If We Don't Do This**: [Risk of inaction — important for prioritization]

---

### Key Insights
- **[INSIGHT 1]**: [Current state problem that makes this necessary]
- **[INSIGHT 2]**: [Technical constraint or key dependency to know upfront]
- **[INSIGHT 3]**: [Risk if we don't do this / cost of inaction]
- **[INSIGHT 4]**: [Quick win or proof of concept available — build momentum]
- **[INSIGHT 5]**: [Lesson learned from similar projects elsewhere]

---

### Scope
**In Scope:**
- [Item 1]
- [Item 2]

**Out of Scope (explicitly — prevents scope creep):**
- [Exclusion 1]
- [Exclusion 2]

---

### Child Stories / Task Breakdown

| Story Key | Title | Points | Priority | Sprint | Depends On |
|-----------|-------|--------|----------|--------|-----------|
| [ENG-XXX] | Discovery: Document current state & gaps | 5 | High | Sprint 1 | — |
| [ENG-XXX] | Design: Architecture and implementation plan | 8 | High | Sprint 1-2 | Discovery |
| [ENG-XXX] | Security review of design | 3 | High | Sprint 2 | Design |
| [ENG-XXX] | Lab/Pilot: Proof of concept | 13 | High | Sprint 3 | Design approved |
| [ENG-XXX] | Rollout Phase 1: [scope] | 8 | High | Sprint 4 | Pilot |
| [ENG-XXX] | Rollout Phase 2: [scope] | 8 | Medium | Sprint 5 | Phase 1 |
| [ENG-XXX] | Rollout Phase 3: [scope] | 8 | Medium | Sprint 6 | Phase 2 |
| [ENG-XXX] | Testing & Validation | 5 | High | Each phase | Each phase |
| [ENG-XXX] | Runbook creation & documentation | 3 | Medium | Sprint 6 | Rollout |
| [ENG-XXX] | Training for operations team | 2 | Medium | Sprint 7 | Runbooks |
| [ENG-XXX] | PIR & project retrospective | 2 | Low | Sprint 8 | Complete |

---

### Milestones & Target Completion

| Milestone | Target Date | Success Criteria | Owner |
|-----------|------------|-----------------|-------|
| Kickoff & Discovery | [Date] | Current state documented, all gaps identified | [Name] |
| Design Approved | [Date] | Architecture sign-off from Engineering + Security | [Name] |
| Pilot Complete | [Date] | [X] systems migrated, no regressions, users unaffected | [Name] |
| Phase 1 Rollout | [Date] | [Scope] complete, verified | [Name] |
| Full Rollout | [Date] | All environments complete, 100% coverage | [Name] |
| Project Close | [Date] | PIR complete, runbooks published, team trained | [Name] |

---

### Risks & Blockers

| Item | Type | Severity | Status | Mitigation / Resolution |
|------|------|---------|--------|------------------------|
| [Risk 1] | Risk | High | Open | [Mitigation plan] |
| [Risk 2] | Risk | Medium | Mitigated | [How mitigated] |
| [Blocker 1] | Blocker | High | Blocked | [Who/what needs to unblock] |
| [Dependency 1] | Dependency | Medium | Tracking | [Other team/project we depend on] |

---

### Next Steps (Immediate)
| # | Action | Owner | Target Completion |
|---|--------|-------|-----------------|
| 1 | Create child stories and link to this Epic | [Name] | [Date] |
| 2 | Schedule kickoff meeting | [Name] | [Date] |
| 3 | [First concrete action] | [Name] | [Date] |

---

### Team & Stakeholders

| Role | Name | Responsibility |
|------|------|---------------|
| Project Lead / Delivery | [Name] | Overall delivery, milestone tracking |
| AD Architect | [Name] | Technical design, architecture decisions |
| Security Review | [Name] | Security sign-off |
| Change Management | [Name] | CAB submissions, change coordination |
| Application Owners | [Names] | Testing, sign-off on app impact |
| Executive Sponsor | [Name] | Budget, escalation, strategic alignment |

---

### Target Completion
**Epic Target Date**: [Date]
**Key Dependencies**: [Other Epics or projects this depends on or blocks]
**Budget**: [If applicable]
