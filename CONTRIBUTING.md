# Contributing to Active-Directory-Awesome

Thanks for wanting to make this better. This repo lives or dies by the quality of its content — every contribution should raise the bar, not lower it.

---

## Content Quality Bar

Every piece of content must meet this standard:

- **Expert-calibrated**: Would a Microsoft CSS Principal or AD MVP nod at this?
- **Production-safe**: Read-only commands clearly marked. Write commands have risk labels and rollbacks.
- **Specific**: No vague "check your settings." Give exact commands, event IDs, error codes.
- **Structured**: Use the established formats (tables, numbered steps, checklists).
- **Tested**: If it's a PowerShell script, it's been run against a real AD environment.

---

## What We Need More Of

- **Runbooks** for operations not yet covered (`13_RUNBOOKS/`)
- **HTML report scripts** for new report types (`14_HTML_POWERSHELL_REPORTS/`)
- **Detection queries** for attack techniques not yet covered (`05_SECURITY_TELEMETRY/query-library.md`)
- **Deep-dive guides** for topics not in `02_AD_DEEP_DIVE_GUIDES/`
- **Jira templates** for AD scenarios not yet templated (`12_JIRA_TEMPLATES/`)

---

## Contribution Process

1. **Fork** the repo
2. **Create a branch**: `feature/add-dc-health-runbook` or `fix/krbtgt-rotation-step-3`
3. **Write your content** following the formats below
4. **Self-review** against the quality bar above
5. **Submit a PR** with a clear description of what you added and why

---

## File Naming Conventions

| Folder | Convention | Example |
|--------|-----------|---------|
| `13_RUNBOOKS/` | `NN-kebab-case-description.md` | `09-schema-extension.md` |
| `14_HTML_POWERSHELL_REPORTS/` | `Invoke-VerbNoun.ps1` | `Invoke-CertExpiryReport.ps1` |
| `12_JIRA_TEMPLATES/` | `NOUN-template.md` | `RFC-template.md` |
| `02_AD_DEEP_DIVE_GUIDES/` | `NN-Title-Case.md` | `15-Fine-Grained-Passwords.md` |
| `15_EXPERT_LEARNING_PATHS/` | `NN-kebab-case.md` | `04-active-directory-for-devs.md` |

---

## Runbook Template

```markdown
# Runbook: [Action] [Object]
**Risk**: [READ-ONLY / LOW / MEDIUM / HIGH / CRITICAL]
**Estimated Time**: [X hours]
**Requires**: [Role / access needed]
**Change Type**: [None / Emergency / Normal — CAB Required]
**Version**: 1.0

## Overview
[2-3 sentences: what this runbook does and when you use it]

## Phase 0 — Pre-Checks (READ-ONLY)
[Pre-conditions that must be true before starting]

## Phase N — [Step Name]
### Step N.N — [Action]
\`\`\`powershell
# WRITE OPERATION — Risk: [LEVEL]
# Rollback: [how to undo]
[command]
\`\`\`
**Expected**: [what success looks like]

## Verification (READ-ONLY)
[Commands to confirm the operation succeeded]

## Rollback
[How to undo everything if needed]
```

---

## PowerShell Script Standards

All `.ps1` files must:

```powershell
#Requires -Modules ActiveDirectory  # Declare dependencies
<#
.SYNOPSIS    One-line description
.DESCRIPTION Full description — mention READ-ONLY if applicable
.PARAMETER   Document every parameter
.EXAMPLE     At least one working example
#>
[CmdletBinding()]
param(...)

# Use -ErrorAction Continue (not Stop) so one failure doesn't abort the report
# Use Write-Host with timestamps for progress: "[HH:mm:ss] Doing X..."
# Always output to a file AND open it (Start-Process $OutputPath)
# Never prompt for credentials mid-script — use -Credential parameter
```

---

## Things We Don't Want

- Attack tools or exploit code (this is a defensive resource)
- Vendor-specific content that doesn't apply broadly
- Untested scripts ("should work" is not good enough)
- Duplicate content — check existing files before adding
- Documentation files (no `*_README.md` prefixes, no `NOTES.md` files)
- Timestamped or dated content ("as of 2025..." becomes stale)

---

## Questions?

Open an issue describing what you want to add. We'll discuss before you spend time writing it.
