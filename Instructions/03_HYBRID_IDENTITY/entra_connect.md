# Azure AD Connect / Entra Connect Troubleshooting

## Deep Dive into Directory Synchronization Issues

---

## Sync Architecture Understanding

### How Sync Actually Works

```
SYNC FLOW ARCHITECTURE:

On-Premises AD                    Azure AD Connect                    Entra ID
    │                                   │                                │
    │  ┌─────────────────────────────────────────────────────────────┐   │
    │  │                    CONNECTOR SPACE                          │   │
    │  │  ┌──────────────┐              ┌──────────────┐            │   │
    ├──┼──► AD Connector │              │ AAD Connector├────────────┼───►
    │  │  │  (Import)    │              │  (Export)    │            │   │
    │  │  └──────┬───────┘              └──────▲───────┘            │   │
    │  │         │                             │                     │   │
    │  │         ▼                             │                     │   │
    │  │  ┌──────────────────────────────────────────┐              │   │
    │  │  │              METAVERSE                    │              │   │
    │  │  │   (Unified view of identity)             │              │   │
    │  │  └──────────────────────────────────────────┘              │   │
    │  └─────────────────────────────────────────────────────────────┘   │
    │                                                                    │

SYNC CYCLE PHASES:
1. IMPORT (AD → Connector Space): Read changes from AD
2. SYNC (Connector Space → Metaverse): Apply sync rules
3. EXPORT (Metaverse → AAD Connector): Stage changes for cloud
4. EXPORT (AAD Connector → Entra ID): Push changes to cloud
```

---

## Section 1: Sync Cycle Issues

### Prompt 1.1: Sync Cycle Not Running

```
Azure AD Connect sync cycles are not running.

CURRENT STATE:
- Scheduler status: [Enabled/Disabled]
- Last successful sync: [Time]
- Error messages: [If any]

Get-ADSyncScheduler OUTPUT:
[Paste output]

Please provide:
1. Verify scheduler is enabled and configured
2. Check for blocking processes
3. Verify SQL connectivity (if remote SQL)
4. Check service account permissions
5. Examine sync engine event logs
6. Resolution steps based on findings
7. Verification that sync resumes
```

### Prompt 1.2: Sync Cycle Failing Mid-Run

```
Sync cycles start but fail before completion.

ERROR:
[Paste error from event log or Synchronization Service Manager]

RUN HISTORY:
- Step that fails: [Import/Sync/Export]
- Connector affected: [AD/AAD]
- Error count: [Number]

Please provide:
1. Identify which phase is failing
2. Common causes for this failure type
3. Connector-specific diagnostics
4. Object-level error investigation
5. Resolution procedure
6. Verify sync completes successfully
```

### Prompt 1.3: Sync Taking Too Long

```
Delta sync cycles are taking much longer than expected.

CURRENT TIMING:
- Normal delta sync time: [X minutes]
- Current delta sync time: [Y minutes]
- Full sync time: [If known]

ENVIRONMENT:
- Objects synced: [Count]
- Sync rules: [Custom rules?]
- Server resources: [CPU, RAM, disk]

Please provide:
1. Identify performance bottleneck
2. Check for large change sets
3. Analyze sync rule efficiency
4. Server resource assessment
5. Database maintenance needs
6. Optimization recommendations
```

---

## Section 2: Object-Level Sync Issues

### Prompt 2.1: Specific Object Not Syncing

```
A specific object is not syncing to Entra ID.

OBJECT DETAILS:
- Object type: [User/Group/Contact/Device]
- Distinguished Name: [DN]
- UPN/Name: [Identifier]
- In scope OU: [Yes/No/Unknown]

ON-PREMISES ATTRIBUTES:
[Key attributes if known]

Please provide:
1. Verify object is in sync scope
2. Check filtering rules
3. Look up object in Connector Space
4. Check for sync errors on object
5. Verify attribute requirements met
6. Trace sync rule application
7. Resolution based on findings
```

### Prompt 2.2: Object Syncing with Wrong Attributes

```
Object is syncing but attributes are incorrect in Entra ID.

OBJECT: [Identifier]
ATTRIBUTE: [Attribute name]
ON-PREM VALUE: [Value]
ENTRA VALUE: [Current value]
EXPECTED: [What it should be]

Please provide:
1. Check attribute flow rules
2. Verify source attribute has value
3. Check for transformation rules
4. Look for precedence conflicts
5. Check if attribute is in sync scope
6. Trace attribute through sync engine
7. Fix and verify attribute syncs correctly
```

### Prompt 2.3: Duplicate/Conflicting Objects

```
Sync is failing due to duplicate or conflicting objects.

ERROR: [Paste AttributeValueMustBeUnique or similar error]

CONFLICTING ATTRIBUTE: [e.g., proxyAddresses, UPN]
OBJECT 1: [DN or identifier]
OBJECT 2: [DN or identifier if known]

Please provide:
1. Identify both conflicting objects
2. Determine which is correct
3. Identify root cause of conflict
4. Resolution options
5. Prevent future conflicts
6. Verify sync after resolution
```

---

## Section 3: Export Errors

### Prompt 3.1: Export Error Analysis

```
I have export errors in Azure AD Connect.

EXPORT ERROR:
- Error type: [e.g., InvalidSoftMatch, AttributeValueMustBeUnique]
- Object: [DN]
- Attribute: [If applicable]
- Full error: [Paste error details]

Please provide:
1. Interpret this specific error
2. Root cause analysis
3. Resolution steps
4. How to prevent recurrence
5. Verify export succeeds after fix
```

### Prompt 3.2: Common Export Error Reference

```
Provide troubleshooting guidance for this export error:

ERROR CODE: [Error name or code]

Include:
1. What this error means
2. All possible causes
3. Diagnostic steps
4. Resolution for each cause
5. Prevention measures
```

### Export Error Quick Reference

| Error | Common Cause | Resolution |
|-------|--------------|------------|
| InvalidSoftMatch | No matching object in Entra | Create cloud object or fix matching attribute |
| AttributeValueMustBeUnique | Duplicate UPN/proxyAddress | Resolve duplicate in AD |
| DataValidationFailed | Invalid attribute format | Fix source attribute |
| LargeObject | Too many values (e.g., group members) | Split group or use group writeback |
| FederatedDomainChangeError | Domain change blocked | Follow federated domain change process |
| ObjectTypeMismatch | Type conflict | Resolve type conflict |
| InvalidHardMatch | ImmutableID conflict | Fix sourceAnchor/ImmutableID |

---

## Section 4: Filtering and Scoping

### Prompt 4.1: OU-Based Filtering Issues

```
Objects in certain OUs are not syncing as expected.

CURRENT OU FILTERING:
[Describe current configuration or paste from wizard]

SYMPTOM:
- OU expected to sync: [OU path]
- Objects in OU: [Count]
- Objects synced: [Count]

Please provide:
1. Verify OU filter configuration
2. Check for nested OU issues
3. Verify filter is applied to correct connector
4. Check if full sync needed after filter change
5. Verify objects appear in Connector Space
6. Resolution steps
```

### Prompt 4.2: Attribute-Based Filtering

```
I need to configure or troubleshoot attribute-based filtering.

REQUIREMENT:
[Describe what should/shouldn't sync]

CURRENT FILTERING:
[Describe current setup if any]

Please provide:
1. Design appropriate filtering rule
2. Implementation steps
3. Testing methodology
4. Impact on existing objects
5. Verification procedure
```

### Prompt 4.3: Group-Based Filtering

```
Group-based filtering is not working correctly.

PILOT GROUP: [Group name]
EXPECTED MEMBERS TO SYNC: [Count]
ACTUALLY SYNCING: [Count]

Please provide:
1. Verify group membership
2. Check group scoping configuration
3. Nested group considerations
4. Sync cycle after membership changes
5. Troubleshooting missing members
6. Resolution steps
```

---

## Section 5: Password Synchronization

### Prompt 5.1: Password Hash Sync Not Working

```
Password Hash Synchronization is failing.

SYMPTOMS:
- All users affected: [Yes/No]
- Specific users: [List if specific]
- Error events: [Paste if available]

CONFIGURATION:
- PHS enabled: [Confirmed]
- Service account: [Account name]

Please provide:
1. Verify PHS is enabled
2. Check service account permissions
3. Review password sync events (Event 656, 657)
4. Check domain controller connectivity
5. Verify password sync agent
6. Resolution steps
7. Force password sync if needed
```

### Prompt 5.2: Password Writeback Issues

```
Password writeback is not working.

SYMPTOMS:
- SSPR fails to write back: [Error message]
- Specific users or all: [Scope]

CONFIGURATION:
- Writeback enabled: [Yes]
- Service account permissions: [Verified?]

Please provide:
1. Verify writeback is enabled
2. Check connector account permissions
3. Verify network connectivity (443 outbound)
4. Check Azure AD Premium license
5. Review writeback events
6. Resolution steps
```

---

## Section 6: Connector Account Issues

### Prompt 6.1: AD Connector Account Problems

```
The AD connector account is having issues.

SYMPTOMS:
[Describe - access denied, password expired, etc.]

CURRENT ACCOUNT: [Account name]
PERMISSIONS: [If known]

Please provide:
1. Verify account exists and is enabled
2. Check password status
3. Verify required permissions
4. Check delegation settings
5. Reset or recreate account if needed
6. Update AAD Connect with new credentials
7. Verify sync works
```

### Prompt 6.2: AAD Connector Account Problems

```
The Azure AD connector account is having issues.

SYMPTOMS:
[Describe - authentication failures, permission issues]

ERROR:
[Paste error if available]

Please provide:
1. Verify account in Entra ID
2. Check account permissions (Global Admin or specific roles)
3. Check for MFA/CA blocking sync
4. Check for password expiration
5. Credential rotation procedure
6. Verify sync works after fix
```

---

## Section 7: High Availability and Staging

### Prompt 7.1: Staging Mode Configuration

```
I need to configure or troubleshoot staging mode.

SCENARIO:
- Current active server: [Name]
- Staging server: [Name]
- Purpose: [DR, upgrade, migration]

Please provide:
1. Verify staging mode configuration
2. Confirm staging server is syncing but not exporting
3. Test failover procedure
4. Activate staging server procedure
5. Verification steps
6. Best practices for staging mode
```

### Prompt 7.2: Promote Staging to Active

```
I need to promote the staging server to active.

REASON: [Planned failover, emergency, maintenance]
CURRENT ACTIVE: [Name - status]
STAGING SERVER: [Name]

Please provide:
1. Pre-promotion checklist
2. Disable active server
3. Enable export on staging server
4. Verify sync and export working
5. Update DNS/documentation
6. Post-promotion verification
7. Handle old active server
```

---

## Section 8: Upgrade and Migration

### Prompt 8.1: AAD Connect Upgrade Planning

```
I need to upgrade Azure AD Connect.

CURRENT VERSION: [Version]
TARGET VERSION: [Version]
CURRENT CONFIGURATION:
- Custom sync rules: [Yes/No, count]
- Staging server: [Available/Not]
- Password sync: [Enabled]
- Writeback features: [List]

Please provide:
1. Upgrade prerequisites
2. Backup current configuration
3. Upgrade procedure options (in-place, swing)
4. Verification after upgrade
5. Rollback procedure if needed
6. Best practices
```

### Prompt 8.2: V1 to V2 Migration (Cloud Sync)

```
I'm evaluating migration from AAD Connect to Cloud Sync.

CURRENT ENVIRONMENT:
- AAD Connect version: [Version]
- Features in use: [List - PHS, writeback, filtering, etc.]
- Custom sync rules: [Count]
- Hybrid Exchange: [Yes/No]

Please provide:
1. Cloud Sync feature comparison
2. What's supported vs. not supported
3. Migration path options
4. Pilot approach
5. Rollback considerations
6. Recommendation for my environment
```

---

## Quick Reference: AAD Connect Commands

```powershell
# === SYNC STATUS ===
Get-ADSyncScheduler
Get-ADSyncScheduler | Select-Object *

# Start sync cycles
Start-ADSyncSyncCycle -PolicyType Delta
Start-ADSyncSyncCycle -PolicyType Initial

# === CONNECTOR OPERATIONS ===
Get-ADSyncConnector
Get-ADSyncConnector | Select-Object Name, Type

# Get connector space object
$connector = Get-ADSyncConnector -Name "domain.com"
Get-ADSyncCSObject -ConnectorIdentifier $connector.Identifier -DistinguishedName "CN=user,OU=Users,DC=domain,DC=com"

# === METAVERSE ===
Get-ADSyncMVObject -Identifier <GUID>

# === SYNC RULES ===
Get-ADSyncRule | Select-Object Name, Direction, Priority
Get-ADSyncRule -Identifier <GUID>

# === PASSWORD SYNC ===
# Trigger password sync for specific user
$connector = Get-ADSyncConnector -Name "domain.com"
$csObject = Get-ADSyncCSObject -ConnectorIdentifier $connector.Identifier -DistinguishedName "CN=user,OU=Users,DC=domain,DC=com"
$csObject | Invoke-ADSyncCSObjectPasswordHashSync

# === DIAGNOSTICS ===
# Run diagnostics
Invoke-ADSyncDiagnostics -PasswordSync

# Export configuration for backup
Get-ADSyncServerConfiguration -Path "C:\AADConnectConfig"

# === STAGING MODE ===
# Check staging mode
(Get-ADSyncScheduler).StagingModeEnabled

# Enable staging mode (also doable via wizard)
Set-ADSyncScheduler -StagingModeEnabled $true

# Disable staging mode
Set-ADSyncScheduler -StagingModeEnabled $false
```

---

## Related Documents

- [Azure AD Hybrid](../02_ACTIVE_DIRECTORY/12-Azure-AD-Hybrid.md) - Hybrid identity overview
- [Pass-Through Authentication](pass_through_auth.md) - PTA troubleshooting
- [Hybrid Failure Modes](hybrid_failure_modes.md) - Common failure patterns

---

[Back to Main README](../README.md)
