# Cross-Platform Identity Log Correlation Framework

## System Prompt

```
You are an expert security analyst specializing in correlating identity events across
multiple logging platforms. Your role is to help engineers build unified timelines
from disparate data sources including Active Directory, Entra ID, SIEM platforms,
EDR solutions, and application logs.

CORE PRINCIPLES:
1. No single log source tells the complete story
2. Correlation confidence increases with independent source agreement
3. Time synchronization issues cause most correlation failures
4. Think in attack chains, not isolated events

CONFIDENCE FRAMEWORK:
- HIGH: 3+ sources corroborate with timestamp alignment
- MEDIUM: 2 sources corroborate
- LOW: Single source with circumstantial support
- UNCORRELATED: Cannot link events across sources
```

---

## Part 1: Log Source Inventory and Normalization

### Identity Log Source Mapping

```
PROMPT: Map available identity log sources and their key fields.

ENVIRONMENT INVENTORY:
- AD Domains: [List]
- Entra Tenant: [Tenant ID]
- SIEM Platform: [Sentinel/Splunk/Other]
- EDR Solution: [MDE/CrowdStrike/Other]
- PAM Solution: [CyberArk/BeyondTrust/Other]

LOG SOURCE NORMALIZATION MATRIX:

| Event Type | AD Security Log | Entra Sign-in | MDE | MDI |
|------------|-----------------|---------------|-----|-----|
| **Successful Logon** | 4624 | ResultType=0 | DeviceLogonEvents | SuccessfulLogon |
| **Failed Logon** | 4625 | ResultType≠0 | DeviceLogonEvents | FailedLogon |
| **Account** | TargetUserName | UserPrincipalName | AccountName | SourceAccountName |
| **Source IP** | IpAddress | IPAddress | RemoteIP | SourceIPAddress |
| **Target** | Computer | ResourceId | DeviceName | DestinationDevice |
| **Timestamp** | TimeCreated | CreatedDateTime | Timestamp | EventTime |
| **Session ID** | TargetLogonId | CorrelationId | LogonId | SessionId |

NORMALIZATION FUNCTION EXAMPLES:

Active Directory to Common Schema:
```kql
SecurityEvent
| where EventID in (4624, 4625)
| extend
    NormalizedUser = tolower(TargetUserName),
    NormalizedSource = iff(isempty(IpAddress), WorkstationName, IpAddress),
    NormalizedTarget = tolower(Computer),
    NormalizedAction = iff(EventID == 4624, "LogonSuccess", "LogonFailure"),
    NormalizedTimestamp = TimeGenerated,
    SourceSystem = "ActiveDirectory"
| project NormalizedTimestamp, SourceSystem, NormalizedAction,
          NormalizedUser, NormalizedSource, NormalizedTarget,
          OriginalEventID = EventID, LogonType
```

Entra ID to Common Schema:
```kql
SigninLogs
| extend
    NormalizedUser = tolower(UserPrincipalName),
    NormalizedSource = IPAddress,
    NormalizedTarget = tolower(ResourceDisplayName),
    NormalizedAction = iff(ResultType == "0", "LogonSuccess", "LogonFailure"),
    NormalizedTimestamp = TimeGenerated,
    SourceSystem = "EntraID"
| project NormalizedTimestamp, SourceSystem, NormalizedAction,
          NormalizedUser, NormalizedSource, NormalizedTarget,
          OriginalResultType = ResultType, AppDisplayName
```

TIME SYNCHRONIZATION CHECK:
```kql
// Check for time drift between sources
union
    (SecurityEvent | summarize ADTime=max(TimeGenerated) | extend Source="AD"),
    (SigninLogs | summarize EntraTime=max(TimeGenerated) | extend Source="Entra"),
    (DeviceProcessEvents | summarize MDETime=max(TimeGenerated) | extend Source="MDE")
| summarize MaxTime=max(ADTime), MinTime=min(ADTime)
| extend DriftMinutes = datetime_diff('minute', MaxTime, MinTime)
```

Expected Drift Tolerance: < 5 minutes
Action if > 5 minutes: Investigate NTP configuration
```

---

## Part 2: Correlation Patterns and Techniques

### User Session Correlation

```
PROMPT: Correlate user session across all identity sources.

TARGET USER: [User principal name or sAMAccountName]
TIMEFRAME: [Investigation window]
SUSPECTED ACTIVITY: [What triggered investigation]

CORRELATION METHODOLOGY:

STEP 1: ESTABLISH SESSION ANCHORS
Identify unique session identifiers in each system:

Active Directory:
- TargetLogonId (unique per session)
- Query: SecurityEvent | where EventID == 4624 | where TargetUserName == "TARGET"

Entra ID:
- CorrelationId (links related events)
- UniqueTokenIdentifier (per token)
- Query: SigninLogs | where UserPrincipalName == "TARGET"

MDE:
- LogonId (matches AD TargetLogonId)
- Query: DeviceLogonEvents | where AccountName == "TARGET"

STEP 2: BUILD UNIFIED TIMELINE
```kql
let targetUser = "TARGET_USER";
let timeStart = datetime("2024-01-15T08:00:00Z");
let timeEnd = datetime("2024-01-15T20:00:00Z");

// AD Events
let adEvents = SecurityEvent
| where TimeGenerated between (timeStart .. timeEnd)
| where TargetUserName =~ targetUser or SubjectUserName =~ targetUser
| where EventID in (4624, 4625, 4648, 4672, 4768, 4769, 4776)
| extend Source = "AD",
         EventType = case(
             EventID == 4624, "Logon",
             EventID == 4625, "LogonFailed",
             EventID == 4648, "ExplicitCreds",
             EventID == 4672, "PrivilegeAssign",
             EventID == 4768, "TGTRequest",
             EventID == 4769, "TGSRequest",
             EventID == 4776, "NTLMAuth", "Other")
| project TimeGenerated, Source, EventType,
          Details = strcat("Target:", Computer, " Type:", LogonType, " IP:", IpAddress);

// Entra Events
let entraEvents = SigninLogs
| where TimeGenerated between (timeStart .. timeEnd)
| where UserPrincipalName =~ targetUser
| extend Source = "Entra",
         EventType = iff(ResultType == "0", "CloudLogon", "CloudLogonFailed")
| project TimeGenerated, Source, EventType,
          Details = strcat("App:", AppDisplayName, " IP:", IPAddress, " Location:", LocationDetails.city);

// MDE Events
let mdeEvents = DeviceLogonEvents
| where TimeGenerated between (timeStart .. timeEnd)
| where AccountName =~ targetUser
| extend Source = "MDE",
         EventType = strcat("EndpointLogon-", ActionType)
| project TimeGenerated, Source, EventType,
          Details = strcat("Device:", DeviceName, " Type:", LogonType);

// MDI Alerts
let mdiAlerts = SecurityAlert
| where TimeGenerated between (timeStart .. timeEnd)
| where ProviderName == "AATP"
| where Entities has targetUser
| extend Source = "MDI", EventType = AlertName
| project TimeGenerated, Source, EventType, Details = Description;

// Combine all
union adEvents, entraEvents, mdeEvents, mdiAlerts
| sort by TimeGenerated asc
| project TimeGenerated, Source, EventType, Details
```

STEP 3: IDENTIFY CORRELATION POINTS
Look for events that should appear in multiple sources:

| User Action | AD Event | Entra Event | MDE Event |
|-------------|----------|-------------|-----------|
| Interactive logon to workstation | 4624 Type 2 | - | DeviceLogonEvents |
| Cloud app access | - | SigninLogs | - |
| Remote access to server | 4624 Type 3 | - | DeviceNetworkEvents |
| Kerberos auth to cloud | 4768, 4769 | SigninLogs (SSO) | - |
| VPN connection | 4624 Type 3 | SigninLogs (if MFA) | - |

STEP 4: GAP ANALYSIS
Events present in one source but missing from expected sources:

| Time | Source Present | Source Missing | Possible Reasons |
|------|----------------|----------------|------------------|
| [T] | AD | MDE | Endpoint not onboarded / Event filtered |
| [T] | Entra | AD | Cloud-only auth / AADC sync delay |
| [T] | MDE | AD | Security log wrap / Collection failure |

CORRELATION CONFIDENCE SCORE:
Based on source agreement, assign confidence to each session:
- 3+ sources agree: HIGH (>90%)
- 2 sources agree: MEDIUM (70-90%)
- Single source: LOW (<70%)
- Conflicting data: INVESTIGATE DISCREPANCY
```

### Attack Chain Correlation

```
PROMPT: Correlate events to build attack chain narrative.

ATTACK HYPOTHESIS: [Type of attack suspected]
INITIAL INDICATOR: [What triggered investigation]
KNOWN ENTITIES: [Users, IPs, devices involved]

ATTACK CHAIN CORRELATION FRAMEWORK:

PHASE 1: INITIAL ACCESS
What logs show the attacker's entry point?

External Entry Points:
| Source | Query Pattern | Key Fields |
|--------|---------------|------------|
| Entra | Failed then success pattern | IPAddress, UserPrincipalName, RiskLevel |
| VPN | Remote access logs | Source IP, User, Connect time |
| Email | O365/Exchange delivery | Sender, Recipient, Attachment hash |
| Firewall | Inbound connections | Source IP, Dest IP, Port |

Correlation Query:
```kql
let suspiciousIP = "SUSPICIOUS_IP";
let timeWindow = 1h;
let initialAccess = SigninLogs
| where IPAddress == suspiciousIP
| where ResultType == "0"
| summarize FirstSuccess = min(TimeGenerated) by UserPrincipalName;

// Find all entry events around this time
union
    (SigninLogs | where IPAddress == suspiciousIP),
    (SecurityEvent | where IpAddress == suspiciousIP),
    (DeviceNetworkEvents | where RemoteIP == suspiciousIP)
| where TimeGenerated between ((toscalar(initialAccess | summarize min(FirstSuccess)) - timeWindow) ..
                               (toscalar(initialAccess | summarize min(FirstSuccess)) + timeWindow))
```

PHASE 2: CREDENTIAL ACCESS
After initial access, how did attacker obtain more credentials?

| Technique | AD Event | MDE Event | MDI Alert |
|-----------|----------|-----------|-----------|
| LSASS dump | - | ProcessAccess to lsass.exe | Credential theft |
| Kerberoast | 4769 (RC4) | PowerShell/Rubeus execution | SPN enumeration |
| DCSync | 4662 (repl rights) | DRSUAPI calls | DCSync detected |
| SAM dump | - | Registry access to SAM | - |

PHASE 3: LATERAL MOVEMENT
How did attacker spread through environment?

Correlation Pattern:
```kql
// Link credential theft to subsequent remote logons
let credTheftTime = datetime("THEFT_TIME");
let stolenAccount = "STOLEN_ACCOUNT";

// Find remote logons after credential theft
let lateralMovement = SecurityEvent
| where TimeGenerated > credTheftTime
| where EventID == 4624
| where LogonType in (3, 10)  // Network, RemoteInteractive
| where TargetUserName == stolenAccount
| project LateralTime = TimeGenerated, TargetComputer = Computer,
          SourceIP = IpAddress, LogonType;

// Correlate with MDE network events
DeviceNetworkEvents
| where TimeGenerated > credTheftTime
| where AccountName == stolenAccount
| where RemotePort in (445, 135, 5985, 3389)
| join kind=inner lateralMovement on $left.RemoteIP == $right.SourceIP
```

PHASE 4: OBJECTIVE COMPLETION
What did the attacker ultimately achieve?

Data Access Indicators:
| Objective | Log Source | Query Pattern |
|-----------|------------|---------------|
| Data exfil | Firewall | Large outbound transfers |
| Email access | Exchange | Mailbox access audit |
| File access | File server | 4663 object access |
| DB access | SQL audit | Sensitive table queries |

BUILD NARRATIVE TIMELINE:
```
Attack Chain Timeline:
────────────────────────────────────────────────────────
T+0 (HH:MM) │ INITIAL ACCESS
            │ Source: [Log source]
            │ Evidence: [Specific event]
            │ Confidence: [HIGH/MED/LOW]
────────────────────────────────────────────────────────
T+X (HH:MM) │ CREDENTIAL ACCESS
            │ Source: [Log source]
            │ Evidence: [Specific event]
            │ Confidence: [HIGH/MED/LOW]
────────────────────────────────────────────────────────
T+Y (HH:MM) │ LATERAL MOVEMENT
            │ Source: [Log source]
            │ Evidence: [Specific event]
            │ Hop: [Device 1] → [Device 2]
            │ Confidence: [HIGH/MED/LOW]
────────────────────────────────────────────────────────
T+Z (HH:MM) │ OBJECTIVE
            │ Source: [Log source]
            │ Evidence: [Specific event]
            │ Impact: [What was accessed/exfiltrated]
            │ Confidence: [HIGH/MED/LOW]
────────────────────────────────────────────────────────
```
```

---

## Part 3: Cross-Platform Query Templates

### Splunk to Sentinel Translation

```
PROMPT: Translate identity queries between Splunk and Sentinel.

USE CASE: [What the query detects]

SPLUNK QUERY:
[Paste Splunk query]

TRANSLATION TO SENTINEL KQL:

FIELD MAPPING:
| Splunk Field | Sentinel Table | Sentinel Field |
|--------------|----------------|----------------|
| src_ip | SigninLogs | IPAddress |
| user | SigninLogs | UserPrincipalName |
| action | SigninLogs | ResultType (0=success) |
| dest | SecurityEvent | Computer |
| EventCode | SecurityEvent | EventID |
| _time | All | TimeGenerated |

COMMON TRANSLATION PATTERNS:

Splunk search command → KQL table reference
| stats count by field → summarize count() by field
| where field="value" → where field == "value"
| eval newfield=if(cond, val1, val2) → extend newfield = iff(cond, val1, val2)
| table field1 field2 → project field1, field2
| sort - field → order by field desc
| dedup field → distinct field (or summarize by field)
| rex field=raw "(?<extract>pattern)" → extract with parse or extract()
| join type=inner → join kind=inner
| earliest=-24h → where TimeGenerated > ago(24h)

EXAMPLE TRANSLATIONS:

Splunk: Password Spray Detection
```splunk
index=azure sourcetype=azure:aad:signin
| where action="failure"
| stats count as failures dc(user) as unique_users values(user) as users by src_ip
| where failures > 30 AND unique_users > 10
```

Sentinel Equivalent:
```kql
SigninLogs
| where ResultType != "0"  // failure
| summarize
    failures = count(),
    unique_users = dcount(UserPrincipalName),
    users = make_set(UserPrincipalName, 100)
    by IPAddress
| where failures > 30 and unique_users > 10
```

Splunk: Lateral Movement via PsExec
```splunk
index=wineventlog EventCode=4624 Logon_Type=3
| join type=inner [search index=wineventlog EventCode=7045 Service_Name="PSEXESVC"]
| table _time src_ip user dest
```

Sentinel Equivalent:
```kql
let psexecServices = SecurityEvent
| where EventID == 7045
| where ServiceName == "PSEXESVC"
| project ServiceTime = TimeGenerated, Computer;

SecurityEvent
| where EventID == 4624
| where LogonType == 3
| join kind=inner psexecServices on Computer
| where abs(datetime_diff('minute', TimeGenerated, ServiceTime)) < 5
| project TimeGenerated, IpAddress, TargetUserName, Computer
```

OUTPUT FORMAT:
- Original Splunk query explanation
- Field-by-field mapping
- Translated KQL query
- Validation approach (sample outputs should match)
```

### Multi-SIEM Unified Query

```
PROMPT: Create equivalent identity detection across multiple SIEM platforms.

DETECTION LOGIC:
[Describe what needs to be detected]

SENTINEL KQL:
```kql
[KQL query here]
```

SPLUNK SPL EQUIVALENT:
```splunk
[SPL query here]
```

ELASTIC EQL EQUIVALENT:
```eql
[EQL query here]
```

CHRONICLE YARA-L EQUIVALENT:
```yaral
[YARA-L rule here]
```

DETECTION LOGIC BREAKDOWN:
1. Data source: [Which logs are used]
2. Baseline behavior: [What's normal]
3. Anomaly pattern: [What indicates threat]
4. Threshold/logic: [Detection criteria]
5. False positive considerations: [What might trigger incorrectly]

VALIDATION ACROSS PLATFORMS:
| Platform | Test Data | Expected Result | Actual Result |
|----------|-----------|-----------------|---------------|
| Sentinel | [Sample] | [Expected] | [Tested?] |
| Splunk | [Sample] | [Expected] | [Tested?] |
| Elastic | [Sample] | [Expected] | [Tested?] |
| Chronicle | [Sample] | [Expected] | [Tested?] |
```

---

## Part 4: Correlation Troubleshooting

### When Correlation Fails

```
PROMPT: Diagnose why identity events aren't correlating properly.

SYMPTOM: [Describe the correlation issue]
EXPECTED: [What should be correlating]
ACTUAL: [What's happening instead]

DIAGNOSTIC FRAMEWORK:

1. TIME SYNCHRONIZATION CHECK:

   Issue: Events exist but timestamps don't align

   Diagnostic Query:
   ```kql
   // Compare timestamps across sources for same event
   let targetEvent = datetime("EVENT_TIME");
   let tolerance = 5m;
   union
       (SecurityEvent | where abs(datetime_diff('minute', TimeGenerated, targetEvent)) < tolerance),
       (SigninLogs | where abs(datetime_diff('minute', TimeGenerated, targetEvent)) < tolerance),
       (DeviceLogonEvents | where abs(datetime_diff('minute', Timestamp, targetEvent)) < tolerance)
   | project TimeGenerated, Source = "Check", SourceSystem
   | sort by TimeGenerated
   ```

   Root Causes:
   - NTP misconfiguration on endpoints/DCs
   - Log collection agent delays
   - SIEM ingestion lag
   - Timezone conversion errors

2. IDENTITY FORMAT MISMATCH:

   Issue: Same user appears differently across sources

   Common Mismatches:
   | Source | Format Example | Normalized |
   |--------|----------------|------------|
   | AD | DOMAIN\username | username@domain.com |
   | Entra | user@domain.com | user@domain.com |
   | MDE | username | username@domain.com |
   | App logs | email@company.com | user@domain.com |

   Normalization Query:
   ```kql
   // Create consistent user identifier
   | extend NormalizedUser = case(
       UserPrincipalName contains "@", tolower(UserPrincipalName),
       TargetUserName contains "\\", tolower(split(TargetUserName, "\\")[1]),
       tolower(TargetUserName))
   ```

3. MISSING DATA SOURCE:

   Issue: Events should exist but don't

   Verification Steps:
   □ Is the log source connected? (Check data connectors)
   □ Is data flowing? (Check ingestion graphs)
   □ Is the specific event type enabled? (Check audit policy)
   □ Is data being filtered? (Check collection rules)
   □ Is retention adequate? (Check workspace settings)

   Data Gap Query:
   ```kql
   // Check for gaps in expected data
   SecurityEvent
   | where Computer == "TARGET_DC"
   | summarize Count = count() by bin(TimeGenerated, 1h)
   | where Count < 100  // Unusually low
   ```

4. JOIN KEY MISMATCH:

   Issue: Join query returns empty despite data existing

   Debug Approach:
   ```kql
   // Inspect actual values before joining
   let leftSide = Table1 | take 10 | project JoinKey1 = KeyField;
   let rightSide = Table2 | take 10 | project JoinKey2 = KeyField;
   union
       (leftSide | extend Side = "Left"),
       (rightSide | extend Side = "Right")
   | project Side, Key = coalesce(JoinKey1, JoinKey2)
   // Compare formats, cases, whitespace
   ```

5. SCOPE MISMATCH:

   Issue: Query runs but wrong data is correlated

   Common Causes:
   - Username collision (same name, different person)
   - IP reuse (NAT, DHCP reassignment)
   - Device name collision (duplicate names)
   - Session ID wrap-around

   Resolution: Add additional qualifiers:
   ```kql
   // Add domain/tenant context to user
   | extend FullyQualifiedUser = strcat(Domain, "\\", Username)

   // Add device context to IP
   | extend IPContext = strcat(IPAddress, "-", DeviceName)
   ```

CORRELATION TROUBLESHOOTING CHECKLIST:
□ Timestamps within tolerance across sources
□ User identifiers normalized consistently
□ IP addresses account for NAT/proxy
□ Device names are unique/qualified
□ Data sources have complete coverage
□ Join keys match exactly (case, format)
□ Timeframe includes all relevant events
□ No collection gaps during incident window
```

---

## Part 5: Advanced Correlation Scenarios

### Multi-Tenant Correlation

```
PROMPT: Correlate identity events across multiple tenants or forests.

ENVIRONMENT:
- Tenant/Forest 1: [Name/ID]
- Tenant/Forest 2: [Name/ID]
- Trust Relationship: [Type if applicable]
- User Mapping: [How users map across environments]

CORRELATION CHALLENGES:

1. Cross-Tenant User Mapping:

   Scenario: User has account in both tenants

   Mapping Table:
   | Tenant 1 Account | Tenant 2 Account | Correlation Key |
   |------------------|------------------|-----------------|
   | user@tenant1.com | user.external@tenant2.com | EmployeeID |

   Query Pattern:
   ```kql
   // Create cross-tenant user lookup
   let userMapping = datatable(Tenant1:string, Tenant2:string)[
       "user1@tenant1.com", "user1_ext@tenant2.com",
       "user2@tenant1.com", "user2_ext@tenant2.com"
   ];

   // Correlate events across tenants
   let tenant1Events = workspace("Tenant1Workspace").SigninLogs
   | project T1Time = TimeGenerated, T1User = UserPrincipalName, T1IP = IPAddress;

   let tenant2Events = workspace("Tenant2Workspace").SigninLogs
   | project T2Time = TimeGenerated, T2User = UserPrincipalName, T2IP = IPAddress;

   tenant1Events
   | join kind=inner userMapping on $left.T1User == $right.Tenant1
   | join kind=inner tenant2Events on $left.Tenant2 == $right.T2User
   | where abs(datetime_diff('hour', T1Time, T2Time)) < 24
   ```

2. Cross-Forest AD Correlation:

   Scenario: Tracking user across trusted forests

   Trust Event Correlation:
   ```kql
   // Forest A: TGT request
   let forestA_TGT = SecurityEvent
   | where Computer contains "FORESTA"
   | where EventID == 4768
   | project TGTTime = TimeGenerated, User = TargetUserName, ClientIP = IpAddress;

   // Forest B: Cross-forest TGS (referral)
   let forestB_TGS = SecurityEvent
   | where Computer contains "FORESTB"
   | where EventID == 4769
   | where ServiceName contains "krbtgt"  // Cross-forest ticket
   | project TGSTime = TimeGenerated, User = TargetUserName, ServiceName;

   forestA_TGT
   | join kind=inner forestB_TGS on User
   | where TGSTime > TGTTime and datetime_diff('minute', TGSTime, TGTTime) < 60
   ```

3. B2B Guest User Correlation:

   Tracking guest user activity in host tenant:
   ```kql
   SigninLogs
   | where UserType == "Guest"
   | extend HomeTenant = tostring(split(UserPrincipalName, "#")[1])
   | summarize
       SignInCount = count(),
       AppsAccessed = make_set(AppDisplayName),
       SourceIPs = make_set(IPAddress)
       by UserPrincipalName, HomeTenant
   ```

CROSS-TENANT CORRELATION MATRIX:
| Event in Tenant A | Expected Event in Tenant B | Correlation Key |
|-------------------|----------------------------|-----------------|
| Guest invite | Guest creation audit | Email address |
| B2B sign-in | Home tenant sign-in | User ID + timestamp |
| Cross-tenant access | Resource access audit | Resource ID |
```

---

## Quick Reference Card

```
LOG CORRELATION QUICK REFERENCE

COMMON CORRELATION KEYS:
- User: Normalize to UPN lowercase
- IP: Account for NAT/proxy in correlation window
- Session: AD LogonId = MDE LogonId
- Time: Allow 5-minute tolerance between sources

QUICK NORMALIZATION:
// AD username to UPN
| extend User = strcat(tolower(TargetUserName), "@", tolower(TargetDomainName))

// MDE to AD LogonId match
SecurityEvent | where TargetLogonId == hexstring

// Entra CorrelationId groups
SigninLogs | summarize by CorrelationId | take 10

CORRELATION HEALTH CHECK:
union
    (SecurityEvent | summarize AD_Latest=max(TimeGenerated)),
    (SigninLogs | summarize Entra_Latest=max(TimeGenerated)),
    (DeviceLogonEvents | summarize MDE_Latest=max(TimeGenerated))

UNIFIED TIMELINE TEMPLATE:
union
    (SecurityEvent | project TimeGenerated, Source="AD", Event=EventID, User=TargetUserName),
    (SigninLogs | project TimeGenerated, Source="Entra", Event="SignIn", User=UserPrincipalName),
    (DeviceLogonEvents | project TimeGenerated=Timestamp, Source="MDE", Event=ActionType, User=AccountName)
| where User =~ "TARGET"
| sort by TimeGenerated

TROUBLESHOOTING CHECKLIST:
1. Are all sources ingesting? (Check last event time)
2. Are timestamps synchronized? (<5 min drift)
3. Are user identifiers normalized? (Same format)
4. Is join logic correct? (Test with sample data)
5. Is timeframe sufficient? (Include buffer)
```

---

*Document Version: 1.0*
*Framework: Cross-Platform Identity Correlation*
*Integration: All identity log sources*
