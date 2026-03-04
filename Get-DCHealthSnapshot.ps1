<#
.SYNOPSIS
    Collects a comprehensive health snapshot from all Domain Controllers in the current domain.

.DESCRIPTION
    Get-DCHealthSnapshot queries Active Directory for all domain controllers, performs health
    checks on each one, and outputs a JSON report conforming to the DCHealthReport schema.

    Health checks include:
    - DCDiag tests (connectivity, advertising, DNS, SYSVOL)
    - Service status (NTDS, DNS, Kerberos KDC, Netlogon, DFSR/FRS)
    - Replication health and partner status
    - System resources (CPU, memory, disk)
    - Time synchronization
    - LDAP/Kerberos connectivity

.PARAMETER OutputPath
    Directory where the JSON report will be saved. Defaults to current directory.

.PARAMETER DomainName
    FQDN of the domain to query. Defaults to current user's domain.

.PARAMETER Credential
    PSCredential object for authentication. Defaults to current user context (Windows auth).

.PARAMETER SkipDCDiag
    Skip running DCDiag tests (faster but less thorough).

.PARAMETER Verbose
    Enable verbose output for troubleshooting.

.EXAMPLE
    .\Get-DCHealthSnapshot.ps1 -OutputPath .\test-output\

.EXAMPLE
    .\Get-DCHealthSnapshot.ps1 -OutputPath \\fileserver\ad-health\ -DomainName corp.contoso.com

.EXAMPLE
    .\Get-DCHealthSnapshot.ps1 -OutputPath .\output\ -SkipDCDiag

.NOTES
    Requires: ActiveDirectory PowerShell module (RSAT)
    Requires: Read access to Active Directory
    Schema: DCHealthReport.schema.json v1.0.0
#>

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$OutputPath = ".",

    [Parameter(Mandatory = $false)]
    [string]$DomainName,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [switch]$SkipDCDiag
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Helper Functions

function Write-Log {
    [CmdletBinding()]
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        "Info"    { Write-Verbose "[$timestamp] INFO: $Message" }
        "Warning" { Write-Warning "[$timestamp] $Message" }
        "Error"   { Write-Error "[$timestamp] $Message" }
    }
}

function New-Guid-String {
    return [System.Guid]::NewGuid().ToString()
}

function Get-ADModuleAvailable {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Get-ServiceHealthStatus {
    [CmdletBinding()]
    param(
        [string]$ComputerName,
        [string[]]$ServiceNames = @("NTDS", "DNS", "Kdc", "Netlogon", "DFSR", "W32Time")
    )

    $services = @()
    foreach ($svcName in $ServiceNames) {
        try {
            $svc = Get-Service -Name $svcName -ComputerName $ComputerName -ErrorAction Stop
            $services += [PSCustomObject]@{
                name        = $svc.ServiceName
                displayName = $svc.DisplayName
                status      = $svc.Status.ToString()
                startType   = $svc.StartType.ToString()
            }
        }
        catch {
            Write-Log "Could not query service '$svcName' on $ComputerName : $_" -Level Warning
            $services += [PSCustomObject]@{
                name        = $svcName
                displayName = $svcName
                status      = "Unknown"
                startType   = "Automatic"
            }
        }
    }
    return $services
}

function Test-LDAPConnectivity {
    [CmdletBinding()]
    param([string]$ComputerName)
    try {
        $ldapConnection = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$ComputerName")
        $null = $ldapConnection.Name
        return @{ status = "Healthy"; message = "LDAP connection successful" }
    }
    catch {
        return @{ status = "Critical"; message = "LDAP connection failed: $_" }
    }
}

function Test-DNSResolution {
    [CmdletBinding()]
    param([string]$ComputerName)
    try {
        $dnsResult = Resolve-DnsName -Name $ComputerName -ErrorAction Stop
        if ($dnsResult) {
            return @{ status = "Healthy"; message = "DNS resolution successful" }
        }
        return @{ status = "Warning"; message = "DNS resolution returned empty result" }
    }
    catch {
        return @{ status = "Critical"; message = "DNS resolution failed: $_" }
    }
}

function Test-TimeSyncHealth {
    [CmdletBinding()]
    param([string]$ComputerName)
    try {
        $w32tmOutput = w32tm /monitor /computers:$ComputerName /nowarn 2>&1
        $skewMatch = $w32tmOutput | Select-String "NTP:\s*([+-]?\d+\.\d+)s"
        if ($skewMatch) {
            $skewSeconds = [math]::Abs([double]$skewMatch.Matches[0].Groups[1].Value)
            if ($skewSeconds -lt 1) {
                return @{ status = "Healthy"; message = "Time skew: ${skewSeconds}s" }
            }
            elseif ($skewSeconds -lt 5) {
                return @{ status = "Warning"; message = "Time skew: ${skewSeconds}s (threshold: 5s)" }
            }
            else {
                return @{ status = "Critical"; message = "Time skew: ${skewSeconds}s exceeds threshold" }
            }
        }
        return @{ status = "Warning"; message = "Could not determine time skew" }
    }
    catch {
        return @{ status = "Warning"; message = "Time sync check failed: $_" }
    }
}

function Get-DCDiagResults {
    [CmdletBinding()]
    param([string]$ComputerName)
    try {
        $dcdiagOutput = dcdiag /s:$ComputerName /test:Connectivity /test:Advertising /test:DNS /test:SysVolCheck /test:NetLogons 2>&1
        $passedTests = ($dcdiagOutput | Select-String "passed test").Count
        $failedTests = ($dcdiagOutput | Select-String "failed test").Count

        if ($failedTests -eq 0) {
            return @{ status = "Healthy"; message = "All DCDiag tests passed ($passedTests passed)" }
        }
        elseif ($failedTests -le 1) {
            return @{ status = "Warning"; message = "$failedTests test(s) failed, $passedTests passed" }
        }
        else {
            return @{ status = "Critical"; message = "$failedTests test(s) failed, $passedTests passed" }
        }
    }
    catch {
        return @{ status = "Warning"; message = "DCDiag execution failed: $_" }
    }
}

function Get-SystemResourceMetrics {
    [CmdletBinding()]
    param([string]$ComputerName)

    $metrics = @{
        cpuUsagePercent    = $null
        memoryUsagePercent = $null
        diskFreePercent    = $null
        uptimeDays         = $null
    }

    try {
        # CPU
        $cpu = Get-WmiObject Win32_Processor -ComputerName $ComputerName -ErrorAction Stop |
            Measure-Object -Property LoadPercentage -Average
        $metrics.cpuUsagePercent = [math]::Round($cpu.Average, 1)
    }
    catch { Write-Log "Could not get CPU metrics from $ComputerName" -Level Warning }

    try {
        # Memory
        $os = Get-WmiObject Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop
        $totalMem = $os.TotalVisibleMemorySize
        $freeMem = $os.FreePhysicalMemory
        $metrics.memoryUsagePercent = [math]::Round((($totalMem - $freeMem) / $totalMem) * 100, 1)

        # Uptime
        $lastBoot = [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)
        $metrics.uptimeDays = [math]::Round(((Get-Date) - $lastBoot).TotalDays, 1)
    }
    catch { Write-Log "Could not get memory/uptime metrics from $ComputerName" -Level Warning }

    try {
        # Disk (system drive)
        $disk = Get-WmiObject Win32_LogicalDisk -ComputerName $ComputerName -Filter "DeviceID='C:'" -ErrorAction Stop
        $metrics.diskFreePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
    }
    catch { Write-Log "Could not get disk metrics from $ComputerName" -Level Warning }

    return $metrics
}

function Get-ReplicationPartnerInfo {
    [CmdletBinding()]
    param([string]$ComputerName)

    try {
        $replInfo = Get-ADReplicationPartnerMetadata -Target $ComputerName -ErrorAction Stop
        $partners = @()
        $failedCount = 0

        foreach ($partner in $replInfo) {
            $partnerStatus = "Healthy"
            $failures = $partner.ConsecutiveReplicationFailures
            if ($failures -gt 0 -and $failures -le 3) { $partnerStatus = "Warning" }
            elseif ($failures -gt 3) { $partnerStatus = "Critical"; $failedCount++ }

            $partners += [PSCustomObject]@{
                partnerHostname     = $partner.Partner
                partnerSite         = $partner.PartnerSiteName
                status              = $partnerStatus
                lastReplication     = if ($partner.LastReplicationSuccess) { $partner.LastReplicationSuccess.ToString("o") } else { $null }
                consecutiveFailures = $failures
                lastError           = if ($partner.LastReplicationResult -ne 0) { "Error code: $($partner.LastReplicationResult)" } else { $null }
                namingContext       = $partner.Partition
            }
        }

        $lastSuccess = ($replInfo | Where-Object { $_.LastReplicationSuccess } |
            Sort-Object LastReplicationSuccess -Descending |
            Select-Object -First 1).LastReplicationSuccess

        return @{
            partnerCount               = $replInfo.Count
            failedPartners             = $failedCount
            lastSuccessfulReplication  = if ($lastSuccess) { $lastSuccess.ToString("o") } else { $null }
            pendingChanges             = 0
            partners                   = $partners
        }
    }
    catch {
        Write-Log "Could not get replication info from $ComputerName : $_" -Level Warning
        return @{
            partnerCount               = 0
            failedPartners             = 0
            lastSuccessfulReplication  = $null
            pendingChanges             = 0
            partners                   = @()
        }
    }
}

function Get-OverallHealth {
    [CmdletBinding()]
    param([array]$Checks)

    $statuses = $Checks | ForEach-Object { $_.status }
    if ($statuses -contains "Critical") { return "Critical" }
    if ($statuses -contains "Warning") { return "Warning" }
    if ($statuses -contains "Offline") { return "Offline" }
    return "Healthy"
}

#endregion

#region Main Logic

function Invoke-DCHealthCollection {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    Write-Log "Starting DC Health Snapshot collection" -Level Info

    # Verify ActiveDirectory module
    if (-not (Get-ADModuleAvailable)) {
        throw "ActiveDirectory PowerShell module is not available. Install RSAT or run on a domain controller."
    }

    # Get domain info
    $adParams = @{}
    if ($DomainName) { $adParams["Server"] = $DomainName }
    if ($Credential) { $adParams["Credential"] = $Credential }

    Write-Log "Querying domain information..." -Level Info
    $domain = Get-ADDomain @adParams
    $forest = Get-ADForest @adParams

    $domainInfo = [PSCustomObject]@{
        name            = $domain.DNSRoot
        forestName      = $forest.Name
        functionalLevel = $domain.DomainMode.ToString()
        siteName        = (Get-ADReplicationSite -Filter * @adParams | Select-Object -First 1).Name
        pdcEmulator     = $domain.PDCEmulator
        schemaVersion   = (Get-ADObject (Get-ADRootDSE @adParams).schemaNamingContext -Property objectVersion @adParams).objectVersion
    }

    # Get all domain controllers
    Write-Log "Enumerating domain controllers..." -Level Info
    $dcs = Get-ADDomainController -Filter * @adParams

    $dcResults = @()
    $healthyCount = 0
    $warningCount = 0
    $criticalCount = 0
    $offlineCount = 0
    $replIssues = 0
    $svcIssues = 0

    foreach ($dc in $dcs) {
        Write-Log "Checking health of $($dc.HostName)..." -Level Info

        $checks = @()
        $isOnline = Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet

        if (-not $isOnline) {
            Write-Log "$($dc.HostName) is offline or unreachable" -Level Warning
            $checks += [PSCustomObject]@{
                name      = "DCDiag"
                status    = "Offline"
                message   = "Domain controller is unreachable"
                timestamp = (Get-Date).ToString("o")
            }
            $offlineCount++
            $overallStatus = "Offline"
        }
        else {
            # Run health checks
            # 1. DNS Resolution
            $dnsCheck = Test-DNSResolution -ComputerName $dc.HostName
            $checks += [PSCustomObject]@{
                name      = "DNSResolution"
                status    = $dnsCheck.status
                message   = $dnsCheck.message
                timestamp = (Get-Date).ToString("o")
            }

            # 2. LDAP Connectivity
            $ldapCheck = Test-LDAPConnectivity -ComputerName $dc.HostName
            $checks += [PSCustomObject]@{
                name      = "LDAPConnectivity"
                status    = $ldapCheck.status
                message   = $ldapCheck.message
                timestamp = (Get-Date).ToString("o")
            }

            # 3. Time Sync
            $timeCheck = Test-TimeSyncHealth -ComputerName $dc.HostName
            $checks += [PSCustomObject]@{
                name      = "TimeSync"
                status    = $timeCheck.status
                message   = $timeCheck.message
                timestamp = (Get-Date).ToString("o")
            }

            # 4. DCDiag (optional)
            if (-not $SkipDCDiag) {
                $dcdiagCheck = Get-DCDiagResults -ComputerName $dc.HostName
                $checks += [PSCustomObject]@{
                    name      = "DCDiag"
                    status    = $dcdiagCheck.status
                    message   = $dcdiagCheck.message
                    timestamp = (Get-Date).ToString("o")
                }
            }

            $overallStatus = Get-OverallHealth -Checks $checks
        }

        # Get resource metrics
        $metrics = @{ cpuUsagePercent = $null; memoryUsagePercent = $null; diskFreePercent = $null; uptimeDays = $null }
        if ($isOnline) {
            $metrics = Get-SystemResourceMetrics -ComputerName $dc.HostName

            # Disk space check
            if ($null -ne $metrics.diskFreePercent) {
                $diskStatus = "Healthy"
                $diskMsg = "Disk free: $($metrics.diskFreePercent)%"
                if ($metrics.diskFreePercent -lt 10) { $diskStatus = "Critical"; $diskMsg += " (CRITICAL: below 10%)" }
                elseif ($metrics.diskFreePercent -lt 20) { $diskStatus = "Warning"; $diskMsg += " (below 20%)" }
                $checks += [PSCustomObject]@{
                    name      = "DiskSpace"
                    status    = $diskStatus
                    message   = $diskMsg
                    timestamp = (Get-Date).ToString("o")
                }
            }
        }

        # Get services
        $services = @()
        if ($isOnline) {
            $services = Get-ServiceHealthStatus -ComputerName $dc.HostName
            $stoppedCritical = $services | Where-Object { $_.status -ne "Running" -and $_.startType -eq "Automatic" }
            if ($stoppedCritical) {
                $svcIssues++
                $checks += [PSCustomObject]@{
                    name      = "ServiceHealth"
                    status    = "Critical"
                    message   = "Stopped services: $($stoppedCritical.name -join ', ')"
                    timestamp = (Get-Date).ToString("o")
                }
            }
            else {
                $checks += [PSCustomObject]@{
                    name      = "ServiceHealth"
                    status    = "Healthy"
                    message   = "All critical services running"
                    timestamp = (Get-Date).ToString("o")
                }
            }
        }

        # Get replication info
        $replData = $null
        if ($isOnline) {
            $replData = Get-ReplicationPartnerInfo -ComputerName $dc.HostName
            $replStatus = "Healthy"
            $replMsg = "Replication healthy with $($replData.partnerCount) partner(s)"
            if ($replData.failedPartners -gt 0) {
                $replStatus = "Critical"
                $replMsg = "$($replData.failedPartners) replication partner(s) failing"
                $replIssues++
            }
            $checks += [PSCustomObject]@{
                name      = "ReplicationHealth"
                status    = $replStatus
                message   = $replMsg
                timestamp = (Get-Date).ToString("o")
            }
        }

        # Recalculate overall after all checks
        $overallStatus = Get-OverallHealth -Checks $checks

        switch ($overallStatus) {
            "Healthy"  { $healthyCount++ }
            "Warning"  { $warningCount++ }
            "Critical" { $criticalCount++ }
        }

        # Build DC object
        $dcObj = [ordered]@{
            hostname         = $dc.HostName
            ipAddress        = $dc.IPv4Address
            site             = $dc.Site
            operatingSystem  = $dc.OperatingSystem
            isGlobalCatalog  = $dc.IsGlobalCatalog
            isReadOnly       = $dc.IsReadOnly
            fsmoRoles        = @($dc.OperationMasterRoles | ForEach-Object { $_.ToString() })
            health           = [ordered]@{
                overallStatus      = $overallStatus
                lastChecked        = (Get-Date).ToString("o")
                uptimeDays         = $metrics.uptimeDays
                cpuUsagePercent    = $metrics.cpuUsagePercent
                memoryUsagePercent = $metrics.memoryUsagePercent
                diskFreePercent    = $metrics.diskFreePercent
                checks             = @($checks)
            }
            services         = @($services)
        }

        if ($dc.OperatingSystemVersion) {
            $dcObj["operatingSystemVersion"] = $dc.OperatingSystemVersion
        }

        if ($replData) {
            $dcObj["replication"] = $replData
        }

        $dcResults += [PSCustomObject]$dcObj
    }

    # Build report
    $report = [ordered]@{
        reportId          = New-Guid-String
        generatedAt       = (Get-Date).ToString("o")
        generatedBy       = "$($env:USERDOMAIN)\$($env:USERNAME)"
        schemaVersion     = "1.0.0"
        domain            = $domainInfo
        domainControllers = @($dcResults)
        summary           = [ordered]@{
            totalDCs          = $dcs.Count
            healthyDCs        = $healthyCount
            warningDCs        = $warningCount
            criticalDCs       = $criticalCount
            offlineDCs        = $offlineCount
            replicationIssues = $replIssues
            serviceIssues     = $svcIssues
            overallHealth     = if ($criticalCount -gt 0 -or $offlineCount -gt 0) { "Critical" }
                                elseif ($warningCount -gt 0) { "Warning" }
                                else { "Healthy" }
        }
    }

    return $report
}

# Execute
try {
    if ($PSCmdlet.ShouldProcess("Active Directory Domain Controllers", "Collect health snapshot")) {
        Write-Log "Initiating DC Health Snapshot collection" -Level Info

        $report = Invoke-DCHealthCollection

        # Output to file
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "dc-health-$timestamp.json"
        $fullPath = Join-Path -Path $OutputPath -ChildPath $fileName

        $jsonOutput = $report | ConvertTo-Json -Depth 20
        $jsonOutput | Out-File -FilePath $fullPath -Encoding UTF8

        Write-Log "Report saved to: $fullPath" -Level Info
        Write-Output "DC Health Snapshot saved to: $fullPath"
        Write-Output "Report ID: $($report.reportId)"
        Write-Output "Domain Controllers checked: $($report.summary.totalDCs)"
        Write-Output "Overall Health: $($report.summary.overallHealth)"
    }
}
catch {
    Write-Error "Failed to collect DC Health Snapshot: $_"
    exit 1
}

#endregion
