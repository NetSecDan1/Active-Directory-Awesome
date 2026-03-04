# Runbook: Domain Controller Promotion
**Risk**: HIGH | **Estimated Time**: 2-4 hours
**Requires**: Domain Admin + local Admin on new server
**Change Type**: Normal — CAB Required | **Version**: 2.0

---

## Decision: What type of DC are you promoting?

| Scenario | Section |
|---------|---------|
| Additional DC in existing domain (most common) | Section A |
| Additional DC in existing domain as RODC | Section B |
| First DC in a new child domain | Section C |

---

## Phase 0 — Prerequisites & Pre-Checks

**Verify before the change window opens:**

```powershell
# On the new server — check OS and name
$env:COMPUTERNAME
(Get-WmiObject Win32_OperatingSystem).Caption
# Must be: Windows Server 2019 or 2022

# Check DNS client settings on new server (must point to existing DC)
Get-DnsClientServerAddress -AddressFamily IPv4

# Check network connectivity to existing DCs
$existingDC = "DC01.corp.contoso.com"
Test-NetConnection $existingDC -Port 389
Test-NetConnection $existingDC -Port 88
Test-NetConnection $existingDC -Port 445

# Check existing domain replication is healthy (don't promote into broken replication)
repadmin /replsummary
# Expected: 0 failures — fix any before continuing

# Check existing DC event logs are clean
Get-WinEvent -ComputerName $existingDC -FilterHashtable @{
    LogName='Directory Service'; Level=1,2
    StartTime=(Get-Date).AddDays(-1)
} -ErrorAction SilentlyContinue | Select-Object -First 10
```

**Pre-Promotion Checklist:**
- [ ] Server is domain-joined (or will be joined during promotion)
- [ ] DNS client on new server points to existing DC
- [ ] Network ports open (88, 389, 445, 135, 3268, 49152-65535)
- [ ] Server has static IP address
- [ ] Existing domain replication healthy (0 failures)
- [ ] AD System State backup of existing DC taken today: `[DATE]`
- [ ] Server OS is supported (WS 2019 or WS 2022 recommended)
- [ ] Disk space: C:\ ≥ 20GB free, separate volume for NTDS recommended
- [ ] Change window open: `[START]` → `[END]`

---

## Section A — Additional DC in Existing Domain

### Step A1 — Install AD DS Role (WRITE — LOW risk)

```powershell
# Run on the NEW server as local admin
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
# Takes 2-5 minutes. Restart NOT required at this point.

# Verify role installed
Get-WindowsFeature AD-Domain-Services | Select-Object Name, InstallState
# Expected: Installed
```

### Step A2 — Run Pre-Promotion Test (READ-ONLY)

```powershell
# Test what promotion WOULD do — no changes made
$domain = "corp.contoso.com"
$safeModePassword = Read-Host -Prompt "DSRM Password" -AsSecureString

Test-ADDSDomainControllerInstallation `
    -DomainName $domain `
    -SafeModeAdministratorPassword $safeModePassword `
    -InstallDns:$true `
    -CreateDnsDelegation:$false `
    -NoRebootOnCompletion:$false `
    -Verbose
```
**Review all output carefully before proceeding. Address any warnings.**

### Step A3 — Execute Promotion (WRITE — HIGH risk)

```powershell
# WRITE OPERATION — promotes this server to DC
# Change window must be open
$domain = "corp.contoso.com"
$safeModePassword = Read-Host -Prompt "DSRM Password (store securely)" -AsSecureString
$domainCred = Get-Credential -Message "Domain Admin credentials"

Install-ADDSDomainController `
    -DomainName $domain `
    -Credential $domainCred `
    -SafeModeAdministratorPassword $safeModePassword `
    -InstallDns:$true `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -NoRebootOnCompletion:$false `
    -Force:$true
```
**Server will restart automatically after promotion.**

> **DSRM Password**: Store this password in your organization's password vault immediately. You need it for offline AD repair.

### Step A4 — Post-Promotion Verification (READ-ONLY)

Run these after the server restarts and AD DS starts (~5-10 minutes):

```powershell
# On the NEW DC
# 1. Confirm it appears as a DC
Get-ADDomainController -Identity $env:COMPUTERNAME

# 2. Confirm it has replicated from partners
repadmin /showrepl $env:COMPUTERNAME

# 3. Confirm services running
Get-Service NTDS, NETLOGON, KDC, DNS, DFSR | Select-Object Name, Status

# 4. Confirm SYSVOL shared
net share | findstr SYSVOL

# 5. Run DCDiag
dcdiag /s:$env:COMPUTERNAME /v 2>&1 | Where-Object { $_ -match "fail|error|warning|pass" }

# 6. Confirm new DC registered in DNS
Resolve-DnsName $env:COMPUTERNAME -Type A
```

### Step A5 — Confirm Replication is Flowing (READ-ONLY)

```powershell
# Wait 15-30 minutes after promotion, then check
repadmin /replsummary
# Expected: New DC appears, 0 failures

# Force replication if needed (WRITE — LOW risk)
repadmin /syncall /AdeP
```

---

## Section B — RODC Promotion

RODCs are for branch offices and untrusted locations. Key differences:
- Hosts **read-only** copy of AD
- Stores passwords only for **explicitly allowed accounts** (Password Replication Policy)
- Can be managed by a **non-Domain Admin** designated user

```powershell
# Pre-step: Create RODC computer account (run on existing writable DC)
# This allows a non-admin to complete the promotion at the branch
Add-ADDSReadOnlyDomainControllerAccount `
    -DomainControllerAccountName "RODC-BRANCH01" `
    -DomainName "corp.contoso.com" `
    -SiteName "BranchOffice" `
    -DelegatedAdministratorAccountName "DOMAIN\BranchAdmin" `
    -AllowPasswordReplicationAccountName @("Branch-Users","RODC-Allowed-RODC-Password-Replication-Group") `
    -DenyPasswordReplicationAccountName @("Domain Admins","Enterprise Admins","KRBTGT")

# Promotion (run on new server at branch)
Install-ADDSDomainController `
    -DomainName "corp.contoso.com" `
    -ReadOnlyReplica:$true `
    -SiteName "BranchOffice" `
    -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM Password") `
    -Credential (Get-Credential) `
    -Force:$true
```

---

## Section C — New Child Domain

> ⚠️ Requires Enterprise Admin. Architectural decision — get sign-off from AD Architect first.

```powershell
# Pre-step: Verify parent domain is healthy and Schema/Domain Naming Master accessible
netdom query fsmo

# Child domain promotion
Install-ADDSDomain `
    -NewDomainName "child" `
    -ParentDomainName "corp.contoso.com" `
    -DomainType "ChildDomain" `
    -Credential (Get-Credential -Message "Enterprise Admin") `
    -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM Password") `
    -CreateDnsDelegation:$true `
    -Force:$true
```

---

## Rollback

DC promotion is not easily reversed, but demotion is clean if done promptly:

```powershell
# WRITE — CRITICAL: Demote the DC (run on the DC being removed)
# Do this within the change window if promotion has unexpected issues
Uninstall-ADDSDomainController `
    -LocalAdministratorPassword (Read-Host -AsSecureString "New local admin password") `
    -Force:$true
# Server restarts as a member server after demotion
```

---

## Post-Promotion Tasks

- [ ] Verify DSRM password stored in password vault
- [ ] Add new DC to monitoring (Nagios/SCOM/custom alerts)
- [ ] Verify new DC in site topology: `Sites and Services → Servers`
- [ ] Check subnet assigned to correct site
- [ ] Update CMDB / asset management
- [ ] Verify backup agent installed and AD System State backup scheduled
- [ ] Change ticket closed, PIR scheduled if required
