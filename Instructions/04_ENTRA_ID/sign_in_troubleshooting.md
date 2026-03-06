# Entra ID Sign-In Troubleshooting

## Diagnosing Authentication Failures in Azure AD / Entra ID

---

## Sign-In Log Analysis Framework

### Understanding Sign-In Logs

```
SIGN-IN LOG ANATOMY:

Every sign-in attempt generates a log entry containing:

┌─────────────────────────────────────────────────────────────────┐
│ IDENTITY INFORMATION                                            │
├─────────────────────────────────────────────────────────────────┤
│ • User Principal Name                                           │
│ • User ID (Object ID)                                           │
│ • User type (Member/Guest)                                      │
│ • Home tenant                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│ REQUEST INFORMATION                                             │
├─────────────────────────────────────────────────────────────────┤
│ • Timestamp (UTC)                                               │
│ • Request ID (unique identifier)                                │
│ • Correlation ID (links related requests)                       │
│ • Application (what they're signing into)                       │
│ • Resource (what they're accessing)                             │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│ CONTEXT INFORMATION                                             │
├─────────────────────────────────────────────────────────────────┤
│ • IP Address                                                    │
│ • Location (derived from IP)                                    │
│ • Device info (OS, browser, compliance)                         │
│ • Client app (browser, mobile app, desktop)                     │
│ • Authentication method used                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│ RESULT INFORMATION                                              │
├─────────────────────────────────────────────────────────────────┤
│ • Status (Success/Failure/Interrupted)                          │
│ • Error code (AADSTS*)                                          │
│ • Failure reason                                                │
│ • Conditional Access result                                     │
│ • MFA result                                                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Section 1: Error Code Analysis

### Prompt 1.1: AADSTS Error Code Diagnosis

```
I need to troubleshoot this Entra ID sign-in error.

ERROR CODE: AADSTS[number]
FULL ERROR MESSAGE: [Paste complete error]

CONTEXT:
- User: [UPN]
- Application: [App name]
- Time: [When]
- Frequency: [One-time/recurring]

Please provide:
1. What this error code means
2. Common causes for this error
3. Diagnostic steps specific to this error
4. Resolution procedure
5. How to prevent recurrence
```

### Common AADSTS Error Reference

```
AUTHENTICATION ERRORS:

AADSTS50126 - Invalid username or password
├── Cause: Wrong credentials entered
├── Check: User account status, password correct
└── Fix: Reset password, verify UPN

AADSTS50076 - MFA required
├── Cause: User needs to complete MFA
├── Check: MFA registration status
└── Fix: Complete MFA, check MFA methods

AADSTS50079 - User needs to enroll in MFA
├── Cause: MFA required but not registered
├── Check: MFA registration
└── Fix: Register MFA method

AADSTS53003 - Blocked by Conditional Access
├── Cause: CA policy blocking access
├── Check: Which CA policy, what condition failed
└── Fix: Meet CA requirements or adjust policy

AADSTS50105 - User not assigned to application
├── Cause: User lacks app assignment
├── Check: Enterprise app user assignment
└── Fix: Assign user to application

AADSTS700016 - Application not found
├── Cause: App ID incorrect or deleted
├── Check: App registration exists
└── Fix: Correct app ID or recreate app

AADSTS7000218 - Invalid client secret
├── Cause: Client secret wrong or expired
├── Check: Secret expiration, correct value
└── Fix: Rotate client secret

AADSTS90002 - Tenant not found
├── Cause: Invalid tenant ID/name
├── Check: Tenant identifier
└── Fix: Correct tenant reference

ACCOUNT STATE ERRORS:

AADSTS50057 - User account disabled
├── Check: Account enabled status
└── Fix: Enable account

AADSTS50053 - Account locked
├── Check: Smart lockout status
└── Fix: Wait for lockout expiry or admin unlock

AADSTS50055 - Password expired
├── Check: Password expiration
└── Fix: Reset password

AADSTS50058 - Silent sign-in failed
├── Cause: No active session, refresh token invalid
├── Check: Session/token state
└── Fix: Interactive sign-in required

TOKEN ERRORS:

AADSTS50013 - Invalid assertion/token
├── Cause: Token malformed or expired
├── Check: Token contents, expiration
└── Fix: Request new token

AADSTS50173 - Fresh credential required
├── Cause: Risky sign-in detected
├── Check: Risk detection
└── Fix: Re-authenticate

AADSTS70001 - Application disabled
├── Check: App enabled for users
└── Fix: Enable application
```

---

## Section 2: Conditional Access Troubleshooting

### Prompt 2.1: CA Policy Blocking Access

```
A user is being blocked by Conditional Access.

USER: [UPN]
APPLICATION: [App name]
ERROR: AADSTS53003 or "Access Denied"

SIGN-IN LOG DETAILS:
- CA policies applied: [If visible]
- Failure reason: [From log]

USER CONTEXT:
- Device: [Managed/Personal/Unknown]
- Location: [Office/Remote/Travel]
- Client app: [Browser/Mobile/Desktop]

Please provide:
1. Identify which CA policy is blocking
2. Determine which condition failed
3. User remediation options
4. Policy adjustment options (if policy is wrong)
5. Verification after resolution
```

### Prompt 2.2: CA Policy Design Review

```
I need to review/design Conditional Access policies.

REQUIREMENTS:
[Describe access requirements]

CURRENT POLICIES:
[List existing policies if any]

USER POPULATION:
- Total users: [Count]
- User types: [Internal, guest, external]
- Device types: [Managed, BYOD, etc.]

Please provide:
1. Recommended policy structure
2. Specific policy configurations
3. Grant controls appropriate for each scenario
4. Session controls if needed
5. Testing approach before rollout
6. Emergency access account considerations
```

### Prompt 2.3: CA What-If Analysis

```
I want to test what would happen with CA policies.

SCENARIO:
- User: [UPN or type]
- Application: [App]
- Device platform: [Windows/iOS/Android/etc.]
- Device state: [Compliant/Domain-joined/etc.]
- Location: [Named location or IP]
- Client app: [Browser/Mobile/Desktop]

Please provide:
1. How to use What-If tool
2. Expected policy evaluation
3. Which policies would apply
4. Expected result (block/allow/MFA)
5. How to interpret results
```

---

## Section 3: MFA Troubleshooting

### Prompt 3.1: MFA Registration Issues

```
User cannot register for MFA.

USER: [UPN]
SYMPTOMS:
[Describe what happens when trying to register]

MFA CONFIGURATION:
- Required methods: [If known]
- Combined registration: [Enabled/Disabled]

Please provide:
1. Check MFA registration status
2. Verify user is in scope for MFA
3. Check for registration restrictions
4. Verify authentication methods policy
5. Troubleshoot specific registration errors
6. Complete registration
```

### Prompt 3.2: MFA Authentication Failures

```
User cannot complete MFA challenge.

USER: [UPN]
MFA METHOD: [App/SMS/Call/FIDO2/etc.]
ERROR: [What happens]

SYMPTOMS:
- Code not received
- Code doesn't work
- App not prompting
- Timeout errors

Please provide:
1. Verify MFA method is registered
2. Check method-specific issues
3. Network/carrier issues for SMS/call
4. App configuration issues
5. Reset MFA if needed
6. Register alternative method
```

### Prompt 3.3: MFA Reset Procedure

```
I need to reset MFA for a user.

USER: [UPN]
REASON: [Lost phone, new device, locked out, etc.]
VERIFICATION: [How user identity was verified]

Please provide:
1. Reset all MFA methods
2. Require re-registration at next sign-in
3. Consider temporary access pass if needed
4. Security considerations
5. User communication
6. Verify user can access after reset
```

---

## Section 4: Application Access Issues

### Prompt 4.1: User Cannot Access Application

```
User cannot access a specific application.

USER: [UPN]
APPLICATION: [App name]
ERROR: [Error message or behavior]

CHECKS COMPLETED:
- User can sign into other apps: [Yes/No]
- Other users can access this app: [Yes/No]

Please provide:
1. Check user assignment to application
2. Check application-specific permissions
3. Review Conditional Access for this app
4. Check app-level access requirements
5. Verify application configuration
6. Resolution steps
```

### Prompt 4.2: Application Registration Issues

```
Application registration is not working correctly.

APPLICATION: [App name/ID]
SYMPTOMS: [What's not working]

CONFIGURATION:
- App type: [Single tenant/Multi-tenant]
- Auth flow: [Authorization code/Client credentials/etc.]

Please provide:
1. Verify app registration configuration
2. Check redirect URIs
3. Verify API permissions and consent
4. Check client credentials if applicable
5. Token configuration review
6. Fix and verify application works
```

---

## Section 5: Guest/External User Issues

### Prompt 5.1: Guest User Cannot Access Resources

```
A guest user cannot access shared resources.

GUEST USER: [Email]
INVITED BY: [If known]
RESOURCE: [What they're trying to access]
ERROR: [Error message]

Please provide:
1. Verify guest account exists and is enabled
2. Check invitation redemption status
3. Verify external access settings
4. Check resource-specific permissions
5. Review cross-tenant access policies
6. Resolution steps
```

### Prompt 5.2: B2B Collaboration Issues

```
B2B collaboration is not working as expected.

SCENARIO:
[Describe collaboration scenario]

EXTERNAL ORGANIZATION: [Partner tenant]
ACCESS REQUIREMENTS: [What access is needed]

CURRENT CONFIGURATION:
- External collaboration settings: [Status]
- Cross-tenant access policies: [Status]

Please provide:
1. Review external collaboration settings
2. Check cross-tenant access policies
3. Verify guest invitation settings
4. Check Conditional Access for guests
5. Troubleshoot specific scenario
6. Resolution and verification
```

---

## Section 6: Token and Session Issues

### Prompt 6.1: Token Acquisition Failures

```
Application cannot acquire tokens.

APPLICATION: [App name]
FLOW: [Auth code/Client credentials/On-behalf-of/etc.]
ERROR: [Error message]

OBSERVED BEHAVIOR:
[Describe what happens]

Please provide:
1. Verify token endpoint being used
2. Check client credentials
3. Verify required permissions
4. Check consent status
5. Analyze token request
6. Fix and verify token acquisition
```

### Prompt 6.2: Session/Refresh Token Issues

```
Users are being signed out unexpectedly.

SYMPTOMS:
- Frequency: [How often]
- Affected users: [Scope]
- Applications affected: [Which apps]

POSSIBLE TRIGGERS:
[Any recent changes?]

Please provide:
1. Check session lifetime policies
2. Review CAE (Continuous Access Evaluation)
3. Check token lifetime configuration
4. Check for revocation events
5. Review sign-in frequency policies
6. Resolution based on findings
```

---

## Section 7: Investigation Queries

### KQL Queries for Sign-In Analysis

```kusto
// Failed sign-ins in last 24 hours
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType != "0"
| project TimeGenerated, UserPrincipalName, AppDisplayName, ResultType, ResultDescription, IPAddress, Location
| order by TimeGenerated desc

// Sign-ins blocked by Conditional Access
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType == "53003"
| project TimeGenerated, UserPrincipalName, AppDisplayName, ConditionalAccessPolicies, Location
| order by TimeGenerated desc

// MFA failures
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType in ("50074", "50076", "50079", "50072")
| project TimeGenerated, UserPrincipalName, AppDisplayName, ResultType, ResultDescription, AuthenticationRequirement
| order by TimeGenerated desc

// Sign-ins for specific user
SigninLogs
| where TimeGenerated > ago(7d)
| where UserPrincipalName =~ "user@domain.com"
| project TimeGenerated, AppDisplayName, ResultType, ResultDescription, IPAddress, DeviceDetail
| order by TimeGenerated desc

// Risky sign-ins
SigninLogs
| where TimeGenerated > ago(24h)
| where RiskLevelDuringSignIn != "none"
| project TimeGenerated, UserPrincipalName, RiskLevelDuringSignIn, RiskState, IPAddress, Location
| order by TimeGenerated desc
```

### PowerShell Graph Queries

```powershell
# Get recent sign-in logs (requires appropriate permissions)
$signIns = Get-MgAuditLogSignIn -Filter "createdDateTime ge 2024-01-01" -Top 100

# Failed sign-ins
$signIns | Where-Object { $_.Status.ErrorCode -ne 0 } |
    Select-Object CreatedDateTime, UserPrincipalName, AppDisplayName, Status

# Get user's sign-in activity
$userSignIns = Get-MgAuditLogSignIn -Filter "userPrincipalName eq 'user@domain.com'" -Top 50

# Check Conditional Access results
$signIns | Select-Object -ExpandProperty ConditionalAccessPolicies |
    Where-Object { $_.Result -eq 'failure' }
```

---

## Quick Reference: Sign-In Log Fields

| Field | Description |
|-------|-------------|
| correlationId | Links related sign-in events |
| requestId | Unique identifier for request |
| userPrincipalName | User's UPN |
| appDisplayName | Application name |
| resourceDisplayName | Resource being accessed |
| status.errorCode | Error code (0 = success) |
| conditionalAccessStatus | notApplied/success/failure |
| ipAddress | Client IP |
| location | Derived location |
| deviceDetail | Device information |
| authenticationRequirement | singleFactorAuthentication/multiFactorAuthentication |
| riskDetail | Risk detection information |

---

## Related Documents

- [Error Codes Reference](error_codes_reference.md) - Complete AADSTS codes
- [Conditional Access Designer](conditional_access_designer.md) - CA policy design
- [Hybrid Failure Modes](../03_HYBRID_IDENTITY/hybrid_failure_modes.md) - Hybrid auth issues

---

[Back to Main README](../README.md)
