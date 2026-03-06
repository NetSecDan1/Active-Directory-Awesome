# 02 — Chain-of-Thought Diagnostic Prompts for Active Directory

> **What this is**: Structured reasoning prompts that force the AI to think step-by-step through AD problems — the same mental model a Microsoft Escalation Engineer uses. Chain-of-thought dramatically improves accuracy on complex, multi-system AD failures.

---

## Why Chain-of-Thought Matters for AD

AD failures are almost never single-component. A "can't log in" issue might be:
- DNS → DC unreachable → Kerberos fails → NTLM fallback → NTLMv1 blocked → auth fails

Without structured reasoning, AI shortcuts to the wrong layer. CoT forces traversal of the full stack.

---

## PROMPT 1: The AD Stack Traversal (Universal Diagnostic)

```
I need you to diagnose an Active Directory problem using strict chain-of-thought reasoning. Work through each layer completely before moving to the next. Do NOT skip layers. Do NOT jump to conclusions.

THE AD STACK (work top-to-bottom, confirm each before descending):

LAYER 7 — Application/Service
└── Is the application or service itself healthy?
└── Is it configured to use the correct auth method?
└── Is the service account valid and not locked/expired?

LAYER 6 — Authentication Protocol
└── Is Kerberos the protocol in use? Or NTLM? Or LDAP bind?
└── Is the SPN registered correctly?
└── Is time sync within 5 minutes of the DC?
└── Is the Kerberos realm correct?

LAYER 5 — Active Directory Services
└── Is the DC that was contacted available and healthy?
└── Is the NETLOGON service running?
└── Is the NTDS service running?
└── Is the DC's SYSVOL share accessible?
└── Is there a PDC Emulator reachable for auth?

LAYER 4 — Group Policy / Authorization
└── Is the user in the correct groups?
└── Is there a GPO blocking logon (deny logon locally, etc.)?
└── Are there Fine-Grained Password Policies affecting this account?
└── Is the account in Protected Users?

LAYER 3 — DNS Resolution
└── Can the client resolve the domain name?
└── Are SRV records present for _ldap._tcp.dc._msdcs.DOMAIN?
└── Are all DCs registered in DNS?
└── Is there conditional forwarding configured correctly?

LAYER 2 — Network/Connectivity
└── Can the client reach the DC on required ports? (88, 389, 445, 135, 3268, 636)
└── Is there a firewall rule blocking?
└── Is there routing between the client subnet and DC subnet?

LAYER 1 — Infrastructure
└── Is the DC online and not in a maintenance window?
└── Is replication healthy? (Could this client be hitting a stale DC?)
└── Is there a site assignment for this client subnet?

---

PROBLEM STATEMENT:
[PASTE YOUR PROBLEM HERE]

---

For each layer, output:
✅ CONFIRMED HEALTHY: [evidence]
❌ CONFIRMED ISSUE: [evidence + impact]
⚠️ UNKNOWN: [what I'd need to check]
🔍 LIKELY ISSUE: [hypothesis + confidence %, what data would confirm]

After all layers, provide:
## Root Cause Hypothesis
[Most likely root cause with evidence chain]

## Diagnostic Commands (READ-ONLY)
[Exact commands to confirm the hypothesis]

## Remediation Plan
[Only after diagnosis is confirmed — with risk level and rollback]
```

---

## PROMPT 2: Replication Convergence Analyzer

```
Perform a systematic chain-of-thought analysis of an Active Directory replication problem. Use this exact methodology:

STEP 1 — TOPOLOGY MAPPING
Think through:
- How many DCs are there and in which sites?
- What is the KCC-generated replication topology (who replicates to whom)?
- Are there manual connection objects overriding KCC?
- Which DC is the ISTG (Inter-Site Topology Generator)?

STEP 2 — ERROR CLASSIFICATION
Classify the replication error by type:
- USN/Journaling errors (8606 = lingering objects, 8614 = USN rollback suspected)
- RPC errors (1722 = endpoint unreachable, 1753 = mapper failed)
- Access/Auth errors (8453 = insufficient access, 5 = access denied)
- DNS-related (8524 = DSA not operational, name lookup failure)
- Time-related (-2146893022 = clock skew, KDC can't find key)

STEP 3 — BLAST RADIUS ANALYSIS
Think through:
- Is this one DC or multiple DCs affected?
- Is this intra-site or inter-site replication?
- Is this affecting all naming contexts (Domain, Schema, Config) or just one?
- How long has replication been failing? (USN delta × replication interval)
- What could be stale on affected DCs? (Password changes, account changes, GPOs)

STEP 4 — ROOT CAUSE DETERMINATION
Work through each possible cause:
A. Network (RPC, firewall, routing)
B. DNS (DC registration, resolution)
C. Authentication (Kerberos, time, account)
D. Database/data integrity (lingering objects, USN rollback)
E. Service/configuration (NTDS, replication schedule, disabled connections)

STEP 5 — REMEDIATION SEQUENCING
Order of safe operations:
1. Verify/fix DNS first (foundation of everything)
2. Verify/fix network (RPC reachability)
3. Verify/fix authentication (time sync, Kerberos)
4. Then address replication-specific issues
5. Data integrity issues last (lingering objects, metadata cleanup)

---

REPLICATION PROBLEM DATA:
[PASTE: repadmin /showrepl output, error codes, site topology info]

Work through all 5 steps completely before providing recommendations.
```

---

## PROMPT 3: Kerberos Failure Deep-Dive

```
A Kerberos authentication failure is occurring. Analyze it using strict protocol-level chain-of-thought reasoning.

KERBEROS FLOW ANALYSIS — verify each step:

PHASE 1: AS-REQ (Authentication Service Request)
→ Client sends AS-REQ to KDC (PDC Emulator by default)
→ Check: Is the KDC reachable on port 88?
→ Check: Is the username valid and enabled?
→ Check: Is the account not locked, expired, or disabled?
→ Check: Is pre-authentication required and working?
→ Possible failures here: KRB_AP_ERR_BAD_INTEGRITY (bad password), KDC_ERR_CLIENT_REVOKED (account issue)

PHASE 2: AS-REP (Authentication Service Response)
→ KDC issues TGT encrypted with client's long-term key
→ Check: Is the KRBTGT account key known to all DCs? (Could be stale after KRBTGT rotation)
→ Check: Is the TGT lifetime appropriate? (Default 10 hours)
→ Possible failures: KDC_ERR_ETYPE_NOTSUPP (encryption type mismatch)

PHASE 3: TGS-REQ (Ticket Granting Service Request)
→ Client presents TGT, requests service ticket for target SPN
→ Check: Is the SPN registered? (setspn -L <account>)
→ Check: Is the SPN registered on the CORRECT account?
→ Check: Is the SPN registered on MULTIPLE accounts? (Duplicate SPN = auth failure)
→ Possible failures: KDC_ERR_S_PRINCIPAL_UNKNOWN (SPN not found)

PHASE 4: TGS-REP (Ticket Granting Service Response)
→ KDC issues service ticket encrypted with service account's key
→ Check: Does the service account's key match what's in AD?
→ Check: Has the service account password changed? (Service not restarted?)
→ Possible failures: KRB_AP_ERR_MODIFIED (ticket tampered or stale)

PHASE 5: AP-REQ (Application Request)
→ Client presents service ticket to target service
→ Check: Is the service running under the expected service account?
→ Check: Is the clock skew within 5 minutes?
→ Check: Does the service have access to its keytab/keys?
→ Possible failures: KRB_AP_ERR_SKEW (time drift), KRB_AP_ERR_TKT_EXPIRED

TIME SYNC ANALYSIS:
→ Client time vs DC time vs Service server time
→ Maximum allowed skew: 5 minutes (300 seconds)
→ PDC Emulator is authoritative time source — is it synchronized?
→ Check: w32tm /query /status on all relevant systems

DELEGATION ANALYSIS (if S4U or delegation involved):
→ Unconstrained: TrustedForDelegation = TRUE → HIGH RISK flag
→ Constrained: msDS-AllowedToDelegateTo populated
→ Resource-based constrained: msDS-AllowedToActOnBehalfOfOtherIdentity on target
→ Protocol transition: TrustedToAuthForDelegation = TRUE required for S4U2Self

---

FAILURE DATA:
[Paste: Event IDs (4768, 4769, 4771, 4776), error codes, affected users, affected services, timing]

Analyze each phase and identify exactly where the Kerberos flow breaks down.
```

---

## PROMPT 4: Account Lockout Forensics

```
Perform forensic chain-of-thought analysis of an Active Directory account lockout. The goal is to identify the EXACT SOURCE causing lockouts with high confidence.

FORENSIC METHODOLOGY:

STEP 1 — POLICY BASELINE
Establish what "lockout" means in this environment:
- Default Domain Policy lockout threshold?
- Fine-Grained Password Policy (PSO) on this user or group?
- Which PSO wins? (Precedence value, direct vs group application)
- What is the observation window and reset duration?

STEP 2 — EVENT LOG FORENSICS
On the PDC Emulator (lockout authority for domain):
- Event 4740: Account lockout — includes CallerComputerName (the SOURCE)
- Event 4625: Failed logon — Logon Type + Failure Reason + Workstation Name
- Event 4771: Kerberos pre-auth failure — includes IP address of client
- Event 4776: NTLM auth failure — includes Workstation name

On domain controllers (all of them):
- Event 4625 with Failure Reason 0xC000006A (bad password) — how many? How frequent?
- Event 4776 for NTLM authentication failures

STEP 3 — SOURCE IDENTIFICATION
Based on CallerComputerName from Event 4740:
A. If source is a WORKSTATION — look for: cached credentials, mapped drives, scheduled tasks, services, COM+ applications running as user, saved passwords in Credential Manager
B. If source is a SERVER — look for: application service accounts, IIS app pools, SQL Server agent, scheduled tasks, monitoring agents
C. If source is BLANK/ANONYMOUS — likely an NTLM spray or old cached password from Credential Manager
D. If source is LOCALHOST — the lockout is happening on the DC itself

STEP 4 — PATTERN ANALYSIS
- What time of day do lockouts occur? (Indicates: login attempt vs automated process)
- How many bad passwords before lockout? (Indicates: typo vs spray)
- Is it one user or many? (Indicates: targeted vs spray/credential stuffing)
- Is it one source or many? (Indicates: specific misconfiguration vs distributed attack)
- Does it correlate with password changes? (Indicates: stale credential cache)

STEP 5 — CANDIDATE LOCATIONS TO CHECK
Ordered by likelihood:
1. Windows Credential Manager (cmdkey /list)
2. Mapped network drives (net use)
3. Scheduled tasks (Get-ScheduledTask | where {$_.Principal.UserId -like "*username*"})
4. Services (Get-WmiObject Win32_Service | where {$_.StartName -like "*username*"})
5. IIS Application Pools
6. COM+ applications
7. Old Outlook profiles with cached password
8. Mobile device with Exchange ActiveSync
9. Legacy NAS/printer with hardcoded credentials

---

LOCKOUT DATA:
[Paste: Username, frequency, Event 4740 details, CallerComputerName, any patterns observed]

Work through all 5 steps. Identify the most likely source with confidence percentage. Provide exact remediation steps.
```

---

## PROMPT 5: GPO Non-Application Root Cause Analysis

```
Analyze a Group Policy Object (GPO) that is not applying correctly. Use strict chain-of-thought through the GPO processing pipeline.

GPO PROCESSING PIPELINE ANALYSIS:

STAGE 1 — DISCOVERY (Can the client find GPOs to apply?)
→ Client queries SYSVOL for GPO list
→ Check: Is SYSVOL accessible? (net use \\DOMAIN\SYSVOL)
→ Check: Is the Netlogon share accessible?
→ Check: Is DFSR/FRS healthy on the authenticating DC?
→ If SYSVOL is inaccessible: GPO application halts entirely

STAGE 2 — SCOPE DETERMINATION (Which GPOs apply to this object?)
→ Site GPOs → Domain GPOs → OU GPOs (in that order)
→ Check: Is the computer/user in the correct OU? (Get-ADComputer/Get-ADUser -Properties CanonicalName)
→ Check: Are there Block Inheritance settings on any OU in the path?
→ Check: Is there an Enforced (No Override) GPO from higher up?

STAGE 3 — SECURITY FILTERING (Does this object have permission to READ the GPO?)
→ Default: Authenticated Users have Read + Apply Group Policy
→ Check: Has security filtering been modified? (GPO → Scope → Security Filtering)
→ Check: Does the object (user/computer) have "Apply Group Policy" permission?
→ Check: Are there DENY permissions? (Deny overrides Allow)
→ Key insight: If you remove Authenticated Users, you MUST add the target explicitly

STAGE 4 — WMI FILTERING (Does the WMI filter evaluate to TRUE?)
→ WMI filters run on the CLIENT, not the DC
→ Check: Is there a WMI filter attached to the GPO?
→ Check: Does the filter query match the client's WMI namespace?
→ Test: Run the WMI query manually: Get-WmiObject -Query "SELECT * FROM ..."
→ Common issue: WMI filter targets Windows version that doesn't match

STAGE 5 — CSE EXECUTION (Is the Client-Side Extension processing the policy?)
→ Each policy type (Registry, Software, Scripts, etc.) has a CSE GUID
→ Check: Are there errors in Event Log (Application log) from relevant CSE?
→ Check: Is the GPO client version matching server version? (gpresult shows this)
→ For user policy: Is the user logged in to a machine in a different site?
→ Loopback processing: Is Loopback mode set? (Merge vs Replace mode)

STAGE 6 — PRECEDENCE RESOLUTION (Which GPO wins if multiple GPOs set the same setting?)
→ Later GPOs in link order WIN (lowest link order number = highest priority)
→ Enforced GPOs win over non-enforced
→ Check: Is there a conflicting GPO higher in precedence?
→ Tool: gpresult /h C:\gpresult.html — shows applied GPOs and winning settings

DIAGNOSTIC COMMANDS:
```powershell
# On the target machine, run as the affected user:
gpresult /r           # Quick summary
gpresult /h C:\gp.html  # Full HTML report
gpupdate /force       # Force refresh (use cautiously)

# On a DC, check GPO permissions:
Get-GPPermission -Name "GPO Name" -All

# Check SYSVOL version vs AD version:
Get-GPO -Name "GPO Name" | Select DisplayName, Id, GpoStatus, *Version*
```

---

GPO PROBLEM DATA:
[Paste: GPO name, target OU, affected objects, gpresult output if available, what the GPO is supposed to do]

Analyze each stage. Identify exactly where the processing chain breaks.
```
