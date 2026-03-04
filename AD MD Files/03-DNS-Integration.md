# Active Directory DNS Integration Troubleshooting

## AI Prompts for Diagnosing and Resolving AD-Integrated DNS Issues

---

## Overview

DNS is the foundation of Active Directory. Without proper DNS configuration, AD authentication, replication, Group Policy, and virtually every AD-dependent service will fail. This module provides comprehensive AI prompts for diagnosing and resolving DNS issues in AD environments.

---

## Section 1: DNS Health Assessment

### Prompt 1.1: Comprehensive DNS Health Check

```
I need to assess the overall DNS health of my Active Directory environment.

ENVIRONMENT:
- Number of DNS servers: [X]
- DNS zones: [List zones - AD-integrated and standard]
- AD-integrated DNS: [Yes/No]
- DNS replication scope: [Forest-wide, domain-wide, custom]
- External DNS forwarding: [Describe configuration]

SYMPTOMS (if any):
[Describe any DNS-related issues observed]

Please provide:
1. Comprehensive DNS diagnostic commands to run
2. Critical DNS records that must exist for AD to function
3. How to verify DNS server health on each DC
4. Zone configuration validation checklist
5. Forwarder and root hints verification
6. DNS-to-AD integration health checks
7. Prioritized action items based on findings
```

### Prompt 1.2: DC DNS Registration Verification

```
I need to verify that all domain controllers have properly registered their DNS records.

DOMAIN: [domain.com]
DOMAIN CONTROLLERS: [List DC names]

Please provide:
1. Commands to check if all required DC DNS records exist
2. List of critical SRV records that must exist for each DC
3. How to verify _msdcs zone records
4. Commands to force DNS registration from a DC
5. How to identify which DC has registration problems
6. Troubleshooting when records are missing or incorrect
7. Automation script to monitor DNS registration
```

---

## Section 2: SRV Record Issues

### Prompt 2.1: Missing or Incorrect SRV Records

```
Domain clients cannot locate domain controllers - suspected SRV record issue.

SYMPTOMS:
- Error messages: [e.g., "Domain controller not found"]
- Affected clients: [Scope of impact]
- nltest /dsgetdc output: [Paste output if available]

DNS SERVER: [Server name]
DOMAIN: [domain.com]

Please provide:
1. Complete list of required AD SRV records and their purposes
2. Commands to query and verify each SRV record type
3. How to diagnose which specific records are missing
4. Manual SRV record creation procedure (emergency)
5. Root cause analysis for missing SRV records
6. Forcing NETLOGON to re-register records
7. Verification that clients can now locate DCs
```

### Prompt 2.2: SRV Record Deep Dive

```
Explain and help me troubleshoot the following AD SRV record type:

RECORD TYPE: [e.g., _ldap._tcp.dc._msdcs.domain.com]

CURRENT ISSUE:
[Describe - missing, incorrect, multiple entries, etc.]

Please provide:
1. Detailed explanation of this record's purpose
2. What AD component registers this record
3. What breaks when this record is missing/incorrect
4. How to query this specific record
5. Correct format and expected values
6. How to fix if incorrect
7. How to prevent future issues
```

---

## Section 3: DNS Zone Issues

### Prompt 3.1: AD-Integrated DNS Zone Problems

```
I'm experiencing issues with AD-integrated DNS zones.

ZONE NAME: [Zone name]
ZONE TYPE: [Primary/AD-integrated]
REPLICATION SCOPE: [Forest/Domain/Custom]

SYMPTOMS:
[Describe - zone not loading, replication issues, stale records]

EVENT LOG ERRORS:
[Paste relevant DNS Server event log entries]

Please provide:
1. Diagnostics for AD-integrated zone health
2. How zones replicate in AD and common failure points
3. Checking zone data in Active Directory
4. Resolving zone loading failures
5. Zone replication troubleshooting
6. Restoring zone from AD if needed
7. Best practices for zone configuration
```

### Prompt 3.2: DNS Zone Transfer Issues

```
DNS zone transfers are failing between servers.

SOURCE DNS SERVER: [Name]
DESTINATION DNS SERVER: [Name]
ZONE: [Zone name]
ZONE TYPE: [Standard Primary/Secondary or AD-integrated]

ERROR:
[Paste error message]

Please provide:
1. Zone transfer prerequisites and requirements
2. Diagnosing zone transfer failures
3. Security settings that affect zone transfers
4. Network and firewall requirements (TCP 53)
5. Forcing zone transfer and verification
6. When to use AD-integrated instead of standard zones
7. Monitoring zone transfer health
```

---

## Section 4: DNS Scavenging

### Prompt 4.1: DNS Scavenging Configuration and Issues

```
I need help with DNS scavenging configuration.

CURRENT SITUATION:
- Scavenging enabled: [Yes/No/Partial]
- Stale records observed: [Yes/No, describe]
- Records being deleted unexpectedly: [Yes/No, describe]

CURRENT SETTINGS (if known):
- No-refresh interval: [Value]
- Refresh interval: [Value]
- Scavenging period: [Value]

Please provide:
1. How DNS scavenging works in AD-integrated DNS
2. Recommended scavenging intervals and why
3. How to enable scavenging safely
4. Preventing important records from being scavenged
5. Identifying and recovering incorrectly scavenged records
6. Troubleshooting records that won't scavenge
7. Best practices for scavenging configuration
```

### Prompt 4.2: DNS Scavenging Emergency

```
EMERGENCY: Critical DNS records appear to have been scavenged.

MISSING RECORDS:
[List critical records that are missing]

IMPACT:
[Describe what's broken]

TIME DISCOVERED: [When]
LAST KNOWN GOOD: [When records were last confirmed present]

Please provide:
1. Immediate steps to restore critical functionality
2. How to recover scavenged records (if possible)
3. Identifying what triggered aggressive scavenging
4. Preventing recurrence
5. Verifying all critical AD records are restored
6. Audit trail to understand what happened
```

---

## Section 5: DNS Client Issues

### Prompt 5.1: Client DNS Resolution Failures

```
Clients are experiencing DNS resolution failures.

AFFECTED CLIENTS:
- Scope: [Single client, subnet, site, all]
- Client OS: [Windows version]
- Client DNS settings: [How configured - DHCP, static, GPO]

SYMPTOMS:
[Describe - cannot resolve domain, specific hosts, etc.]

NSLOOKUP OUTPUT:
[Paste relevant nslookup tests]

IPCONFIG /ALL OUTPUT (sample client):
[Paste output]

Please provide:
1. Client-side DNS troubleshooting steps
2. Verifying client DNS server configuration
3. Testing resolution path and identifying failure point
4. DNS cache issues and how to clear
5. HOSTS file interference check
6. Name resolution order troubleshooting
7. Network-level DNS issues (firewall, routing)
```

### Prompt 5.2: DNS Suffix and Search Order Issues

```
Clients have issues with DNS suffix configuration.

SYMPTOMS:
[Describe - short names not resolving, wrong domain being appended]

CURRENT SUFFIX CONFIGURATION:
- Primary DNS suffix: [Value]
- Connection-specific suffixes: [Values]
- DNS suffix search list: [Values]

GPO SETTINGS (if applicable):
[Describe DNS-related GPO settings]

Please provide:
1. How DNS suffix search works in Windows
2. Diagnosing suffix-related resolution failures
3. GPO settings for DNS suffix configuration
4. DHCP options for DNS suffixes
5. Troubleshooting devolution issues
6. Best practices for multi-domain environments
7. Testing and verification steps
```

---

## Section 6: Conditional Forwarding and Forwarders

### Prompt 6.1: Conditional Forwarder Troubleshooting

```
Conditional forwarding is not working as expected.

CONDITIONAL FORWARDER CONFIGURATION:
- DNS domain: [Target domain]
- Forwarder IP(s): [Target DNS server IPs]
- Configured on: [Which DNS servers]
- Stored in AD: [Yes/No]

SYMPTOMS:
[Describe - queries not forwarding, wrong response, timeout]

Please provide:
1. How to verify conditional forwarder configuration
2. Testing conditional forwarder resolution
3. Common failure causes and resolutions
4. Network requirements (ports, firewall)
5. AD-stored vs. server-specific forwarders
6. Troubleshooting conditional forwarder replication
7. Alternative approaches if conditional forwarding is problematic
```

### Prompt 6.2: Root Hints vs. Forwarders

```
I need guidance on DNS forwarder vs. root hints configuration.

CURRENT CONFIGURATION:
- Forwarders configured: [Yes/No, list if yes]
- Root hints: [Default/Modified/Removed]
- Recursive queries: [Enabled/Disabled]

REQUIREMENTS:
- Internet resolution needed: [Yes/No]
- Security restrictions: [Describe any]
- Split DNS: [Yes/No, describe]

Please provide:
1. When to use forwarders vs. root hints
2. Security implications of each approach
3. Recommended configuration for AD environments
4. How to properly configure forwarders
5. Managing root hints updates
6. Testing external name resolution
7. Best practices for enterprise DNS
```

---

## Section 7: DNS and AD Replication

### Prompt 7.1: DNS Causing AD Replication Issues

```
I suspect DNS issues are causing AD replication failures.

REPLICATION ERRORS:
[Paste replication error codes/messages]

DNS CONFIGURATION:
- DNS servers on DCs: [List]
- Zone type: [AD-integrated/Standard]
- DCs can resolve each other: [Yes/No/Intermittent]

NSLOOKUP TESTS (DC to DC):
[Paste results of cross-DC resolution tests]

Please provide:
1. How DNS affects AD replication
2. Diagnosing DNS-related replication failures
3. Verifying DCs can resolve each other
4. _msdcs zone health verification
5. DNS round-robin considerations
6. Fixing DNS to restore replication
7. Verification steps after DNS fixes
```

### Prompt 7.2: DNS Zone Replication vs. AD Replication

```
I'm confused about how DNS zone replication relates to AD replication.

CURRENT SITUATION:
[Describe what you're observing - inconsistent DNS data, etc.]

QUESTIONS:
- How does AD-integrated DNS replicate?
- Why would DNS records be different on different DCs?
- How do I verify DNS replication is working?

Please provide:
1. Detailed explanation of AD-integrated DNS replication
2. Difference between DNS zone transfer and AD replication
3. Replication scopes and their implications
4. Diagnosing DNS record inconsistencies
5. Tools to verify DNS data consistency
6. Forcing DNS replication through AD
7. Best practices for DNS replication scope
```

---

## Section 8: DNS Security

### Prompt 8.1: DNS Security Configuration

```
I want to review and improve DNS security in my AD environment.

CURRENT SECURITY MEASURES:
- Secure dynamic updates: [Enabled/Disabled]
- DNS zones secured: [Describe]
- DNSSEC: [Implemented/Planned/Not used]
- DNS socket pool: [Configured/Default]

CONCERNS:
[Describe any security concerns or requirements]

Please provide:
1. DNS security best practices for AD
2. Configuring secure dynamic updates properly
3. Zone security and ACLs
4. Cache poisoning protection
5. DNS socket pool configuration
6. DNSSEC implementation considerations
7. Auditing DNS for security issues
```

### Prompt 8.2: Secure Dynamic Update Issues

```
Secure dynamic updates are not working correctly.

SYMPTOMS:
[Describe - updates failing, wrong account registering, etc.]

CONFIGURATION:
- Zone set to: [Secure updates only/Non-secure and secure]
- DHCP-DNS integration: [Describe]
- Aging and scavenging: [Enabled/Disabled]

EVENT LOG ERRORS:
[Paste relevant errors]

Please provide:
1. How secure dynamic updates work in AD
2. Diagnosing secure update failures
3. Account permissions required for registration
4. DHCP server DNS registration settings
5. Cleaning up records registered by wrong accounts
6. DNSUpdateProxy group usage and implications
7. Best practices for dynamic update configuration
```

---

## Section 9: Troubleshooting Tools and Scripts

### Prompt 9.1: DNS Diagnostic Script

```
Create a comprehensive PowerShell script for AD DNS diagnostics that:

1. Verifies DNS service status on all DCs
2. Checks all required AD SRV records exist
3. Tests cross-DC name resolution
4. Validates zone configuration and health
5. Checks scavenging settings
6. Verifies forwarder connectivity
7. Tests external name resolution
8. Generates HTML report with findings
9. Highlights critical issues requiring immediate attention

Include error handling and support for multi-domain forests.
```

### Prompt 9.2: DNS Record Audit

```
I need to audit DNS records in my AD environment.

REQUIREMENTS:
1. Find stale A records (no corresponding AD computer object)
2. Find duplicate A records with different IPs
3. Identify PTR record inconsistencies
4. List all static records
5. Verify SRV record consistency across DNS servers
6. Export comprehensive DNS inventory

Please provide:
1. PowerShell commands for each audit requirement
2. Complete audit script with report generation
3. How to interpret the results
4. Remediation procedures for common issues
5. Regular audit schedule recommendations
```

---

## Quick Reference: DNS Commands

```powershell
# === DNS DIAGNOSTICS ===

# Test DNS on all DCs
dcdiag /test:dns /v /e

# Test DNS registration
dcdiag /test:RegisterInDNS /DnsDomain:domain.com /v

# Query specific SRV records
nslookup -type=srv _ldap._tcp.dc._msdcs.domain.com
nslookup -type=srv _kerberos._tcp.dc._msdcs.domain.com
nslookup -type=srv _gc._tcp.forest.com

# Test DNS server
nslookup server.domain.com DNSServerIP

# Clear DNS client cache
Clear-DnsClientCache
ipconfig /flushdns

# Display DNS client cache
Get-DnsClientCache
ipconfig /displaydns

# === DNS SERVER MANAGEMENT ===

# Check DNS server status
Get-DnsServer

# View zone information
Get-DnsServerZone
Get-DnsServerZone -Name "domain.com" | Format-List *

# Check zone aging settings
Get-DnsServerZoneAging -Name "domain.com"

# Force DNS registration (run on DC)
ipconfig /registerdns
nltest /dsregdns

# Restart NETLOGON to re-register records
Restart-Service NETLOGON

# === RECORD QUERIES ===

# Get all records in zone
Get-DnsServerResourceRecord -ZoneName "domain.com"

# Find specific record
Get-DnsServerResourceRecord -ZoneName "domain.com" -Name "servername"

# Query _msdcs zone
Get-DnsServerResourceRecord -ZoneName "_msdcs.domain.com"

# === SCAVENGING ===

# Check scavenging settings
Get-DnsServerScavenging

# Enable scavenging
Set-DnsServerScavenging -ScavengingState $true -RefreshInterval 7.00:00:00 -NoRefreshInterval 7.00:00:00

# Start scavenging manually
Start-DnsServerScavenging -Force

# === FORWARDERS ===

# View forwarders
Get-DnsServerForwarder

# View conditional forwarders
Get-DnsServerZone | Where-Object {$_.ZoneType -eq 'Forwarder'}

# Add forwarder
Add-DnsServerForwarder -IPAddress 8.8.8.8

# Test forwarder resolution
Resolve-DnsName external.com -Server DNSServerIP
```

---

## Critical SRV Records Reference

| Record | Purpose | Location |
|--------|---------|----------|
| _ldap._tcp.dc._msdcs.domain.com | DC locator | _msdcs zone |
| _kerberos._tcp.dc._msdcs.domain.com | Kerberos KDC | _msdcs zone |
| _ldap._tcp.sitename._sites.dc._msdcs.domain.com | Site-specific DC | _msdcs zone |
| _gc._tcp.forest.com | Global Catalog | Forest zone |
| _ldap._tcp.pdc._msdcs.domain.com | PDC locator | _msdcs zone |
| _kpasswd._tcp.domain.com | Password change | Domain zone |

---

## Related Modules

- [Replication Issues](01-Replication-Issues.md) - DNS issues cause replication failures
- [Authentication & Kerberos](02-Authentication-Kerberos.md) - Kerberos needs DNS for SPN resolution
- [Domain Controller Health](06-Domain-Controller-Health.md) - DNS is a core DC service

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
