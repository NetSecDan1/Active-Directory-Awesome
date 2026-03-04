# INCIDENT JIRA TEMPLATE
> Copy into Jira as a Story or Bug. Fill in all `[BRACKETED]` fields.

---

**Summary**: INC-[AUTO] | [P0/P1/P2] | [Short description of impact, not symptom]
*Example: "P1 | Authentication failures blocking 400 APAC users from corporate resources"*

**Issue Type**: Incident
**Priority**: [Critical / High / Medium / Low]
**Labels**: `active-directory` `[p0/p1/p2/p3]` `incident` `[on-prem/hybrid/entra]`
**Component**: [AD Replication / Authentication / DNS / GPO / Hybrid Identity / PKI / Security / FSMO]
**Affects Version**: [Domain Functional Level — e.g., WS2019]

---

## Description

### Business Impact
- **Users Affected**: [Number and description — e.g., "~400 users in APAC site"]
- **Services Down**: [List key services — e.g., "Outlook, VPN, SharePoint, file shares"]
- **SLA Breach**: [Yes / No — which SLA]
- **Started**: [UTC datetime]
- **Detected**: [UTC datetime — when we found out vs when it started]

---

### Key Insights
- **[INSIGHT 1]**: [Most important finding so far]
- **[INSIGHT 2]**: [What we've ruled out]
- **[INSIGHT 3]**: [Current state / what's being done]
- **[INSIGHT 4]**: [Pattern or anomaly observed]

---

### Current Hypothesis
| Rank | Hypothesis | Confidence | Evidence |
|------|-----------|-----------|---------|
| 1 | [Most likely cause] | [XX%] | [Supporting data] |
| 2 | [Second hypothesis] | [XX%] | [Supporting data] |

**Ruled Out**: [List exonerated hypotheses and why]

---

### Timeline
| Time (UTC) | Event |
|-----------|-------|
| [HH:MM] | First reports received |
| [HH:MM] | Incident declared |
| [HH:MM] | [Key diagnostic finding] |
| [HH:MM] | [Update] |
| [HH:MM] | **[ONGOING]** |

---

### Diagnostic Data Collected
- [ ] `repadmin /replsummary` — [result/status]
- [ ] Event logs from PDC Emulator — [result/status]
- [ ] `dcdiag` — [result/status]
- [ ] Network/firewall check — [result/status]
- [ ] DNS SRV records — [result/status]
- [ ] Splunk/SIEM query — [result/status]

---

### Next Steps
| # | Action | Owner | Target Completion | Status |
|---|--------|-------|------------------|--------|
| 1 | [Immediate action] | [Name] | [HH:MM UTC] | 🔄 In Progress |
| 2 | [Second action] | [Name] | [HH:MM UTC] | ⏳ Pending |
| 3 | [Third action] | [Name] | [HH:MM UTC] | ⏳ Pending |

---

### Blockers
- [ ] [Blocker 1 — what is blocking resolution and who needs to unblock]
- [ ] [Blocker 2]

---

### Communications
- **Bridge Call**: [Yes/No — Meeting ID/Link]
- **Incident Commander**: [Name]
- **AD SME**: [Name]
- **Stakeholder Update Sent**: [Yes/No — Time]
- **Status Page Updated**: [Yes/No]
- **Executive Notified**: [Yes/No — Name/Time]

---

### Resolution *(complete after fix)*
**Root Cause**: [Specific technical root cause — be precise]
**Resolution**: [Exact steps taken]
**Resolved At**: [UTC datetime]
**MTTR**: [Detection to Resolution time]

---

### Post-Incident
**PIR Required**: [Yes/No]
**PIR Scheduled**: [Date]
**PIR Ticket**: [Link]
