# Runbook: SPN and Kerberos Delegation Troubleshooting
**Risk**: READ-ONLY (investigation) / LOW-MEDIUM (fixes) | **Estimated Time**: 45-90 minutes
**Requires**: AD read access, Domain Admin for fixes | **Change Type**: Normal
**Version**: 1.0 | **Owner**: AD Engineering

---

## Overview

SPN and delegation issues cause some of the most confusing symptoms in AD environments:
- "Works on my machine but not from the server"
- "Only breaks when going through the load balancer"
- "SQL integrated auth fails from the web tier"
- "Works with Domain Admin credentials, not service account"

These are classic Kerberos double-hop and SPN problems. This runbook gives you a systematic path from symptom to fix.

---

## Quick Concept Review

**SPN (Service Principal Name)**: The identity a service advertises to Kerberos. Clients look up the SPN to get a service ticket. If the SPN is wrong, missing, or duplicated — Kerberos fails and usually falls back to NTLM (which then fails for double-hop scenarios).

**Delegation types** (in order of risk):
| Type | How It Works | Risk |
|------|-------------|------|
| **Unconstrained** | Service can impersonate user to ANY service | HIGH — avoid |
| **Constrained (KCD)** | Service can impersonate user to SPECIFIC services | MEDIUM — recommended |
| **Resource-Based KCD (RBKCD)** | Target resource controls who can delegate to it | LOW — modern preferred |
| **Protocol Transition** | Service can impersonate without user's TGT (S4U2Self) | MEDIUM |

---

## Decision Tree

```
START: Kerberos/delegation failure
    │
    ├─ Error: "Target principal name is incorrect"? ──────────────────► Phase 2: SPN Lookup
    │
    ├─ NTLM fallback observed (klist shows no service ticket)? ───────► Phase 2: SPN Lookup
    │
    ├─ SPN exists but auth fails? ────────────────────────────────────► Phase 3: Duplicate SPN
    │
    ├─ Three-tier app: web tier succeeds, DB tier fails? ─────────────► Phase 4: Double-Hop (KCD)
    │
    ├─ Works from some client IPs but not others? ────────────────────► Phase 5: Load Balancer SPN
    │
    ├─ Resource-based delegation scenario? ───────────────────────────► Phase 6: RBKCD
    │
    └─ Service runs as LocalSystem / managed service account? ────────► Phase 7: Computer Account SPN
```

---

## Phase 0 — Gather Information

- [ ] **Failing service**: Which application, which server?
- [ ] **Service account**: Domain account, LocalSystem, gMSA, or managed account?
- [ ] **Tier**: Two-tier (client→server) or three-tier (client→web→database)?
- [ ] **Error**: "Target principal name is incorrect" / KRB error code / generic 401?
- [ ] **Network**: Direct, load-balanced VIP, or reverse proxy (SSL offload)?
- [ ] **NTLM**: Is NTLM blocked in the environment? Required to use Kerberos only?

---

## Phase 1 — Determine What Authentication Protocol Is Being Used

```powershell
# ── Check current tickets on client ───────────────────────────────────────
klist
# If you see a service ticket for the target: Kerberos is being used
# If you don't: NTLM fallback likely happening

# ── Verify auth protocol on IIS (if web app) ──────────────────────────────
# IIS → Site → Authentication → look for "Windows Authentication" with "Providers"
# Providers order matters: Negotiate first (tries Kerberos), NTLM second (fallback)
# If only NTLM in providers: Kerberos will never be attempted

# ── Check auth type in event logs on the server ────────────────────────────
$targetServer = "appserver.domain.com"
Get-WinEvent -ComputerName $targetServer -FilterHashtable @{
    LogName   = 'Security'
    Id        = 4624   # Successful logon
    StartTime = (Get-Date).AddMinutes(-30)
} -ErrorAction SilentlyContinue | ForEach-Object {
    [PSCustomObject]@{
        Time      = $_.TimeCreated
        User      = "$($_.Properties[6].Value)\$($_.Properties[5].Value)"
        LogonType = $_.Properties[8].Value
        AuthPkg   = $_.Properties[14].Value   # "Kerberos" or "NTLM"
        ClientIP  = $_.Properties[18].Value
    }
} | Format-Table -AutoSize

# ── Test Kerberos with a specific target SPN ──────────────────────────────
klist get HTTP/appserver.domain.com
# If this succeeds: SPN exists and Kerberos works
# If error 0x7 (KDC_ERR_S_PRINCIPAL_UNKNOWN): SPN not registered
```

---

## Phase 2 — SPN Lookup and Registration Audit

```powershell
# ── Find the SPN for a specific server ────────────────────────────────────
$serverFQDN = "appserver.domain.com"
$serverShort = "appserver"

# Search by hostname
Get-ADObject -Filter { ServicePrincipalName -like "*$serverShort*" } `
    -Properties ServicePrincipalName | Format-Table Name, ServicePrincipalName

# Common SPN patterns to look for:
$spnsToCheck = @(
    "HTTP/$serverFQDN",
    "HTTP/$serverShort",
    "HOST/$serverFQDN",
    "HOST/$serverShort",
    "MSSQLSvc/$serverFQDN",
    "MSSQLSvc/${serverFQDN}:1433"
)

foreach ($spn in $spnsToCheck) {
    $found = Get-ADObject -Filter { ServicePrincipalName -eq $spn } -Properties ServicePrincipalName
    if ($found) {
        Write-Host "FOUND: $spn → $($found.Name)" -ForegroundColor Green
    } else {
        Write-Host "MISSING: $spn" -ForegroundColor Red
    }
}

# ── Using setspn for confirmation ─────────────────────────────────────────
setspn -Q "HTTP/$serverFQDN"
# "Checking domain DC=domain,DC=com"
# "Existing SPN found!" → registered
# "No such SPN found" → not registered

# ── List ALL SPNs for a service account ───────────────────────────────────
$serviceAccount = "svc-webapp"
setspn -L $serviceAccount
# Shows every SPN currently registered

# ── Register a missing SPN (WRITE — LOW RISK) ─────────────────────────────
# Verify NO duplicate exists first (run setspn -X below)
# setspn -S "HTTP/appserver.domain.com" "domain\svc-webapp"
# setspn -S "HTTP/appserver" "domain\svc-webapp"
# Both FQDN and short name usually required for full compatibility
```

---

## Phase 3 — Duplicate SPN Detection and Resolution

A duplicate SPN is **critical** — Kerberos cannot choose which account's key to use and fails with 0x32 (KDC_ERR_BADMATCH) or silently falls back to NTLM.

```powershell
# ── Find ALL duplicate SPNs in the entire forest ──────────────────────────
# This is the most important SPN audit you can run
setspn -X -F
# Output shows every SPN registered on more than one account
# Every line is a problem to resolve

# ── Targeted duplicate check for a specific SPN ───────────────────────────
$spn = "HTTP/appserver.domain.com"
Get-ADObject -Filter { ServicePrincipalName -eq $spn } -Properties ServicePrincipalName |
    Select-Object Name, DistinguishedName, @{N='SPN';E={ $spn }} | Format-Table -AutoSize

# If two objects returned: you have a duplicate — fix it

# ── Remove SPN from wrong account (WRITE — MEDIUM RISK) ──────────────────
# Step 1: Confirm which account SHOULD own the SPN
# Step 2: Remove from the wrong account
# setspn -D "HTTP/appserver.domain.com" "domain\wrongaccount"
# Step 3: Verify it's still on the correct account
# setspn -L "domain\correctaccount"

# ── Common duplicate SPN causes ────────────────────────────────────────────
# - Service account renamed: old name still has SPN
# - Server moved to different OU but old computer account still exists
# - Service was reconfigured to use different account — old account still has SPN
# - Manual SPN added on computer account when a service account also has it
```

---

## Phase 4 — Double-Hop (Kerberos Constrained Delegation)

The classic three-tier problem: User → Web Server → Database. Web server needs to forward user's credentials to DB.

```powershell
$webServiceAccount = "svc-webapp"   # Account that runs the web tier
$dbServer          = "sqlserver.domain.com"
$dbSPN             = "MSSQLSvc/$dbServer:1433"

# ── Check current delegation setting on web service account ───────────────
Get-ADUser $webServiceAccount -Properties TrustedForDelegation,
    TrustedToAuthForDelegation, msDS-AllowedToDelegateTo |
    Select-Object SamAccountName,
    @{N='DelegationType'; E={
        if ($_.TrustedForDelegation)          { "Unconstrained (HIGH RISK)" }
        elseif ($_.TrustedToAuthForDelegation) { "Protocol Transition (S4U2Self)" }
        elseif ($_.'msDS-AllowedToDelegateTo') { "Constrained KCD" }
        else                                  { "None" }
    }},
    @{N='AllowedTo'; E={ $_.'msDS-AllowedToDelegateTo' -join "`n" }} | Format-List

# ── Verify the DB SPN is in the "allowed to delegate to" list ─────────────
$delegList = (Get-ADUser $webServiceAccount -Properties 'msDS-AllowedToDelegateTo').'msDS-AllowedToDelegateTo'

if ($delegList -contains $dbSPN) {
    Write-Host "OK: $dbSPN is in delegation list" -ForegroundColor Green
} else {
    Write-Host "MISSING: $dbSPN is NOT in delegation list" -ForegroundColor Red
    Write-Host "Current delegation list: $($delegList -join ', ')"
}

# ── Verify the DB SPN actually exists ─────────────────────────────────────
setspn -Q $dbSPN
# Must exist — KCD delegation requires a valid SPN on the target

# ── Configure KCD (WRITE — MEDIUM RISK) ───────────────────────────────────
# Set-ADUser $webServiceAccount -Add @{'msDS-AllowedToDelegateTo' = @($dbSPN, "MSSQLSvc/$dbServer")}
# Set-ADAccountControl $webServiceAccount -TrustedToAuthForDelegation $false  # Do NOT enable protocol transition unless needed

# ── Validate KCD config post-change ───────────────────────────────────────
Get-ADUser $webServiceAccount -Properties 'msDS-AllowedToDelegateTo' |
    Select-Object -ExpandProperty 'msDS-AllowedToDelegateTo' | Format-List
```

---

## Phase 5 — Load Balancer / VIP SPN Issues

When a VIP (Virtual IP) or F5/NetScaler is in front of servers, the SPN must be on the service account — not the computer account — and must include the VIP hostname.

```powershell
$vipFQDN = "app.domain.com"     # The VIP DNS name users hit
$vipShort = "app"
$serviceAccount = "svc-webapp"

# ── Check if the VIP SPN is registered ────────────────────────────────────
$vipSPNs = @(
    "HTTP/$vipFQDN",
    "HTTP/$vipShort"
)

foreach ($spn in $vipSPNs) {
    $found = Get-ADObject -Filter { ServicePrincipalName -eq $spn } -Properties ServicePrincipalName
    if ($found) {
        Write-Host "FOUND: $spn → $($found.Name)" -ForegroundColor Green
    } else {
        Write-Host "MISSING: $spn" -ForegroundColor Red
    }
}

# ── Common LB SPN mistakes ─────────────────────────────────────────────────
# WRONG: SPN on individual backend server computer accounts
# WRONG: SPN on multiple accounts (duplicates)
# RIGHT: SPN on the service account that the app pool/service runs as
#         SPN for BOTH the VIP name AND individual server names (if direct access also works)

# ── IIS application pool — does it run as the right account? ─────────────
# Import-Module WebAdministration
# Get-WebConfiguration system.applicationHost/applicationPools/add |
#     Where-Object { $_.name -eq "AppPoolName" } |
#     Select-Object name, processModel | Format-List
# The identity must match the account that has the SPN registered

# ── Register VIP SPN on service account (WRITE — LOW RISK) ──────────────
# setspn -S "HTTP/app.domain.com" "domain\svc-webapp"
# setspn -S "HTTP/app" "domain\svc-webapp"
```

---

## Phase 6 — Resource-Based Kerberos Constrained Delegation (RBKCD)

Modern approach (Windows 2012+): the TARGET resource controls who can delegate to it. No Domain Admin needed — the resource owner can configure it.

```powershell
$frontendService = "svc-webapp"   # Account that needs to delegate
$backendServer   = "sqlserver"    # Target resource server

# ── Check if RBKCD is configured on the backend ───────────────────────────
Get-ADComputer $backendServer -Properties PrincipalsAllowedToDelegateToAccount |
    Select-Object Name, PrincipalsAllowedToDelegateToAccount | Format-List

# ── Configure RBKCD (WRITE — MEDIUM RISK — done on target, not source) ────
# Grant svc-webapp permission to delegate to sqlserver
# Set-ADComputer $backendServer -PrincipalsAllowedToDelegateToAccount `
#     @((Get-ADUser $frontendService), (Get-ADComputer "webserver01"))

# ── Important: RBKCD vs Classic KCD ───────────────────────────────────────
# Classic KCD: Configured on the SERVICE ACCOUNT (requires Domain Admin, AD attribute write)
# RBKCD:       Configured on the TARGET COMPUTER (can be done by resource owner)
#              Requires Windows 2012+ DFL
#              Does NOT require protocol transition setting (uses S4U2Self implicitly)
#              Works cross-domain within same forest

# ── Verify RBKCD is working ───────────────────────────────────────────────
# After configuring, purge tickets and test:
# klist purge
# Test the three-tier application access
# Check klist again — should see service ticket for backend server
```

---

## Phase 7 — Computer Account SPNs (LocalSystem / gMSA / NETWORK SERVICE)

Services running as LocalSystem or NETWORK SERVICE use the **computer account's** Kerberos identity. The SPN must be on the computer account.

```powershell
$serverName = "appserver"

# ── View current SPNs on a computer account ───────────────────────────────
setspn -L $serverName
# HOST/appserver.domain.com and HOST/appserver are auto-registered
# Additional service SPNs (HTTP, MSSQLSvc, etc.) need manual registration OR
# the service registers them automatically when it starts

# ── Auto-registered SPNs (host-based services) ────────────────────────────
# Windows auto-registers: HOST/<FQDN> and HOST/<NetBIOS>
# If these are missing, run on the computer:
# setspn -R APPSERVER   # Re-registers default computer SPNs

# ── gMSA (Group Managed Service Account) SPN ─────────────────────────────
$gmsaName = "svc-webapp$"   # gMSA names end in $
Get-ADServiceAccount $gmsaName -Properties ServicePrincipalName |
    Select-Object Name, ServicePrincipalName | Format-List

# SPNs on gMSA must be managed manually (not auto-registered by Kerberos)
# setspn -S "HTTP/appserver.domain.com" "domain\svc-webapp$"

# ── Verify the gMSA can be retrieved by the server ────────────────────────
# Run on the server hosting the gMSA service:
Test-ADServiceAccount $gmsaName
# Returns True if server can retrieve the gMSA password
```

---

## SPN / Delegation Fix Summary

| Symptom | Likely Cause | Fix | Risk |
|---------|-------------|-----|------|
| "Target principal name is incorrect" | SPN not registered | `setspn -S <spn> <account>` | LOW |
| Kerberos falls back to NTLM | SPN missing or on wrong account | Register SPN on correct account | LOW |
| Error 0x32 / KDC_ERR_BADMATCH | Duplicate SPN | `setspn -D <spn> <wrongaccount>` | MEDIUM |
| Double-hop fails (web→DB) | KCD not configured | Add DB SPN to `msDS-AllowedToDelegateTo` | MEDIUM |
| Works on server A, fails on B | SPN missing from service account (only on computer) | Register SPN on service account | LOW |
| VIP auth fails | VIP SPN missing | Register VIP SPN on app pool account | LOW |
| gMSA service not authenticating | SPN not on gMSA | Register SPN manually on gMSA | LOW |
| S4U2Self / protocol transition failing | TrustedToAuthForDelegation not set | Set on service account (with justification) | MEDIUM |

---

## Documentation

Record in Jira ticket:
- Failing service and server: `[NAME]`
- Service account: `[ACCOUNT]`
- SPN status before fix: `[setspn -L output]`
- Delegation type configured: `[Unconstrained / KCD / RBKCD]`
- Root cause: `[DESCRIPTION]`
- Commands run: `[LIST]`
- Verification: `[klist output / auth protocol in event 4624]`
