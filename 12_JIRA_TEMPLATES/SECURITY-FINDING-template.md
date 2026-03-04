# SECURITY FINDING JIRA TEMPLATE
> For vulnerabilities, misconfigurations, and security gaps discovered in AD. From audits, pentests, MDI alerts, or threat hunts.

---

**Summary**: SEC-[AUTO] | [Critical/High/Medium/Low] | [Finding title — one line]
*Example: "HIGH | Kerberoastable service accounts with weak passwords — 23 accounts"*

**Issue Type**: Security Finding / Bug
**Priority**: [Critical / High / Medium / Low]
**Labels**: `active-directory` `security` `identity-security` `[severity]` `[finding-type]`
**Component**: [AD Security / Entra ID / PKI / Privileged Access / Authentication]
**Source**: [Internal Audit / Pentest / MDI Alert / Threat Hunt / Config Review / Vulnerability Scan]

---

## Description

### Executive Summary
[2-3 sentences: what the vulnerability is, how it could be exploited, and business impact. Written for a CISO — no deep technical jargon.]

### Technical Detail
**Vulnerability**: [Precise technical description]
**Attack Vector**: [How an attacker exploits this]
**MITRE ATT&CK**: [Tactic: TA00XX] | [Technique: TXXXX.XXX — Name]
**Exploit Complexity**: [Low / Medium / High]
**Authentication Required**: [None / Domain User / Admin]
**Privileges Gained**: [What attacker gets]

**Affected Objects**:
```
[List: users, computers, groups, GPOs, or describe the scope]
Total affected: [N]
```

---

### Key Insights
- **Why this is serious**: [Business risk in one sentence]
- **Exploitability in your environment**: [Realistic attacker scenario — internal threat, external after breach, etc.]
- **Existing controls**: [What, if anything, currently limits this risk]
- **Detection gap**: [Would you know if this was exploited? Current log coverage?]
- **Urgency**: [Why this can't wait — or why it can]

---

### Evidence / Proof of Concept
```powershell
# Command that identified the issue (READ-ONLY — for reproduction)
[Command used to find the vulnerability]
```
**Output**: [What the output showed]

---

### Remediation Steps

**Immediate (0-48 hours):**
- [ ] [Containment or quick mitigation — reduces risk NOW without a change window]

**Short-term (1-2 weeks):**
- [ ] [Primary remediation — closes the gap]

**Long-term (1-3 months):**
- [ ] [Systemic improvement — prevents recurrence class-wide]

**Verification** (after remediation — READ-ONLY):
```powershell
# Confirm finding is remediated
[PowerShell command to verify]
```
**Expected output after fix**: [What clean output looks like]

---

### Detection Query

```kql
// Microsoft Sentinel / MDE Advanced Hunting KQL
// Detects exploitation of this vulnerability
[KQL query]
```

```spl
// Splunk SPL equivalent
[SPL query]
```

---

### Next Steps
| # | Action | Owner | Target Completion | Blockers |
|---|--------|-------|-----------------|---------|
| 1 | [Notify affected team(s)] | Security Ops | [Date] | None |
| 2 | [Immediate containment] | AD Engineering | [Date] | None |
| 3 | [Primary remediation] | [Team] | [Date] | [Any blockers] |
| 4 | [Verify & close] | Security | [Date] | Remediation |

---

### Target Completion
**Immediate Actions By**: [Date — 48h from discovery]
**Full Remediation By**: [Date]
**Retest Date**: [Date after remediation]
**Escalation If Not Fixed By**: [Date — SLA trigger]

---

### Risk Acceptance (if remediation delayed)
If remediation cannot meet target date, document risk acceptance:
- **Accepted By**: [Name/Role]
- **Acceptance Date**: [Date]
- **Compensating Controls**: [What reduces risk while we wait]
- **Review Date**: [When risk acceptance expires]
