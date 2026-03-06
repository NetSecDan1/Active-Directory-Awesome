# Active Directory Database & Recovery

## AI Prompts for AD Database Management and Disaster Recovery

---

## Overview

The Active Directory database (NTDS.dit) is the heart of AD, containing all directory objects and their attributes. Understanding database maintenance, backup strategies, and recovery procedures is critical for AD administrators. This module provides comprehensive AI prompts for database management and disaster recovery scenarios.

---

## Section 1: AD Database Fundamentals

### Prompt 1.1: AD Database Health Assessment

```
I need to assess the health of the AD database on a domain controller.

DC NAME: [Name]
REASON FOR CHECK: [Routine, suspected issue, post-incident]

SYMPTOMS (if any):
[Describe - slow queries, events mentioning database, etc.]

CURRENT DATABASE SIZE:
- NTDS.dit size: [If known]
- Log files size: [If known]

Please provide:
1. Database health check commands and procedures
2. Integrity verification methods
3. Database size analysis and optimization
4. Transaction log analysis
5. White space assessment
6. Performance metrics to collect
7. Recommended maintenance schedule
```

### Prompt 1.2: Understanding NTDS.dit Structure

```
I need to understand the AD database structure for troubleshooting purposes.

SPECIFIC QUESTIONS:
[List specific aspects you want to understand]

Please provide:
1. NTDS.dit file structure explanation
2. Database tables and their purposes
3. Transaction log function and management
4. How changes are written and committed
5. Database partitions explained
6. Garbage collection process
7. Tools for database analysis
```

---

## Section 2: AD Backup

### Prompt 2.1: AD Backup Strategy Development

```
I need to develop or improve our AD backup strategy.

ENVIRONMENT:
- Number of DCs: [X]
- Domain/forest structure: [Describe]
- Current backup solution: [None/Windows Backup/Third-party]
- RPO requirement: [Maximum acceptable data loss]
- RTO requirement: [Maximum acceptable downtime]

CURRENT BACKUP STATUS:
[Describe existing backup procedures if any]

Please provide:
1. AD-specific backup requirements and best practices
2. System State vs. bare metal backup
3. Recommended backup frequency
4. Backup storage and retention recommendations
5. Which DCs to back up and why
6. Backup verification procedures
7. Documentation requirements
8. Integration with enterprise backup strategy
```

### Prompt 2.2: Backup Verification

```
I need to verify that AD backups are valid and restorable.

BACKUP SOLUTION: [Windows Backup/Veeam/CommVault/etc.]
LAST BACKUP DATE: [Date]
BACKUP LOCATION: [Path/media]

Please provide:
1. Backup verification commands and procedures
2. Testing restore to isolated environment
3. System State backup validation
4. Backup catalog verification
5. Common backup issues to check for
6. Backup monitoring and alerting
7. Regular verification schedule recommendation
```

---

## Section 3: Object Recovery (Recycle Bin)

### Prompt 3.1: AD Recycle Bin Recovery

```
I need to recover a deleted object from the AD Recycle Bin.

DELETED OBJECT:
- Object type: [User/Computer/Group/OU/Other]
- Object name: [Name]
- Deletion time: [When deleted, if known]
- Deleted by: [If known]

RECYCLE BIN STATUS: [Enabled/Disabled]
TOMBSTONE LIFETIME: [X days]

Please provide:
1. Verify Recycle Bin is enabled and object is recoverable
2. How to find deleted objects
3. Complete recovery procedure
4. Verifying object is restored with all attributes
5. Restoring linked attributes (group memberships)
6. Recovering container with children
7. What to do if Recycle Bin isn't enabled
```

### Prompt 3.2: Enable and Configure AD Recycle Bin

```
I want to enable the AD Recycle Bin.

FOREST FUNCTIONAL LEVEL: [Level]
NUMBER OF DOMAINS: [X]
CURRENT STATUS: [Recycle Bin not enabled]

Please provide:
1. Prerequisites for AD Recycle Bin
2. Impact of enabling Recycle Bin
3. Step-by-step enablement procedure
4. Verification that Recycle Bin is working
5. Deleted object lifetime configuration
6. Best practices after enablement
7. Implications for backup and recovery procedures
```

---

## Section 4: Authoritative Restore

### Prompt 4.1: Authoritative Restore Planning

```
I need to perform an authoritative restore of AD objects.

SCENARIO:
- Objects to restore: [Describe - OU, users, groups, etc.]
- Why authoritative restore needed: [Accidental deletion beyond Recycle Bin, corruption, etc.]
- Scope of restore: [Specific objects, entire subtree, etc.]

AVAILABLE BACKUP:
- Backup date: [Date]
- Backup type: [System State, full, etc.]
- Backup verified: [Yes/No]

CURRENT AD STATE:
- Object still tombstoned: [Yes/No]
- Days since deletion: [X days]
- Tombstone lifetime: [X days]

Please provide:
1. Authoritative restore explained
2. Decision tree: authoritative restore vs. other options
3. Pre-restore planning and impact assessment
4. Step-by-step authoritative restore procedure
5. How to mark specific objects as authoritative
6. Post-restore verification
7. Replication considerations
8. Rollback plan if issues occur
```

### Prompt 4.2: Performing Authoritative Restore

```
CRITICAL: I need to perform an authoritative restore now.

WHAT TO RESTORE: [Specific DN or subtree]
BACKUP BEING USED: [Date and type]
DC FOR RESTORE: [Name]

IMPACT ASSESSMENT COMPLETED: [Yes/No]
CHANGE APPROVAL: [Yes/No/Emergency]

Please provide:
1. Boot DC into DSRM procedure
2. System State restore procedure
3. Marking objects authoritative (ntdsutil)
4. Version increment calculation for subtrees
5. Restarting DC and monitoring replication
6. Verifying authoritative data propagates
7. Troubleshooting if restore fails
8. Post-restore validation checklist
```

---

## Section 5: Non-Authoritative Restore

### Prompt 5.1: Non-Authoritative DC Restore

```
I need to restore a DC using non-authoritative restore.

SCENARIO: [DC crash, corruption, rebuilding DC]
DC TO RESTORE: [Name]
ROLES HELD: [FSMO, GC, etc.]

AVAILABLE OPTIONS:
- System State backup available: [Yes/No, date]
- Other healthy DCs exist: [Yes/No]
- Reinstall and promote viable: [Yes/No]

Please provide:
1. Non-authoritative restore explained
2. When to restore vs. rebuild from scratch
3. Step-by-step restore procedure
4. Post-restore replication convergence
5. Verification that DC is healthy
6. FSMO role considerations
7. Sysvol restoration considerations
8. Alternative: reinstall and repromote procedure
```

---

## Section 6: Database Maintenance

### Prompt 6.1: Offline Database Defragmentation

```
I need to perform offline defragmentation of the AD database.

DC: [Name]
CURRENT DATABASE SIZE: [X GB]
ESTIMATED WHITE SPACE: [If known]
MAINTENANCE WINDOW: [Available time]

Please provide:
1. When offline defrag is needed vs. online
2. Prerequisites and preparations
3. Step-by-step offline defrag procedure
4. Using ntdsutil for compact
5. Expected time and disk space requirements
6. Verification after defragmentation
7. Risks and rollback plan
8. Alternatives if maintenance window is limited
```

### Prompt 6.2: Database Integrity Check

```
I need to verify AD database integrity.

DC: [Name]
REASON: [Suspected corruption, routine check, post-incident]

SYMPTOMS SUGGESTING CORRUPTION:
[Describe any symptoms]

Please provide:
1. Online integrity check options
2. Offline integrity check procedure (esentutl)
3. Semantic database analysis
4. Interpreting integrity check results
5. Actions if corruption is found
6. Decision: repair vs. restore vs. rebuild
7. Reporting and documentation
```

### Prompt 6.3: Database Repair

```
CRITICAL: AD database corruption has been detected.

DC: [Name]
CORRUPTION EVIDENCE: [Describe - events, errors, integrity check results]
OTHER HEALTHY DCS: [Yes/No, list]

Please provide:
1. Assess severity and scope of corruption
2. Immediate containment (isolate DC if needed)
3. Repair options and their risks
4. esentutl repair procedure
5. semantic database analysis after repair
6. When repair is not recommended
7. Restore from backup alternative
8. Rebuild DC alternative
9. Preventing corruption spread
```

---

## Section 7: Disaster Recovery Scenarios

### Prompt 7.1: Complete Forest Recovery

```
DISASTER: Complete forest recovery is needed.

SCENARIO: [Describe - all DCs lost, forest corruption, security breach requiring reset]

AVAILABLE RESOURCES:
- Backup availability: [Describe]
- Backup age: [Date of most recent]
- Offline copies: [If any]
- Documentation available: [What exists]

FOREST DETAILS (from documentation):
- Number of domains: [X]
- Forest root domain: [Name]
- FSMO role holders: [List if known]

Please provide:
1. Forest recovery planning and assessment
2. Selecting DC to restore first
3. Forest recovery procedure overview
4. Step-by-step recovery of first DC
5. Recovering additional DCs
6. Rebuilding vs. restoring subsequent DCs
7. Post-recovery validation checklist
8. Communication and documentation requirements
```

### Prompt 7.2: Single Domain Recovery

```
DISASTER: A single domain in my forest needs recovery.

AFFECTED DOMAIN: [Name]
FOREST ROOT: [Name - is it affected?]
OTHER DOMAINS: [List - are they healthy?]

SCENARIO:
[Describe what happened and current state]

BACKUP AVAILABILITY:
[Describe what backups exist]

Please provide:
1. Single domain recovery assessment
2. Impact on forest and other domains
3. Recovery procedure for non-root domain
4. Trust relationship restoration
5. Special considerations if forest root
6. Post-recovery verification
7. Timeline and communication planning
```

### Prompt 7.3: Recovering from USN Rollback

```
CRITICAL: USN rollback has occurred and needs remediation.

AFFECTED DC: [Name]
CAUSE: [VM snapshot restore, improper backup restore, etc.]
DETECTION METHOD: [How was it discovered]
TIME SINCE ROLLBACK: [If known]

OTHER DCS STATUS:
[Describe health of other DCs]

Please provide:
1. Confirm USN rollback has occurred
2. Immediate isolation of affected DC
3. Assess impact and scope
4. Remediation options
5. Preferred: forcibly demote and rebuild
6. Lingering objects cleanup
7. Verification after remediation
8. Prevention measures
```

---

## Section 8: DSRM (Directory Services Restore Mode)

### Prompt 8.1: DSRM Password Management

```
I need to manage the DSRM password.

DC: [Name]
ISSUE: [Password unknown, needs reset, policy requirement]

Please provide:
1. DSRM password purpose and importance
2. How to reset DSRM password
3. ntdsutil method
4. Syncing DSRM password with domain account
5. DSRM password policy recommendations
6. Documenting DSRM passwords securely
7. Testing DSRM access
```

### Prompt 8.2: Booting into DSRM

```
I need to boot a DC into Directory Services Restore Mode.

DC: [Name]
REASON: [Database maintenance, restore, troubleshooting]
ACCESS METHOD: [Physical console, RDP, VM console, etc.]

Please provide:
1. Methods to enter DSRM
2. bcdedit method for remote boot to DSRM
3. F8/boot menu method
4. DSRM login requirements
5. What services are available in DSRM
6. Performing required operations in DSRM
7. Returning to normal operation
8. Troubleshooting DSRM boot issues
```

---

## Section 9: Tombstone and Deleted Objects

### Prompt 9.1: Tombstone Lifetime Management

```
I need to understand or modify tombstone lifetime.

CURRENT TOMBSTONE LIFETIME: [X days, or unknown]
FOREST FUNCTIONAL LEVEL: [Level]
RECYCLE BIN ENABLED: [Yes/No]

CONCERN:
[Describe - DCs offline too long, need shorter/longer lifetime, etc.]

Please provide:
1. Tombstone lifetime explained
2. How to check current tombstone lifetime
3. Implications of changing tombstone lifetime
4. Safe procedure to modify
5. Relationship with backup retention
6. Deleted object lifetime (with Recycle Bin)
7. Best practices for tombstone lifetime
```

### Prompt 9.2: Recovering Objects Beyond Tombstone

```
CRITICAL: I need to recover an object deleted beyond tombstone lifetime.

OBJECT DETAILS:
- Type: [User/Group/Computer/Other]
- Name: [Name]
- Deletion date: [Date]
- Current tombstone lifetime: [X days]

BACKUP AVAILABILITY:
[Describe available backups]

Please provide:
1. Options for recovery beyond tombstone
2. Authoritative restore procedure
3. Recreating object with same SID (if applicable)
4. Group membership considerations
5. Alternative: recreate and migrate
6. Verification after recovery
7. Preventing future extended deletions
```

---

## Section 10: Backup and Recovery Scripts

### Prompt 10.1: AD Backup Automation Script

```
Create a PowerShell script for automated AD backup:

REQUIREMENTS:
1. Perform Windows Server Backup of System State
2. Rotate backups (keep last X backups)
3. Verify backup completed successfully
4. Log all backup operations
5. Send email notification on success/failure
6. Support for network backup location
7. Schedule via Task Scheduler

Include error handling and documentation.
```

### Prompt 10.2: Backup Verification Script

```
Create a PowerShell script that verifies AD backup health:

REQUIREMENTS:
1. Check backup age (alert if older than X days)
2. Verify backup file integrity
3. Check backup catalog
4. Verify backup size is reasonable
5. Test ability to browse backup
6. Generate compliance report
7. Alert on any failures

Include integration with monitoring systems.
```

---

## Quick Reference: Database Commands

```powershell
# === DATABASE INFORMATION ===

# Database file location
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters" | Select-Object "DSA Database file"

# Database and log sizes
Get-ChildItem "C:\Windows\NTDS" | Select-Object Name, Length, LastWriteTime

# === INTEGRITY CHECK (OFFLINE ONLY - DSRM) ===

# Check database integrity
esentutl /g "C:\Windows\NTDS\ntds.dit"

# Check header
esentutl /mh "C:\Windows\NTDS\ntds.dit"

# === DEFRAGMENTATION (OFFLINE ONLY - DSRM) ===

# Compact database using ntdsutil
ntdsutil
activate instance ntds
files
compact to C:\Temp
quit
quit

# === RECOVERY ===

# Check backup catalog
wbadmin get versions

# Start System State restore (DSRM)
wbadmin start systemstaterecovery -version:<version>

# Authoritative restore
ntdsutil
activate instance ntds
authoritative restore
restore object "CN=User,OU=Users,DC=domain,DC=com"
restore subtree "OU=Users,DC=domain,DC=com"
quit
quit

# === RECYCLE BIN ===

# Check if Recycle Bin is enabled
Get-ADOptionalFeature -Filter {name -like "Recycle Bin Feature"}

# Enable Recycle Bin
Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target 'forest.com'

# Find deleted objects
Get-ADObject -Filter 'isDeleted -eq $true' -IncludeDeletedObjects

# Restore deleted object
Restore-ADObject -Identity <ObjectGUID>

# === TOMBSTONE ===

# Check tombstone lifetime
Get-ADObject "CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=domain,DC=com" -Properties tombstoneLifetime

# Modify tombstone lifetime (forest-wide!)
Set-ADObject "CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=domain,DC=com" -Replace @{tombstoneLifetime=180}

# === DSRM ===

# Set boot to DSRM
bcdedit /set safeboot dsrepair

# Return to normal boot
bcdedit /deletevalue safeboot

# Reset DSRM password
ntdsutil
set dsrm password
reset password on server null
<enter new password>
quit
quit

# === BACKUP ===

# Create System State backup
wbadmin start systemstatebackup -backupTarget:D:

# Schedule backup
wbadmin enable backup -addtarget:D: -schedule:02:00
```

---

## Recovery Decision Tree

```
Has object been deleted?
├── Yes → Is AD Recycle Bin enabled?
│   ├── Yes → Is object within deleted object lifetime?
│   │   ├── Yes → Use Restore-ADObject ✓
│   │   └── No → Need authoritative restore
│   └── No → Is object within tombstone lifetime?
│       ├── Yes → Limited recovery (reanimation) possible
│       └── No → Need authoritative restore
└── No → Is DC/Database corrupted?
    ├── Yes → Are other healthy DCs available?
    │   ├── Yes → Rebuild DC from replication
    │   └── No → Restore from backup or forest recovery
    └── No → Standard troubleshooting
```

---

## Related Modules

- [Domain Controller Health](06-Domain-Controller-Health.md) - DC health affects database
- [FSMO Roles](05-FSMO-Roles.md) - FSMO considerations in recovery
- [Replication Issues](01-Replication-Issues.md) - Replication after restore
- [Security & Incident Response](10-Security-Incident-Response.md) - Recovery from security incidents

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
