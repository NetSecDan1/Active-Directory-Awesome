# Runbook: AD Replication Failure Recovery
**Risk**: HIGH (some steps) | **Estimated Time**: 1-4 hours
**Requires**: Domain Admin | **Change Type**: Emergency or Normal (based on severity)
**Version**: 2.0 | **Owner**: AD Engineering

---

## Decision Tree — Which Procedure to Follow

```
START: Replication failure detected
    │
    ├─ Is it ONE failing link? ──────────────────► Section A: Single Link Recovery
    │
    ├─ Is it ALL links to ONE DC? ───────────────► Section B: DC-Specific Failure
    │
    ├─ Is it site-wide (inter-site only)? ───────► Section C: Inter-Site Link Failure
    │
    ├─ Error code 8606 (lingering objects)? ─────► Section D: Lingering Object Cleanup
    │
    ├─ Error code 8614 (USN rollback suspected)? ► Section E: USN Rollback ⚠️ CRITICAL
    │
    └─ All replication broken (error 8453)? ─────► Section F: Access/Auth Failure
```

---

## Phase 0 — Assessment (READ-ONLY, Always Run First)

```powershell
# Full replication status — run first, understand scope
repadmin /replsummary

# Detailed errors — which DCs, which naming contexts, which error codes
repadmin /showrepl * /errorsonly

# Replication queue — is it backing up?
repadmin /queue

# Check for obvious DC issues
dcdiag /test:replications /v

# Note: Record all error codes before proceeding
# Common codes: 1722 (RPC), 8453 (access denied), 8524 (DNS), 8606 (lingering), 8614 (USN rollback)
```

---

## Section A — Single Replication Link Recovery (RPC/Network Errors)

**For errors**: 1722 (RPC server unavailable), 1753 (endpoint mapper), 1727 (remote call failed)

```powershell
$SourceDC = "DC01"
$DestDC = "DC02"

# Step A1: Verify basic connectivity (READ-ONLY)
Test-NetConnection $SourceDC -Port 135  # RPC endpoint mapper
Test-NetConnection $SourceDC -Port 389  # LDAP
Test-NetConnection $SourceDC -Port 88   # Kerberos
Test-NetConnection $SourceDC -Port 445  # SMB

# Step A2: Verify DNS resolution (READ-ONLY)
Resolve-DnsName $SourceDC -Type A
Resolve-DnsName $SourceDC -Type CNAME

# Step A3: Test RPC connectivity specifically (READ-ONLY)
# From DestDC, run:
# portqry -n SourceDC -e 135  (if portqry available)
# Or: Test-NetConnection SourceDC -Port 135

# Step A4: Check NETLOGON service on source (READ-ONLY)
Get-Service -ComputerName $SourceDC -Name NETLOGON | Select-Object Status

# Step A5: Force replication (WRITE — requires change window)
repadmin /replicate $DestDC $SourceDC "dc=domain,dc=com"

# Step A6: Sync all naming contexts (WRITE — requires change window)
repadmin /syncall /AdeP
```

---

## Section B — DC-Specific Failure (One DC Can't Replicate)

```powershell
$ProblemDC = "DC03"

# Step B1: Full DCDiag on problem DC (READ-ONLY)
dcdiag /s:$ProblemDC /v 2>&1 | Where-Object { $_ -match "fail|error|warning" }

# Step B2: Check if DC can find other DCs (READ-ONLY)
nltest /dsgetdc:(Get-ADDomain).DNSRoot /force /server:$ProblemDC

# Step B3: Check DNS registration on problem DC (READ-ONLY)
nltest /dnsgetdc:(Get-ADDomain).DNSRoot /server:$ProblemDC

# Step B4: Re-register DNS (WRITE — generally safe, restores DNS records)
# Run on the problem DC:
ipconfig /registerdns
nltest /dsregdns

# Step B5: Reset secure channel (WRITE — requires change window)
# Run from the problem DC:
netdom resetpwd /server:(Get-ADDomain).PDCEmulator /userd:DOMAIN\DomainAdmin /passwordd:*
```

---

## Section C — Inter-Site Replication Failure

```powershell
# Step C1: Identify site link and cost (READ-ONLY)
Get-ADReplicationSiteLink -Filter * | Select-Object Name, Cost, ReplicationFrequencyInMinutes, SitesIncluded

# Step C2: Check ISTG (READ-ONLY)
repadmin /showism

# Step C3: Check bridgehead servers (READ-ONLY)
repadmin /bridgeheads

# Step C4: Force KCC to recalculate topology (WRITE — very low risk)
repadmin /kcc $ProblemDC

# Step C5: Force inter-site sync (WRITE — requires change window)
repadmin /syncall /Ade
```

---

## Section D — Lingering Object Cleanup (Error 8606)

> Lingering objects are objects that exist on one DC but have been deleted (tombstoned and garbage-collected) on others. They block replication.

```powershell
$ReferenceDC = "DC01"  # Known good, authoritative DC
$ProblemDC = "DC02"    # DC with lingering objects
$NC = "dc=domain,dc=com"  # Naming context

# Step D1: Identify lingering objects WITHOUT removing them (READ-ONLY — advisory mode)
repadmin /removelingeringobjects $ProblemDC $ReferenceDC $NC /advisory_mode
# Review output — lists objects that WOULD be removed

# Step D2: If advisory output looks correct, remove lingering objects (WRITE — APPROVAL REQUIRED)
# Only proceed after reviewing advisory output and getting approval
# Run on the DC that REFERENCES (has the correct state):
repadmin /removelingeringobjects $ProblemDC $ReferenceDC $NC

# Step D3: If widespread, enable strict replication consistency to prevent future issues (WRITE)
repadmin /regkey $ProblemDC +strict

# Step D4: Verify replication after cleanup (READ-ONLY)
repadmin /showrepl $ProblemDC /errorsonly
```

---

## Section E — USN Rollback Recovery ⚠️ CRITICAL

> USN rollback occurs when a DC is restored from a snapshot/backup without using VSS-aware restore methods. The DC has old USNs but claims they're current. **This is one of the most serious AD issues.**

**Indicators**: Error 8614, repadmin shows DC behind by thousands of USNs, objects exist on this DC that were deleted on others.

> ⚠️ **STOP**: This section requires senior engineer or AD architect review. Do NOT proceed autonomously.

```powershell
# Step E1: Confirm USN rollback (READ-ONLY)
repadmin /showvector /latency

# Step E2: Check event log for 2103 (USN rollback detected)
Get-WinEvent -FilterHashtable @{LogName='Directory Service'; Id=2103} -ErrorAction SilentlyContinue

# Step E3: Options (discuss with team before choosing):
#   Option 1: If DC is expendable → Demote and re-promote (cleanest)
#   Option 2: If DC is critical → Force non-authoritative restore from good backup
#   Option 3: If caught early → Registry fix (risky, only for specific scenarios)

# Option 1: Demotion (CRITICAL — requires change window and approval)
# - First, transfer any FSMO roles off this DC
# - Then: Uninstall-ADDSDomainController -NoReplicationSyncAtDemote -Force
```

---

## Section F — Replication Access Denied (Error 8453)

```powershell
# Error 8453 = "Replication access was denied"
# Usually caused by: incorrect permissions on NC head, broken secure channel, or account issue

# Step F1: Check permissions on domain NC (READ-ONLY)
# Use ADSIEdit to check "Replicating Directory Changes" on domain head
# Or:
(Get-Acl "AD:DC=domain,DC=com").Access |
    Where-Object { $_.ActiveDirectoryRights -like "*ReplicationGet*" } |
    Format-Table -AutoSize

# Step F2: Reset domain controller machine account password (WRITE — moderate risk)
# Run on the problem DC:
netdom resetpwd /server:(Get-ADDomain).PDCEmulator /userd:DOMAIN\DomainAdmin /passwordd:*

# Step F3: If error 5 (access denied) accompanies 8453 — check SPN registration
setspn -L $ProblemDC

# Step F4: Re-sync security settings (WRITE — low risk)
repadmin /replicate $ProblemDC $ReferenceDC "dc=domain,dc=com" /force
```

---

## Post-Recovery Verification (READ-ONLY)

After any recovery:

```powershell
# Full health sweep
repadmin /replsummary          # 0 failures?
dcdiag /test:replications /v  # All passed?
repadmin /showrepl * /errorsonly  # Any remaining errors?

# Confirm the fixed DC is up-to-date
repadmin /showvector /latency

# Check event log — no new replication errors
Get-WinEvent -ComputerName $ProblemDC -FilterHashtable @{
    LogName='Directory Service'
    Level=2  # Error
    StartTime=(Get-Date).AddHours(-1)
} -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, Message | Format-List
```

**Sign-off**: Replication healthy ✓ | Event logs clean ✓ | Change ticket closed ✓
