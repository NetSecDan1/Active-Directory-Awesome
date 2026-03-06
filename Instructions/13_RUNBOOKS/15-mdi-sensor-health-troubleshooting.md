# Runbook: Microsoft Defender for Identity — Sensor Health Issue Troubleshooting
**Risk**: READ-ONLY (investigation) / LOW-MEDIUM (configuration fixes) | **Estimated Time**: 30-120 minutes
**Requires**: Security Administrator / MDI Administrator, Domain Admin for audit policy changes
**Version**: 1.0 | **Owner**: AD Engineering / Security Operations
**Reference**: [Microsoft Docs — MDI Health Issues](https://learn.microsoft.com/en-us/defender-for-identity/health-alerts)

---

## Overview

MDI sensor health issues surface in the Microsoft Defender XDR portal and directly impact MDI's ability to detect identity-based attacks. A degraded or silent sensor is worse than no sensor — it creates a false sense of security.

**Portal location**: [security.microsoft.com](https://security.microsoft.com) → **Identities** → **Health issues**

Two tabs:
- **Sensor health issues** — problems on a specific sensor/DC
- **Global health issues** — domain-wide configuration or credential problems

**Health issue statuses**:
| Status | Meaning |
|--------|---------|
| **Open** | Active, unresolved |
| **Closed** | Auto-closed when MDI detects the issue is resolved; or manually closed |
| **Suppressed** | Manually suppressed up to 7 days (use for planned maintenance windows only) |

---

## Quick-Reference: All Health Issues

### Sensor Health Issues (per sensor)

| Alert | Severity | Phase |
|-------|----------|-------|
| Sensor service failed to start | **HIGH** | [Phase 1](#phase-1--sensor-service-failed-to-start) |
| Sensor running on unsupported OS | **HIGH** | [Phase 2](#phase-2--unsupported-or-end-of-support-os) |
| Sensor has issues with packet capturing component (WinPcap / bad Npcap) | **HIGH** / Medium | [Phase 3](#phase-3--packet-capture-component-issues-npcapwinpcap) |
| Network configuration mismatch on VMware | **HIGH** | [Phase 4](#phase-4--vmware-network-configuration-mismatch) |
| Sensor stopped communicating | Medium | [Phase 5](#phase-5--sensor-stopped-communicating) |
| Domain controller unreachable by sensor | Medium | [Phase 6](#phase-6--domain-controller-unreachable-by-sensor) |
| Sensor reached a memory resource limit | Medium | [Phase 7](#phase-7--sensor-reached-memory-resource-limit) |
| Capture network adapters disabled/disconnected | Medium | [Phase 8](#phase-8--capture-network-adapters-disabled-or-disconnected) |
| No traffic received from domain controller | Medium | [Phase 9](#phase-9--no-traffic-received-from-domain-controller) |
| Some network traffic could not be analyzed | Medium | [Phase 10](#phase-10--some-network-traffic-could-not-be-analyzed) |
| Some Windows events are not being analyzed | Medium | [Phase 11](#phase-11--some-windows-events-are-not-being-analyzed) |
| Some ETW events are not being analyzed | Medium | [Phase 12](#phase-12--some-etw-events-are-not-being-analyzed) |
| NTLM Auditing is not enabled | Medium | [Phase 13](#phase-13--ntlm-auditing-not-enabled) |
| Directory Services Advanced Auditing not enabled | Medium | [Phase 14](#phase-14--directory-services-advanced-auditing-not-enabled) |
| Auditing for AD CS servers not enabled | Medium | [Phase 15](#phase-15--ad-cs-auditing-not-enabled) |
| Sensor failed to retrieve Entra Connect configuration | Medium | [Phase 16](#phase-16--sensor-failed-to-retrieve-entra-connect-configuration) |
| Sensor v3.x RPC Audit Misconfigured | Medium | [Phase 17](#phase-17--sensor-v3x-rpc-audit-misconfigured) |
| Sensor running on OS soon to become unsupported | Medium | [Phase 2](#phase-2--unsupported-or-end-of-support-os) |
| Sensor outdated | Medium | [Phase 18](#phase-18--sensor-outdated) |
| Power mode not configured for optimal performance | Low | [Phase 19](#phase-19--power-mode-not-optimal) |
| Low success rate of active name resolution | Low | [Phase 20](#phase-20--low-success-rate-of-active-name-resolution) |
| Sensor failed to write to the custom log path | Low | [Phase 21](#phase-21--sensor-failed-to-write-to-custom-log-path) |

### Global Health Issues (domain-wide)

| Alert | Severity | Phase |
|-------|----------|-------|
| Read-only user password expired | **HIGH** | [Phase 22](#phase-22--directory-service-account-password-expired-or-expiring) |
| Directory services user credentials are incorrect | Medium | [Phase 23](#phase-23--directory-services-user-credentials-incorrect) |
| Read-only user password to expire shortly | Medium | [Phase 22](#phase-22--directory-service-account-password-expired-or-expiring) |
| Directory Services Object Auditing not enabled | Medium | [Phase 24](#phase-24--directory-services-object-auditing-not-enabled) |
| Auditing on the Configuration container not enabled | Medium | [Phase 25](#phase-25--auditing-on-configuration-container-not-enabled) |
| Auditing on the ADFS container not enabled | Medium | [Phase 26](#phase-26--auditing-on-adfs-container-not-enabled) |
| Radius accounting data ingestion failures (VPN) | Low | [Phase 27](#phase-27--radius-accounting-vpn-data-ingestion-failures) |

---

## Phase 0 — General Diagnostic Approach

Before troubleshooting any specific alert:

```powershell
# ── Identify which sensor/DC is affected ──────────────────────────────────
# In the portal: Identities → Health issues → click the alert
# Note: Sensor name, DC hostname, sensor version, when first seen

# ── Check MDI sensor service status on the affected DC ────────────────────
$targetDC = "DC01"   # Replace with actual DC name
Get-Service -ComputerName $targetDC -Name AATPSensor, AATPSensorUpdater |
    Select-Object MachineName, Name, Status, StartType | Format-Table -AutoSize

# ── Check MDI sensor version on the affected DC ───────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Where-Object { $_.DisplayName -like "*Azure Advanced Threat Protection Sensor*" -or
                       $_.DisplayName -like "*Defender for Identity Sensor*" } |
        Select-Object DisplayName, DisplayVersion
}

# ── MDI sensor log location ───────────────────────────────────────────────
# Logs at: C:\ProgramData\Microsoft\Microsoft.Tri.Sensor\Deployment\Logs\
# Main log: Microsoft.Tri.Sensor-YYYY-MM-DD.log
# Read the most recent log on the affected DC:
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    $logPath = "C:\ProgramData\Microsoft\Microsoft.Tri.Sensor\Deployment\Logs"
    $latestLog = Get-ChildItem $logPath -Filter "Microsoft.Tri.Sensor-*.log" |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Write-Host "Latest log: $($latestLog.FullName)"
    Get-Content $latestLog.FullName -Tail 50  # Last 50 lines
}
```

---

## Phase 1 — Sensor Service Failed to Start

**Severity**: HIGH | The sensor service failed to start for ≥ 30 minutes. No detections from this DC.

```powershell
$targetDC = "DC01"

# ── Step 1: Check Windows Event Log for service start failure ─────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    Get-WinEvent -FilterHashtable @{
        LogName   = 'System'
        StartTime = (Get-Date).AddHours(-2)
        Id        = @(7000, 7009, 7011, 7023, 7031, 7034)  # Service control manager errors
    } -ErrorAction SilentlyContinue |
    Where-Object { $_.Message -like "*AATPSensor*" -or $_.Message -like "*Defender for Identity*" } |
    Format-Table TimeCreated, Id, Message -AutoSize -Wrap
}

# ── Step 2: Read MDI sensor log for root cause ────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    $logPath = "C:\ProgramData\Microsoft\Microsoft.Tri.Sensor\Deployment\Logs"
    Get-ChildItem $logPath -Filter "*.log" | Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 | Get-Content | Select-String -Pattern "Error|Exception|fail" |
        Select-Object -Last 30
}

# ── Step 3: Check gMSA prerequisites (most common cause) ─────────────────
# Verify the gMSA account is correctly configured
$gmsaAccount = "mdiSvc01$"   # Replace with your MDI gMSA name
Get-ADServiceAccount $gmsaAccount -Properties PrincipalsAllowedToRetrieveManagedPassword |
    Select-Object Name, Enabled, PrincipalsAllowedToRetrieveManagedPassword | Format-List

# Verify the DC can retrieve the gMSA password:
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    Test-ADServiceAccount $using:gmsaAccount
    # True = OK, False = DC cannot retrieve gMSA password
}

# ── Step 4: Verify "Log on as a service" right ────────────────────────────
# Check via GPO or Local Security Policy that the MDI service account has this right
# secpol.msc → Local Policies → User Rights Assignment → Log on as a service

# ── Step 5: Manually restart the sensor services ─────────────────────────
# WRITE OPERATION — LOW RISK — run on affected DC
# Invoke-Command -ComputerName $targetDC -ScriptBlock {
#     Restart-Service AATPSensorUpdater -Force
#     Start-Sleep -Seconds 5
#     Start-Service AATPSensor
# }
```

**Common root causes and fixes**:
| Root Cause | Evidence in Log | Fix |
|-----------|----------------|-----|
| gMSA can't retrieve password | `Failed to retrieve gMSA credentials` | Grant DC computer account rights on gMSA; `klist -li 0x3e7 purge` then restart |
| Missing "Log on as a service" right | `Logon failure: the user has not been granted the requested logon type` | Add MDI service account to GPO right |
| Registry access denied | `Access to registry key denied` | Check ACLs on `HKLM\SOFTWARE\Microsoft\AAD\` |
| TLS 1.2 not enabled | `TLS handshake failed` | Enable TLS 1.2 on DC; see [MDI prerequisites](https://aka.ms/mdi/prereqs) |
| Conflicting security software | `File locked by another process` | Exclude MDI paths from AV/EDR |

---

## Phase 2 — Unsupported or End-of-Support OS

**Severity**: HIGH (unsupported) / Medium (nearing EOL)

```powershell
# ── Check OS version on the affected DC ───────────────────────────────────
$targetDC = "DC01"
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    $os = Get-CimInstance Win32_OperatingSystem
    [PSCustomObject]@{
        Caption       = $os.Caption
        Version       = $os.Version
        BuildNumber   = $os.BuildNumber
        ServicePack   = $os.ServicePackMajorVersion
        InstallDate   = $os.InstallDate
    }
} | Format-List

# ── Audit all DCs for OS version ──────────────────────────────────────────
Get-ADDomainController -Filter * | ForEach-Object {
    $dc = $_.HostName
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ComputerName $dc -ErrorAction Stop
        [PSCustomObject]@{
            DC         = $dc
            OS         = $os.Caption
            Version    = $os.Version
            BuildNumber = $os.BuildNumber
        }
    } catch {
        [PSCustomObject]@{ DC=$dc; OS="UNREACHABLE" }
    }
} | Format-Table -AutoSize
```

**Supported OS for MDI sensor** (as of 2026): Windows Server 2016, 2019, 2022, 2025.
Windows Server 2012 / 2012 R2 reached EOL October 10, 2023 — MDI sensor is unsupported.

**Resolution**: Upgrade the DC OS. Until upgrade is possible, MDI detections from that DC are unreliable and unsupported. Reference: [aka.ms/mdi/os](https://aka.ms/mdi/os)

---

## Phase 3 — Packet Capture Component Issues (Npcap/WinPcap)

**Severity**: HIGH (WinPcap or misconfigured Npcap) / Medium (old Npcap version)

```powershell
$targetDC = "DC01"

# ── Check which packet capture driver is installed ────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    # Check for WinPcap (unsupported — must be replaced)
    $winpcap = Get-ItemProperty "HKLM:\SOFTWARE\WinPcap" -ErrorAction SilentlyContinue
    if ($winpcap) { Write-Host "WinPcap INSTALLED — must be replaced with Npcap" -ForegroundColor Red }

    # Check for Npcap
    $npcap = Get-ItemProperty "HKLM:\SOFTWARE\Npcap" -ErrorAction SilentlyContinue
    if ($npcap) {
        Write-Host "Npcap installed: version $($npcap.ProductVersion)" -ForegroundColor Green
    } else {
        Write-Host "Npcap NOT installed" -ForegroundColor Red
    }

    # Check via installed programs
    Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                     "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Where-Object { $_.DisplayName -like "*npcap*" -or $_.DisplayName -like "*winpcap*" } |
        Select-Object DisplayName, DisplayVersion, InstallDate | Format-Table -AutoSize
}

# ── Verify Npcap service is running ───────────────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    Get-Service -Name npcap -ErrorAction SilentlyContinue |
        Select-Object Name, Status, StartType | Format-Table -AutoSize
}
```

**Fix matrix**:
| Alert Sub-Type | Required Action |
|---------------|-----------------|
| WinPcap installed | Uninstall WinPcap → Install Npcap with required options. Follow: [aka.ms/mdi/npcap](https://aka.ms/mdi/npcap) |
| Npcap version < 1.0 | Upgrade Npcap to current version. MDI v2.184+ auto-installs Npcap 1.0 OEM |
| Npcap misconfigured | Reinstall Npcap with correct options (WinPcap API-compatible mode, loopback adapter) |

**Note**: MDI v2.184+ automatically installs and manages Npcap 1.0 OEM. If running a current MDI version and still seeing this — force a sensor update first (Phase 18).

---

## Phase 4 — VMware Network Configuration Mismatch

**Severity**: HIGH | Affects all VMware-hosted DCs. Causes packet capture failures and missed detections.

```powershell
$targetDC = "DC01"  # A VMware-hosted DC

# ── Check NIC offload settings on the Guest OS ────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    # List all network adapters and their offload settings
    Get-NetAdapterAdvancedProperty | Where-Object {
        $_.DisplayName -match "Large Send Offload|LSO|TSO|Offload"
    } | Select-Object Name, DisplayName, DisplayValue | Format-Table -AutoSize
}

# ── Check via Get-NetAdapter ───────────────────────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    Get-NetAdapterLso | Select-Object Name, IPv4Enabled, IPv6Enabled | Format-Table -AutoSize
}
```

**Required settings** (disable on the Guest OS NIC, NOT in the VMware hypervisor):

```powershell
# ── Fix: Disable LSO/TSO offload on Guest OS (WRITE — LOW RISK) ──────────
# Run on the affected VMware-hosted DC:

# Option A: Via PowerShell (requires the NIC adapter name)
# Disable-NetAdapterLso -Name "Ethernet0" -IPv4 -IPv6   # Replace adapter name

# Option B: Manually via Device Manager
# Network Adapter → Properties → Advanced tab:
#   - "Large Send Offload V2 (IPv4)"  → Disabled
#   - "Large Send Offload V2 (IPv6)"  → Disabled
#   - "IPv4 TSO Offload"              → Disabled (if present)
#   - "IPv6 TSO Offload"              → Disabled (if present)

# Restart the sensor after disabling:
# Restart-Service AATPSensor -Force
```

Reference: [aka.ms/mdi/vmware-sensor-issue](https://aka.ms/mdi/vmware-sensor-issue)

---

## Phase 5 — Sensor Stopped Communicating

**Severity**: Medium | No communication received for > 5 minutes. Sensor may be offline or connectivity to MDI cloud blocked.

```powershell
$targetDC = "DC01"

# ── Step 1: Is the sensor service running? ───────────────────────────────
Get-Service -ComputerName $targetDC -Name AATPSensor, AATPSensorUpdater |
    Select-Object MachineName, Name, Status | Format-Table -AutoSize

# ── Step 2: Can the sensor reach the MDI cloud endpoints? ─────────────────
# MDI cloud endpoint: <workspace-name>.atp.azure.com
# Replace <workspace-name> with your tenant's MDI workspace name (found in MDI settings)
$mdiEndpoint = "contoso.atp.azure.com"   # Replace with your workspace endpoint

Invoke-Command -ComputerName $targetDC -ScriptBlock {
    param($endpoint)
    # Test HTTPS to MDI cloud
    $result = Test-NetConnection -ComputerName $endpoint -Port 443 -WarningAction SilentlyContinue
    Write-Host "MDI cloud ($endpoint) port 443: $(if ($result.TcpTestSucceeded) { 'REACHABLE' } else { 'BLOCKED' })"

    # Test DNS resolution of MDI endpoint
    try {
        $resolved = Resolve-DnsName $endpoint -ErrorAction Stop
        Write-Host "DNS resolution OK: $($resolved[0].IPAddress)"
    } catch {
        Write-Host "DNS resolution FAILED for $endpoint" -ForegroundColor Red
    }
} -ArgumentList $mdiEndpoint

# ── Step 3: Check for proxy configuration issues ──────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    # Check WinHTTP proxy (MDI sensor uses WinHTTP)
    netsh winhttp show proxy
    # "Direct access (no proxy server)" = no proxy configured
    # If proxy is listed: verify it allows traffic to *.atp.azure.com
}

# ── Step 4: Check firewall — required outbound rules ─────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    # MDI requires outbound HTTPS (443) to:
    # *.atp.azure.com — MDI cloud service
    # *.microsoftonline.com — Azure AD auth
    # *.aadrm.com — Rights management
    Test-NetConnection "login.microsoftonline.com" -Port 443 -WarningAction SilentlyContinue |
        Select-Object ComputerName, TcpTestSucceeded | Format-Table -AutoSize
}
```

---

## Phase 6 — Domain Controller Unreachable by Sensor

**Severity**: Medium | Sensor has limited functionality — cannot perform LDAP queries against the DC.

```powershell
$sensorDC = "DC01"   # The DC where the sensor is installed
$targetDC = "DC02"   # The DC that is unreachable

# ── Test LDAP connectivity from sensor DC to target DC ────────────────────
Invoke-Command -ComputerName $sensorDC -ScriptBlock {
    param($target)
    Test-NetConnection $target -Port 389  -WarningAction SilentlyContinue | Select-Object ComputerName, TcpTestSucceeded
    Test-NetConnection $target -Port 3268 -WarningAction SilentlyContinue | Select-Object ComputerName, TcpTestSucceeded
    Test-NetConnection $target -Port 636  -WarningAction SilentlyContinue | Select-Object ComputerName, TcpTestSucceeded
} -ArgumentList $targetDC

# ── Verify the Directory Service account can bind to the DC ───────────────
# Test LDAP bind from the sensor DC:
Invoke-Command -ComputerName $sensorDC -ScriptBlock {
    param($target)
    $conn = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$target")
    try {
        $name = $conn.Name
        Write-Host "LDAP bind to $target succeeded: $name" -ForegroundColor Green
    } catch {
        Write-Host "LDAP bind to $target FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
} -ArgumentList $targetDC

# ── Check if a DS account is configured for this DC's forest ─────────────
# In MDI portal: Settings → Identities → Directory Service Accounts
# Verify an account is configured for the forest containing this DC
# This is required for every forest MDI monitors
```

---

## Phase 7 — Sensor Reached Memory Resource Limit

**Severity**: Medium | MDI sensor self-limited to protect DC from low-memory condition. Partial monitoring only.

```powershell
$targetDC = "DC01"

# ── Check current memory usage on DC ─────────────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    $os = Get-CimInstance Win32_OperatingSystem
    [PSCustomObject]@{
        TotalRAM_GB     = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        FreeRAM_GB      = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        UsedRAM_Pct     = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
        CommittedMB     = [math]::Round((Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory).CommittedBytes / 1MB, 0)
    }
} | Format-List

# ── Check MDI sensor memory consumption ───────────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    Get-Process -Name "Microsoft.Tri.Sensor", "AATPSensor" -ErrorAction SilentlyContinue |
        Select-Object Name, Id,
            @{N='WorkingSetMB'; E={ [math]::Round($_.WorkingSet64 / 1MB, 0) }},
            @{N='PrivateMemMB'; E={ [math]::Round($_.PrivateMemorySize64 / 1MB, 0) }}
}

# ── MDI minimum memory requirements ───────────────────────────────────────
# DC with MDI sensor should have:
# Minimum: 6 GB RAM (for MDI sensor + DC)
# Recommended: 8+ GB RAM
# MDI limits its own memory usage to protect DC performance
```

**Resolution**: Add RAM to the DC, or install MDI sensor on a dedicated standalone sensor server and use port mirroring to feed it DC traffic.

---

## Phase 8 — Capture Network Adapters Disabled or Disconnected

**Severity**: Medium | Traffic from one or more DCs is not being captured.

```powershell
$targetDC = "DC01"

# ── Check NIC status ──────────────────────────────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    Get-NetAdapter | Select-Object Name, InterfaceDescription, Status,
        MacAddress, LinkSpeed | Format-Table -AutoSize
}

# ── Cross-reference with MDI sensor configuration ─────────────────────────
# In MDI portal: Settings → Sensors → [sensor name] → Edit
# Check which NICs are selected for packet capture
# Any NIC listed in the sensor config must show Status = "Up" in the output above

# ── Re-enable a disabled NIC (WRITE — LOW RISK) ──────────────────────────
# Invoke-Command -ComputerName $targetDC -ScriptBlock {
#     Enable-NetAdapter -Name "Ethernet0" -Confirm:$false
# }
```

---

## Phase 9 — No Traffic Received from Domain Controller

**Severity**: Medium | Applies to standalone sensor deployments with port mirroring. No packets arriving.

```powershell
$standaloneServer = "MDI-SENSOR-01"  # Your standalone sensor server

# ── Verify port mirror traffic is arriving ────────────────────────────────
Invoke-Command -ComputerName $standaloneServer -ScriptBlock {
    # Check if the capture NIC has any traffic counter activity
    Get-NetAdapterStatistics | Select-Object Name, ReceivedBytes, ReceivedPackets |
        Format-Table -AutoSize
    # If ReceivedPackets = 0 or not incrementing → port mirror traffic not arriving
}

# ── Check for RSC (Receive Segment Coalescing) — must be disabled on capture NIC ──
Invoke-Command -ComputerName $standaloneServer -ScriptBlock {
    Get-NetAdapterRsc | Select-Object Name, IPv4Enabled, IPv6Enabled | Format-Table -AutoSize
    # Both should be Disabled on the capture NIC
}
```

**Resolution checklist**:
```
□ Port mirroring configured on the switch/hypervisor (SPAN/RSPAN/ERSPAN)
□ Source ports = DC NIC(s); Destination port = Standalone sensor capture NIC
□ Capture NIC on standalone sensor is dedicated to capture (no IP address required)
□ RSC disabled on capture NIC: Disable-NetAdapterRsc -Name "CaptureNIC" -IPv4 -IPv6
□ RSC (IPv4) and RSC (IPv6) both disabled in Advanced NIC settings
```

---

## Phase 10 — Some Network Traffic Could Not Be Analyzed

**Severity**: Medium | Sensor receiving more traffic than it can process. Some detections may be missed.

```powershell
$targetDC = "DC01"

# ── Check CPU and memory headroom ─────────────────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    $cpu = (Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
    $os  = Get-CimInstance Win32_OperatingSystem
    $freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    Write-Host "CPU avg load: $cpu%"
    Write-Host "Free RAM: $freeMem GB"
}

# ── VMware check: verify LSO/TSO offload is disabled ─────────────────────
# If this is a VMware VM, LSO/TSO can cause inflated traffic volumes
# → See Phase 4 for remediation
```

**Resolution options**:
1. Add CPU cores / RAM to the DC
2. If VMware: disable LSO/TSO offload (Phase 4) — often fixes this without hardware changes
3. If standalone sensor: reduce number of DCs mirrored per sensor

---

## Phase 11 — Some Windows Events Are Not Being Analyzed

**Severity**: Medium | Event volume exceeds sensor processing capacity. Detection gaps possible.

```powershell
$targetDC = "DC01"

# ── Check event log volume ────────────────────────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    # How many security events in the last hour?
    $count = (Get-WinEvent -FilterHashtable @{
        LogName   = 'Security'
        StartTime = (Get-Date).AddHours(-1)
    } -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "Security events in last hour: $count"
    # Very high volumes (>50,000/hr) can overwhelm sensors
}

# ── Check CPU/RAM (same as Phase 10) ─────────────────────────────────────
```

**Resolution**:
- Add CPU / RAM to the DC
- Review audit policy — if noisy/verbose policies are enabled beyond MDI requirements, tune them down
- For standalone sensors: reduce number of event-forwarding sources

---

## Phase 12 — Some ETW Events Are Not Being Analyzed

**Severity**: Medium | ETW event volume exceeds sensor processing capacity.

```powershell
$targetDC = "DC01"

# ── Check current ETW provider load ───────────────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    # Check for active ETW sessions
    logman query -ets | Select-String "AATPEtw|DefenderForIdentity"
}

# ── Check CPU/RAM utilization ─────────────────────────────────────────────
# Same as Phase 10 — ETW event drops are always a resource problem
```

**Resolution**: Add CPU / RAM. This is always a resource capacity issue.

---

## Phase 13 — NTLM Auditing Not Enabled

**Severity**: Medium | Without NTLM auditing (Event ID 8004), MDI cannot detect NTLM-based attacks. Validated daily.

```powershell
$targetDC = "DC01"

# ── Verify current NTLM audit configuration ────────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    # Check the three required NTLM audit registry values
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
    $ntlmKeys = @(
        "AuditNtlmInDomain",
        "RestrictSendingNTLMTraffic",
        "DCAllowedNTLMServers"
    )
    foreach ($key in $ntlmKeys) {
        $val = (Get-ItemProperty $regPath -Name $key -ErrorAction SilentlyContinue).$key
        Write-Host "$key = $val"
    }

    # Also check Security policy audit:
    auditpol /get /subcategory:"Network Policy Server" 2>$null
}

# ── Check NTLM audit GPO settings using RSOP ─────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    # Run gpresult and filter for NTLM policy
    gpresult /R /SCOPE COMPUTER 2>&1 | Select-String -Pattern "NTLM|Network security"
}
```

**Required GPO settings** (Computer Configuration → Windows Settings → Security Settings → Local Policies → Security Options):

| Policy | Required Value |
|--------|---------------|
| Network security: Restrict NTLM: Audit NTLM authentication in this domain | Enable all |
| Network security: Restrict NTLM: Outgoing NTLM traffic to remote servers | Audit all |
| Network security: Restrict NTLM: Audit Incoming NTLM Traffic | Enable auditing for all accounts |

Reference: [Configure NTLM Auditing](https://learn.microsoft.com/en-us/defender-for-identity/configure-windows-event-collection#configure-ntlm-auditing)

---

## Phase 14 — Directory Services Advanced Auditing Not Enabled

**Severity**: Medium | Required Advanced Audit Policy subcategories missing. Validated daily.

```powershell
$targetDC = "DC01"

# ── Check Advanced Audit Policy configuration ──────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    auditpol /get /category:* | Where-Object { $_ -match "Credential|Account|Logon|Directory|Privilege|Policy" }
}

# ── Required subcategories and expected settings ──────────────────────────
# auditpol output should show "Success and Failure" or at minimum "Success" for:
# Account Logon → Credential Validation          (Success and Failure)
# Account Management → Computer Account Management (Success)
# Account Management → Distribution Group Management (Success)
# Account Management → Other Account Management Events (Success)
# Account Management → Security Group Management  (Success)
# Account Management → User Account Management    (Success and Failure)
# DS Access → Directory Service Access            (Success and Failure)
# DS Access → Directory Service Changes           (Success and Failure)
# Logon/Logoff → Account Lockout                  (Failure)
# Logon/Logoff → Logon                            (Success and Failure)
# Policy Change → Audit Policy Change             (Success)
# Privilege Use → Sensitive Privilege Use         (Success and Failure)
# System → Security System Extension              (Success)

# ── Quick: check DS Access subcategories specifically ─────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    auditpol /get /subcategory:"Directory Service Access","Directory Service Changes",
                               "Directory Service Replication","Detailed Directory Service Replication"
}
```

Reference: [Configure audit policies](https://learn.microsoft.com/en-us/defender-for-identity/configure-windows-event-collection)

---

## Phase 15 — AD CS Auditing Not Enabled

**Severity**: Medium | Auditing not configured on Active Directory Certificate Services. Validated daily.

```powershell
$adcsServer = "PKI-CA01"   # Replace with your CA server name

# ── Check CA audit filter ─────────────────────────────────────────────────
Invoke-Command -ComputerName $adcsServer -ScriptBlock {
    # Check current audit filter
    certutil -getreg CA\AuditFilter
    # Expected: AuditFilter REG_DWORD = 0x7f (127 decimal = all events audited)
    # If 0x0 or missing: auditing is disabled
}

# ── Check Advanced Audit Policy on the CA server ──────────────────────────
Invoke-Command -ComputerName $adcsServer -ScriptBlock {
    auditpol /get /subcategory:"Certification Services"
    # Expected: Success and Failure
}
```

**Fix** (WRITE — LOW RISK — run on the CA server):
```powershell
# Enable all AD CS audit events:
# certutil -setreg CA\AuditFilter 127
# Restart-Service certsvc

# Enable audit policy via GPO or:
# auditpol /set /subcategory:"Certification Services" /success:enable /failure:enable
```

Reference: [Configure auditing on AD CS](https://learn.microsoft.com/en-us/defender-for-identity/configure-windows-event-collection#configure-auditing-on-ad-cs)

---

## Phase 16 — Sensor Failed to Retrieve Entra Connect Configuration

**Severity**: Medium | Applies only to servers running Microsoft Entra Connect (Azure AD Connect).

```powershell
$entraConnectServer = "ENTRACONN01"   # Replace with Entra Connect server name

# ── Check Microsoft Azure AD Sync service status ──────────────────────────
Get-Service -ComputerName $entraConnectServer -Name ADSync |
    Select-Object MachineName, Status, StartType | Format-Table -AutoSize

# ── Verify sensor has access to the ADSync database ──────────────────────
# The MDI sensor on this server needs access to the local ADSync SQL DB
# Check: does the MDI service account have db_datareader on the ADSync database?
Invoke-Command -ComputerName $entraConnectServer -ScriptBlock {
    # Check ADSync DB connection string (read-only, no sensitive data exposed here)
    $configPath = "C:\ProgramFiles\Microsoft Azure Active Directory Connect\AzureADConnect.exe.config"
    if (Test-Path $configPath) {
        Select-String "connectionString|ADSync" $configPath | Select-Object -First 5
    }

    # Check SQL instance being used
    Get-Service -Name "ADSync" | ForEach-Object {
        Get-CimInstance Win32_Service -Filter "Name='ADSync'" | Select-Object Name, PathName
    }
}
```

**Common causes**:
| Cause | Fix |
|-------|-----|
| ADSync service stopped | `Start-Service ADSync` on Entra Connect server |
| MDI sensor account lacks DB rights | Grant `db_datareader` role to MDI service account on ADSync DB |
| ADSync DB moved after upgrade | Re-grant permissions after Entra Connect upgrade |

Reference: [Entra Connect SQL connectivity troubleshooting](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/tshoot-connect-tshoot-sql-connectivity)

---

## Phase 17 — Sensor v3.x RPC Audit Misconfigured

**Severity**: Medium | Applies only to MDI sensor v3.x. RPC audit tag not applied or incorrectly applied.

```powershell
# ── This is a portal-side configuration — check in Defender XDR ──────────
# Portal: security.microsoft.com → Settings → Identities → Asset rule management
# Verify the "Unified Sensor RPC Audit" tag is applied to the affected sensor/DC

# ── Verify the tag is applied (PowerShell via MDE/MDI API is limited for this) ──────────
# Best verified in the portal UI under:
# Settings → Identities → Sensors → [affected sensor] → Tags
```

Reference: [Configure RPC on v3.x sensors](https://learn.microsoft.com/en-us/defender-for-identity/deploy/prerequisites-sensor-version-3#configure-rpc-on-v3x-sensors-to-support-advanced-identity-detections)

---

## Phase 18 — Sensor Outdated

**Severity**: Medium | Sensor is too many versions behind to communicate with MDI cloud. No detections.

```powershell
$targetDC = "DC01"

# ── Check current sensor version ─────────────────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
        Where-Object { $_.DisplayName -like "*Azure Advanced Threat Protection*" -or
                       $_.DisplayName -like "*Defender for Identity*" } |
        Select-Object DisplayName, DisplayVersion | Format-Table -AutoSize
}

# ── Check if auto-update service is running ───────────────────────────────
Get-Service -ComputerName $targetDC -Name AATPSensorUpdater |
    Select-Object MachineName, Name, Status | Format-Table -AutoSize

# ── Check if auto-update can reach the update service ────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    Test-NetConnection "sensor.atp.azure.com" -Port 443 -WarningAction SilentlyContinue |
        Select-Object ComputerName, TcpTestSucceeded
}
```

**Manual update steps** (if auto-update is broken):
1. Download latest sensor installer from **Defender XDR portal → Settings → Identities → Sensors → Download sensor** (access key included)
2. Run installer on the DC — it upgrades in place, no uninstall needed
3. Restart sensor services if prompted

---

## Phase 19 — Power Mode Not Optimal

**Severity**: Low | Power plan set to Balanced or Power Saver. Can throttle CPU and reduce sensor performance.

```powershell
$targetDC = "DC01"

# ── Check current power plan ──────────────────────────────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    $plan = powercfg /getactivescheme
    Write-Host "Active power scheme: $plan"
    # Expected: GUID 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c = High performance
    # Problem:  GUID 381b4222-f694-41f0-9685-ff5bb260df2e = Balanced
}

# ── Fix: Set High Performance power plan (WRITE — LOW RISK) ──────────────
# Invoke-Command -ComputerName $targetDC -ScriptBlock {
#     powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
#     # Or set via GPO: Computer Config → Administrative Templates → System → Power Management
# }
```

---

## Phase 20 — Low Success Rate of Active Name Resolution

**Severity**: Low | Sensor failing to resolve IP → hostname >90% of the time via NTLM/RPC, NetBIOS, or reverse DNS.

```powershell
$targetDC = "DC01"

# ── Test RPC/NTLM name resolution (port 135) ──────────────────────────────
# Sensor uses NTLM over RPC (port 135) as primary resolution method
# Test from the DC to a few workstations:
$testIPs = @("10.0.0.50", "10.0.0.51")  # Replace with client IPs in your environment
foreach ($ip in $testIPs) {
    $result = Test-NetConnection -ComputerName $ip -Port 135 -WarningAction SilentlyContinue
    Write-Host "Port 135 to $ip`: $(if ($result.TcpTestSucceeded) { 'OPEN' } else { 'BLOCKED' })"
}

# ── Test reverse DNS lookup ───────────────────────────────────────────────
foreach ($ip in $testIPs) {
    try {
        $name = [System.Net.Dns]::GetHostEntry($ip).HostName
        Write-Host "PTR $ip → $name" -ForegroundColor Green
    } catch {
        Write-Host "PTR $ip → FAILED" -ForegroundColor Yellow
    }
}

# ── Test NetBIOS name resolution (port 137) ───────────────────────────────
foreach ($ip in $testIPs) {
    $result = Test-NetConnection -ComputerName $ip -Port 137 -WarningAction SilentlyContinue
    Write-Host "Port 137 to $ip`: $(if ($result.TcpTestSucceeded) { 'OPEN' } else { 'BLOCKED' })"
}
```

**Resolution**: Work with network team to open inbound port 135 (NTLM/RPC) and 137 (NetBIOS) from the MDI sensor/DC to all workstations in the monitored network. Alternatively, ensure reverse DNS PTR records are configured in your DNS platform.

---

## Phase 21 — Sensor Failed to Write to Custom Log Path

**Severity**: Low | The `SensorCustomLogLocation` configuration path is invalid or inaccessible.

```powershell
$targetDC = "DC01"

# ── Check the current custom log path in sensor config ────────────────────
Invoke-Command -ComputerName $targetDC -ScriptBlock {
    $configFile = "C:\ProgramData\Microsoft\Microsoft.Tri.Sensor\Deployment\SensorConfiguration.json"
    if (Test-Path $configFile) {
        $config = Get-Content $configFile | ConvertFrom-Json
        Write-Host "SensorCustomLogLocation: $($config.SensorCustomLogLocation)"
        if ($config.SensorCustomLogLocation) {
            Test-Path $config.SensorCustomLogLocation
        }
    }
}

# ── Fix: Clear or correct the custom log path (WRITE — LOW RISK) ─────────
# Run on the DC:
# 1. Stop-Service AATPSensorUpdater, AATPSensor
# 2. Edit SensorConfiguration.json: set "SensorCustomLogLocation" to null or a valid path
# 3. Start-Service AATPSensorUpdater, AATPSensor
```

---

## Phase 22 — Directory Service Account Password Expired or Expiring

**Severity**: HIGH (expired) / Medium (expiring < 30 days) | When expired, ALL sensors stop collecting data.

```powershell
# ── Check the DS account password expiry ─────────────────────────────────
$dsAccount = "mdi-ds-account"   # Replace with actual DS account name (or gMSA name)

# For standard AD account:
Get-ADUser $dsAccount -Properties PasswordExpired, PasswordLastSet, PasswordNeverExpires |
    Select-Object SamAccountName, PasswordExpired, PasswordLastSet, PasswordNeverExpires |
    Format-List

# Calculate days until expiry:
$policy = Get-ADDefaultDomainPasswordPolicy
$pwdLastSet = (Get-ADUser $dsAccount -Properties PasswordLastSet).PasswordLastSet
$expiryDate = $pwdLastSet + $policy.MaxPasswordAge
$daysLeft = [math]::Round(($expiryDate - (Get-Date)).TotalDays, 0)
Write-Host "Password expires: $($expiryDate.ToString('yyyy-MM-dd')) ($daysLeft days)"
```

**Fix** (WRITE — HIGH IMPACT if not done correctly):
1. Change the password for the DS account in Active Directory
2. **Immediately** update the password in the **Defender XDR portal**:
   - `Settings → Identities → Directory Service Accounts → [account] → Edit`
3. Verify sensors resume communication (check health issues page ~5 minutes later)

**Prevention**: Set the DS account to `Password never expires`, or configure a password rotation process with automatic portal updates.

---

## Phase 23 — Directory Services User Credentials Incorrect

**Severity**: Medium | Wrong username, password, or domain in MDI DS account configuration.

```powershell
# ── Verify the account exists and is enabled ─────────────────────────────
$dsAccount = "mdi-ds-account"
Get-ADUser $dsAccount -Properties Enabled, LockedOut, PasswordExpired |
    Select-Object SamAccountName, Enabled, LockedOut, PasswordExpired | Format-List

# ── For gMSA: verify DC can retrieve the managed password ────────────────
$gmsaAccount = "mdiSvc01$"
Get-ADServiceAccount $gmsaAccount -Properties PrincipalsAllowedToRetrieveManagedPassword |
    Select-Object Name, PrincipalsAllowedToRetrieveManagedPassword | Format-List

# Which DCs are allowed to retrieve the password?
$allowedPrincipals = (Get-ADServiceAccount $gmsaAccount -Properties PrincipalsAllowedToRetrieveManagedPassword).PrincipalsAllowedToRetrieveManagedPassword
Write-Host "Principals allowed to retrieve gMSA password:"
$allowedPrincipals | ForEach-Object { Write-Host "  $_" }

# Purge stale Kerberos tickets on a DC (for gMSA auth refresh):
# Invoke-Command -ComputerName DC01 -ScriptBlock { klist -li 0x3e7 purge }
```

**Resolution in portal**: `Settings → Identities → Directory Service Accounts` → correct the username, password, or domain, then **Test** the connection before saving.

---

## Phase 24 — Directory Services Object Auditing Not Enabled

**Severity**: Medium | SACL auditing not configured on AD objects. Validated daily per domain.

```powershell
$domainDN = (Get-ADDomain).DistinguishedName

# ── Check SACL on the domain root ─────────────────────────────────────────
$acl = Get-Acl "AD:\$domainDN"
$saclEntries = $acl.Audit
Write-Host "SACL entries on domain root: $($saclEntries.Count)"
$saclEntries | Format-Table IdentityReference, AuditFlags, ActiveDirectoryRights,
    InheritanceType, ObjectType -AutoSize

# Required SACLs (Everyone or Domain Users, Success+Failure, on descendant objects):
# Descendant User objects         - Write + Write All Properties
# Descendant Group objects        - Write + Write All Properties
# Descendant Computer objects     - Write + Write All Properties
# Descendant msDS-GroupManagedServiceAccount - Write
# Descendant msDS-ManagedServiceAccount      - Write
```

**Configure via ADSI Edit**:
1. `adsiedit.msc` → Connect to Default naming context
2. Right-click domain root → Properties → Security → Advanced → Auditing
3. Add entries for `Everyone`, `Success` and `Failure`, on applicable descendant object types

Reference: [Configure domain object auditing](https://learn.microsoft.com/en-us/defender-for-identity/configure-windows-event-collection#configure-domain-object-auditing)

---

## Phase 25 — Auditing on Configuration Container Not Enabled

**Severity**: Medium | Required for environments with Exchange (current or historical).

```powershell
$rootDSE = Get-ADRootDSE
$configNC = $rootDSE.configurationNamingContext

# ── Check SACL on Configuration container ─────────────────────────────────
$acl = Get-Acl "AD:\$configNC"
Write-Host "SACL entries on Configuration container: $($acl.Audit.Count)"
$acl.Audit | Format-Table IdentityReference, AuditFlags, ActiveDirectoryRights -AutoSize
```

**Required**: `Everyone` with `Write All Properties`, `Success` and `Failure`, on `This object and all descendant objects` on `CN=Configuration,DC=...`

Configure in **ADSI Edit** → connect to Configuration partition → right-click `CN=Configuration,...` → Security → Advanced → Auditing.

---

## Phase 26 — Auditing on ADFS Container Not Enabled

**Severity**: Medium | Applies to environments using Active Directory Federation Services.

```powershell
$domainDN = (Get-ADDomain).DistinguishedName
$adfsPath = "CN=ADFS,CN=Microsoft,CN=Program Data,$domainDN"

# ── Verify ADFS container exists ──────────────────────────────────────────
try {
    $adfsObj = Get-ADObject $adfsPath -ErrorAction Stop
    Write-Host "ADFS container exists: $adfsPath" -ForegroundColor Green

    # Check SACL
    $acl = Get-Acl "AD:\$adfsPath"
    Write-Host "SACL entries: $($acl.Audit.Count)"
    $acl.Audit | Format-Table IdentityReference, AuditFlags, ActiveDirectoryRights -AutoSize
} catch {
    Write-Host "ADFS container not found — ADFS may not be deployed in this domain" -ForegroundColor Yellow
}
```

Reference: [Configure auditing on ADFS](https://learn.microsoft.com/en-us/defender-for-identity/configure-windows-event-collection#configure-auditing-on-an-active-directory-federation-services-ad-fs)

---

## Phase 27 — Radius Accounting (VPN) Data Ingestion Failures

**Severity**: Low | MDI VPN integration failing. Affects VPN-based user location tracking.

```powershell
# ── This is a configuration issue in the MDI portal ──────────────────────
# Portal: Settings → Identities → VPN
# Verify: Shared secret matches the VPN server RADIUS configuration

# ── Check if RADIUS accounting data is arriving on any sensor ─────────────
# The sensor that should receive RADIUS accounting must have UDP/1813 open from VPN server
$sensorDC = "DC01"
$vpnServerIP = "10.0.0.100"  # Replace with your VPN gateway IP

Invoke-Command -ComputerName $sensorDC -ScriptBlock {
    param($vpnIP)
    # Check Windows Firewall allows UDP 1813 inbound from VPN server
    Get-NetFirewallRule | Where-Object {
        $_.Direction -eq "Inbound" -and $_.Enabled -eq "True"
    } | Get-NetFirewallPortFilter | Where-Object { $_.LocalPort -eq "1813" }
} -ArgumentList $vpnServerIP
```

**Shared secret mismatch resolution**:
1. In portal: `Settings → Identities → VPN` → note the shared secret configured
2. On the VPN server: verify RADIUS shared secret for the MDI sensor as RADIUS client matches exactly (case-sensitive)

---

## Documentation

For each health issue resolved, record in your Jira ticket:

```
Alert name:             [exact text from portal]
Sensor/DC affected:     [hostname]
First seen:             [timestamp]
Root cause identified:  [description]
Commands run:           [list]
Fix applied:            [change made]
Portal status after:    [Closed / still Open]
Verification method:    [how you confirmed the fix]
```
