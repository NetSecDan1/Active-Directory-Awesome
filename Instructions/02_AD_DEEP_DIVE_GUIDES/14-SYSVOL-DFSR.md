# SYSVOL & DFS-R Troubleshooting

## AI Prompts for SYSVOL Replication and DFS-R Issues

---

## Overview

SYSVOL contains Group Policy objects and logon scripts that must be consistently available on all domain controllers. DFS-R (or legacy FRS) handles SYSVOL replication. Failures in SYSVOL replication directly impact Group Policy application and can cause significant issues. This module provides AI prompts for SYSVOL and DFS-R troubleshooting.

---

## Section 1: SYSVOL Health Assessment

### Prompt 1.1: SYSVOL Health Check

```
I need to assess SYSVOL health across my domain controllers.

ENVIRONMENT:
- Number of DCs: [X]
- Replication method: [DFS-R/FRS]
- Domain functional level: [Level]
- Recent issues: [Describe any]

Please provide:
1. SYSVOL share availability check on all DCs
2. DFS-R (or FRS) service status
3. Replication state verification
4. Content consistency check
5. NETLOGON share verification
6. GPO file comparison across DCs
7. Priority issues to address
```

### Prompt 1.2: SYSVOL Not Shared

```
SYSVOL is not being shared on a domain controller.

AFFECTED DC: [Name]
SYSVOL PATH: [Local path]
ERROR: [Any error messages]

DCDIAG OUTPUT:
[Paste relevant dcdiag output]

Please provide:
1. Verify SYSVOL folder exists and has content
2. Check DFS-R/FRS service status
3. Verify SYSVOL is in replicated state
4. Registry settings verification
5. Forcing SYSVOL share recreation
6. Checking AD replication of DFS-R config
7. Resolution steps
```

---

## Section 2: DFS-R Troubleshooting

### Prompt 2.1: DFS-R Replication Not Working

```
DFS-R replication for SYSVOL has stopped.

AFFECTED DCs: [List]
SYMPTOMS:
- Replication state: [Error state if known]
- Event log errors: [Paste events]
- Duration: [How long]

RECENT CHANGES:
[Any changes before issue started]

Please provide:
1. DFS-R service status verification
2. Replication group state check
3. Connection status between DCs
4. Backlog analysis
5. Common DFS-R issues and causes
6. Resolution procedure
7. Verification after fix
```

### Prompt 2.2: DFS-R Backlog Issues

```
DFS-R has a large replication backlog.

AFFECTED PATH: SYSVOL
SOURCE DC: [Name]
DESTINATION DC: [Name]
BACKLOG COUNT: [Number if known]

Please provide:
1. Checking backlog between DCs
2. Identifying cause of backlog
3. Backlog size thresholds
4. Resolving backlog buildup
5. Bandwidth and schedule considerations
6. Monitoring backlog health
7. Prevention measures
```

### Prompt 2.3: DFS-R Journal Wrap

```
CRITICAL: DFS-R journal wrap has occurred.

AFFECTED DC: [Name]
EVENT ID: [4012 or related]
CURRENT STATE: [Auto-recovery pending, manual intervention needed]

Please provide:
1. Journal wrap explained
2. Impact of journal wrap
3. Auto-recovery process
4. Manual recovery procedure if needed
5. Forcing authoritative/non-authoritative sync
6. Verification after recovery
7. Prevention measures
```

---

## Section 3: FRS to DFS-R Migration

### Prompt 3.1: FRS to DFS-R Migration Planning

```
I need to migrate SYSVOL replication from FRS to DFS-R.

ENVIRONMENT:
- Domain functional level: [Current level]
- Number of DCs: [X]
- Operating systems: [List DC OS versions]
- Current FRS health: [Status]

REQUIREMENTS:
- Maintenance window: [Available time]
- Rollback capability needed: [Yes/No]

Please provide:
1. Migration prerequisites
2. Pre-migration health checks
3. Migration phases explained
4. Step-by-step migration procedure
5. Verification at each stage
6. Rollback procedure
7. Post-migration validation
```

### Prompt 3.2: FRS to DFS-R Migration Troubleshooting

```
SYSVOL migration from FRS to DFS-R is stuck or failing.

CURRENT STATE: [Migration state - Prepared/Redirected/Eliminated]
STUCK AT: [Which phase]
ERROR: [Error message if any]

DC STATUS:
[List DCs and their migration states]

Please provide:
1. Diagnose migration state
2. Identify blocking issues
3. Resolution for this migration phase
4. Forcing migration state if needed
5. Rolling back if necessary
6. Completing migration
7. Verification of DFS-R operation
```

---

## Section 4: SYSVOL Content Issues

### Prompt 4.1: SYSVOL Content Inconsistency

```
SYSVOL content is different across domain controllers.

SYMPTOMS:
- GPOs different on different DCs: [Yes/No]
- Scripts missing: [Yes/No]
- File versions differ: [Yes/No]

COMPARISON:
[Describe differences found]

Please provide:
1. Tools for SYSVOL comparison
2. Identifying source of inconsistency
3. Determining authoritative source
4. Forcing authoritative sync
5. Resolving specific file conflicts
6. Verification of consistency
7. Monitoring for future inconsistencies
```

### Prompt 4.2: GPO Files Missing from SYSVOL

```
Group Policy files are missing from SYSVOL.

AFFECTED GPO: [Name and GUID]
MISSING FROM: [Which DCs]
PRESENT ON: [Which DCs, if any]

SYMPTOMS:
- GPO not applying: [Yes/No]
- GPO version mismatch: [AD vs. SYSVOL]

Please provide:
1. Verify GPO in AD vs. SYSVOL
2. Identify replication issue cause
3. Restore GPO files if possible
4. Force replication from source
5. Rebuild GPO if necessary
6. Verification after fix
7. Prevention measures
```

---

## Section 5: DFS-R Configuration

### Prompt 5.1: DFS-R Connection Issues

```
DFS-R connections between DCs are not working.

SOURCE DC: [Name]
DESTINATION DC: [Name]
CONNECTION STATE: [Error state]

NETWORK:
- DCs can ping each other: [Yes/No]
- Required ports open: [Verified/Unknown]

Please provide:
1. DFS-R connection requirements
2. Network connectivity verification
3. RPC connectivity test
4. Schedule and bandwidth check
5. Connection recreation if needed
6. Verification of connection health
7. Monitoring recommendations
```

### Prompt 5.2: DFS-R Staging and Conflict Folders

```
I need to manage DFS-R staging and conflict folders.

CONCERN:
- Disk space issues: [Yes/No]
- Large staging quota: [Yes/No]
- Conflict folder growing: [Yes/No]

CURRENT SETTINGS:
[Describe current staging quota if known]

Please provide:
1. Staging folder purpose and management
2. Conflict folder explained
3. Appropriate staging quota sizing
4. Modifying staging quota
5. Cleaning up safely
6. Monitoring disk space
7. Best practices for DFS-R folders
```

---

## Section 6: Authoritative and Non-Authoritative Restore

### Prompt 6.1: SYSVOL Authoritative Restore

```
I need to perform an authoritative restore of SYSVOL.

SCENARIO:
[Why authoritative restore is needed]

AUTHORITATIVE DC: [Name - DC with correct content]
OTHER DCs: [Count]

Please provide:
1. When authoritative restore is appropriate
2. Prerequisites and warnings
3. Step-by-step authoritative restore procedure
4. D4/D2 method for DFS-R
5. Monitoring sync to other DCs
6. Verification of completion
7. Troubleshooting if sync fails
```

### Prompt 6.2: SYSVOL Non-Authoritative Restore

```
I need to perform a non-authoritative restore of SYSVOL on a DC.

AFFECTED DC: [Name]
REASON: [Why this DC needs non-authoritative sync]

OTHER DCs STATUS:
[Confirm other DCs are healthy]

Please provide:
1. Non-authoritative restore explained
2. Prerequisites
3. Step-by-step procedure
4. D2 setting for DFS-R
5. Monitoring replication to this DC
6. Verification of completion
7. When to use this vs. other approaches
```

---

## Section 7: DFS-R Diagnostic Tools

### Prompt 7.1: DFS-R Diagnostics

```
I need to run comprehensive DFS-R diagnostics.

SCOPE: [All DCs / Specific DCs]
SPECIFIC CONCERN: [Describe if any]

Please provide:
1. DFSRDIAG commands for each check
2. DFS-R health report generation
3. Propagation test procedure
4. Event log analysis
5. WMI-based diagnostics
6. Interpreting diagnostic results
7. Common issues and resolutions
```

### Prompt 7.2: DFS-R Monitoring Script

```
Create a PowerShell script for DFS-R SYSVOL monitoring:

REQUIREMENTS:
1. Check DFS-R service on all DCs
2. Verify SYSVOL share availability
3. Check replication state
4. Measure backlog between DCs
5. Compare SYSVOL content hash
6. Generate health report
7. Alert on issues

Include error handling and scheduling guidance.
```

---

## Section 8: Legacy FRS Issues

### Prompt 8.1: FRS Troubleshooting

```
I'm still using FRS for SYSVOL and having issues.

SYMPTOMS:
[Describe FRS issues]

EVENT LOG:
[Paste FRS-related events]

MIGRATION STATUS:
[Planning migration to DFS-R?]

Please provide:
1. FRS service status check
2. FRS event log analysis
3. NTFRS debugging
4. Common FRS issues
5. Resolution procedures
6. FRS-specific considerations
7. Strong recommendation to migrate to DFS-R
```

---

## Quick Reference: DFS-R Commands

```powershell
# === DFS-R SERVICE ===

# Check DFS-R service
Get-Service DFSR

# Restart DFS-R
Restart-Service DFSR

# === REPLICATION STATUS ===

# Get DFS-R replication groups
Get-DfsReplicationGroup

# Get SYSVOL replication group members
Get-DfsrMember -GroupName "Domain System Volume"

# Get replication connections
Get-DfsrConnection -GroupName "Domain System Volume"

# === HEALTH REPORTS ===

# Generate health report
Write-DfsrHealthReport -GroupName "Domain System Volume" -Path C:\Reports

# Propagation test
dfsrdiag PropagationTest /testfile:test.txt /RGName:"Domain System Volume" /RFName:"SYSVOL Share"

# === BACKLOG ===

# Check backlog between DCs
dfsrdiag Backlog /SendingMember:DC1 /ReceivingMember:DC2 /RGName:"Domain System Volume" /RFName:"SYSVOL Share"

# Get backlog using PowerShell
Get-DfsrBacklog -GroupName "Domain System Volume" -FolderName "SYSVOL Share" -SourceComputerName DC1 -DestinationComputerName DC2

# === REPLICATION STATE ===

# Get replication state
dfsrdiag ReplicationState

# Get member state
Get-DfsrState

# === AUTHORITATIVE/NON-AUTHORITATIVE ===

# View current DFS-R flags (check registry)
# HKLM\SYSTEM\CurrentControlSet\Services\DFSR\Parameters\SysVols\Replicating Volumes\SYSVOL Share

# Force authoritative (D4) - run on authoritative DC
# Stop DFSR
# Set HKLM\...\SYSVOL Share value "Options" to 1
# Start DFSR

# Force non-authoritative (D2) - run on receiving DCs
# Stop DFSR
# Set HKLM\...\SYSVOL Share value "Options" to 0
# Delete files in local SYSVOL
# Start DFSR

# === SYSVOL VERIFICATION ===

# Check SYSVOL share
Get-SmbShare -Name SYSVOL

# Verify SYSVOL content
Get-ChildItem \\domain.com\SYSVOL\domain.com\Policies

# Compare SYSVOL across DCs
# (Compare-Object on file listings)

# === DCDIAG TESTS ===

# Test SYSVOL
dcdiag /test:sysvolcheck

# Test NETLOGON
dcdiag /test:netlogons

# Full DFS-R test
dcdiag /test:DFSREvent
```

---

## SYSVOL/DFS-R Event IDs

| Event ID | Source | Description |
|----------|--------|-------------|
| 4012 | DFSR | Journal wrap occurred |
| 4104 | DFSR | SYSVOL sharing enabled |
| 4114 | DFSR | SYSVOL sharing disabled |
| 4602 | DFSR | Successfully synced |
| 4604 | DFSR | Initial sync completed |
| 5002 | DFSR | File conflict resolved |
| 5008 | DFSR | Connection created |
| 5014 | DFSR | Staging space issue |
| 1202 | NETLOGON | Share failed |

---

## DFS-R Migration States

| State | Value | Description |
|-------|-------|-------------|
| Start | 0 | FRS active, DFS-R not configured |
| Prepared | 1 | DFS-R configured, FRS active |
| Redirected | 2 | DFS-R active, FRS still running |
| Eliminated | 3 | DFS-R active, FRS removed |

---

## SYSVOL Troubleshooting Flowchart

```
SYSVOL Issue Detected
│
├── SYSVOL share not available?
│   ├── Check DFS-R service
│   ├── Check SYSVOL replication state
│   └── Verify registry settings
│
├── Content inconsistent?
│   ├── Check replication backlog
│   ├── Verify connections
│   └── Consider authoritative restore
│
├── GPO not applying?
│   ├── Check GPO in SYSVOL on target DC
│   ├── Verify replication completed
│   └── Check AD GPO replication
│
└── Replication stopped?
    ├── Check for journal wrap (4012)
    ├── Check disk space
    └── Check connectivity between DCs
```

---

## Related Modules

- [Replication Issues](01-Replication-Issues.md) - AD replication affects DFS-R config
- [Group Policy](04-Group-Policy.md) - GPOs stored in SYSVOL
- [Domain Controller Health](06-Domain-Controller-Health.md) - DC services including DFS-R

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
