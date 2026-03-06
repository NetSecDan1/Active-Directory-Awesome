# Safe PowerShell Patterns for Identity Operations

## System Prompt

```
You are an expert PowerShell automation engineer specializing in Active Directory and
Entra ID operations. Your role is to help engineers write safe, production-ready
PowerShell scripts that follow security best practices and minimize blast radius.

CORE PRINCIPLES:
1. Read-only operations first - gather data before making changes
2. -WhatIf before execution - always preview changes
3. Transaction logging - log every action for audit
4. Rollback capability - design scripts that can undo changes
5. Least privilege - request minimum permissions needed

RISK CLASSIFICATION:
- [SAFE]: Read-only, no changes possible
- [ADVISORY]: Changes limited to single object
- [APPROVAL]: Changes to multiple objects, require approval
- [ELEVATED]: Domain-wide or tenant-wide changes
- [FORBIDDEN]: Never automate without human intervention
```

---

## Part 1: Safe Script Templates

### Read-Only Investigation Script Template

```powershell
<#
.SYNOPSIS
    [SAFE] Read-only identity investigation script template
.DESCRIPTION
    This template provides a safe pattern for gathering identity data
    without making any changes to the environment.
.PARAMETER TargetIdentity
    The user, group, or object to investigate
.PARAMETER OutputPath
    Path to save the investigation report
.EXAMPLE
    .\Invoke-IdentityInvestigation.ps1 -TargetIdentity "jsmith" -OutputPath "C:\Reports"
.NOTES
    Risk Level: [SAFE] - Read-only operations only
    Required Modules: ActiveDirectory, Microsoft.Graph
    Required Permissions: Read access to AD, User.Read.All in Entra
#>

#Requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetIdentity,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Reports",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeEntraID
)

# ============================================================================
# SAFETY CONTROLS
# ============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# Verify we're not accidentally running with elevated permissions we don't need
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Warning "Running as Administrator - this script only requires standard read access"
    Write-Warning "Consider running without elevation for principle of least privilege"
}

# ============================================================================
# LOGGING CONFIGURATION
# ============================================================================

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $OutputPath "Investigation_${TargetIdentity}_${timestamp}.log"
$reportFile = Join-Path $OutputPath "Investigation_${TargetIdentity}_${timestamp}.html"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry
    switch ($Level) {
        "ERROR" { Write-Error $Message }
        "WARNING" { Write-Warning $Message }
        default { Write-Information $Message }
    }
}

# ============================================================================
# DATA COLLECTION (READ-ONLY)
# ============================================================================

try {
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    Write-Log "Starting investigation for: $TargetIdentity"
    Write-Log "Script executing as: $($env:USERNAME)"
    Write-Log "Risk Level: [SAFE] - Read-only operations"

    $results = @{
        InvestigationTarget = $TargetIdentity
        Timestamp = Get-Date
        ExecutedBy = $env:USERNAME
        ADData = $null
        EntraData = $null
        Errors = @()
    }

    # ========== ACTIVE DIRECTORY DATA ==========
    Write-Log "Gathering Active Directory data..."

    try {
        $adUser = Get-ADUser -Identity $TargetIdentity -Properties * -ErrorAction Stop

        $results.ADData = @{
            BasicInfo = @{
                SamAccountName = $adUser.SamAccountName
                UserPrincipalName = $adUser.UserPrincipalName
                DisplayName = $adUser.DisplayName
                Enabled = $adUser.Enabled
                LockedOut = $adUser.LockedOut
                PasswordExpired = $adUser.PasswordExpired
                PasswordLastSet = $adUser.PasswordLastSet
                LastLogonDate = $adUser.LastLogonDate
                WhenCreated = $adUser.WhenCreated
                WhenChanged = $adUser.WhenChanged
            }
            GroupMemberships = (Get-ADPrincipalGroupMembership -Identity $TargetIdentity |
                Select-Object Name, GroupCategory, GroupScope)
            AccountFlags = @{
                AccountNotDelegated = $adUser.AccountNotDelegated
                TrustedForDelegation = $adUser.TrustedForDelegation
                TrustedToAuthForDelegation = $adUser.TrustedToAuthForDelegation
                PasswordNeverExpires = $adUser.PasswordNeverExpires
                CannotChangePassword = $adUser.CannotChangePassword
            }
        }

        # Check for sensitive group memberships
        $sensitiveGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins",
                            "Administrators", "Account Operators", "Backup Operators")
        $userGroups = $results.ADData.GroupMemberships | Select-Object -ExpandProperty Name
        $matchedSensitive = $sensitiveGroups | Where-Object { $_ -in $userGroups }

        if ($matchedSensitive) {
            Write-Log "WARNING: User is member of sensitive groups: $($matchedSensitive -join ', ')" -Level WARNING
        }

        Write-Log "AD data collection complete"
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Log "User not found in Active Directory: $TargetIdentity" -Level WARNING
        $results.Errors += "AD user not found"
    }

    # ========== ENTRA ID DATA (OPTIONAL) ==========
    if ($IncludeEntraID) {
        Write-Log "Gathering Entra ID data..."

        try {
            # Check for Microsoft.Graph module
            if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
                throw "Microsoft.Graph.Users module not installed"
            }

            # Use read-only scopes
            Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All" -NoWelcome

            $mgUser = Get-MgUser -Filter "userPrincipalName eq '$($adUser.UserPrincipalName)'" -Property *

            if ($mgUser) {
                $results.EntraData = @{
                    Id = $mgUser.Id
                    AccountEnabled = $mgUser.AccountEnabled
                    CreatedDateTime = $mgUser.CreatedDateTime
                    LastSignInDateTime = $mgUser.SignInActivity.LastSignInDateTime
                    RiskLevel = $mgUser.RiskLevel
                    RiskState = $mgUser.RiskState
                }
            }

            Write-Log "Entra ID data collection complete"
        }
        catch {
            Write-Log "Entra ID collection failed: $($_.Exception.Message)" -Level WARNING
            $results.Errors += "Entra ID collection failed: $($_.Exception.Message)"
        }
    }

    # ========== GENERATE REPORT ==========
    Write-Log "Generating investigation report..."

    # [Report generation code would go here]
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath ($reportFile -replace '\.html$', '.json')

    Write-Log "Investigation complete. Report saved to: $reportFile"
    Write-Log "Log file: $logFile"

    return $results
}
catch {
    Write-Log "Critical error: $($_.Exception.Message)" -Level ERROR
    throw
}
finally {
    if ($IncludeEntraID) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
    }
}
```

---

## Part 2: Change Scripts with Safety Controls

### User Modification with WhatIf

```powershell
<#
.SYNOPSIS
    [ADVISORY] Safely modify user account with full audit trail
.DESCRIPTION
    Modifies user properties with mandatory WhatIf preview, confirmation,
    and rollback capability.
.PARAMETER TargetUser
    The user to modify
.PARAMETER Changes
    Hashtable of property changes
.PARAMETER Force
    Skip confirmation prompts (requires approval ticket)
.PARAMETER ApprovalTicket
    Change management ticket number (required for -Force)
.EXAMPLE
    $changes = @{ Department = "IT"; Title = "Engineer" }
    .\Set-UserPropertySafe.ps1 -TargetUser "jsmith" -Changes $changes
.NOTES
    Risk Level: [ADVISORY] - Single user modification
    Required Permissions: Write access to user object
    Requires: Approval ticket for -Force execution
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetUser,

    [Parameter(Mandatory = $true)]
    [hashtable]$Changes,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$ApprovalTicket
)

# ============================================================================
# SAFETY CONTROLS
# ============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Require approval ticket for Force mode
if ($Force -and -not $ApprovalTicket) {
    throw "ApprovalTicket is required when using -Force. Please provide a valid change ticket number."
}

# Prevent dangerous attribute modifications
$forbiddenAttributes = @(
    'adminCount',
    'msDS-AllowedToActOnBehalfOfOtherIdentity',
    'msDS-AllowedToDelegateTo',
    'servicePrincipalName',
    'userAccountControl'  # Use specific cmdlets for these
)

$dangerousRequested = $Changes.Keys | Where-Object { $_ -in $forbiddenAttributes }
if ($dangerousRequested) {
    throw "[FORBIDDEN] Cannot modify these attributes via this script: $($dangerousRequested -join ', '). Use dedicated procedures."
}

# ============================================================================
# LOGGING & BACKUP
# ============================================================================

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = ".\Logs\UserModification_${TargetUser}_${timestamp}.log"
$backupPath = ".\Backups\UserBackup_${TargetUser}_${timestamp}.xml"

# Ensure directories exist
@(".\Logs", ".\Backups") | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

function Write-AuditLog {
    param([string]$Action, [string]$Details, [string]$Result)
    $entry = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ExecutedBy = $env:USERNAME
        ApprovalTicket = $ApprovalTicket
        TargetUser = $TargetUser
        Action = $Action
        Details = $Details
        Result = $Result
    }
    $entry | Export-Csv -Path $logPath -Append -NoTypeInformation
    Write-Verbose "AUDIT: $Action - $Details - $Result"
}

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

Write-AuditLog -Action "SCRIPT_START" -Details "Initiated user modification" -Result "Starting"

# Get current user state for backup
try {
    $currentUser = Get-ADUser -Identity $TargetUser -Properties *
    Write-AuditLog -Action "USER_FOUND" -Details "User exists in AD" -Result "Success"
}
catch {
    Write-AuditLog -Action "USER_LOOKUP" -Details $_.Exception.Message -Result "Failed"
    throw "Cannot find user: $TargetUser"
}

# Create backup of current state
$currentUser | Export-Clixml -Path $backupPath
Write-AuditLog -Action "BACKUP_CREATED" -Details "Backup saved to $backupPath" -Result "Success"

# ============================================================================
# CHANGE PREVIEW (WHATIF)
# ============================================================================

Write-Host "`n===== CHANGE PREVIEW =====" -ForegroundColor Cyan
Write-Host "Target User: $($currentUser.SamAccountName) ($($currentUser.DisplayName))"
Write-Host "Approval Ticket: $(if ($ApprovalTicket) { $ApprovalTicket } else { 'NONE - Manual confirmation required' })"
Write-Host "`nProposed Changes:"

$changePreview = @()
foreach ($key in $Changes.Keys) {
    $currentValue = $currentUser.$key
    $newValue = $Changes[$key]

    $changePreview += [PSCustomObject]@{
        Property = $key
        CurrentValue = $currentValue
        NewValue = $newValue
        Changed = ($currentValue -ne $newValue)
    }

    if ($currentValue -ne $newValue) {
        Write-Host "  $key : '$currentValue' -> '$newValue'" -ForegroundColor Yellow
    }
    else {
        Write-Host "  $key : No change (already '$currentValue')" -ForegroundColor Gray
    }
}

# Count actual changes
$actualChanges = $changePreview | Where-Object { $_.Changed }
if ($actualChanges.Count -eq 0) {
    Write-Host "`nNo changes required - all values already match." -ForegroundColor Green
    Write-AuditLog -Action "SCRIPT_END" -Details "No changes needed" -Result "NoOp"
    return
}

# ============================================================================
# EXECUTION WITH CONFIRMATION
# ============================================================================

if ($PSCmdlet.ShouldProcess($TargetUser, "Apply $($actualChanges.Count) property changes")) {

    try {
        # Apply each change individually for granular logging
        foreach ($change in $actualChanges) {
            $setParams = @{
                Identity = $TargetUser
                $change.Property = $change.NewValue
            }

            Write-AuditLog -Action "APPLYING_CHANGE" -Details "$($change.Property): '$($change.CurrentValue)' -> '$($change.NewValue)'" -Result "InProgress"

            Set-ADUser @setParams

            Write-AuditLog -Action "CHANGE_APPLIED" -Details "$($change.Property) updated" -Result "Success"
        }

        # Verify changes
        $verifyUser = Get-ADUser -Identity $TargetUser -Properties ($Changes.Keys)
        $verificationFailed = $false

        foreach ($change in $actualChanges) {
            if ($verifyUser.$($change.Property) -ne $change.NewValue) {
                Write-AuditLog -Action "VERIFICATION" -Details "$($change.Property) verification failed" -Result "Failed"
                $verificationFailed = $true
            }
        }

        if ($verificationFailed) {
            Write-Warning "Some changes may not have applied correctly. Review audit log."
        }
        else {
            Write-Host "`nAll changes applied and verified successfully." -ForegroundColor Green
            Write-AuditLog -Action "SCRIPT_END" -Details "All changes verified" -Result "Success"
        }
    }
    catch {
        Write-AuditLog -Action "ERROR" -Details $_.Exception.Message -Result "Failed"

        Write-Host "`n===== ROLLBACK INFORMATION =====" -ForegroundColor Red
        Write-Host "An error occurred. To rollback, use the backup file:"
        Write-Host "  Import-Clixml '$backupPath' | Set-ADUser"
        Write-Host "Or manually review and restore from audit log:"
        Write-Host "  $logPath"

        throw
    }
}
else {
    Write-AuditLog -Action "SCRIPT_END" -Details "Cancelled by user or WhatIf" -Result "Cancelled"
}
```

---

## Part 3: Bulk Operations with Throttling

### Safe Bulk User Operations

```powershell
<#
.SYNOPSIS
    [APPROVAL] Bulk user operations with throttling and checkpoint
.DESCRIPTION
    Processes bulk user changes with rate limiting, checkpointing,
    and automatic pause on error threshold.
.PARAMETER InputFile
    CSV file with users and changes
.PARAMETER MaxErrorPercent
    Maximum error percentage before auto-pause (default: 5)
.PARAMETER BatchSize
    Users to process between checkpoints (default: 50)
.PARAMETER ThrottleDelayMs
    Milliseconds between operations (default: 100)
.NOTES
    Risk Level: [APPROVAL] - Multiple user modifications
    Required: Change management approval before execution
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$ApprovalTicket,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 20)]
    [int]$MaxErrorPercent = 5,

    [Parameter(Mandatory = $false)]
    [ValidateRange(10, 500)]
    [int]$BatchSize = 50,

    [Parameter(Mandatory = $false)]
    [ValidateRange(50, 5000)]
    [int]$ThrottleDelayMs = 100,

    [Parameter(Mandatory = $false)]
    [string]$ResumeFromCheckpoint
)

# ============================================================================
# SAFETY CONTROLS
# ============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Validate approval ticket format (customize regex for your org)
if ($ApprovalTicket -notmatch '^CHG\d{7}$') {
    throw "Invalid approval ticket format. Expected: CHGnnnnnnn"
}

# ============================================================================
# CONFIGURATION
# ============================================================================

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$sessionId = [guid]::NewGuid().ToString().Substring(0, 8)
$checkpointFile = ".\Checkpoints\BulkOp_${sessionId}.checkpoint"
$logFile = ".\Logs\BulkOperation_${sessionId}.log"
$reportFile = ".\Reports\BulkOperation_${sessionId}.csv"

# Ensure directories
@(".\Checkpoints", ".\Logs", ".\Reports", ".\Backups") | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

$state = @{
    TotalUsers = 0
    ProcessedUsers = 0
    SuccessCount = 0
    ErrorCount = 0
    SkippedCount = 0
    StartTime = Get-Date
    LastCheckpoint = 0
    Errors = @()
}

function Save-Checkpoint {
    $state | Export-Clixml -Path $checkpointFile
    Write-Host "  Checkpoint saved at user $($state.ProcessedUsers)" -ForegroundColor DarkGray
}

function Get-Checkpoint {
    param([string]$Path)
    if (Test-Path $Path) {
        return Import-Clixml -Path $Path
    }
    return $null
}

function Write-BulkLog {
    param([string]$User, [string]$Action, [string]$Result, [string]$Details)
    [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        SessionId = $sessionId
        ApprovalTicket = $ApprovalTicket
        User = $User
        Action = $Action
        Result = $Result
        Details = $Details
    } | Export-Csv -Path $logFile -Append -NoTypeInformation
}

# ============================================================================
# LOAD AND VALIDATE INPUT
# ============================================================================

# Resume from checkpoint if specified
if ($ResumeFromCheckpoint) {
    $resumeState = Get-Checkpoint -Path $ResumeFromCheckpoint
    if ($resumeState) {
        $state = $resumeState
        Write-Host "Resuming from checkpoint: $($state.ProcessedUsers) users already processed" -ForegroundColor Yellow
    }
}

# Load input file
$users = Import-Csv -Path $InputFile
$state.TotalUsers = $users.Count

Write-Host "===== BULK OPERATION PREVIEW =====" -ForegroundColor Cyan
Write-Host "Session ID: $sessionId"
Write-Host "Approval Ticket: $ApprovalTicket"
Write-Host "Input File: $InputFile"
Write-Host "Total Users: $($state.TotalUsers)"
Write-Host "Batch Size: $BatchSize"
Write-Host "Throttle Delay: ${ThrottleDelayMs}ms"
Write-Host "Max Error Threshold: ${MaxErrorPercent}%"

if (-not $PSCmdlet.ShouldProcess("$($state.TotalUsers) users", "Execute bulk operation")) {
    Write-Host "`nOperation cancelled." -ForegroundColor Yellow
    return
}

# ============================================================================
# MAIN PROCESSING LOOP
# ============================================================================

Write-Host "`nStarting bulk operation..." -ForegroundColor Green
Write-BulkLog -User "SYSTEM" -Action "BULK_START" -Result "Starting" -Details "Processing $($state.TotalUsers) users"

$progressParams = @{
    Activity = "Bulk User Operation"
    Status = "Processing..."
    PercentComplete = 0
}

foreach ($user in $users) {
    # Skip already processed users (for resume)
    if ($state.ProcessedUsers -lt $state.LastCheckpoint) {
        $state.ProcessedUsers++
        continue
    }

    $identity = $user.SamAccountName  # Adjust based on your CSV structure

    # Update progress
    $progressParams.PercentComplete = [math]::Round(($state.ProcessedUsers / $state.TotalUsers) * 100)
    $progressParams.Status = "Processing $identity ($($state.ProcessedUsers + 1) of $($state.TotalUsers))"
    Write-Progress @progressParams

    try {
        # ===== YOUR OPERATION HERE =====
        # Example: Set-ADUser -Identity $identity -Department $user.Department

        # Placeholder for actual operation
        $operation = {
            # Set-ADUser -Identity $identity -Department $user.Department -WhatIf:$WhatIfPreference
        }
        & $operation

        $state.SuccessCount++
        Write-BulkLog -User $identity -Action "UPDATE" -Result "Success" -Details "Operation completed"
    }
    catch {
        $state.ErrorCount++
        $state.Errors += @{
            User = $identity
            Error = $_.Exception.Message
            Time = Get-Date
        }
        Write-BulkLog -User $identity -Action "UPDATE" -Result "Failed" -Details $_.Exception.Message
        Write-Warning "Error processing $identity : $($_.Exception.Message)"
    }

    $state.ProcessedUsers++

    # Check error threshold
    $errorPercent = ($state.ErrorCount / $state.ProcessedUsers) * 100
    if ($errorPercent -gt $MaxErrorPercent) {
        Save-Checkpoint
        Write-Host "`n===== OPERATION PAUSED =====" -ForegroundColor Red
        Write-Host "Error threshold exceeded: $([math]::Round($errorPercent, 1))% errors"
        Write-Host "Checkpoint saved: $checkpointFile"
        Write-Host "Review errors and resume with: -ResumeFromCheckpoint '$checkpointFile'"
        Write-BulkLog -User "SYSTEM" -Action "BULK_PAUSED" -Result "ErrorThreshold" -Details "Error rate: $errorPercent%"
        return
    }

    # Checkpoint
    if ($state.ProcessedUsers % $BatchSize -eq 0) {
        $state.LastCheckpoint = $state.ProcessedUsers
        Save-Checkpoint
    }

    # Throttle
    Start-Sleep -Milliseconds $ThrottleDelayMs
}

Write-Progress -Activity "Bulk User Operation" -Completed

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

$duration = (Get-Date) - $state.StartTime

Write-Host "`n===== OPERATION COMPLETE =====" -ForegroundColor Green
Write-Host "Session ID: $sessionId"
Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))"
Write-Host "Total Processed: $($state.ProcessedUsers)"
Write-Host "Successful: $($state.SuccessCount)" -ForegroundColor Green
Write-Host "Failed: $($state.ErrorCount)" -ForegroundColor $(if ($state.ErrorCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "Skipped: $($state.SkippedCount)" -ForegroundColor Yellow
Write-Host "`nLog File: $logFile"
Write-Host "Report: $reportFile"

Write-BulkLog -User "SYSTEM" -Action "BULK_COMPLETE" -Result "Success" -Details "Processed: $($state.ProcessedUsers), Success: $($state.SuccessCount), Failed: $($state.ErrorCount)"

# Export final report
$state | Export-Clixml -Path $reportFile.Replace('.csv', '.xml')
```

---

## Part 4: Graph API Safe Patterns

### Entra ID Operations with Safety

```powershell
<#
.SYNOPSIS
    Safe Entra ID operations using Microsoft Graph
.DESCRIPTION
    Templates for common Entra operations with safety controls
.NOTES
    Risk Level: Varies by operation
    Required Modules: Microsoft.Graph
#>

#Requires -Modules Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.Identity.DirectoryManagement

# ============================================================================
# SAFE CONNECTION PATTERN
# ============================================================================

function Connect-GraphSafe {
    <#
    .SYNOPSIS
        Connect to Graph with minimal required scopes
    .PARAMETER Operation
        Type of operation to determine required scopes
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ReadOnly', 'UserWrite', 'GroupWrite', 'RoleWrite')]
        [string]$Operation
    )

    $scopeMap = @{
        'ReadOnly'   = @('User.Read.All', 'Group.Read.All', 'Directory.Read.All', 'AuditLog.Read.All')
        'UserWrite'  = @('User.ReadWrite.All')
        'GroupWrite' = @('Group.ReadWrite.All', 'GroupMember.ReadWrite.All')
        'RoleWrite'  = @('RoleManagement.ReadWrite.Directory')  # [ELEVATED] - Requires approval
    }

    $scopes = $scopeMap[$Operation]

    Write-Host "Connecting to Microsoft Graph..."
    Write-Host "Requested scopes: $($scopes -join ', ')"

    if ($Operation -eq 'RoleWrite') {
        Write-Warning "[ELEVATED] Role management scope requested. Ensure change management approval."
        $confirm = Read-Host "Continue? (yes/no)"
        if ($confirm -ne 'yes') { return $false }
    }

    Connect-MgGraph -Scopes $scopes -NoWelcome

    # Verify connection
    $context = Get-MgContext
    if ($context) {
        Write-Host "Connected as: $($context.Account)" -ForegroundColor Green
        Write-Host "Tenant: $($context.TenantId)"
        return $true
    }
    return $false
}

# ============================================================================
# USER OPERATIONS
# ============================================================================

function Get-EntraUserSafe {
    <#
    .SYNOPSIS
        [SAFE] Retrieve user with comprehensive properties
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName
    )

    $properties = @(
        'Id', 'UserPrincipalName', 'DisplayName', 'Mail',
        'AccountEnabled', 'CreatedDateTime', 'LastPasswordChangeDateTime',
        'SignInActivity', 'OnPremisesSyncEnabled', 'OnPremisesLastSyncDateTime',
        'AssignedLicenses', 'AssignedPlans'
    )

    $user = Get-MgUser -UserId $UserPrincipalName -Property $properties -ErrorAction Stop

    # Get additional context
    $groups = Get-MgUserMemberOf -UserId $user.Id | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.group' }
    $roles = Get-MgUserMemberOf -UserId $user.Id | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.directoryRole' }

    return [PSCustomObject]@{
        User = $user
        Groups = $groups
        DirectoryRoles = $roles
        IsSynced = $user.OnPremisesSyncEnabled
        LastSignIn = $user.SignInActivity.LastSignInDateTime
    }
}

function Disable-EntraUserSafe {
    <#
    .SYNOPSIS
        [ADVISORY] Disable user with session revocation
    .NOTES
        Creates backup and logs all actions
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserPrincipalName,

        [Parameter(Mandatory = $true)]
        [string]$Reason,

        [Parameter(Mandatory = $false)]
        [string]$Ticket
    )

    # Get current state for backup
    $currentState = Get-EntraUserSafe -UserPrincipalName $UserPrincipalName

    # Check if cloud-only or synced
    if ($currentState.IsSynced) {
        Write-Warning "This is a synced user. Disable in on-premises AD instead."
        Write-Warning "Entra changes will be overwritten on next sync."
        $continue = Read-Host "Continue anyway? (yes/no)"
        if ($continue -ne 'yes') { return }
    }

    # Create backup
    $backupPath = ".\Backups\EntraUser_$($currentState.User.Id)_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $currentState | ConvertTo-Json -Depth 10 | Out-File $backupPath

    Write-Host "Backup created: $backupPath"

    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Disable account and revoke sessions")) {

        # Disable account
        Update-MgUser -UserId $currentState.User.Id -AccountEnabled:$false
        Write-Host "Account disabled" -ForegroundColor Yellow

        # Revoke sessions
        Revoke-MgUserSignInSession -UserId $currentState.User.Id
        Write-Host "All sessions revoked" -ForegroundColor Yellow

        # Log action
        $logEntry = @{
            Timestamp = Get-Date
            Action = "DisableUser"
            User = $UserPrincipalName
            Reason = $Reason
            Ticket = $Ticket
            ExecutedBy = (Get-MgContext).Account
            BackupPath = $backupPath
        }
        $logEntry | ConvertTo-Json | Out-File ".\Logs\EntraActions.log" -Append

        Write-Host "User disabled successfully. Sessions revoked." -ForegroundColor Green
        Write-Host "To re-enable: Update-MgUser -UserId '$($currentState.User.Id)' -AccountEnabled:`$true"
    }
}

# ============================================================================
# GROUP OPERATIONS
# ============================================================================

function Add-EntraGroupMemberSafe {
    <#
    .SYNOPSIS
        [ADVISORY] Add user to group with validation
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupId,

        [Parameter(Mandatory = $true)]
        [string]$UserId,

        [Parameter(Mandatory = $false)]
        [string]$Ticket
    )

    # Get group details
    $group = Get-MgGroup -GroupId $GroupId

    # Check for privileged groups
    $privilegedGroupPatterns = @(
        'Admin', 'Global Admin', 'Privileged', 'Security'
    )

    $isPrivileged = $privilegedGroupPatterns | Where-Object { $group.DisplayName -match $_ }

    if ($isPrivileged) {
        Write-Warning "[ELEVATED] Adding user to privileged group: $($group.DisplayName)"
        if (-not $Ticket) {
            throw "Ticket required for privileged group membership changes"
        }
    }

    # Check current membership
    $currentMembers = Get-MgGroupMember -GroupId $GroupId -All
    if ($currentMembers.Id -contains $UserId) {
        Write-Host "User is already a member of this group" -ForegroundColor Yellow
        return
    }

    if ($PSCmdlet.ShouldProcess("$UserId to $($group.DisplayName)", "Add group membership")) {
        New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $UserId

        Write-Host "User added to group: $($group.DisplayName)" -ForegroundColor Green

        # Log
        @{
            Timestamp = Get-Date
            Action = "AddGroupMember"
            Group = $group.DisplayName
            GroupId = $GroupId
            User = $UserId
            Ticket = $Ticket
            IsPrivileged = [bool]$isPrivileged
        } | ConvertTo-Json | Out-File ".\Logs\EntraActions.log" -Append
    }
}
```

---

## Part 5: Emergency Response Scripts

### Account Lockdown Script

```powershell
<#
.SYNOPSIS
    [ELEVATED] Emergency account containment
.DESCRIPTION
    Immediately contains a compromised account across AD and Entra
.PARAMETER Identity
    User to contain
.PARAMETER Reason
    Reason for containment (logged)
.PARAMETER IncidentTicket
    Security incident ticket (required)
.NOTES
    Risk Level: [ELEVATED] - Immediate account disablement
    Use only for confirmed security incidents
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Identity,

    [Parameter(Mandatory = $true)]
    [string]$Reason,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^INC\d{7}$')]
    [string]$IncidentTicket
)

$ErrorActionPreference = 'Continue'  # Continue on errors to complete containment
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$containmentLog = ".\EmergencyContainment_${Identity}_${timestamp}.log"

function Log-ContainmentAction {
    param([string]$Action, [string]$Result, [string]$Details)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Action | $Result | $Details"
    Add-Content -Path $containmentLog -Value $entry
    Write-Host $entry -ForegroundColor $(if ($Result -eq 'SUCCESS') { 'Green' } else { 'Red' })
}

Write-Host "===== EMERGENCY CONTAINMENT =====" -ForegroundColor Red
Write-Host "Target: $Identity"
Write-Host "Incident: $IncidentTicket"
Write-Host "Reason: $Reason"
Write-Host "=================================" -ForegroundColor Red

Log-ContainmentAction -Action "CONTAINMENT_START" -Result "INITIATED" -Details "Incident: $IncidentTicket, Reason: $Reason"

# ============================================================================
# PHASE 1: ACTIVE DIRECTORY CONTAINMENT
# ============================================================================

Write-Host "`n[PHASE 1] Active Directory Containment" -ForegroundColor Yellow

try {
    # Get AD user
    $adUser = Get-ADUser -Identity $Identity -Properties *

    # Backup current state
    $adUser | Export-Clixml ".\Backups\AD_${Identity}_${timestamp}.xml"
    Log-ContainmentAction -Action "AD_BACKUP" -Result "SUCCESS" -Details "Backup saved"

    # Disable account
    Disable-ADAccount -Identity $Identity
    Log-ContainmentAction -Action "AD_DISABLE" -Result "SUCCESS" -Details "Account disabled"

    # Reset password to random
    $newPassword = [System.Web.Security.Membership]::GeneratePassword(24, 4)
    Set-ADAccountPassword -Identity $Identity -Reset -NewPassword (ConvertTo-SecureString $newPassword -AsPlainText -Force)
    Log-ContainmentAction -Action "AD_PASSWORD_RESET" -Result "SUCCESS" -Details "Password randomized"

    # Remove from all groups (except Domain Users)
    $groups = Get-ADPrincipalGroupMembership -Identity $Identity | Where-Object { $_.Name -ne 'Domain Users' }
    foreach ($group in $groups) {
        Remove-ADGroupMember -Identity $group -Members $Identity -Confirm:$false
        Log-ContainmentAction -Action "AD_GROUP_REMOVE" -Result "SUCCESS" -Details "Removed from: $($group.Name)"
    }
}
catch {
    Log-ContainmentAction -Action "AD_CONTAINMENT" -Result "FAILED" -Details $_.Exception.Message
}

# ============================================================================
# PHASE 2: ENTRA ID CONTAINMENT
# ============================================================================

Write-Host "`n[PHASE 2] Entra ID Containment" -ForegroundColor Yellow

try {
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All" -NoWelcome

    $upn = $adUser.UserPrincipalName
    $mgUser = Get-MgUser -UserId $upn

    if ($mgUser) {
        # Backup
        $mgUser | ConvertTo-Json -Depth 10 | Out-File ".\Backups\Entra_${Identity}_${timestamp}.json"
        Log-ContainmentAction -Action "ENTRA_BACKUP" -Result "SUCCESS" -Details "Backup saved"

        # Disable account
        Update-MgUser -UserId $mgUser.Id -AccountEnabled:$false
        Log-ContainmentAction -Action "ENTRA_DISABLE" -Result "SUCCESS" -Details "Account disabled"

        # Revoke all sessions
        Revoke-MgUserSignInSession -UserId $mgUser.Id
        Log-ContainmentAction -Action "ENTRA_REVOKE_SESSIONS" -Result "SUCCESS" -Details "All sessions revoked"

        # Revoke app consents
        $consents = Get-MgUserOAuth2PermissionGrant -UserId $mgUser.Id
        foreach ($consent in $consents) {
            Remove-MgOAuth2PermissionGrant -OAuth2PermissionGrantId $consent.Id
            Log-ContainmentAction -Action "ENTRA_REVOKE_CONSENT" -Result "SUCCESS" -Details "Revoked consent: $($consent.ClientId)"
        }
    }
}
catch {
    Log-ContainmentAction -Action "ENTRA_CONTAINMENT" -Result "FAILED" -Details $_.Exception.Message
}
finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n===== CONTAINMENT COMPLETE =====" -ForegroundColor Green
Write-Host "Log file: $containmentLog"
Write-Host "Backups saved to: .\Backups\"
Write-Host "`nNext steps:"
Write-Host "1. Investigate the incident thoroughly"
Write-Host "2. Review backup files before any restoration"
Write-Host "3. Document findings in: $IncidentTicket"

Log-ContainmentAction -Action "CONTAINMENT_COMPLETE" -Result "SUCCESS" -Details "All phases completed"
```

---

## Quick Reference Card

```
POWERSHELL SAFETY PATTERNS QUICK REFERENCE

BEFORE ANY SCRIPT:
□ Check risk level ([SAFE]/[ADVISORY]/[APPROVAL]/[ELEVATED])
□ Get approval ticket if required
□ Run with -WhatIf first
□ Create backups before changes

READ-ONLY PATTERN:
Get-AD* | Select-Object | Export-Csv  # Safe
Get-MgUser -Property * | ConvertTo-Json  # Safe

CHANGE WITH CONFIRMATION:
Set-ADUser -Identity $user -Property $value -WhatIf
Set-ADUser -Identity $user -Property $value -Confirm

BULK WITH THROTTLE:
$users | ForEach-Object {
    Set-ADUser ...
    Start-Sleep -Milliseconds 100
}

EMERGENCY CONTAINMENT ORDER:
1. Disable-ADAccount (immediate)
2. Set-ADAccountPassword -Reset (randomize)
3. Remove-ADGroupMember (strip access)
4. Update-MgUser -AccountEnabled:$false
5. Revoke-MgUserSignInSession (kill sessions)

REQUIRED LOGGING:
- Who ran the script
- When it ran
- What changed (before/after)
- Approval ticket
- Backup location
```

---

*Document Version: 1.0*
*Framework: Safe PowerShell Automation*
*Integration: Active Directory, Microsoft Graph*
