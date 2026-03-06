# Runbook: Privileged Identity Tier Model — Health Audit
**Risk**: READ-ONLY | **Estimated Time**: 60-120 minutes
**Requires**: AD read access, Entra read access | **Change Type**: N/A (audit only)
**Version**: 1.0 | **Owner**: Identity Security / AD Engineering

---

## Phase 0 — Information Gathering

**Before proceeding, I need the following:**

- [ ] **Audit scope**: Full domain audit? Specific tier? Specific group? Triggered by security review?
- [ ] **Tiering model in use**: Microsoft Tier 0/1/2? Custom model? PAW model deployed?
- [ ] **Domain(s)**: Which domain(s) to audit?
- [ ] **Known privileged groups**: Which groups are considered Tier 0 in this environment?
- [ ] **Output needed**: Full audit report? Specific concern (e.g., admin with stale account, excessive group membership)?
- [ ] **Recent changes**: Any recent admin account changes, role assignments, or security incidents?

Do not proceed until these are answered.

---

## Overview

This runbook audits the health of the privileged identity tier model across Active Directory and Entra ID. It identifies: over-privileged accounts, stale admin accounts, missing tier separation, shadow admins (accounts with admin-equivalent rights not in admin groups), and Tier 0 blast radius.

**Tiers (Microsoft model)**:
| Tier | Scope | Examples |
|------|-------|---------|
| **Tier 0** | Control plane — full AD / identity control | Domain Admins, Enterprise Admins, Schema Admins, KRBTGT, Domain Controllers, Entra Global Admins |
| **Tier 1** | Server management | Server Admins, Exchange Admins, application-specific admins |
| **Tier 2** | Workstation / user support | Help Desk, Local Admins on workstations |

---

## Phase 1 — Tier 0 Group Membership Audit

```powershell
$domain = (Get-ADDomain).DNSRoot

# ── Enumerate Tier 0 AD groups and their members ─────────────────────────
$tier0Groups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Administrators",
    "Group Policy Creator Owners",
    "DNSAdmins",           # Can achieve Tier 0 via DLL injection on DNS service
    "Account Operators",   # Can modify admin group members
    "Backup Operators",    # Can read any file, restore as admin
    "Print Operators",     # Can load drivers, potential code execution on DCs
    "Server Operators"     # Can start/stop services on DCs
)

$tier0Findings = foreach ($group in $tier0Groups) {
    try {
        $members = Get-ADGroupMember -Identity $group -Recursive -ErrorAction Stop
        foreach ($member in $members) {
            $acct = if ($member.objectClass -eq 'user') {
                Get-ADUser $member.DistinguishedName -Properties LastLogonDate, Enabled, PasswordLastSet, PasswordNeverExpires
            } else { $member }

            [PSCustomObject]@{
                Group              = $group
                Member             = $member.SamAccountName
                Type               = $member.objectClass
                Enabled            = if ($acct.Enabled -ne $null) { $acct.Enabled } else { "N/A (group)" }
                LastLogon          = if ($acct.LastLogonDate) { $acct.LastLogonDate.ToString("yyyy-MM-dd") } else { "Never/Unknown" }
                PasswordLastSet    = if ($acct.PasswordLastSet) { $acct.PasswordLastSet.ToString("yyyy-MM-dd") } else { "N/A" }
                PwdNeverExpires    = if ($acct.PasswordNeverExpires -ne $null) { $acct.PasswordNeverExpires } else { "N/A" }
            }
        }
    } catch {
        [PSCustomObject]@{ Group=$group; Member="ERROR: $($_.Exception.Message)"; Type=""; Enabled=""; LastLogon=""; PasswordLastSet=""; PwdNeverExpires="" }
    }
}

Write-Host "=== TIER 0 GROUP MEMBERSHIP ===" -ForegroundColor Cyan
Write-Host "Total Tier 0 group memberships: $($tier0Findings.Count)"
$tier0Findings | Format-Table -AutoSize

# ── Flag risky conditions ─────────────────────────────────────────────────
Write-Host "`n=== RISK FLAGS ===" -ForegroundColor Yellow

# Stale accounts with Tier 0 access (no logon in 90 days)
$stale = $tier0Findings | Where-Object {
    $_.LastLogon -ne "Never/Unknown" -and $_.LastLogon -lt (Get-Date).AddDays(-90).ToString("yyyy-MM-dd") -and $_.Type -eq "user"
}
if ($stale) {
    Write-Host "STALE TIER 0 ACCOUNTS (>90 days no logon):" -ForegroundColor Red
    $stale | Format-Table Group, Member, LastLogon -AutoSize
}

# Disabled accounts still in Tier 0 groups
$disabled = $tier0Findings | Where-Object { $_.Enabled -eq $false }
if ($disabled) {
    Write-Host "DISABLED ACCOUNTS IN TIER 0 GROUPS:" -ForegroundColor Red
    $disabled | Format-Table Group, Member, Enabled -AutoSize
}

# Accounts with password never expires (Tier 0 should rotate)
$noExpiry = $tier0Findings | Where-Object { $_.PwdNeverExpires -eq $true -and $_.Type -eq "user" }
if ($noExpiry) {
    Write-Host "TIER 0 ACCOUNTS WITH PASSWORD NEVER EXPIRES:" -ForegroundColor Yellow
    $noExpiry | Format-Table Group, Member, PasswordLastSet -AutoSize
}
```

---

## Phase 2 — Shadow Admin Detection

Shadow admins have admin-level delegated rights in AD but are not members of admin groups. These are extremely dangerous and commonly overlooked.

```powershell
$domainDN = (Get-ADDomain).DistinguishedName

# ── Find accounts with AdminSDHolder write access ─────────────────────────
# AdminSDHolder protects privileged accounts — write access = can control Tier 0
$adminSDHolder = "CN=AdminSDHolder,CN=System,$domainDN"
$acl = Get-Acl "AD:\$adminSDHolder"
$acl.Access | Where-Object {
    $_.AccessControlType -eq "Allow" -and
    $_.ActiveDirectoryRights -match "WriteProperty|GenericWrite|GenericAll|WriteDacl|WriteOwner" -and
    $_.IdentityReference -notmatch "Domain Admins|Enterprise Admins|SYSTEM|Administrators"
} | Format-Table IdentityReference, ActiveDirectoryRights, ObjectType -AutoSize

# ── Find accounts with DCSync rights (most dangerous shadow admin path) ───
# DCSync: Replicating Directory Changes + Replicating Directory Changes All on domain root
$domainACL = Get-Acl "AD:\$domainDN"
$dcsyncRights = $domainACL.Access | Where-Object {
    $_.ObjectType -in @(
        [GUID]"1131f6aa-9c07-11d1-f79f-00c04fc2dcd2",  # Replicating Directory Changes
        [GUID]"1131f6ad-9c07-11d1-f79f-00c04fc2dcd2",  # Replicating Directory Changes All
        [GUID]"89e95b76-444d-4c62-991a-0facbeda640c"   # Replicating Directory Changes In Filtered Set
    ) -and
    $_.AccessControlType -eq "Allow" -and
    $_.IdentityReference -notmatch "Domain Controllers|Enterprise Domain Controllers|SYSTEM|Administrators|Domain Admins|Enterprise Admins"
}

if ($dcsyncRights) {
    Write-Host "⚠️ ACCOUNTS WITH DCSYNC RIGHTS (Shadow Admin):" -ForegroundColor Red
    $dcsyncRights | Format-Table IdentityReference, ActiveDirectoryRights -AutoSize
} else {
    Write-Host "OK: No unexpected DCSync rights found" -ForegroundColor Green
}

# ── Find accounts with GenericAll/WriteDacl on Tier 0 groups ─────────────
foreach ($group in @("Domain Admins", "Enterprise Admins")) {
    $grpDN = (Get-ADGroup $group).DistinguishedName
    $grpACL = Get-Acl "AD:\$grpDN"
    $dangerousRights = $grpACL.Access | Where-Object {
        $_.ActiveDirectoryRights -match "GenericAll|WriteDacl|WriteOwner|WriteProperty" -and
        $_.AccessControlType -eq "Allow" -and
        $_.IdentityReference -notmatch "Domain Admins|SYSTEM|Administrators|Enterprise Admins"
    }
    if ($dangerousRights) {
        Write-Host "⚠️ SHADOW ADMIN RIGHTS ON $group`:" -ForegroundColor Red
        $dangerousRights | Format-Table IdentityReference, ActiveDirectoryRights -AutoSize
    }
}
```

---

## Phase 3 — Tier 0 Account Quality Checks

```powershell
# ── Check if Tier 0 accounts are dedicated admin accounts ─────────────────
# Best practice: admin accounts should be separate from daily-use accounts
# Warning signs: admin UPNs that look like normal user accounts, no "adm-" prefix

Get-ADGroupMember "Domain Admins" -Recursive | Where-Object { $_.objectClass -eq "user" } |
    ForEach-Object {
        $user = Get-ADUser $_.DistinguishedName -Properties *
        [PSCustomObject]@{
            Account          = $user.SamAccountName
            DisplayName      = $user.DisplayName
            UPN              = $user.UserPrincipalName
            LooksLikeAdmin   = $user.SamAccountName -match "^(adm|adm-|admin|admin-|svc)" ? "YES" : "REVIEW — no admin prefix"
            HasMailbox       = [bool]$user.Mail
            HasMFA           = "Check Entra"   # Must verify in portal
            LastLogon        = $user.LastLogonDate
            PasswordAge      = if ($user.PasswordLastSet) { [math]::Round(((Get-Date) - $user.PasswordLastSet).TotalDays) } else { "Never set" }
        }
    } | Format-Table -AutoSize

# ── Check KRBTGT account health ───────────────────────────────────────────
$krbtgt = Get-ADUser krbtgt -Properties PasswordLastSet, LastLogonDate, BadPwdCount
[PSCustomObject]@{
    Account        = $krbtgt.SamAccountName
    PasswordLastSet = $krbtgt.PasswordLastSet.ToString("yyyy-MM-dd")
    PasswordAgeDays = [math]::Round(((Get-Date) - $krbtgt.PasswordLastSet).TotalDays)
    Recommendation = if (((Get-Date) - $krbtgt.PasswordLastSet).TotalDays -gt 180) {
        "⚠️ OVERDUE — rotate KRBTGT (see Runbook 04)"
    } else { "OK" }
} | Format-List

# ── Check for admin accounts with SPN set (Kerberoastable Tier 0) ─────────
Get-ADGroupMember "Domain Admins" -Recursive | Where-Object { $_.objectClass -eq "user" } |
    ForEach-Object {
        $user = Get-ADUser $_.DistinguishedName -Properties ServicePrincipalName
        if ($user.ServicePrincipalName) {
            Write-Host "⚠️ KERBEROASTABLE TIER 0 ACCOUNT: $($user.SamAccountName) — SPNs: $($user.ServicePrincipalName -join ', ')" -ForegroundColor Red
        }
    }
```

---

## Phase 4 — Entra ID Privileged Role Audit

```powershell
Connect-MgGraph -Scopes "Directory.Read.All", "RoleManagement.Read.Directory"

# ── List all Entra privileged roles and their members ─────────────────────
$criticalRoles = @(
    "Global Administrator",
    "Privileged Role Administrator",
    "Security Administrator",
    "Conditional Access Administrator",
    "Authentication Policy Administrator",
    "Privileged Authentication Administrator",
    "User Administrator",
    "Exchange Administrator",
    "SharePoint Administrator",
    "Intune Administrator",
    "Azure AD Joined Device Local Administrator"
)

$roleFindings = foreach ($roleName in $criticalRoles) {
    $role = Get-MgDirectoryRole -Filter "displayName eq '$roleName'" -ErrorAction SilentlyContinue
    if ($role) {
        $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
        foreach ($member in $members) {
            $user = Get-MgUser -UserId $member.Id -Property DisplayName, UserPrincipalName, AccountEnabled, UserType -ErrorAction SilentlyContinue
            if ($user) {
                [PSCustomObject]@{
                    Role        = $roleName
                    User        = $user.DisplayName
                    UPN         = $user.UserPrincipalName
                    Enabled     = $user.AccountEnabled
                    UserType    = $user.UserType  # Member vs Guest
                }
            }
        }
    }
}

Write-Host "=== ENTRA PRIVILEGED ROLE MEMBERS ===" -ForegroundColor Cyan
$roleFindings | Format-Table -AutoSize

# ── Flag guest accounts in privileged roles ───────────────────────────────
$guestAdmins = $roleFindings | Where-Object { $_.UserType -eq "Guest" }
if ($guestAdmins) {
    Write-Host "⚠️ GUEST ACCOUNTS WITH PRIVILEGED ROLES:" -ForegroundColor Red
    $guestAdmins | Format-Table Role, UPN, UserType -AutoSize
}

# ── Check Global Admin count ──────────────────────────────────────────────
$gaCount = ($roleFindings | Where-Object { $_.Role -eq "Global Administrator" }).Count
Write-Host "Global Administrator count: $gaCount $(if ($gaCount -gt 5) { '⚠️ TOO MANY — recommend max 5' } else { '✅' })"
```

---

## Phase 5 — PIM (Privileged Identity Management) Status

```powershell
# ── Check if PIM is being used for Entra roles ───────────────────────────
# Requires Azure AD P2 license

# List eligible (PIM) vs permanent assignments:
Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All |
    ForEach-Object {
        $principal = Get-MgDirectoryObject -DirectoryObjectId $_.PrincipalId -ErrorAction SilentlyContinue
        $role = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $_.RoleDefinitionId -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Role      = $role.DisplayName
            Principal = $principal.AdditionalProperties.userPrincipalName ?? $principal.AdditionalProperties.displayName
            Type      = "Eligible (PIM)"
            StartDate = $_.ScheduleInfo.StartDateTime
            EndDate   = $_.ScheduleInfo.Expiration.EndDateTime
        }
    } | Format-Table -AutoSize

# ── Identify permanent (non-PIM) assignments that should be PIM ──────────
Get-MgRoleManagementDirectoryRoleAssignmentSchedule -All |
    Where-Object { $_.AssignmentType -eq "Assigned" } |  # Permanent assignments
    ForEach-Object {
        $principal = Get-MgDirectoryObject -DirectoryObjectId $_.PrincipalId -ErrorAction SilentlyContinue
        $role = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $_.RoleDefinitionId -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Role      = $role.DisplayName
            Principal = $principal.AdditionalProperties.userPrincipalName
            Type      = "Permanent ⚠️"
        }
    } | Format-Table -AutoSize
```

---

## Phase 6 — Tier Boundary Violations

```powershell
# ── Find Tier 0 accounts logged into non-Tier 0 machines ─────────────────
# Check Tier 0 accounts' recent logon workstations (security event 4624)
# This is hard to query at scale — use MDI or Sentinel for this
# Quick check: see if any admin account has recently logged into a workstation

$tier0Users = Get-ADGroupMember "Domain Admins" -Recursive | Where-Object { $_.objectClass -eq "user" }
foreach ($adminUser in $tier0Users) {
    $user = Get-ADUser $adminUser -Properties LastLogonDate, LogonWorkstations
    if ($user.LogonWorkstations) {
        Write-Host "$($user.SamAccountName) restricted to workstations: $($user.LogonWorkstations)" -ForegroundColor Yellow
    }
}

# ── Check if Tier 0 admin accounts are restricted to PAWs ────────────────
# Best practice: Tier 0 admin accounts should have "Log On To" restrictions
# pointing only to PAW (Privileged Access Workstation) machine names
# If LogonWorkstations is empty: account can log in from ANY machine

$unrestricted = $tier0Users | ForEach-Object {
    $user = Get-ADUser $_ -Properties LogonWorkstations
    if (-not $user.LogonWorkstations) {
        [PSCustomObject]@{
            Account = $user.SamAccountName
            Risk    = "No workstation restriction — can log in from any machine"
        }
    }
}
if ($unrestricted) {
    Write-Host "⚠️ TIER 0 ACCOUNTS WITHOUT WORKSTATION RESTRICTIONS:" -ForegroundColor Red
    $unrestricted | Format-Table -AutoSize
}
```

---

## Audit Summary Output

```powershell
# ── Generate risk summary ────────────────────────────────────────────────
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  PRIVILEGED IDENTITY TIER AUDIT SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Domain: $((Get-ADDomain).DNSRoot)"
Write-Host "Audit date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host ""
Write-Host "RISK ITEMS TO ACTION:"
Write-Host "  Run phases 1-6 above and collect findings into:"
Write-Host "  1. [CRITICAL] Shadow admins with DCSync or GenericAll rights"
Write-Host "  2. [HIGH]     Stale/disabled accounts in Tier 0 groups"
Write-Host "  3. [HIGH]     Admin accounts with SPNs (Kerberoastable)"
Write-Host "  4. [HIGH]     Tier 0 accounts without workstation restrictions"
Write-Host "  5. [MEDIUM]   Admin account naming not following convention"
Write-Host "  6. [MEDIUM]   Password never expires on Tier 0 accounts"
Write-Host "  7. [MEDIUM]   KRBTGT password age > 180 days"
Write-Host "  8. [MEDIUM]   Guest accounts with privileged Entra roles"
Write-Host "  9. [LOW]      Tier 0 members with mailboxes on same account"
Write-Host " 10. [LOW]      Permanent Entra role assignments that should use PIM"
```

---

## Documentation

Record findings in a Security Finding Jira card (use `12_JIRA_TEMPLATES/SECURITY-FINDING-template.md`):
- Domain audited: `[NAME]`
- Tier 0 member count: `[N users]`
- Shadow admins found: `[COUNT]`
- Stale Tier 0 accounts: `[COUNT]`
- Kerberoastable admin accounts: `[COUNT]`
- Entra Global Admin count: `[N]`
- PIM deployed: `[Yes / Partial / No]`
- Critical findings: `[LIST]`
- Recommended actions: `[LIST with owners and due dates]`
