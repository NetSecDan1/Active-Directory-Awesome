# 11_MASTER_AI_PROMPTS — Elite AD & Identity AI Prompt Library

> Copy-paste prompts for Microsoft Copilot Studio agents, Claude, GPT-4, and any LLM. Every prompt enforces the **Information-First Protocol** — the AI asks for all required context before generating any output. No assumptions. No guessed environment details.

---

## How to Use This Library

1. **Copy a prompt** into your AI chat (Claude, Copilot, GPT-4) as the system prompt or first message
2. **Answer the info-gathering questions** the AI asks — these are critical for accurate output
3. **Follow the output format** defined in each prompt
4. **Chain prompts together** for complex, multi-phase work (see Combos section)

---

## Prompt Index

| # | File | Purpose | When to Use |
|---|------|---------|-------------|
| 01 | [01-ultimate-ad-system-prompt.md](01-ultimate-ad-system-prompt.md) | Activate AI as expert AD engineer | Starting any new AD/identity AI session |
| 02 | [02-chain-of-thought-diagnostics.md](02-chain-of-thought-diagnostics.md) | Deep step-by-step reasoning | Issue is multi-layered or root cause is unclear |
| 03 | [03-structured-output-prompts.md](03-structured-output-prompts.md) | Force clean JSON / table / card output | Need machine-readable or copy-paste-ready output |
| 04 | [04-read-only-safe-diagnostic-prompts.md](04-read-only-safe-diagnostic-prompts.md) | Production-safe investigation only | Working on production DCs with no write access |
| 05 | [05-ai-prompt-engineering-for-ad.md](05-ai-prompt-engineering-for-ad.md) | 8 principles for 10x better AI results | Building or improving your own AD prompts |
| 06 | [06-jira-card-generator-prompts.md](06-jira-card-generator-prompts.md) | Generate incidents, changes, epics, stories | Need a Jira card, fast and complete |
| 07 | [07-html-report-generator-prompts.md](07-html-report-generator-prompts.md) | PowerShell → HTML health dashboards | Need a visual report from AD data |
| 08 | [08-runbook-generator-prompts.md](08-runbook-generator-prompts.md) | Generate production runbooks on demand | No runbook exists for your specific procedure |
| 09 | [09-architecture-review-prompts.md](09-architecture-review-prompts.md) | Full AD architecture assessment | Planning a major change or new design |
| 10 | [10-learning-acceleration-prompts.md](10-learning-acceleration-prompts.md) | Become an AD expert faster | Onboarding, cert prep, or skill building |
| 11 | [11-itil-change-audit-prompts.md](11-itil-change-audit-prompts.md) | ITIL pre-change audit, risk matrix, CAB pack | Before ANY significant AD/identity change |
| 12 | [12-info-gathering-protocol.md](12-info-gathering-protocol.md) | Information-First Protocol reference | Building new prompts; embedding in agents |

---

## Information-First Protocol (IFP)

**Rule**: The AI always asks for all required context before generating output. No silent defaults. No assumed environment details.

See `12-info-gathering-protocol.md` for the full protocol, reusable question bank, and integration guide for new prompts.

---

## Prompt Quality Standard

Every prompt meets this bar:
- **Expert-calibrated**: Outputs match Microsoft CSS Principal / AD MVP level
- **Safety-encoded**: Write operations gated and labelled with risk level
- **Information-first**: AI gathers context before generating — never assumes
- **Structured output**: Tables, checklists, code blocks — no prose walls
- **Chain-ready**: Composable with other prompts and runbooks

---

## Quick-Start Combos

### P0 Identity Incident Response
```
01 (activate expert) → 04 (safe diagnostic) → 02 (chain-of-thought) → 01_IDENTITY_P0_COMMAND/p0_incident_commander_prompt.md
```

### Pre-Change ITIL Audit + CAB Pack
```
11 (ITIL audit) → 06 (change request card) → 13_RUNBOOKS/[relevant runbook]
```

### Security Posture Review
```
01 → 09 (architecture review) → 19-privileged-identity-tier-audit runbook → 12_JIRA_TEMPLATES/SECURITY-FINDING-template.md
```

### Sprint Planning for AD Work
```
12 (info gathering) → 06 (generate cards) → 12_JIRA_TEMPLATES/STORY-template.md (Fibonacci sizing)
```

### HTML Health Report
```
07 (report prompt) → 14_HTML_POWERSHELL_REPORTS/
```

---

## Fibonacci Story Points Quick Reference

| Points | Effort | Rule |
|--------|--------|------|
| **1** | < 1 hour | Trivial, fully documented |
| **2** | 1–3 hours | Small, 1–2 steps |
| **4** | Half day | Moderate, multiple steps |
| **8** | 1–2 days | Complex — **must break down before sprint** |
