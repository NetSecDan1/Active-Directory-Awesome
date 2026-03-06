# Pass-Through Authentication (PTA) Troubleshooting

## Real-Time Authentication Against On-Premises AD

---

## PTA Architecture

```
PTA AUTHENTICATION FLOW:

User                    Entra ID                 PTA Agent              On-Prem AD
  │                        │                        │                      │
  │ 1. Enter credentials   │                        │                      │
  ├───────────────────────►│                        │                      │
  │                        │                        │                      │
  │                        │ 2. Encrypt password    │                      │
  │                        ├───────────────────────►│                      │
  │                        │    (via Service Bus)   │                      │
  │                        │                        │                      │
  │                        │                        │ 3. Validate against AD
  │                        │                        ├─────────────────────►│
  │                        │                        │                      │
  │                        │                        │ 4. Return result     │
  │                        │                        │◄─────────────────────┤
  │                        │                        │                      │
  │                        │ 5. Auth result         │                      │
  │                        │◄───────────────────────┤                      │
  │                        │                        │                      │
  │ 6. Success/Failure     │                        │                      │
  │◄───────────────────────┤                        │                      │

KEY POINTS:
- Password NEVER stored in cloud
- Requires outbound 443 only (no inbound)
- High availability via multiple agents
- Falls back to PHS if configured and agents unavailable
```

---

## Section 1: PTA Agent Health

### Prompt 1.1: PTA Agent Status Check

```
I need to verify the health of PTA agents.

ENVIRONMENT:
- Number of PTA agents: [X]
- Agent servers: [List]
- Azure portal status: [Active/Inactive for each]

SYMPTOMS (if any):
[Describe authentication issues if present]

Please provide:
1. Commands to check local agent status
2. Verify agent connectivity to Azure
3. Check agent event logs
4. Verify certificate validity
5. Test authentication through each agent
6. Remediation for unhealthy agents
```

### Prompt 1.2: PTA Agent Not Connecting

```
A PTA agent shows as inactive or disconnected.

AGENT SERVER: [Name]
AZURE PORTAL STATUS: [Inactive/Error]
LOCAL SERVICE STATUS: [Running/Stopped]

ERROR MESSAGES:
[Paste from event log or portal]

Please provide:
1. Verify service is running
2. Check network connectivity (443 outbound)
3. Verify proxy configuration if applicable
4. Check certificate validity
5. Verify agent registration
6. Reinstall agent if needed
7. Confirm agent connects after fix
```

### Prompt 1.3: All PTA Agents Failing

```
CRITICAL: All PTA agents are offline/failing.

NUMBER OF AGENTS: [X]
ALL SHOWING: [Status]
AUTHENTICATION IMPACT: [Users cannot authenticate to cloud]

FALLBACK:
- PHS enabled as backup: [Yes/No]
- Federated domains: [If applicable]

Please provide:
1. Immediate mitigation options
2. Enable PHS emergency failover if configured
3. Diagnose common cause across all agents
4. Network/firewall change investigation
5. Certificate expiration check
6. Resolution steps
7. Prevention measures
```

---

## Section 2: Authentication Failures via PTA

### Prompt 2.1: PTA Authentication Failing for Users

```
Users cannot authenticate through PTA.

SYMPTOMS:
- Error message: [Exact error from sign-in]
- Affected users: [Scope - all, some, specific]
- Error code: [AADSTS code if available]

PTA AGENT STATUS:
[Status in Azure portal]

ON-PREM AUTHENTICATION:
- Users can authenticate on-prem: [Yes/No]

Please provide:
1. Verify PTA agent health
2. Check user account status in AD
3. Analyze sign-in logs for error details
4. Test on-prem authentication
5. Check for account-specific issues
6. Resolution based on error code
7. Verify authentication works after fix
```

### Prompt 2.2: Intermittent PTA Failures

```
PTA authentication is intermittent.

PATTERN:
- Frequency: [How often]
- Time-based: [Yes/No - when]
- User-based: [All users or specific]

AGENT CONFIGURATION:
- Number of agents: [X]
- Agent locations: [Sites/regions]

Please provide:
1. Check agent distribution and load
2. Analyze which agent is serving failures
3. Network stability investigation
4. AD DC availability and performance
5. Agent resource utilization
6. Recommendations for reliability
```

### Prompt 2.3: PTA Timeout Errors

```
PTA authentication is timing out.

ERROR: Connection timeout / request timeout
TIMEOUT FREQUENCY: [How often]

ENVIRONMENT:
- Agent servers: [Specs]
- Network path: [Description]
- AD DC performance: [Status]

Please provide:
1. Check agent to AD DC connectivity
2. Measure DC response time
3. Check agent server performance
4. Network latency investigation
5. Adjust timeout settings if needed
6. Scale agent deployment if needed
```

---

## Section 3: PTA Agent Installation and Configuration

### Prompt 3.1: Install Additional PTA Agent

```
I need to install an additional PTA agent for high availability.

CURRENT AGENTS: [Number]
NEW AGENT SERVER: [Name, OS]
NETWORK: [On-prem, DMZ, Azure]

REQUIREMENTS:
- Outbound 443: [Verified/Need to verify]
- Proxy: [Required/Not required]
- Service account: [Required?]

Please provide:
1. Prerequisites checklist
2. Download and installation procedure
3. Registration with tenant
4. Verify agent appears in portal
5. Test authentication through new agent
6. Best practices for agent placement
```

### Prompt 3.2: PTA Agent Behind Proxy

```
I need to configure PTA agent to work through a proxy.

PROXY DETAILS:
- Proxy URL: [URL]
- Authentication required: [Yes/No]
- Proxy type: [HTTP/HTTPS]

CURRENT ISSUE:
[Agent not connecting, registration failing, etc.]

Please provide:
1. Proxy configuration requirements for PTA
2. Configure agent to use proxy
3. Machine-level vs. user-level proxy
4. Bypass list if needed
5. Verify connectivity through proxy
6. Troubleshoot proxy-related failures
```

### Prompt 3.3: Upgrade PTA Agents

```
I need to upgrade PTA agents to latest version.

CURRENT VERSION: [Version]
TARGET VERSION: [Version]
NUMBER OF AGENTS: [X]

Please provide:
1. Upgrade prerequisites
2. Best practice upgrade order
3. Upgrade procedure per agent
4. Maintain availability during upgrade
5. Verify each agent after upgrade
6. Rollback procedure if needed
```

---

## Section 4: PTA and High Availability

### Prompt 4.1: PTA HA Architecture Review

```
I need to review/design PTA high availability.

CURRENT STATE:
- Number of agents: [X]
- Agent locations: [List]
- Current availability: [Issues?]

REQUIREMENTS:
- Availability target: [99.x%]
- Geographic distribution: [Requirements]

Please provide:
1. Recommended number of agents
2. Placement strategy (sites, regions)
3. Network considerations
4. Monitoring requirements
5. Failover behavior
6. PHS as ultimate fallback recommendation
```

### Prompt 4.2: PTA Failover to PHS

```
I want to configure automatic failover from PTA to PHS.

CURRENT CONFIG:
- PTA: [Enabled]
- PHS: [Enabled/Disabled]

REQUIREMENT:
[Seamless failover when PTA unavailable]

Please provide:
1. Enable PHS alongside PTA
2. Staged rollout configuration
3. How failover works
4. Testing failover
5. Monitoring for failover events
6. Recovery to PTA after agents restored
```

---

## Section 5: Security Considerations

### Prompt 5.1: PTA Security Audit

```
I need to audit PTA security configuration.

ENVIRONMENT:
- Agent servers: [Where hosted]
- Network segmentation: [Status]
- Agent service accounts: [Accounts used]

CONCERNS:
[Security requirements or audit findings]

Please provide:
1. PTA security architecture review
2. Agent server hardening requirements
3. Network security requirements
4. Certificate security
5. Monitoring and alerting for security
6. Audit logging configuration
7. Recommendations for improvement
```

### Prompt 5.2: PTA Agent Compromise Response

```
SECURITY: PTA agent server may be compromised.

AFFECTED SERVER: [Name]
COMPROMISE INDICATOR: [What triggered this concern]
AGENT STATUS: [Active/Disabled]

Please provide:
1. Immediate agent isolation
2. Disable agent in Azure portal
3. Evidence collection
4. Determine if credentials were exposed
5. User impact assessment
6. Recovery procedure
7. Prevention measures
```

---

## Section 6: Troubleshooting Tools and Logs

### Prompt 6.1: PTA Diagnostic Data Collection

```
I need to collect PTA diagnostic data for troubleshooting.

ISSUE: [Brief description]
AGENT SERVER: [Name]

Please provide:
1. Event log locations
2. Key events to look for
3. Trace log collection
4. Network trace if needed
5. Information to collect for support case
6. How to interpret common log entries
```

### PTA Event Log Reference

```
IMPORTANT PTA EVENTS:

Event Log: Application and Services Logs > Microsoft > AzureADConnect > AuthenticationAgent > Admin

KEY EVENTS:
- Event 10000: Agent started
- Event 10001: Agent stopped
- Event 12000: Authentication request received
- Event 12001: Authentication successful
- Event 12002: Authentication failed
- Event 12003: Authentication error
- Event 12004: Connection to AD failed
- Event 6000: Agent registered successfully
- Event 6001: Agent registration failed
- Event 6002: Certificate renewed
- Event 6003: Certificate renewal failed
```

---

## Quick Reference: PTA Commands

```powershell
# === AGENT STATUS ===

# Check PTA agent service
Get-Service AzureADConnectAuthenticationAgent

# Check agent version
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Azure AD Connect Authentication Agent" | Select-Object Version

# === CONNECTIVITY TESTS ===

# Test Azure connectivity
Test-NetConnection -ComputerName autologon.microsoftazuread-sso.com -Port 443
Test-NetConnection -ComputerName login.microsoftonline.com -Port 443

# Test AD connectivity from agent
Test-ComputerSecureChannel

# === EVENT LOGS ===

# Get PTA agent events
Get-WinEvent -LogName "Microsoft-AzureADConnect-AuthenticationAgent/Admin" -MaxEvents 50

# Filter for errors
Get-WinEvent -LogName "Microsoft-AzureADConnect-AuthenticationAgent/Admin" |
    Where-Object {$_.Level -eq 2} |
    Select-Object TimeCreated, Message

# === REGISTRATION ===

# Re-register agent (requires reinstall or specific tool)
# Generally done through agent installer

# === AZURE PORTAL ===
# Navigate to: Entra ID > Azure AD Connect > Pass-through Authentication
# View agent status, version, and last contact time
```

---

## PTA vs PHS Decision Matrix

| Factor | PTA | PHS |
|--------|-----|-----|
| Password stored in cloud | No | Yes (hash) |
| On-prem AD dependency for auth | Yes | No |
| Latency | Higher (on-prem round-trip) | Lower (cloud-only) |
| Requires agents | Yes | No (AAD Connect only) |
| Offline on-prem = Cloud auth fails | Yes | No |
| Enforce on-prem policies | Yes | Limited |
| Complexity | Higher | Lower |
| Recommended for most | No | Yes |

---

## Related Documents

- [Entra Connect](entra_connect.md) - Azure AD Connect overview
- [Hybrid Failure Modes](hybrid_failure_modes.md) - Common failure patterns
- [Seamless SSO](seamless_sso.md) - Related technology

---

[Back to Main README](../README.md)
