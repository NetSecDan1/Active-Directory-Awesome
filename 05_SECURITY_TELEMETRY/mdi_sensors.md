# Microsoft Defender for Identity (MDI)

## Identity Threat Detection and Sensor Management

---

## MDI Architecture Overview

```
MDI ARCHITECTURE:

Domain Controllers                    MDI Cloud Service
       │                                     │
       │  ┌──────────────────────────┐      │
       │  │     MDI SENSOR           │      │
       │  │  • Captures traffic      │      │
       │  │  • Parses events         │      │
       ├──┤  • Sends to cloud        ├──────┤
       │  │  • Local detection       │      │
       │  └──────────────────────────┘      │
       │                                     │
       │                              ┌──────┴──────┐
       │                              │   MDI       │
       │                              │  PORTAL     │
       │                              │  • Alerts   │
       │                              │  • Timeline │
       │                              │  • Hunting  │
       │                              └─────────────┘

DATA SOURCES CAPTURED:
• Network traffic (port mirroring or WinPcap)
• Windows Security Events (4776, 4768, 4769, etc.)
• ETW traces
• DNS queries
• LDAP queries
• NTLM authentication
• Kerberos traffic
```

---

## Section 1: Sensor Health and Troubleshooting

### Prompt 1.1: MDI Sensor Health Check

```
I need to verify MDI sensor health.

ENVIRONMENT:
- Number of DCs: [X]
- Sensors installed: [X]
- Sensor type: [Standalone/DC-installed]

CONCERNS:
[Describe any issues or reason for check]

Please provide:
1. Sensor status verification in portal
2. Local sensor service check
3. Connectivity verification
4. Event log analysis
5. Common sensor issues
6. Remediation steps
```

### Prompt 1.2: Sensor Not Reporting

```
An MDI sensor is not reporting data.

AFFECTED DC: [Name]
SENSOR STATUS: [In portal]
LAST COMMUNICATION: [When]

LOCAL CHECKS:
- Service status: [Running/Stopped]
- Error messages: [If any]

Please provide:
1. Verify sensor service is running
2. Check network connectivity to MDI service
3. Verify proxy configuration if used
4. Check certificate validity
5. Review sensor event logs
6. Reinstall sensor if needed
7. Confirm sensor reports after fix
```

### Prompt 1.3: Sensor Performance Issues

```
MDI sensor is causing performance issues on DC.

DC: [Name]
SYMPTOMS:
- High CPU: [Yes/No, by which process]
- High memory: [Yes/No]
- Network impact: [Yes/No]

DC SPECIFICATIONS:
- CPU/RAM: [Specs]
- Concurrent users: [Count]

Please provide:
1. Verify sensor resource usage
2. Check if DC is undersized for sensor
3. Review sensor configuration
4. Adjust sensor settings if possible
5. Consider standalone sensor
6. Capacity planning recommendations
```

---

## Section 2: Alert Investigation

### Prompt 2.1: MDI Alert Triage

```
I have an MDI alert that needs investigation.

ALERT NAME: [Alert title]
SEVERITY: [High/Medium/Low]
AFFECTED ENTITIES: [Users/Computers involved]
TIMESTAMP: [When]

ALERT DETAILS:
[Key information from alert]

Please provide:
1. What this alert type indicates
2. Is this likely true positive or false positive?
3. Investigation steps specific to this alert
4. Evidence to collect
5. Response actions if confirmed
6. Tuning options if false positive
```

### Prompt 2.2: Common MDI Alert Types

```
MDI ALERT REFERENCE:

RECONNAISSANCE ALERTS:
├── Account enumeration
│   └── Attackers discovering valid accounts
├── Network mapping
│   └── Discovery of network topology
├── User and group recon
│   └── LDAP/SAM-R queries for users/groups
└── Honeytoken triggered
    └── Decoy account was accessed

CREDENTIAL THEFT ALERTS:
├── Suspected DCSync attack
│   └── Replication request from non-DC
├── Suspected Golden Ticket
│   └── Forged Kerberos ticket detected
├── Suspected Skeleton Key
│   └── Backdoor authentication detected
├── Malicious Kerberos request
│   └── Unusual ticket properties
└── Overpass-the-hash
    └── Abnormal Kerberos auth pattern

LATERAL MOVEMENT ALERTS:
├── Pass-the-hash
│   └── NTLM hash reuse detected
├── Pass-the-ticket
│   └── Kerberos ticket reuse
├── Remote code execution
│   └── Suspicious process execution
└── Suspicious service creation
    └── Potentially malicious service

DOMAIN DOMINANCE ALERTS:
├── Data exfiltration over SMB
│   └── Large data transfer patterns
├── Malicious DCShadow
│   └── Rogue DC registration attempt
└── Suspicious additions to sensitive groups
    └── Unexpected privilege escalation
```

### Prompt 2.3: Investigate Lateral Movement Alert

```
MDI detected potential lateral movement.

ALERT: [Specific alert name]
SOURCE: [Source computer/user]
DESTINATION: [Target computer]
TECHNIQUE: [Pass-the-hash/Pass-the-ticket/etc.]

CONTEXT:
- Time: [When]
- User account: [Account involved]
- Is this account admin?: [Yes/No]

Please provide:
1. Understand the attack technique
2. Determine if this is expected admin activity
3. Check if source is compromised
4. Check destination for compromise
5. Trace the attack path
6. Response actions
7. Hunting for related activity
```

---

## Section 3: MDI and AD Troubleshooting Correlation

### Prompt 3.1: Using MDI for AD Investigation

```
I'm troubleshooting an AD issue and want to use MDI data.

AD ISSUE: [Description]
TIMEFRAME: [When]
AFFECTED ENTITIES: [Users/Computers]

Please provide:
1. Relevant MDI data to examine
2. Entity timeline analysis
3. Authentication patterns
4. LDAP query patterns
5. Correlating MDI data with AD events
6. How MDI can help identify root cause
```

### Prompt 3.2: MDI During Security Incident

```
SECURITY INCIDENT: Using MDI for incident response.

INCIDENT TYPE: [Credential theft, lateral movement, etc.]
KNOWN COMPROMISED: [Accounts/systems if known]
TIMEFRAME: [Incident timeline]

Please provide:
1. MDI queries for affected entities
2. Timeline reconstruction from MDI
3. Identify scope of compromise
4. Find additional affected accounts
5. Track attacker movement
6. Identify persistence mechanisms
7. Evidence collection from MDI
```

---

## Section 4: MDI Configuration

### Prompt 4.1: MDI Deployment Planning

```
I need to plan MDI deployment.

ENVIRONMENT:
- Number of domains: [X]
- Number of DCs: [X]
- DC operating systems: [List]
- Network topology: [Describe]

REQUIREMENTS:
- Coverage: [All DCs or critical only]
- Monitoring goals: [What to detect]

Please provide:
1. Deployment architecture recommendation
2. Sensor sizing requirements
3. Network configuration needs
4. Firewall/proxy requirements
5. Deployment sequence
6. Validation steps
```

### Prompt 4.2: MDI Exclusions and Tuning

```
I need to tune MDI to reduce false positives.

ALERT TYPE: [Alert generating false positives]
FALSE POSITIVE PATTERN: [What's triggering it]

LEGITIMATE ACTIVITY:
[Describe the legitimate behavior]

Please provide:
1. Understand why alert is triggering
2. Exclusion options for this alert type
3. Configure exclusion safely
4. Test exclusion
5. Monitor that real attacks still detected
6. Document exclusion rationale
```

---

## Section 5: MDI and Hybrid Identity

### Prompt 5.1: MDI in Hybrid Environment

```
I have hybrid identity and want MDI visibility.

CONFIGURATION:
- Hybrid auth method: [PHS/PTA/ADFS]
- Azure AD Connect: [Yes]
- Cloud apps: [M365, etc.]

VISIBILITY GAPS CONCERNED ABOUT:
[What attacks might not be visible]

Please provide:
1. MDI coverage in hybrid scenarios
2. Gaps in on-prem only monitoring
3. Integration with Defender for Cloud Apps
4. Cloud identity protection considerations
5. Comprehensive hybrid monitoring strategy
```

---

## Quick Reference: MDI Commands and Checks

```powershell
# === SENSOR SERVICE ===

# Check sensor service status
Get-Service "Azure Advanced Threat Protection Sensor"

# Sensor installation location
# Default: C:\Program Files\Azure Advanced Threat Protection Sensor

# === SENSOR LOGS ===

# Sensor log location
# C:\Program Files\Azure Advanced Threat Protection Sensor\Logs

# Key log files:
# Microsoft.Tri.Sensor.log - Main sensor log
# Microsoft.Tri.Sensor.Updater.log - Update log

# === CONNECTIVITY ===

# Required endpoints (must be accessible):
# *.atp.azure.com - MDI service
# *.blob.core.windows.net - Updates
# *.servicebus.windows.net - Communication

# Test connectivity
Test-NetConnection -ComputerName "your-workspace.atp.azure.com" -Port 443

# === EVENT LOG ===

# Sensor events in Windows Event Log
Get-WinEvent -LogName "Microsoft-Windows-ATA/Sensor-Operational" -MaxEvents 50
```

---

## MDI Alert Severity Guide

| Severity | Meaning | Response Time |
|----------|---------|---------------|
| High | Likely real attack, immediate risk | Immediate investigation |
| Medium | Suspicious, needs investigation | Within hours |
| Low | Anomalous, may be legitimate | Review when able |
| Informational | For awareness | Periodic review |

---

## Related Documents

- [Security Incident Response](../02_ACTIVE_DIRECTORY/10-Security-Incident-Response.md) - IR procedures
- [MDE from AD Perspective](mde_from_ad_perspective.md) - Endpoint detection
- [Timeline Reconstruction](../01_IDENTITY_P0_COMMAND/timeline_reconstruction.md) - Incident timeline

---

[Back to Main README](../README.md)
