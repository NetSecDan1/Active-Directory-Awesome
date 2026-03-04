# Active Directory Authentication & Kerberos Troubleshooting

## AI Prompts for Diagnosing Authentication and Kerberos Issues

---

## Overview

Authentication failures directly impact end-user productivity and application availability. Kerberos is the primary authentication protocol in Active Directory, and its proper functioning is critical for secure, seamless authentication. This module provides AI prompts for systematic diagnosis of authentication problems.

---

## Section 1: Authentication Failure Triage

### Prompt 1.1: Authentication Failure Initial Assessment

```
I'm experiencing authentication failures in my Active Directory environment.

SYMPTOMS:
- Affected users/computers: [Describe scope - single user, group, entire site]
- Error messages seen: [Exact error messages]
- Applications affected: [List - Windows logon, specific apps, services]
- When did this start: [Date/time and any correlating events]
- Intermittent or consistent: [Pattern of failures]

ENVIRONMENT:
- Domain functional level: [Level]
- Authentication methods in use: [Kerberos/NTLM/Certificate/etc.]
- Recent changes: [Patches, GPO changes, network changes, etc.]

Please provide:
1. Initial diagnostic commands to run on client and DC
2. Event log entries to look for and their meaning
3. Decision tree to determine if this is Kerberos, NTLM, or other issue
4. Most likely causes based on the symptom pattern
5. Safe immediate actions while investigating
```

### Prompt 1.2: Determine Authentication Protocol in Use

```
I need to determine which authentication protocol is being used for a failing connection.

CONNECTION DETAILS:
- Client computer: [Name]
- Target resource: [Server/service name]
- Resource type: [File share, web app, SQL, etc.]
- Current error: [Error message]

Please provide:
1. How to determine if Kerberos or NTLM is being attempted
2. Commands to check what protocol was actually used
3. How to verify Kerberos ticket acquisition
4. Network trace interpretation for authentication packets
5. Common reasons for Kerberos-to-NTLM fallback
6. How to force Kerberos authentication for testing
```

---

## Section 2: Kerberos-Specific Issues

### Prompt 2.1: Kerberos Ticket Troubleshooting

```
I'm experiencing Kerberos ticket-related issues.

SYMPTOMS:
[Describe - cannot obtain TGT, service ticket failures, ticket expiration issues]

AFFECTED ACCOUNT: [User/computer/service account]
TARGET SERVICE: [Service being accessed]

KLIST OUTPUT (from affected client):
[Paste output of: klist]

KLIST OUTPUT FOR TARGET SERVICE:
[Paste output of: klist get <SPN>]

Please analyze and provide:
1. Interpretation of the klist output
2. Whether correct tickets are present
3. Diagnostic steps for ticket acquisition failures
4. How to purge and re-acquire tickets safely
5. Time synchronization verification steps
6. Kerberos policy settings to check
```

### Prompt 2.2: KDC and TGT Issues

```
Users are unable to obtain Kerberos TGT (Ticket Granting Ticket).

ERROR DETAILS:
- Kerberos error code: [e.g., KRB5KDC_ERR_C_PRINCIPAL_UNKNOWN, KRB5KRB_AP_ERR_SKEW]
- Error source: [Client event log, application, etc.]
- Event Log entries: [Paste relevant Security/System events]

AFFECTED SCOPE:
- Single user or multiple: [Describe]
- Specific DC or all DCs: [Describe]

Please provide:
1. Detailed explanation of this specific Kerberos error
2. Root cause analysis for TGT acquisition failures
3. DC-side diagnostics (KDC service, event logs)
4. Client-side diagnostics
5. Resolution steps with exact commands
6. Verification that TGT can now be obtained
```

### Prompt 2.3: Service Principal Name (SPN) Issues

```
I suspect SPN (Service Principal Name) issues are causing authentication failures.

SERVICE DETAILS:
- Service type: [SQL, IIS, custom app, etc.]
- Service account: [Account running the service]
- Server name: [FQDN]
- Service URL/connection string: [How clients connect]

CURRENT ERROR:
[Paste error message]

Please provide:
1. How to check what SPNs are registered for the service account
2. How to determine what SPN the client is requesting
3. Commands to diagnose duplicate SPN issues
4. Proper SPN format for this service type
5. How to register missing SPNs safely
6. Verification that SPN configuration is correct
7. Delegation considerations if applicable
```

### Prompt 2.4: Duplicate SPN Detection and Resolution

```
I need to find and resolve duplicate SPNs in my environment.

SYMPTOMS:
[Describe - intermittent auth failures, Kerberos errors mentioning SPN]

SUSPECTED DUPLICATE SPN: [SPN if known]

Please provide:
1. Commands to search entire forest for duplicate SPNs
2. PowerShell script to audit all SPNs and identify duplicates
3. How to determine which registration is correct
4. Safe procedure to remove incorrect SPN registration
5. Impact of duplicate SPNs on authentication
6. Verification steps after cleanup
7. Prevention measures for future
```

---

## Section 3: Kerberos Delegation

### Prompt 3.1: Kerberos Delegation Configuration

```
I need to configure Kerberos delegation for a multi-tier application.

APPLICATION ARCHITECTURE:
- Front-end server: [Name and role]
- Middle-tier server: [Name and role]
- Back-end server: [Name and role - e.g., SQL Server]
- Service accounts used: [List accounts at each tier]
- User authentication flow: [How users connect]

CURRENT ISSUE:
[Describe - double-hop problem, delegation not working, etc.]

Please provide:
1. Explanation of delegation types (Unconstrained, Constrained, RBCD)
2. Which delegation type is appropriate for this scenario
3. Step-by-step configuration procedure
4. SPN requirements for each tier
5. Security implications of each option
6. Testing procedure to verify delegation works
7. Troubleshooting steps if delegation fails
```

### Prompt 3.2: Constrained Delegation Troubleshooting

```
Kerberos Constrained Delegation is not working as expected.

CONFIGURATION:
- Delegating account: [Account name]
- Target service SPNs configured: [List SPNs]
- Protocol transition: [Enabled/Disabled]

SYMPTOMS:
[Describe - access denied, wrong identity, etc.]

DIAGNOSTIC OUTPUT:
[Any relevant klist, event log, or trace output]

Please analyze and provide:
1. Verification steps for constrained delegation configuration
2. Common misconfigurations and how to identify them
3. Event log entries indicating delegation issues
4. How to trace the delegation flow
5. Resolution steps for identified issues
6. RBCD as an alternative if traditional CD is problematic
```

### Prompt 3.3: Resource-Based Constrained Delegation (RBCD)

```
I want to implement Resource-Based Constrained Delegation.

SCENARIO:
- Service needing to delegate: [Front-end service account]
- Target resource: [Back-end service/server]
- Reason for RBCD over traditional CD: [Cross-domain, no DA rights, etc.]

Please provide:
1. RBCD concepts and when to use it
2. Prerequisites and requirements
3. Step-by-step PowerShell configuration
4. How RBCD differs from traditional constrained delegation
5. Security considerations specific to RBCD
6. Testing and verification procedures
7. Rollback procedure if issues arise
```

---

## Section 4: NTLM Issues

### Prompt 4.1: NTLM Fallback Troubleshooting

```
Authentication is falling back to NTLM when Kerberos should be used.

AFFECTED CONNECTION:
- Client: [Name]
- Target: [Server/service]
- Expected: Kerberos
- Actual: NTLM (verified via [method])

ENVIRONMENT DETAILS:
[Describe DNS, network, trust configuration if relevant]

Please provide:
1. Common reasons for Kerberos-to-NTLM fallback
2. Diagnostic steps to identify the specific cause
3. How to check if SPN exists and is reachable
4. DNS verification for the target
5. Time sync verification
6. Network path analysis (ports, firewalls)
7. Resolution based on identified cause
```

### Prompt 4.2: NTLM Auditing and Restriction

```
I need to audit NTLM usage and plan for restrictions.

CURRENT STATE:
- NTLM version enforced: [LM/NTLMv1/NTLMv2/Unknown]
- Current NTLM audit policies: [Describe]
- Known NTLM dependencies: [List if known]

GOAL:
- Audit NTLM to identify usage
- Eventually restrict NTLM for security

Please provide:
1. GPO settings to enable comprehensive NTLM auditing
2. Event IDs to monitor for NTLM authentication
3. PowerShell scripts to analyze NTLM audit logs
4. How to identify which applications/services use NTLM
5. Staged approach to restricting NTLM safely
6. Exception handling for legacy systems
7. Verification that restrictions don't break critical services
```

---

## Section 5: Time Synchronization

### Prompt 5.1: Time Sync Issues Affecting Authentication

```
I suspect time synchronization issues are causing authentication failures.

SYMPTOMS:
- Kerberos errors mentioning clock skew
- Event IDs related to time: [List any]
- Affected systems: [Describe scope]

CURRENT TIME CONFIGURATION:
- PDC Emulator: [DC name]
- External time source configured: [Yes/No, source if yes]
- Time skew observed: [X seconds/minutes difference]

Please provide:
1. How Kerberos uses time and default tolerance
2. Commands to check time sync status across DCs
3. Proper time hierarchy configuration in AD
4. How to configure authoritative time source
5. Forcing immediate time resync safely
6. Verification that time is synchronized
7. Monitoring recommendations for time sync
```

### Prompt 5.2: Configure AD Time Synchronization

```
I need to properly configure time synchronization in my AD environment.

ENVIRONMENT:
- Forest root domain: [Name]
- PDC Emulator: [DC name]
- Number of domains/DCs: [X]
- Virtualized DCs: [Yes/No]
- External time source available: [Yes/No, describe]

Please provide:
1. Recommended time sync architecture for AD
2. Configuring PDC Emulator as authoritative source
3. External NTP source configuration
4. GPO settings for domain member time sync
5. Special considerations for virtual DCs
6. Verification commands for entire hierarchy
7. Alerting for time drift detection
```

---

## Section 6: Secure Channel Issues

### Prompt 6.1: Computer Account Secure Channel Repair

```
A computer is unable to authenticate to the domain - potential secure channel issue.

SYMPTOMS:
- Error: "Trust relationship between workstation and domain failed"
- Computer: [Name]
- Domain: [Name]
- Recent events: [Restore from backup, long offline period, etc.]

Please provide:
1. Commands to test secure channel status
2. How to repair secure channel without rejoining domain
3. When rejoining is necessary vs. repair
4. Preserving computer group memberships during repair
5. Automation for bulk secure channel issues
6. Prevention measures
7. Root cause analysis approach
```

### Prompt 6.2: Service Account Authentication Issues

```
A service account is experiencing authentication failures.

SERVICE DETAILS:
- Account name: [Name]
- Account type: [User account, MSA, gMSA]
- Services using this account: [List]
- Running on servers: [List]

ERROR DETAILS:
[Paste error messages]

Please provide:
1. Diagnostic steps for service account authentication
2. Checking password status and expiration
3. SPN verification for the account
4. Delegation settings review
5. Resolution based on account type
6. Migration to gMSA if appropriate
7. Best practices for service account management
```

---

## Section 7: Certificate-Based Authentication

### Prompt 7.1: Smart Card Authentication Issues

```
Smart card authentication is failing.

SYMPTOMS:
[Describe - card not recognized, cert errors, PIN issues]

ENVIRONMENT:
- Smart card type: [Physical card, virtual smart card]
- Certificate template: [Name]
- CA: [Internal PKI/third-party]

ERROR DETAILS:
[Paste error messages]

Please provide:
1. Smart card authentication flow explanation
2. Client-side diagnostics (CSP, certificate store)
3. DC-side diagnostics (KDC certificate, mapping)
4. Certificate validation troubleshooting
5. Revocation checking issues
6. NTAuth store verification
7. Resolution steps based on symptoms
```

### Prompt 7.2: Certificate Mapping and PKINIT

```
I need to troubleshoot certificate-to-user mapping in AD.

SCENARIO:
- Authentication method: [Smart card, certificate auth, etc.]
- Mapping type: [Implicit UPN, explicit mapping, altSecurityIdentities]
- Current issue: [Describe - wrong user, auth failure, etc.]

Please provide:
1. Certificate mapping methods in AD explained
2. How to verify current mapping configuration
3. Troubleshooting PKINIT authentication
4. Strong certificate mapping requirements (KB5014754)
5. Configuring explicit certificate mapping
6. Handling multiple certificates per user
7. Best practices for certificate authentication
```

---

## Section 8: Claims and Compound Authentication

### Prompt 8.1: Claims-Based Access Control Issues

```
Dynamic Access Control (DAC) or claims-based authentication isn't working.

CONFIGURATION:
- Claims configured: [List claim types]
- Central access policies: [Describe]
- Affected resources: [File servers, etc.]

SYMPTOMS:
[Describe - access denied when should work, claims not present]

Please provide:
1. How to verify claims are being issued
2. Checking claim types configuration
3. Central access policy troubleshooting
4. Device claims vs. user claims
5. Kerberos armoring (FAST) requirements
6. File server configuration verification
7. Effective access analysis tools
```

---

## Section 9: Authentication Event Analysis

### Prompt 9.1: Security Event Log Analysis

```
I need to analyze authentication events to diagnose issues.

SCENARIO:
[Describe the authentication problem]

RELEVANT EVENT IDS COLLECTED:
[Paste events - 4771, 4768, 4769, 4776, 4625, etc.]

Please provide:
1. Interpretation of each authentication event type
2. What these specific events indicate about the failure
3. Correlation between related events
4. Identifying the root cause from event patterns
5. Additional events to look for
6. Recommended actions based on analysis
```

### Prompt 9.2: Kerberos Event Analysis Script

```
Create a PowerShell script that:

1. Collects Kerberos-related events from DCs (4768, 4769, 4771)
2. Collects authentication failure events (4625, 4776)
3. Filters for a specific user, computer, or time range
4. Correlates TGT and service ticket requests
5. Identifies failure patterns
6. Outputs a summary report with:
   - Authentication success/failure rates
   - Common failure reasons
   - Problematic accounts or services
   - Timeline of issues
7. Exports detailed data for further analysis

Include parameters for time range, target user, and target service.
```

---

## Quick Reference: Authentication Commands

```powershell
# === KERBEROS DIAGNOSTICS ===

# View current Kerberos tickets
klist

# View tickets for specific service
klist get MSSQLSvc/server.domain.com:1433

# Purge all Kerberos tickets (force re-auth)
klist purge

# View Kerberos configuration
ksetup

# Test Kerberos authentication
runas /user:domain\user "cmd"

# === SPN MANAGEMENT ===

# List SPNs for an account
setspn -L accountname

# Search for SPN in forest
setspn -Q */servername*

# Find duplicate SPNs
setspn -X

# Register SPN
setspn -S MSSQLSvc/server.domain.com:1433 domain\sqlaccount

# === SECURE CHANNEL ===

# Test secure channel
Test-ComputerSecureChannel -Verbose

# Repair secure channel
Test-ComputerSecureChannel -Repair -Verbose

# Using netdom
netdom verify computername /domain:domain.com

# Reset computer password
netdom resetpwd /server:DCName /userd:domain\admin /passwordd:*

# === TIME SYNC ===

# Check time sync status
w32tm /query /status

# Check time source
w32tm /query /source

# Force time resync
w32tm /resync /force

# Check time config
w32tm /query /configuration

# === AUTHENTICATION TESTING ===

# Test LDAP bind
$cred = Get-Credential
[System.DirectoryServices.DirectoryEntry]::new("LDAP://dc.domain.com", $cred.UserName, $cred.GetNetworkCredential().Password)

# Test Kerberos-only connection
New-PSSession -ComputerName server -Authentication Kerberos
```

---

## Common Kerberos Error Codes Reference

| Error Code | Name | Common Cause |
|------------|------|--------------|
| 0x6 | KDC_ERR_C_PRINCIPAL_UNKNOWN | Invalid username or pre-auth type |
| 0x7 | KDC_ERR_S_PRINCIPAL_UNKNOWN | SPN not found |
| 0x17 | KDC_ERR_KEY_EXPIRED | Password expired |
| 0x18 | KDC_ERR_PREAUTH_FAILED | Wrong password |
| 0x25 | KDC_ERR_PREAUTH_REQUIRED | Pre-authentication needed |
| 0x37 | KRB_AP_ERR_SKEW | Time difference too great |

---

## Related Modules

- [DNS Integration](03-DNS-Integration.md) - DNS essential for Kerberos
- [Account Management & Lockouts](13-Account-Management-Lockouts.md) - Account issues affect auth
- [Security & Incident Response](10-Security-Incident-Response.md) - Auth failures may indicate attacks

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
