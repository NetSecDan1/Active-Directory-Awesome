# Conditional Access Policy Designer

## AI-Assisted CA Policy Design and Troubleshooting

---

## CA Policy Architecture

```
CONDITIONAL ACCESS EVALUATION FLOW:

User Sign-in Attempt
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│                    SIGNAL COLLECTION                          │
│  • User/Group membership                                      │
│  • Application being accessed                                 │
│  • Device state (compliant, hybrid joined, etc.)             │
│  • Location (IP, named locations)                            │
│  • Risk level (user risk, sign-in risk)                      │
│  • Client application type                                    │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│                    POLICY EVALUATION                          │
│  For each policy where assignments match:                     │
│  • If conditions met AND access controls not satisfied        │
│    → Policy triggers                                          │
│  • Multiple policies can apply (most restrictive wins)        │
└───────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│                    DECISION                                   │
│  • GRANT: All required controls satisfied                     │
│  • BLOCK: Access denied                                       │
│  • REQUIRE: Must satisfy controls (MFA, device, etc.)        │
└───────────────────────────────────────────────────────────────┘
```

---

## Section 1: Policy Design Prompts

### Prompt 1.1: Design CA Policy for Requirement

```
I need to create a Conditional Access policy.

REQUIREMENT:
[Describe what you want to achieve - who, what, when, how]

ENVIRONMENT:
- Users affected: [Scope]
- Applications: [Which apps]
- Devices: [Managed/BYOD/Both]
- Current policies: [Existing policies if relevant]

CONSTRAINTS:
- Must not break: [Critical workflows]
- Exception groups needed: [Yes/No]
- Pilot before rollout: [Yes/No]

Please provide:
1. Recommended policy design
2. Assignment configuration (users, apps, conditions)
3. Grant/session controls
4. Exception handling (break-glass accounts)
5. Deployment approach (report-only first)
6. Testing and validation steps
```

### Prompt 1.2: Review Existing CA Policies

```
I need to review my Conditional Access policies for gaps or issues.

CURRENT POLICIES:
[List policies with brief descriptions]

SECURITY REQUIREMENTS:
- MFA: [Requirements]
- Device compliance: [Requirements]
- Location restrictions: [Requirements]
- Application protection: [Requirements]

CONCERNS:
[Any specific concerns or incidents]

Please provide:
1. Gap analysis against requirements
2. Overlap/conflict identification
3. Potential bypasses
4. Optimization recommendations
5. Missing baseline policies
6. Prioritized action items
```

---

## Section 2: Common Policy Templates

### Template: Require MFA for All Users

```
POLICY: Require MFA for All Users

ASSIGNMENTS:
├── Users: All users
├── Exclude:
│   ├── Emergency access accounts
│   └── Service accounts (if needed)
├── Cloud apps: All cloud apps
└── Conditions: None (always applies)

ACCESS CONTROLS:
├── Grant: Require multi-factor authentication
└── Session: None

ENABLE: Report-only → On

NOTES:
- Ensure all users have MFA registered before enabling
- Test with pilot group first
- Emergency access accounts must be excluded
```

### Template: Block Legacy Authentication

```
POLICY: Block Legacy Authentication

ASSIGNMENTS:
├── Users: All users
├── Exclude:
│   └── Service accounts requiring legacy (document & plan migration)
├── Cloud apps: All cloud apps
└── Conditions:
    └── Client apps:
        ├── Exchange ActiveSync clients
        └── Other clients

ACCESS CONTROLS:
├── Grant: Block access
└── Session: None

ENABLE: Report-only → On

NOTES:
- Review sign-in logs for legacy auth usage first
- Communicate to users about app upgrades
- Critical for security baseline
```

### Template: Require Compliant Device for Sensitive Apps

```
POLICY: Require Compliant Device for Sensitive Applications

ASSIGNMENTS:
├── Users: All users
├── Exclude:
│   ├── Emergency access accounts
│   └── Guest users (separate policy)
├── Cloud apps:
│   ├── Microsoft 365
│   ├── [Sensitive App 1]
│   └── [Sensitive App 2]
└── Conditions:
    └── Device platforms: All platforms

ACCESS CONTROLS:
├── Grant:
│   ├── Require device to be marked as compliant
│   └── OR Require Hybrid Azure AD joined device
└── Session: None

ENABLE: Report-only → On

NOTES:
- Requires Intune enrollment for compliance
- Users with non-managed devices will be blocked
- Consider app protection policies for BYOD alternative
```

### Template: Block Access from Untrusted Locations

```
POLICY: Block Access Outside Corporate Network for High-Risk Apps

ASSIGNMENTS:
├── Users: All users
├── Exclude:
│   ├── Emergency access accounts
│   └── Executives (with separate MFA-only policy)
├── Cloud apps:
│   └── [High-sensitivity applications]
└── Conditions:
    └── Locations:
        └── Exclude: Trusted locations (corporate IPs)

ACCESS CONTROLS:
├── Grant: Block access
└── Session: None

ALTERNATIVE (Allow with controls):
├── Grant:
│   ├── Require MFA
│   └── AND Require compliant device

NOTES:
- Define named locations first
- Consider VPN IPs as trusted
- May impact remote workers - have alternative
```

### Template: Require MFA for Risky Sign-ins

```
POLICY: Require MFA for Medium and High Risk Sign-ins

ASSIGNMENTS:
├── Users: All users
├── Exclude:
│   └── Emergency access accounts
├── Cloud apps: All cloud apps
└── Conditions:
    └── Sign-in risk: Medium and High

ACCESS CONTROLS:
├── Grant: Require multi-factor authentication
└── Session: Sign-in frequency: 1 hour

ENABLE: On (risk policies are generally safe to enable)

NOTES:
- Requires Azure AD Premium P2
- Works with Identity Protection
- Lower risk than blanket MFA requirement
- Users only prompted when risk detected
```

---

## Section 3: Policy Troubleshooting

### Prompt 3.1: Policy Not Applying as Expected

```
A Conditional Access policy is not working as intended.

POLICY NAME: [Name]
EXPECTED BEHAVIOR: [What should happen]
ACTUAL BEHAVIOR: [What is happening]

USER TEST CASE:
- User: [UPN]
- Application: [App]
- Device: [Type/State]
- Location: [Where]

SIGN-IN LOG RESULT:
- CA Status: [Applied/Not Applied]
- Policy result: [If available]

Please provide:
1. Verify policy configuration is correct
2. Check if user/app is in scope
3. Verify conditions are being evaluated
4. Check for conflicting policies
5. Use What-If to simulate
6. Resolution steps
```

### Prompt 3.2: Policy Blocking Unintended Users

```
A CA policy is blocking users who should have access.

POLICY NAME: [Name]
BLOCKED USERS: [Who is affected]
SHOULD HAVE ACCESS: [Why they should be allowed]

POLICY CONFIGURATION:
[Brief description of policy settings]

Please provide:
1. Analyze why users are matching policy
2. Identify if condition is too broad
3. Options to exclude legitimate users
4. Risk of creating exclusion
5. Alternative policy design
6. Testing after change
```

### Prompt 3.3: Conflicting Policies

```
I suspect multiple CA policies are conflicting.

SCENARIO:
[Describe the access scenario]

POLICIES THAT MIGHT APPLY:
- Policy 1: [Name and purpose]
- Policy 2: [Name and purpose]
- Policy 3: [Name and purpose]

UNEXPECTED RESULT:
[What's happening that seems wrong]

Please provide:
1. How CA policy precedence works
2. Analyze policy overlaps
3. Identify which policy is "winning"
4. Recommendations to resolve conflict
5. Best practices for policy organization
```

---

## Section 4: Policy Deployment Best Practices

### Prompt 4.1: Safe Policy Deployment

```
I'm deploying a new Conditional Access policy.

POLICY PURPOSE: [Description]
AFFECTED USERS: [Scope]
POTENTIAL IMPACT: [What could break]

Please provide:
1. Pre-deployment checklist
2. Report-only mode testing approach
3. How to analyze report-only results
4. Pilot group strategy
5. Gradual rollout approach
6. Rollback procedure
7. Success criteria
```

### Deployment Checklist

```
CA POLICY DEPLOYMENT CHECKLIST:

PRE-DEPLOYMENT:
□ Emergency access accounts excluded
□ Policy documented
□ Stakeholders notified
□ Support team briefed
□ Rollback plan documented

REPORT-ONLY PHASE (1-2 weeks):
□ Policy enabled in report-only mode
□ Sign-in logs reviewed daily
□ False positives identified
□ Policy adjusted as needed
□ Impact assessed

PILOT PHASE (1 week):
□ Small pilot group identified
□ Policy enabled for pilot only
□ Pilot feedback collected
□ Issues resolved
□ Success criteria met

PRODUCTION ROLLOUT:
□ Gradual expansion to larger groups
□ Monitor sign-in logs
□ Watch for support tickets
□ Confirm expected behavior
□ Full rollout when stable

POST-DEPLOYMENT:
□ Documentation updated
□ Monitoring in place
□ Regular review scheduled
```

---

## Section 5: Named Locations and Network Configuration

### Prompt 5.1: Configure Named Locations

```
I need to configure named locations for CA policies.

LOCATIONS TO DEFINE:
- Corporate offices: [IP ranges]
- VPN egress: [IP ranges]
- Partner locations: [If applicable]
- Countries to allow/block: [List]

Please provide:
1. Best practices for named location design
2. IP-based location configuration
3. Country-based location configuration
4. Trusted location marking
5. MFA trusted IPs vs named locations
6. Testing location-based policies
```

---

## Section 6: Advanced Scenarios

### Prompt 6.1: Zero Trust CA Architecture

```
I want to implement Zero Trust with Conditional Access.

CURRENT STATE:
- Network security model: [Traditional perimeter/Hybrid/Cloud-first]
- Device management: [Intune/Other/None]
- Identity protection: [Current state]

ZERO TRUST GOALS:
- Verify explicitly: [Requirements]
- Least privilege: [Requirements]
- Assume breach: [Requirements]

Please provide:
1. Zero Trust CA policy framework
2. Required policy layers
3. Device trust requirements
4. Application protection integration
5. Continuous access evaluation
6. Phased implementation approach
```

### Prompt 6.2: Cross-Tenant Access Policies

```
I need to configure access with external organizations.

SCENARIO:
- Partner organization: [Name/Tenant]
- Collaboration type: [B2B guests, cross-tenant sync, etc.]
- Access requirements: [What access is needed]
- Security requirements: [What controls are needed]

Please provide:
1. Cross-tenant access policy configuration
2. Inbound vs outbound settings
3. Trust settings for external MFA/devices
4. CA policies for guest users
5. Testing cross-tenant access
6. Monitoring and governance
```

---

## Quick Reference: CA Policy Components

### Assignments

| Component | Options |
|-----------|---------|
| Users | All users, specific groups, exclude groups |
| Cloud apps | All apps, specific apps, user actions |
| Conditions | Platforms, locations, client apps, device state, risk |

### Grant Controls

| Control | Description |
|---------|-------------|
| Block access | Deny all access |
| Require MFA | Multi-factor authentication |
| Require compliant device | Intune compliance |
| Require hybrid AAD join | Domain-joined and registered |
| Require approved app | App protection policy |
| Require app protection | Intune app protection |
| Require password change | For risky users |
| Require all selected | AND logic |
| Require one of selected | OR logic |

### Session Controls

| Control | Description |
|---------|-------------|
| App enforced restrictions | For SharePoint/Exchange |
| MCAS Conditional Access | Cloud app security integration |
| Sign-in frequency | How often to re-authenticate |
| Persistent browser session | Allow "stay signed in" |
| Continuous access evaluation | Real-time policy enforcement |

---

## Related Documents

- [Sign-In Troubleshooting](sign_in_troubleshooting.md) - Diagnose failures
- [Error Codes Reference](error_codes_reference.md) - AADSTS codes
- [Executive Translation](../01_IDENTITY_P0_COMMAND/executive_translation.md) - Communicate CA impact

---

[Back to Main README](../README.md)
