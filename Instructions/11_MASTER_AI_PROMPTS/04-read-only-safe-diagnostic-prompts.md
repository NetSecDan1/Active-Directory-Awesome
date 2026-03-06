# 04 — Read-Only Safe Diagnostic Prompts

> **PRODUCTION SAFE**: Every command in this file is read-only. Zero state changes. Zero risk of causing additional impact during an incident. These are the prompts and commands you run FIRST — always — before touching anything.

---

## The Golden Rule of AD Diagnostics

> "Gather all data in read-only mode before forming any hypothesis. The fastest path to resolution is complete data, not fast action."
> — Microsoft CSS Principal, Identity Team

---

## PROMPT: Generate My Read-Only Diagnostic Runbook

```
I need a complete read-only diagnostic data collection plan for an Active Directory issue. Generate ONLY commands that:
- Make no changes to AD, DNS, GPOs, or system configuration
- Can be run safely during production hours
- Can be run by an L1 engineer following instructions
- Produce output that an L3/L4 engineer can analyze

Organize by category. Include exact PowerShell and command-line syntax. Note the expected output format and what "healthy" vs "unhealthy" looks like.

ISSUE DESCRIPTION:
[Describe the problem here]

ENVIRONMENT:
- Domain functional level: [e.g., 2016]
- Number of DCs: [e.g., 12 across 4 sites]
- Hybrid: [Yes/No — if yes, AAD Connect version]
- Tools available: [e.g., PowerShell 5.1, AD module, no MDI]
```

---

## MASTER READ-ONLY COMMAND REFERENCE

### DC Health (Run on any DC or remotely)

```powershell
# =============================================
# DC HEALTH — READ-ONLY COLLECTION
# =============================================

# Overall DC health test (read-only — dcdiag never changes anything)
dcdiag /test:replications /test:ncsecdesc /test:netlogons /test:advertising /test:fsmocheck /v

# Replication summary (all DCs in domain)
repadmin /replsummary

# Detailed replication status with errors
repadmin /showrepl * /errorsonly

# Show all replication failures
repadmin /showrepl * /csv | ConvertFrom-Csv | Where-Object {$_.NumberOfFailures -gt 0}

# Show replication queue depth (is it backed up?)
repadmin /showreps

# USN vector — check for USN rollback indicators
repadmin /showvector /latency dc01.domain.com

# FSMO role holders
netdom query fsmo

# DC locator — which DC authenticated last logon
nltest /dsgetdc:domain.com /force

# List all DCs in domain
Get-ADDomainController -Filter * | Select-Object Name, Site, IPv4Address, IsGlobalCatalog, OperatingSystem, Enabled

# DC connectivity check (read-only ping of services)
Test-ComputerSecureChannel -Verbose  # Read-only when no -Repair switch

# Time sync status on current DC
w32tm /query /status
w32tm /query /peers

# Services status on local DC
Get-Service NTDS, NETLOGON, DFSR, DNS, KDC, W32Time | Select Name, Status, StartType
```

### Active Directory Object Queries (Read-Only)

```powershell
# =============================================
# AD OBJECT QUERIES — READ-ONLY
# =============================================

# User account status
Get-ADUser -Identity "username" -Properties * |
    Select-Object SamAccountName, Enabled, LockedOut, BadPwdCount, BadPasswordTime,
                  LastLogonDate, PasswordExpired, PasswordLastSet,
                  PasswordNeverExpires, SmartcardLogonRequired,
                  DistinguishedName, MemberOf | Format-List

# All locked out users (domain-wide)
Search-ADAccount -LockedOut | Select-Object Name, SamAccountName, DistinguishedName, LastLogonDate

# All disabled users
Search-ADAccount -AccountDisabled -UsersOnly | Select-Object Name, SamAccountName, DistinguishedName

# All accounts with password expired
Search-ADAccount -PasswordExpired | Select-Object Name, SamAccountName, PasswordExpired, PasswordLastSet

# Users not logged in for 90 days
$cutoff = (Get-Date).AddDays(-90)
Get-ADUser -Filter {LastLogonDate -lt $cutoff -and Enabled -eq $true} -Properties LastLogonDate |
    Select-Object Name, SamAccountName, LastLogonDate | Sort-Object LastLogonDate

# SPN check — find duplicate SPNs (common Kerberos failure cause)
setspn -X -F  # Forest-wide duplicate SPN check (read-only, can take a few minutes)

# SPN list for specific account
setspn -L hostname
setspn -L serviceaccount

# Computer account health
Get-ADComputer -Identity "computername" -Properties * |
    Select-Object Name, Enabled, LastLogonDate, OperatingSystem,
                  PasswordLastSet, DNSHostName, ServicePrincipalNames | Format-List

# Stale computer accounts (no logon in 60 days)
$cutoff = (Get-Date).AddDays(-60)
Get-ADComputer -Filter {LastLogonDate -lt $cutoff -and Enabled -eq $true} -Properties LastLogonDate |
    Select-Object Name, LastLogonDate | Sort-Object LastLogonDate

# Group membership — recursive
Get-ADGroupMember -Identity "GroupName" -Recursive | Select-Object Name, SamAccountName, ObjectClass

# User's group memberships (including nested)
(Get-ADUser "username" -Properties MemberOf).MemberOf |
    Get-ADGroup | Select-Object Name, GroupScope, GroupCategory
```

### DNS Health (Read-Only)

```powershell
# =============================================
# DNS — READ-ONLY DIAGNOSTICS
# =============================================

# Test SRV record resolution (critical for DC locator)
Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.domain.com" -Type SRV
Resolve-DnsName -Name "_kerberos._tcp.dc._msdcs.domain.com" -Type SRV
Resolve-DnsName -Name "_ldap._tcp.pdc._msdcs.domain.com" -Type SRV

# Test domain name resolution
Resolve-DnsName -Name "domain.com" -Type A
Resolve-DnsName -Name "domain.com" -Type SOA

# DC registration check — all DCs should be registered
Get-ADDomainController -Filter * | ForEach-Object {
    $dc = $_
    try {
        $result = Resolve-DnsName -Name $dc.HostName -Type A -ErrorAction Stop
        [PSCustomObject]@{DC=$dc.Name; Hostname=$dc.HostName; IP=$result.IPAddress; DNSStatus="OK"}
    } catch {
        [PSCustomObject]@{DC=$dc.Name; Hostname=$dc.HostName; IP="UNRESOLVABLE"; DNSStatus="FAIL"}
    }
}

# DNS server event log — last 100 DNS errors
Get-WinEvent -LogName "DNS Server" -MaxEvents 100 |
    Where-Object { $_.LevelDisplayName -eq "Error" } |
    Select-Object TimeCreated, Id, Message | Format-List

# Check zone health on local DNS server (read-only)
Get-DnsServerZone | Select-Object ZoneName, ZoneType, IsReverseLookupZone, IsDsIntegrated, DynamicUpdate | Format-Table

# Show scavenging settings
Get-DnsServerZone | Select-Object ZoneName, ScavengingServers, AgingEnabled, NoRefreshInterval, RefreshInterval
```

### Group Policy (Read-Only)

```powershell
# =============================================
# GROUP POLICY — READ-ONLY
# =============================================

# Generate HTML GPResult report for current user/computer
gpresult /h C:\Temp\GPResult_$(hostname)_$(Get-Date -Format 'yyyyMMdd-HHmmss').html /f

# Quick console output (no file)
gpresult /r

# GPResult for specific user on specific computer (run from that computer)
gpresult /user DOMAIN\username /h C:\Temp\gp_user.html /f

# List all GPOs in domain (read-only)
Get-GPO -All | Select-Object DisplayName, Id, GpoStatus, CreationTime, ModificationTime |
    Sort-Object ModificationTime -Descending | Format-Table -AutoSize

# Recently modified GPOs (last 7 days) — useful for correlation
$since = (Get-Date).AddDays(-7)
Get-GPO -All | Where-Object {$_.ModificationTime -gt $since} |
    Select-Object DisplayName, ModificationTime, Id | Sort-Object ModificationTime -Descending

# GPO link status — which GPOs are linked where
Get-GPInheritance -Target "OU=Corp,DC=domain,DC=com" |
    Select-Object -ExpandProperty GpoLinks |
    Select-Object DisplayName, Enabled, Enforced, Order

# Get GPO settings (read-only report generation)
Get-GPOReport -Name "GPO Name" -ReportType Html -Path "C:\Temp\GPO_Report.html"
# Or all GPOs:
Get-GPOReport -All -ReportType Html -Path "C:\Temp\All_GPOs.html"
```

### Security Event Log (Read-Only Forensics)

```powershell
# =============================================
# SECURITY EVENT LOG — READ-ONLY FORENSICS
# =============================================

# Lockout events on PDC Emulator (run there, or use -ComputerName)
Get-WinEvent -ComputerName $PDCEmulator -FilterHashtable @{
    LogName = 'Security'
    Id = 4740
    StartTime = (Get-Date).AddHours(-4)
} | Select-Object TimeCreated,
    @{N='Username';E={$_.Properties[0].Value}},
    @{N='CallerComputer';E={$_.Properties[1].Value}} |
    Sort-Object TimeCreated -Descending | Format-Table -AutoSize

# Failed logon events (event 4625) with failure reason
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 4625
    StartTime = (Get-Date).AddHours(-1)
} | ForEach-Object {
    [PSCustomObject]@{
        Time = $_.TimeCreated
        Username = $_.Properties[5].Value
        Domain = $_.Properties[6].Value
        Workstation = $_.Properties[13].Value
        FailureReason = $_.Properties[8].Value
        LogonType = $_.Properties[10].Value
    }
} | Format-Table -AutoSize

# Successful admin logons (4672 — special privileges assigned)
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 4672
    StartTime = (Get-Date).AddHours(-24)
} | Select-Object TimeCreated,
    @{N='Account';E={$_.Properties[1].Value}},
    @{N='Privileges';E={$_.Properties[4].Value}} |
    Sort-Object TimeCreated -Descending | Select-Object -First 50 | Format-Table

# AD object modifications (5136) — what changed in AD recently
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 5136
    StartTime = (Get-Date).AddHours(-24)
} | ForEach-Object {
    [PSCustomObject]@{
        Time = $_.TimeCreated
        Actor = $_.Properties[3].Value
        Object = $_.Properties[8].Value
        Attribute = $_.Properties[9].Value
        Value = $_.Properties[11].Value
    }
} | Format-Table -AutoSize

# Kerberos failures (4771)
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    Id = 4771
    StartTime = (Get-Date).AddHours(-2)
} | ForEach-Object {
    [PSCustomObject]@{
        Time = $_.TimeCreated
        Username = $_.Properties[0].Value
        ClientIP = $_.Properties[6].Value
        FailureCode = $_.Properties[4].Value
    }
} | Group-Object Username | Sort-Object Count -Descending | Select-Object -First 20
```

### Replication Deep Dive (Read-Only)

```powershell
# =============================================
# REPLICATION — READ-ONLY ANALYSIS
# =============================================

# Complete replication status — all DCs, all partitions
repadmin /showrepl * /csv | ConvertFrom-Csv

# Replication lag — how stale is each DC?
repadmin /showvector /latency

# Which objects have failed to replicate?
repadmin /showattr * /gc /allvalues /filter:"(objectClass=user)" /atts:name,lastLogon

# Check for lingering objects (dry run — read-only check)
repadmin /removelingeringobjects DC01 DC02 DomainNC /advisory_mode
# Note: /advisory_mode makes this READ-ONLY — it reports what WOULD be removed

# Site topology check
repadmin /showobjmeta * "cn=NTDS Settings,cn=DC01,cn=Servers,cn=Site1,cn=Sites,cn=Configuration,dc=domain,dc=com"

# Check if replication is happening (metadata of a known object)
repadmin /showobjmeta * "cn=administrator,cn=users,dc=domain,dc=com"

# Show inbound/outbound replication connections
repadmin /showconn

# Check if specific naming context is up to date
repadmin /showutdvec dc01 dc=domain,dc=com
```

---

## PROMPT: Incident Data Collection Checklist

```
I'm responding to an Active Directory incident. Generate a prioritized data collection checklist of ONLY read-only commands.

The checklist should be organized by:
1. IMMEDIATE (first 5 minutes) — data that could be overwritten by continued operations
2. URGENT (next 15 minutes) — data needed to form initial hypothesis
3. STANDARD (next 30 minutes) — thorough baseline data
4. BACKGROUND (collect while working) — ongoing telemetry

For each command:
- Label it: [POWERSHELL], [CMD], [BROWSER], or [SIEM]
- Rate its value: [CRITICAL] / [HIGH] / [MEDIUM]
- Note which system to run it on

INCIDENT TYPE: [e.g., Mass authentication failures / Replication outage / Account lockout storm / DC unreachable]
SCOPE: [Number of users/systems affected]
DURATION: [How long has this been occurring]
```

---

## PROMPT: Safe Pre-Change Baseline Capture

```
Before making any change to Active Directory, I need to capture a complete baseline so we can verify the change worked and roll back if needed. Generate a read-only baseline capture script for the following change.

The baseline should capture:
1. Current state of every object that will be affected
2. Current replication status (before we start)
3. Current event log state (watermark — last event before change)
4. Service status on all relevant DCs
5. Verification commands to run AFTER the change to confirm success

OUTPUT FORMAT: PowerShell script with clear comments, output to timestamped files in C:\Temp\ADBaseline\

PLANNED CHANGE:
[Describe the change you're about to make]
```
