# Microsoft Sentinel: Identity Security Analytics

## System Prompt

```
You are an expert Microsoft Sentinel analyst specializing in identity threat detection
and Active Directory security monitoring. Your role is to help engineers create, tune,
and investigate identity-focused analytics rules, hunting queries, and workbooks.

CORE PRINCIPLES:
1. Identity is the new perimeter - monitor it accordingly
2. Correlate across AD, Entra, MDE, and MDI data sources
3. False positive reduction is as important as detection
4. Context enrichment transforms alerts into actionable intelligence

CONFIDENCE FRAMEWORK:
- HIGH: Multi-source correlation with behavioral anomaly
- MEDIUM: Single source alert with context enrichment
- LOW: Rule-based detection without behavioral context
- SPECULATIVE: Hunting hypothesis without confirmed malicious activity
```

---

## Part 1: Data Source Integration

### Identity Data Sources in Sentinel

```
PROMPT: Assess identity data source availability and health in Sentinel.

CURRENT CONFIGURATION:
- Workspace: [Workspace name]
- Data Connectors Enabled: [List known connectors]
- Retention Period: [Days]

DATA SOURCE INVENTORY:

1. ACTIVE DIRECTORY (On-Premises):

   | Data Source | Table | Status | Ingestion Lag |
   |-------------|-------|--------|---------------|
   | Security Events | SecurityEvent | ? | ? |
   | Sysmon | Sysmon | ? | ? |
   | DNS Logs | DnsEvents | ? | ? |
   | DHCP Logs | DHCPActivity | ? | ? |

   Health Check Query:
   ```kql
   SecurityEvent
   | where TimeGenerated > ago(1h)
   | where Computer contains "DC"
   | summarize Count=count(),
       LastEvent=max(TimeGenerated) by Computer
   | project Computer, Count, LastEvent,
       Lag=datetime_diff('minute', now(), LastEvent)
   ```

2. ENTRA ID (Azure AD):

   | Data Source | Table | Status | Ingestion Lag |
   |-------------|-------|--------|---------------|
   | Sign-in Logs | SigninLogs | ? | ? |
   | Audit Logs | AuditLogs | ? | ? |
   | Non-Interactive | AADNonInteractiveUserSignInLogs | ? | ? |
   | Service Principal | AADServicePrincipalSignInLogs | ? | ? |
   | Managed Identity | AADManagedIdentitySignInLogs | ? | ? |
   | Provisioning | AADProvisioningLogs | ? | ? |

   Health Check Query:
   ```kql
   SigninLogs
   | where TimeGenerated > ago(1h)
   | summarize Count=count(), LastEvent=max(TimeGenerated)
   | project Count, LastEvent,
       Lag=datetime_diff('minute', now(), LastEvent)
   ```

3. MICROSOFT DEFENDER FOR IDENTITY:

   | Data Source | Table | Status |
   |-------------|-------|--------|
   | Security Alerts | SecurityAlert (provider=AATP) | ? |
   | Identity Info | IdentityInfo | ? |

4. MICROSOFT DEFENDER FOR ENDPOINT:

   | Data Source | Table | Status |
   |-------------|-------|--------|
   | Device Events | DeviceProcessEvents | ? |
   | Device Network | DeviceNetworkEvents | ? |
   | Device Logon | DeviceLogonEvents | ? |
   | Alerts | SecurityAlert (provider=MDATP) | ? |

DATA COMPLETENESS ASSESSMENT:
- Are all DCs sending logs? [Y/N/Partial]
- Is AADC health logged? [Y/N]
- Are all identity workloads covered? [Y/N/List gaps]
- Recommended additions: [List]
```

---

## Part 2: Analytics Rules for Identity Threats

### Credential Attack Detection Rules

```
PROMPT: Create or tune analytics rules for credential-based attacks.

ATTACK CATEGORIES:

1. PASSWORD SPRAY DETECTION:
```kql
// Analytics Rule: Password Spray Attack
let threshold = 30;  // Tunable threshold
let timeWindow = 10m;
SigninLogs
| where TimeGenerated > ago(1d)
| where ResultType == "50126"  // Invalid username or password
| summarize
    FailedAttempts = count(),
    TargetedAccounts = dcount(UserPrincipalName),
    AccountsList = make_set(UserPrincipalName, 100),
    AppList = make_set(AppDisplayName)
    by IPAddress, bin(TimeGenerated, timeWindow)
| where FailedAttempts > threshold
| where TargetedAccounts > 10  // Multiple accounts targeted
| project
    TimeGenerated,
    IPAddress,
    FailedAttempts,
    TargetedAccounts,
    SampleAccounts = array_slice(AccountsList, 0, 10),
    Applications = AppList
```

Rule Configuration:
- Severity: High
- Frequency: 10 minutes
- Lookback: 1 hour
- Threshold: 30 failures, 10+ accounts

2. BRUTE FORCE DETECTION:
```kql
// Analytics Rule: Brute Force Against Single Account
let threshold = 20;
let timeWindow = 5m;
SigninLogs
| where TimeGenerated > ago(1d)
| where ResultType in ("50126", "50053", "50055")
| summarize
    FailedAttempts = count(),
    SourceIPs = dcount(IPAddress),
    IPList = make_set(IPAddress, 20)
    by UserPrincipalName, bin(TimeGenerated, timeWindow)
| where FailedAttempts > threshold
| project
    TimeGenerated,
    UserPrincipalName,
    FailedAttempts,
    UniqueSourceIPs = SourceIPs,
    SampleIPs = array_slice(IPList, 0, 10)
```

3. CREDENTIAL STUFFING PATTERN:
```kql
// Multiple accounts from same IP with some successes
let timeWindow = 1h;
SigninLogs
| where TimeGenerated > ago(1d)
| summarize
    TotalAttempts = count(),
    SuccessCount = countif(ResultType == "0"),
    FailCount = countif(ResultType != "0"),
    UniqueAccounts = dcount(UserPrincipalName),
    SuccessfulAccounts = make_set_if(UserPrincipalName, ResultType == "0")
    by IPAddress, bin(TimeGenerated, timeWindow)
| where UniqueAccounts > 20
| where SuccessCount > 0 and FailCount > SuccessCount * 5
| extend SuccessRate = round(100.0 * SuccessCount / TotalAttempts, 2)
| where SuccessRate between (1 .. 30)  // Suspicious pattern
```

TUNING PARAMETERS:
| Attack Type | Threshold | Timeframe | FP Mitigation |
|-------------|-----------|-----------|---------------|
| Password Spray | 30 failures, 10 accounts | 10 min | Exclude known pen test IPs |
| Brute Force | 20 failures | 5 min | Exclude service accounts expected failures |
| Credential Stuffing | 20 accounts, 1-30% success | 1 hour | Review geographic context |

ENTITY MAPPING:
- Account: UserPrincipalName
- IP: IPAddress
- Host: DeviceDetail.displayName (if available)
```

### Lateral Movement Detection Rules

```
PROMPT: Create analytics rules for detecting lateral movement in hybrid environment.

1. SUSPICIOUS REMOTE LOGON PATTERNS:
```kql
// First-time remote access to sensitive system
let sensitiveComputers = dynamic(["DC01", "DC02", "SQL-PROD", "PAW-"]);
let lookbackDays = 30;
let recentWindow = 1d;
let historicalLogons =
    SecurityEvent
    | where TimeGenerated between (ago(lookbackDays) .. ago(recentWindow))
    | where EventID == 4624
    | where LogonType in (3, 10)  // Network, RemoteInteractive
    | where Computer has_any (sensitiveComputers)
    | summarize by TargetUserName, Computer;
SecurityEvent
| where TimeGenerated > ago(recentWindow)
| where EventID == 4624
| where LogonType in (3, 10)
| where Computer has_any (sensitiveComputers)
| join kind=leftanti historicalLogons
    on TargetUserName, Computer
| project
    TimeGenerated,
    Computer,
    TargetUserName,
    LogonType,
    IpAddress,
    LogonProcessName
| extend AlertReason = "First-time remote access to sensitive system"
```

2. PASS-THE-HASH INDICATOR:
```kql
// NTLM logon without corresponding interactive session
let timeWindow = 1h;
let interactiveLogons =
    SecurityEvent
    | where TimeGenerated > ago(timeWindow)
    | where EventID == 4624
    | where LogonType in (2, 10, 11)  // Interactive types
    | summarize by TargetUserName, Computer;
SecurityEvent
| where TimeGenerated > ago(timeWindow)
| where EventID == 4624
| where LogonType == 3
| where AuthenticationPackageName == "NTLM"
| join kind=leftanti interactiveLogons on TargetUserName
| where TargetUserName !endswith "$"  // Exclude computer accounts
| project
    TimeGenerated,
    Computer,
    TargetUserName,
    IpAddress,
    AuthenticationPackageName,
    WorkstationName
```

3. ANOMALOUS SMB ACTIVITY:
```kql
// Unusual SMB connections from user accounts
SecurityEvent
| where TimeGenerated > ago(1d)
| where EventID == 5140  // Network share access
| where SubjectUserName !endswith "$"
| summarize
    ShareAccessCount = count(),
    UniqueShares = dcount(ShareName),
    UniqueComputers = dcount(Computer),
    SharesList = make_set(ShareName, 50)
    by SubjectUserName, bin(TimeGenerated, 1h)
| where UniqueComputers > 10 or UniqueShares > 20
| project
    TimeGenerated,
    SubjectUserName,
    ShareAccessCount,
    UniqueComputers,
    UniqueShares,
    TopShares = array_slice(SharesList, 0, 10)
```

4. DOMAIN CONTROLLER LATERAL MOVEMENT:
```kql
// Suspicious lateral movement to Domain Controllers
let dcComputers = dynamic(["DC01", "DC02"]);
SecurityEvent
| where TimeGenerated > ago(1d)
| where EventID == 4624
| where Computer in (dcComputers)
| where LogonType == 3
| where IpAddress !in (dcComputers)  // Not DC-to-DC
| where TargetUserName !endswith "$"
| join kind=inner (
    SecurityEvent
    | where EventID == 4672  // Special privilege assigned
    | project PrivAssignTime = TimeGenerated,
              TargetUserName, PrivilegesAssigned = PrivilegeList
) on TargetUserName
| where abs(datetime_diff('minute', TimeGenerated, PrivAssignTime)) < 5
| project
    TimeGenerated,
    Computer,
    TargetUserName,
    IpAddress,
    LogonProcessName,
    PrivilegesAssigned
```

CROSS-REFERENCE RECOMMENDATIONS:
- Correlate with MDE DeviceNetworkEvents for endpoint context
- Join with IdentityInfo for user risk level
- Check MDI alerts for same timeframe
```

### Privilege Escalation Detection

```
PROMPT: Create analytics for detecting privilege escalation attempts.

1. SENSITIVE GROUP MEMBERSHIP CHANGES:
```kql
// Addition to privileged groups
let sensitiveGroups = dynamic([
    "Domain Admins", "Enterprise Admins", "Schema Admins",
    "Account Operators", "Backup Operators", "Administrators",
    "DnsAdmins", "Group Policy Creator Owners"
]);
SecurityEvent
| where TimeGenerated > ago(1d)
| where EventID in (4728, 4732, 4756)  // Member added to group
| where TargetUserName has_any (sensitiveGroups)
| project
    TimeGenerated,
    TargetGroup = TargetUserName,
    AddedMember = MemberName,
    AddedBy = SubjectUserName,
    Computer
| extend Severity = case(
    TargetGroup in ("Domain Admins", "Enterprise Admins"), "Critical",
    TargetGroup in ("Schema Admins", "Account Operators"), "High",
    "Medium")
```

2. DCSYNC PERMISSION GRANT:
```kql
// Delegation of replication rights
SecurityEvent
| where TimeGenerated > ago(1d)
| where EventID == 5136
| where OperationType == "%%14674"  // Value Added
| where AttributeLDAPDisplayName == "nTSecurityDescriptor"
| where ObjectClass == "domainDNS"
| parse ObjectDN with * "DC=" Domain "," *
| project
    TimeGenerated,
    Domain,
    ModifiedBy = SubjectUserName,
    TargetObject = ObjectDN,
    Computer
| extend AlertReason = "Potential DCSync permission delegation"
```

3. ADMIN SDHOLDER MODIFICATION:
```kql
// Changes to AdminSDHolder (affects all protected objects)
SecurityEvent
| where TimeGenerated > ago(1d)
| where EventID == 5136
| where ObjectDN contains "CN=AdminSDHolder"
| project
    TimeGenerated,
    ModifiedBy = SubjectUserName,
    AttributeChanged = AttributeLDAPDisplayName,
    ObjectDN,
    Computer
| extend Severity = "Critical"
| extend AlertReason = "AdminSDHolder modification - affects all protected accounts"
```

4. SID HISTORY INJECTION:
```kql
// SID History added (can grant instant domain admin)
SecurityEvent
| where TimeGenerated > ago(1d)
| where EventID == 4765 or EventID == 4766
| project
    TimeGenerated,
    TargetAccount = TargetUserName,
    SIDHistory = SidHistory,
    AddedBy = SubjectUserName,
    Computer
| extend Severity = "Critical"
| extend AlertReason = "SID History modification - potential privilege escalation"
```

5. AZURE AD ROLE ELEVATION:
```kql
// Privileged Azure AD role assignment
AuditLogs
| where TimeGenerated > ago(1d)
| where OperationName in ("Add member to role", "Add eligible member to role")
| extend RoleName = tostring(TargetResources[0].displayName)
| where RoleName in ("Global Administrator", "Privileged Role Administrator",
    "Application Administrator", "Authentication Administrator",
    "Exchange Administrator", "SharePoint Administrator",
    "Security Administrator")
| extend TargetUser = tostring(TargetResources[0].userPrincipalName)
| extend Actor = tostring(InitiatedBy.user.userPrincipalName)
| project
    TimeGenerated,
    RoleName,
    TargetUser,
    Actor,
    OperationName,
    Result
```

ALERT PRIORITY MATRIX:
| Detection | Severity | Response SLA | Auto-Incident |
|-----------|----------|--------------|---------------|
| Domain Admins addition | Critical | 15 min | Yes |
| DCSync permission | Critical | 15 min | Yes |
| AdminSDHolder modification | Critical | 15 min | Yes |
| SID History injection | Critical | 15 min | Yes |
| Global Administrator | Critical | 15 min | Yes |
| Other privileged group | High | 1 hour | Yes |
```

---

## Part 3: Hunting Queries

### Proactive Identity Threat Hunting

```
PROMPT: Execute identity-focused threat hunting in Sentinel.

HUNTING HYPOTHESIS: [State the hypothesis being investigated]
TIMEFRAME: [Investigation window]
SCOPE: [Users/systems in scope]

HUNTING QUERY LIBRARY:

1. DORMANT ACCOUNT ACTIVATION:
```kql
// Accounts inactive for 90+ days suddenly active
let dormancyPeriod = 90d;
let recentActivity = 7d;
let dormantAccounts =
    SigninLogs
    | where TimeGenerated between (ago(dormancyPeriod) .. ago(recentActivity))
    | summarize LastActiveDate = max(TimeGenerated) by UserPrincipalName
    | where LastActiveDate < ago(dormancyPeriod - recentActivity);
SigninLogs
| where TimeGenerated > ago(recentActivity)
| where ResultType == "0"  // Successful
| join kind=inner dormantAccounts on UserPrincipalName
| project
    TimeGenerated,
    UserPrincipalName,
    DormantSince = LastActiveDate,
    DormancyDays = datetime_diff('day', TimeGenerated, LastActiveDate),
    IPAddress,
    Location = LocationDetails.city,
    AppDisplayName,
    DeviceDetail
```

2. IMPOSSIBLE TRAVEL DEEP DIVE:
```kql
// Refined impossible travel with velocity calculation
SigninLogs
| where TimeGenerated > ago(1d)
| where ResultType == "0"
| extend City = tostring(LocationDetails.city)
| extend Country = tostring(LocationDetails.countryOrRegion)
| extend Lat = toreal(LocationDetails.geoCoordinates.latitude)
| extend Long = toreal(LocationDetails.geoCoordinates.longitude)
| order by UserPrincipalName, TimeGenerated
| serialize
| extend PrevCity = prev(City, 1, City)
| extend PrevCountry = prev(Country, 1, Country)
| extend PrevLat = prev(Lat, 1, Lat)
| extend PrevLong = prev(Long, 1, Long)
| extend PrevTime = prev(TimeGenerated, 1, TimeGenerated)
| extend PrevUser = prev(UserPrincipalName, 1, "")
| where UserPrincipalName == PrevUser
| where City != PrevCity
| extend TimeDiffHours = datetime_diff('hour', TimeGenerated, PrevTime)
| extend DistanceKm = round(geo_distance_2points(Long, Lat, PrevLong, PrevLat) / 1000, 0)
| where TimeDiffHours > 0
| extend VelocityKmH = round(DistanceKm / TimeDiffHours, 0)
| where VelocityKmH > 1000  // Faster than commercial flight
| project
    TimeGenerated,
    UserPrincipalName,
    FromCity = PrevCity,
    ToCity = City,
    TimeDiffHours,
    DistanceKm,
    VelocityKmH,
    IPAddress
```

3. SERVICE PRINCIPAL ANOMALIES:
```kql
// Unusual service principal activity
AADServicePrincipalSignInLogs
| where TimeGenerated > ago(7d)
| summarize
    TotalRequests = count(),
    UniqueIPs = dcount(IPAddress),
    UniqueResources = dcount(ResourceDisplayName),
    ErrorCount = countif(ResultType != "0"),
    IPList = make_set(IPAddress, 20)
    by ServicePrincipalName, bin(TimeGenerated, 1d)
| order by ServicePrincipalName, TimeGenerated
| serialize
| extend PrevRequests = prev(TotalRequests, 1)
| extend PrevIPs = prev(UniqueIPs, 1)
| extend PrevUser = prev(ServicePrincipalName, 1, "")
| where ServicePrincipalName == PrevUser
| where TotalRequests > PrevRequests * 5  // 5x increase
    or UniqueIPs > PrevIPs * 2  // IP diversity increase
| project
    TimeGenerated,
    ServicePrincipalName,
    TotalRequests,
    PrevRequests,
    RequestIncrease = TotalRequests - PrevRequests,
    UniqueIPs,
    ErrorCount
```

4. LEGACY PROTOCOL USAGE:
```kql
// Tracking legacy auth protocols
SigninLogs
| where TimeGenerated > ago(7d)
| where ClientAppUsed in ("Exchange ActiveSync", "IMAP4", "POP3",
    "SMTP", "Authenticated SMTP", "Other clients")
| summarize
    LegacyAuthCount = count(),
    UniqueUsers = dcount(UserPrincipalName),
    UserList = make_set(UserPrincipalName, 100)
    by ClientAppUsed, bin(TimeGenerated, 1d)
| project
    TimeGenerated,
    ClientAppUsed,
    LegacyAuthCount,
    UniqueUsers,
    SampleUsers = array_slice(UserList, 0, 10)
```

5. OAUTH APPLICATION ABUSE:
```kql
// Suspicious OAuth consent grants
AuditLogs
| where TimeGenerated > ago(30d)
| where OperationName == "Consent to application"
| extend AppName = tostring(TargetResources[0].displayName)
| extend AppId = tostring(TargetResources[0].id)
| extend ConsentedBy = tostring(InitiatedBy.user.userPrincipalName)
| extend Permissions = TargetResources[0].modifiedProperties
| summarize
    ConsentCount = count(),
    Users = make_set(ConsentedBy, 100)
    by AppName, AppId
| where ConsentCount > 5  // Multiple users consenting
| project
    AppName,
    AppId,
    ConsentCount,
    ConsentedUsers = Users
```

HUNTING RESULTS DOCUMENTATION:
| Hypothesis | Query | Findings | Risk Level | Follow-up |
|------------|-------|----------|------------|-----------|
| [Hypothesis] | [Query #] | [Summary] | [H/M/L] | [Actions] |
```

---

## Part 4: Workbook Visualizations

### Identity Security Posture Dashboard

```
PROMPT: Create Sentinel workbook for identity security monitoring.

WORKBOOK STRUCTURE:

TAB 1: EXECUTIVE SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━

Tile 1: Authentication Health (KQL)
```kql
SigninLogs
| where TimeGenerated > ago(24h)
| summarize
    TotalSignIns = count(),
    Successful = countif(ResultType == "0"),
    Failed = countif(ResultType != "0")
| extend SuccessRate = round(100.0 * Successful / TotalSignIns, 1)
| project
    strcat("🟢 ", SuccessRate, "% Success Rate"),
    strcat("Total: ", TotalSignIns),
    strcat("Failed: ", Failed)
```

Tile 2: Risky Sign-ins (Last 24h)
```kql
SigninLogs
| where TimeGenerated > ago(24h)
| where RiskLevelAggregated in ("medium", "high")
| summarize Count = count() by RiskLevelAggregated
| extend Emoji = case(RiskLevelAggregated == "high", "🔴",
                      RiskLevelAggregated == "medium", "🟡", "🟢")
| project Display = strcat(Emoji, " ", RiskLevelAggregated, ": ", Count)
```

Tile 3: Identity Alerts (Last 24h)
```kql
SecurityAlert
| where TimeGenerated > ago(24h)
| where ProviderName in ("AATP", "Azure Active Directory Identity Protection")
| summarize Count = count() by AlertSeverity
| extend Order = case(AlertSeverity == "High", 1,
                      AlertSeverity == "Medium", 2, 3)
| order by Order
```

TAB 2: AUTHENTICATION TRENDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━

Chart 1: Sign-in Volume Over Time
```kql
SigninLogs
| where TimeGenerated > ago(7d)
| summarize
    Successful = countif(ResultType == "0"),
    Failed = countif(ResultType != "0")
    by bin(TimeGenerated, 1h)
| render timechart
```

Chart 2: Failed Sign-in Reasons
```kql
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType != "0"
| summarize Count = count() by ResultDescription
| top 10 by Count
| render piechart
```

Chart 3: Authentication by Location
```kql
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType == "0"
| extend Country = tostring(LocationDetails.countryOrRegion)
| summarize Count = count() by Country
| top 10 by Count
| render barchart
```

TAB 3: THREAT DETECTION
━━━━━━━━━━━━━━━━━━━━━━━

Grid 1: Active Identity Alerts
```kql
SecurityAlert
| where TimeGenerated > ago(7d)
| where ProviderName in ("AATP", "Azure Active Directory Identity Protection", "Microsoft 365 Defender")
| where Status != "Resolved"
| project
    TimeGenerated,
    AlertName,
    Severity = AlertSeverity,
    Status,
    Description,
    Entities
| order by TimeGenerated desc
```

Grid 2: Risky Users
```kql
SigninLogs
| where TimeGenerated > ago(7d)
| where RiskLevelAggregated in ("medium", "high")
| summarize
    RiskySignIns = count(),
    LastRisky = max(TimeGenerated),
    RiskLevels = make_set(RiskLevelAggregated)
    by UserPrincipalName
| order by RiskySignIns desc
| take 20
```

Chart 3: Attack Timeline
```kql
union
    (SecurityAlert
    | where ProviderName contains "Identity"
    | project TimeGenerated, Type = "Alert", Name = AlertName),
    (SigninLogs
    | where RiskLevelAggregated == "high"
    | project TimeGenerated, Type = "RiskySignIn", Name = UserPrincipalName)
| where TimeGenerated > ago(7d)
| summarize Count = count() by Type, bin(TimeGenerated, 4h)
| render timechart
```

TAB 4: PRIVILEGED ACCESS
━━━━━━━━━━━━━━━━━━━━━━━━

Grid 1: Privileged Role Assignments
```kql
AuditLogs
| where TimeGenerated > ago(30d)
| where OperationName has "role"
| where OperationName has_any ("Add", "Remove")
| extend Role = tostring(TargetResources[0].displayName)
| extend Target = tostring(TargetResources[0].userPrincipalName)
| extend Actor = tostring(InitiatedBy.user.userPrincipalName)
| project TimeGenerated, OperationName, Role, Target, Actor
| order by TimeGenerated desc
```

Grid 2: Admin Sign-in Activity
```kql
let adminUsers = IdentityInfo
| where AssignedRoles has_any ("Global Administrator", "Privileged Role Administrator")
| distinct AccountUPN;
SigninLogs
| where TimeGenerated > ago(7d)
| where UserPrincipalName in (adminUsers)
| project
    TimeGenerated,
    UserPrincipalName,
    IPAddress,
    Location = LocationDetails.city,
    AppDisplayName,
    Result = iff(ResultType == "0", "✓", "✗")
| order by TimeGenerated desc
```

TAB 5: HYBRID IDENTITY
━━━━━━━━━━━━━━━━━━━━━━

Chart 1: Sync Health
```kql
AADProvisioningLogs
| where TimeGenerated > ago(7d)
| summarize
    Success = countif(ResultType == "Success"),
    Failure = countif(ResultType == "Failure")
    by bin(TimeGenerated, 1h)
| render timechart
```

Grid 2: Sync Errors
```kql
AADProvisioningLogs
| where TimeGenerated > ago(24h)
| where ResultType == "Failure"
| project
    TimeGenerated,
    SourceIdentity,
    TargetIdentity,
    ErrorCode = ResultSignature,
    ErrorDescription = ResultDescription
| order by TimeGenerated desc
```

PARAMETER CONTROLS:
- TimeRange: Default 24h, options: 1h, 4h, 24h, 7d, 30d
- User Filter: Optional UPN filter
- Risk Level: All, High only, Medium+High
```

---

## Part 5: Automation and Response

### Logic App Playbooks for Identity Incidents

```
PROMPT: Design automated response playbooks for identity incidents.

PLAYBOOK 1: RISKY USER RESPONSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Trigger: Sentinel Alert (High-risk user detected)

Steps:
1. Parse alert entities (extract UserPrincipalName)
2. Get user details from Microsoft Graph
3. Check user's group memberships
4. If user in privileged group:
   - Send Teams notification to Security team
   - Create high-priority incident
5. If risk level = high:
   - Require password reset at next sign-in
   - Revoke refresh tokens
   - Notify user manager
6. Add incident comment with actions taken
7. Update incident severity based on user privilege level

Graph API Calls:
```json
// Get user
GET https://graph.microsoft.com/v1.0/users/{userPrincipalName}

// Check group membership
GET https://graph.microsoft.com/v1.0/users/{id}/memberOf

// Revoke sessions
POST https://graph.microsoft.com/v1.0/users/{id}/revokeSignInSessions

// Force password change
PATCH https://graph.microsoft.com/v1.0/users/{id}
{
    "passwordProfile": {
        "forceChangePasswordNextSignIn": true
    }
}
```

PLAYBOOK 2: COMPROMISED ACCOUNT CONTAINMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Trigger: MDI Alert (Account compromise confirmed)

Steps:
1. Parse alert - get affected account
2. Immediate actions:
   - Disable account in both AD and Entra
   - Revoke all sessions
   - Remove from all groups (save list for recovery)
3. Investigation enrichment:
   - Pull last 24h sign-in activity
   - Pull last 24h audit logs for user
   - Check mailbox rules (if Exchange)
4. Notification:
   - Alert SOC with full context
   - Notify IT for device isolation
   - Notify HR if employee
5. Create Sentinel incident with:
   - All enrichment data
   - Timeline of actions taken
   - Recovery instructions

PLAYBOOK 3: PRIVILEGED ROLE CHANGE APPROVAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Trigger: Sentinel Alert (Privileged role assignment)

Steps:
1. Parse audit event details
2. Check if assignment was through PIM:
   - If yes, validate approval workflow
   - If no (direct assignment), flag as suspicious
3. Send approval request to Security team via Teams
4. Wait for approval (timeout: 30 minutes)
5. If approved:
   - Log approval in Sentinel
   - Close incident
6. If denied or timeout:
   - Remove the role assignment
   - Disable the assigning admin account
   - Escalate to security leadership
   - Create high-severity incident

PLAYBOOK ERROR HANDLING:
- Retry Logic: 3 attempts with exponential backoff
- Failure Notification: Email to SOC
- Manual Override: Allow analyst to bypass automation
- Audit Trail: Log all actions in incident comments
```

---

## Quick Reference Card

```
SENTINEL IDENTITY HUNTING QUICK QUERIES

Password Spray:
SigninLogs | where ResultType == "50126" | summarize count() by IPAddress, bin(TimeGenerated, 10m) | where count_ > 30

Risky Sign-ins Today:
SigninLogs | where TimeGenerated > ago(24h) | where RiskLevelAggregated in ("medium","high") | project TimeGenerated, UserPrincipalName, RiskLevelAggregated, IPAddress

Privileged Role Changes:
AuditLogs | where OperationName has "role" | where TimeGenerated > ago(24h) | project TimeGenerated, OperationName, TargetResources

Dormant Account Login:
SigninLogs | where TimeGenerated > ago(1d) | join kind=inner (IdentityInfo | where LastPasswordChangeTime < ago(180d)) on $left.UserPrincipalName == $right.AccountUPN

Service Principal Failures:
AADServicePrincipalSignInLogs | where ResultType != "0" | summarize count() by ServicePrincipalName, ResultDescription

Legacy Auth Usage:
SigninLogs | where ClientAppUsed !in ("Browser","Mobile Apps and Desktop clients") | summarize count() by ClientAppUsed

KEY TABLES:
- SigninLogs: Interactive user sign-ins
- AADNonInteractiveUserSignInLogs: Background app activity
- AADServicePrincipalSignInLogs: App/service activity
- AuditLogs: Configuration changes
- SecurityAlert: MDI, AADIP alerts
- IdentityInfo: User metadata
- SecurityEvent: On-prem AD events
```

---

*Document Version: 1.0*
*Framework: Microsoft Sentinel Identity Analytics*
*Integration: Entra ID, MDI, Active Directory*
