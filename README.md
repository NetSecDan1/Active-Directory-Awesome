# Active Directory Awesome — Elite AD × AI Engineering Resource

> World-class Active Directory prompts, runbooks, Jira templates, ITIL change audits, and HTML reports for engineers who use AI as a force multiplier. Every prompt enforces the Information-First Protocol — the AI always asks before it assumes.

**License**: MIT 2026 | **Audience**: AD Engineers, Identity Architects, SecOps, IAM Teams

---

## Quick Start

| I want to... | Go to |
|-------------|-------|
| Solve an AD problem right now | [solve-anything-ad.md](solve-anything-ad.md) |
| Troubleshoot a specific issue | [troubleshooting.md](troubleshooting.md) |
| Activate world-class AI for AD | [Instructions/11_MASTER_AI_PROMPTS/01-ultimate-ad-system-prompt.md](Instructions/11_MASTER_AI_PROMPTS/01-ultimate-ad-system-prompt.md) |
| Run a pre-change ITIL audit | [Instructions/11_MASTER_AI_PROMPTS/11-itil-change-audit-prompts.md](Instructions/11_MASTER_AI_PROMPTS/11-itil-change-audit-prompts.md) |
| Respond to a P0 incident | [Instructions/01_IDENTITY_P0_COMMAND/p0_incident_commander_prompt.md](Instructions/01_IDENTITY_P0_COMMAND/p0_incident_commander_prompt.md) |
| Investigate an account lockout | [Instructions/13_RUNBOOKS/05-account-lockout-investigation.md](Instructions/13_RUNBOOKS/05-account-lockout-investigation.md) |
| Audit privileged identities | [Instructions/13_RUNBOOKS/19-privileged-identity-tier-audit.md](Instructions/13_RUNBOOKS/19-privileged-identity-tier-audit.md) |
| Generate an AD health report | [Instructions/14_HTML_POWERSHELL_REPORTS/](Instructions/14_HTML_POWERSHELL_REPORTS/) |
| Create a Jira card | [Instructions/12_JIRA_TEMPLATES/](Instructions/12_JIRA_TEMPLATES/) |
| Learn AD from scratch | [learning-ad.md](learning-ad.md) |
| Review AD security posture | [security-hardening.md](security-hardening.md) |

---

## Repository Structure

```
Active-Directory-Awesome/
│
├── ROOT ENTRY POINTS (quick-access prompts)
│   ├── solve-anything-ad.md          Universal AD problem solver
│   ├── troubleshooting.md            5-scenario troubleshooter
│   ├── building-ad.md                Infrastructure design & migration
│   ├── gpo-builder.md                Group Policy design & troubleshooting
│   ├── learning-ad.md                Adaptive learning for any skill level
│   ├── security-hardening.md         AD security & attack defense
│   ├── powershell-expert.md          PowerShell automation & script generation
│   └── splunk-query-builder.md       SPL queries for AD monitoring
│
├── Skills/                           Claude Code & Copilot Studio skill files
│   ├── AD Expert.md                  Merged operator prompt (PowerShell + troubleshooting)
│   ├── skill.md                      Prompt & skill authoring skill
│   ├── skill author.md               Skill authoring guide
│   └── ad-identity-copilot.skill.md  Production Copilot Studio / MCP skill (NEW)
│
├── _Archive/                         Superseded content — not active
│
└── Instructions/                     Agent knowledge base (Copilot Studio / MCP)
    │
    ├── AGENT_SYSTEM_PROMPT.md        Copilot Studio system prompt (deploy this)
    ├── MCP_SKILLS_INDEX.md           MCP tool manifest — maps all skills to parameters
    │
    ├── 00_GLOBAL_GUARDRAILS/         Safety rules, risk matrix, confidence scoring
    ├── 01_IDENTITY_P0_COMMAND/       P0 incident commander framework
    ├── 02_AD_DEEP_DIVE_GUIDES/       15 topic guides: replication, Kerberos, DNS, GPO...
    ├── 03_HYBRID_IDENTITY/           Entra Connect, PTA, hybrid failure modes
    ├── 04_ENTRA_ID/                  Conditional Access, sign-in troubleshooting
    ├── 05_SECURITY_TELEMETRY/        MDI, MDE, Sentinel KQL, log correlation
    ├── 06_DEPENDENCIES_AND_OWNERSHIP/ RACI matrix, ownership model
    ├── 07_PROOF_AND_EXONERATION/     Proving issues are NOT identity-related
    ├── 08_AUTOMATION_AND_REPORTING/  PowerShell scripts, JSON schemas
    ├── 09_GENERAL_WORLD_CLASS_PROMPTS/ Five Whys, OODA Loop, SBAR
    ├── 10_AI_CONSULTANT_PERSONAS/    McKinsey, Deloitte, Incident Commander personas
    │
    ├── 11_MASTER_AI_PROMPTS/         Elite AI prompt library (12 files)
    │   ├── 01-ultimate-ad-system-prompt.md
    │   ├── 02-chain-of-thought-diagnostics.md
    │   ├── 03-structured-output-prompts.md
    │   ├── 04-read-only-safe-diagnostic-prompts.md
    │   ├── 05-ai-prompt-engineering-for-ad.md
    │   ├── 06-jira-card-generator-prompts.md
    │   ├── 07-html-report-generator-prompts.md
    │   ├── 08-runbook-generator-prompts.md
    │   ├── 09-architecture-review-prompts.md
    │   ├── 10-learning-acceleration-prompts.md
    │   ├── 11-itil-change-audit-prompts.md   ← ITIL pre-change audit (NEW)
    │   └── 12-info-gathering-protocol.md     ← Never-assume protocol (NEW)
    │
    ├── 12_JIRA_TEMPLATES/            Copy-paste Jira templates (7 types)
    │   ├── INCIDENT-template.md
    │   ├── CHANGE-REQUEST-template.md
    │   ├── EPIC-template.md
    │   ├── STORY-template.md         ← Fibonacci story points (NEW)
    │   ├── TASK-template.md
    │   ├── SECURITY-FINDING-template.md
    │   └── PIR-template.md
    │
    ├── 13_RUNBOOKS/                  19 operational runbooks
    │   ├── Operations: 01-08 (health check, DC promo/decomm, KRBTGT, FSMO, replication, DR)
    │   ├── Troubleshooting: 05, 09-11, 14, 16-18 (lockout, DNS, Kerberos, GPO, SPN, PKI, Entra Connect, CA)
    │   ├── ETFC: 12-13 (forest trust, cross-forest auth)
    │   └── Security: 15, 19 (MDI sensor health, privileged identity audit)
    │
    ├── 14_HTML_POWERSHELL_REPORTS/   Read-only PowerShell → HTML dashboards
    │   ├── Invoke-ADHealthReport.ps1
    │   ├── Invoke-ADSecurityPostureReport.ps1
    │   ├── Invoke-GPOReport.ps1
    │   ├── Invoke-PrivilegedAccessReport.ps1
    │   └── Invoke-StaleAccountReport.ps1
    │
    └── 15_EXPERT_LEARNING_PATHS/     Onboarding, cert prep, attack & defense
```

---

## Workflow Guides

### Responding to a P0/P1 Incident
```
1. Activate   → Instructions/11_MASTER_AI_PROMPTS/01-ultimate-ad-system-prompt.md
2. Diagnose   → Instructions/11_MASTER_AI_PROMPTS/04-read-only-safe-diagnostic-prompts.md
3. Reason     → Instructions/11_MASTER_AI_PROMPTS/02-chain-of-thought-diagnostics.md
4. Document   → Instructions/12_JIRA_TEMPLATES/INCIDENT-template.md
5. Execute    → Instructions/13_RUNBOOKS/ (appropriate runbook)
6. Report     → Instructions/14_HTML_POWERSHELL_REPORTS/
7. Close      → Instructions/12_JIRA_TEMPLATES/PIR-template.md
```

### Planning a Change (ITIL)
```
1. Audit      → Instructions/11_MASTER_AI_PROMPTS/11-itil-change-audit-prompts.md (CAB pack)
2. Risk       → Instructions/00_GLOBAL_GUARDRAILS/change_risk_matrix.md
3. Document   → Instructions/12_JIRA_TEMPLATES/CHANGE-REQUEST-template.md
4. Execute    → Instructions/13_RUNBOOKS/ (appropriate runbook)
5. Stories    → Instructions/12_JIRA_TEMPLATES/STORY-template.md (Fibonacci: 1/2/4/8)
```

### Security Review
```
1. Audit tiers   → Instructions/13_RUNBOOKS/19-privileged-identity-tier-audit.md
2. Review MDI    → Instructions/13_RUNBOOKS/15-mdi-sensor-health-troubleshooting.md
3. Detect        → Instructions/05_SECURITY_TELEMETRY/
4. Document      → Instructions/12_JIRA_TEMPLATES/SECURITY-FINDING-template.md
5. Report        → Instructions/14_HTML_POWERSHELL_REPORTS/Invoke-ADSecurityPostureReport.ps1
```

### Learning Active Directory
```
1. Entry point   → learning-ad.md
2. Deep dives    → Instructions/02_AD_DEEP_DIVE_GUIDES/ (15 topics)
3. AI-coached    → Instructions/11_MASTER_AI_PROMPTS/10-learning-acceleration-prompts.md
4. Practice      → Instructions/11_MASTER_AI_PROMPTS/02-chain-of-thought-diagnostics.md
```

---

## Quick Reference — AD Event IDs

| Event ID | Meaning | Key For |
|----------|---------|---------|
| 4624 | Successful logon | Baseline, lateral movement |
| 4625 | Failed logon | Lockout source, spray detection |
| 4648 | Logon with explicit credentials | Pass-the-hash, runas |
| 4662 | Object operation | DCSync detection |
| 4672 | Special privileges at logon | Admin logon tracking |
| 4728/4732/4756 | Group member added | Privilege escalation |
| 4740 | **Account lockout** | Lockout investigation |
| 4769 | Kerberos service ticket request | Kerberoasting detection |
| 4771 | Kerberos pre-auth failed | Password spray detection |
| 4776 | NTLM authentication attempt | NTLM spray |
| 5136 | AD object modified | Change tracking |
| 5141 | AD object deleted | Deletion tracking |

## Quick Reference — Common AD Ports

| Port | Service | Why It Matters |
|------|---------|---------------|
| 88 | Kerberos | Authentication — must be open to DCs |
| 389 / 636 | LDAP / LDAPS | Directory queries |
| 3268 / 3269 | Global Catalog | Forest-wide searches |
| 464 | Kerberos password change | Password changes across trusts |
| 53 | DNS | DC locator — critical for everything |
| 445 | SMB | SYSVOL, NETLOGON, Group Policy |
| 135 + 49152-65535 | RPC | Replication, remote management |

---

*Built for engineers who demand excellence. Safety-first, production-hardened, AI-optimized.*
