# Runbook: Domain Controller Decommission
**Risk**: HIGH | **Estimated Time**: 2-3 hours
**Requires**: Domain Admin | **Change Type**: Normal — CAB Required
**Version**: 2.0

---

## The Golden Rules of DC Decommission

1. **Never seize FSMO roles** when you can transfer them
2. **Always demote gracefully** — never just shut down a DC without demoting
3. **Verify replication** converges BEFORE and AFTER
4. **Clean up metadata** ONLY if graceful demotion failed (e.g., DC is already dead)

---

## Phase 0 — Pre-Decommission Assessment

```powershell
$DC = "DC-OLD01"
$domain = (Get-ADDomain).DNSRoot

# Step 0.1 — Confirm DC exists and get its details
Get-ADDomainController -Identity $DC |
    Select-Object Name, Site, IPv4Address, IsGlobalCatalog, IsReadOnly, OperatingSystem

# Step 0.2 — Check if DC holds any FSMO roles (CRITICAL — must transfer first)
netdom query fsmo
# If this DC appears in output → go to Phase 1 before Phase 2

# Step 0.3 — Check if DC is a bridgehead server
repadmin /bridgeheads | Select-String $DC
# If it appears → KCC will select new bridgehead automatically after demotion

# Step 0.4 — Check DNS — is this DC listed as a DNS server anywhere?
Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses -contains (Resolve-DnsName $DC -Type A).IPAddress }
# Update DNS client settings on any machine pointing to this DC before decommission

# Step 0.5 — Verify remaining DCs are healthy (don't decommission into broken replication)
repadmin /replsummary
# Expected: 0 failures

# Step 0.6 — Confirm we will still have adequate DC coverage after removal
Get-ADDomainController -Filter * | Select-Object Name, Site |
    Group-Object Site | Select-Object Name, Count
# Ensure every site with users still has ≥ 2 DCs after removal
```

---

## Phase 1 — Transfer FSMO Roles (if held by this DC)

> Skip if the DC holds no FSMO roles (confirmed in Step 0.2)

```powershell
# Identify a suitable target DC for roles
$targetDC = "DC-NEW01"  # Must be healthy, well-connected DC

# Transfer individual roles (WRITE — MEDIUM risk)
# Transfer PDC Emulator
Move-ADDirectoryServerOperationMasterRole -Identity $targetDC -OperationMasterRole PDCEmulator
# Transfer RID Master
Move-ADDirectoryServerOperationMasterRole -Identity $targetDC -OperationMasterRole RIDMaster
# Transfer Infrastructure Master
Move-ADDirectoryServerOperationMasterRole -Identity $targetDC -OperationMasterRole InfrastructureMaster

# Forest-level roles (only if DC is in forest root domain)
# Move-ADDirectoryServerOperationMasterRole -Identity $targetDC -OperationMasterRole SchemaMaster
# Move-ADDirectoryServerOperationMasterRole -Identity $targetDC -OperationMasterRole DomainNamingMaster

# Verify transfers completed
netdom query fsmo
# Expected: $DC no longer appears for any role
```

---

## Phase 2 — Remove Global Catalog (if applicable)

If the DC is a Global Catalog server in a site where other GCs exist:

```powershell
# Remove GC designation before demotion (reduces demotion time)
# Run in Active Directory Sites and Services:
# Navigate to: Site → Servers → DC-OLD01 → NTDS Settings
# Right-click NTDS Settings → Properties → Uncheck "Global Catalog"
# Wait for replication to converge (~15 minutes), then proceed with demotion

# Verify GC removed
Get-ADDomainController -Identity $DC | Select-Object Name, IsGlobalCatalog
# Expected: IsGlobalCatalog = False
```

---

## Phase 3 — Graceful Demotion (WRITE — HIGH risk)

### Option A: Remote demotion (preferred — run from another machine)

```powershell
# Demote via remote PowerShell session on the DC being removed
$session = New-PSSession -ComputerName $DC -Credential (Get-Credential -Message "Domain Admin")
Invoke-Command -Session $session -ScriptBlock {
    Uninstall-ADDSDomainController `
        -LocalAdministratorPassword (ConvertTo-SecureString "TempLocalPass123!" -AsPlainText -Force) `
        -NoRebootOnCompletion:$false `
        -Force:$true
}
# DC will restart as a member server
```

### Option B: Local demotion (run on the DC being removed)

```powershell
Uninstall-ADDSDomainController `
    -LocalAdministratorPassword (Read-Host -Prompt "New local admin password" -AsSecureString) `
    -NoRebootOnCompletion:$false `
    -Force:$true
# Server restarts automatically. After restart it's a plain member server.
```

**What happens during graceful demotion:**
- AD DS role is removed
- DNS server role is removed (if installed by AD DS)
- Computer object moves to "Computers" container
- All NTDS Settings objects cleaned up automatically
- DNS records de-registered automatically

---

## Phase 4 — Post-Demotion Cleanup

```powershell
# Step 4.1 — Verify DC no longer appears in AD
Get-ADDomainController -Filter * | Select-Object Name
# Expected: $DC is NOT in the list

# Step 4.2 — Verify replication still healthy after removal
repadmin /replsummary
# Expected: 0 failures, $DC no longer in output

# Step 4.3 — Check for stale DNS records (read-only check)
Resolve-DnsName $DC -Type A -ErrorAction SilentlyContinue
# Should resolve to nothing, or if it does resolve, manually clean up:
# Get-DnsServerResourceRecord -ZoneName $domain -Name $DC | Remove-DnsServerResourceRecord -Force

# Step 4.4 — Remove computer account if not needed
# (only after confirming server is repurposed or retired)
# Get-ADComputer $DC | Disable-ADAccount   # Disable first, wait 30 days
# Get-ADComputer $DC | Remove-ADObject -Recursive  # Then delete
```

---

## Phase 5 — Emergency: Metadata Cleanup (DC Already Dead)

> Only use this if the DC crashed/burned and you **cannot** do a graceful demotion.
> This manually removes the dead DC's AD metadata.

```powershell
# WRITE — CRITICAL: Only run if graceful demotion is impossible
# Requires: the DC is confirmed permanently offline

# Method 1: PowerShell (WS 2012 R2+)
$deadDC = Get-ADDomainController -Identity $DC -ErrorAction SilentlyContinue
if (-not $deadDC) {
    # Already removed from AD. Check for orphaned objects:
    Get-ADObject -Filter { ObjectClass -eq 'nTDSDSA' } -SearchBase "CN=Sites,CN=Configuration,DC=domain,DC=com" |
        Where-Object { $_.DistinguishedName -like "*$DC*" }
}

# Method 2: ntdsutil (if above fails)
# Run on any healthy DC:
# ntdsutil
#   metadata cleanup
#     connections
#       connect to server DC02
#     quit
#   select operation target
#     list sites → select site N
#     list servers in site → select server N (the dead DC)
#   remove selected server
#   quit
# quit

# After metadata cleanup — verify clean
dcdiag /test:replications /v
repadmin /replsummary
```

---

## Final Checklist

- [ ] FSMO roles transferred and verified on new holder
- [ ] Graceful demotion completed (server restarted as member server)
- [ ] Replication healthy after removal (0 failures)
- [ ] Stale DNS records removed
- [ ] Computer account disabled/deleted
- [ ] Monitoring system updated (remove DC from alerts)
- [ ] CMDB / asset management updated
- [ ] Any hardcoded DNS pointers to old DC IP updated
- [ ] Change ticket closed
- [ ] DSRM password for decommissioned DC removed from vault
