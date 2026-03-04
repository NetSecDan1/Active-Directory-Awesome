# AD Security Hardening

**Use Case:** Harden Active Directory against modern attack techniques — Kerberoasting, Pass-the-Hash, DCSync, privilege escalation, and lateral movement.
**Techniques:** Tier model, privileged access workstations, attack path analysis, detection controls

---

## AD Security Assessment Prompt

```
You are a senior Active Directory security specialist with expertise in offensive AD techniques (Red Team certified) and defensive hardening. You know how attackers move through AD environments and how to stop them.

MY ENVIRONMENT:
- Forest/domain structure: [single/multi-domain]
- DC OS versions: [e.g., 2016/2019/2022]
- Privileged account count: [rough number of Domain Admins, etc.]
- Current security controls: [e.g., MFA for admins, PAWs, LAPS, audit logging level]
- Known concerns: [any specific threats or compliance requirements]

ASSESSMENT FOCUS:
[All / Authentication security / Privilege model / Lateral movement prevention / Detection/monitoring]

---

Perform a structured AD security assessment covering:

## 1. Critical Attack Paths in My Environment
Based on my environment, what are the most likely attacker paths from initial access to Domain Admin? Walk through the attack chain.

## 2. High-Priority Hardening (Fix These First)

### Authentication Hardening
- Kerberoasting protection (service account passwords, encryption types)
- NTLM restriction strategy (disable/limit NTLM)
- Kerberos delegation audit and remediation
- AS-REP Roasting prevention

### Privilege Model
- Domain Admin account hygiene
- Privileged Access Workstation (PAW) design
- Admin Tier Model implementation (Tier 0/1/2)
- Protected Users security group usage

### Lateral Movement Prevention
- Local admin password uniqueness (LAPS deployment)
- SMB signing enforcement
- Credential Guard deployment
- Remote Credential Guard for RDP

### Detection Controls
- Advanced Audit Policy configuration
- Event forwarding to SIEM
- Honeypot accounts and honey tokens
- Purple team exercises

## 3. Implementation Roadmap
Prioritize actions by: Impact vs. Effort matrix
- Quick wins (high impact, low effort): do this week
- Medium-term (high impact, moderate effort): do this quarter
- Strategic (high impact, high effort): plan and resource

## 4. Specific Commands to Assess Your Current State
[Provide PowerShell/cmd to identify vulnerabilities in the environment described]
```

---

## Attack-Specific Hardening

### Kerberoasting Defense

```powershell
# Find Kerberoastable accounts (SPNs set on user accounts with weak encryption)
Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Properties ServicePrincipalName, PasswordLastSet, msDS-SupportedEncryptionTypes |
  Select Name, SamAccountName, ServicePrincipalName, PasswordLastSet, msDS-SupportedEncryptionTypes |
  Sort PasswordLastSet

# Check encryption types — RC4 (0x4) is vulnerable, AES256 (0x18) is required
# Remediation: set strong password (25+ chars) + enforce AES encryption

# Set AES encryption on service accounts
Set-ADUser -Identity <svc_account> -KerberosEncryptionType AES256,AES128

# Better: convert to gMSA (Group Managed Service Account)
# gMSAs have auto-rotating 240-char passwords — completely Kerberoasting-resistant
New-ADServiceAccount -Name "gmsa_service" -DNSHostName "service.domain.com" `
  -PrincipalsAllowedToRetrieveManagedPassword "Servers_Group"
```

### Pass-the-Hash / Pass-the-Ticket Prevention

```
Guidance for preventing credential theft attacks:

1. LAPS (Local Administrator Password Solution)
   - Unique, auto-rotating local admin passwords per machine
   - Deploy via GPO: Computer Configuration > Administrative Templates > LAPS

2. Credential Guard (Windows 10/Server 2016+)
   - Isolates LSASS in a virtualized container
   - Prevents mimikatz-style credential extraction
   - Enable via GPO or UEFI firmware

3. Protected Users Security Group
   - Add privileged accounts here immediately
   - Prevents: NTLM auth, unconstrained delegation, long-term caching
   - Test in staging — can break some legacy apps

4. Disable NTLM progressively:
   Audit: "Audit NTLM Authentication in this domain"
   Then restrict NTLMv1, then NTLMv2, then full block
   GPO: Security Settings > Local Policies > Security Options
```

### Privileged Access Tier Model

```
Design a Tier Model (Microsoft's Enterprise Access Model) for my organization:

Size: [number of servers, workstations, privileged users]
Current state: [admins use one account for everything / partially segmented / etc.]

Design:
- Tier 0 (Identity layer — DCs, AD, AAD Connect, PKI, etc.)
  - Who/what is Tier 0?
  - Tier 0 admin account policy
  - PAW requirements

- Tier 1 (Server layer — member servers, apps)
  - Separation from Tier 0
  - Just-Enough-Administration (JEA) opportunities

- Tier 2 (User/workstation layer)
  - Standard admin accounts
  - Helpdesk access model

Show me:
1. Which accounts need to be created/renamed
2. Group structure for each tier
3. Authentication policy silos (Kerberos armoring)
4. GPO changes to enforce tier separation
5. A 90-day implementation plan
```

---

## Detection Ruleset Prompt

```
Write detection rules (in Splunk SPL or Sigma format) for these AD attacks:

1. DCSync (replication from non-DC)
2. Golden Ticket usage (anomalous Kerberos TGT lifetime)
3. Kerberoasting (multiple RC4 TGS requests)
4. AS-REP Roasting (accounts with Kerberos pre-auth disabled)
5. AdminSDHolder abuse (SDProp anomalies)
6. SID history injection
7. Domain trust escalation

For each rule:
- Detection logic
- False positive considerations
- Tuning recommendations
- Response playbook (first 3 steps when this fires)
```

---

**Tips:**
- Start with Protected Users group for all Tier 0 accounts — zero implementation effort, high impact
- LAPS first, PAWs second, Tier Model third — in that order of ROI
- Most attackers use BloodHound to find attack paths — run it yourself first (authorized, of course)
- Accounts with "AdminCount=1" are protected by SDProp — review this list carefully
- The most common Domain Admin escalation path: Kerberoastable service account → its server → find DA credentials in memory
