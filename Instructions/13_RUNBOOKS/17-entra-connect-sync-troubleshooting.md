# Runbook: Microsoft Entra Connect Sync Troubleshooting
**Risk**: READ-ONLY (investigation) / MEDIUM (sync fixes) | **Estimated Time**: 45-120 minutes
**Requires**: Entra Connect server local admin, Global Admin or Hybrid Identity Admin | **Change Type**: Normal
**Version**: 1.0 | **Owner**: AD Engineering / Identity Team

---

## Phase 0 — Information Gathering

**Before proceeding, I need the following:**

- [ ] **Symptom**: Objects not syncing to Entra? Password hash sync broken? Writeback failing? Full sync taking forever?
- [ ] **Entra Connect server hostname**: `[HOSTNAME]`
- [ ] **Entra Connect version**: (Get from `Get-ADSyncGlobalSettings` or Programs & Features)
- [ ] **Sync topology**: Single server? Active/Staging pair? Multiple connectors?
- [ ] **Scope**: All objects, specific OU, specific user(s), or specific attribute?
- [ ] **Error message**: Exact text from Synchronization Service Manager or event log
- [ ] **When started**: When was the issue first noticed? Was a sync cycle run recently?
- [ ] **Recent changes**: Entra Connect upgraded? AD schema change? UPN change? OU moved?

Do not proceed until these are answered.

---

## Overview

Entra Connect sync failures split into five areas:
1. **Connectivity** — Can't reach on-premises AD or Entra ID
2. **Sync rules and filtering** — Objects not in scope or filtered out
3. **Object-level errors** — Specific objects failing with attribute conflicts
4. **Password Hash Sync (PHS)** — Passwords not flowing to cloud
5. **Writeback** — Cloud changes not writing back to on-premises

---

## Decision Tree

```
START: Entra Connect / hybrid sync issue
    │
    ├─ No sync at all (all objects stale)? ──────────────────────► Phase 1: Connectivity
    │
    ├─ Most objects syncing, specific ones failing? ─────────────► Phase 2: Object Errors
    │
    ├─ Object exists in AD but not in Entra? ────────────────────► Phase 3: Filtering / Scope
    │
    ├─ Password changes not flowing to cloud? ───────────────────► Phase 4: Password Hash Sync
    │
    ├─ Cloud changes not writing back to AD? ────────────────────► Phase 5: Writeback
    │
    ├─ Sync taking forever / scheduler stuck? ───────────────────► Phase 6: Scheduler & Performance
    │
    └─ Staging server needs to be promoted? ─────────────────────► Phase 7: Staging Mode
```

---

## Phase 1 — Connectivity and Service Health

```powershell
$syncServer = "ENTRACONN01"   # Replace with Entra Connect server hostname

# ── Check Entra Connect services ──────────────────────────────────────────
Get-Service -ComputerName $syncServer -Name ADSync, AzureADConnectAgentUpdater -ErrorAction SilentlyContinue |
    Select-Object MachineName, Name, Status, StartType | Format-Table -AutoSize

# ── Check sync connectivity to Entra ID ───────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Import-Module ADSync -ErrorAction SilentlyContinue

    # Test connection to Azure AD connector
    $connectors = Get-ADSyncConnector | Select-Object Name, Type, ConnectivityParameters
    Write-Host "Configured connectors:"
    $connectors | Format-Table -AutoSize

    # Test Entra connectivity:
    Test-AzureADConnectivityFromServer   # if available in your version
}

# ── Check sync account credentials ────────────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Import-Module ADSync
    # List connector accounts (don't show passwords — read-only check)
    Get-ADSyncConnector | ForEach-Object {
        [PSCustomObject]@{
            Connector = $_.Name
            Type      = $_.Type
            Account   = ($_.ConnectivityParameters | Where-Object { $_.Name -eq 'forest-login-user' }).Value
        }
    } | Format-Table -AutoSize
}

# ── Check event log for connector errors ─────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Get-WinEvent -FilterHashtable @{
        LogName   = 'Application'
        Source    = 'ADSync'
        StartTime = (Get-Date).AddHours(-24)
        Level     = @(1, 2)   # Critical, Error
    } -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, Message | Format-Table -AutoSize -Wrap
}
```

---

## Phase 2 — Object-Level Sync Errors

```powershell
$syncServer = "ENTRACONN01"

# ── Get all objects with sync errors ──────────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Import-Module ADSync

    # All current sync errors
    Get-ADSyncCSObject -ConnectorName "contoso.com" -ErrorAction SilentlyContinue |  # Replace connector name
        Where-Object { $_.SyncAttemptErrors -ne $null } |
        Select-Object AnchorValue, DisplayName, SyncAttemptErrors | Format-List
}

# ── Use Synchronization Service Manager (GUI) for deep dives ──────────────
# On Entra Connect server:
# Start → Synchronization Service → Operations tab
# Look for: Export errors, Import errors, Provisioning errors
# Common error categories:
# - AttributeValueMustBeUnique (duplicate proxyAddresses or UPN in Entra)
# - InvalidSoftMatch (duplicate object match conflict)
# - ObjectTypeMismatch (user vs contact conflict in Entra)

# ── PowerShell: Export sync errors to reviewable table ────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Import-Module ADSync, MSOnline -ErrorAction SilentlyContinue

    # Get Entra ID sync errors via MSOnline:
    Connect-MsolService   # Requires Global Admin credentials
    Get-MsolDirSyncProvisioningError -ErrorCategory PropertyConflict |
        Select-Object DisplayName, UserPrincipalName, PropertyConflictErrors |
        Format-Table -AutoSize
}

# ── Fix duplicate attribute conflict (most common object error) ───────────
# Example: Two on-prem users have same proxyAddress, only one can sync
# Step 1: Identify which on-prem account has the conflicting attribute
# Get-ADUser -Filter { proxyAddresses -like "*conflicting@domain.com*" } -Properties proxyAddresses

# Step 2: Remove duplicate from the wrong account (WRITE — MEDIUM RISK)
# Set-ADUser "wronguser" -Remove @{proxyAddresses="smtp:conflicting@domain.com"}

# Step 3: Force delta sync to resolve
# Invoke-Command -ComputerName $syncServer -ScriptBlock {
#     Import-Module ADSync
#     Start-ADSyncSyncCycle -PolicyType Delta
# }
```

---

## Phase 3 — Filtering and Scope (Object Not Syncing)

```powershell
$syncServer  = "ENTRACONN01"
$testUser    = "jdoe"   # SamAccountName of the user that should be syncing
$connectorName = "contoso.com"   # Replace with your AD connector name

# ── Check if the user is in the sync scope ────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    param($user, $connector)
    Import-Module ADSync

    # Find the user in the connector space (CS)
    $csObj = Get-ADSyncCSObject -ConnectorName $connector -DistinguishedName (Get-ADUser $user).DistinguishedName -ErrorAction SilentlyContinue
    if ($csObj) {
        Write-Host "Object FOUND in connector space" -ForegroundColor Green
        Write-Host "Sync state: $($csObj.SyncState)"
        Write-Host "MV link: $($csObj.ConnectedMVObjectId)"
    } else {
        Write-Host "Object NOT in connector space — check OU filtering" -ForegroundColor Red
    }
} -ArgumentList $testUser, $connectorName

# ── Check OU-based filtering ──────────────────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Import-Module ADSync
    # Show which OUs are included/excluded in sync scope
    $connector = Get-ADSyncConnector -Name "contoso.com"
    $connector.Partitions | ForEach-Object {
        Write-Host "Partition: $($_.Name)"
        Write-Host "  Included OUs:" -ForegroundColor Green
        $_.ContainerIncludeList | ForEach-Object { Write-Host "    $_" }
        Write-Host "  Excluded OUs:" -ForegroundColor Red
        $_.ContainerExcludeList | ForEach-Object { Write-Host "    $_" }
    }
}

# ── Check attribute-based filtering ──────────────────────────────────────
# If you have attribute-based filtering (e.g., extensionAttribute1 = "sync"):
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Import-Module ADSync
    Get-ADSyncRule | Where-Object { $_.ScopingFilter -ne $null -and $_.ScopingFilter.ScopeConditionList.Count -gt 0 } |
        Select-Object Name, Precedence, ScopingFilter | Format-List
}

# ── Add an OU to sync scope (WRITE — MEDIUM RISK) ─────────────────────────
# Use the Entra Connect wizard: re-run and choose "Customize synchronization options"
# → Domain and OU filtering → add the required OU
# DO NOT manually modify sync rules directly
```

---

## Phase 4 — Password Hash Sync (PHS) Failures

```powershell
$syncServer = "ENTRACONN01"

# ── Check PHS agent status ────────────────────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Import-Module ADSync
    Get-ADSyncAADPasswordSyncConfiguration -SourceConnector "contoso.com" |
        Format-List

    # Check PHS service/agent:
    Get-Service -Name AzureADConnectAuthenticationAgent -ErrorAction SilentlyContinue |
        Select-Object Status, DisplayName
}

# ── Check PHS event log ───────────────────────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        Source  = 'ADSync'
        Id      = @(656, 657, 658, 659)  # PHS-specific event IDs
        StartTime = (Get-Date).AddHours(-24)
    } -ErrorAction SilentlyContinue | Format-Table TimeCreated, Id, Message -AutoSize -Wrap
}

# ── Verify PHS is enabled ─────────────────────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Import-Module ADSync
    # Check if PHS feature is enabled
    $features = Get-ADSyncGlobalSettings
    Write-Host "PHS Enabled: $($features.Parameters | Where-Object { $_.Name -eq 'Microsoft.OptionalFeature.PasswordHashSync' })"
}

# ── Force immediate password sync for a specific user ────────────────────
# (Triggers a delta sync for that user's password hash — LOW RISK)
# Invoke-Command -ComputerName $syncServer -ScriptBlock {
#     Import-Module ADSync
#     $user = Get-ADUser "jdoe" -Properties ObjectGUID
#     Invoke-ADSyncRunProfile -ConnectorName "contoso.com" -RunProfileName "Delta Import"
# }
```

**PHS common failures**:
| Symptom | Cause | Fix |
|---------|-------|-----|
| Passwords not syncing after change | PHS disabled | Enable via Entra Connect wizard |
| Sync account lacks AD DS permissions | DSRM/KDS permission not granted | Re-run wizard, re-grant permissions |
| PHS working but cloud password overriding | Password writeback conflict | Check writeback config and priority |
| Selective password sync filtered | msDS-ExternalDirectoryObjectId conflict | Review Azure AD Connect sync rules for password scope |

---

## Phase 5 — Writeback Failures

```powershell
$syncServer = "ENTRACONN01"

# ── Check which writeback features are enabled ────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Import-Module ADSync
    Get-ADSyncAADCompanyFeature | Format-List
    # Look for: PasswordWriteback, GroupWriteback, DeviceWriteback, UserWriteback
}

# ── Check writeback event log ─────────────────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Get-WinEvent -FilterHashtable @{
        LogName   = 'Application'
        Source    = 'PasswordResetService'
        StartTime = (Get-Date).AddHours(-24)
        Level     = @(1, 2, 3)
    } -ErrorAction SilentlyContinue | Format-Table TimeCreated, Id, Message -AutoSize -Wrap
}

# ── Check password writeback service account permissions ─────────────────
# The Entra Connect service account needs these AD rights for SSPR writeback:
# - Reset password on descendant User objects
# - Write lockoutTime on descendant User objects
# - Write pwdLastSet on descendant User objects
$syncAccount = "DOMAIN\MSOL_xxxxxxxx"   # Replace with actual sync account
Get-ADUser -Filter { SamAccountName -like "MSOL_*" } |
    Select-Object SamAccountName, DistinguishedName | Format-Table -AutoSize
```

---

## Phase 6 — Scheduler and Performance

```powershell
$syncServer = "ENTRACONN01"

# ── Check sync scheduler status ──────────────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Import-Module ADSync
    Get-ADSyncScheduler | Format-List
    # Key fields:
    # SyncCycleEnabled: True/False
    # CurrentlyRunning: True = sync in progress
    # NextSyncCyclePolicyType: Delta / Initial
    # NextSyncCycleStartTimeInUTC: when next sync fires
    # MaintenanceEnabled: True = maintenance tasks running
    # StagingModeEnabled: True = THIS IS STAGING SERVER — does not export to Entra
}

# ── Check last sync run times ─────────────────────────────────────────────
Invoke-Command -ComputerName $syncServer -ScriptBlock {
    Import-Module ADSync
    Get-ADSyncRunStepResult | Select-Object -First 20 |
        Select-Object ConnectorName, RunProfileName, StartDate, EndDate,
            @{N='Duration'; E={ ($_.EndDate - $_.StartDate).ToString("hh\:mm\:ss") }},
            StepResult | Format-Table -AutoSize
}

# ── If scheduler is stuck: restart safely ────────────────────────────────
# WRITE OPERATION — LOW RISK — run on Entra Connect server
# Invoke-Command -ComputerName $syncServer -ScriptBlock {
#     Import-Module ADSync
#     # Stop any running sync:
#     Stop-ADSyncSyncCycle
#     # Restart ADSync service:
#     Restart-Service ADSync
#     # Then start a delta sync:
#     Start-ADSyncSyncCycle -PolicyType Delta
# }
```

---

## Phase 7 — Staging Mode (Disaster Recovery Promotion)

```powershell
$activeServer  = "ENTRACONN01"   # Current active server
$stagingServer = "ENTRACONN02"  # Staging server to promote

# ── Verify staging server status ─────────────────────────────────────────
Invoke-Command -ComputerName $stagingServer -ScriptBlock {
    Import-Module ADSync
    $scheduler = Get-ADSyncScheduler
    Write-Host "Staging mode: $($scheduler.StagingModeEnabled)"
    Write-Host "Last sync: $($scheduler.LastSyncCycleResult)"
    # StagingModeEnabled = True means this server is NOT exporting to Entra
    # It is importing and processing — ready to be promoted
}

# ── Check staging server is up to date ────────────────────────────────────
Invoke-Command -ComputerName $stagingServer -ScriptBlock {
    Import-Module ADSync
    # Last successful import should be within 30 minutes
    Get-ADSyncRunStepResult | Select-Object -First 5 |
        Select-Object ConnectorName, StartDate, StepResult | Format-Table -AutoSize
}

# ── Promote staging to active (WRITE — HIGH RISK — only when active is offline) ──
# Invoke-Command -ComputerName $stagingServer -ScriptBlock {
#     Import-Module ADSync
#     # Disable staging mode — THIS SERVER WILL NOW EXPORT TO ENTRA
#     Set-ADSyncScheduler -StagingModeEnabled $false
#     # Then run a full sync to export all pending changes
#     Start-ADSyncSyncCycle -PolicyType Initial
# }
# NOTE: After promoting, decommission or rebuild the old active server
#       Do NOT have two active sync servers simultaneously
```

---

## Entra Connect Health Quick Reference

Access at: [entra.microsoft.com](https://entra.microsoft.com) → Identity → Hybrid Management → Entra Connect Health

| Health Alert | Meaning | Fix |
|-------------|---------|-----|
| Sync service not running | ADSync service stopped | `Start-Service ADSync` |
| Duplicate attribute | Two objects with same UPN/proxyAddress | Remove duplicate attribute from one object |
| Object filtering changed | OU/attribute filter removed objects | Re-add OU to sync scope |
| Export errors | Objects failing to export to Entra | Check Sync Service Manager → Operations → Export errors |
| Scheduler disabled | `SyncCycleEnabled = False` | `Set-ADSyncScheduler -SyncCycleEnabled $true` |
| Staging mode active | Server not exporting | Intentional (staging) or bug — verify which |
| Password writeback not configured | Writeback feature disabled | Enable in Entra Connect wizard |

---

## Documentation

Record in Jira ticket:
- Entra Connect server: `[NAME]` / Version: `[VERSION]`
- Sync scope: Active / Staging
- Symptom: `[CATEGORY]`
- Objects affected: `[COUNT / NAMES]`
- Error: `[CODE / MESSAGE]`
- Root cause: `[DESCRIPTION]`
- Fix: `[COMMAND OR CHANGE]`
- Verification: `[Sync completed, object visible in Entra]`
