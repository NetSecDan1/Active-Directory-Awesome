# 03 — Structured Output Prompts for AD Engineering

> **What this is**: Prompts that force AI to produce clean, structured, parseable output — perfect for documentation, tickets, runbooks, and data pipelines. Stop getting walls of text. Start getting usable outputs.

---

## Why Structured Output Matters

Unstructured AI output on AD topics is hard to:
- Copy into tickets or runbooks
- Parse programmatically
- Review quickly under pressure
- Hand off to another engineer

These prompts solve that by enforcing specific output schemas.

---

## PROMPT 1: Diagnostic Output as Structured JSON

```
Analyze the following Active Directory problem and output your response ONLY as valid JSON conforming to this schema. No prose outside the JSON block.

SCHEMA:
{
  "problem_classification": {
    "type": "string (Authentication|Replication|DNS|GPO|Lockout|Security|Hybrid|PKI|Performance|Schema|Other)",
    "scope": "string (Workstation|Site|Domain|Forest|Hybrid)",
    "severity": "string (P0-Critical|P1-High|P2-Medium|P3-Low)",
    "confidence": "integer (1-10)"
  },
  "hypotheses": [
    {
      "rank": "integer",
      "description": "string",
      "confidence_pct": "integer (0-100)",
      "evidence_for": ["string"],
      "evidence_against": ["string"]
    }
  ],
  "information_gaps": ["string (what I'd need to know to be more certain)"],
  "diagnostic_commands": [
    {
      "description": "string",
      "command": "string (exact command to run)",
      "run_on": "string (Client|DC|PDC Emulator|Any DC|SIEM)",
      "risk": "string (READ-ONLY|LOW|MEDIUM|HIGH)",
      "expected_output_if_healthy": "string",
      "expected_output_if_problem": "string"
    }
  ],
  "remediation": {
    "primary_action": "string",
    "steps": [
      {
        "step": "integer",
        "action": "string",
        "command": "string (optional)",
        "risk_level": "string (READ-ONLY|LOW|MEDIUM|HIGH|CRITICAL)",
        "rollback": "string"
      }
    ],
    "verification": ["string"],
    "prevention": ["string"]
  }
}

PROBLEM DATA:
[Paste your AD problem here]
```

---

## PROMPT 2: DC Health as Structured Report Table

```
Parse the following diagnostic output from an Active Directory domain controller and produce a structured health assessment table.

OUTPUT FORMAT (Markdown table, then summary):

### DC Health Assessment: [DC Name]

| Check | Status | Detail | Action Required |
|-------|--------|--------|-----------------|
| NTDS Service | ✅ Running / ❌ Stopped / ⚠️ Unknown | [detail] | [None/action] |
| NETLOGON Service | | | |
| KDC Service | | | |
| DNS Service | | | |
| DFSR Service | | | |
| Replication (Inbound) | | | |
| Replication (Outbound) | | | |
| SYSVOL Share | | | |
| NETLOGON Share | | | |
| DNS SRV Records | | | |
| Time Sync | | | |
| Disk Space (NTDS Volume) | | | |
| Memory Pressure | | | |
| AD Database Size | | | |

### Summary
- **Overall Status**: 🟢 Healthy / 🟡 Warning / 🔴 Critical
- **Critical Issues**: [count] — [list]
- **Warnings**: [count] — [list]
- **Recommended Immediate Actions**: [ordered list]

### Top 3 Actions (Prioritized)
1. [Highest priority action]
2. [Second priority action]
3. [Third priority action]

DIAGNOSTIC DATA:
[Paste dcdiag output, event logs, service status, etc.]
```

---

## PROMPT 3: Replication Status as Matrix

```
Convert the following replication data into a structured replication health matrix.

OUTPUT FORMAT:

### Replication Health Matrix — [Domain] — [Timestamp]

**Legend**: ✅ Success (<15min lag) | ⚠️ Warning (15-60min lag) | ❌ Failure (>60min or error) | ➖ No direct link

| Source → Dest | Site | Last Success | Lag | Failures | Status | Error Code |
|---------------|------|-------------|-----|----------|--------|------------|
| DC01 → DC02 | Site1→Site1 | [time] | [Xm] | 0 | ✅ | - |
| DC01 → DC03 | Site1→Site2 | [time] | [Xh] | 3 | ❌ | 1722 |
[...continue for all pairs with failures or warnings...]

### Replication Summary
- **Total Links Checked**: [N]
- **Healthy Links**: [N] (✅)
- **Warning Links**: [N] (⚠️)
- **Failed Links**: [N] (❌)
- **Most Affected DC**: [DC name] ([N] failures)
- **Oldest Replication**: [DC name] — [duration]

### Error Analysis
| Error Code | Meaning | Affected Links | Fix |
|-----------|---------|---------------|-----|
| 1722 | RPC Server Unavailable | DC01→DC03 | Check firewall/RPC service |
| 8524 | DSA unavailable | ... | Check DC status/DNS |

### Recommended Actions (Ordered)
1. [First fix — addresses most failures]
2. [Second fix]

REPLICATION DATA (paste repadmin output):
[Paste here]
```

---

## PROMPT 4: Security Finding as MITRE ATT&CK Card

```
Analyze this Active Directory security finding and produce a structured MITRE ATT&CK-aligned security card.

OUTPUT FORMAT:

## Security Finding Card

| Field | Value |
|-------|-------|
| **Finding ID** | [Generate: SEC-YYYYMMDD-NNN] |
| **Title** | [Short descriptive title] |
| **Severity** | 🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low |
| **MITRE Tactic** | [TA00XX - Tactic Name] |
| **MITRE Technique** | [TXXXX.XXX - Technique Name] |
| **Discovery Method** | [How was this found] |
| **Asset Type** | [User Account / Computer / Group / GPO / Trust / Service] |
| **Affected Count** | [How many objects affected] |

### What Is Happening
[1-2 sentences: technical description without jargon]

### Business Risk
[1-2 sentences: what a CISO cares about — data loss, access, compliance]

### Attack Path
```
Attacker → [Step 1] → [Step 2] → [Goal Achieved]
```

### Detection Query (KQL/SPL)
```kql
// Sentinel/MDE KQL to detect this
[KQL query]
```

### Remediation (Prioritized)
| Priority | Action | Effort | Risk |
|----------|--------|--------|------|
| 1 | [Quick win] | Low | Low |
| 2 | [Primary fix] | Medium | Medium |
| 3 | [Long-term] | High | Low |

### Verification
```powershell
# Confirm remediation is complete (read-only)
[PowerShell to verify]
```

FINDING DATA:
[Describe the security issue]
```

---

## PROMPT 5: Change Impact Analysis Card

```
Analyze the following proposed Active Directory change and produce a structured impact analysis card for Change Advisory Board (CAB) review.

OUTPUT FORMAT:

## Change Impact Analysis

### Change Overview
| Field | Value |
|-------|-------|
| **Change Title** | |
| **Change Type** | Standard / Normal / Emergency |
| **Risk Classification** | 🔴 Critical / 🟠 High / 🟡 Medium / 🟢 Low |
| **Proposed Window** | |
| **Rollback Window** | |
| **Estimated Duration** | |

### Blast Radius Analysis
| Impact Area | Affected | Count/Scope | Recovery Time if Failed |
|------------|---------|-------------|------------------------|
| Users | Yes/No | [count] | [time] |
| Computers | Yes/No | [count] | [time] |
| Applications | Yes/No | [list] | [time] |
| Sites | Yes/No | [list] | [time] |
| Other DCs | Yes/No | [how] | [time] |
| Hybrid/Entra | Yes/No | [how] | [time] |

### Risk Register
| Risk | Probability | Impact | Mitigation | Residual Risk |
|------|------------|--------|-----------|--------------|
| [Risk 1] | H/M/L | H/M/L | [Plan] | H/M/L |
| [Risk 2] | H/M/L | H/M/L | [Plan] | H/M/L |

### Pre-Change Checklist
- [ ] AD Backup verified: [date of last backup]
- [ ] Replication healthy: `repadmin /replsummary`
- [ ] Event logs clear of critical errors (24h)
- [ ] Change window communicated to stakeholders
- [ ] Rollback steps tested in lab
- [ ] Monitoring alerts configured
- [ ] Rollback resources standing by

### Go/No-Go Criteria
**Abort and rollback if any of the following occur:**
- [ ] [Criterion 1 — e.g., "Replication failures detected post-change"]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

### Approval Required From
- [ ] AD Engineering Lead
- [ ] Security Team (if security impact)
- [ ] [Application owners if apps affected]
- [ ] CAB Board

CHANGE DESCRIPTION:
[Describe the planned change]
```

---

## PROMPT 6: Generate AD Inventory Report (Structured)

```
Generate a comprehensive Active Directory environment inventory in structured format. I'll provide raw data; produce a clean, organized inventory document.

OUTPUT FORMAT:

## AD Environment Inventory — [Domain] — [Date]

### Forest & Domain Summary
| Property | Value |
|---------|-------|
| Forest Name | |
| Forest Functional Level | |
| Domain Name | |
| Domain Functional Level | |
| NetBIOS Name | |
| Total DCs | |
| Total Sites | |
| Trust Relationships | |
| Schema Version | |
| Recycle Bin Enabled | |
| Fine-Grained Password Policies | |

### Domain Controller Inventory
| DC Name | Site | Role | OS | IP | GC | RODC | FSMO Roles |
|---------|------|------|----|----|----|----|-----------|
[Rows for each DC]

### FSMO Role Holders
| Role | DC | Site |
|------|----|----|
| PDC Emulator | | |
| RID Master | | |
| Infrastructure Master | | |
| Schema Master | | |
| Domain Naming Master | | |

### Sites & Connectivity
| Site | Subnets | DC Count | Site Links |
|------|---------|----------|-----------|
[Rows per site]

### Account Summary
| Category | Count | Notes |
|---------|-------|-------|
| Total User Accounts | | |
| Enabled Users | | |
| Disabled Users | | |
| Locked Out (now) | | |
| Password Never Expires | | |
| Stale (90d+) | | |
| Service Accounts | | |
| Admin Accounts (Domain Admins) | | |
| Computer Accounts (Enabled) | | |
| Computer Accounts (Stale 60d) | | |

### Group Policy Summary
| Metric | Count/Value |
|-------|------------|
| Total GPOs | |
| Linked GPOs | |
| Unlinked GPOs | |
| Disabled GPOs | |
| GPOs Modified (7d) | |

### Health Indicators
| Indicator | Status | Last Checked |
|----------|--------|-------------|
| Replication | ✅/⚠️/❌ | |
| DNS Health | ✅/⚠️/❌ | |
| DC Services | ✅/⚠️/❌ | |
| SYSVOL/DFSR | ✅/⚠️/❌ | |
| Time Sync | ✅/⚠️/❌ | |
| Certificate Services | ✅/⚠️/❌ | |

RAW DATA TO STRUCTURE:
[Paste AD data here]
```
