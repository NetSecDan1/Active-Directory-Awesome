# Active Directory PowerShell Expert

**Use Case:** Generate, explain, and optimize PowerShell scripts for any AD task.
**Techniques:** AD module, ADSI, .NET, error handling, bulk operations

---

## The AD PowerShell Request Prompt

```
You are an expert Active Directory PowerShell engineer. You write clean, production-safe scripts with proper error handling, logging, and -WhatIf support for destructive operations.

TASK:
[Describe exactly what you need the PowerShell to do]

ENVIRONMENT:
- AD Module available: [Yes / No — use ADSI if no]
- PowerShell version: [5.1 / 7.x]
- Scope: [One-liner / Full script with logging]
- Run as: [Service account / Interactive / Scheduled task]
- Output needed: [Console / CSV / Log file / None]

CONSTRAINTS:
- Read-only (no changes): [Yes/No]
- Must support -WhatIf: [Yes/No]
- Must log all actions: [Yes/No]
- Error handling level: [Basic try/catch / Full production-grade]

Generate:
1. The PowerShell code
2. Explanation of what each section does
3. How to run it safely (test approach)
4. Common mistakes or gotchas with this operation
```

---

## Essential AD PowerShell One-Liners

### Users

```powershell
# Get all disabled users in an OU
Get-ADUser -Filter {Enabled -eq $false} -SearchBase "OU=Users,DC=domain,DC=com" -Properties LastLogonDate |
  Select Name, SamAccountName, LastLogonDate | Sort LastLogonDate

# Find users who haven't logged on in 90 days
$cutoff = (Get-Date).AddDays(-90)
Get-ADUser -Filter {LastLogonDate -lt $cutoff -and Enabled -eq $true} -Properties LastLogonDate |
  Select Name, SamAccountName, LastLogonDate

# Get users expiring in next 14 days
$soon = (Get-Date).AddDays(14)
Get-ADUser -Filter {AccountExpirationDate -lt $soon -and AccountExpirationDate -gt (Get-Date) -and Enabled -eq $true} `
  -Properties AccountExpirationDate | Select Name, SamAccountName, AccountExpirationDate

# Find users with password never expires
Get-ADUser -Filter {PasswordNeverExpires -eq $true -and Enabled -eq $true} -Properties PasswordNeverExpires |
  Select Name, SamAccountName

# Bulk create users from CSV
Import-Csv users.csv | ForEach-Object {
    New-ADUser -Name $_.Name -SamAccountName $_.SamAccountName `
      -UserPrincipalName "$($_.SamAccountName)@domain.com" `
      -Path "OU=Users,DC=domain,DC=com" `
      -AccountPassword (ConvertTo-SecureString $_.Password -AsPlainText -Force) `
      -Enabled $true
}

# Reset password and force change at next logon
Set-ADAccountPassword -Identity <username> -NewPassword (ConvertTo-SecureString "TempP@ss123!" -AsPlainText -Force) -Reset
Set-ADUser -Identity <username> -ChangePasswordAtLogon $true

# Find accounts locked out right now
Search-ADAccount -LockedOut | Select Name, SamAccountName, LockedOut, LastLogonDate | Sort Name

# Unlock all locked accounts (use with caution!)
Search-ADAccount -LockedOut | Unlock-ADAccount -WhatIf  # Remove -WhatIf to execute
```

### Groups

```powershell
# Get all members of a group recursively
Get-ADGroupMember -Identity "Domain Admins" -Recursive |
  Get-ADUser -Properties Department, Title |
  Select Name, SamAccountName, Department, Title

# Find empty groups
Get-ADGroup -Filter * -Properties Members |
  Where-Object { $_.Members.Count -eq 0 } |
  Select Name, GroupScope, GroupCategory

# Find groups with a user as a member (nested)
$user = Get-ADUser -Identity <username>
Get-ADGroup -Filter * | Where-Object {
    (Get-ADGroupMember $_ -Recursive).DistinguishedName -contains $user.DistinguishedName
}
# (WARNING: slow on large directories — use specific SearchBase)

# Add/remove bulk users to a group from CSV
Import-Csv users.csv | ForEach-Object { Add-ADGroupMember -Identity "GroupName" -Members $_.SamAccountName }
Import-Csv users.csv | ForEach-Object { Remove-ADGroupMember -Identity "GroupName" -Members $_.SamAccountName -Confirm:$false }

# Export group membership to CSV
Get-ADGroupMember "Domain Admins" -Recursive |
  Get-ADUser -Properties * |
  Select Name, SamAccountName, Email, Department |
  Export-Csv "DomainAdmins.csv" -NoTypeInformation
```

### Computers

```powershell
# Find stale computer accounts (not logged in 90 days)
$cutoff = (Get-Date).AddDays(-90)
Get-ADComputer -Filter {LastLogonDate -lt $cutoff -and Enabled -eq $true} `
  -Properties LastLogonDate, OperatingSystem |
  Select Name, LastLogonDate, OperatingSystem | Sort LastLogonDate

# Get all computers by OS
Get-ADComputer -Filter * -Properties OperatingSystem |
  Group-Object OperatingSystem | Sort Count -Descending |
  Select Name, Count

# Find computers not in the right OU
Get-ADComputer -Filter * -Properties CanonicalName |
  Where-Object { $_.CanonicalName -notlike "*/Workstations/*" } |
  Select Name, CanonicalName
```

### Domain & Replication

```powershell
# Get all DCs with their roles
Get-ADDomainController -Filter * |
  Select Name, Site, IsGlobalCatalog, OperationMasterRoles, IPv4Address |
  Format-Table -AutoSize

# Check replication status
Get-ADReplicationFailure -Scope Forest |
  Select Server, Partner, FirstFailureTime, FailureCount, LastError |
  Sort FailureCount -Descending

# Get replication queue length
Get-ADReplicationQueueOperation -Server <DCName>

# Force sync a specific partition from a specific DC
Sync-ADObject -Object "DC=domain,DC=com" -Source <SourceDC> -Destination <DestDC>

# Find FSMO role holders
Get-ADForest | Select SchemaMaster, DomainNamingMaster
Get-ADDomain | Select PDCEmulator, RIDMaster, InfrastructureMaster
```

---

## Script Generator Prompt

```
Write a production-grade PowerShell script to:
[DESCRIBE THE TASK]

Requirements:
- Comment header with: Purpose, Author, Date, Version, Usage
- CmdletBinding with -WhatIf and -Confirm support
- Parameter validation
- Try/catch error handling
- Transcript logging to C:\Logs\
- Progress indicator for bulk operations
- Output to both console and CSV
- Test mode that shows what WOULD be done without doing it

The script should be safe to run in production. Destructive operations must require confirmation or -Force parameter.
```

---

**Tips:**
- Always test bulk operations with `-WhatIf` first — you can't un-delete an OU
- `Get-ADUser -Properties *` is slow — only request properties you need
- Use `SearchBase` to limit scope on large directories
- For service accounts: use Managed Service Accounts (MSAs/gMSAs) instead of regular accounts
- Pipe to `Out-GridView` for interactive filtering during investigation
