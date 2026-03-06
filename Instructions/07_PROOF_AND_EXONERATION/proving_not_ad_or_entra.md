# Identity Exoneration Framework

## Proving It's NOT Active Directory or Entra ID

> **The Gold Standard**: Being able to definitively prove that an issue is NOT an identity problem is just as valuable as diagnosing identity issues. This framework provides the methodology to exonerate AD/Entra with confidence.

---

## The Exoneration Principle

```
IN EVERY P0, IDENTITY GETS BLAMED.

Why? Because it's visible, it's central, and it's easy to point at.

Your job isn't just to diagnose identity issues.
Your job is also to PROTECT identity from false blame.

When identity is exonerated:
├── The real root cause gets found faster
├── The identity team isn't pulled into every incident
├── Trust is built with other teams
└── Future incidents get triaged more accurately
```

---

## The Exoneration Standard

### What Does "Exonerated" Mean?

```
EXONERATION LEVELS:

[FULLY EXONERATED] - 95%+ confidence
├── Multiple independent evidence sources
├── All identity components verified working
├── Alternative root cause identified
└── No reasonable identity explanation remains

[HIGHLY UNLIKELY] - 85-94% confidence
├── Primary identity components verified working
├── Evidence points elsewhere
├── Would require unusual identity failure mode
└── Alternative explanation is more probable

[INCONCLUSIVE] - 50-84% confidence
├── Some identity components verified
├── Cannot fully rule out identity
├── Need more data or testing
└── Possible but not proven either way

[CANNOT EXONERATE] - <50% confidence
├── Identity involvement is plausible
├── Evidence insufficient to rule out
├── Need identity-specific investigation
└── Proceed with identity troubleshooting
```

---

## The Five Pillars of Identity Exoneration

### Pillar 1: Authentication Path Verification

```
PROVE: Authentication to AD/Entra IS working

TEST 1: Fresh Kerberos Authentication
─────────────────────────────────────
# On affected client, purge tickets and re-acquire
klist purge
klist get krbtgt/DOMAIN.COM

✓ PASS: TGT successfully obtained → Kerberos auth working
✗ FAIL: Cannot obtain TGT → Identity MAY be involved

TEST 2: LDAP Connectivity
─────────────────────────────────────
# Test LDAP bind to DC
$de = New-Object DirectoryServices.DirectoryEntry("LDAP://DC.domain.com")
$de.Name

✓ PASS: LDAP bind succeeds → AD accessible
✗ FAIL: LDAP bind fails → Could be identity OR network

TEST 3: Azure AD Token (if hybrid)
─────────────────────────────────────
# Using Azure CLI or browser
az login --allow-no-subscriptions

✓ PASS: Token obtained → Entra auth working
✗ FAIL: Cannot authenticate → Entra MAY be involved

TEST 4: Service-Specific Authentication
─────────────────────────────────────
# Authenticate to the specific service failing
# Method depends on service type

✓ PASS: Auth to target service works → Issue is post-auth
✗ FAIL: Auth to target service fails → Need more investigation
```

### Pillar 2: Authorization Path Verification

```
PROVE: Authorization (permissions) in AD/Entra IS correct

TEST 1: Group Membership Verification
─────────────────────────────────────
# Check user's group memberships
Get-ADPrincipalGroupMembership username | Select-Object Name

# Compare to expected groups for access

✓ PASS: User has required group membership
✗ FAIL: Missing expected group → Identity involved

TEST 2: Kerberos PAC/Token Contents
─────────────────────────────────────
# View token contents
whoami /groups

# Check for expected SIDs/groups

✓ PASS: Token contains expected groups
✗ FAIL: Token missing groups → May be token issue (identity)

TEST 3: Azure AD Role Assignment
─────────────────────────────────────
# Check Entra role assignments
Get-AzureADUserMembership -ObjectId user@domain.com

✓ PASS: User has required assignments
✗ FAIL: Missing assignment → Identity involved

TEST 4: Object-Level Permissions
─────────────────────────────────────
# Check ACLs on target resource (application-specific)

✓ PASS: Permissions are correct → Issue is elsewhere
✗ FAIL: Permissions incorrect → Likely identity-related
```

### Pillar 3: Infrastructure Health Verification

```
PROVE: Identity infrastructure IS healthy

TEST 1: Domain Controller Health
─────────────────────────────────────
dcdiag /v /c /e

✓ PASS: All tests pass → DC infrastructure healthy
✗ FAIL: Tests failing → Identity MAY be involved

TEST 2: Replication Status
─────────────────────────────────────
repadmin /replsummary

✓ PASS: Replication current, no failures
✗ FAIL: Replication issues → Could affect specific users/sites

TEST 3: DNS Resolution
─────────────────────────────────────
nslookup -type=srv _ldap._tcp.dc._msdcs.domain.com

✓ PASS: SRV records present and correct
✗ FAIL: DNS issues → Could be DNS, not identity

TEST 4: Azure AD Connect Status (if hybrid)
─────────────────────────────────────
Get-ADSyncScheduler

✓ PASS: Sync running, no errors
✗ FAIL: Sync issues → Hybrid identity MAY be involved

TEST 5: Service Health
─────────────────────────────────────
# AD: Check critical services
Get-Service NTDS, KDC, Netlogon, DNS

# Entra: Check service health
# https://status.azure.com/ or admin.microsoft.com

✓ PASS: All services running
✗ FAIL: Service down → Identity involved
```

### Pillar 4: Correlation Analysis

```
PROVE: The failure pattern DOESN'T match identity failure

ANALYSIS 1: Scope Pattern
─────────────────────────────────────
Identity issues typically affect:
• All users (complete failure)
• Site-specific users (DC/replication issue)
• Users with specific attributes (filtering issue)
• Users in specific groups (permission issue)

If pattern is:
• Single user, random timing → Unlikely identity
• Specific application only → Likely application, not identity
• Network-correlated → Likely network, not identity

ANALYSIS 2: Timing Pattern
─────────────────────────────────────
Identity issues typically:
• Start suddenly (change-related)
• Affect everyone at same time
• Have clear before/after demarcation

If pattern is:
• Gradual degradation → Less likely identity
• Intermittent with no pattern → May not be identity
• Correlates with non-identity events → Likely not identity

ANALYSIS 3: Error Pattern
─────────────────────────────────────
Identity errors have specific signatures:
• Kerberos: Event 4771, 4768, 4769 failures
• NTLM: Event 4776 failures
• Azure: Specific error codes (AADSTS*)

If errors are:
• Application-specific errors → Application issue
• Network timeout errors → Network issue
• HTTP errors without auth codes → Application issue
```

### Pillar 5: Alternative Root Cause Evidence

```
PROVE: Something ELSE caused this

ALTERNATIVE 1: Network Issue Evidence
─────────────────────────────────────
Test connectivity to target:
Test-NetConnection -ComputerName target -Port 443

If:
• Connectivity fails but auth works → Network issue
• Latency high → Network issue
• Packet loss → Network issue

ALTERNATIVE 2: Application Issue Evidence
─────────────────────────────────────
If:
• Auth to app succeeds but app fails → Application issue
• Only one app affected, auth works to others → Application issue
• App logs show non-auth errors → Application issue

ALTERNATIVE 3: Certificate Issue Evidence
─────────────────────────────────────
If:
• SSL handshake fails → Certificate issue (could be app or client)
• Certificate expired → Certificate issue
• Certificate trust fails → Certificate issue (PKI, not AD auth)

ALTERNATIVE 4: Client-Side Issue Evidence
─────────────────────────────────────
If:
• Issue only on one device → Client issue
• Works after reboot → Client issue
• Credential Manager has stale creds → Client config issue
```

---

## Exoneration Evidence Checklist

```
IDENTITY EXONERATION EVIDENCE PACKAGE

□ AUTHENTICATION TESTS
  □ Fresh Kerberos TGT obtained successfully
  □ LDAP bind to DC successful
  □ Azure AD token obtained (if hybrid)
  □ Authentication to other services works

□ AUTHORIZATION TESTS
  □ User group membership verified correct
  □ Token contains expected groups
  □ Azure AD assignments verified (if applicable)

□ INFRASTRUCTURE TESTS
  □ DCDiag passes on relevant DCs
  □ Replication current
  □ DNS resolution correct
  □ Azure AD Connect sync healthy (if hybrid)

□ PATTERN ANALYSIS
  □ Failure pattern doesn't match identity patterns
  □ Scope doesn't align with identity boundaries
  □ Timing doesn't correlate with identity changes

□ ALTERNATIVE CAUSE
  □ Alternative root cause identified
  □ Evidence supports alternative cause
  □ Alternative explains all symptoms

EXONERATION CONFIDENCE: [FULLY/HIGHLY UNLIKELY/INCONCLUSIVE/CANNOT]
```

---

## Common Scenarios Where Identity is Falsely Blamed

### Scenario 1: "Can't Log In to Application"

```
SYMPTOM: User can't access specific application
BLAME: "AD must be down"

EXONERATION PATH:
1. Can user log into Windows? → YES → AD auth works
2. Can user access other apps? → YES → AD auth works for others
3. Can OTHER users access this app? → YES → Not widespread
4. What error does the app show? → [Application-specific error]

LIKELY ACTUAL CAUSE:
• Application configuration
• Application permissions (app-level, not AD)
• Application service issue
• Load balancer/network path to app

EXONERATION STATEMENT:
"User can authenticate to AD (confirmed via fresh TGT) and can access
other domain resources. The application is returning [specific error]
which indicates [application/network] issue, not identity."
```

### Scenario 2: "VPN Users Can't Connect"

```
SYMPTOM: Remote users can't connect via VPN
BLAME: "AD authentication is broken"

EXONERATION PATH:
1. Can office users authenticate? → YES → AD working
2. Does VPN reach AD? (Test from VPN) → Check connectivity
3. What VPN error? → [VPN-specific error]
4. Is MFA working? → Check MFA provider, not AD

LIKELY ACTUAL CAUSE:
• VPN infrastructure issue
• MFA provider issue (not AD-native)
• Network routing to AD from VPN
• Certificate on VPN/RADIUS server

EXONERATION STATEMENT:
"On-premises authentication is working normally. The issue is
[VPN connectivity/MFA provider/RADIUS] based on [specific evidence]."
```

### Scenario 3: "Email is Down"

```
SYMPTOM: Users can't access email
BLAME: "Must be an Entra sync issue"

EXONERATION PATH:
1. Is Entra healthy? → Check status.office.com
2. Can users access other M365 services? → Check Teams, SharePoint
3. Is Exchange Online healthy? → Check Exchange-specific status
4. What error do users see? → [Exchange error]

LIKELY ACTUAL CAUSE:
• Exchange Online service issue (Microsoft-side)
• Mail flow rules
• Mailbox provisioning (specific user)
• Client configuration

EXONERATION STATEMENT:
"Azure AD authentication is working (users can access Teams/SharePoint).
Exchange Online is experiencing [service issue/specific problem] as
evidenced by [error messages/service health dashboard]."
```

### Scenario 4: "Single Sign-On Broken"

```
SYMPTOM: SSO not working for a SaaS application
BLAME: "ADFS/Entra is broken"

EXONERATION PATH:
1. Does SSO work to OTHER apps? → YES → Federation healthy
2. What error from this specific app? → [SAML error/app error]
3. Has app config changed? → Check app side
4. Has certificate expired? → Check app federation cert

LIKELY ACTUAL CAUSE:
• Application federation configuration changed
• Application-side certificate expired
• Application metadata changed
• Application-specific session issue

EXONERATION STATEMENT:
"SSO is functioning correctly for [other apps]. The specific
application is returning [error] which indicates [app config/
app certificate/app service] issue."
```

---

## The Exoneration Conversation

### How to Communicate Exoneration

```
TO THE INCIDENT COMMANDER:

"I've completed identity diagnostics. Based on [specific tests],
I can confirm with [HIGH/MODERATE] confidence that this is NOT
an Active Directory or Entra ID issue.

Evidence:
• [Test 1]: [Result]
• [Test 2]: [Result]
• [Test 3]: [Result]

The error pattern suggests [alternative system] as the likely cause
because [reasoning].

I recommend engaging [other team] for further investigation."
```

### Documentation Template

```
IDENTITY EXONERATION REPORT

Incident: [Number/Name]
Date/Time: [Timestamp]
Analyst: [Name]

ISSUE DESCRIPTION:
[What was initially reported]

IDENTITY INVESTIGATION:
[Tests performed and results]

EXONERATION DETERMINATION: [EXONERATED / NOT EXONERATED]
Confidence: [Percentage]

EVIDENCE SUMMARY:
• [Key evidence point 1]
• [Key evidence point 2]
• [Key evidence point 3]

ALTERNATIVE ROOT CAUSE:
[If identified, what the actual cause appears to be]

RECOMMENDED NEXT STEPS:
[Who should investigate further]

IDENTITY TEAM STATUS: RELEASED FROM INCIDENT
```

---

## Related Documents

- [Evidence Checklists](evidence_checklists.md) - Detailed evidence requirements
- [Confidence Scoring](confidence_scoring.md) - How to quantify certainty
- [P0 Incident Commander](../01_IDENTITY_P0_COMMAND/p0_incident_commander_prompt.md) - Overall incident approach
