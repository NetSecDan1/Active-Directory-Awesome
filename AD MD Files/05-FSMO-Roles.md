# Active Directory FSMO Roles Troubleshooting

## AI Prompts for Managing and Troubleshooting FSMO Role Issues

---

## Overview

Flexible Single Master Operations (FSMO) roles are critical Active Directory functions that must be performed by a single domain controller to prevent conflicts. Understanding, managing, and troubleshooting these roles is essential for AD health. This module provides comprehensive AI prompts for FSMO role management.

---

## Section 1: FSMO Role Identification and Assessment

### Prompt 1.1: Identify Current FSMO Role Holders

```
I need to identify all FSMO role holders in my Active Directory environment.

ENVIRONMENT:
- Number of forests: [X]
- Number of domains: [X]
- Forest name: [Name]
- Domain names: [List]

Please provide:
1. Commands to identify all five FSMO role holders
2. Explanation of each role's function and scope (forest vs. domain)
3. How to verify role holders are healthy
4. Best practices for FSMO role placement
5. Documentation template for FSMO role inventory
6. Monitoring recommendations for FSMO availability
```

### Prompt 1.2: FSMO Role Health Assessment

```
I need to assess the health of FSMO role holders.

CURRENT ROLE HOLDERS:
- Schema Master: [DC name]
- Domain Naming Master: [DC name]
- PDC Emulator: [DC name]
- RID Master: [DC name]
- Infrastructure Master: [DC name]

ENVIRONMENT DETAILS:
- Domain functional level: [Level]
- Number of DCs: [X]
- Known issues: [Describe any]

Please provide:
1. Health check commands for each FSMO role holder
2. How to verify each role is functioning properly
3. Performance indicators for each role
4. Common issues that indicate FSMO problems
5. Proactive monitoring recommendations
6. Best practices for role holder redundancy planning
```

---

## Section 2: FSMO Role Transfer

### Prompt 2.1: Planned FSMO Role Transfer

```
I need to transfer FSMO roles as part of planned maintenance.

TRANSFER SCENARIO:
- Roles to transfer: [List specific roles]
- Current holder: [DC name]
- Target DC: [DC name]
- Reason: [Maintenance, decommission, optimization]

PREREQUISITES VERIFICATION:
- Replication current: [Yes/No]
- Target DC health: [Status]
- Network connectivity: [Status]

Please provide:
1. Pre-transfer checklist and verification steps
2. Step-by-step transfer procedure for each role
3. Commands for both GUI and command-line transfers
4. How to verify transfer was successful
5. Post-transfer validation steps
6. Rollback procedure if issues arise
7. Communication plan for stakeholders
```

### Prompt 2.2: Transfer All FSMO Roles to New DC

```
I need to transfer all FSMO roles to a new domain controller.

CURRENT ROLE HOLDER: [DC name]
TARGET DC: [DC name]
REASON: [Decommissioning old DC, hardware refresh, etc.]

ENVIRONMENT:
- Domain: [Name]
- Other DCs available: [List]
- Replication status: [Healthy/Issues]

Please provide:
1. Complete procedure for transferring all five roles
2. Order of transfer recommendations
3. Verification after each role transfer
4. Time estimation for complete transfer
5. Risk mitigation steps
6. What to do if a transfer fails
7. Final validation checklist
```

---

## Section 3: FSMO Role Seizure

### Prompt 3.1: Emergency FSMO Role Seizure

```
EMERGENCY: A FSMO role holder is permanently offline and I need to seize roles.

OFFLINE DC: [DC name]
ROLES HELD BY OFFLINE DC: [List roles]
DC STATUS: [Crashed, corrupted, physically destroyed, etc.]
RECOVERY POSSIBLE: [Yes/No/Unknown]

IMPACT OBSERVED:
[Describe what functionality is affected]

Please provide:
1. Confirmation of when seizure is appropriate vs. waiting for recovery
2. Critical warnings and irreversible implications
3. Step-by-step seizure procedure using ntdsutil
4. Post-seizure actions required
5. What to do if the old DC comes back online
6. Metadata cleanup requirements
7. How to prevent duplicate operations
```

### Prompt 3.2: Schema Master Seizure

```
CRITICAL: I need to seize the Schema Master role.

CURRENT SCHEMA MASTER: [DC name - offline/unrecoverable]
TARGET DC: [DC name]

REASON FOR SEIZURE:
[Describe why transfer is not possible]

Please provide:
1. Specific risks of Schema Master seizure
2. Prerequisites before seizing Schema Master
3. Complete seizure procedure
4. Post-seizure validation
5. What happens if old Schema Master comes online
6. Permanent removal of old Schema Master from AD
7. Best practices after Schema Master seizure
```

### Prompt 3.3: RID Master Seizure

```
CRITICAL: I need to seize the RID Master role.

CURRENT RID MASTER: [DC name - offline]
RID POOL STATUS:
- Remaining RIDs on other DCs: [If known]
- RID exhaustion concern: [Yes/No]

Please provide:
1. RID Master seizure implications
2. Complete seizure procedure
3. RID pool verification after seizure
4. Preventing duplicate SID assignment
5. What if old RID Master returns
6. RID pool management post-seizure
7. Monitoring for RID issues
```

---

## Section 4: Individual FSMO Role Issues

### Prompt 4.1: PDC Emulator Issues

```
I'm experiencing issues related to the PDC Emulator role.

PDC EMULATOR: [DC name]
SYMPTOMS:
[Describe - time sync issues, password change failures, lockout issues, GPO editing problems]

CURRENT STATUS:
- DC online: [Yes/No]
- Reachable: [Yes/No]
- CPU/Memory load: [If known]

Please provide:
1. PDC Emulator functions and what fails when it's unavailable
2. Diagnosing specific PDC Emulator issues
3. Impact of PDC Emulator problems
4. Immediate mitigation steps
5. Resolution based on symptoms
6. When to transfer vs. troubleshoot
7. Post-resolution verification
```

### Prompt 4.2: RID Master and RID Pool Issues

```
I'm experiencing RID-related issues.

SYMPTOMS:
[Describe - cannot create objects, RID pool warnings, Event 16644/16645/16656]

RID MASTER: [DC name]
EVENT LOG ENTRIES:
[Paste relevant events]

Please provide:
1. How RID allocation works in AD
2. Diagnosing RID pool issues
3. Checking RID pool status on all DCs
4. Requesting new RID pool manually
5. RID pool exhaustion prevention
6. InvalidateRidPool procedure if needed
7. Monitoring RID pool health
```

### Prompt 4.3: Infrastructure Master Issues

```
I'm experiencing issues potentially related to the Infrastructure Master.

SYMPTOMS:
[Describe - phantom objects, group membership issues, cross-domain reference problems]

INFRASTRUCTURE MASTER: [DC name]
IS INFRA MASTER ALSO A GC: [Yes/No]
ALL DCS ARE GCs: [Yes/No]

Please provide:
1. Infrastructure Master function explained
2. GC and Infrastructure Master placement rules
3. Diagnosing Infrastructure Master issues
4. Impact of incorrect placement
5. Resolution steps
6. Verification after fixes
7. Best practices for Infrastructure Master placement
```

### Prompt 4.4: Domain Naming Master Issues

```
I cannot add or remove domains in my forest.

DOMAIN NAMING MASTER: [DC name]
ATTEMPTED OPERATION: [Add domain, remove domain, add/remove partition]
ERROR MESSAGE: [Paste exact error]

Please provide:
1. Domain Naming Master functions
2. Requirements for domain operations
3. Diagnosing Domain Naming Master connectivity
4. Resolving Domain Naming Master issues
5. When seizure might be necessary
6. Verification of Domain Naming Master health
7. Best practices for Domain Naming Master placement
```

### Prompt 4.5: Schema Master Issues

```
I cannot extend the AD schema or I'm having Schema Master issues.

SCHEMA MASTER: [DC name]
ATTEMPTED OPERATION: [Schema extension, application installation requiring schema]
ERROR MESSAGE: [Paste exact error]

Please provide:
1. Schema Master functions
2. Schema extension prerequisites
3. Diagnosing Schema Master connectivity
4. Schema Admin permissions verification
5. Resolving Schema Master issues
6. Safe schema extension procedure
7. Schema Master best practices
```

---

## Section 5: FSMO Role Placement Strategy

### Prompt 5.1: Optimal FSMO Role Placement

```
I need guidance on optimal FSMO role placement for my environment.

ENVIRONMENT:
- Number of domains: [X]
- Number of sites: [X]
- Number of DCs per domain: [X]
- Global Catalogs: [Which DCs]
- Primary datacenter: [Location]
- DR site: [Location]
- Virtualized DCs: [Yes/No, which]

CURRENT PLACEMENT:
[List current role holders]

Please provide:
1. Recommended FSMO placement strategy
2. Co-location recommendations (which roles together)
3. Site considerations for role placement
4. Global Catalog vs. non-GC considerations
5. Virtualization considerations
6. DR and high availability recommendations
7. Migration plan if changes are needed
```

### Prompt 5.2: Multi-Domain FSMO Placement

```
I have a multi-domain forest and need FSMO placement guidance.

FOREST STRUCTURE:
- Forest root domain: [Name]
- Child domains: [List]
- Resource domains: [If any]

CURRENT PLACEMENT:
[List all role holders in all domains]

REQUIREMENTS:
- DR capability: [Requirements]
- Geographic constraints: [List]

Please provide:
1. Forest-wide role (Schema, Domain Naming) placement
2. Domain-specific role placement per domain
3. Cross-domain considerations
4. Infrastructure Master GC implications per domain
5. Centralized vs. distributed placement pros/cons
6. DR scenario planning for FSMO roles
7. Documentation and monitoring recommendations
```

---

## Section 6: Post-DC Decommission FSMO Tasks

### Prompt 6.1: Proper DC Decommissioning with FSMO Roles

```
I need to decommission a DC that holds FSMO roles.

DC TO DECOMMISSION: [Name]
ROLES HELD: [List]
TARGET DC FOR ROLES: [Name]
DECOMMISSION METHOD: [Planned demotion, forced removal]

Please provide:
1. Complete pre-decommission checklist
2. FSMO transfer procedure before demotion
3. Verification that transfers succeeded
4. Proper dcpromo demotion procedure
5. Post-demotion validation
6. Metadata cleanup (if forced removal)
7. DNS and other cleanup tasks
```

### Prompt 6.2: Metadata Cleanup After Failed DC

```
A DC that held FSMO roles has been forcibly removed or crashed and I need to clean up.

FAILED DC: [Name]
ROLES IT HELD: [List]
REMOVAL METHOD: [Crash, forced removal, etc.]
ROLES ALREADY SEIZED: [Yes/No, list if yes]

Please provide:
1. Complete metadata cleanup procedure
2. NTDSUTIL metadata cleanup commands
3. DNS record cleanup
4. SYSVOL cleanup
5. Verification that cleanup is complete
6. Preventing the old DC from causing issues if it returns
7. Final validation checklist
```

---

## Section 7: Monitoring and Alerting

### Prompt 7.1: FSMO Role Monitoring Setup

```
I want to implement monitoring for FSMO role holders.

MONITORING TOOLS AVAILABLE: [SCOM, custom scripts, third-party]
ALERTING REQUIREMENTS: [Email, SMS, ticketing system]

Please provide:
1. Key metrics to monitor for each FSMO role
2. Health check scripts for automated monitoring
3. Alert thresholds and severity levels
4. Recommended monitoring intervals
5. Integration with existing monitoring tools
6. Sample alert response procedures
7. Regular health check schedule
```

### Prompt 7.2: FSMO Health Check Script

```
Create a comprehensive PowerShell script that:

1. Identifies all FSMO role holders in the forest
2. Tests connectivity to each role holder
3. Verifies each role is responding correctly
4. Checks replication status for role holders
5. Validates role holders are properly advertised in DNS
6. Generates report with health status
7. Sends alerts if issues are detected

Include error handling, logging, and scheduling guidance.
```

---

## Quick Reference: FSMO Commands

```powershell
# === IDENTIFY FSMO ROLE HOLDERS ===

# All roles (quick)
netdom query fsmo

# Forest-wide roles
Get-ADForest | Select-Object SchemaMaster, DomainNamingMaster

# Domain-wide roles
Get-ADDomain | Select-Object PDCEmulator, RIDMaster, InfrastructureMaster

# Using ntdsutil
ntdsutil
roles
connections
connect to server DCName
quit
select operation target
list roles for connected server
quit
quit
quit

# === TRANSFER ROLES (PowerShell) ===

# Transfer Schema Master
Move-ADDirectoryServerOperationMasterRole -Identity TargetDC -OperationMasterRole SchemaMaster

# Transfer Domain Naming Master
Move-ADDirectoryServerOperationMasterRole -Identity TargetDC -OperationMasterRole DomainNamingMaster

# Transfer PDC Emulator
Move-ADDirectoryServerOperationMasterRole -Identity TargetDC -OperationMasterRole PDCEmulator

# Transfer RID Master
Move-ADDirectoryServerOperationMasterRole -Identity TargetDC -OperationMasterRole RIDMaster

# Transfer Infrastructure Master
Move-ADDirectoryServerOperationMasterRole -Identity TargetDC -OperationMasterRole InfrastructureMaster

# Transfer all roles
Move-ADDirectoryServerOperationMasterRole -Identity TargetDC -OperationMasterRole SchemaMaster,DomainNamingMaster,PDCEmulator,RIDMaster,InfrastructureMaster

# === SEIZE ROLES (Emergency Only) ===

# Using ntdsutil (interactive)
ntdsutil
roles
connections
connect to server TargetDC
quit
seize schema master
seize naming master
seize pdc
seize rid master
seize infrastructure master
quit
quit

# Using PowerShell (add -Force for seizure)
Move-ADDirectoryServerOperationMasterRole -Identity TargetDC -OperationMasterRole PDCEmulator -Force

# === RID POOL MANAGEMENT ===

# Check RID pool status
dcdiag /test:ridmanager /v

# Check available RIDs
Get-ADObject -Identity "CN=RID Manager$,CN=System,DC=domain,DC=com" -Properties rIDAvailablePool

# === HEALTH CHECKS ===

# Test FSMO connectivity
dcdiag /test:fsmocheck

# Verify specific role holder
nltest /dsgetdc:domain.com /pdc
nltest /dsgetdc:domain.com /gc

# Test Schema Master
Get-ADObject -SearchBase "CN=Schema,CN=Configuration,DC=domain,DC=com" -Filter * -Properties * | Select-Object -First 1
```

---

## FSMO Roles Quick Reference

| Role | Scope | Function | Impact When Offline |
|------|-------|----------|---------------------|
| Schema Master | Forest | Schema modifications | Cannot extend schema |
| Domain Naming Master | Forest | Domain add/remove | Cannot add/remove domains |
| PDC Emulator | Domain | Time sync, password changes, GPO editing, legacy auth | Authentication delays, time drift, lockout issues |
| RID Master | Domain | RID pool allocation | Cannot create new objects (eventually) |
| Infrastructure Master | Domain | Cross-domain reference updates | Stale group memberships (multi-domain) |

---

## Related Modules

- [Domain Controller Health](06-Domain-Controller-Health.md) - DC health affects FSMO availability
- [AD Database & Recovery](08-AD-Database-Recovery.md) - Recovery scenarios may require FSMO actions
- [Replication Issues](01-Replication-Issues.md) - Replication is critical for FSMO operations

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
