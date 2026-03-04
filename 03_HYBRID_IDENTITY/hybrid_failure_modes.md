# Hybrid Identity Failure Modes

## Common Failure Patterns and Diagnostic Approaches

---

## Failure Mode Classification

```
HYBRID IDENTITY FAILURE CATEGORIES:

┌─────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FAILURES                      │
├─────────────────────────────────────────────────────────────────┤
│ • Cloud auth fails, on-prem works                               │
│ • On-prem auth fails, cloud works                               │
│ • Both fail (rare, catastrophic)                                │
│ • Intermittent failures                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SYNCHRONIZATION FAILURES                     │
├─────────────────────────────────────────────────────────────────┤
│ • Full sync failure                                             │
│ • Delta sync failure                                            │
│ • Object-specific sync failure                                  │
│ • Attribute-specific sync failure                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FEATURE-SPECIFIC FAILURES                    │
├─────────────────────────────────────────────────────────────────┤
│ • Password writeback failure                                    │
│ • Device writeback failure                                      │
│ • Group writeback failure                                       │
│ • Seamless SSO failure                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Section 1: Authentication Failure Patterns

### Pattern 1.1: Cloud Auth Fails, On-Prem Works

```
SYMPTOMS:
- Users can log into domain-joined computers
- Users cannot access Microsoft 365 / cloud apps
- On-prem applications work fine

POSSIBLE CAUSES & DIAGNOSTICS:

1. PASSWORD HASH SYNC ISSUE
   Check: Get-ADSyncScheduler
   Check: Password sync events (656, 657)
   Fix: Trigger password sync, verify PHS enabled

2. PTA AGENT FAILURE
   Check: Azure portal PTA agent status
   Check: Agent service on servers
   Fix: Restart agents, install additional agents

3. FEDERATION SERVICE DOWN
   Check: ADFS service status
   Check: ADFS endpoints accessibility
   Fix: Restore ADFS services

4. CONDITIONAL ACCESS BLOCKING
   Check: Sign-in logs for CA policy result
   Check: User not meeting CA requirements
   Fix: Adjust CA policy or user compliance

5. USER NOT SYNCED TO CLOUD
   Check: User exists in Entra ID
   Check: Sync errors for user
   Fix: Resolve sync issue

DECISION TREE:
On-prem auth works?
├── YES → Check cloud-specific auth method
│   ├── PHS → Check sync status
│   ├── PTA → Check agent status
│   └── Federation → Check ADFS
└── NO → This is an AD issue, not hybrid
```

### Pattern 1.2: Recent Password Change Not Working

```
SYMPTOMS:
- User changed password on-premises
- Old password still works in cloud
- New password not accepted in cloud

POSSIBLE CAUSES & DIAGNOSTICS:

1. PASSWORD SYNC DELAY
   Normal: Up to 2 minutes
   Check: Force sync cycle
   Wait: Allow sync to complete

2. PHS DISABLED OR FAILING
   Check: Password sync configuration
   Check: Event log for password sync errors
   Fix: Re-enable or troubleshoot PHS

3. SYNC CYCLE NOT RUNNING
   Check: Get-ADSyncScheduler
   Fix: Start sync cycle or fix scheduler

4. SPECIFIC USER SYNC ERROR
   Check: Connector space for user errors
   Check: Export errors for user
   Fix: Resolve user-specific sync issue

5. WRITE-BACK CONFLICT (if using SSPR)
   Check: Password writeback errors
   Check: Permissions on user object
   Fix: Resolve writeback configuration
```

### Pattern 1.3: Seamless SSO Not Working

```
SYMPTOMS:
- Users prompted for credentials when should have SSO
- Works for some users but not others
- Browser-specific behavior

POSSIBLE CAUSES & DIAGNOSTICS:

1. AZUREADSSOACC COMPUTER ACCOUNT ISSUE
   Check: Account exists in AD
   Check: Account password age (should be <30 days)
   Fix: Update SSO key

2. INTRANET ZONE NOT CONFIGURED
   Check: GPO for Intranet zone URLs
   Required: https://autologon.microsoftazuread-sso.com
   Fix: Deploy GPO for Intranet zone

3. BROWSER NOT CONFIGURED
   Check: Browser supports Kerberos/NTLM
   Check: Browser sends Windows auth
   Fix: Configure browser settings

4. DEVICE NOT DOMAIN-JOINED
   Check: Device join status
   Check: dsregcmd /status
   Fix: Join device to domain or Azure AD

5. KERBEROS TICKET NOT AVAILABLE
   Check: klist for SSO ticket
   Check: User can get tickets to other services
   Fix: Troubleshoot Kerberos issues
```

---

## Section 2: Synchronization Failure Patterns

### Pattern 2.1: Full Sync Failure

```
SYMPTOMS:
- Initial sync never completes
- Full sync required but fails
- Sync stuck for extended period

POSSIBLE CAUSES & DIAGNOSTICS:

1. DATABASE ISSUE
   Check: SQL connectivity (if remote SQL)
   Check: Database size and space
   Fix: Database maintenance or upgrade

2. LARGE ENVIRONMENT TIMEOUT
   Check: Object count
   Check: Sync rule complexity
   Fix: Optimize rules, increase resources

3. CONNECTOR ACCOUNT PERMISSIONS
   Check: AD connector account
   Check: Required permissions
   Fix: Grant required permissions

4. NETWORK CONNECTIVITY
   Check: DC accessibility
   Check: Entra ID connectivity
   Fix: Resolve network issues

RECOVERY APPROACH:
1. Stop sync scheduler
2. Clear run history if needed
3. Start with single OU/container
4. Gradually expand scope
5. Monitor progress
```

### Pattern 2.2: Delta Sync Working, Objects Missing

```
SYMPTOMS:
- Delta sync completes successfully
- Specific objects not in Entra ID
- No obvious errors

POSSIBLE CAUSES & DIAGNOSTICS:

1. OBJECT OUT OF SCOPE
   Check: OU filtering configuration
   Check: Object location vs. filter
   Fix: Add OU to scope or move object

2. ATTRIBUTE FILTERING
   Check: Attribute-based filtering rules
   Check: Object's attribute values
   Fix: Modify object or filtering

3. OBJECT TYPE NOT SYNCED
   Check: Object type (user, contact, group)
   Check: Sync rules for object type
   Fix: Enable sync for object type

4. SOFT MATCH FAILURE
   Check: Matching attributes (UPN, SMTP)
   Check: Existing cloud object conflict
   Fix: Enable hard match or resolve conflict

DIAGNOSTIC STEPS:
1. Search Connector Space for object
2. If not found → filtering issue
3. If found → check metaverse
4. If in metaverse → check export errors
```

### Pattern 2.3: Attribute Not Syncing

```
SYMPTOMS:
- Object syncs but specific attribute wrong
- Attribute has value on-prem, different/missing in cloud
- Affects specific attribute across users

POSSIBLE CAUSES & DIAGNOSTICS:

1. ATTRIBUTE NOT IN SYNC SCOPE
   Check: Attribute flow rules
   Check: Azure AD Connect schema
   Fix: Add attribute to sync

2. TRANSFORMATION ISSUE
   Check: Attribute flow expression
   Check: Source attribute format
   Fix: Correct transformation rule

3. PRECEDENCE CONFLICT
   Check: Multiple rules writing attribute
   Check: Rule precedence order
   Fix: Adjust precedence

4. CLOUD-AUTHORITATIVE ATTRIBUTE
   Check: If attribute is cloud-mastered
   Check: Directory extensions
   Fix: Change authoritative source

5. ATTRIBUTE FORMAT INVALID
   Check: Attribute value format
   Check: Export error for validation failure
   Fix: Correct source attribute format
```

---

## Section 3: Time-Based Failure Patterns

### Pattern 3.1: Failure After Certificate Expiration

```
TYPICAL TIMELINE:
Day -30: Certificate expiration warning (often ignored)
Day -7:  Another warning
Day 0:   Certificate expires at midnight
Day 0+:  Failures begin

AFFECTED CERTIFICATES:
- Azure AD Connect encryption certificate
- PTA agent certificate
- ADFS token signing certificate
- ADFS service communication certificate
- Seamless SSO computer account (not a cert but acts like one)

DIAGNOSTIC APPROACH:
1. Check all certificate expiration dates
2. Correlate failure start time with expirations
3. Identify which component's cert expired
4. Renew or roll over certificate
5. Restart affected services
6. Verify functionality restored
```

### Pattern 3.2: Failure After Password Expiration

```
SERVICE ACCOUNTS THAT CAN EXPIRE:
- AAD Connect AD service account
- AAD Connect Azure account (if password-based)
- PTA agent service account
- ADFS service account

SYMPTOMS:
- Sync stops working
- Authentication fails
- No recent changes, just stopped working

DIAGNOSTIC APPROACH:
1. Check account last password set date
2. Check account expiration settings
3. Check security event log for auth failures
4. Update password or set non-expiring
5. Update credentials in configuration
6. Verify functionality restored
```

### Pattern 3.3: Failure After Long Disconnect

```
SCENARIOS:
- DC offline for extended period
- AAD Connect server offline > tombstone lifetime
- Network partition lasting days

IMPACT:
- Objects may tombstone
- Replication may break
- Sync state may become invalid

RECOVERY APPROACH:
1. Assess duration of disconnect
2. Check for tombstoned objects
3. Check replication health
4. May need to reinitialize sync
5. May need to rebuild components
```

---

## Section 4: Multi-Factor Failure Patterns

### Pattern 4.1: Cascading Failure

```
EXAMPLE SCENARIO:
1. DNS server fails
2. AD cannot be located
3. AAD Connect cannot sync
4. PTA cannot reach AD
5. Cloud authentication fails
6. Users locked out everywhere

ROOT CAUSE: DNS, not identity

DIAGNOSTIC APPROACH:
1. Don't assume first symptom is root cause
2. Trace back to earliest failure
3. Check foundational services (DNS, network, DC)
4. Fix root cause first
5. Dependent services often auto-recover
```

### Pattern 4.2: Partial Failure

```
EXAMPLE SCENARIO:
- 50% of users can authenticate
- 50% cannot
- No obvious pattern

POSSIBLE CAUSES:
- Multi-DC environment with one DC failing
- Load balancer with unhealthy backend
- PTA with some agents failing
- Conditional Access affecting subset

DIAGNOSTIC APPROACH:
1. Find commonality in affected users
2. Check all redundant components
3. Identify the failing component
4. May be geographic, OU-based, or random
```

---

## Section 5: Recovery Procedures

### Recovery 5.1: Complete Hybrid Auth Failure

```
EMERGENCY RECOVERY PROCEDURE:

IMMEDIATE (0-5 minutes):
1. Confirm scope of failure
2. Check Microsoft service health
3. Communicate to stakeholders

SHORT-TERM (5-15 minutes):
1. If PTA failing → Check if PHS is backup → Enable PHS
2. If ADFS failing → Check WAP, ADFS servers
3. If AAD Connect failing → Check staging server

DIAGNOSIS (15-30 minutes):
1. Systematically check each component
2. Check event logs on all components
3. Check network connectivity
4. Identify failed component

RESOLUTION (varies):
1. Apply fix for identified component
2. Verify auth restored
3. Monitor for stability
4. Document incident
```

### Recovery 5.2: Sync Corruption/Invalid State

```
NUCLEAR OPTION - SYNC REBUILD:

When to consider:
- Sync database corrupted
- Sync state inconsistent
- Export errors cannot be resolved
- Guidance from Microsoft Support

PROCEDURE:
1. Document current configuration
2. Export custom sync rules
3. Record filtering configuration
4. Uninstall AAD Connect
5. Delete database (or start fresh)
6. Reinstall AAD Connect
7. Reconfigure settings
8. Import custom rules
9. Run initial full sync
10. Verify all objects sync correctly

WARNING: This is disruptive and time-consuming
Only use when other options exhausted
```

---

## Failure Mode Quick Reference

| Symptom | Likely Cause | First Check |
|---------|--------------|-------------|
| Cloud auth fails, on-prem works | PHS/PTA/ADFS issue | Auth method status |
| Password change not syncing | PHS issue | Sync cycle, PHS events |
| New user can't access cloud | Sync not complete | Wait or force sync |
| SSO not working | Browser/Kerberos/SSO config | Intranet zone, klist |
| Intermittent cloud auth | PTA agent instability | Agent health in portal |
| Sync stopped completely | Scheduler, permissions, network | Get-ADSyncScheduler |
| Export errors accumulating | Attribute conflicts | Sync Service Manager |
| Object not appearing | Filtering, scope | Connector Space search |

---

## Related Documents

- [Entra Connect](entra_connect.md) - Sync troubleshooting
- [Pass-Through Authentication](pass_through_auth.md) - PTA specifics
- [Timeline Reconstruction](../01_IDENTITY_P0_COMMAND/timeline_reconstruction.md) - Finding root cause

---

[Back to Main README](../README.md)
