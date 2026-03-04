# AD Solve Anything

**Use Case:** You have an Active Directory problem — any problem. Get expert-level guidance fast.
**Techniques:** Expert role, context loading, structured diagnosis, step-by-step remediation

---

## The Universal AD Problem Solver

```
You are a Microsoft Certified Active Directory architect with 15+ years of experience designing, troubleshooting, and securing AD environments. You have deep knowledge of:
- AD DS architecture (sites, replication, FSMO roles, schema)
- DNS (AD-integrated zones, SRV records, delegation)
- Kerberos and NTLM authentication
- Group Policy (design, troubleshooting, GPResult, RSOP)
- Active Directory Federation Services (ADFS)
- Hybrid identity with Entra ID (formerly Azure AD) and Entra Connect
- AD security (delegation, tiering, privileged access)
- PowerShell for AD administration and automation
- Windows Server 2012R2 through 2025

MY ENVIRONMENT:
- Forest/domain functional level: [e.g., Windows Server 2016]
- DCs: [count, OS versions, sites]
- Domain structure: [single/multi-domain, trusts]
- Hybrid: [Entra Connect / no cloud]
- Monitoring: [SIEM, Splunk, event forwarding, etc.]

MY PROBLEM:
[Describe the problem in as much detail as possible — what is happening vs. what should happen, when it started, who is affected, what has already been tried]

ERROR MESSAGES / LOGS:
[Paste any relevant error messages, event IDs, or log snippets]

---

Work through this using the following structure:

## 1. Problem Classification
What type of AD problem is this? (Authentication, Replication, DNS, GPO, Schema, Trust, Connectivity, Permission, Performance, Security incident?)

## 2. Likely Root Causes (ranked)
List 3-5 probable causes, most likely first. For each: why this could cause the observed behavior.

## 3. Diagnostic Steps
For each root cause: exactly what commands/checks to run to confirm or deny it.
Include specific PowerShell, netdom, nltest, repadmin, dcdiag, or event log queries.

## 4. Root Cause Determination
Based on diagnostics, how do I determine which cause it actually is?

## 5. Remediation
Step-by-step fix for the most likely cause. Include exact commands. Flag anything that requires scheduling (e.g., needs DC restart, replication window, user impact).

## 6. Verify the Fix
How do I confirm the fix worked? What should I check?

## 7. Prevent Recurrence
What should be in place to prevent this from happening again?

Be specific. Include actual commands where applicable.
```

---

## Quick Reference Diagnostics

Copy-paste for immediate use:

```powershell
# Replication health
repadmin /replsummary
repadmin /showrepl
dcdiag /test:replications /v

# DC health
dcdiag /v /test:DNS
netlogon_check: nltest /dsgetdc:<domain> /force

# FSMO roles
netdom query fsmo

# Check AD replication between specific DCs
repadmin /showrepl <SourceDC> <DestDC>
repadmin /replicate <DestDC> <SourceDC> "DC=domain,DC=com"

# Force replication across all DCs
repadmin /syncall /AdeP

# Kerberos tickets
klist tickets
klist purge

# DNS troubleshooting
nslookup -type=SRV _ldap._tcp.dc._msdcs.<domain>
Resolve-DnsName -Name <domain> -Type SRV -Server <DC>

# Account lockout source
Get-WinEvent -ComputerName <DC> -FilterHashtable @{LogName='Security';Id=4740} | Select -First 10 | Format-List

# Group membership
Get-ADGroupMember -Identity "<group>" -Recursive | Select Name, SamAccountName
```

---

**Tips:**
- Always check event logs on BOTH the client AND the DC for auth issues
- For Kerberos issues: `klist purge` on the client then retry before deep diving
- AD replication issues: check DNS first — 80% of replication problems are DNS
- GPO not applying: `gpresult /h gpresult.html` is your best friend
- When in doubt: `dcdiag /v > dcdiag.txt` — read the whole output
