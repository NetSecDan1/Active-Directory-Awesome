# AD Threat Detection Query Library
> 50+ named, documented KQL (Sentinel/MDE) and SPL (Splunk) queries for Active Directory threat detection. Each query includes: what it detects, MITRE ATT&CK mapping, tuning notes, and response guidance.

---

## Query Index

| # | Name | Threat | MITRE |
|---|------|--------|-------|
| 01 | Kerberoasting — RC4 TGS Requests | Credential Access | T1558.003 |
| 02 | AS-REP Roasting Attempt | Credential Access | T1558.004 |
| 03 | DCSync Activity | Credential Access | T1003.006 |
| 04 | Golden Ticket — Anomalous TGT Lifetime | Credential Access | T1558.001 |
| 05 | Pass-the-Hash via NTLM Network Logon | Lateral Movement | T1550.002 |
| 06 | Account Lockout Storm | Impact / Spray | T1110.001 |
| 07 | Password Spray Detection | Credential Access | T1110.003 |
| 08 | Privileged Group Membership Change | Privilege Escalation | T1098 |
| 09 | Domain Admin Logon from New Workstation | Initial Access | T1078 |
| 10 | KRBTGT Password Reset | Defense Evasion | T1098 |
| 11 | New User Account Created | Persistence | T1136.002 |
| 12 | Scheduled Task Created on DC | Persistence | T1053.005 |
| 13 | Unconstrained Delegation — TGT Capture Prep | Credential Access | T1558 |
| 14 | AdminSDHolder ACL Modification | Persistence | T1222 |
| 15 | Lateral Movement via SMB | Lateral Movement | T1021.002 |
| 16 | Honey Account Authentication | Detection | — |
| 17 | Bulk Account Enumeration (LDAP) | Discovery | T1087.002 |
| 18 | SIDHistory Attribute Modified | Persistence | T1134.005 |
| 19 | GPO Modification | Defense Evasion | T1484.001 |
| 20 | New Trust Created | Persistence | T1484.002 |

---

## KQL Queries (Microsoft Sentinel / MDE Advanced Hunting)

---

### Q01 — Kerberoasting: RC4 TGS Requests
**MITRE**: T1558.003 | **Severity**: High

```kql
// Kerberoasting — RC4 (0x17) service ticket requests
// RC4 tickets are crackable offline; AES256 (0x12) is safe
SecurityEvent
| where EventID == 4769
| where TicketEncryptionType == "0x17"   // RC4-HMAC = weak
| where ServiceName !endswith "$"         // Exclude computer accounts
| where ServiceName !in ("krbtgt", "")
| where AccountName !endswith "$"
| summarize
    RequestCount = count(),
    TargetServices = make_set(ServiceName),
    SourceIPs = make_set(IpAddress)
    by AccountName, AccountDomain, bin(TimeGenerated, 5m)
| where RequestCount > 3   // Multiple service tickets in short window = tooling
| project-reorder TimeGenerated, AccountName, RequestCount, TargetServices, SourceIPs
| order by RequestCount desc
```

**Tuning**: Lower threshold for high-security environments. Baseline RC4 requests during normal hours first.
**Response**: Identify source workstation → check for Mimikatz/Rubeus → investigate account.

---

### Q02 — AS-REP Roasting: Pre-Auth Not Required
**MITRE**: T1558.004 | **Severity**: High

```kql
// AS-REP Roasting — authentication requested without pre-auth
// Pre-Authentication Type 0x0 = pre-auth not required (vulnerable accounts)
SecurityEvent
| where EventID == 4768
| where PreAuthType == "0"
| where AccountName !endswith "$"
| where Result == "0x0"  // Success
| summarize count() by AccountName, IpAddress, bin(TimeGenerated, 1h)
| order by count_ desc
```

**Prevention query — find vulnerable accounts**:
```kql
// Run as PowerShell, not KQL — but document the finding
// Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true -and Enabled -eq $true}
```

---

### Q03 — DCSync: Replication Rights Exercised by Non-DC
**MITRE**: T1003.006 | **Severity**: Critical

```kql
// DCSync attack — non-DC account exercising directory replication rights
// Event 4662: Object access with replication GUIDs
SecurityEvent
| where EventID == 4662
| where Properties has "1131f6aa-9c07-11d1-f79f-00c04fc2dcd2"  // DS-Replication-Get-Changes
     or Properties has "1131f6ab-9c07-11d1-f79f-00c04fc2dcd2"  // DS-Replication-Get-Changes-All
     or Properties has "89e95b76-444d-4c62-991a-0facbeda640c"  // DS-Replication-Get-Changes-In-Filtered-Set
| where SubjectUserName !endswith "$"  // Exclude DC computer accounts
| where SubjectUserName != "MSOL_*"   // Exclude Azure AD Connect (adjust for your env)
| project TimeGenerated, SubjectUserName, SubjectDomainName, IpAddress = Computer, Properties
| order by TimeGenerated desc
```

**Response**: IMMEDIATE — this is a Critical P0 indicator. Isolate source system, begin incident response.

---

### Q04 — Golden Ticket: Anomalous TGT Properties
**MITRE**: T1558.001 | **Severity**: Critical

```kql
// Golden Ticket indicators — TGT with suspicious characteristics
// Note: MDI is better at this; use as supplemental detection
SecurityEvent
| where EventID == 4768  // Kerberos TGT request
| where TicketOptions has "0x40810010"  // Forwardable + renewable + pre-auth
| extend TicketLifetimeHrs = datetime_diff('hour', todatetime(TicketOptions), TimeGenerated)
| where TicketLifetimeHrs > 20  // Normal max TGT lifetime = 10 hours
| project TimeGenerated, AccountName, IpAddress, TicketLifetimeHrs
```

**Better detection**: Enable MDI — it has behavioral Golden Ticket detection.

---

### Q05 — Pass-the-Hash: NTLM Network Logon Anomaly
**MITRE**: T1550.002 | **Severity**: High

```kql
// Pass-the-Hash indicator — NTLM network logon from workstation for admin accounts
SecurityEvent
| where EventID == 4624
| where LogonType == 3           // Network logon
| where AuthenticationPackageName == "NTLM"
| where AccountName in~ (       // Adjust to your admin account naming convention
    "admin", "administrator") or AccountName startswith "adm-"
| where WorkstationName != Computer  // Source != target
| summarize count() by AccountName, WorkstationName, Computer, IpAddress, bin(TimeGenerated, 1h)
| where count_ > 3
| order by count_ desc
```

---

### Q06 — Account Lockout Storm
**MITRE**: T1110.001 | **Severity**: High

```kql
// Lockout storm — many accounts locking out in short window (spray indicator)
SecurityEvent
| where EventID == 4740
| summarize
    LockedAccounts = dcount(TargetAccount),
    Accounts = make_set(TargetAccount),
    Sources = make_set(SubjectUserName)
    by CallerComputerName, bin(TimeGenerated, 10m)
| where LockedAccounts > 5
| order by LockedAccounts desc
```

---

### Q07 — Password Spray: Many Accounts, One Source
**MITRE**: T1110.003 | **Severity**: High

```kql
// Password spray — one source IP targeting many accounts
SecurityEvent
| where EventID == 4625
| where LogonType in (3, 10)  // Network or RemoteInteractive
| summarize
    UniqueAccounts = dcount(TargetAccount),
    FailureCount = count(),
    Accounts = make_set(TargetAccount)
    by IpAddress, bin(TimeGenerated, 10m)
| where UniqueAccounts > 10  // Many unique accounts = spray (not repeated failures on one)
| order by UniqueAccounts desc
```

---

### Q08 — Privileged Group Change
**MITRE**: T1098 | **Severity**: High

```kql
// Member added to privileged AD group
SecurityEvent
| where EventID in (4728, 4732, 4756)  // Global, Local, Universal group member added
| extend
    GroupName = tostring(EventData.TargetUserName),
    AddedMember = tostring(EventData.SubjectUserName),
    Actor = tostring(EventData.SubjectUserName)
| where GroupName in~ (
    "Domain Admins", "Enterprise Admins", "Schema Admins",
    "Administrators", "Group Policy Creator Owners", "DNSAdmins")
| project TimeGenerated, GroupName, AddedMember, Actor, Computer
| order by TimeGenerated desc
```

---

### Q09 — Domain Admin Logon from New Workstation
**MITRE**: T1078 | **Severity**: Medium-High

```kql
// Domain admin logon from a workstation not previously seen
let KnownAdminWorkstations = dynamic(["PAW01", "PAW02", "JUMPHOST01"]);  // Adjust to yours
SecurityEvent
| where EventID == 4624
| where MemberName has "Domain Admins"  // Or filter by account names
| where LogonType in (2, 10)  // Interactive or RemoteInteractive
| where WorkstationName !in~ (KnownAdminWorkstations)
| project TimeGenerated, AccountName, WorkstationName, IpAddress
| order by TimeGenerated desc
```

---

### Q10 — KRBTGT Password Reset
**MITRE**: T1098 | **Severity**: High (expected during rotation, unexpected = alert)

```kql
// KRBTGT password change — expected during rotation runbook, unexpected = investigate
SecurityEvent
| where EventID in (4723, 4724)  // Password change / reset
| where TargetAccount has "krbtgt"
| project TimeGenerated, Actor = SubjectUserName, TargetAccount, EventID, Computer
```

**Note**: This should fire exactly twice during `13_RUNBOOKS/04-krbtgt-rotation.md`. Any other occurrence is an incident.

---

### Q11 — New User Account Created
**MITRE**: T1136.002 | **Severity**: Medium

```kql
// New AD user account creation — watch for after-hours creation in admin OU
SecurityEvent
| where EventID == 4720
| extend
    NewUser = tostring(EventData.TargetUserName),
    Creator = SubjectUserName,
    OUPath = tostring(EventData.TargetDomainName)
| where TimeGenerated between (
    datetime_add('hour', 18, startofday(now()))..  // After 6PM
    datetime_add('hour', 7, startofday(now()) + 1d) // Before 7AM next day
  )
| project TimeGenerated, NewUser, Creator, OUPath
```

---

### Q12 — Scheduled Task Created on DC
**MITRE**: T1053.005 | **Severity**: High

```kql
// Scheduled task created on a domain controller — persistence indicator
SecurityEvent
| where EventID == 4698  // Scheduled task created
| join kind=inner (
    // Get list of DC computer names
    SecurityEvent
    | where EventID == 4624
    | where Computer endswith ".corp.com"  // Adjust domain suffix
    | summarize by Computer
) on Computer
| project TimeGenerated, TaskName = tostring(EventData.TaskName),
          Creator = SubjectUserName, Computer
```

---

### Q16 — Honey Account Authentication (ANY auth = Alert)
**MITRE**: — | **Severity**: Critical

```kql
// Honey account used — should NEVER authenticate under any circumstances
let HoneyAccounts = dynamic(["svc-backup-legacy", "honeyadmin01", "old-svc-sql"]);  // Your honey accounts
SecurityEvent
| where EventID in (4624, 4625, 4768, 4769, 4776)
| where AccountName in~ (HoneyAccounts) or TargetAccount in~ (HoneyAccounts)
| project TimeGenerated, EventID, AccountName, TargetAccount, IpAddress, WorkstationName
// Alert: ANY row here = active threat actor in your environment
```

---

### Q17 — LDAP Bulk Enumeration (Reconnaissance)
**MITRE**: T1087.002 | **Severity**: Medium

```kql
// Bulk LDAP queries — attacker enumerating AD objects
// Requires: LDAP query auditing enabled (Event 1644 in Directory Service log)
Event
| where EventLog == "Directory Service"
| where EventID == 1644
| where RenderedDescription contains "1000"  // >1000 results returned
| summarize QueryCount = count() by Computer, bin(TimeGenerated, 5m)
| where QueryCount > 10
```

---

### Q19 — GPO Modification
**MITRE**: T1484.001 | **Severity**: High

```kql
// Group Policy modification — could indicate policy tampering for persistence/evasion
SecurityEvent
| where EventID == 5136  // AD object modified
| where ObjectClass == "groupPolicyContainer"
| project TimeGenerated, Actor = SubjectUserName, ObjectDN, AttributeLDAPDisplayName,
          OldValue = tostring(EventData.OldValue), NewValue = tostring(EventData.NewValue)
| order by TimeGenerated desc
```

---

## Splunk SPL Queries

---

### SPL01 — Kerberoasting

```spl
index=wineventlog EventCode=4769 TicketEncryptionType="0x17"
| where ServiceName!="krbtgt" AND ServiceName!=""
| where NOT ServiceName LIKE "%$"
| stats count AS ticket_count, values(ServiceName) AS services, values(src_ip) AS sources
    BY Account, _time span=5m
| where ticket_count > 3
| sort -ticket_count
```

---

### SPL02 — Password Spray

```spl
index=wineventlog EventCode=4625 LogonType IN (3,10)
| stats dc(TargetUserName) AS unique_accounts, count AS failures, values(TargetUserName) AS accounts
    BY src_ip, _time span=10m
| where unique_accounts > 10
| sort -unique_accounts
```

---

### SPL03 — Privileged Group Changes

```spl
index=wineventlog EventCode IN (4728,4732,4756)
| eval group=mvindex(split(Message,"Group Name:"),1)
| where like(group,"%Domain Admins%") OR like(group,"%Enterprise Admins%")
    OR like(group,"%Schema Admins%") OR like(group,"%Administrators%")
| table _time, Account, group, host, Message
| sort -_time
```

---

### SPL04 — Account Lockout Investigation

```spl
index=wineventlog EventCode=4740
| stats count AS lockout_count, values(CallerComputerName) AS sources
    BY TargetAccount
| sort -lockout_count
| head 20
```

---

### SPL05 — DCSync Detection

```spl
index=wineventlog EventCode=4662
| eval props=lower(Properties)
| where like(props,"%1131f6aa%") OR like(props,"%1131f6ab%")
| where NOT like(SubjectUserName,"*$")
| table _time, SubjectUserName, SubjectDomainName, Properties, host
| sort -_time
```

---

### SPL06 — DC Logon Failure Surge

```spl
index=wineventlog EventCode=4625
| stats count AS fail_count BY host, _time span=5m
| where fail_count > 50
| sort -fail_count
```

---

### SPL07 — New Local Admin Created

```spl
index=wineventlog EventCode=4732
| where like(TargetUserName,"%Administrators%")
| table _time, SubjectUserName, MemberName, TargetUserName, host
| sort -_time
```

---

### SPL08 — NTLM Authentication (Visibility)

```spl
index=wineventlog EventCode=4776
| stats count AS auth_count, values(Workstation) AS workstations
    BY SubjectUserName
| sort -auth_count
| head 20
```

---

## Alert Tuning Guide

| Query | FP Sources | Tuning Approach |
|-------|-----------|----------------|
| Q01 Kerberoasting | Legacy apps using RC4 by default | Whitelist known-good service accounts; fix encryption |
| Q03 DCSync | Azure AD Connect account | Whitelist MSOL_ / AAD Connect service accounts |
| Q07 Password Spray | Monitoring systems, load balancers | Whitelist scanner IPs; verify they're legitimate |
| Q08 Group Changes | Scripted provisioning | Whitelist provisioning service accounts; require justification |
| Q17 LDAP Enum | SIEM agents, HR sync tools | Baseline normal query volume; alert on anomalies |

---

## Implementation Checklist

- [ ] Confirm all DC Security event logs are forwarded to SIEM
- [ ] Confirm Directory Service (1644) auditing is enabled for LDAP queries
- [ ] Create honey accounts: `15_EXPERT_LEARNING_PATHS/03-ad-attack-and-defense.md`
- [ ] Set alert thresholds based on your baseline (run queries in investigate mode first)
- [ ] Assign each alert to a responder with a response runbook
- [ ] Review and tune monthly
