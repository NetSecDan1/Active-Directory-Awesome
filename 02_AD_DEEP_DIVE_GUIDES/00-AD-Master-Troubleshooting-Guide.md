# Active Directory Master Troubleshooting Guide

## AI-Powered Prompts & Instructions for Enterprise AD Engineers

> **Mission**: Equip Active Directory engineers with world-class AI prompts to diagnose, troubleshoot, and resolve critical AD infrastructure issues with precision, speed, and safety.

---

## Table of Contents

| # | Module | Critical Focus Areas |
|---|--------|---------------------|
| 01 | [Replication Issues](01-Replication-Issues.md) | Replication failures, USN rollback, lingering objects, convergence |
| 02 | [Authentication & Kerberos](02-Authentication-Kerberos.md) | Kerberos errors, NTLM fallback, SPN issues, delegation |
| 03 | [DNS Integration](03-DNS-Integration.md) | SRV records, scavenging, zone problems, conditional forwarders |
| 04 | [Group Policy](04-Group-Policy.md) | GPO processing, RSoP, inheritance, WMI filters, preferences |
| 05 | [FSMO Roles](05-FSMO-Roles.md) | Role placement, transfer, seizure, role holder failures |
| 06 | [Domain Controller Health](06-Domain-Controller-Health.md) | DCDiag, NETLOGON, services, time sync, secure channel |
| 07 | [Trust Relationships](07-Trust-Relationships.md) | Trust validation, cross-forest, selective authentication |
| 08 | [AD Database & Recovery](08-AD-Database-Recovery.md) | NTDS.dit, tombstone, backup/restore, authoritative restore |
| 09 | [Certificate Services](09-Certificate-Services.md) | AD CS, enrollment, templates, CRL, OCSP |
| 10 | [Security & Incident Response](10-Security-Incident-Response.md) | Compromise detection, credential theft, lateral movement |
| 11 | [Performance Optimization](11-Performance-Optimization.md) | LDAP queries, indexing, LSASS, connection optimization |
| 12 | [Azure AD & Hybrid Identity](12-Azure-AD-Hybrid.md) | AAD Connect, sync issues, pass-through auth, federation |
| 13 | [Account Management & Lockouts](13-Account-Management-Lockouts.md) | Lockout troubleshooting, stale accounts, password policies |
| 14 | [SYSVOL & DFS-R](14-SYSVOL-DFSR.md) | SYSVOL replication, DFS-R health, journal wrap |

---

## Universal AI System Prompt for AD Troubleshooting

```
You are an elite Microsoft Active Directory engineer with 20+ years of experience managing enterprise environments ranging from 10,000 to 500,000+ objects. You have deep expertise in:

- Windows Server 2008 R2 through Windows Server 2025
- Multi-domain, multi-forest architectures
- Hybrid identity with Azure AD / Entra ID
- Security hardening and incident response
- Disaster recovery and business continuity

CRITICAL OPERATING PRINCIPLES:

1. SAFETY FIRST: Always assess blast radius before recommending changes
2. DIAGNOSTIC BEFORE ACTION: Gather comprehensive data before conclusions
3. REVERSIBILITY: Prefer reversible actions; document rollback procedures
4. CHANGE MANAGEMENT: Note when changes require CAB approval or maintenance windows
5. LEAST PRIVILEGE: Recommend minimum required permissions for any action

RESPONSE FORMAT:
- Start with severity assessment (P1-Critical, P2-High, P3-Medium, P4-Low)
- Provide structured diagnostic steps with exact commands
- Explain the "why" behind each recommendation
- Include verification steps to confirm resolution
- Document any risks or prerequisites

When I describe an AD issue, help me systematically diagnose and resolve it while protecting the production environment.
```

---

## Quick Reference: Critical First Response Commands

### Immediate Health Assessment

```powershell
# Domain Controller comprehensive health check
dcdiag /v /c /d /e /s:DCName > C:\Logs\dcdiag_full.txt

# Replication status across enterprise
repadmin /replsummary
repadmin /showrepl * /csv > C:\Logs\replstatus.csv

# DNS health verification
dcdiag /test:dns /v /e

# FSMO role holders identification
netdom query fsmo

# Forest and domain functional levels
Get-ADForest | Select-Object ForestMode
Get-ADDomain | Select-Object DomainMode
```

### Emergency Contacts Checklist

Before engaging AI assistance for critical issues, ensure you have:

- [ ] Current AD topology diagram
- [ ] FSMO role holder list
- [ ] Recent backup status and locations
- [ ] Change management ticket number (if applicable)
- [ ] Rollback plan documented
- [ ] Stakeholder communication plan

---

## Severity Classification Matrix

| Severity | Impact | Response Time | Examples |
|----------|--------|---------------|----------|
| **P1 - Critical** | Complete AD outage, all authentication failing | Immediate | All DCs down, forest-wide replication failure |
| **P2 - High** | Significant degradation, business impact | < 1 hour | Single-site DC failure, FSMO holder offline |
| **P3 - Medium** | Partial impact, workaround available | < 4 hours | GPO not applying, replication delays |
| **P4 - Low** | Minor issue, no immediate business impact | < 24 hours | Stale computer objects, minor event log errors |

---

## How to Use These Prompts

### Step 1: Identify the Problem Category
Review the table of contents and select the most relevant module for your issue.

### Step 2: Gather Initial Data
Run the Quick Reference commands above to collect baseline information.

### Step 3: Use the Module-Specific Prompts
Each module contains:
- **Diagnostic Prompts**: For understanding and isolating issues
- **Resolution Prompts**: For implementing fixes safely
- **Verification Prompts**: For confirming successful resolution
- **Prevention Prompts**: For implementing long-term safeguards

### Step 4: Document Everything
Maintain detailed records of:
- Initial symptoms and error messages
- Diagnostic data collected
- Actions taken and their outcomes
- Root cause analysis
- Preventive measures implemented

---

## Emergency Escalation Framework

```
ESCALATION PROMPT:

I have a [SEVERITY LEVEL] Active Directory incident affecting [SCOPE].

CURRENT SYMPTOMS:
[Describe what users/systems are experiencing]

DIAGNOSTIC DATA COLLECTED:
[Paste relevant command outputs]

ACTIONS ALREADY TAKEN:
[List troubleshooting steps completed]

BUSINESS IMPACT:
[Quantify affected users/systems/revenue if known]

CONSTRAINTS:
- Maintenance window: [Yes/No, timing if yes]
- Change approval: [Approved/Pending/Emergency]
- Available resources: [Team size, expertise level]

Help me determine the fastest safe path to resolution while minimizing risk to the production environment.
```

---

## Contributing & Feedback

These prompts are designed to evolve with the AD engineering community. When using these prompts:

1. **Document Success**: Note which prompts resolved issues effectively
2. **Identify Gaps**: Flag scenarios not adequately covered
3. **Share Improvements**: Contribute enhanced prompts based on real-world experience

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01 | Initial release - Complete AD troubleshooting suite |

---

**Remember**: AI is a powerful diagnostic partner, but critical AD changes should always be validated by experienced engineers and follow your organization's change management processes.
