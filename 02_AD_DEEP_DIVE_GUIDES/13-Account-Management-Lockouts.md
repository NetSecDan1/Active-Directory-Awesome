# Account Management & Lockouts Troubleshooting

## AI Prompts for User Account Issues and Lockout Investigation

---

## Overview

Account lockouts and account management issues are among the most common support requests in enterprise environments. They can result from forgotten passwords, misconfigured services, malicious attacks, or application issues. This module provides AI prompts for systematic account troubleshooting.

---

## Section 1: Account Lockout Investigation

### Prompt 1.1: Account Lockout Root Cause Analysis

```
A user account is repeatedly locking out.

AFFECTED ACCOUNT: [Username]
LOCKOUT FREQUENCY: [How often]
LOCKOUT THRESHOLD: [X attempts]
LOCKOUT DURATION: [X minutes]

INITIAL OBSERVATIONS:
- Started when: [Date/time]
- User changed password recently: [Yes/No]
- Remote access used: [VPN, OWA, etc.]
- Mobile devices: [Yes/No]

Please provide:
1. Lockout source identification procedure
2. PDC Emulator event analysis
3. Using account lockout tools
4. Identifying the source IP/computer
5. Common lockout causes and patterns
6. Resolution based on findings
7. Prevention measures
```

### Prompt 1.2: Mass Account Lockouts

```
INCIDENT: Multiple accounts are locking out simultaneously.

SCOPE:
- Number of affected accounts: [X]
- Pattern: [Same OU, same job function, random]
- Started when: [Date/time]

POTENTIAL CAUSES TO INVESTIGATE:
- Security attack suspected: [Yes/No]
- Recent password policy change: [Yes/No]
- Service account password changed: [Yes/No]

Please provide:
1. Immediate triage steps
2. Distinguish attack vs. misconfiguration
3. Identify common source
4. Containment if security incident
5. Resolution for common causes
6. User communication
7. Post-incident analysis
```

### Prompt 1.3: Lockout Source Identification

```
I've identified a lockout but need to find the exact source.

LOCKED ACCOUNT: [Username]
LOCKOUT DC: [DC name if known]
CLIENT INFO FROM LOGS: [IP/hostname if available]

EVENT LOG DATA:
[Paste relevant Security events - 4740, 4625, etc.]

Please provide:
1. Interpret lockout events
2. Trace source from event data
3. Identify application or service
4. Check for saved credentials
5. Mobile device considerations
6. Scheduled task check
7. Service account review
```

---

## Section 2: Password Issues

### Prompt 2.1: Password Not Working

```
A user's password is not working despite being correct.

ACCOUNT: [Username]
SYMPTOMS:
- Lockout: [Yes/No]
- "Wrong password" error: [Yes/No]
- Some systems work, others don't: [Describe]

PASSWORD DETAILS:
- Recently changed: [Yes/No, when]
- Reset by admin: [Yes/No]
- User changed: [Yes/No]

Please provide:
1. Verify password is synced to all DCs
2. Check password replication
3. Kerberos vs. NTLM authentication check
4. Password age and expiration
5. Password policy compliance
6. Fine-grained password policy check
7. Resolution steps
```

### Prompt 2.2: Password Expiration Issues

```
Users are having issues with password expiration.

SYMPTOMS:
[Describe - no warning, immediate expiration, can't change]

PASSWORD POLICY:
- Maximum password age: [X days]
- Password notification: [X days before]

AFFECTED USERS:
[Scope - all users, specific OU, remote users]

Please provide:
1. Password expiration policy verification
2. User password expiration date check
3. "User must change password" setting
4. Password never expires flag check
5. Remote user password change issues
6. Policy propagation verification
7. Resolution and user guidance
```

### Prompt 2.3: Password Policy Troubleshooting

```
Password policy is not applying as expected.

EXPECTED POLICY:
- Complexity: [Requirements]
- Length: [Minimum]
- History: [Count]
- Age: [Min/Max]

ACTUAL BEHAVIOR:
[Describe what's happening]

POLICY SOURCE:
- Default domain policy: [Settings]
- Fine-grained password policies: [In use?]

Please provide:
1. Verify effective password policy
2. Fine-grained policy precedence
3. Policy application troubleshooting
4. PSO configuration check
5. User's resultant policy
6. Resolution steps
7. Verification after fix
```

---

## Section 3: Account Status Issues

### Prompt 3.1: Account Disabled/Expired

```
An account is disabled or expired unexpectedly.

ACCOUNT: [Username]
CURRENT STATUS: [Disabled/Expired]
EXPECTED STATUS: [Active]

ACCOUNT DETAILS:
- Created: [Date]
- Last logon: [Date]
- Account expires: [Date if set]

Please provide:
1. Identify who/what disabled account
2. Check account expiration settings
3. Review Security event logs
4. Identify automation that might disable
5. Policy that auto-disables inactive accounts
6. Re-enable procedure
7. Prevention if appropriate
```

### Prompt 3.2: Account Permissions Issues

```
A user account doesn't have expected permissions.

ACCOUNT: [Username]
MISSING ACCESS: [Describe what they can't access]
EXPECTED GROUPS: [Groups they should be in]
CURRENT GROUPS: [Groups they're currently in]

RECENT CHANGES:
[Describe any known changes]

Please provide:
1. Verify group membership
2. Check nested group membership
3. Token bloat considerations
4. Verify group has access
5. Kerberos ticket refresh requirement
6. Resolution procedure
7. Verification steps
```

---

## Section 4: Service Account Management

### Prompt 4.1: Service Account Lockouts

```
A service account is locking out.

ACCOUNT: [Username]
SERVICES USING ACCOUNT: [List services/servers]
LOCKOUT PATTERN: [Frequency and timing]

CONFIGURATION:
- Account type: [User account, MSA, gMSA]
- Password management: [Manual/Automatic]
- Last password change: [Date]

Please provide:
1. Identify all services using account
2. Check scheduled tasks
3. Verify password is current everywhere
4. Check for stale credentials
5. Migration to gMSA consideration
6. Resolution procedure
7. Preventing future lockouts
```

### Prompt 4.2: Service Account Password Management

```
I need to manage a service account password change.

ACCOUNT: [Username]
SERVICES AFFECTED: [List]
SERVERS: [List]
CHANGE REASON: [Routine, security, lockouts]

Please provide:
1. Password change planning
2. Service discovery (find all uses)
3. Change execution procedure
4. Updating all services
5. Verification after change
6. Rollback if issues
7. Migration to gMSA recommendation
```

### Prompt 4.3: gMSA Implementation

```
I want to implement Group Managed Service Accounts.

CURRENT SERVICE ACCOUNTS:
[List accounts to convert]

SERVICES:
[List services and which servers]

REQUIREMENTS:
- KDS root key: [Exists/Needs creation]
- Target servers: [Windows version]

Please provide:
1. gMSA prerequisites
2. KDS root key creation
3. gMSA creation procedure
4. Configuring services to use gMSA
5. Migration from standard accounts
6. Permission requirements
7. Verification and testing
```

---

## Section 5: Stale Account Management

### Prompt 5.1: Stale Account Identification

```
I need to identify and manage stale accounts.

DEFINITIONS NEEDED:
- Stale user: Last logon > [X days]
- Stale computer: Last logon > [X days]

CURRENT PROCESS:
[Describe existing stale account handling]

Please provide:
1. PowerShell to find stale accounts
2. Differentiating inactive from unused
3. Service account considerations
4. Staged cleanup procedure
5. Disabling vs. deleting approach
6. Documentation requirements
7. Automation recommendations
```

### Prompt 5.2: Account Lifecycle Automation

```
I want to automate account lifecycle management.

REQUIREMENTS:
- New account provisioning: [Needs]
- Modification workflows: [Needs]
- Deprovisioning: [Needs]
- Stale account handling: [Needs]

CURRENT TOOLS:
[Describe available tools - IdM, scripts, manual]

Please provide:
1. Account lifecycle best practices
2. Provisioning automation options
3. Group membership automation
4. Deprovisioning workflow design
5. Stale account automation
6. Audit and compliance considerations
7. Tool recommendations
```

---

## Section 6: Account Lockout Tools and Scripts

### Prompt 6.1: Lockout Investigation Script

```
Create a PowerShell script for account lockout investigation:

REQUIREMENTS:
1. Query all DCs for lockout events
2. Find source computer/IP
3. Identify the process/caller
4. Time-based filtering
5. Export results to CSV
6. Summary report generation
7. Run remotely against any account

Include error handling and documentation.
```

### Prompt 6.2: Account Health Report

```
Create a PowerShell script for account health reporting:

REQUIREMENTS:
1. Password expiration report
2. Locked accounts list
3. Disabled accounts list
4. Stale accounts identification
5. Accounts with password never expires
6. Service accounts audit
7. HTML report output

Include scheduling guidance and documentation.
```

---

## Section 7: Account Security

### Prompt 7.1: Privileged Account Security

```
I need to improve security for privileged accounts.

CURRENT PRIVILEGED ACCOUNTS:
- Domain Admins: [Count]
- Enterprise Admins: [Count]
- Server local admins: [Managed/Not]

CURRENT PROTECTIONS:
[Describe existing security measures]

Please provide:
1. Privileged account inventory
2. Reducing privilege where possible
3. Protected Users group implementation
4. Admin account password requirements
5. Privileged Access Workstations
6. Monitoring and alerting
7. Regular access review process
```

### Prompt 7.2: Account Compromise Detection

```
I want to detect potentially compromised accounts.

AVAILABLE DATA:
- Security logs: [Retention]
- SIEM: [Available/Not]
- Azure AD Identity Protection: [Yes/No]

DETECTION GOALS:
[List specific scenarios to detect]

Please provide:
1. Indicators of compromised accounts
2. Unusual logon pattern detection
3. Impossible travel detection
4. Password spray detection
5. Privilege escalation detection
6. Alerting configuration
7. Response procedures
```

---

## Quick Reference: Account Commands

```powershell
# === ACCOUNT STATUS ===

# Get account details
Get-ADUser username -Properties *

# Check account lockout status
Get-ADUser username -Properties LockedOut, LockoutTime, BadLogonCount

# Unlock account
Unlock-ADAccount -Identity username

# Enable/disable account
Enable-ADAccount -Identity username
Disable-ADAccount -Identity username

# === PASSWORD MANAGEMENT ===

# Check password last set
Get-ADUser username -Properties PasswordLastSet

# Check password expiration
Get-ADUser username -Properties PasswordExpired, PasswordNeverExpires

# Reset password
Set-ADAccountPassword -Identity username -Reset -NewPassword (ConvertTo-SecureString "NewP@ssw0rd" -AsPlainText -Force)

# Force password change at next logon
Set-ADUser username -ChangePasswordAtLogon $true

# === GROUP MEMBERSHIP ===

# Get user's groups
Get-ADPrincipalGroupMembership username

# Get nested group membership
Get-ADUser username -Properties MemberOf | Select-Object -ExpandProperty MemberOf

# === LOCKOUT INVESTIGATION ===

# Find locked accounts
Search-ADAccount -LockedOut

# Get lockout events from PDC
Get-WinEvent -ComputerName PDCName -FilterHashtable @{
    LogName='Security'
    Id=4740
} -MaxEvents 100

# Find account lockout source
Get-WinEvent -ComputerName PDCName -FilterHashtable @{
    LogName='Security'
    Id=4740
} | Where-Object { $_.Message -match "username" }

# === STALE ACCOUNTS ===

# Find users not logged in for 90 days
$90days = (Get-Date).AddDays(-90)
Get-ADUser -Filter {LastLogonDate -lt $90days} -Properties LastLogonDate

# Find computers not logged in for 90 days
Get-ADComputer -Filter {LastLogonDate -lt $90days} -Properties LastLogonDate

# === PASSWORD POLICY ===

# Get default domain password policy
Get-ADDefaultDomainPasswordPolicy

# Get fine-grained password policies
Get-ADFineGrainedPasswordPolicy -Filter *

# Get resultant password policy for user
Get-ADUserResultantPasswordPolicy -Identity username
```

---

## Account Event ID Reference

| Event ID | Description |
|----------|-------------|
| 4720 | User account created |
| 4722 | User account enabled |
| 4723 | Password change attempted |
| 4724 | Password reset attempt |
| 4725 | User account disabled |
| 4726 | User account deleted |
| 4738 | User account changed |
| 4740 | Account locked out |
| 4767 | Account unlocked |
| 4625 | Failed logon |
| 4771 | Kerberos pre-auth failed |
| 4776 | NTLM authentication |

---

## Lockout Troubleshooting Flowchart

```
Account Locked Out
│
├── Check Security log on PDC Emulator (4740)
│   └── Identify Caller Computer Name
│       │
│       ├── Is it a server?
│       │   └── Check services, scheduled tasks, application pools
│       │
│       ├── Is it a workstation?
│       │   └── Check mapped drives, cached creds, applications
│       │
│       └── Is it a mobile device/mail?
│           └── Check mail profile, apps, cached password
│
└── No specific source?
    └── Check for authentication from:
        - VPN
        - OWA/Outlook Anywhere
        - ADFS
        - Legacy applications
```

---

## Related Modules

- [Authentication & Kerberos](02-Authentication-Kerberos.md) - Authentication issues
- [Security & Incident Response](10-Security-Incident-Response.md) - Security-related lockouts
- [Azure AD & Hybrid](12-Azure-AD-Hybrid.md) - Cloud account sync

---

[Back to Master Guide](00-AD-Master-Troubleshooting-Guide.md)
