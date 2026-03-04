# Safe Troubleshooting Rules

## Read-Only Diagnostics & Non-Destructive Operations

> **Principle**: The first phase of any P0 investigation must use only read-only operations. Changing state before understanding state causes more P0s than it solves.

---

## The Read-Only First Rule

```
P0 INVESTIGATION PHASES:

PHASE 1: OBSERVE (Read-Only Only)
├── Gather symptoms
├── Collect logs
├── Query status
├── Document state
└── Duration: Until root cause hypothesis formed

PHASE 2: HYPOTHESIZE
├── Form competing theories
├── Identify validation tests
├── Assess confidence levels
└── Duration: Until high-confidence hypothesis

PHASE 3: VALIDATE (Minimal Intervention)
├── Targeted diagnostic actions
├── Single-variable tests
├── Confirm or eliminate hypotheses
└── Duration: Until root cause confirmed

PHASE 4: REMEDIATE (Approved Changes)
├── Get appropriate approvals
├── Execute fix with witness
├── Document all changes
└── Verify resolution
```

---

## Always Safe Operations

These operations are **always safe** and can be run without approval:

### Active Directory Queries

```powershell
# Domain and Forest Information
Get-ADDomain
Get-ADForest
Get-ADDomainController -Filter *
(Get-ADForest).ForestMode
(Get-ADDomain).DomainMode

# Replication Status
repadmin /replsummary
repadmin /showrepl
repadmin /showrepl * /csv
repadmin /queue
repadmin /showconn

# FSMO Roles
netdom query fsmo
Get-ADDomain | Select-Object PDCEmulator, RIDMaster, InfrastructureMaster
Get-ADForest | Select-Object SchemaMaster, DomainNamingMaster

# Health Checks (Read-Only)
dcdiag /v /c /e
dcdiag /test:dns /v
dcdiag /test:replications

# Account Queries
Get-ADUser -Identity username -Properties *
Get-ADUser -Filter * -Properties PasswordLastSet, LastLogonDate | Select-Object Name, PasswordLastSet, LastLogonDate
Get-ADComputer -Filter * -Properties LastLogonDate
Search-ADAccount -LockedOut
Search-ADAccount -PasswordExpired
Get-ADPrincipalGroupMembership username

# Group Policy Queries
Get-GPO -All
Get-GPOReport -All -ReportType HTML -Path report.html
gpresult /r
gpresult /h report.html
```

### DNS Queries

```powershell
# DNS Health
nslookup -type=srv _ldap._tcp.dc._msdcs.domain.com
nslookup -type=srv _kerberos._tcp.domain.com
Get-DnsServerZone
Get-DnsServerResourceRecord -ZoneName "domain.com"
Resolve-DnsName hostname
```

### Network Diagnostics

```powershell
# Connectivity Tests
Test-NetConnection -ComputerName DC1 -Port 389
Test-NetConnection -ComputerName DC1 -Port 636
Test-NetConnection -ComputerName DC1 -Port 88
Test-NetConnection -ComputerName DC1 -Port 53
nltest /dsgetdc:domain.com
nltest /sc_query:domain.com

# Note: Test-NetConnection is read-only, unlike Test-Connection which may trigger alerts
```

### Event Log Queries

```powershell
# Security Events
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4740} -MaxEvents 100  # Lockouts
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625} -MaxEvents 100  # Failed logons
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4771} -MaxEvents 100  # Kerberos pre-auth failure

# Directory Service Events
Get-WinEvent -FilterHashtable @{LogName='Directory Service'} -MaxEvents 100

# System Events
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='NETLOGON'} -MaxEvents 100

# DFS Replication
Get-WinEvent -FilterHashtable @{LogName='DFS Replication'} -MaxEvents 100
```

### Certificate Queries

```powershell
# Certificate Status
certutil -viewstore My
certutil -verify certificate.cer
certutil -URL "http://crl-path"
Get-ChildItem Cert:\LocalMachine\My
```

### Hybrid Identity Queries

```powershell
# Azure AD Connect Status
Get-ADSyncScheduler
Get-ADSyncConnector
Get-ADSyncConnectorStatistics -ConnectorName "domain.com"

# Device Registration (Client-side)
dsregcmd /status
```

---

## Conditionally Safe Operations

These operations are **generally safe** but have minor state-change effects:

### Kerberos Ticket Operations

```powershell
# View tickets - SAFE
klist

# Purge tickets - CONDITIONALLY SAFE
# Effect: Forces re-authentication, may cause brief delay
# When safe: Troubleshooting auth issues, user present
# When caution needed: Automated service accounts, user not present
klist purge
```

### DNS Cache Operations

```powershell
# View cache - SAFE
Get-DnsClientCache
ipconfig /displaydns

# Clear cache - CONDITIONALLY SAFE
# Effect: Forces DNS re-resolution
# When safe: Troubleshooting stale DNS
# When caution needed: High-volume client, production server
Clear-DnsClientCache
ipconfig /flushdns
```

### Service Status (View Only)

```powershell
# Always safe to VIEW
Get-Service NTDS, Netlogon, KDC, DNS, DFSR

# CONDITIONALLY SAFE to restart minor services
# See Change Risk Matrix for classifications
```

---

## Operations That Appear Safe But Aren't

### Dangerous "Query" Operations

Some operations look like queries but can cause issues:

```powershell
# DANGEROUS: These can cause load or change state

# Test-ADServiceAccount -Identity gMSAname
# Can cause password rotation on gMSA if not retrieved recently

# Repair-ADServiceAccount -Identity gMSAname
# DEFINITELY changes state

# Get-ADReplicationFailure (without -Target)
# Safe, but running repeatedly in loop can cause load

# repadmin /syncall
# NOT a query - forces replication
```

### Queries That Can Trigger Security Alerts

```powershell
# May trigger security tooling alerts:

# Enumeration patterns (running many times)
Get-ADUser -Filter *
Get-ADGroupMember "Domain Admins" -Recursive
Get-ADComputer -Filter *

# Inform security team before running extensive enumeration
# during P0 to avoid creating additional alerts
```

---

## Performance-Safe Query Guidelines

### Avoid Performance Impact

```
QUERY BEST PRACTICES:

1. Always use -Filter server-side, not Where-Object
   GOOD:  Get-ADUser -Filter {Enabled -eq $false}
   BAD:   Get-ADUser -Filter * | Where-Object {$_.Enabled -eq $false}

2. Limit properties retrieved
   GOOD:  Get-ADUser user -Properties LastLogonDate, PasswordLastSet
   BAD:   Get-ADUser user -Properties *   (for bulk queries)

3. Use pagination for large result sets
   GOOD:  Get-ADUser -Filter * -ResultSetSize 1000
   BAD:   Get-ADUser -Filter *  (in 100k+ user environment)

4. Target specific DCs when testing
   GOOD:  Get-ADUser user -Server DC1.domain.com
   BAD:   Get-ADUser user  (during DC locator issues)

5. Avoid expensive LDAP filters
   EXPENSIVE:  (anr=john)  # Ambiguous name resolution
   BETTER:     (sAMAccountName=john*)  # More specific
```

---

## Evidence Collection Protocol

### Collecting Without Modifying

```
SAFE EVIDENCE COLLECTION:

1. Event Logs
   - Export to EVTX: wevtutil epl Security C:\evidence\security.evtx
   - Query to CSV: Get-WinEvent ... | Export-Csv
   - DO NOT clear logs during investigation

2. Configuration State
   - Export before any changes
   - Use read-only export commands
   - Timestamp all exports

3. Screenshots
   - UI state for error messages
   - Console output
   - Application errors

4. Network Captures
   - Wireshark/netsh trace (if approved)
   - Note: May require security approval
   - Contains sensitive data - handle appropriately
```

### What NOT to Do During Evidence Collection

```
EVIDENCE COLLECTION DON'TS:

[ ] Don't reboot systems before collecting volatile data
[ ] Don't clear event logs
[ ] Don't run cleanup scripts
[ ] Don't install new software (even diagnostic tools)
[ ] Don't modify registry unless collecting read-only export
[ ] Don't run third-party tools without approval
[ ] Don't perform memory dumps without security approval
```

---

## Safe Diagnostic Sequences

### Authentication Failure Diagnostic (Safe)

```powershell
# All operations in this sequence are read-only

# 1. Check account status
Get-ADUser $user -Properties *
Search-ADAccount -LockedOut | Where-Object {$_.SamAccountName -eq $user}

# 2. Check DC being used
nltest /dsgetdc:domain.com

# 3. Check Kerberos
klist  # on client

# 4. Check events on DC
Get-WinEvent -ComputerName $dc -FilterHashtable @{LogName='Security'; ID=4771,4625,4768,4769} |
    Where-Object {$_.Message -match $user}

# 5. Check time sync
w32tm /query /status  # on client
w32tm /query /status  # on DC
```

### Replication Failure Diagnostic (Safe)

```powershell
# All operations in this sequence are read-only

# 1. Summary view
repadmin /replsummary

# 2. Detailed status
repadmin /showrepl DC1
repadmin /showrepl DC2

# 3. Queue depth
repadmin /queue DC1

# 4. Test specific replication path
repadmin /showrepl DC1 /verbose | Select-String "Last attempt"

# 5. Check network path
Test-NetConnection DC2 -Port 135
Test-NetConnection DC2 -Port 389

# 6. Check relevant events
Get-WinEvent -ComputerName DC1 -FilterHashtable @{LogName='Directory Service'; Level=2,3} -MaxEvents 50
```

---

## When Safe Operations Become Unsafe

### Context Matters

```
SAME OPERATION, DIFFERENT RISK:

Get-ADUser -Filter *
├── In 1,000 user environment: SAFE
├── In 500,000 user environment: PERFORMANCE RISK
└── Running in loop every 5 seconds: DANGEROUS

Restart-Service DNS
├── On DC with 3 other DCs in site: LOW RISK
├── On only DC in remote site: HIGH RISK
└── During middle of P0: NEEDS APPROVAL

klist purge
├── On user workstation with user present: SAFE
├── On service account session: DANGEROUS
└── On domain controller: VERY DANGEROUS
```

---

## The Five-Minute Rule

> Before running ANY operation during a P0, ask yourself:

```
THE FIVE QUESTIONS:

1. Does this change state or only read state?
   If it changes state -> needs approval

2. What's the worst that can happen if this goes wrong?
   If answer is bad -> needs approval

3. Can I undo this immediately if needed?
   If no -> needs approval

4. Am I 100% sure of the target and syntax?
   If no -> double check first

5. Would I be comfortable explaining this to the CIO?
   If no -> reconsider
```

---

## Related Documents

- [Change Risk Matrix](change_risk_matrix.md) - Classification of all operations
- [Truth and Confidence](truth_and_confidence.md) - When to stop and verify
- [Evidence Checklists](../07_PROOF_AND_EXONERATION/evidence_checklists.md) - What to collect
