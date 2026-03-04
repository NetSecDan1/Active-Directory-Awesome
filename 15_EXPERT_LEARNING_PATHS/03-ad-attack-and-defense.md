# AD Attack & Defense — Purple Team Learning Track

> Understanding how AD is attacked is the fastest path to defending it well. This track teaches you to think like an attacker so you can build better defenses. Everything here is for **defensive understanding** in authorized environments only.

---

## Track Philosophy

The best AD defenders have run the attacks in a lab. They know exactly what Kerberoasting looks like in the event log because they've done it themselves. This track:

1. Explains the attack technique
2. Shows how to **detect it** (event IDs, KQL, indicators)
3. Shows how to **prevent it** (configuration controls)
4. Gives you a **lab exercise** to practice detection

**Prerequisite**: A lab environment — a Windows Server VM with AD DS installed. Never run attack tools in production.

---

## MODULE 1: Credential Theft Techniques

### 1.1 — Kerberoasting

**What it is**: Any domain user can request a Kerberos service ticket for any SPN-registered account. The ticket is encrypted with the service account's password hash. Offline cracking reveals the password.

**Why it matters**: Service accounts often have old, weak passwords and high privileges.

**Detection**:
```powershell
# Find Kerberoastable accounts in your environment
Get-ADUser -Filter {Enabled -eq $true} -Properties ServicePrincipalName, PasswordLastSet |
    Where-Object { $_.ServicePrincipalName.Count -gt 0 } |
    Select-Object Name, SamAccountName, PasswordLastSet, ServicePrincipalName |
    Sort-Object PasswordLastSet
```

**Event ID signature**: Event 4769 (Kerberos service ticket request)
- `Ticket Encryption Type` = `0x17` (RC4 — weak, crackable) → ALERT
- `Ticket Encryption Type` = `0x12` (AES256 — strong, much harder to crack)

```kql
// Sentinel/MDE KQL — Detect Kerberoasting (RC4 TGS requests)
SecurityEvent
| where EventID == 4769
| where TicketEncryptionType == "0x17"
| where ServiceName !endswith "$"  // Exclude computer accounts
| where ServiceName != "krbtgt"
| summarize count() by AccountName, ServiceName, IpAddress, bin(TimeGenerated, 5m)
| where count_ > 5  // Multiple requests = tooling behavior
```

**Prevention**:
- Use gMSA (Group Managed Service Accounts) — passwords are 240-char random, auto-rotated
- For accounts that can't use gMSA: set 30+ character random passwords, rotate annually
- Enable AES256 encryption: `Set-ADUser -KerberosEncryptionType AES256`
- Place service accounts in Protected Users group (disables RC4)

**Lab Exercise**: Set up a service account with an SPN. Request a TGS ticket. Check Event 4769. Change encryption to AES256. Observe the difference.

---

### 1.2 — AS-REP Roasting

**What it is**: If a user account has "Do not require Kerberos preauthentication" enabled, an attacker can request an AS-REP without knowing the password. The response contains data encrypted with the user's key — crackable offline.

**Detection**:
```powershell
# Find AS-REP Roastable accounts
Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true -and Enabled -eq $true} |
    Select-Object Name, SamAccountName
```

**Event ID**: Event 4768 with Pre-Authentication Type = 0

**Prevention**: Enable Kerberos pre-authentication on ALL accounts (it's the default — check for exceptions).

---

### 1.3 — Pass-the-Hash (PtH)

**What it is**: Windows cached NTLM hashes can be extracted from LSASS memory and used directly to authenticate as that user — no need to crack the hash.

**Tools used by attackers**: Mimikatz (`sekurlsa::logonpasswords`), Cobalt Strike

**Detection** — Event 4624 with:
- `Logon Type` = 3 (Network)
- `Authentication Package` = NTLM
- Source IP doesn't match the user's known workstation

**Prevention**:
- **Credential Guard** — isolates LSASS in a virtualization-based security container; hashes can't be extracted
- **Protected Users** — prevents NTLM authentication for group members
- **LAPS** — unique local admin passwords mean hash extraction on one machine doesn't work everywhere
- **Disable NTLMv1** — require NTLMv2 minimum

```powershell
# Check if Credential Guard is enabled
(Get-WmiObject -Class Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).SecurityServicesRunning
# 1 = Credential Guard running
```

---

## MODULE 2: Privilege Escalation

### 2.1 — DCSync

**What it is**: Any account with `DS-Replication-Get-Changes-All` permission on the domain root can impersonate a DC and "sync" password hashes for any account — including KRBTGT. No code execution on the DC required.

**Why it's devastating**: Immediately leads to Golden Ticket if KRBTGT hash obtained.

**Detection — Event 4662**:
```kql
// Detect DCSync — DS-Replication-Get-Changes-All being exercised
SecurityEvent
| where EventID == 4662
| where Properties has "1131f6aa-9c07-11d1-f79f-00c04fc2dcd2"  // DS-Replication-Get-Changes
     or Properties has "1131f6ab-9c07-11d1-f79f-00c04fc2dcd2"  // DS-Replication-Get-Changes-All
| where SubjectUserName !endswith "$"  // Exclude actual DCs (computer accounts)
| project TimeGenerated, SubjectUserName, SubjectDomainName, Properties, Computer
```

**Prevention**:
```powershell
# Audit who has DCSync rights right now
$domainDN = (Get-ADDomain).DistinguishedName
$acl = Get-Acl "AD:$domainDN"
$acl.Access | Where-Object {
    $_.ObjectType -eq "1131f6aa-9c07-11d1-f79f-00c04fc2dcd2" -or  # DS-Replication-Get-Changes
    $_.ObjectType -eq "1131f6ab-9c07-11d1-f79f-00c04fc2dcd2"      # DS-Replication-Get-Changes-All
} | Select-Object IdentityReference, ObjectType, AccessControlType
# Only Domain Controllers and Azure AD Connect accounts should appear
```

---

### 2.2 — Golden Ticket

**What it is**: Using the KRBTGT password hash, an attacker forges a Ticket Granting Ticket (TGT) for any user, including domain admins — with any privileges, any group membership, any lifetime.

**Why it's devastating**: Valid for the KRBTGT password lifetime — effectively permanent until KRBTGT is rotated TWICE.

**Detection**: Golden Tickets are hard to detect because they look like legitimate TGTs. Indicators:
- TGT with unusually long lifetime (default max is 10 hours — forged tickets often have 10+ years)
- Account in Event 4624 that hasn't been seen before
- Microsoft Defender for Identity detects this natively with its Golden Ticket alert

**Prevention**:
- Protect the KRBTGT account with maximum controls
- Rotate KRBTGT password annually (see `13_RUNBOOKS/04-krbtgt-rotation.md`)
- Rotate IMMEDIATELY after any suspected domain compromise
- Enable MDI — it has behavioral detection for Golden Ticket usage

---

### 2.3 — ACL Abuse

**What it is**: Misconfigurations in ACLs on AD objects grant unexpected permissions. Common vectors:
- `GenericAll` on a user account → reset password, add to groups
- `WriteDACL` on a domain object → grant yourself any permission
- `WriteOwner` → take ownership, then grant yourself full control
- `GenericWrite` on a computer → set msDS-AllowedToActOnBehalfOfOtherIdentity (RBCD attack)

**Detection with PowerShell**:
```powershell
# Find non-standard ACEs on domain object root
$domainDN = (Get-ADDomain).DistinguishedName
(Get-Acl "AD:$domainDN").Access |
    Where-Object {
        $_.IdentityReference -notlike "*Domain Admins*" -and
        $_.IdentityReference -notlike "*Enterprise Admins*" -and
        $_.IdentityReference -notlike "*SYSTEM*" -and
        $_.IdentityReference -notlike "*Administrators*" -and
        $_.ActiveDirectoryRights -match "GenericAll|WriteDACL|WriteOwner|GenericWrite"
    } | Format-Table IdentityReference, ActiveDirectoryRights -AutoSize
```

**Tool for comprehensive ACL review**: BloodHound (for defensive analysis in authorized environments)

---

## MODULE 3: Persistence Techniques

### 3.1 — SID History Injection

**What it is**: The `sIDHistory` attribute stores previous domain SID values for migrated accounts. An attacker with Domain Admin can add any SID (including Domain Admins SID) to any account's sIDHistory — giving that account covert admin rights.

**Detection**:
```powershell
# Find accounts with SID History populated
Get-ADUser -Filter {SIDHistory -like '*'} -Properties SIDHistory |
    Select-Object Name, SamAccountName, SIDHistory
# Any non-migrated account with SIDHistory populated is suspicious
```

**Event ID 4765** — SID History was added to an account.

---

### 3.2 — AdminSDHolder Abuse

**What it is**: AdminSDHolder is a template container that applies its ACL to all protected objects (Domain Admins, etc.) every 60 minutes via SDProp. An attacker who can modify AdminSDHolder's ACL gains persistent rights to all protected objects.

**Detection**:
```powershell
# Check AdminSDHolder ACL for unexpected entries
$adminSDHolder = "CN=AdminSDHolder,CN=System,$((Get-ADDomain).DistinguishedName)"
(Get-Acl "AD:$adminSDHolder").Access |
    Where-Object { $_.IdentityReference -notlike "*Domain Admins*" -and
                   $_.IdentityReference -notlike "*Enterprise Admins*" -and
                   $_.IdentityReference -notlike "*Administrators*" -and
                   $_.IdentityReference -notlike "*SYSTEM*" } |
    Format-Table IdentityReference, ActiveDirectoryRights -AutoSize
# Should return nothing — any hit is a finding
```

---

## MODULE 4: Detection & Hunting Baseline

### Monitoring Minimum Viable Set

For any AD environment, these MUST be collected and alerted on:

| Event | Source | Alert Condition |
|-------|--------|----------------|
| 4740 | PDC Emulator | >10 lockouts/hour for same account |
| 4625 | All DCs | >20 failures/5min from one IP |
| 4769 + RC4 | All DCs | Any TGS with encryption type 0x17 for service accounts |
| 4662 + Replication GUIDs | All DCs | From non-DC, non-AAD Connect accounts |
| 4728/4732/4756 | All DCs | Addition to privileged groups |
| 4723/4724 | All DCs | Password change/reset on KRBTGT or admin accounts |

### Honey Accounts

Create decoy accounts that should never be used. Alert on any authentication:

```powershell
# Create a honey account (no real users should ever use this)
New-ADUser -Name "svc-backup-legacy" `
    -SamAccountName "svc-backup-legacy" `
    -AccountPassword (ConvertTo-SecureString (New-Guid).Guid -AsPlainText -Force) `
    -Enabled $true `
    -Description "Legacy backup service — DO NOT USE"

# Add SPN to make it Kerberoastable bait
setspn -A MSSQLSvc/backup-legacy.corp.com:1433 svc-backup-legacy

# Alert: Any event 4769 for this account = Kerberoasting activity in your environment
```

---

## MODULE 5: Defense-in-Depth Scorecard

Rate your environment against each control:

| Control | Your Rating | Effort to Fix | Priority |
|---------|------------|--------------|---------|
| Credential Guard enabled on workstations | 🔴/🟡/🟢 | High | High |
| LAPS deployed — all workstations | 🔴/🟡/🟢 | Medium | High |
| Protected Users — all Tier 0 accounts | 🔴/🟡/🟢 | Low | Critical |
| No unconstrained delegation (non-DCs) | 🔴/🟡/🟢 | Medium | Critical |
| Kerberoastable accounts use AES/gMSA | 🔴/🟡/🟢 | Medium | High |
| AS-REP Roasting — 0 vulnerable accounts | 🔴/🟡/🟢 | Low | High |
| DCSync rights limited to DCs + AAD Connect | 🔴/🟡/🟢 | Low | Critical |
| AdminSDHolder ACL reviewed | 🔴/🟡/🟢 | Low | High |
| SIDHistory — 0 unexpected entries | 🔴/🟡/🟢 | Low | Medium |
| MDI or equivalent deployed | 🔴/🟡/🟢 | High | High |
| Event log audit policy covers all critical IDs | 🔴/🟡/🟢 | Low | High |
| KRBTGT rotated in last 12 months | 🔴/🟡/🟢 | Low | Medium |

**AI Session for This Module**:
```
Use 11_MASTER_AI_PROMPTS/09-architecture-review-prompts.md →
"AD Security Architecture Review" prompt.

Then use 11_MASTER_AI_PROMPTS/01-ultimate-ad-system-prompt.md:
"Activate Security Reviewer.
Here is my security scorecard: [paste your ratings].
Walk me through the highest-priority remediations in order."
```
