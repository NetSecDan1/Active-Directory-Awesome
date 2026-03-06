# Runbook: Conditional Access Policy Troubleshooting
**Risk**: READ-ONLY (investigation) / HIGH (policy changes) | **Estimated Time**: 30-90 minutes
**Requires**: Security Administrator or Conditional Access Administrator in Entra ID | **Change Type**: Normal — CAB approval required for policy changes
**Version**: 1.0 | **Owner**: Identity Security / AD Engineering

---

## Phase 0 — Information Gathering

**Before proceeding, I need the following:**

- [ ] **Symptom**: Sign-in blocked? MFA loop? Device compliance failure? Named location mismatch? App-specific block?
- [ ] **Affected user(s)**: Specific user UPN(s) or all users?
- [ ] **Affected application**: Which app or resource is blocking access?
- [ ] **Client**: Browser? Desktop app? Mobile app? Legacy auth?
- [ ] **Error code**: Exact text from the sign-in screen (e.g., AADSTS50076, AADSTS53003, error code number)
- [ ] **Sign-in log available?**: Can you pull the specific sign-in log entry from Entra? (Correlation ID)
- [ ] **Recent changes**: New CA policy created? Policy modified? User/device moved to different group? License change?
- [ ] **Expected behavior**: What SHOULD happen for this user/app/device combination?

Do not proceed until these are answered.

---

## Overview

Conditional Access (CA) problems fall into four categories:
1. **Policy logic** — Wrong grants, wrong conditions, policy applies when it shouldn't
2. **Signal failures** — MFA not satisfied, device compliance unknown, location mismatch
3. **Break-glass and exclusions** — Emergency accounts blocked, admin exclusions missing
4. **Legacy authentication** — Old protocols blocked or bypassed unintentionally

**Golden rule**: Never modify a CA policy in production without a rollback plan and a staged rollout. One wrong policy can lock out all users or all admins.

---

## Decision Tree

```
START: Conditional Access / sign-in issue
    │
    ├─ Complete sign-in block (AADSTS53003 / error 53003)? ──────► Phase 1: Policy Identification
    │
    ├─ MFA prompt loop / MFA never satisfying? ──────────────────► Phase 2: MFA Signal Issues
    │
    ├─ Device compliance failure blocking access? ────────────────► Phase 3: Device Compliance
    │
    ├─ Named location / IP mismatch? ────────────────────────────► Phase 4: Named Locations
    │
    ├─ Break-glass / admin account blocked? ─────────────────────► Phase 5: Exclusions Audit
    │
    ├─ Legacy auth still flowing when it should be blocked? ─────► Phase 6: Legacy Auth Audit
    │
    └─ "What-If" test needed before policy deployment? ──────────► Phase 7: What-If Analysis
```

---

## Phase 1 — Policy Identification (What's Blocking?)

The Entra sign-in logs tell you exactly which policy blocked access.

```powershell
# ── Pull sign-in logs for affected user ───────────────────────────────────
# Requires: Microsoft Graph PowerShell or AzureAD module + Sign-in log read permissions

Connect-MgGraph -Scopes "AuditLog.Read.All", "Directory.Read.All"

$userUPN = "jdoe@contoso.com"   # Replace with affected user UPN

# Get last 50 sign-in events for this user
$signIns = Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$userUPN'" -Top 50 |
    Select-Object CreatedDateTime, AppDisplayName, Status,
        @{N='ErrorCode';   E={ $_.Status.ErrorCode }},
        @{N='FailureReason'; E={ $_.Status.FailureReason }},
        @{N='AdditionalDetails'; E={ $_.Status.AdditionalDetails }},
        @{N='CorrelationId'; E={ $_.CorrelationId }},
        ConditionalAccessStatus

$signIns | Format-Table -AutoSize

# ── Get the specific CA policies that applied to a sign-in ────────────────
# Find the Correlation ID from the blocked sign-in above, then:
$correlationId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"   # Replace

$signIn = Get-MgAuditLogSignIn -Filter "correlationId eq '$correlationId'" | Select-Object -First 1
$signIn.ConditionalAccessPolicies | ForEach-Object {
    [PSCustomObject]@{
        PolicyName     = $_.DisplayName
        PolicyId       = $_.Id
        Result         = $_.Result          # success, failure, notApplied, notEnabled
        GrantControls  = $_.GrantControlsResult -join ", "
        SessionControls = $_.SessionControlsResult -join ", "
    }
} | Format-Table -AutoSize

# Result meanings:
# "failure"    = this policy BLOCKED the sign-in
# "success"    = this policy's conditions were met and controls satisfied
# "notApplied" = conditions not met (user/app/device not in scope)
# "notEnabled" = policy is in report-only mode
```

---

## Phase 2 — MFA Signal Issues

```powershell
# ── Check user's MFA registration status ─────────────────────────────────
$userUPN = "jdoe@contoso.com"

# Via Graph:
$authMethods = Get-MgUserAuthenticationMethod -UserId $userUPN
$authMethods | ForEach-Object {
    [PSCustomObject]@{
        Method = $_.ODataType -replace "#microsoft.graph.", ""
        Id     = $_.Id
    }
} | Format-Table -AutoSize

# Check if user has any registered authentication methods:
$strongMethods = $authMethods | Where-Object {
    $_.ODataType -notlike "*passwordAuthentication*"
}
if ($strongMethods.Count -eq 0) {
    Write-Host "NO MFA methods registered — user cannot satisfy MFA requirement" -ForegroundColor Red
} else {
    Write-Host "$($strongMethods.Count) MFA method(s) registered" -ForegroundColor Green
}

# ── Check if Authenticator app is registered ──────────────────────────────
$authMethods | Where-Object { $_.ODataType -like "*microsoftAuthenticator*" } |
    Select-Object Id, @{N='DeviceName'; E={ $_.DisplayName }},
        @{N='DeviceType'; E={ $_.PhoneAppVersion }} | Format-Table -AutoSize

# ── Check if user is excluded from MFA registration campaign ─────────────
# Entra portal: Security → Authentication methods → Registration campaign
# Verify the user isn't excluded

# ── Check Authentication Strengths (if using them) ────────────────────────
Get-MgPolicyAuthenticationStrengthPolicy | Select-Object DisplayName, AllowedCombinations |
    Format-Table -AutoSize
```

---

## Phase 3 — Device Compliance Failures

```powershell
$userUPN  = "jdoe@contoso.com"
$deviceName = "LAPTOP-001"   # Replace with affected device name

# ── Check device compliance state in Entra ────────────────────────────────
$device = Get-MgDevice -Filter "displayName eq '$deviceName'" |
    Select-Object DisplayName, IsCompliant, IsManaged, TrustType,
        OperatingSystem, OperatingSystemVersion,
        @{N='RegistrationDateTime'; E={ $_.RegistrationDateTime }}
$device | Format-List

# Compliance states:
# IsCompliant = True → Device passed Intune compliance policy
# IsCompliant = False → Device failed compliance (check Intune)
# IsCompliant = null → Device not evaluated (not enrolled in Intune)
# IsManaged = False → Device not MDM-enrolled — CA "require compliant device" will fail

# ── Check device trust type ───────────────────────────────────────────────
# TrustType meanings:
# Workplace  = Entra Registered (personal device)
# AzureAd    = Entra Joined (cloud-only join)
# ServerAd   = Hybrid Entra Joined (domain-joined + Entra)
# If CA requires "Hybrid Entra Joined" and device is "Workplace" → blocked

# ── Check Hybrid Entra Join status on device ──────────────────────────────
# Run on the device itself:
# dsregcmd /status
# Look for:
#   AzureAdJoined: YES
#   DomainJoined: YES
#   DeviceAuthStatus: SUCCESS
# If NOT both YES → hybrid join is broken → device can't satisfy "Hybrid joined" CA condition

# ── Check Intune compliance for this device ───────────────────────────────
# Intune portal: Devices → All devices → [device name] → Device compliance
# Intune shows exactly which compliance rule is failing
```

---

## Phase 4 — Named Location / IP Issues

```powershell
# ── List all configured named locations ───────────────────────────────────
Get-MgIdentityConditionalAccessNamedLocation | ForEach-Object {
    [PSCustomObject]@{
        Name   = $_.DisplayName
        Type   = $_.ODataType -replace "#microsoft.graph.", ""
        IsTrusted = if ($_.AdditionalProperties.isTrusted) { $_.AdditionalProperties.isTrusted } else { "N/A" }
        Ranges = if ($_.AdditionalProperties.ipRanges) {
            ($_.AdditionalProperties.ipRanges | ForEach-Object { $_.cidrAddress }) -join ", "
        } else { "Country-based" }
    }
} | Format-Table -AutoSize

# ── Check what IP the user is signing in from ─────────────────────────────
# In sign-in logs (from Phase 1 output):
$signIn = Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$userUPN'" -Top 5
$signIn | Select-Object CreatedDateTime,
    @{N='IPAddress'; E={ $_.IPAddress }},
    @{N='Location'; E={ "$($_.Location.City), $($_.Location.CountryOrRegion)" }},
    @{N='NamedLocation'; E={ $_.NetworkLocationDetails.NetworkType }} | Format-Table -AutoSize

# ── Verify the signing-in IP is in the expected named location ────────────
# Compare the user's IP from the sign-in log against the IP ranges in the named location
# If the user is VPN'd: the exit node IP is what Entra sees — not the local corporate IP

# ── Check if "Compliant Network" (Global Secure Access) is in use ─────────
# If "Require compliant network" control is in the policy, only GSA-connected devices pass
```

---

## Phase 5 — Break-Glass and Exclusion Audit

```powershell
# ── Audit all CA policies for break-glass account exclusions ─────────────
# CRITICAL: Break-glass accounts MUST be excluded from ALL CA policies
# If they are not — a buggy policy can lock you out of the tenant

$breakGlassAccounts = @("breakglass1@contoso.com", "breakglass2@contoso.com")  # Replace

Get-MgIdentityConditionalAccessPolicy | ForEach-Object {
    $policy = $_
    $excluded = $policy.Conditions.Users.ExcludeUsers

    $bgCovered = $breakGlassAccounts | ForEach-Object {
        $bg = $_
        $bgObj = Get-MgUser -Filter "userPrincipalName eq '$bg'" | Select-Object -ExpandProperty Id
        if ($excluded -contains $bgObj) { "EXCLUDED ✅" } else { "NOT EXCLUDED ⚠️" }
    }

    [PSCustomObject]@{
        PolicyName  = $policy.DisplayName
        State       = $policy.State
        BG1_Covered = $bgCovered[0]
        BG2_Covered = if ($bgCovered.Count -gt 1) { $bgCovered[1] } else { "N/A" }
    }
} | Format-Table -AutoSize

# ── Check if any admin roles are excluded from CA policies ────────────────
Get-MgIdentityConditionalAccessPolicy | ForEach-Object {
    [PSCustomObject]@{
        PolicyName     = $_.DisplayName
        ExcludedRoles  = $_.Conditions.Users.ExcludeRoles -join ", "
        ExcludedGroups = $_.Conditions.Users.ExcludeGroups -join ", "
        ExcludedUsers  = $_.Conditions.Users.ExcludeUsers | Measure-Object | Select-Object -ExpandProperty Count
    }
} | Where-Object { $_.ExcludedRoles -ne "" -or $_.ExcludedGroups -ne "" } | Format-Table -AutoSize
```

---

## Phase 6 — Legacy Authentication Audit

```powershell
# ── Find sign-ins using legacy auth in the last 7 days ────────────────────
$legacySignIns = Get-MgAuditLogSignIn -Filter "clientAppUsed ne 'Browser' and clientAppUsed ne 'Mobile Apps and Desktop Clients'" -Top 200 |
    Where-Object { $_.CreatedDateTime -gt (Get-Date).AddDays(-7) }

Write-Host "Legacy auth sign-ins in last 7 days: $($legacySignIns.Count)"
$legacySignIns | Group-Object ClientAppUsed | Sort-Object Count -Descending |
    Select-Object Name, Count | Format-Table -AutoSize

# Legacy auth clients to watch for:
# "Exchange ActiveSync" = mobile mail apps using Basic auth
# "SMTP" = automated emailers using Basic SMTP
# "POP3" / "IMAP4" = old mail clients
# "Authenticated SMTP" = scripts or apps using Basic SMTP auth

# ── Check if legacy auth block policy is in place and correct ─────────────
Get-MgIdentityConditionalAccessPolicy | Where-Object {
    $_.Conditions.ClientAppTypes -contains "exchangeActiveSync" -or
    $_.Conditions.ClientAppTypes -contains "other"
} | Select-Object DisplayName, State,
    @{N='ClientApps'; E={ $_.Conditions.ClientAppTypes -join ", " }},
    @{N='GrantControl'; E={ $_.GrantControls.BuiltInControls -join ", " }} |
    Format-Table -AutoSize

# An effective legacy auth block has:
# - ClientAppTypes: includes "exchangeActiveSync" AND "other"
# - GrantControls.BuiltInControls: "block"
# - State: "enabled"
```

---

## Phase 7 — What-If Analysis (Before Deploying a New Policy)

```powershell
# ── Use Entra What-If tool ────────────────────────────────────────────────
# Portal path: Entra ID → Security → Conditional Access → What If
# Inputs:
#   - User: [UPN to test]
#   - Cloud app: [App to test]
#   - IP address: [User's IP]
#   - Device platform: [Windows / iOS / etc.]
#   - Device state: [Compliant / Domain joined / etc.]
# Output: Which policies apply and what controls they require

# ── PowerShell: Simulate via Graph API (preview) ──────────────────────────
# Microsoft Graph has a beta endpoint for CA What-If evaluation
# This is read-only and safe to run anytime

$params = @{
    conditionalAccessWhatIfConditions = @{
        userPrincipalName = "jdoe@contoso.com"
        ipAddress         = "203.0.113.1"   # Replace with test IP
        cloudAppOrAction  = @{
            "@odata.type" = "#microsoft.graph.conditionalAccessCloudAppsAndActions"
            includeApplications = @("00000002-0000-0ff1-ce00-000000000000")  # Exchange Online
        }
        devicePlatform    = "windows"
        signInRiskLevel   = "none"
        userRiskLevel     = "none"
        servicePrincipalRiskLevel = "none"
        country           = "US"
    }
}
# Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/identity/conditionalAccess/evaluate" -Body ($params | ConvertTo-Json -Depth 5)
```

---

## Conditional Access Fix Summary

| Problem | Cause | Fix | Risk |
|---------|-------|-----|------|
| All users blocked | Policy too broad — no exclusions | Add break-glass to exclusion, then fix policy | HIGH |
| MFA loop | Authentication strength not satisfiable | Check registered methods match required strength | MEDIUM |
| Device compliance fail | Not enrolled in Intune | Enroll device; or add device as exception temporarily | MEDIUM |
| Location block for VPN users | VPN exit IP not in named location | Add VPN IP range to named location | LOW |
| Admin blocked | Admin role not excluded | Add admin role group to policy exclusion | HIGH |
| Legacy auth still working | Policy missing "other" client app type | Add "other" and "exchangeActiveSync" to policy | MEDIUM |
| Break-glass account blocked | Break-glass not excluded | Immediately exclude BG account from all policies | CRITICAL |

---

## ⚠️ Change Warning

Modifying CA policies requires:
1. **What-If analysis** before any change
2. **Report-only mode** before enabling (monitor 1-7 days)
3. **Staged rollout** — apply to a test group first
4. **Break-glass accounts** verified excluded before enabling
5. **CAB approval** for any policy affecting more than 50 users

**Never enable a CA policy in production without testing in report-only mode first.**

---

## Documentation

Record in Jira ticket:
- Affected user(s): `[UPN(s)]`
- Blocking policy: `[POLICY NAME]` / `[CORRELATION ID]`
- Symptom: `[CATEGORY]`
- Root cause: `[DESCRIPTION]`
- Fix applied: `[CHANGE — policy name, what changed]`
- Report-only period: `[HOW LONG]`
- Verification: `[Sign-in log shows success]`
