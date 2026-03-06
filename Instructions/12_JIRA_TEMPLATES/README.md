# 12_JIRA_TEMPLATES — Active Directory Jira Card Templates

> **Copy → Paste → Fill in the blanks.** Standalone templates for every AD work type. For AI-assisted generation, see `11_MASTER_AI_PROMPTS/06-jira-card-generator-prompts.md`.

## Template Index

| File | Card Type | When to Use |
|------|-----------|-------------|
| [INCIDENT-template.md](INCIDENT-template.md) | Incident | Active P0/P1/P2 — something is broken now |
| [CHANGE-REQUEST-template.md](CHANGE-REQUEST-template.md) | Change Request | Planned change requiring CAB approval |
| [EPIC-template.md](EPIC-template.md) | Epic | Multi-week project with multiple child stories |
| [STORY-template.md](STORY-template.md) | Story | Discrete sprint deliverable — uses Fibonacci points |
| [TASK-template.md](TASK-template.md) | Task | Sub-task or standalone operational action |
| [SECURITY-FINDING-template.md](SECURITY-FINDING-template.md) | Security Finding | Vulnerability, audit finding, or risk |
| [PIR-template.md](PIR-template.md) | PIR | Post-incident review after any P0/P1 |

## Fibonacci Story Point Sizing

| Points | Effort | Use when... | Break down? |
|--------|--------|------------|-------------|
| **1** | < 1 hour | Trivial, fully documented, zero unknowns | No |
| **2** | 1–3 hours | Small, well-understood, 1–2 steps | No |
| **4** | Half day | Multiple steps, some coordination needed | Consider if blockers emerge |
| **8** | 1–2 days | Complex, cross-team, or novel in this env | **Yes — required before sprint** |

> **8-point rule**: Break into Discovery (1–2pt) + Implementation (2–4pt) + Validation (1–2pt) + Docs (1pt).

## Jira Label Standards

| Label | Use for |
|-------|---------|
| `active-directory` | Any AD DS work |
| `entra-id` | Azure AD / Entra ID work |
| `hybrid-identity` | Entra Connect, PTA, ADFS |
| `identity-security` | Security findings, hardening, audits |
| `pki` | AD CS / certificate management |
| `dns` | DNS changes or investigations |
| `conditional-access` | CA policy work |
| `mdi` | Microsoft Defender for Identity |
| `change-request` | CAB-bound changes |
| `runbook` | Runbook creation or execution |
| `incident` | Active or incident-triggered work |
| `tech-debt` | Known technical debt |
| `p0` / `p1` / `p2` / `p3` | Incident severity |
