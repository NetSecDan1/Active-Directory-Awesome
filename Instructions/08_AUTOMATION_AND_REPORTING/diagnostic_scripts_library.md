# Read-Only Diagnostic Scripts Library

## System Prompt

```
You are an expert diagnostician specializing in Active Directory and identity infrastructure.
Your role is to help engineers gather comprehensive diagnostic information safely using
read-only operations that cannot modify the environment.

CORE PRINCIPLES:
1. NEVER modify - all operations must be read-only
2. Comprehensive collection - gather enough data to diagnose without re-running
3. Performance aware - don't overload systems with heavy queries
4. Structured output - produce data that's easy to analyze

SAFETY CLASSIFICATION:
All scripts in this library are [SAFE] - read-only operations only
```

---

## Part 1: Active Directory Diagnostics

### Domain Controller Health Check

```powershell
<#
.SYNOPSIS
    [SAFE] Comprehensive Domain Controller health diagnostic
.DESCRIPTION
    Collects DC health metrics without making any changes
.NOTES
    Risk Level: [SAFE] - Read-only operations only
    Required: Domain Admin or equivalent read permissions
#>

function Get-DCHealthDiagnostic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$DomainControllers,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\DCHealth_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    )

    Write-Host "[SAFE] Starting DC Health Diagnostic - Read-Only Mode" -ForegroundColor Green

    # Get all DCs if not specified
    if (-not $DomainControllers) {
        $DomainControllers = (Get-ADDomainController -Filter *).HostName
    }

    $results = @{
        CollectionTime = Get-Date
        CollectedBy = $env:USERNAME
        Domain = (Get-ADDomain).DNSRoot
        DomainControllers = @()
    }

    foreach ($dc in $DomainControllers) {
        Write-Host "  Checking: $dc" -ForegroundColor Cyan

        $dcResult = @{
            Name = $dc
            Reachable = $false
            DCDiag = @{}
            Replication = @{}
            Services = @{}
            DNS = @{}
            Time = @{}
            Certificates = @{}
            DiskSpace = @{}
            EventLogs = @{}
            Performance = @{}
        }

        try {
            # Test connectivity
            $dcResult.Reachable = Test-Connection -ComputerName $dc -Count 1 -Quiet

            if ($dcResult.Reachable) {

                # DCDiag tests (read-only)
                Write-Host "    Running DCDiag..." -ForegroundColor Gray
                $dcdiagOutput = dcdiag /s:$dc /test:Connectivity /test:Advertising /test:FrsEvent /test:DFSREvent /test:SysVolCheck /test:KccEvent /test:Services /test:Replications 2>&1
                $dcResult.DCDiag = @{
                    RawOutput = $dcdiagOutput | Out-String
                    PassedTests = ($dcdiagOutput | Select-String "passed test" | Measure-Object).Count
                    FailedTests = ($dcdiagOutput | Select-String "failed test" | Measure-Object).Count
                }

                # Replication status
                Write-Host "    Checking replication..." -ForegroundColor Gray
                $replStatus = Get-ADReplicationPartnerMetadata -Target $dc -ErrorAction SilentlyContinue
                $dcResult.Replication = @{
                    Partners = $replStatus | ForEach-Object {
                        @{
                            Partner = $_.Partner
                            LastReplicationAttempt = $_.LastReplicationAttempt
                            LastReplicationSuccess = $_.LastReplicationSuccess
                            LastReplicationResult = $_.LastReplicationResult
                            ConsecutiveFailures = $_.ConsecutiveReplicationFailures
                        }
                    }
                    FailureCount = ($replStatus | Where-Object { $_.LastReplicationResult -ne 0 }).Count
                }

                # Service status
                Write-Host "    Checking services..." -ForegroundColor Gray
                $criticalServices = @('NTDS', 'DNS', 'Netlogon', 'W32Time', 'DFSR', 'KDC', 'IsmServ')
                $dcResult.Services = Invoke-Command -ComputerName $dc -ScriptBlock {
                    param($services)
                    $services | ForEach-Object {
                        $svc = Get-Service -Name $_ -ErrorAction SilentlyContinue
                        @{
                            Name = $_
                            Status = $svc.Status.ToString()
                            StartType = $svc.StartType.ToString()
                        }
                    }
                } -ArgumentList (,$criticalServices) -ErrorAction SilentlyContinue

                # DNS health
                Write-Host "    Checking DNS..." -ForegroundColor Gray
                $dcResult.DNS = @{
                    ResolvesOwnName = [bool](Resolve-DnsName -Name $dc -Server $dc -ErrorAction SilentlyContinue)
                    SRVRecords = @{
                        LDAP = [bool](Resolve-DnsName -Name "_ldap._tcp.$((Get-ADDomain).DNSRoot)" -Type SRV -Server $dc -ErrorAction SilentlyContinue)
                        Kerberos = [bool](Resolve-DnsName -Name "_kerberos._tcp.$((Get-ADDomain).DNSRoot)" -Type SRV -Server $dc -ErrorAction SilentlyContinue)
                        GC = [bool](Resolve-DnsName -Name "_gc._tcp.$((Get-ADForest).RootDomain)" -Type SRV -Server $dc -ErrorAction SilentlyContinue)
                    }
                }

                # Time sync
                Write-Host "    Checking time sync..." -ForegroundColor Gray
                $w32tmOutput = w32tm /query /computer:$dc /status 2>&1 | Out-String
                $dcResult.Time = @{
                    RawOutput = $w32tmOutput
                    Source = ($w32tmOutput | Select-String "Source:" | ForEach-Object { $_.Line.Split(":")[1].Trim() })
                }

                # Disk space
                Write-Host "    Checking disk space..." -ForegroundColor Gray
                $dcResult.DiskSpace = Invoke-Command -ComputerName $dc -ScriptBlock {
                    Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
                        @{
                            Drive = $_.DeviceID
                            SizeGB = [math]::Round($_.Size / 1GB, 2)
                            FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                            FreePercent = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
                        }
                    }
                } -ErrorAction SilentlyContinue

                # Recent critical events
                Write-Host "    Checking event logs..." -ForegroundColor Gray
                $dcResult.EventLogs = Invoke-Command -ComputerName $dc -ScriptBlock {
                    $last24h = (Get-Date).AddHours(-24)
                    @{
                        DirectoryService = Get-WinEvent -FilterHashtable @{
                            LogName = 'Directory Service'
                            Level = 1,2  # Critical, Error
                            StartTime = $last24h
                        } -MaxEvents 10 -ErrorAction SilentlyContinue | ForEach-Object {
                            @{ Time = $_.TimeCreated; Id = $_.Id; Message = $_.Message.Substring(0, [Math]::Min(200, $_.Message.Length)) }
                        }
                        DNS = Get-WinEvent -FilterHashtable @{
                            LogName = 'DNS Server'
                            Level = 1,2
                            StartTime = $last24h
                        } -MaxEvents 10 -ErrorAction SilentlyContinue | ForEach-Object {
                            @{ Time = $_.TimeCreated; Id = $_.Id; Message = $_.Message.Substring(0, [Math]::Min(200, $_.Message.Length)) }
                        }
                    }
                } -ErrorAction SilentlyContinue
            }
        }
        catch {
            $dcResult.Error = $_.Exception.Message
        }

        $results.DomainControllers += $dcResult
    }

    # Summary
    $results.Summary = @{
        TotalDCs = $results.DomainControllers.Count
        ReachableDCs = ($results.DomainControllers | Where-Object { $_.Reachable }).Count
        DCsWithReplicationFailures = ($results.DomainControllers | Where-Object { $_.Replication.FailureCount -gt 0 }).Count
        DCsWithServiceIssues = ($results.DomainControllers | Where-Object {
            $_.Services | Where-Object { $_.Status -ne 'Running' }
        }).Count
        DCsWithLowDiskSpace = ($results.DomainControllers | Where-Object {
            $_.DiskSpace | Where-Object { $_.FreePercent -lt 15 }
        }).Count
    }

    # Output
    $results | ConvertTo-Json -Depth 10 | Out-File $OutputPath
    Write-Host "`nDiagnostic complete. Results saved to: $OutputPath" -ForegroundColor Green

    return $results
}
```

### Replication Diagnostic

```powershell
<#
.SYNOPSIS
    [SAFE] Detailed AD replication diagnostic
.DESCRIPTION
    Analyzes replication topology, latency, and failures
#>

function Get-ReplicationDiagnostic {
    [CmdletBinding()]
    param(
        [string]$OutputPath = ".\ReplicationDiag_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    )

    Write-Host "[SAFE] Starting Replication Diagnostic" -ForegroundColor Green

    $results = @{
        CollectionTime = Get-Date
        Forest = (Get-ADForest).Name
        Sites = @()
        ReplicationLinks = @()
        ReplicationFailures = @()
        PartitionStatus = @()
    }

    # Get site topology
    Write-Host "  Collecting site topology..." -ForegroundColor Gray
    $sites = Get-ADReplicationSite -Filter *
    foreach ($site in $sites) {
        $siteInfo = @{
            Name = $site.Name
            Description = $site.Description
            Subnets = (Get-ADReplicationSubnet -Filter "Site -eq '$($site.DistinguishedName)'" |
                       Select-Object Name, Location).Name
            DomainControllers = (Get-ADDomainController -Filter "Site -eq '$($site.Name)'" |
                                Select-Object Name, IPv4Address).Name
        }
        $results.Sites += $siteInfo
    }

    # Get site links
    Write-Host "  Collecting site links..." -ForegroundColor Gray
    $siteLinks = Get-ADReplicationSiteLink -Filter *
    foreach ($link in $siteLinks) {
        $results.ReplicationLinks += @{
            Name = $link.Name
            Sites = $link.SitesIncluded
            Cost = $link.Cost
            ReplicationFrequencyMinutes = $link.ReplicationFrequencyInMinutes
            Schedule = $link.ReplicationSchedule
        }
    }

    # Get replication failures
    Write-Host "  Checking for replication failures..." -ForegroundColor Gray
    $allDCs = Get-ADDomainController -Filter *
    foreach ($dc in $allDCs) {
        try {
            $failures = Get-ADReplicationFailure -Target $dc.HostName -ErrorAction SilentlyContinue
            foreach ($failure in $failures) {
                $results.ReplicationFailures += @{
                    Server = $failure.Server
                    Partner = $failure.Partner
                    PartitionDN = $failure.PartitionDN
                    FirstFailureTime = $failure.FirstFailureTime
                    FailureCount = $failure.FailureCount
                    LastError = $failure.LastError
                }
            }
        }
        catch {
            Write-Warning "Could not check replication failures on $($dc.HostName): $_"
        }
    }

    # Get partition replication status
    Write-Host "  Checking partition status..." -ForegroundColor Gray
    $partitions = @(
        (Get-ADDomain).DistinguishedName,
        "CN=Configuration,$((Get-ADRootDSE).rootDomainNamingContext)",
        "CN=Schema,CN=Configuration,$((Get-ADRootDSE).rootDomainNamingContext)",
        "DC=DomainDnsZones,$((Get-ADDomain).DistinguishedName)",
        "DC=ForestDnsZones,$((Get-ADRootDSE).rootDomainNamingContext)"
    )

    foreach ($partition in $partitions) {
        try {
            $partitionMeta = Get-ADReplicationPartnerMetadata -Target (Get-ADDomainController).HostName -Partition $partition -ErrorAction SilentlyContinue
            $results.PartitionStatus += @{
                Partition = $partition
                Partners = $partitionMeta | ForEach-Object {
                    @{
                        Partner = $_.Partner
                        LastReplication = $_.LastReplicationSuccess
                        Result = $_.LastReplicationResult
                    }
                }
            }
        }
        catch {
            # Partition may not exist in this context
        }
    }

    # Calculate replication latency
    Write-Host "  Calculating replication latency..." -ForegroundColor Gray
    $results.ReplicationLatency = @{
        MaxLatencyMinutes = 0
        AverageLatencyMinutes = 0
        Measurements = @()
    }

    try {
        # Use repadmin to get more detailed latency info
        $repadminOutput = repadmin /showrepl * /csv 2>&1
        if ($repadminOutput) {
            $results.ReplicationLatency.RawData = $repadminOutput | Out-String
        }
    }
    catch {
        # repadmin may not be available
    }

    # Summary
    $results.Summary = @{
        TotalSites = $results.Sites.Count
        TotalSiteLinks = $results.ReplicationLinks.Count
        TotalFailures = $results.ReplicationFailures.Count
        AffectedPartners = ($results.ReplicationFailures | Select-Object -Unique Partner).Count
        OldestFailure = ($results.ReplicationFailures | Sort-Object FirstFailureTime | Select-Object -First 1).FirstFailureTime
    }

    $results | ConvertTo-Json -Depth 10 | Out-File $OutputPath
    Write-Host "`nReplication diagnostic complete. Results: $OutputPath" -ForegroundColor Green

    return $results
}
```

---

## Part 2: Entra ID Diagnostics

### Sign-In Analysis Diagnostic

```powershell
<#
.SYNOPSIS
    [SAFE] Comprehensive sign-in analysis from Entra ID
.DESCRIPTION
    Analyzes sign-in patterns, failures, and anomalies without modifications
#>

function Get-SignInDiagnostic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$DaysBack = 7,

        [Parameter(Mandatory = $false)]
        [string]$UserPrincipalName,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\SignInDiag_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    )

    Write-Host "[SAFE] Starting Sign-In Diagnostic - Read-Only Mode" -ForegroundColor Green

    # Connect with read-only scopes
    Connect-MgGraph -Scopes "AuditLog.Read.All", "Directory.Read.All" -NoWelcome

    $startDate = (Get-Date).AddDays(-$DaysBack).ToString("yyyy-MM-ddTHH:mm:ssZ")

    $results = @{
        CollectionTime = Get-Date
        AnalysisPeriod = "$DaysBack days"
        TenantId = (Get-MgContext).TenantId
        SignInSummary = @{}
        FailureAnalysis = @{}
        RiskAnalysis = @{}
        LocationAnalysis = @{}
        ApplicationAnalysis = @{}
        UserAnalysis = @{}
    }

    # Build filter
    $filter = "createdDateTime ge $startDate"
    if ($UserPrincipalName) {
        $filter += " and userPrincipalName eq '$UserPrincipalName'"
    }

    Write-Host "  Fetching sign-in logs..." -ForegroundColor Gray
    $signIns = Get-MgAuditLogSignIn -Filter $filter -All

    Write-Host "  Analyzing $(($signIns | Measure-Object).Count) sign-in events..." -ForegroundColor Gray

    # Sign-in summary
    $results.SignInSummary = @{
        TotalSignIns = $signIns.Count
        SuccessfulSignIns = ($signIns | Where-Object { $_.Status.ErrorCode -eq 0 }).Count
        FailedSignIns = ($signIns | Where-Object { $_.Status.ErrorCode -ne 0 }).Count
        UniqueUsers = ($signIns | Select-Object -Unique UserPrincipalName).Count
        UniqueIPs = ($signIns | Select-Object -Unique IpAddress).Count
        UniqueApps = ($signIns | Select-Object -Unique AppDisplayName).Count
        InteractiveSignIns = ($signIns | Where-Object { $_.IsInteractive }).Count
        NonInteractiveSignIns = ($signIns | Where-Object { -not $_.IsInteractive }).Count
    }

    # Failure analysis
    Write-Host "  Analyzing failures..." -ForegroundColor Gray
    $failures = $signIns | Where-Object { $_.Status.ErrorCode -ne 0 }
    $results.FailureAnalysis = @{
        TotalFailures = $failures.Count
        ByErrorCode = $failures | Group-Object { $_.Status.ErrorCode } | ForEach-Object {
            @{
                ErrorCode = $_.Name
                Count = $_.Count
                SampleMessage = ($_.Group | Select-Object -First 1).Status.FailureReason
            }
        } | Sort-Object { $_.Count } -Descending | Select-Object -First 20
        ByUser = $failures | Group-Object UserPrincipalName | ForEach-Object {
            @{
                User = $_.Name
                FailureCount = $_.Count
                ErrorCodes = ($_.Group | Select-Object -Unique { $_.Status.ErrorCode }).'$_.Status.ErrorCode'
            }
        } | Sort-Object { $_.FailureCount } -Descending | Select-Object -First 20
        ByIP = $failures | Group-Object IpAddress | ForEach-Object {
            @{
                IP = $_.Name
                FailureCount = $_.Count
                TargetedUsers = ($_.Group | Select-Object -Unique UserPrincipalName).Count
            }
        } | Sort-Object { $_.FailureCount } -Descending | Select-Object -First 20
    }

    # Risk analysis
    Write-Host "  Analyzing risk signals..." -ForegroundColor Gray
    $riskySignIns = $signIns | Where-Object { $_.RiskLevelAggregated -ne 'none' -and $_.RiskLevelAggregated }
    $results.RiskAnalysis = @{
        TotalRiskySignIns = $riskySignIns.Count
        ByRiskLevel = $riskySignIns | Group-Object RiskLevelAggregated | ForEach-Object {
            @{ Level = $_.Name; Count = $_.Count }
        }
        RiskyUsers = $riskySignIns | Group-Object UserPrincipalName | ForEach-Object {
            @{
                User = $_.Name
                RiskySignIns = $_.Count
                RiskLevels = ($_.Group | Select-Object -Unique RiskLevelAggregated).RiskLevelAggregated
            }
        } | Sort-Object { $_.RiskySignIns } -Descending | Select-Object -First 20
    }

    # Location analysis
    Write-Host "  Analyzing locations..." -ForegroundColor Gray
    $results.LocationAnalysis = @{
        ByCountry = $signIns | Group-Object { $_.Location.CountryOrRegion } | ForEach-Object {
            @{ Country = $_.Name; Count = $_.Count }
        } | Sort-Object { $_.Count } -Descending | Select-Object -First 20
        ByCity = $signIns | Group-Object { $_.Location.City } | ForEach-Object {
            @{ City = $_.Name; Count = $_.Count }
        } | Sort-Object { $_.Count } -Descending | Select-Object -First 20
    }

    # Application analysis
    Write-Host "  Analyzing applications..." -ForegroundColor Gray
    $results.ApplicationAnalysis = @{
        ByApp = $signIns | Group-Object AppDisplayName | ForEach-Object {
            @{
                App = $_.Name
                SignIns = $_.Count
                UniqueUsers = ($_.Group | Select-Object -Unique UserPrincipalName).Count
                FailureRate = [math]::Round(
                    (($_.Group | Where-Object { $_.Status.ErrorCode -ne 0 }).Count / $_.Count) * 100, 1
                )
            }
        } | Sort-Object { $_.SignIns } -Descending | Select-Object -First 20
        LegacyAuth = $signIns | Where-Object {
            $_.ClientAppUsed -notin @('Browser', 'Mobile Apps and Desktop clients')
        } | Group-Object ClientAppUsed | ForEach-Object {
            @{ ClientApp = $_.Name; Count = $_.Count }
        }
    }

    # Anomaly detection
    Write-Host "  Detecting anomalies..." -ForegroundColor Gray
    $results.Anomalies = @{
        # Multiple countries in short time
        ImpossibleTravel = @()
        # High failure rate users
        HighFailureRateUsers = $results.FailureAnalysis.ByUser |
            Where-Object { $_.FailureCount -gt 20 }
        # Suspicious IPs (high failure, multiple users)
        SuspiciousIPs = $results.FailureAnalysis.ByIP |
            Where-Object { $_.FailureCount -gt 50 -and $_.TargetedUsers -gt 5 }
    }

    # User analysis (if specific user requested)
    if ($UserPrincipalName) {
        $userSignIns = $signIns | Where-Object { $_.UserPrincipalName -eq $UserPrincipalName }
        $results.UserAnalysis = @{
            User = $UserPrincipalName
            TotalSignIns = $userSignIns.Count
            SuccessfulSignIns = ($userSignIns | Where-Object { $_.Status.ErrorCode -eq 0 }).Count
            FailedSignIns = ($userSignIns | Where-Object { $_.Status.ErrorCode -ne 0 }).Count
            UniqueIPs = ($userSignIns | Select-Object -Unique IpAddress).Count
            UniqueLocations = ($userSignIns | Select-Object -Unique { $_.Location.City }).Count
            AppsUsed = ($userSignIns | Select-Object -Unique AppDisplayName).AppDisplayName
            RecentFailures = $userSignIns |
                Where-Object { $_.Status.ErrorCode -ne 0 } |
                Sort-Object CreatedDateTime -Descending |
                Select-Object -First 10 |
                ForEach-Object {
                    @{
                        Time = $_.CreatedDateTime
                        ErrorCode = $_.Status.ErrorCode
                        FailureReason = $_.Status.FailureReason
                        IP = $_.IpAddress
                        App = $_.AppDisplayName
                    }
                }
        }
    }

    $results | ConvertTo-Json -Depth 10 | Out-File $OutputPath
    Write-Host "`nSign-in diagnostic complete. Results: $OutputPath" -ForegroundColor Green

    Disconnect-MgGraph
    return $results
}
```

---

## Part 3: Hybrid Identity Diagnostics

### Azure AD Connect Health Check

```powershell
<#
.SYNOPSIS
    [SAFE] Azure AD Connect synchronization diagnostic
.DESCRIPTION
    Analyzes sync status, errors, and configuration without modifications
#>

function Get-AADConnectDiagnostic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$AADConnectServer = $env:COMPUTERNAME,

        [string]$OutputPath = ".\AADConnectDiag_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    )

    Write-Host "[SAFE] Starting AAD Connect Diagnostic" -ForegroundColor Green

    $results = @{
        CollectionTime = Get-Date
        Server = $AADConnectServer
        Configuration = @{}
        SyncStatus = @{}
        ConnectorStatus = @{}
        SyncErrors = @{}
        PasswordSync = @{}
    }

    # Check if running on AAD Connect server
    $isAADCServer = Get-Service -Name "ADSync" -ErrorAction SilentlyContinue

    if (-not $isAADCServer) {
        Write-Warning "ADSync service not found. Run this on the Azure AD Connect server."
        $results.Error = "Not running on AAD Connect server"
        return $results
    }

    Import-Module ADSync -ErrorAction SilentlyContinue

    # Get scheduler status
    Write-Host "  Checking scheduler status..." -ForegroundColor Gray
    $scheduler = Get-ADSyncScheduler
    $results.SyncStatus = @{
        SchedulerEnabled = $scheduler.SyncCycleEnabled
        StagingModeEnabled = $scheduler.StagingModeEnabled
        MaintenanceEnabled = $scheduler.MaintenanceEnabled
        NextSyncCycleTime = $scheduler.NextSyncCycleStartTimeInUTC
        LastSyncTime = $scheduler.LastSyncCycleStartTimeinUTC
        CurrentSyncType = $scheduler.CurrentlyEffectiveSyncCycleType
        SyncInterval = $scheduler.CurrentlyEffectiveSyncCycleInterval
    }

    # Get connector information
    Write-Host "  Checking connectors..." -ForegroundColor Gray
    $connectors = Get-ADSyncConnector
    $results.ConnectorStatus = $connectors | ForEach-Object {
        $connector = $_
        $runProfiles = Get-ADSyncConnectorRunProfile -Connector $_

        @{
            Name = $connector.Name
            Type = $connector.Type
            Enabled = $connector.Enabled
            LastRunProfile = $connector.LatestRunProfile
            RunProfiles = $runProfiles.Name
        }
    }

    # Get sync run history
    Write-Host "  Getting sync history..." -ForegroundColor Gray
    $runHistory = Get-ADSyncRunProfileResult -NumberRequested 20
    $results.SyncHistory = $runHistory | ForEach-Object {
        @{
            ConnectorName = $_.ConnectorName
            RunProfileName = $_.RunProfileName
            StartTime = $_.StartDate
            EndTime = $_.EndDate
            Result = $_.Result
            CountersAD = @{
                Adds = $_.StepResults.ConnectorCounters.FilteredAdds
                Updates = $_.StepResults.ConnectorCounters.FilteredUpdates
                Deletes = $_.StepResults.ConnectorCounters.FilteredDeletes
            }
        }
    }

    # Get sync errors
    Write-Host "  Checking for sync errors..." -ForegroundColor Gray
    $csExportErrors = Get-ADSyncCSExportError
    $results.SyncErrors = @{
        TotalErrors = ($csExportErrors | Measure-Object).Count
        Errors = $csExportErrors | Select-Object -First 50 | ForEach-Object {
            @{
                ConnectorName = $_.ConnectorName
                DistinguishedName = $_.DistinguishedName
                ErrorType = $_.ErrorType
                ErrorCode = $_.ErrorCode
                ErrorDetail = $_.ErrorDetail
            }
        }
    }

    # Password sync status (if enabled)
    Write-Host "  Checking password sync..." -ForegroundColor Gray
    try {
        $pwdSyncState = Get-ADSyncAADPasswordSyncState -ErrorAction SilentlyContinue
        $results.PasswordSync = @{
            Enabled = $true
            LastSyncTime = $pwdSyncState.LastSyncTime
            State = $pwdSyncState.State
        }
    }
    catch {
        $results.PasswordSync = @{
            Enabled = $false
            Note = "Password hash sync may not be enabled or PTA is in use"
        }
    }

    # Get global settings
    Write-Host "  Getting global settings..." -ForegroundColor Gray
    $globalSettings = Get-ADSyncGlobalSettings
    $results.Configuration = @{
        Version = (Get-ADSyncScheduler).SyncCycleVersion
        GlobalSettings = $globalSettings.Parameters | ForEach-Object {
            @{ Name = $_.Name; Value = $_.Value }
        }
    }

    # Summary
    $results.Summary = @{
        SyncEnabled = $results.SyncStatus.SchedulerEnabled
        StagingMode = $results.SyncStatus.StagingModeEnabled
        ConnectorCount = $results.ConnectorStatus.Count
        RecentErrors = $results.SyncErrors.TotalErrors
        LastSuccessfulSync = ($results.SyncHistory |
            Where-Object { $_.Result -eq 'Success' } |
            Select-Object -First 1).EndTime
    }

    $results | ConvertTo-Json -Depth 10 | Out-File $OutputPath
    Write-Host "`nAAD Connect diagnostic complete. Results: $OutputPath" -ForegroundColor Green

    return $results
}
```

---

## Part 4: Quick Diagnostic Commands

### One-Liner Diagnostics

```powershell
# ============================================================================
# QUICK DIAGNOSTIC ONE-LINERS
# All commands are [SAFE] - read-only operations
# ============================================================================

# ----- ACTIVE DIRECTORY -----

# Get all DCs and their status
Get-ADDomainController -Filter * | Select-Object Name, Site, IsGlobalCatalog,
    OperatingSystem, IsReadOnly, Enabled | Format-Table -AutoSize

# Check FSMO role holders
netdom query fsmo

# Quick replication check
repadmin /replsummary

# Get recent AD replication failures
Get-ADReplicationFailure -Target (Get-ADDomainController).HostName |
    Select-Object Server, Partner, FirstFailureTime, FailureCount, LastError

# List stale computer accounts (90+ days)
Get-ADComputer -Filter "LastLogonDate -lt '$((Get-Date).AddDays(-90))'" -Properties LastLogonDate |
    Select-Object Name, LastLogonDate, Enabled | Sort-Object LastLogonDate

# List disabled users still in groups
Get-ADUser -Filter {Enabled -eq $false} -Properties MemberOf |
    Where-Object { $_.MemberOf.Count -gt 1 } |
    Select-Object SamAccountName, @{N='GroupCount';E={$_.MemberOf.Count}}

# Check password policy
Get-ADDefaultDomainPasswordPolicy | Select-Object ComplexityEnabled,
    MinPasswordLength, PasswordHistoryCount, MaxPasswordAge, LockoutThreshold

# Find accounts with "Password Never Expires"
Get-ADUser -Filter {PasswordNeverExpires -eq $true -and Enabled -eq $true} |
    Select-Object SamAccountName, Name | Sort-Object SamAccountName

# Get privileged group membership counts
@('Domain Admins', 'Enterprise Admins', 'Schema Admins', 'Administrators') | ForEach-Object {
    $members = (Get-ADGroupMember -Identity $_ -Recursive -ErrorAction SilentlyContinue | Measure-Object).Count
    [PSCustomObject]@{ Group = $_; MemberCount = $members }
}

# ----- DNS -----

# Check DNS zone health
Get-DnsServerZone | Select-Object ZoneName, ZoneType, DynamicUpdate,
    ReplicationScope | Format-Table -AutoSize

# Check DNS forwarders
Get-DnsServerForwarder | Select-Object IPAddress, ReorderedIPAddress

# ----- SERVICES -----

# Check critical services on all DCs
$DCs = (Get-ADDomainController -Filter *).HostName
$Services = @('NTDS', 'DNS', 'Netlogon', 'W32Time', 'DFSR', 'KDC')
$DCs | ForEach-Object {
    $dc = $_
    Get-Service -ComputerName $dc -Name $Services -ErrorAction SilentlyContinue |
        Select-Object @{N='DC';E={$dc}}, Name, Status
} | Format-Table -AutoSize

# ----- ENTRA ID (Requires Microsoft.Graph) -----

# Quick sign-in failure summary (last 24h)
Connect-MgGraph -Scopes "AuditLog.Read.All" -NoWelcome
Get-MgAuditLogSignIn -Filter "createdDateTime ge $((Get-Date).AddDays(-1).ToString('yyyy-MM-ddTHH:mm:ssZ')) and status/errorCode ne 0" |
    Group-Object { $_.Status.ErrorCode } |
    Select-Object @{N='ErrorCode';E={$_.Name}}, Count |
    Sort-Object Count -Descending | Select-Object -First 10

# Get risky users
Get-MgRiskyUser -Filter "RiskState eq 'atRisk'" |
    Select-Object UserPrincipalName, RiskLevel, RiskState, RiskLastUpdatedDateTime

# MFA registration status summary
Get-MgReportAuthenticationMethodUserRegistrationDetail |
    Group-Object IsMfaRegistered |
    Select-Object @{N='MFARegistered';E={$_.Name}}, Count

# ----- CERTIFICATES -----

# Check DC certificates expiring in 30 days
Get-ChildItem Cert:\LocalMachine\My |
    Where-Object { $_.NotAfter -lt (Get-Date).AddDays(30) -and $_.NotAfter -gt (Get-Date) } |
    Select-Object Subject, NotAfter, Thumbprint

# ----- GROUP POLICY -----

# List GPOs modified in last 7 days
Get-GPO -All | Where-Object { $_.ModificationTime -gt (Get-Date).AddDays(-7) } |
    Select-Object DisplayName, ModificationTime, GpoStatus | Sort-Object ModificationTime -Descending

# Check GPO replication status
Get-GPO -All | ForEach-Object {
    $gpo = $_
    $sysvol = Test-Path "\\$env:USERDNSDOMAIN\SYSVOL\$env:USERDNSDOMAIN\Policies\{$($gpo.Id)}"
    [PSCustomObject]@{
        GPO = $gpo.DisplayName
        SysvolPresent = $sysvol
    }
} | Where-Object { -not $_.SysvolPresent }
```

---

## Quick Reference Card

```
DIAGNOSTIC COMMANDS QUICK REFERENCE

All commands are [SAFE] - Read-Only

DC HEALTH:
dcdiag /v /c /d /e                     # Full DC diagnostics
repadmin /replsummary                   # Replication summary
repadmin /showrepl * /csv              # Detailed replication status

REPLICATION:
repadmin /queue                        # Replication queue
repadmin /showconn                     # Connection objects
Get-ADReplicationFailure -Target DC01  # PowerShell failures

DNS:
dcdiag /test:DNS /DnsAll               # DNS diagnostics
Resolve-DnsName -Name _ldap._tcp.domain.com -Type SRV

KERBEROS:
klist                                  # Current tickets
klist -li 0x3e7                        # System tickets

AD CONNECT:
Get-ADSyncScheduler                    # Sync status
Get-ADSyncConnectorRunStatus           # Current run
Get-ADSyncCSExportError               # Export errors

ENTRA ID:
Get-MgAuditLogSignIn -Top 100         # Recent sign-ins
Get-MgRiskyUser -All                  # Risky users

OUTPUT FORMATS:
| Out-File report.txt                  # Text file
| Export-Csv report.csv -NoTypeInfo    # CSV
| ConvertTo-Json | Out-File report.json # JSON
| ConvertTo-Html | Out-File report.html # HTML
```

---

*Document Version: 1.0*
*Framework: Read-Only Diagnostics Library*
*Risk Level: [SAFE] - All Read-Only Operations*
