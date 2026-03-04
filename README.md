# Active Directory Awesome — Elite AD × AI Engineering Resource

> World-class Active Directory prompts, runbooks, diagnostic tools, Jira templates, and HTML reports for engineers who use AI as a force multiplier.

**License**: MIT 2026 | **Audience**: AD Engineers, Identity Architects, SecOps, IAM Teams

---

## Quick Start

| I want to... | Go to |
|-------------|-------|
| Solve an AD problem right now | [solve-anything-ad.md](solve-anything-ad.md) |
| Troubleshoot a specific issue | [troubleshooting.md](troubleshooting.md) |
| Activate world-class AI for AD | [11_MASTER_AI_PROMPTS/01-ultimate-ad-system-prompt.md](11_MASTER_AI_PROMPTS/01-ultimate-ad-system-prompt.md) |
| Respond to a P0 incident | [01_IDENTITY_P0_COMMAND/p0_incident_commander_prompt.md](01_IDENTITY_P0_COMMAND/p0_incident_commander_prompt.md) |
| Investigate an account lockout | [13_RUNBOOKS/05-account-lockout-investigation.md](13_RUNBOOKS/05-account-lockout-investigation.md) |
| Generate an AD health report | [14_HTML_POWERSHELL_REPORTS/](14_HTML_POWERSHELL_REPORTS/) |
| Create a Jira ticket | [12_JIRA_TEMPLATES/](12_JIRA_TEMPLATES/) |
| Learn AD from scratch | [learning-ad.md](learning-ad.md) |
| Review AD security posture | [security-hardening.md](security-hardening.md) |

---

## Repository Structure

```
Active-Directory-Awesome/
│
├── 📋 ROOT ENTRY POINTS (Quick-access prompts)
│   ├── solve-anything-ad.md          Universal AD problem solver
│   ├── troubleshooting.md            5-scenario troubleshooter (auth, repl, DNS, GPO, lockout)
│   ├── building-ad.md                Infrastructure design & migration prompts
│   ├── gpo-builder.md                Group Policy design & troubleshooting
│   ├── learning-ad.md                Adaptive learning for any skill level
│   ├── security-hardening.md         AD security & attack defense
│   ├── powershell-expert.md          PowerShell one-liners & script generation
│   └── splunk-query-builder.md       SPL queries for AD monitoring
│
├── 00_GLOBAL_GUARDRAILS/             Safety, risk matrix, confidence calibration
├── 01_IDENTITY_P0_COMMAND/           P0 incident response framework
├── 02_AD_DEEP_DIVE_GUIDES/           15 in-depth topic guides (replication, Kerberos, DNS, GPO, etc.)
├── 03_HYBRID_IDENTITY/               Entra Connect, PTA, hybrid failure modes
├── 04_ENTRA_ID/                      Conditional Access, sign-in troubleshooting
├── 05_SECURITY_TELEMETRY/            MDI, MDE, Sentinel KQL queries, log correlation
├── 06_DEPENDENCIES_AND_OWNERSHIP/    RACI matrix, ownership model
├── 07_PROOF_AND_EXONERATION/         Proving issues are NOT identity-related
│
├── 08_AUTOMATION_AND_REPORTING/      PowerShell scripts, JSON schemas, diagnostic tools
│   ├── Get-DCHealthSnapshot.ps1      571-line DC health collector
│   ├── DCHealthReport.schema.json    JSON schema for DC health data
│   ├── ReplicationStatus.schema.json Replication status schema
│   ├── GPODrift.schema.json          GPO drift detection schema
│   ├── StaleAccounts.schema.json     Stale account schema
│   ├── TrustRelationship.schema.json Trust health schema
│   ├── Certificate-Expiry-v1.json    Certificate lifecycle template
│   ├── DC-Offline-v1.json            DC offline incident template
│   ├── DNS-Resolution-Failure-v1.json DNS failure template
│   ├── KRBTGT-Rotation-v1.json       KRBTGT rotation tracking
│   └── Replication-Failure-v1.json   Replication failure template
│
├── 09_GENERAL_WORLD_CLASS_PROMPTS/   Five Whys, OODA Loop, SBAR, bias mitigation
├── 10_AI_CONSULTANT_PERSONAS/        McKinsey, Deloitte, Incident Commander personas
│
├── ⭐ 11_MASTER_AI_PROMPTS/          Elite AI × AD prompt library
│   ├── 00-README.md                  Index & quick-start combos
│   ├── 01-ultimate-ad-system-prompt.md  Master system prompt — activates AD expert AI
│   ├── 02-chain-of-thought-diagnostics.md  5 CoT prompts for deep AD reasoning
│   ├── 03-structured-output-prompts.md    Force clean JSON/table/card outputs
│   ├── 04-read-only-safe-diagnostic-prompts.md  Production-safe commands only
│   ├── 05-ai-prompt-engineering-for-ad.md  8 principles for 10x AI results
│   ├── 06-jira-card-generator-prompts.md   Generate perfect Jira cards via AI
│   ├── 07-html-report-generator-prompts.md  AI → rich HTML reports
│   ├── 08-runbook-generator-prompts.md     Generate runbooks on demand
│   ├── 09-architecture-review-prompts.md   Full AD architecture review
│   └── 10-learning-acceleration-prompts.md  Become AD expert faster
│
├── 📝 12_JIRA_TEMPLATES/             Copy-paste Jira cards for all AD work
│   ├── INCIDENT-template.md          P0/P1/P2 incident card
│   ├── CHANGE-REQUEST-template.md    CAB-ready change request
│   ├── EPIC-template.md              Multi-week project epic
│   ├── SECURITY-FINDING-template.md  Vuln/audit finding card
│   ├── TASK-template.md              Operational task card
│   └── PIR-template.md               Post-incident review
│
├── 📖 13_RUNBOOKS/                   Production-grade operational runbooks
│   ├── README.md                     Runbook index & usage standards
│   ├── 04-krbtgt-rotation.md         KRBTGT password rotation (2-phase)
│   ├── 05-account-lockout-investigation.md  Lockout forensics
│   └── 07-replication-recovery.md    Replication failure recovery decision tree
│
└── 📊 14_HTML_POWERSHELL_REPORTS/    Read-only PowerShell → HTML report scripts
    ├── README.md                     Script index & quick start
    ├── Invoke-PrivilegedAccessReport.ps1  Privileged group membership dashboard
    └── Invoke-StaleAccountReport.ps1      Stale user & computer accounts
```

---

## Workflow Guides

### Responding to a P0/P1 Incident
```
1. Activate → 11_MASTER_AI_PROMPTS/01-ultimate-ad-system-prompt.md (Incident Commander mode)
2. Diagnose → 11_MASTER_AI_PROMPTS/04-read-only-safe-diagnostic-prompts.md
3. Reason → 11_MASTER_AI_PROMPTS/02-chain-of-thought-diagnostics.md
4. Document → 12_JIRA_TEMPLATES/INCIDENT-template.md
5. Execute → 13_RUNBOOKS/ (appropriate runbook)
6. Report → 14_HTML_POWERSHELL_REPORTS/Invoke-ADHealthReport (from 11_MASTER_AI_PROMPTS/07)
7. Close → 12_JIRA_TEMPLATES/PIR-template.md
```

### Planning a Change
```
1. Design → 11_MASTER_AI_PROMPTS/09-architecture-review-prompts.md
2. Risk review → 00_GLOBAL_GUARDRAILS/change_risk_matrix.md
3. Document → 12_JIRA_TEMPLATES/CHANGE-REQUEST-template.md
4. Execute → 13_RUNBOOKS/ (or generate one with 11_MASTER_AI_PROMPTS/08)
```

### Learning Active Directory
```
1. Start → learning-ad.md (entry point)
2. Deep dives → 02_AD_DEEP_DIVE_GUIDES/ (15 topic guides)
3. AI-accelerated → 11_MASTER_AI_PROMPTS/10-learning-acceleration-prompts.md
4. Practice → 11_MASTER_AI_PROMPTS/02-chain-of-thought-diagnostics.md (scenarios)
```

### Security Review
```
1. Assess → security-hardening.md + 11_MASTER_AI_PROMPTS/09-architecture-review-prompts.md
2. Detect → 05_SECURITY_TELEMETRY/ (MDI, Sentinel, MDE)
3. Document finding → 12_JIRA_TEMPLATES/SECURITY-FINDING-template.md
4. Report → 14_HTML_POWERSHELL_REPORTS/Invoke-PrivilegedAccessReport.ps1
```

---

## Quick Reference — AD Event IDs

| Event ID | Meaning | Key For |
|----------|---------|---------|
| 4624 | Successful logon | Baseline, lateral movement |
| 4625 | Failed logon | Lockout source, spray detection |
| 4634/4647 | Logoff | Session tracking |
| 4648 | Logon with explicit credentials | Pass-the-hash, runas |
| 4662 | Object operation (audit) | DCSync detection |
| 4672 | Special privileges at logon | Admin logon tracking |
| 4688 | Process creation | Lateral movement, malware |
| 4698 | Scheduled task created | Persistence detection |
| 4720 | User account created | Account provisioning |
| 4728/4732/4756 | Group member added | Privilege escalation |
| 4740 | **Account lockout** | Lockout investigation |
| 4769 | Kerberos service ticket | Kerberoasting detection |
| 4771 | Kerberos pre-auth failed | Password spray |
| 4776 | NTLM auth attempt | NTLM spray, credential testing |
| 5136 | AD object modified | Change tracking |
| 5137 | AD object created | New object tracking |
| 5141 | AD object deleted | Deletion tracking |

## Quick Reference — Common AD Ports

| Port | Service | Why It Matters |
|------|---------|---------------|
| 88 | Kerberos | Authentication — must be open to DCs |
| 389 | LDAP | Directory queries |
| 636 | LDAPS | Secure LDAP |
| 3268 | Global Catalog LDAP | Forest-wide searches |
| 3269 | Global Catalog LDAPS | Secure GC |
| 464 | Kerberos password change | Password changes |
| 53 | DNS | DC locator — critical |
| 445 | SMB | SYSVOL, NETLOGON shares |
| 135 | RPC Endpoint Mapper | Replication, remote management |
| 49152-65535 | RPC Dynamic Ports | Replication channels |

---

*Built for engineers who demand excellence. Safety-first, production-hardened, AI-optimized.*
