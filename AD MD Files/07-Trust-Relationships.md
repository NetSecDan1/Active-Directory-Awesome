# Active Directory Trust Relationships Troubleshooting

## AI Prompts for Managing and Troubleshooting AD Trusts

---

## Overview

Trust relationships enable resource access between Active Directory domains and forests. Trust failures can prevent cross-domain authentication, break applications, and disrupt business operations. This module provides comprehensive AI prompts for trust management and troubleshooting.

---

## Section 1: Trust Assessment and Inventory

### Prompt 1.1: Trust Inventory and Health Check

```
I need to assess all trust relationships in my AD environment.

ENVIRONMENT:
- Number of forests: [X]
- Number of domains: [X]
- Forest root domain: [Name]
- External trusts: [List partner domains/forests]

KNOWN TRUST ISSUES (if any):
[Describe current problems]

Please provide:
1. Commands to enumerate all trust relationships
2. Trust health verification procedures
3. Trust type identification (forest, external, realm, shortcut)
4. Trust direction and transitivity assessment
5. Selective authentication status check
6. SID filtering status
7. Complete trust documentation template
```

### Prompt 1.2: Trust Validation

```
I need to validate that existing trusts are functioning correctly.

TRUSTS TO VALIDATE:
- Trust 1: [Domain A] <-> [Domain B] ([Type])
- Trust 2: [Continue as needed]

VALIDATION REQUIREMENTS:
- Authentication working: [Yes/No/Intermittent]
- Resource access working: [Yes/No/Intermittent]
- Replication via trust: [If applicable]

Please provide:
1. Trust validation commands (netdom, nltest)
2. Cross-domain authentication testing
3. Kerberos ticket verification across trust
4. DNS resolution verification for trusted domain
5. Network port verification for trust traffic
6. SID history considerations
7. Complete validation checklist
```

---

## Section 2: Trust Failures

### Prompt 2.1: Trust Relationship Failed

```
A trust relationship has failed.

TRUST DETAILS:
- Local domain: [Name]
- Trusted/trusting domain: [Name]
- Trust type: [Forest/External/Shortcut/Realm]
- Trust direction: [One-way/Two-way, inbound/outbound]

ERROR MESSAGE:
[Paste exact error from trust validation]

SYMPTOMS:
[Describe - auth failures, access denied, etc.]

NLTEST OUTPUT:
[Paste nltest /sc_query:trusteddomain output]

Please provide:
1. Common causes for trust failures
2. Diagnostic commands to isolate the issue
3. Trust password reset procedure
4. Network connectivity verification
5. DNS resolution for trusted domain
6. Kerberos and NTLM path verification
7. Resolution steps
8. Verification after repair
```

### Prompt 2.2: Intermittent Trust Issues

```
Trust authentication is working intermittently.

TRUST: [Domain A] <-> [Domain B]
PATTERN:
- Works from some DCs but not others
- Works at certain times but not others
- Affects certain users but not all

SYMPTOMS DETAIL:
[Describe specific behavior]

Please provide:
1. Causes of intermittent trust issues
2. DC-specific trust validation
3. Load balancing and DC selection issues
4. Network path analysis
5. DNS round-robin considerations
6. Trust password age verification
7. Site-aware trust traffic analysis
8. Resolution approach
```

---

## Section 3: Trust Creation and Configuration

### Prompt 3.1: Create New Forest Trust

```
I need to create a new forest trust.

LOCAL FOREST: [Name]
REMOTE FOREST: [Name]
TRUST TYPE NEEDED: [Forest trust]
DIRECTION: [One-way (inbound/outbound) / Two-way]
SELECTIVE AUTHENTICATION: [Required/Not required]
SID FILTERING: [Standard/Relaxed]

CURRENT STATE:
- DNS resolution between forests: [Verified/Not verified]
- Network connectivity: [Verified/Not verified]
- Admin credentials for both forests: [Available/Not available]

Please provide:
1. Prerequisites checklist
2. DNS configuration requirements
3. Network port requirements
4. Step-by-step trust creation procedure
5. Selective authentication configuration
6. SID filtering considerations
7. Post-creation validation
8. Documentation requirements
```

### Prompt 3.2: Create External Trust

```
I need to create an external trust to a Windows NT domain or non-transitive trust.

LOCAL DOMAIN: [Name]
EXTERNAL DOMAIN: [Name]
PURPOSE: [Describe why external trust needed]
DIRECTION: [One-way/Two-way]

Please provide:
1. When to use external vs. forest trust
2. Prerequisites for external trust
3. DNS requirements
4. Creation procedure
5. Security considerations for external trusts
6. SID filtering implications
7. Validation steps
8. Ongoing maintenance requirements
```

### Prompt 3.3: Create Shortcut Trust

```
I want to create a shortcut trust to optimize authentication.

DOMAINS INVOLVED:
- Domain A: [Name, forest path]
- Domain B: [Name, forest path]

CURRENT TRUST PATH:
[Describe the current path authentication takes]

REASON FOR SHORTCUT:
[Performance, reliability, etc.]

Please provide:
1. How shortcut trusts work
2. When shortcut trusts are beneficial
3. Creation procedure
4. Impact on authentication path
5. Validation that shortcut is being used
6. Maintenance considerations
7. Potential issues to watch for
```

---

## Section 4: Trust Security

### Prompt 4.1: Selective Authentication Configuration

```
I need to configure or troubleshoot selective authentication on a trust.

TRUST: [Domain A] <-> [Domain B]
CURRENT STATUS: [Selective auth enabled/disabled]

REQUIREMENT:
[Describe who should access what resources]

ISSUE (if troubleshooting):
[Describe - users can't access, users can access too much]

Please provide:
1. How selective authentication works
2. Enabling/disabling selective authentication
3. "Allowed to Authenticate" permission configuration
4. Resource-side permission requirements
5. Testing selective authentication
6. Troubleshooting access issues with selective auth
7. Best practices for selective authentication
```

### Prompt 4.2: SID Filtering and SID History

```
I need to understand or troubleshoot SID filtering on a trust.

TRUST: [Domain A] <-> [Domain B]
CURRENT SID FILTERING: [Enabled/Disabled/Quarantine status]

ISSUE:
[Describe - SID history not working, access denied, etc.]

MIGRATION SCENARIO: [Yes/No - describe if yes]

Please provide:
1. What SID filtering does and why it exists
2. SID filtering vs. SID history explained
3. When to disable SID filtering (and risks)
4. quarantine mode explained
5. Enabling SID history across trust
6. Security implications
7. Verification after changes
8. Best practices post-migration
```

### Prompt 4.3: Trust Security Audit

```
I need to perform a security audit of all trust relationships.

ENVIRONMENT:
- Trusts to audit: [List or "all"]
- Compliance requirements: [If any]
- Security concerns: [Describe]

Please provide:
1. Trust security audit checklist
2. Identifying risky trust configurations
3. Selective authentication assessment
4. SID filtering status review
5. Trust account password age
6. Network exposure assessment
7. Recommendations for improving trust security
8. Ongoing monitoring recommendations
```

---

## Section 5: Cross-Forest Authentication

### Prompt 5.1: Cross-Forest Authentication Failures

```
Authentication across a forest trust is failing.

LOCAL FOREST: [Name]
TRUSTED FOREST: [Name]
AFFECTED USERS: [Users from which forest]
TARGET RESOURCES: [Resources in which forest]

ERROR MESSAGES:
[Paste authentication errors]

Please provide:
1. Cross-forest authentication flow explained
2. Diagnosing where authentication fails
3. GC availability verification
4. Name suffix routing verification
5. Kerberos forest trust referral troubleshooting
6. NTLM fallback across forest trust
7. Resolution steps
8. Testing authentication after fix
```

### Prompt 5.2: Name Suffix Routing Issues

```
I'm having name suffix routing issues with a forest trust.

FOREST TRUST: [Forest A] <-> [Forest B]

NAME SUFFIXES:
- Forest A suffixes: [List UPN suffixes]
- Forest B suffixes: [List UPN suffixes]

ISSUE:
[Describe - routing disabled, conflicts, authentication to wrong forest]

Please provide:
1. Name suffix routing explained
2. How to view current routing status
3. Enabling/disabling routing for specific suffixes
4. Handling UPN suffix conflicts
5. Impact on authentication
6. Verification steps
7. Best practices for name suffix management
```

---

## Section 6: Realm Trusts (MIT Kerberos)

### Prompt 6.1: Realm Trust Configuration

```
I need to configure a realm trust with a non-Windows Kerberos realm.

AD DOMAIN: [Name]
KERBEROS REALM: [Name, e.g., UNIX.COMPANY.COM]
REALM PLATFORM: [Linux/UNIX/MIT Kerberos/etc.]

PURPOSE:
[Describe what access is needed]

Please provide:
1. Realm trust prerequisites
2. Kerberos realm requirements
3. Trust creation procedure (AD side)
4. Kerberos realm configuration (non-AD side)
5. Principal mapping requirements
6. Testing cross-realm authentication
7. Common issues and resolutions
8. Security considerations
```

### Prompt 6.2: Realm Trust Troubleshooting

```
A realm trust is not working correctly.

AD DOMAIN: [Name]
KERBEROS REALM: [Name]

SYMPTOMS:
[Describe - authentication failures, specific errors]

KERBEROS ERRORS:
[Paste any Kerberos error messages]

Please provide:
1. Diagnosing realm trust issues
2. KDC communication verification
3. Principal name format issues
4. Encryption type mismatches
5. Clock skew verification
6. Trust password verification
7. Packet capture analysis guidance
8. Resolution steps
```

---

## Section 7: Trust Maintenance

### Prompt 7.1: Trust Password Reset

```
I need to reset the trust password between domains.

TRUST: [Domain A] <-> [Domain B]
REASON: [Routine, suspected compromise, trust failure]

ACCESS AVAILABLE:
- Admin in Domain A: [Yes/No]
- Admin in Domain B: [Yes/No]

Please provide:
1. Trust password explained
2. When trust password reset is needed
3. Reset procedure (both sides accessible)
4. Reset procedure (one side only)
5. Reset with netdom
6. Verification after reset
7. Impact during reset process
8. Best practices for trust password management
```

### Prompt 7.2: Trust Removal

```
I need to remove an existing trust relationship.

TRUST TO REMOVE: [Domain A] <-> [Domain B]
REASON: [Describe - decommissioning, consolidation, security]
IMPACT ASSESSMENT: [What will break]

Please provide:
1. Pre-removal impact assessment
2. User and application notification requirements
3. Trust removal procedure (both sides)
4. One-sided removal implications
5. Cleanup after removal
6. Verification trust is fully removed
7. Handling orphaned foreign security principals
8. Documentation requirements
```

---

## Section 8: Performance and Optimization

### Prompt 8.1: Trust Performance Issues

```
Cross-trust authentication is slow.

TRUST: [Domain A] <-> [Domain B]
SYMPTOMS:
- Login delay: [X seconds]
- Resource access delay: [X seconds]
- Specific users or all: [Describe]

NETWORK PATH:
[Describe - WAN link, latency, bandwidth]

Please provide:
1. Cross-trust authentication path analysis
2. Identifying performance bottlenecks
3. DC selection and site topology review
4. Shortcut trust consideration
5. GC placement for forest trusts
6. Caching and ticket lifetime optimization
7. Network optimization recommendations
8. Measurement and baseline procedures
```

---

## Section 9: Scripts and Automation

### Prompt 9.1: Trust Monitoring Script

```
Create a PowerShell script that monitors trust health:

REQUIREMENTS:
1. Enumerate all trusts
2. Validate each trust
3. Check trust password age
4. Verify DNS resolution for trusted domains
5. Test authentication to trusted domain
6. Generate health report
7. Send alerts for failures
8. Log results for trending

Include error handling and scheduling guidance.
```

### Prompt 9.2: Trust Documentation Script

```
Create a PowerShell script that documents all trusts:

REQUIREMENTS:
1. List all trusts with properties
2. Trust type and direction
3. Selective authentication status
4. SID filtering status
5. Name suffix routing (for forest trusts)
6. Trust creation date
7. Export to CSV/HTML
8. Support for multiple forests

Include comments and documentation.
```

---

## Quick Reference: Trust Commands

```powershell
# === TRUST ENUMERATION ===

# List all trusts
Get-ADTrust -Filter *

# List trusts for specific domain
Get-ADTrust -Filter * -Server domain.com

# Using netdom
netdom trust domain.com /d:trusteddomain.com /verify

# === TRUST VALIDATION ===

# Verify trust
netdom trust domain.com /d:trusteddomain.com /verify

# Full trust validation
nltest /sc_verify:trusteddomain.com

# Query trust status
nltest /domain_trusts

# Trust password test
nltest /sc_query:trusteddomain.com

# === TRUST CREATION ===

# Create forest trust (PowerShell)
New-ADForestTrust -TargetForest "otherforest.com" -TrustType Forest -TrustDirection Bidirectional

# Create external trust
New-ADExternalTrust -TargetDomain "external.com" -TrustDirection Bidirectional

# Using netdom
netdom trust domain.com /d:trusteddomain.com /add /twoway

# === TRUST MANAGEMENT ===

# Reset trust password
netdom trust domain.com /d:trusteddomain.com /reset /passwordt:newpassword

# Remove trust
Remove-ADTrust -Identity "trusteddomain.com"

# Using netdom
netdom trust domain.com /d:trusteddomain.com /remove

# === SELECTIVE AUTHENTICATION ===

# Check selective auth status
Get-ADTrust -Identity "trusteddomain.com" | Select-Object SelectiveAuthentication

# Enable selective authentication
Set-ADTrust -Identity "trusteddomain.com" -SelectiveAuthentication $true

# === SID FILTERING ===

# Check SID filtering
netdom trust domain.com /d:trusteddomain.com /quarantine

# Disable SID filtering (use with caution!)
netdom trust domain.com /d:trusteddomain.com /quarantine:no

# === NAME SUFFIX ROUTING ===

# View name suffix routing
netdom trust domain.com /d:trustedforest.com /namesuffixes

# Enable routing for suffix
netdom trust domain.com /d:trustedforest.com /enablesidhistory:yes

# === FOREST TRUST INFO ===

# Get forest trust information
Get-ADForest -Identity "otherforest.com" | Select-Object Name, RootDomain, Domains

# Verify GC availability in trusted forest
nltest /dsgetdc:trustedforest.com /gc
```

---

## Trust Types Reference

| Type | Scope | Transitivity | Use Case |
|------|-------|--------------|----------|
| Forest | Forest | Transitive | Full cross-forest access |
| External | Domain | Non-transitive | Single domain access, legacy |
| Shortcut | Domain | Transitive (within forest) | Authentication optimization |
| Realm | Domain | Non-transitive (typically) | MIT Kerberos realms |
| Parent-Child | Domain | Transitive | Automatic within forest |
| Tree-Root | Domain | Transitive | Automatic within forest |

---

## Trust Ports Reference

| Port | Protocol | Purpose |
|------|----------|---------|
| 53 | TCP/UDP | DNS |
| 88 | TCP/UDP | Kerberos |
| 135 | TCP | RPC Endpoint Mapper |
| 389 | TCP/UDP | LDAP |
| 445 | TCP | SMB |
| 464 | TCP/UDP | Kerberos password change |
| 636 | TCP | LDAPS |
| 3268 | TCP | Global Catalog |
| 3269 | TCP | Global Catalog SSL |
| Dynamic | TCP | RPC (49152-65535) |

---

## Related Modules

- [Authentication & Kerberos](02-Authentication-Kerberos.md) - Cross-trust authentication
- [DNS Integration](03-DNS-Integration.md) - DNS for trusted domains
- [Security & Incident Response](10-Security-Incident-Response.md) - Trust security

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
