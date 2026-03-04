# Domain Controller Health Troubleshooting

## AI Prompts for Diagnosing and Maintaining DC Health

---

## Overview

Domain Controllers are the backbone of Active Directory infrastructure. Their health directly impacts authentication, policy application, and overall AD functionality. This module provides comprehensive AI prompts for systematic DC health assessment and troubleshooting.

---

## Section 1: Comprehensive DC Health Assessment

### Prompt 1.1: Full DC Health Check

```
I need to perform a comprehensive health check on a domain controller.

DC DETAILS:
- DC Name: [Name]
- Operating System: [Windows Server version]
- Roles: [FSMO roles if any, GC, DNS, DHCP, etc.]
- Virtual/Physical: [VM platform if virtual]
- Site: [AD site name]

REASON FOR CHECK:
[Routine, suspected issue, pre-maintenance, post-incident]

Please provide:
1. Complete dcdiag test suite with interpretation guide
2. Essential services to verify
3. Performance baseline metrics to collect
4. Event log entries to review
5. Replication health verification
6. DNS and network connectivity checks
7. Priority ranking of any issues found
```

### Prompt 1.2: Enterprise-Wide DC Health Assessment

```
I need to assess health across all domain controllers in my environment.

ENVIRONMENT:
- Total DCs: [X]
- Domains: [X]
- Sites: [X]
- Operating systems in use: [List versions]

Please provide:
1. Commands to assess all DCs simultaneously
2. How to collect and consolidate results
3. Key health indicators to compare across DCs
4. Identifying outliers or problem DCs
5. Prioritization framework for remediation
6. Automation script for regular health checks
7. Dashboard/reporting recommendations
```

---

## Section 2: DCDIAG Deep Dive

### Prompt 2.1: DCDIAG Test Interpretation

```
Help me interpret these DCDIAG results.

DCDIAG OUTPUT:
[Paste full dcdiag output]

Please analyze and provide:
1. Explanation of each failed or warning test
2. Root cause analysis for failures
3. Priority ranking of issues (critical to low)
4. Step-by-step resolution for each issue
5. Tests to re-run after fixes
6. Any cascading issues (one failure causing others)
7. Overall DC health assessment
```

### Prompt 2.2: Specific DCDIAG Test Failures

```
I'm getting a specific DCDIAG test failure.

FAILED TEST: [Test name, e.g., Advertising, DFSREvent, KccEvent, etc.]
ERROR MESSAGE: [Full error text]
DC: [DC name]

RELATED SYMPTOMS:
[Describe any observed issues]

Please provide:
1. Detailed explanation of what this test verifies
2. Common causes for this specific failure
3. Diagnostic steps to isolate the cause
4. Resolution procedure
5. Verification steps after fix
6. Preventive measures
7. Related tests to check
```

---

## Section 3: Critical DC Services

### Prompt 3.1: NETLOGON Service Issues

```
I'm experiencing NETLOGON service issues.

DC: [Name]
SERVICE STATUS: [Running/Stopped/Starting/Failing]
ERROR MESSAGES: [Paste any errors]

SYMPTOMS:
[Describe - authentication failures, secure channel issues, etc.]

RELEVANT EVENT LOG ENTRIES:
[Paste NETLOGON and System events]

Please provide:
1. NETLOGON service function and dependencies
2. Diagnosing NETLOGON failures
3. Common causes and resolutions
4. Checking Netlogon.log for issues
5. Service recovery procedures
6. Impact on domain operations
7. Verification after repair
```

### Prompt 3.2: NTDS (AD DS) Service Issues

```
The NTDS (Active Directory Domain Services) service is having problems.

DC: [Name]
SERVICE STATUS: [Status]
ERROR MESSAGES: [Paste errors]

SYMPTOMS:
[Describe - DC not advertising, LDAP issues, etc.]

EVENT LOG (Directory Service):
[Paste relevant events]

Please provide:
1. NTDS service function and dependencies
2. Diagnosing NTDS service failures
3. Database integrity concerns
4. Safe recovery procedures
5. When to attempt database recovery
6. Implications of extended NTDS downtime
7. Escalation criteria
```

### Prompt 3.3: KDC Service Issues

```
The KDC (Key Distribution Center) service is having issues.

DC: [Name]
SERVICE STATUS: [Status]
KERBEROS ERRORS: [Any Kerberos event IDs]

AUTHENTICATION IMPACT:
[Describe authentication issues observed]

Please provide:
1. KDC service function
2. Diagnosing KDC failures
3. Certificate requirements for KDC
4. Common KDC issues and resolutions
5. Impact on domain authentication
6. Forcing Kerberos clients to use other DCs
7. Verification after repair
```

---

## Section 4: Time Synchronization

### Prompt 4.1: DC Time Sync Configuration

```
I need to configure proper time synchronization for my DCs.

ENVIRONMENT:
- PDC Emulator: [DC name]
- Number of DCs: [X]
- External time source: [Available/Not available]
- Virtualized DCs: [Yes/No]

CURRENT ISSUES (if any):
[Describe time-related problems]

Please provide:
1. Proper time hierarchy for AD
2. PDC Emulator time source configuration
3. Other DC time configuration
4. Virtualized DC special considerations
5. Commands to verify time sync status
6. Troubleshooting time drift
7. Monitoring recommendations
```

### Prompt 4.2: Time Sync Troubleshooting

```
I'm experiencing time synchronization issues on a DC.

DC: [Name]
IS PDC EMULATOR: [Yes/No]
CURRENT TIME OFFSET: [Offset from expected]
W32TM STATUS OUTPUT:
[Paste w32tm /query /status output]

SYMPTOMS:
[Describe - Kerberos errors, time skew events, etc.]

Please provide:
1. Diagnosing time sync failure root cause
2. Checking time source chain
3. Forcing time resync
4. Resetting W32Time service
5. Virtual machine time sync considerations
6. Verification steps
7. Preventing future drift
```

---

## Section 5: DC Promotion and Demotion Issues

### Prompt 5.1: DC Promotion Failures

```
DC promotion (dcpromo/Install-ADDSDomainController) is failing.

TARGET SERVER: [Name]
DOMAIN: [Name]
PROMOTION METHOD: [GUI/PowerShell/Answer file]
ERROR MESSAGE: [Full error text]

ATTEMPTED CONFIGURATION:
[Describe - new DC, additional DC, new domain, etc.]

Please provide:
1. Prerequisites verification checklist
2. Common promotion failure causes
3. DNS requirements validation
4. Network connectivity checks
5. Credential and permission verification
6. Log files to examine
7. Resolution based on specific error
```

### Prompt 5.2: DC Demotion Failures

```
DC demotion is failing.

DC TO DEMOTE: [Name]
DEMOTION METHOD: [GUI/PowerShell/Forced]
ERROR MESSAGE: [Full error text]
FSMO ROLES HELD: [Yes/No - which if yes]
LAST DC IN DOMAIN: [Yes/No]

Please provide:
1. Prerequisites for successful demotion
2. Common demotion failure causes
3. FSMO role considerations
4. Forced demotion procedure and implications
5. Metadata cleanup after forced demotion
6. DNS cleanup steps
7. Verification after demotion
```

### Prompt 5.3: Forced DC Removal

```
I need to forcibly remove a DC from Active Directory.

DC TO REMOVE: [Name]
REASON: [Crashed, unreachable, corrupted, etc.]
DC RECOVERY POSSIBLE: [Yes/No]
ROLES HELD: [List FSMO roles, GC, etc.]

Please provide:
1. When forced removal is appropriate
2. Pre-removal documentation requirements
3. FSMO role seizure if needed
4. Metadata cleanup procedure (ntdsutil)
5. DNS record cleanup
6. SYSVOL cleanup
7. Preventing the removed DC from rejoining
8. Complete validation checklist
```

---

## Section 6: Secure Channel Issues

### Prompt 6.1: DC Secure Channel Problems

```
A domain controller has secure channel issues with other DCs.

AFFECTED DC: [Name]
SYMPTOMS:
- Replication errors: [Describe]
- Trust errors: [Describe]
- Event log errors: [Paste relevant events]

NLTEST OUTPUT:
[Paste nltest /sc_verify:domain output]

Please provide:
1. DC-to-DC secure channel explained
2. Diagnosing secure channel failures
3. Common causes for DC secure channel issues
4. Repair procedures
5. When to reset DC computer account
6. Verification after repair
7. Preventing future issues
```

### Prompt 6.2: Reset DC Machine Account Password

```
I may need to reset a DC's machine account password.

DC: [Name]
REASON: [Describe why this is being considered]
CURRENT SYMPTOMS: [Describe]

Please provide:
1. When resetting DC machine account is appropriate
2. Risks and implications
3. Procedure for DC password reset
4. netdom resetpwd usage
5. Verification after reset
6. Alternative approaches to try first
7. Recovery if reset causes issues
```

---

## Section 7: DC Performance Issues

### Prompt 7.1: DC Performance Troubleshooting

```
A domain controller is experiencing performance issues.

DC: [Name]
SYMPTOMS:
- High CPU: [Yes/No, process if known]
- High memory: [Yes/No]
- Slow LDAP queries: [Yes/No]
- Slow authentication: [Yes/No]
- Disk performance: [Status]

CURRENT LOAD:
- Users/computers serviced: [Approximate number]
- Concurrent connections: [If known]

PERFORMANCE COUNTERS (if available):
[Paste relevant perfmon data]

Please provide:
1. Key performance metrics for DC health
2. Diagnosing CPU, memory, disk issues
3. LSASS high utilization troubleshooting
4. Identifying resource-intensive operations
5. Optimization recommendations
6. When to add additional DCs
7. Capacity planning considerations
```

### Prompt 7.2: LSASS Memory and CPU Issues

```
LSASS.exe is consuming excessive resources on a DC.

DC: [Name]
CPU USAGE: [Percentage]
MEMORY USAGE: [Amount]
DURATION: [How long has this been occurring]

SYMPTOMS:
[Describe authentication delays, etc.]

Please provide:
1. Normal LSASS resource usage expectations
2. Common causes for high LSASS usage
3. Diagnosing LSASS issues safely
4. Identifying problematic LDAP queries or authentications
5. Resolution approaches
6. When memory leak might be indicated
7. Safe LSASS troubleshooting (avoiding security tools interference)
```

---

## Section 8: DC Event Log Analysis

### Prompt 8.1: Critical DC Event Analysis

```
I need help analyzing critical events on a domain controller.

EVENT LOG ENTRIES:
[Paste relevant Directory Service, System, and Security events]

DC: [Name]
OBSERVED SYMPTOMS: [Describe]

Please provide:
1. Interpretation of each event
2. Correlation between events
3. Root cause identification
4. Priority ranking of issues
5. Resolution steps for each issue
6. Events to monitor going forward
7. Alert thresholds to configure
```

### Prompt 8.2: DC Event Monitoring Configuration

```
I want to configure effective event monitoring for my DCs.

MONITORING SYSTEM: [SCOM, Splunk, Custom, etc.]
ALERTING REQUIREMENTS: [Response time expectations]

Please provide:
1. Critical events to monitor (by Event ID and source)
2. Warning-level events worth tracking
3. Event correlation rules
4. Recommended alert thresholds
5. Sample queries/filters for each monitoring system
6. False positive reduction strategies
7. Escalation procedures for different event types
```

---

## Section 9: DC Recovery Scenarios

### Prompt 9.1: DC Not Booting

```
EMERGENCY: A domain controller is not booting.

DC: [Name]
ROLES: [FSMO, GC, etc.]
BOOT SYMPTOMS: [Describe - BSOD, boot loop, stops at stage X]
ERROR CODES: [If visible]
PHYSICAL/VIRTUAL: [Platform]
RECENT CHANGES: [Updates, hardware, etc.]

Please provide:
1. Initial diagnostic steps
2. Safe mode boot attempt procedure
3. AD-specific boot issues
4. When to attempt repair vs. restore from backup
5. Seizing FSMO roles if needed
6. Rebuilding DC if necessary
7. Immediate mitigation for AD services
```

### Prompt 9.2: DC Database Corruption Suspected

```
I suspect AD database corruption on a DC.

DC: [Name]
SYMPTOMS:
[Describe - events, errors, data inconsistencies]

RELEVANT EVENTS:
[Paste Directory Service events mentioning database or NTDS]

Please provide:
1. Indicators of AD database corruption
2. Diagnostic commands (esentutl, ntdsutil)
3. Database integrity verification
4. Semantic database analysis
5. Repair options and implications
6. When to restore from backup vs. repair
7. Preventing promotion of corrupted DC data
```

---

## Section 10: Virtualized DC Considerations

### Prompt 10.1: Virtual DC Best Practices

```
I need guidance on virtual domain controller configuration.

VIRTUALIZATION PLATFORM: [VMware, Hyper-V, etc.]
CURRENT VIRTUAL DCS: [Number and names]
CONCERNS: [Performance, snapshots, cloning, etc.]

Please provide:
1. Virtual DC best practices
2. VM-Generation ID importance and verification
3. Time sync configuration for virtual DCs
4. Storage recommendations
5. Snapshot policies and risks
6. Clone and DR considerations
7. Resource allocation recommendations
8. Migration and vMotion considerations
```

### Prompt 10.2: Virtual DC Snapshot Recovery

```
A virtual DC may have been restored from a snapshot.

DC: [Name]
SNAPSHOT DATE: [If known]
CURRENT DATE: [Date]
SYMPTOMS: [Describe - USN rollback events, replication issues, auth problems]

Please provide:
1. How to determine if snapshot restore occurred
2. USN rollback implications
3. VM-Generation ID protection explanation
4. Recovery procedures if USN rollback occurred
5. Preventing future snapshot issues
6. Educating VM admins on AD snapshot risks
7. Monitoring for snapshot restore detection
```

---

## Quick Reference: DC Health Commands

```powershell
# === COMPREHENSIVE HEALTH ===

# Full DCDIAG
dcdiag /v /c /d /e /s:DCName

# Quick DCDIAG
dcdiag /q /s:DCName

# DNS-specific DCDIAG
dcdiag /test:dns /v /s:DCName

# All DCs in enterprise
dcdiag /v /e

# === SERVICE STATUS ===

# Check critical AD services
Get-Service NTDS, Netlogon, KDC, DNS, DFSR -ComputerName DCName

# Start stopped service
Start-Service ServiceName -ComputerName DCName

# Check service dependencies
Get-Service NTDS -DependentServices

# === REPLICATION HEALTH ===

# Quick replication summary
repadmin /replsummary

# Replication status for DC
repadmin /showrepl DCName

# Queue status
repadmin /queue DCName

# === NETLOGON ===

# Enable Netlogon debug logging
nltest /dbflag:0x2080ffff

# Verify secure channel
nltest /sc_verify:domain.com

# Query DC
nltest /dsgetdc:domain.com

# === TIME SYNC ===

# Check time status
w32tm /query /status

# Check time source
w32tm /query /source

# Check peer status
w32tm /query /peers

# Force resync
w32tm /resync /force

# === PERFORMANCE ===

# Quick performance check
Get-Process lsass -ComputerName DCName | Select-Object CPU, WorkingSet64

# Active Directory performance counters
Get-Counter "\DirectoryServices(*)\*" -ComputerName DCName

# LDAP connection count
Get-Counter "\NTDS\LDAP Active Threads" -ComputerName DCName

# === EVENT LOGS ===

# Directory Service events (last 24 hours)
Get-WinEvent -FilterHashtable @{LogName='Directory Service';StartTime=(Get-Date).AddHours(-24)} -ComputerName DCName

# System events for AD services
Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='NETLOGON','NTDS'} -ComputerName DCName -MaxEvents 50

# === DATABASE ===

# Check database integrity (offline only!)
# esentutl /g "C:\Windows\NTDS\ntds.dit"

# Database file info
Get-ItemProperty "\\DCName\C$\Windows\NTDS\ntds.dit" | Select-Object Length, LastWriteTime
```

---

## Critical DC Services Reference

| Service | Display Name | Purpose | Impact if Down |
|---------|--------------|---------|----------------|
| NTDS | Active Directory Domain Services | Core AD | DC non-functional |
| Netlogon | Netlogon | Secure channel, DC locator | Auth failures |
| KDC | Kerberos Key Distribution Center | Kerberos auth | Kerberos failures |
| DNS | DNS Server | Name resolution | AD can't function |
| DFSR | DFS Replication | SYSVOL replication | GPO issues |
| W32Time | Windows Time | Time sync | Kerberos errors |

---

## Related Modules

- [FSMO Roles](05-FSMO-Roles.md) - FSMO role holder health
- [Replication Issues](01-Replication-Issues.md) - DC replication health
- [DNS Integration](03-DNS-Integration.md) - DNS service on DCs
- [SYSVOL & DFS-R](14-SYSVOL-DFSR.md) - SYSVOL replication health

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
