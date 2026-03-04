# Splunk Query Builder — Active Directory & Windows

**Use Case:** Build Splunk SPL queries for AD security monitoring, event investigation, threat hunting, and compliance reporting.
**Techniques:** SPL, Windows event log parsing, AD-specific field extraction, dashboards

---

## The Query Builder Prompt

```
You are a Splunk expert specializing in Active Directory and Windows security event log analysis. You write efficient, production-ready SPL queries.

WHAT I NEED TO FIND/MONITOR:
[Describe in plain English what you want to detect, investigate, or report on]

DATA SOURCE:
- Index: [e.g., wineventlog, windows, security]
- Sourcetype: [e.g., WinEventLog:Security, XmlWinEventLog:Security]
- Time range: [e.g., last 24h, last 7 days, specific date range]
- Data volume: [rough estimate — helps with query efficiency]

EVENT IDS RELEVANT:
[List if you know them, otherwise describe the activity]

OUTPUT FORMAT:
[ ] Investigation (ad-hoc search, see raw results)
[ ] Table (key fields, deduplicated)
[ ] Statistics (counts, top values)
[ ] Dashboard panel (with time chart)
[ ] Alert (threshold-based)

FIELDS AVAILABLE:
[List any custom field extractions you've done, or leave blank]

Generate:
1. The SPL query
2. Explanation of each pipeline stage
3. How to tune for performance on large data volumes
4. Suggested visualizations if creating a dashboard
5. Alert threshold recommendations if monitoring
```

---

## Ready-to-Use AD Splunk Queries

### Authentication Monitoring

```splunk
# Failed logon attempts (brute force detection)
index=wineventlog EventCode=4625
| stats count as FailedAttempts, values(IpAddress) as SourceIPs by TargetUserName, host
| where FailedAttempts > 10
| sort -FailedAttempts

# Account lockouts with source identification
index=wineventlog EventCode=4740
| eval LockedAccount=mvindex(split(Message, "Account Name:"), 1)
| table _time, host, TargetUserName, SubjectUserName, IpAddress
| sort -_time

# Successful logons after failed attempts (possible compromise)
index=wineventlog (EventCode=4625 OR EventCode=4624)
| eventstats count(eval(EventCode=4625)) as Failures,
             count(eval(EventCode=4624)) as Successes by TargetUserName
| where Failures > 5 AND Successes > 0
| table _time, TargetUserName, Failures, Successes, IpAddress

# Pass-the-Hash detection (NTLM logon type 3 from workstations)
index=wineventlog EventCode=4624 Logon_Type=3 AuthenticationPackageName=NTLM
| where NOT match(IpAddress, "^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)")
| table _time, TargetUserName, IpAddress, WorkstationName
| sort -_time

# Kerberoasting detection (many TGS requests)
index=wineventlog EventCode=4769
| where TicketEncryptionType="0x17" OR TicketEncryptionType="0x18"
| stats count by _time span=1h, ClientAddress, ServiceName
| where count > 20
| sort -count

# Pass-the-Ticket / Golden Ticket (anomalous Kerberos TGT)
index=wineventlog EventCode=4768
| eval hour=strftime(_time, "%H")
| stats count by TargetUserName, IpAddress, hour
| where (hour < 6 OR hour > 22) AND count > 3
```

### Privileged Account Monitoring

```splunk
# Admin group membership changes
index=wineventlog (EventCode=4728 OR EventCode=4732 OR EventCode=4756)
| eval GroupName=mvindex(split(Message,"Group Name:"),1)
| eval MemberAdded=mvindex(split(Message,"Member Name:"),1)
| table _time, EventCode, SubjectUserName, GroupName, MemberAdded, host
| sort -_time

# Domain Admin logons to non-DC machines
index=wineventlog EventCode=4624
| lookup ad_groups user as TargetUserName OUTPUT groups
| where match(groups, "Domain Admins")
| lookup dc_list host as WorkstationName OUTPUT is_dc
| where is_dc != "true"
| table _time, TargetUserName, WorkstationName, IpAddress

# New local admin account creation
index=wineventlog EventCode=4720
| join SubjectUserName [search index=wineventlog EventCode=4732 GroupName="Administrators"]
| table _time, SubjectUserName, TargetUserName, host

# Service account interactive logons (should never happen)
index=wineventlog EventCode=4624 (Logon_Type=2 OR Logon_Type=10)
| where match(TargetUserName, "svc_|sa_|service")
| table _time, TargetUserName, IpAddress, WorkstationName, Logon_Type
| sort -_time
```

### AD Object Changes

```splunk
# User account modifications
index=wineventlog EventCode=5136
| eval AttributeChanged=mvindex(split(Message, "Attribute:"), 1)
| eval NewValue=mvindex(split(Message, "Value:"), 2)
| table _time, SubjectUserName, ObjectDN, AttributeChanged, NewValue
| sort -_time

# GPO modifications
index=wineventlog EventCode=5136
| where match(ObjectDN, ".*CN=Policies.*")
| table _time, SubjectUserName, ObjectDN, Message
| sort -_time

# OU/Object deletions
index=wineventlog EventCode=5141
| table _time, SubjectUserName, ObjectDN, ObjectClass, host
| sort -_time

# User account creation/deletion/enable/disable
index=wineventlog (EventCode=4720 OR EventCode=4722 OR EventCode=4725 OR EventCode=4726)
| eval Action=case(
    EventCode=4720, "Created",
    EventCode=4722, "Enabled",
    EventCode=4725, "Disabled",
    EventCode=4726, "Deleted")
| table _time, Action, SubjectUserName, TargetUserName, host
| sort -_time
```

### Threat Hunting Queries

```splunk
# DCSync detection (replication rights used from non-DC)
index=wineventlog EventCode=4662
| where match(Properties, "1131f6aa-9c07-11d1-f79f-00c04fc2dcd2") OR
        match(Properties, "1131f6ab-9c07-11d1-f79f-00c04fc2dcd2") OR
        match(Properties, "89e95b76-444d-4c62-991a-0facbeda640c")
| lookup dc_list host OUTPUT is_dc
| where is_dc != "true"
| table _time, SubjectUserName, host, Properties

# Lateral movement via RDP
index=wineventlog EventCode=4624 Logon_Type=10
| stats count by TargetUserName, IpAddress, host
| where count > 5
| sort -count

# Suspicious process execution (from audit logs)
index=wineventlog EventCode=4688
| where match(NewProcessName, ".*\\(mimikatz|lsass|procdump|psexec|wce|fgdump).*")
| table _time, SubjectUserName, NewProcessName, ParentProcessName, host

# Admin share access (C$, ADMIN$)
index=wineventlog EventCode=5140
| where match(ShareName, ".*\\(C\$|ADMIN\$|IPC\$).*")
| stats count by _time span=1h, SubjectUserName, IpAddress, ShareName
| where count > 20
```

### Compliance & Reporting

```splunk
# Weekly admin activity report
index=wineventlog (EventCode=4720 OR EventCode=4722 OR EventCode=4725 OR EventCode=4726 OR EventCode=4728 OR EventCode=4732)
earliest=-7d@d latest=@d
| eval EventDescription=case(
    EventCode=4720, "User Created",
    EventCode=4722, "Account Enabled",
    EventCode=4725, "Account Disabled",
    EventCode=4726, "User Deleted",
    EventCode=4728, "Added to Global Group",
    EventCode=4732, "Added to Local Group")
| table _time, EventDescription, SubjectUserName, TargetUserName, host
| sort _time

# Password changes and resets (compliance tracking)
index=wineventlog (EventCode=4723 OR EventCode=4724)
| eval EventDescription=if(EventCode=4723, "User Changed Password", "Admin Reset Password")
| table _time, EventDescription, SubjectUserName, TargetUserName, host
| sort -_time
```

---

## Dashboard Template Prompt

```
Create a Splunk dashboard XML for an Active Directory Security Overview dashboard.

Panels needed:
1. Account lockouts (last 24h) — single value panel
2. Failed logon trend — time chart (last 7 days)
3. Top locked out accounts — table
4. Admin group changes (last 30 days) — table
5. Logon by type breakdown — pie chart
6. Accounts created/deleted (last 7 days) — bar chart

Use these indexes and sourcetypes: [specify yours]

Generate the full Splunk Simple XML for this dashboard.
```

---

**Tips:**
- Use `XmlWinEventLog:Security` sourcetype for better field extraction than `WinEventLog:Security`
- Add `earliest=-15m` to alert searches to reduce false positives from delayed log ingestion
- For high-volume environments, add `index=wineventlog host=<PDC>` to focus on critical DCs first
- `| tstats` instead of `| search` is 10-100x faster for large timeframes — learn it
- Build lookup tables: dc_list, privileged_accounts, known_good_ips — they make queries much more powerful
