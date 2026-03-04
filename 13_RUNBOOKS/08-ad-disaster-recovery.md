# Runbook: Active Directory Disaster Recovery
**Risk**: CRITICAL | **Estimated Time**: 4-24 hours (scenario-dependent)
**Requires**: Domain Admin + physical/console access | **Change Type**: Emergency
**Version**: 2.0

> ⚠️ **READ THIS ENTIRE RUNBOOK BEFORE TAKING ANY ACTION.** Wrong decisions in AD disaster recovery compound damage. Take 10 minutes to assess before touching anything.

---

## Scenario Classification — Choose Your Path

```
QUESTION 1: Do you have at least one healthy DC?
├── YES → Go to SECTION A (Partial failure — most common)
└── NO  → QUESTION 2: Do you have a recent AD backup?
           ├── YES → Go to SECTION B (Full forest recovery from backup)
           └── NO  → SECTION C (Forest recovery without backup — very hard)
```

---

## Phase 0 — Crisis Assessment (Do First — Always)

**Before any action**, answer these questions:

```powershell
# 1. Which DCs are alive?
Get-ADDomainController -Filter * | ForEach-Object {
    [PSCustomObject]@{
        DC = $_.Name; Site = $_.Site
        Online = (Test-Connection $_.HostName -Count 1 -Quiet -ErrorAction SilentlyContinue)
    }
} | Format-Table -AutoSize

# 2. What is the scope of failure?
# One DC? Multiple DCs? All DCs? One site? All sites?

# 3. What failed? (hardware, OS, AD corruption, ransomware, accidental deletion, USN rollback?)

# 4. When did it fail? (How stale would a restored backup be?)

# 5. What data might be lost if we restore from backup?
# (Accounts created, passwords changed, GPO updates since last backup)
```

**Assessment document** (fill in before proceeding):
- DCs online: `[list]`
- DCs offline/failed: `[list]`
- FSMO roles current holders: `[run netdom query fsmo]`
- Last known good AD state: `[approximate time]`
- Last backup date/time: `[from backup system]`
- Failure type: `[hardware / OS / corruption / ransomware / deletion / USN rollback]`

---

## Section A — Partial Failure (One or More DCs Lost, Others Healthy)

### A1 — Transfer FSMO Roles Off Failed DCs

```powershell
# If the failed DC holds FSMO roles, seize them on a healthy DC
# See 06-fsmo-transfer.md → Phase 3 (Emergency Seizure)
$healthyDC = "DC02"
Move-ADDirectoryServerOperationMasterRole `
    -Identity $healthyDC `
    -OperationMasterRole PDCEmulator, RIDMaster, InfrastructureMaster `
    -Force
netdom query fsmo  # Verify
```

### A2 — Clean Up Dead DC's Metadata

```powershell
# After confirming failed DC cannot be recovered
# See 03-dc-decommission.md → Phase 5 (Metadata Cleanup)

# Quick version — remove dead DC's NTDS Settings:
$deadDC = "DC-DEAD01"
$site = "Default-First-Site-Name"  # Adjust to actual site
$domain = (Get-ADDomain).DistinguishedName

# Remove NTDS Settings object (the DC's AD presence)
Get-ADObject `
    -SearchBase "CN=Sites,CN=Configuration,$domain" `
    -Filter { ObjectClass -eq 'nTDSDSA' } |
    Where-Object { $_.DistinguishedName -like "*$deadDC*" } |
    Remove-ADObject -Recursive -Confirm:$false

# Verify
dcdiag /test:replications /v
repadmin /replsummary
```

### A3 — Replace Failed DC

Promote a new DC following [02-dc-promotion.md](02-dc-promotion.md).

---

## Section B — Full Forest Recovery from Backup

> Use when ALL DCs are gone or corrupted and you have a System State backup.

### B1 — Restore the First DC (PDC Emulator Preferred)

**On the first DC to restore:**

1. Boot from Windows Server installation media
2. Choose "Repair your computer" → "Troubleshoot" → "System Image Recovery"
3. OR boot normally and restore System State via Windows Server Backup:

```cmd
REM Boot into Directory Services Restore Mode (DSRM)
REM At boot: F8 → Directory Services Restore Mode
REM Login with: .\Administrator and your DSRM password (NOT domain admin password)

REM Restore from Windows Server Backup
wbadmin get versions -backupTarget:\\BackupServer\ADBackups
wbadmin start systemstaterecovery -version:MM/DD/YYYY-HH:MM -backupTarget:\\BackupServer\ADBackups
```

4. After restore — boot normally (AD DS starts)
5. **Immediately set this DC as authoritative** for SYSVOL:

```powershell
# Only on the FIRST restored DC — makes its SYSVOL authoritative
# Run in elevated PowerShell:
$dfsrParams = @{
    ComputerName = $env:COMPUTERNAME
    Namespace = 'root/MicrosoftDFS'
    Class = 'DfsrVolumeConfig'
}
# Set SYSVOL to authoritative restore mode
Set-ItemProperty `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Services\DFSR\Parameters\SysVols\Seeding SysVols\$((Get-ADDomain).DNSRoot)\Replication" `
    -Name "Enabled" -Value 1 -Type DWORD
# Restart DFSR service
Restart-Service DFSR
```

### B2 — Raise the RID Pool

After restoring from backup, the RID pool might allocate already-used RIDs:

```powershell
# Force RID Master to issue new RIDs (avoids RID collision)
# Run on the restored PDC Emulator
$ridKey = "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\RID Values"
Set-ItemProperty $ridKey -Name "RID Issuance Cap" -Value ([int]::MaxValue)
```

### B3 — Reset KRBTGT Password (MANDATORY after forest recovery)

After any forest recovery, reset KRBTGT **twice** (with wait period):

```powershell
# See 04-krbtgt-rotation.md for the full procedure
# Quick version:
Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (New-Object System.Security.SecureString)
# Wait 10+ hours (max TGT lifetime)
Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (New-Object System.Security.SecureString)
```

### B4 — Restore Additional DCs

For subsequent DCs: either restore from backup (same procedure) or promote fresh DCs following [02-dc-promotion.md](02-dc-promotion.md) and let them replicate from the restored DC.

### B5 — Post-Recovery Verification

```powershell
# Full health sweep
dcdiag /v
repadmin /replsummary
netdom query fsmo

# Check for objects created/changed since backup (data loss assessment)
$backupDate = [datetime]"2026-01-15"  # Adjust to backup date
Get-ADUser -Filter { WhenCreated -gt $backupDate } -Properties WhenCreated |
    Select-Object Name, SamAccountName, WhenCreated |
    Sort-Object WhenCreated
# These users will need to be recreated manually
```

---

## Section C — Forest Recovery Without Backup

> This is a last resort. You will lose data. You may be able to partially reconstruct AD from:
> - Azure AD Connect sync (if hybrid — Entra ID has a copy of most user attributes)
> - HR system exports
> - Email directory
> - Application databases that store user info

### C1 — Rebuild the Forest

```powershell
# Install a fresh forest
Install-ADDSForest `
    -DomainName "corp.contoso.com" `
    -DomainNetbiosName "CORP" `
    -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM Password") `
    -InstallDns:$true `
    -Force:$true
```

### C2 — Reconstruct Users from Entra ID (if hybrid)

```powershell
# Connect to Entra ID (requires Azure AD module or Graph)
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All"

# Export all users from Entra ID
Get-MgUser -All -Select "DisplayName,UserPrincipalName,Department,JobTitle,Mail,ProxyAddresses" |
    Export-Csv "C:\Recovery\UsersFromEntraID.csv" -NoTypeInformation

# Recreate users in new AD from CSV
Import-Csv "C:\Recovery\UsersFromEntraID.csv" | ForEach-Object {
    $sam = ($_.UserPrincipalName -split "@")[0]
    New-ADUser `
        -Name $_.DisplayName `
        -SamAccountName $sam `
        -UserPrincipalName $_.UserPrincipalName `
        -Department $_.Department `
        -Title $_.JobTitle `
        -EmailAddress $_.Mail `
        -AccountPassword (ConvertTo-SecureString "TempPass123!" -AsPlainText -Force) `
        -Enabled $true `
        -ChangePasswordAtLogon $true
}
```

---

## Post-Recovery Mandatory Steps

After ANY disaster recovery path:

- [ ] **KRBTGT rotated twice** (mandatory — see 04-krbtgt-rotation.md)
- [ ] All DC replication healthy: `repadmin /replsummary`
- [ ] All DCDiag tests passing: `dcdiag /v`
- [ ] FSMO roles confirmed on correct DCs
- [ ] User authentication tested from each site
- [ ] SYSVOL replication healthy (GPOs applying)
- [ ] Application teams confirmed services restored
- [ ] Security team notified (incident may be security-related)
- [ ] Data loss assessment documented (accounts/changes since last backup)
- [ ] PIR scheduled within 5 business days
- [ ] Backup strategy reviewed — how do we prevent this?

---

## Prevention (Do These Now — Before You Need This Runbook)

```powershell
# Verify backup exists and is recent
wbadmin get versions  # Should show backup from today or yesterday

# Verify backup includes System State
wbadmin get versions | Select-String "System State"

# Test restore in a lab yearly — "An untested backup is not a backup"

# Ensure multiple DCs per site (2 minimum)
Get-ADDomainController -Filter * | Group-Object Site | Select-Object Name, Count

# Document DSRM passwords for all DCs in password vault
# Without the DSRM password you cannot restore from backup
```

> **The best disaster recovery is never needing this runbook.** Run your [weekly health check](01-weekly-health-check.md) every week and keep backups current.
