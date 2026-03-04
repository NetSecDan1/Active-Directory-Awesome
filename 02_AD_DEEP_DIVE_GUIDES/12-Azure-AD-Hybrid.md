# Azure AD & Hybrid Identity Troubleshooting

## AI Prompts for Hybrid Identity and Azure AD Connect Issues

---

## Overview

Hybrid identity environments connect on-premises Active Directory with Azure AD (Entra ID), enabling single sign-on and unified identity management. Synchronization issues, authentication problems, and configuration errors can significantly impact user productivity. This module provides AI prompts for hybrid identity troubleshooting.

---

## Section 1: Azure AD Connect Health Assessment

### Prompt 1.1: AAD Connect Sync Health Check

```
I need to assess the health of Azure AD Connect synchronization.

ENVIRONMENT:
- AAD Connect version: [Version]
- Sync mode: [Password Hash Sync/Pass-through Auth/Federation]
- Staging server: [Yes/No]
- Number of forests synced: [X]
- Objects synced: [Approximate count]

CURRENT CONCERNS:
[Describe any known issues]

Please provide:
1. AAD Connect service health verification
2. Sync cycle status check
3. Export error analysis
4. Connector space health
5. Password sync verification (if applicable)
6. AAD Connect Health portal check
7. Common issues to look for
```

### Prompt 1.2: Sync Cycle Troubleshooting

```
Azure AD Connect sync cycles are failing or showing errors.

ERROR MESSAGES:
[Paste sync errors from event log or Synchronization Service Manager]

SYNC STATUS:
- Last successful sync: [Date/time]
- Delta sync working: [Yes/No]
- Full sync required: [Yes/No]

Please provide:
1. Interpret the sync error messages
2. Identify root cause
3. Resolution steps for this specific error
4. Force sync after fix
5. Verify sync is working
6. Prevention measures
7. When to escalate to Microsoft
```

---

## Section 2: Synchronization Issues

### Prompt 2.1: Objects Not Syncing

```
Specific objects are not synchronizing to Azure AD.

AFFECTED OBJECTS:
- Type: [Users/Groups/Contacts/Devices]
- Count: [X objects]
- Examples: [Sample object names]

EXPECTED BEHAVIOR:
[What should sync]

FILTERING IN PLACE:
- OU filtering: [Describe]
- Attribute filtering: [Describe]
- Group filtering: [If used]

Please provide:
1. Verify object is in sync scope
2. Check for sync errors on object
3. Connector space object status
4. Metaverse object check
5. Common reasons for sync exclusion
6. Resolution based on findings
7. Verification after fix
```

### Prompt 2.2: Attribute Sync Issues

```
Specific attributes are not syncing correctly.

ATTRIBUTE: [Attribute name]
SOURCE VALUE: [On-premises value]
AZURE AD VALUE: [Current Azure AD value]
EXPECTED: [What it should be]

SYNC RULE:
[Default or custom rules if known]

Please provide:
1. Attribute flow analysis
2. Checking sync rule configuration
3. Transformation issues
4. Precedence conflicts
5. Modifying attribute flow
6. Testing attribute sync
7. Verification in Azure AD
```

### Prompt 2.3: Export Errors

```
I'm getting export errors in Azure AD Connect.

ERROR TYPE: [Permission issue, data validation, duplicate, etc.]
ERROR MESSAGE:
[Paste full error]

AFFECTED OBJECT:
[Object DN or name]

Please provide:
1. Interpret the export error
2. Common causes for this error type
3. Diagnostic steps
4. Resolution procedure
5. Preventing recurrence
6. Handling bulk export errors
7. When to open support case
```

---

## Section 3: Password Synchronization

### Prompt 3.1: Password Hash Sync Not Working

```
Password Hash Synchronization is not working.

SYMPTOMS:
- New passwords not syncing: [Yes/No]
- All passwords affected: [Yes/No]
- Specific users affected: [List if applicable]

CONFIGURATION:
- PHS enabled: [Confirmed]
- AAD Connect version: [Version]

ERROR MESSAGES:
[Paste any password sync related errors]

Please provide:
1. Password sync prerequisites verification
2. Service account permissions check
3. Password sync troubleshooting steps
4. Event log analysis
5. Force password sync
6. Verification of sync working
7. Common PHS issues and resolutions
```

### Prompt 3.2: Password Writeback Issues

```
Password writeback is not functioning.

SYMPTOMS:
[Describe - SSPR not writing back, errors on reset]

CONFIGURATION:
- Writeback enabled: [Yes]
- Azure AD Premium license: [Confirmed]
- SSPR enabled: [Yes]

ERROR:
[Paste error message if available]

Please provide:
1. Password writeback prerequisites
2. Connector account permissions
3. Firewall/proxy requirements
4. Troubleshooting writeback failures
5. Testing writeback
6. Common writeback issues
7. Verification after fix
```

---

## Section 4: Pass-Through Authentication

### Prompt 4.1: PTA Agent Issues

```
Pass-through Authentication agents are not working.

SYMPTOMS:
- Authentication failures: [Describe]
- Agent status in portal: [Status]
- Number of agents: [X]

AGENT SERVERS:
[List servers with PTA agents]

ERRORS:
[Paste relevant errors]

Please provide:
1. PTA agent health check
2. Connectivity requirements
3. Agent log analysis
4. Troubleshooting agent issues
5. Agent reinstallation procedure
6. High availability verification
7. Failover testing
```

### Prompt 4.2: PTA vs. PHS Failover

```
I need to configure or troubleshoot PTA/PHS failover.

CURRENT CONFIGURATION:
- Primary: [PTA/PHS]
- Failover: [Configured/Not configured]
- Agent count: [If PTA]

CONCERN:
[Describe issue or goal]

Please provide:
1. PTA/PHS failover explained
2. Configuring staged rollout
3. Emergency PHS enablement
4. Testing failover
5. Monitoring for failures
6. User communication
7. Best practices for resilience
```

---

## Section 5: Federation (AD FS)

### Prompt 5.1: AD FS Authentication Issues

```
AD FS authentication for Azure AD is failing.

SYMPTOMS:
[Describe authentication failures]

AD FS INFRASTRUCTURE:
- AD FS servers: [Count]
- WAP servers: [Count]
- Certificate status: [Valid/Expiring/Expired]

ERROR:
[Paste error message]

Please provide:
1. AD FS service health check
2. Certificate verification
3. Federation metadata verification
4. Token issuance troubleshooting
5. Claims rule analysis
6. WAP connectivity
7. Resolution steps
```

### Prompt 5.2: AD FS to Cloud Auth Migration

```
I'm planning to migrate from AD FS to cloud authentication.

CURRENT STATE:
- AD FS version: [Version]
- Applications using AD FS: [Count/List]
- Customizations: [Describe claims rules, MFA, etc.]

TARGET STATE:
- Authentication method: [PHS/PTA]
- Timeline: [Planned timeline]

Please provide:
1. Migration planning checklist
2. Application compatibility assessment
3. Staged rollout procedure
4. Cutover procedure
5. Rollback plan
6. Testing strategy
7. User communication plan
```

---

## Section 6: Hybrid Azure AD Join

### Prompt 6.1: Hybrid Azure AD Join Issues

```
Devices are not completing Hybrid Azure AD Join.

AFFECTED DEVICES:
- Device type: [Windows 10/11, Windows Server]
- Count: [X devices]
- Domain: [Domain name]

SYMPTOMS:
- dsregcmd status: [Paste output]
- Event log errors: [Paste if available]

CONFIGURATION:
- SCP configured: [Yes/No]
- Device sync enabled: [Yes/No]

Please provide:
1. Hybrid join prerequisites check
2. SCP configuration verification
3. Device registration troubleshooting
4. Common registration failures
5. Certificate requirements (if applicable)
6. Sync verification for device objects
7. Resolution steps
```

### Prompt 6.2: Device Writeback Configuration

```
I need to configure or troubleshoot device writeback.

PURPOSE:
[Conditional Access, device-based policies, etc.]

CURRENT STATE:
- Device writeback enabled: [Yes/No]
- Device sync working: [Yes/No]

ISSUE (if troubleshooting):
[Describe the problem]

Please provide:
1. Device writeback requirements
2. Configuration procedure
3. Container permissions
4. Verification of writeback
5. Common issues and resolutions
6. Impact on on-premises AD
7. Best practices
```

---

## Section 7: Seamless SSO

### Prompt 7.1: Seamless SSO Not Working

```
Seamless Single Sign-On is not working.

SYMPTOMS:
- Users prompted for credentials: [When/Where]
- Affected users: [Scope]
- Browser: [Which browsers affected]

CONFIGURATION:
- SSO enabled: [Yes]
- Computer account: [AZUREADSSOACC status]
- GPO deployed: [Yes/No]

Please provide:
1. Seamless SSO prerequisites
2. Kerberos ticket verification
3. Computer account password age
4. Browser configuration verification
5. Intranet zone settings
6. Troubleshooting steps
7. Resolution and verification
```

### Prompt 7.2: Seamless SSO Key Rollover

```
I need to perform Seamless SSO key rollover.

REASON: [Routine, security concern, troubleshooting]
CURRENT KEY AGE: [If known]

Please provide:
1. Key rollover importance
2. Rollover procedure
3. Impact during rollover
4. Verification after rollover
5. Recommended rollover schedule
6. Automation options
7. Monitoring key health
```

---

## Section 8: Troubleshooting Tools

### Prompt 8.1: AAD Connect Diagnostic Commands

```
I need to run diagnostics on Azure AD Connect.

ISSUE TYPE:
[Describe what you're troubleshooting]

Please provide:
1. Synchronization Service Manager usage
2. PowerShell diagnostic commands
3. Event log locations
4. Connector space queries
5. Metaverse queries
6. AAD Connect wizard troubleshooter
7. Debug logging enablement
```

### Prompt 8.2: Hybrid Identity Diagnostic Script

```
Create a PowerShell script for hybrid identity diagnostics:

REQUIREMENTS:
1. Check AAD Connect service status
2. Verify last sync cycle
3. Check for export errors
4. Verify password sync status
5. Check PTA agent status
6. Verify SSO computer account
7. Generate summary report

Include error handling and documentation.
```

---

## Section 9: Emergency Procedures

### Prompt 9.1: AAD Connect Emergency Recovery

```
EMERGENCY: Azure AD Connect is down and needs recovery.

SITUATION:
[Describe - server crash, corruption, etc.]

STAGING SERVER: [Available/Not available]
LAST KNOWN GOOD BACKUP: [Date]

IMPACT:
[Describe sync delay impact]

Please provide:
1. Immediate mitigation steps
2. Staging server activation
3. Rebuilding AAD Connect if needed
4. Database recovery options
5. Preserving sync configuration
6. Verification after recovery
7. Preventing future outages
```

### Prompt 9.2: Break-Glass Azure AD Access

```
I need emergency access to Azure AD during hybrid issues.

SCENARIO:
[Describe - AD FS down, AAD Connect issues, etc.]

CURRENT ACCESS METHODS:
[What's working/not working]

Please provide:
1. Emergency access account setup
2. Cloud-only admin access
3. Bypassing federation temporarily
4. PHS emergency enablement
5. Staged rollout for bypass
6. Recovery procedures
7. Post-incident hardening
```

---

## Quick Reference: AAD Connect Commands

```powershell
# === SYNC STATUS ===

# Check sync cycle status
Get-ADSyncScheduler

# Start delta sync
Start-ADSyncSyncCycle -PolicyType Delta

# Start full sync
Start-ADSyncSyncCycle -PolicyType Initial

# === CONNECTOR OPERATIONS ===

# Get connectors
Get-ADSyncConnector

# Get connector space objects
Get-ADSyncCSObject -ConnectorName "domain.com" -DistinguishedName "CN=User,OU=Users,DC=domain,DC=com"

# === PASSWORD SYNC ===

# Get password sync status
Get-ADSyncAADPasswordSyncConfiguration

# Trigger password sync for user
Invoke-ADSyncCSObjectPasswordHashSync -ConnectorName "domain.com" -DistinguishedName "CN=User,OU=Users,DC=domain,DC=com"

# === DIAGNOSTICS ===

# Run connectivity test
Start-ADSyncDiagnostics

# Export configuration
Get-ADSyncServerConfiguration -Path "C:\AADConnect_Config"

# === SSO ===

# Get SSO status
Get-AzureADSSOAccountStatus

# Roll over SSO key
Update-AzureADSSOForest -OnPremCredentials $creds

# === DEVICE STATUS (on client) ===

# Check device registration status
dsregcmd /status

# Check SSO state
dsregcmd /status | findstr SSOState
```

---

## Common Sync Error Reference

| Error | Common Cause | Resolution |
|-------|--------------|------------|
| AttributeValueMustBeUnique | Duplicate UPN or proxyAddress | Resolve duplicate |
| InvalidSoftMatch | No matching object found | Verify matching attributes |
| DataValidationFailed | Invalid attribute value | Fix source attribute |
| LargeObject | Object exceeds size limits | Reduce group members |
| FederatedDomainChangeError | Domain change blocked | Use proper procedure |
| ObjectTypeMismatch | Object type conflict | Resolve type mismatch |

---

## Related Modules

- [Authentication & Kerberos](02-Authentication-Kerberos.md) - Authentication protocols
- [DNS Integration](03-DNS-Integration.md) - DNS for hybrid scenarios
- [Account Management & Lockouts](13-Account-Management-Lockouts.md) - Account sync issues

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
