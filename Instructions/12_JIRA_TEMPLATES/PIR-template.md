# POST-INCIDENT REVIEW (PIR) JIRA TEMPLATE
> Complete within 5 business days of incident resolution. Blameless culture — focus on systems, not people.

---

**Summary**: PIR | [Original Incident Key] | [One-line incident description]
*Example: "PIR | INC-4421 | P1 Authentication failure APAC — 3h 22min outage"*

**Issue Type**: Post-Incident Review
**Priority**: [High (P0/P1 incidents) / Medium (P2)]
**Labels**: `active-directory` `pir` `incident` `[p0/p1/p2]`
**Linked Issues**: [Original incident Jira key(s)]
**PIR Owner**: [Name]
**PIR Date**: [Date of review meeting]

---

## Incident Summary

| Field | Value |
|-------|-------|
| **Incident Key** | [INC-XXXX] |
| **Severity** | [P0 / P1 / P2] |
| **Start Time** | [UTC] |
| **Detection Time** | [UTC — when we first knew] |
| **Resolution Time** | [UTC] |
| **TTD (Time to Detect)** | [Duration] |
| **TTR (Time to Resolve)** | [Duration] |
| **MTTR** | [Duration] |
| **Users Affected** | [Count] |
| **Services Affected** | [List] |
| **SLA Breached** | [Yes/No] |

---

## Root Cause Analysis

### Root Cause (Precise)
[One sentence: the specific technical condition that caused the incident. Not a symptom.]

### Five Whys Analysis
| Why # | Question | Answer |
|-------|---------|--------|
| Why 1 | Why did the incident occur? | [Answer] |
| Why 2 | Why did [Why 1 answer] happen? | [Answer] |
| Why 3 | Why did [Why 2 answer] happen? | [Answer] |
| Why 4 | Why did [Why 3 answer] happen? | [Answer] |
| Why 5 | Why did [Why 4 answer] happen? | [Systemic root cause] |

**Systemic Root Cause**: [The underlying process/tooling/knowledge gap that allowed this to happen]

### Contributing Factors
- [Factor 1 — additional conditions that made the incident worse or longer]
- [Factor 2]
- [Factor 3]

---

## Detailed Timeline

| Time (UTC) | Event | Actor | Notes |
|-----------|-------|-------|-------|
| [HH:MM] | [First impact] | [System/User] | |
| [HH:MM] | [Alert fired / detected] | [System/Person] | |
| [HH:MM] | [Incident declared] | [Person] | |
| [HH:MM] | [Key diagnostic finding] | [Person] | |
| [HH:MM] | [Hypothesis confirmed] | [Person] | |
| [HH:MM] | [Fix applied] | [Person] | |
| [HH:MM] | [Verification completed] | [Person] | |
| [HH:MM] | **Incident resolved** | [Person] | MTTR: [duration] |

---

## Key Insights

- **[INSIGHT 1]**: [What we learned about our systems]
- **[INSIGHT 2]**: [What we learned about our process]
- **[INSIGHT 3]**: [What detection/monitoring gap was exposed]
- **[INSIGHT 4]**: [What would have prevented this entirely]
- **[INSIGHT 5]**: [What made this incident worse than it needed to be]

---

## What Went Well
- [Things that worked — response speed, tooling, communication, runbooks]
- [Detection that worked as designed]
- [Team coordination that was effective]

## What Needs Improvement
- [Detection gaps — we should have known sooner]
- [Runbook gaps — we didn't have a documented procedure]
- [Communication gaps — stakeholders weren't updated fast enough]
- [Tooling gaps — we lacked access or data we needed]
- [Knowledge gaps — expertise that slowed diagnosis]

---

## Action Items

| # | Action | Owner | Target Completion | Jira Ticket |
|---|--------|-------|-----------------|-------------|
| 1 | [Immediate fix to prevent recurrence] | [Name] | [Date] | [ENG-XXX] |
| 2 | [Detection/alerting improvement] | [Name] | [Date] | [ENG-XXX] |
| 3 | [Runbook create/update] | [Name] | [Date] | [ENG-XXX] |
| 4 | [Process improvement] | [Name] | [Date] | [ENG-XXX] |
| 5 | [Tooling improvement] | [Name] | [Date] | [ENG-XXX] |
| 6 | [Training or documentation] | [Name] | [Date] | [ENG-XXX] |

---

## Next Steps (PIR Process)
| # | Action | Owner | Target |
|---|--------|-------|--------|
| 1 | PIR meeting held with all responders | [Name] | [Date] |
| 2 | All action items created as Jira tickets | [Name] | [Date] |
| 3 | PIR document shared with management | [Name] | [Date] |
| 4 | Action items tracked to completion | [Team Lead] | [Rolling] |

---

## Target Completion: [Date of PIR — within 5 business days of resolution]

---

*Blameless PIR: This review focuses on improving systems and processes, not assigning blame to individuals. All findings are shared openly to improve collective knowledge.*
