# Runbook: KRBTGT Password Rotation
**Risk**: MEDIUM | **Estimated Time**: 3-4 hours (including wait periods)
**Requires**: Domain Admin | **Change Type**: Normal — CAB Required
**Version**: 2.0 | **Owner**: AD Engineering

---

## Why This Runbook Exists

KRBTGT is the Key Distribution Center (KDC) service account. Its password is used to encrypt all Kerberos Ticket Granting Tickets (TGTs). Rotating it is critical after:
- Suspected compromise / Golden Ticket attack
- Scheduled security hygiene (recommend: annually minimum)
- Major admin personnel changes
- Post-AD-breach remediation

**Critical Rule**: KRBTGT rotation MUST be done TWICE to fully invalidate old tickets (due to how the password history works — the previous password is kept for Kerberos validation).

**Wait between rotations**: Minimum = max TGT lifetime (default 10 hours). Safe = replication convergence time + TGT lifetime.

---

## Phase 0 — Prerequisites & Pre-Checks

**Do NOT start if any of these fail:**

```powershell
# Check 1: Replication health — MUST be healthy before rotation
repadmin /replsummary
# Expected: 0 failures. If failures exist, fix replication FIRST.

# Check 2: All DCs reachable
Get-ADDomainController -Filter * | ForEach-Object {
    [PSCustomObject]@{
        DC = $_.Name
        Online = (Test-Connection $_.HostName -Count 1 -Quiet)
    }
} | Format-Table -AutoSize
# Expected: All True. Any False = investigate before continuing.

# Check 3: Current KRBTGT password last set (document this)
Get-ADUser krbtgt -Properties PasswordLastSet, Created |
    Select-Object SamAccountName, PasswordLastSet, Created
# Record: PasswordLastSet = [DATE] — this is your before-state

# Check 4: Current TGT lifetime policy (determines wait time)
# Check Default Domain Policy > Computer Config > Windows Settings > Security Settings > Account Policies > Kerberos Policy
# Default max TGT lifetime = 10 hours. Document your setting.
```

**Pre-check Sign-off**:
- [ ] Replication healthy: 0 failures ✓
- [ ] All DCs reachable ✓
- [ ] Current PasswordLastSet documented: `[DATE]`
- [ ] TGT lifetime confirmed: `[X hours]`
- [ ] Change window open ✓
- [ ] AD backup current: `[BACKUP DATE]`
- [ ] War room bridge active (if security incident driving this rotation): `[MEETING ID]`

---

## Phase 1 — ROTATION 1 OF 2

> This resets the KRBTGT password for the first time. Existing TGTs remain valid until they expire (up to [TGT lifetime] hours from now). This is intentional.

### Step 1.1 — Execute First Rotation

```powershell
# WRITE OPERATION — Risk: MEDIUM
# Resets KRBTGT password. All existing Kerberos tickets remain valid until expiry.
# This is expected and correct behavior.

# Method A: Using AD PowerShell module (preferred)
Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (New-Object System.Security.SecureString)
# Note: Passing empty SecureString forces AD to generate a random password

# Method B: Using Reset-KrbtgtKeyInteractive (Microsoft script — recommended for complex environments)
# Download from: https://github.com/microsoft/New-KrbtgtKeys.ps1
# .\New-KrbtgtKeys.ps1

# Verify: Password last set should now be TODAY
Get-ADUser krbtgt -Properties PasswordLastSet | Select-Object SamAccountName, PasswordLastSet
```
**Expected**: `PasswordLastSet` = current timestamp
**Risk**: MEDIUM — write operation
**Rollback**: Not reversible, but TGTs issued with old password remain valid until expiry

### Step 1.2 — Verify Rotation 1 Replicated

```powershell
# READ-ONLY — Wait for replication to propagate to ALL DCs
# Check every 5 minutes until all DCs show the new PasswordLastSet

$targetTime = Get-Date  # Approximate time of rotation
Get-ADDomainController -Filter * | ForEach-Object {
    $dc = $_.HostName
    try {
        $krb = Get-ADUser krbtgt -Server $dc -Properties PasswordLastSet
        [PSCustomObject]@{
            DC = $dc
            PasswordLastSet = $krb.PasswordLastSet
            Replicated = ($krb.PasswordLastSet -gt $targetTime.AddMinutes(-5))
        }
    } catch {
        [PSCustomObject]@{DC = $dc; PasswordLastSet = "ERROR"; Replicated = $false}
    }
} | Format-Table -AutoSize
```
**Expected**: All DCs show `Replicated = True` and `PasswordLastSet` = today

### Step 1.3 — Monitor for Issues (30 minutes)

Watch for:
- Authentication failures (unusual spike in Event 4771/4625)
- Application errors (service accounts using Kerberos)
- Replication lag

```powershell
# Quick check on PDC Emulator — auth failure count
$PDC = (Get-ADDomain).PDCEmulator
(Get-WinEvent -ComputerName $PDC -FilterHashtable @{
    LogName = 'Security'; Id = 4625
    StartTime = (Get-Date).AddMinutes(-30)
} -ErrorAction SilentlyContinue).Count
# Compare to your baseline — a moderate spike is normal (expiring old tickets)
```

---

## Phase 2 — WAIT PERIOD

> **MANDATORY WAIT**: You MUST wait for all existing Kerberos tickets to expire before doing Rotation 2. This ensures no clients are still using tickets encrypted with the old-old key (which will be gone after Rotation 2).

**Minimum wait**: `[TGT Lifetime]` hours (default: 10 hours)
**Recommended wait**: 12-24 hours for most environments
**Rotation 2 earliest start**: `[Rotation 1 time + TGT Lifetime]`

```
⏰ ROTATION 2 EARLIEST START TIME: [Calculate and fill in]
```

**During wait — monitor**:
```powershell
# Every 2 hours during wait period — check auth failure rate is normal
$PDC = (Get-ADDomain).PDCEmulator
Get-WinEvent -ComputerName $PDC -FilterHashtable @{
    LogName='Security'; Id=4625
    StartTime=(Get-Date).AddHours(-1)
} -ErrorAction SilentlyContinue | Measure-Object | Select-Object Count
```

---

## Phase 3 — ROTATION 2 OF 2

> This invalidates any remaining tickets that were issued under the OLD (pre-Rotation 1) key. After this rotation, the old-old key is gone from AD's password history.

### Step 3.1 — Pre-Rotation 2 Checks

```powershell
# Verify no auth failure spike (should be back to baseline)
# Verify replication still healthy
repadmin /replsummary

# Verify all DCs still show Rotation 1's PasswordLastSet
Get-ADDomainController -Filter * | ForEach-Object {
    Get-ADUser krbtgt -Server $_.HostName -Properties PasswordLastSet |
    Select-Object @{N='DC';E={$_.DistinguishedName -replace '.*,CN=Servers,CN=(.*),CN=Sites.*','$1'}},
                  SamAccountName, PasswordLastSet
} | Format-Table -AutoSize
```

### Step 3.2 — Execute Second Rotation

```powershell
# WRITE OPERATION — Risk: MEDIUM
# This is the critical rotation — invalidates all tickets from before Rotation 1
Set-ADAccountPassword -Identity krbtgt -Reset -NewPassword (New-Object System.Security.SecureString)

# Verify
Get-ADUser krbtgt -Properties PasswordLastSet | Select-Object SamAccountName, PasswordLastSet
```
**Expected**: `PasswordLastSet` = current timestamp (newer than Rotation 1)

### Step 3.3 — Verify Rotation 2 Replicated

Repeat Step 1.2 — wait for ALL DCs to show Rotation 2's new timestamp.

---

## Phase 4 — Post-Rotation Verification

```powershell
# Final verification suite (all READ-ONLY)

# 1. Confirm final PasswordLastSet on ALL DCs
Get-ADDomainController -Filter * | ForEach-Object {
    Get-ADUser krbtgt -Server $_.HostName -Properties PasswordLastSet |
    Select-Object @{N='DC';E={$_.Name}}, PasswordLastSet
} | Format-Table -AutoSize

# 2. Confirm replication still healthy post-rotation
repadmin /replsummary

# 3. Auth failure rate back to baseline
$PDC = (Get-ADDomain).PDCEmulator
(Get-WinEvent -ComputerName $PDC -FilterHashtable @{
    LogName='Security'; Id=4625; StartTime=(Get-Date).AddHours(-1)
} -ErrorAction SilentlyContinue).Count

# 4. Test interactive logon (have a test user log in fresh)
# Expected: Successful login with new TGT issued
```

---

## Phase 5 — Documentation & Close

```powershell
# Generate rotation certificate for audit log
[PSCustomObject]@{
    RotationDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    Domain = (Get-ADDomain).DNSRoot
    Rotation1Time = "[fill in from step 1.1]"
    Rotation2Time = "[fill in from step 3.2]"
    ExecutedBy = "$env:DOMAIN\$env:USERNAME"
    Reason = "[Scheduled hygiene / Post-incident / etc.]"
    AllDCsReplicated = "Yes"
    ReplicationHealthPost = "Clean"
} | ConvertTo-Json | Out-File "C:\ADLogs\KRBTGT_Rotation_$(Get-Date -Format yyyyMMdd).json"
```

**Post-Rotation Checklist**:
- [ ] Both rotations completed
- [ ] All DCs show final PasswordLastSet
- [ ] Replication healthy post-rotation
- [ ] Auth failure rate back to baseline
- [ ] Rotation logged and documented
- [ ] Change ticket closed
- [ ] If security incident: notify security team rotation complete

---

## Troubleshooting

| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| Authentication failures spike after Rotation 2 | Tickets issued in pre-Rotation 1 window still in use | Wait — they will expire within TGT lifetime |
| Application stops working after rotation | App using cached Kerberos ticket with old key | Restart the application/service to force new TGT request |
| Rotation fails with "Access Denied" | Running account doesn't have Domain Admin rights | Verify account privileges |
| DCs show different PasswordLastSet hours later | Replication failure | Fix replication before Rotation 2 |
| Golden Ticket still works after both rotations | Forged ticket uses the domain SID, not KRBTGT key (different attack) | Golden Ticket requires KRBTGT key rotation AND domain SID change |
