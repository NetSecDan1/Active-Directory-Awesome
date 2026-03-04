# Microsoft Defender for Endpoint: Identity-Focused Investigation

## System Prompt

```
You are an expert security analyst specializing in Microsoft Defender for Endpoint (MDE)
with a focus on identity-related threats and Active Directory attack detection. Your role
is to help engineers correlate endpoint telemetry with identity events to detect lateral
movement, credential theft, and Active Directory attacks.

CORE PRINCIPLES:
1. Endpoint behavior often reveals identity attacks before they appear in AD logs
2. Correlate MDE alerts with sign-in logs, MDI alerts, and AD events
3. Process injection and credential access are precursors to identity compromise
4. Think like an attacker: endpoints are stepping stones to domain compromise

CONFIDENCE FRAMEWORK:
- HIGH: MDE alert + correlated identity event + timeline match
- MEDIUM: MDE alert with identity implications but no direct correlation
- LOW: Behavioral anomaly that may indicate identity attack
- SPECULATIVE: Pattern matching without direct evidence
```

---

## Part 1: Identity Attack Detection via MDE

### Credential Theft Detection Prompt

```
CONTEXT: You are investigating potential credential theft detected by MDE.

ALERT DETAILS:
- Alert Name: [Paste alert name]
- Device: [Device name]
- User Context: [User logged in]
- Detection Time: [Timestamp]
- Process Tree: [If available]

ANALYSIS REQUIREMENTS:

1. CREDENTIAL ACCESS TECHNIQUE IDENTIFICATION:
   Map to MITRE ATT&CK T1003 subtechniques:
   □ T1003.001 - LSASS Memory (mimikatz, procdump, comsvcs.dll)
   □ T1003.002 - SAM Database (reg save, shadow copy)
   □ T1003.003 - NTDS.dit (ntdsutil, vssadmin)
   □ T1003.004 - LSA Secrets (registry extraction)
   □ T1003.005 - Cached Credentials
   □ T1003.006 - DCSync (replication requests)

2. IMPACTED CREDENTIALS ASSESSMENT:
   Based on process and user context, what credentials may be compromised?

   | Credential Type | Risk Level | Evidence |
   |-----------------|------------|----------|
   | Local admin hash | ? | ? |
   | Domain user hash | ? | ? |
   | Kerberos tickets | ? | ? |
   | Service account | ? | ? |
   | Cached creds | ? | ? |

3. BLAST RADIUS CALCULATION:
   If credentials were stolen, what can attacker access?
   - Same user on other machines
   - Service accounts and their permissions
   - Cached privileged credentials
   - Kerberos ticket validity window

4. TIMELINE CORRELATION:
   Query requirements for correlation:
   - AD logon events for this user (4624, 4625)
   - MDI alerts for same timeframe
   - Other endpoints with same user activity

OUTPUT FORMAT:
**Credential Theft Assessment**
- Technique: [Specific method]
- Confidence: [HIGH/MEDIUM/LOW]
- Impacted Credentials: [List]
- Recommended Response: [Immediate actions]
```

### KQL Queries for Identity Investigation

```
PROMPT: Generate MDE Advanced Hunting queries for identity-focused investigation.

INVESTIGATION CONTEXT:
- Scope: [Specific user/device/timeframe]
- Concern: [Type of identity attack suspected]
- Known IOCs: [If any]

QUERY CATEGORIES NEEDED:

1. CREDENTIAL ACCESS DETECTION:
```kql
// LSASS Access Detection
DeviceProcessEvents
| where Timestamp > ago(24h)
| where FileName =~ "lsass.exe" or InitiatingProcessFileName =~ "lsass.exe"
| where ActionType in ("ProcessAccessed", "CreateRemoteThreadApiCall")
| project Timestamp, DeviceName, AccountName, InitiatingProcessFileName,
          InitiatingProcessCommandLine, FileName
| sort by Timestamp desc

// Suspicious credential tool execution
DeviceProcessEvents
| where Timestamp > ago(7d)
| where FileName in~ ("mimikatz.exe", "procdump.exe", "sekurlsa.exe")
   or ProcessCommandLine has_any ("sekurlsa", "lsadump", "kerberos::list",
      "privilege::debug", "token::elevate")
| project Timestamp, DeviceName, AccountName, FileName, ProcessCommandLine
```

2. LATERAL MOVEMENT TRACKING:
```kql
// Remote execution following credential access
let credentialAccessDevices =
    DeviceAlertEvents
    | where Timestamp > ago(24h)
    | where Title has_any ("credential", "LSASS", "mimikatz")
    | distinct DeviceId;
DeviceNetworkEvents
| where Timestamp > ago(24h)
| where DeviceId in (credentialAccessDevices)
| where RemotePort in (445, 135, 5985, 5986, 22, 3389)
| summarize ConnectionCount=count(),
    TargetIPs=make_set(RemoteIP),
    Ports=make_set(RemotePort) by DeviceName, AccountName
| where ConnectionCount > 5
```

3. KERBEROS ATTACK INDICATORS:
```kql
// Potential Kerberoasting
DeviceNetworkEvents
| where Timestamp > ago(24h)
| where RemotePort == 88  // Kerberos
| summarize KerberosRequests=count() by DeviceName, AccountName, bin(Timestamp, 1h)
| where KerberosRequests > 50  // Unusual volume

// AS-REP Roasting indicators
DeviceProcessEvents
| where Timestamp > ago(7d)
| where ProcessCommandLine has_any ("asreproast", "GetNPUsers",
    "rubeus asrep", "Invoke-ASREPRoast")
```

4. DCSYNC DETECTION:
```kql
// DCSync from non-DC
DeviceNetworkEvents
| where Timestamp > ago(24h)
| where RemotePort == 135 or RemotePort == 389
| where RemoteIP has_any (DC_IPs)  // Replace with actual DC IPs
| join kind=inner (
    DeviceInfo
    | where DeviceType != "DomainController"
) on DeviceId
| where ActionType == "ConnectionSuccess"
| project Timestamp, DeviceName, RemoteIP, AccountName
```

OUTPUT: Provide queries customized to investigation context with:
- Timeframe appropriate to incident
- Filters for specific users/devices
- Correlation joins where valuable
```

---

## Part 2: Endpoint-to-Identity Attack Correlation

### Lateral Movement Investigation Prompt

```
CONTEXT: Investigating potential lateral movement following credential compromise.

INITIAL COMPROMISE:
- Patient Zero Device: [Device name]
- Compromised Account: [Account name]
- Compromise Time: [Timestamp]
- Method: [How credentials were obtained]

INVESTIGATION WORKFLOW:

PHASE 1: MAP CREDENTIAL USAGE
What did the compromised credential access after theft?

Query MDE for:
□ Remote logons using this account
□ Service installations (psexec, WMI)
□ Remote scheduled tasks
□ PowerShell remoting connections
□ RDP sessions initiated

Expected Evidence:
- DeviceLogonEvents where AccountName = "[compromised account]" and LogonType = "RemoteInteractive"
- DeviceProcessEvents for remote execution tools
- DeviceNetworkEvents for lateral connections

PHASE 2: IDENTIFY HOP PATTERN
```
[Patient Zero] → [Hop 1] → [Hop 2] → [Target?]
     |              |          |
   Time: T0      T+?min     T+?min
   Method: ?     Method: ?   Method: ?
```

For each hop:
- How did attacker move? (psexec/WMI/RDP/PowerShell)
- What credentials were used?
- Were new credentials harvested?
- What is the asset value of this system?

PHASE 3: TIMELINE RECONSTRUCTION
Create consolidated timeline from:
- MDE process execution
- MDE network connections
- AD logon events (4624/4625)
- MDI alerts
- Entra sign-in logs (if hybrid)

| Time | Source | Event | Device | Account | Details |
|------|--------|-------|--------|---------|---------|
| ? | MDE | ? | ? | ? | ? |

PHASE 4: SCOPE DETERMINATION
Based on lateral movement pattern:

1. All compromised endpoints: [List]
2. All potentially compromised accounts: [List]
3. Data/systems accessed: [List]
4. Current attacker position: [Assessment]

CONTAINMENT RECOMMENDATION:
Based on blast radius analysis, recommend:
□ Account disables needed
□ Device isolation needed
□ Password resets required
□ Ticket invalidation (krbtgt if Kerberos compromise)
```

### Pass-the-Hash/Pass-the-Ticket Detection

```
PROMPT: Analyze potential pass-the-hash or pass-the-ticket attack indicators.

DETECTION TRIGGERS:
- MDE Alert: [Alert details]
- Anomalous Authentication Pattern: [Description]
- Timeline: [Relevant timeframe]

ANALYSIS FRAMEWORK:

1. PASS-THE-HASH INDICATORS:

   MDE Evidence:
   □ LSASS access preceding remote authentication
   □ NTLM authentication without prior interactive logon
   □ Remote logon with local account hash
   □ Tool execution: sekurlsa::pth, Invoke-SMBExec

   AD Evidence to Correlate:
   □ 4624 Type 3 with NTLM without Type 2/10 first
   □ 4776 NTLM validation for unusual source
   □ Logon from multiple devices simultaneously

2. PASS-THE-TICKET INDICATORS:

   MDE Evidence:
   □ Rubeus, Mimikatz kerberos:: commands
   □ Ticket injection API calls
   □ TGT/TGS extraction detected

   AD/MDI Evidence to Correlate:
   □ Ticket used from different IP than issue IP
   □ Forged ticket anomalies
   □ Encryption downgrade attacks

3. GOLDEN/SILVER TICKET INDICATORS:

   MDE Evidence:
   □ krbtgt hash extraction
   □ Service account hash extraction
   □ Ticket lifetime anomalies

   AD Evidence:
   □ Tickets with unusual validity periods
   □ TGT without corresponding AS-REQ
   □ Service ticket without TGT request

CORRELATION QUERY STRUCTURE:
```kql
// Combine MDE credential access with AD auth anomalies
let credentialAccess = DeviceAlertEvents
| where Title has_any ("credential", "hash", "ticket")
| project DeviceId, DeviceName, CredAccessTime=Timestamp, AccountName;

let suspiciousAuth = IdentityLogonEvents
| where LogonType == "Remote"
| where AuthenticationMethod == "NTLM" or Protocol == "Kerberos"
| project AuthTime=Timestamp, TargetDevice=DestinationDeviceName,
          SourceIP=IPAddress, AuthAccount=AccountUpn;

credentialAccess
| join kind=inner suspiciousAuth
    on $left.AccountName == $right.AuthAccount
| where AuthTime between (CredAccessTime .. (CredAccessTime + 4h))
| project CredAccessTime, AuthTime, DeviceName, TargetDevice,
          AccountName, SourceIP
```

OUTPUT:
- Attack Type: [PTH/PTT/Golden/Silver]
- Confidence: [With reasoning]
- Evidence Chain: [MDE → AD correlation]
- Accounts Requiring Reset: [List]
```

---

## Part 3: Active Directory Attack Surface Monitoring

### Domain Controller Monitoring via MDE

```
PROMPT: Domain Controller security monitoring using MDE telemetry.

DC INVENTORY:
- DCs being monitored: [List DC names]
- MDE onboarding status: [Confirmed/Partial]
- MDI sensor status: [If applicable]

MONITORING REQUIREMENTS:

1. UNUSUAL PROCESS EXECUTION ON DCs:
```kql
// Processes that should never run on DCs
let suspiciousProcesses = dynamic(["mimikatz.exe", "procdump.exe",
    "psexec.exe", "pwdump.exe", "gsecdump.exe", "wce.exe"]);
DeviceProcessEvents
| where DeviceName in (DC_Names)  // Replace with DC names
| where FileName in~ (suspiciousProcesses)
    or ProcessCommandLine has_any ("sekurlsa", "lsadump", "dcsync")
| project Timestamp, DeviceName, AccountName, FileName,
          ProcessCommandLine, InitiatingProcessFileName

// PowerShell on DCs (should be limited)
DeviceProcessEvents
| where DeviceName in (DC_Names)
| where FileName =~ "powershell.exe"
| where ProcessCommandLine has_any ("invoke-", "iex", "downloadstring",
    "-enc", "-e ", "bypass")
```

2. REMOTE CONNECTIONS TO DCs:
```kql
// Non-standard remote connections
DeviceNetworkEvents
| where DeviceName in (DC_Names)
| where ActionType == "ConnectionAccepted"
| where RemotePort in (5985, 5986, 22, 3389)
| where RemoteIP !in (Admin_Workstations)  // Replace with PAW IPs
| project Timestamp, DeviceName, RemoteIP, RemotePort,
          InitiatingProcessFileName
```

3. NTDS.DIT ACCESS:
```kql
// Direct database access attempts
DeviceFileEvents
| where DeviceName in (DC_Names)
| where FolderPath contains "NTDS"
| where FileName =~ "ntds.dit" or FileName =~ "SYSTEM"
| where ActionType in ("FileRead", "FileCopied", "FileRenamed")
| project Timestamp, DeviceName, AccountName, ActionType,
          FolderPath, InitiatingProcessFileName
```

4. DCSYNC DETECTION:
```kql
// Replication requests from non-DCs
DeviceNetworkEvents
| where RemotePort in (135, 389, 636)
| where RemoteIP in (DC_IPs)
| where DeviceName !in (DC_Names)
| join kind=inner (
    DeviceProcessEvents
    | where ProcessCommandLine has_any ("dcsync", "lsadump::dcsync",
        "Get-ADReplAccount", "-ReplicaDC")
) on DeviceId
| project Timestamp, DeviceName, RemoteIP, ProcessCommandLine
```

ALERT THRESHOLDS:
| Scenario | Threshold | Severity |
|----------|-----------|----------|
| Credential tool on DC | Any | Critical |
| Admin remote from non-PAW | Any | High |
| NTDS.dit access | Any | Critical |
| Unusual replication source | Any | Critical |
| PowerShell obfuscation on DC | Any | High |
```

### Service Account Abuse Detection

```
PROMPT: Detect service account abuse using MDE and identity correlation.

SERVICE ACCOUNTS OF CONCERN:
- Account Names: [List service accounts]
- Expected Behavior: [Normal usage pattern]
- Anomaly Detected: [What triggered investigation]

DETECTION METHODOLOGY:

1. INTERACTIVE LOGON WITH SERVICE ACCOUNTS:
   Service accounts should NOT log on interactively.

```kql
let serviceAccounts = dynamic(["svc_sql", "svc_backup", "svc_app"]);
DeviceLogonEvents
| where AccountName in (serviceAccounts)
| where LogonType in ("Interactive", "RemoteInteractive")
| project Timestamp, DeviceName, AccountName, LogonType,
          RemoteIP, InitiatingProcessFileName
```

2. SERVICE ACCOUNT LATERAL MOVEMENT:
```kql
let serviceAccounts = dynamic(["svc_sql", "svc_backup"]);
DeviceNetworkEvents
| where AccountName in (serviceAccounts)
| where RemotePort in (445, 135, 5985, 3389)
| summarize
    TargetCount=dcount(RemoteIP),
    Targets=make_set(RemoteIP) by AccountName, DeviceName
| where TargetCount > 3  // Service accounts typically talk to few hosts
```

3. UNUSUAL PROCESS EXECUTION:
```kql
// Service accounts running unexpected processes
let serviceAccounts = dynamic(["svc_sql", "svc_backup"]);
let expectedProcesses = dynamic(["sqlservr.exe", "backupexec.exe"]);
DeviceProcessEvents
| where AccountName in (serviceAccounts)
| where FileName !in~ (expectedProcesses)
| where FileName !in~ ("conhost.exe", "cmd.exe")  // Filter noise
| project Timestamp, DeviceName, AccountName, FileName,
          ProcessCommandLine
```

4. KERBEROASTING OF SERVICE ACCOUNTS:
   Correlate with MDI Kerberoasting alerts.

   If service account TGS was requested:
   □ Was the SPN enumerated first?
   □ From what endpoint?
   □ Was offline cracking attempted?
   □ Has the account been used suspiciously since?

SERVICE ACCOUNT FORENSICS:
| Account | Expected Hosts | Actual Hosts | Expected Process | Actual Process | Verdict |
|---------|----------------|--------------|------------------|----------------|---------|
| [Name] | [List] | [MDE shows] | [Process] | [MDE shows] | [OK/Suspicious] |

RESPONSE ACTIONS:
If service account compromise confirmed:
□ Disable account (impact assessment first)
□ Rotate password immediately
□ Review all systems where account has access
□ Check for persistence mechanisms
□ Correlate with data access logs
```

---

## Part 4: Incident Response Integration

### MDE + MDI + AD Correlation Framework

```
PROMPT: Create correlated investigation across MDE, MDI, and AD.

INCIDENT SUMMARY:
- Trigger: [What initiated investigation]
- Timeframe: [Investigation window]
- Scope: [Users/devices in scope]

CORRELATION MATRIX:

| Event Type | MDE Source | MDI Source | AD Source | Entra Source |
|------------|------------|------------|-----------|--------------|
| Cred Theft | DeviceAlertEvents | Credential theft alert | 4648, 4624 | - |
| Lateral Move | DeviceNetworkEvents | Lateral movement path | 4624 Type 3 | - |
| Privilege Esc | DeviceProcessEvents | Privilege escalation | 4672, 4673 | Role elevation |
| Recon | DeviceProcessEvents | LDAP/DNS recon | 4662 | - |
| Persistence | DeviceRegistryEvents | - | 4720, 4738 | - |

UNIFIED TIMELINE QUERY:
```kql
// Combine telemetry sources
let timeWindow = datetime("2024-01-15T10:00:00Z");
let endWindow = datetime("2024-01-15T18:00:00Z");
let targetAccount = "compromised.user";

// MDE Events
let mdeEvents = DeviceProcessEvents
| where Timestamp between (timeWindow .. endWindow)
| where AccountName == targetAccount
| project Timestamp, Source="MDE-Process", DeviceName,
          Details=strcat(FileName, " - ", ProcessCommandLine);

// MDE Network
let mdeNetwork = DeviceNetworkEvents
| where Timestamp between (timeWindow .. endWindow)
| where AccountName == targetAccount
| project Timestamp, Source="MDE-Network", DeviceName=DeviceName,
          Details=strcat(RemoteIP, ":", RemotePort);

// MDI Alerts
let mdiAlerts = IdentityDirectoryEvents
| where Timestamp between (timeWindow .. endWindow)
| where AccountName == targetAccount
| project Timestamp, Source="MDI", DeviceName=DestinationDeviceName,
          Details=ActionType;

// Combine
union mdeEvents, mdeNetwork, mdiAlerts
| sort by Timestamp asc
```

INVESTIGATION PHASES:

Phase 1: Initial Access
- How did attacker get initial foothold?
- MDE: Initial malware/exploit detection
- AD: First anomalous logon

Phase 2: Credential Access
- What credentials were stolen?
- MDE: LSASS access, credential tools
- MDI: Credential theft alerts

Phase 3: Lateral Movement
- How did attacker spread?
- MDE: Remote connections, process execution
- MDI: Lateral movement paths
- AD: Remote logon events

Phase 4: Privilege Escalation
- Did attacker gain higher privileges?
- MDE: Privilege escalation techniques
- MDI: Privilege escalation alerts
- AD: Sensitive group modifications

Phase 5: Objectives
- What did attacker access/exfiltrate?
- MDE: Data access, staging, exfil
- AD: Object access auditing

CONFIDENCE SCORING:
| Phase | Evidence Quality | Sources Correlated | Confidence |
|-------|-----------------|-------------------|------------|
| Initial Access | ? | MDE+?+? | ?% |
| Credential Access | ? | MDE+MDI+? | ?% |
| Lateral Movement | ? | MDE+AD+? | ?% |
| Privilege Escalation | ? | ?+?+? | ?% |
| Objectives | ? | ?+? | ?% |

Overall Incident Confidence: [Weighted average]
```

---

## Part 5: Automated Response Playbooks

### MDE Automated Investigation Supplement

```
PROMPT: Supplement MDE automated investigation with identity context.

AUTOMATED INVESTIGATION ID: [Investigation ID]
AUTOMATED FINDINGS: [Summary of MDE auto-investigation]

IDENTITY CONTEXT ENRICHMENT:

1. USER RISK ASSESSMENT:
   For each user in automated investigation:

   | User | Role | Privilege Level | Recent Password Change | MFA Status |
   |------|------|-----------------|------------------------|------------|
   | ? | ? | ? | ? | ? |

2. DEVICE TRUST ASSESSMENT:
   | Device | Compliance | Join Type | Last Seen | Primary User |
   |--------|------------|-----------|-----------|--------------|
   | ? | ? | ? | ? | ? |

3. ACCESS SCOPE CALCULATION:
   If this user/device is compromised, what can attacker reach?

   AD Access:
   - Group memberships: [List sensitive groups]
   - Delegated permissions: [Any AD delegations]
   - Admin on systems: [List]

   Azure/Entra Access:
   - Azure RBAC roles: [List]
   - Application permissions: [List]
   - Conditional Access gaps: [Any bypass conditions]

4. RECOMMENDED ACTIONS BEYOND AUTO-REMEDIATION:

   □ Password reset required (Y/N, reasoning)
   □ Session revocation needed (Y/N, reasoning)
   □ Account disable needed (Y/N, reasoning)
   □ Device isolation needed (Y/N, reasoning)
   □ Broader scope investigation (Y/N, reasoning)

5. FALSE POSITIVE ASSESSMENT:
   Could this be legitimate activity?

   Legitimacy Indicators:
   - User's normal job function: [Description]
   - Recent legitimate changes: [Any change tickets]
   - Tool authorization: [Is tool approved]
   - Time of activity: [Business hours?]

   False Positive Probability: [%]
   Reasoning: [Explanation]
```

---

## Quick Reference Card

```
MDE + IDENTITY INVESTIGATION QUICK COMMANDS

Credential Theft Hunt:
DeviceProcessEvents | where FileName =~ "lsass.exe" | project Timestamp, DeviceName, InitiatingProcessFileName, InitiatingProcessCommandLine

Lateral Movement Track:
DeviceNetworkEvents | where RemotePort in (445,5985,3389) | summarize by DeviceName, AccountName, RemoteIP

Service Account Abuse:
DeviceLogonEvents | where AccountName startswith "svc_" | where LogonType == "Interactive"

DC Security Check:
DeviceProcessEvents | where DeviceName in (DC_Names) | where FileName in~ ("mimikatz.exe","procdump.exe","psexec.exe")

Timeline Build:
union DeviceProcessEvents, DeviceNetworkEvents, DeviceLogonEvents | where AccountName == "TARGET" | sort by Timestamp

CORRELATION PRIORITIES:
1. MDE credential alert → Check MDI for same user → Check AD for spread
2. MDE lateral movement → Map path → Identify all hops
3. MDE on DC → Immediate escalation → Check for domain compromise
```

---

*Document Version: 1.0*
*Framework: MDE Identity Investigation*
*Integration: MDI, Active Directory, Entra ID*
