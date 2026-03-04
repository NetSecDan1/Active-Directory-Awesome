# Runbook: FSMO Role Transfer (and Emergency Seizure)
**Risk**: HIGH (Transfer) / CRITICAL (Seizure)
**Estimated Time**: 30-60 minutes | **Requires**: Domain Admin (Transfer) / Enterprise Admin (Seizure)
**Change Type**: Normal (Transfer) / Emergency (Seizure) | **Version**: 2.0

---

## The Critical Distinction

| | Transfer | Seizure |
|--|---------|---------|
| **When** | Current role holder is online and healthy | Current role holder is gone and unrecoverable |
| **How** | Both DCs communicate, handoff is clean | New DC forcibly takes the role |
| **Risk** | LOW — clean operation | HIGH — can cause issues if old holder returns |
| **Command** | `Move-ADDirectoryServerOperationMasterRole` | `Move-ADDirectoryServerOperationMasterRole -Force` |
| **Reversible** | Yes | **Never bring old holder back online after seizure** |

> ⚠️ **Never seize when you can transfer.** If the current holder is unreachable but might come back, fix the connectivity first.

---

## Phase 0 — Current State Assessment

```powershell
# Step 0.1 — Who holds each role RIGHT NOW?
netdom query fsmo

# Step 0.2 — Are the current role holders online and healthy?
$fsmoHolders = @(
    (Get-ADDomain).PDCEmulator,
    (Get-ADDomain).RIDMaster,
    (Get-ADDomain).InfrastructureMaster,
    (Get-ADForest).SchemaMaster,
    (Get-ADForest).DomainNamingMaster
) | Sort-Object -Unique

foreach ($dc in $fsmoHolders) {
    $online = Test-Connection $dc -Count 1 -Quiet -ErrorAction SilentlyContinue
    $ldap = Test-NetConnection $dc -Port 389 -WA SilentlyContinue
    Write-Host "$dc : Ping=$online LDAP=$($ldap.TcpTestSucceeded)"
}

# Step 0.3 — Is replication healthy? (Important before any transfer)
repadmin /replsummary
```

---

## Phase 1 — Transfer (Normal Operation)

### Step 1.1 — Transfer Domain Roles

```powershell
# Target: The DC that will receive the roles
$targetDC = "DC02.corp.contoso.com"

# Transfer PDC Emulator (most commonly transferred)
# Impact: Authentication, lockout processing, time sync, GPO updates
Move-ADDirectoryServerOperationMasterRole `
    -Identity $targetDC `
    -OperationMasterRole PDCEmulator
Write-Host "PDC Emulator transferred to $targetDC"

# Transfer RID Master
# Impact: Account creation — RID pool allocation
Move-ADDirectoryServerOperationMasterRole `
    -Identity $targetDC `
    -OperationMasterRole RIDMaster
Write-Host "RID Master transferred to $targetDC"

# Transfer Infrastructure Master
# Impact: Cross-domain group membership display
# Note: Do NOT place on a GC server (unless all DCs are GCs)
Move-ADDirectoryServerOperationMasterRole `
    -Identity $targetDC `
    -OperationMasterRole InfrastructureMaster
Write-Host "Infrastructure Master transferred to $targetDC"
```

### Step 1.2 — Transfer Forest Roles (run in forest root domain context)

```powershell
# Forest roles — require Enterprise Admin
# Schema Master — transfer only when running schema extensions (rarely moved otherwise)
Move-ADDirectoryServerOperationMasterRole `
    -Identity $targetDC `
    -OperationMasterRole SchemaMaster

# Domain Naming Master — transfer only when adding/removing domains
Move-ADDirectoryServerOperationMasterRole `
    -Identity $targetDC `
    -OperationMasterRole DomainNamingMaster
```

### Step 1.3 — Verify Transfers

```powershell
# Verify all roles are where expected
netdom query fsmo

# Confirm the target DC responds as the new role holder
nltest /dsgetdc:(Get-ADDomain).DNSRoot /PDC /force
# Expected: Returns $targetDC
```

---

## Phase 2 — Role Placement Best Practices

| Role | Recommended DC | Reasoning |
|------|---------------|-----------|
| **PDC Emulator** | Fastest, most reliable DC in largest site | Authentication, lockouts, time sync — latency sensitive |
| **RID Master** | Same DC as PDC Emulator | Minimizes RPC calls between roles |
| **Infrastructure Master** | NOT on a GC server (if not all DCs are GCs) | Needs to compare its data with GC data |
| **Schema Master** | Forest root domain, any DC | Rarely used — keep offline when not extending schema |
| **Domain Naming Master** | Forest root domain, same as Schema Master | Rarely used |

```powershell
# Quick check: Is Infrastructure Master on a GC? (Problem if not all DCs are GCs)
$infra = (Get-ADDomain).InfrastructureMaster
$isGC = (Get-ADDomainController -Identity $infra).IsGlobalCatalog
$allGC = (Get-ADDomainController -Filter *).IsGlobalCatalog -notcontains $false

if ($isGC -and -not $allGC) {
    Write-Host "⚠️ WARNING: Infrastructure Master is on a GC but not all DCs are GCs" -ForegroundColor Yellow
    Write-Host "    This causes cross-domain group membership display issues" -ForegroundColor Yellow
}
```

---

## Phase 3 — Emergency Seizure (Current Holder Permanently Gone)

> **Gate**: Confirm the current holder is permanently offline before proceeding.
> Once you seize a role, **the old holder must NEVER come back online.**
> If there's any chance it returns, fix connectivity instead.

```powershell
# Step 3.1 — Confirm old holder is unrecoverable (document this decision)
# Who confirmed: _______________ | Time: _______________ | Reason: _______________

# Step 3.2 — Seize domain roles
$targetDC = "DC02.corp.contoso.com"  # Healthy DC that will take the roles

Move-ADDirectoryServerOperationMasterRole `
    -Identity $targetDC `
    -OperationMasterRole PDCEmulator, RIDMaster, InfrastructureMaster `
    -Force  # Force = Seizure — the -Force flag is what makes this a seizure
# You will be prompted to confirm for each role

# Step 3.3 — Seize forest roles (if forest root DC is gone — Enterprise Admin required)
Move-ADDirectoryServerOperationMasterRole `
    -Identity $targetDC `
    -OperationMasterRole SchemaMaster, DomainNamingMaster `
    -Force

# Step 3.4 — Verify
netdom query fsmo

# Step 3.5 — After seizure: Clean up metadata of old DC
# See 03-dc-decommission.md → Phase 5: Metadata Cleanup
```

---

## Verification After Transfer or Seizure

```powershell
# 1. Confirm new role holders
netdom query fsmo

# 2. Confirm authentication still working
nltest /dsgetdc:(Get-ADDomain).DNSRoot /PDC /force
# Expected: returns the new PDC Emulator

# 3. Test a password change (uses PDC Emulator)
# Have a test user change their password and verify it succeeds

# 4. Confirm RID pool allocation (test account creation)
# Try creating a test user — if RID Master isn't working this fails
New-ADUser -Name "TEST-FSMO-$(Get-Random)" -SamAccountName "test-fsmo" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
    -Enabled $true
# Verify created, then clean up:
Remove-ADUser -Identity "test-fsmo" -Confirm:$false

# 5. Confirm replication still healthy
repadmin /replsummary
```

---

## Rollback

**For transfers**: Simply transfer roles back to the original DC.

```powershell
$originalDC = "DC01.corp.contoso.com"
Move-ADDirectoryServerOperationMasterRole `
    -Identity $originalDC `
    -OperationMasterRole PDCEmulator, RIDMaster, InfrastructureMaster
```

**For seizures**: No rollback possible. The seized DC is authoritative. The old DC must remain offline permanently.

---

## Post-Operation Checklist

- [ ] All FSMO roles confirmed on expected DCs (`netdom query fsmo`)
- [ ] Replication healthy post-operation (`repadmin /replsummary`)
- [ ] Authentication testing passed
- [ ] Documentation updated (CMDB, runbooks, team wiki)
- [ ] Monitoring updated (alert on new FSMO holder)
- [ ] If seizure: old DC metadata cleaned up, old DC permanently isolated
- [ ] Change ticket closed
