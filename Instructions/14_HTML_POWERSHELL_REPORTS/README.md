# 14_HTML_POWERSHELL_REPORTS — Rich HTML Report Scripts

> Production-ready PowerShell scripts that generate professional HTML reports from AD data. All scripts are **read-only** — zero changes to your environment.

---

## Scripts

| Script | Output | Safe to Run | Frequency |
|--------|--------|-------------|-----------|
| [Invoke-ADHealthReport.ps1](Invoke-ADHealthReport.ps1) | Full AD health dashboard | ✅ Always | Daily/Weekly |
| [Invoke-ADSecurityPostureReport.ps1](Invoke-ADSecurityPostureReport.ps1) | Security gap analysis | ✅ Always | Monthly |
| [Invoke-StaleAccountReport.ps1](Invoke-StaleAccountReport.ps1) | Stale user & computer accounts | ✅ Always | Weekly |
| [Invoke-GPOReport.ps1](Invoke-GPOReport.ps1) | GPO inventory and change tracking | ✅ Always | Weekly |
| [Invoke-PrivilegedAccessReport.ps1](Invoke-PrivilegedAccessReport.ps1) | Privileged group membership | ✅ Always | Daily |

> **Full featured** `Invoke-ADHealthReport.ps1` is embedded in `11_MASTER_AI_PROMPTS/07-html-report-generator-prompts.md` — copy it from there.

---

## Quick Start

```powershell
# Run any report — outputs HTML to your Desktop by default
.\Invoke-ADHealthReport.ps1

# Specify output path
.\Invoke-ADHealthReport.ps1 -OutputPath "C:\Reports\AD_Health_$(Get-Date -Format yyyyMMdd).html"

# Target specific domain
.\Invoke-ADHealthReport.ps1 -Domain "corp.contoso.com"
```

---

## Report Features

All reports include:
- **Color-coded status** (Green / Yellow / Red)
- **Health score** (0-100)
- **Executive summary** at top
- **Sortable tables** for technical detail
- **Timestamped** for audit trail
- **Self-contained HTML** (single file, no external dependencies)
