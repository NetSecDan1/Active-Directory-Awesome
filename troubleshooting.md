# AD Troubleshooting Prompts

**Use Case:** Systematic troubleshooting for specific AD problem categories.
**Techniques:** Elimination methodology, layered diagnosis, command-specific guidance

---

## Authentication Failure Troubleshooter

```
I have an authentication problem in Active Directory.

SYMPTOM:
[Describe exactly: user/computer can't authenticate, error message, affected services]

SCOPE:
[ ] Single user    [ ] Group of users    [ ] All users
[ ] Single machine [ ] Specific subnet   [ ] Domain-wide
[ ] Specific service/app only

AUTHENTICATION TYPE:
[ ] Kerberos   [ ] NTLM   [ ] LDAP bind   [ ] Not sure

ENVIRONMENT:
- Domain functional level:
- Affected user type: [domain user / service account / computer account]
- Error code (if known): [e.g., 0xC000006D, KDC_ERR_PREAUTH_FAILED]
- Event IDs seen: [e.g., 4625, 4771, 4776]

---

Guide me through diagnosing this step by step.

Start with: What are the most common causes for this exact symptom pattern?

For each potential cause, give me:
1. The exact diagnostic command to run
2. What output confirms this cause
3. What output rules it out
4. The fix if confirmed

Work through the layers: Network → DNS → DC availability → Account status → Kerberos/NTLM specifics
```

---

## Replication Troubleshooter

```
AD replication is failing or showing errors.

WHAT I'M SEEING:
[Paste repadmin /replsummary and/or repadmin /showrepl output]

ENVIRONMENT:
- Number of DCs:
- Number of sites:
- Functional level:
- Any recent changes (new DC, network change, firewall change):

---

Diagnose the replication issue:

1. Interpret the error codes in the output above
2. Identify which DCs and partitions are affected
3. For each error code: common causes and exact diagnostic steps
4. Recommended remediation sequence (order matters in AD replication repair)
5. Commands to verify repair

Common AD replication error codes I may encounter:
- 8453: Replication access denied
- 8606: Object not found
- 1722: RPC server unavailable
- 1256: Remote system not available
- 8524: DSA operation unable to proceed due to DNS lookup failure
- -2146893022: Target principal name incorrect (Kerberos)

Diagnose based on the output I provided.
```

---

## Account Lockout Investigator

```
Users are getting locked out. I need to find the source.

AFFECTED ACCOUNT(S):
[Username(s)]

LOCKOUT POLICY:
- Threshold: [X bad passwords]
- Observation window: [X minutes]
- Duration: [X minutes / manual unlock]

WHAT I'VE CHECKED SO FAR:
[Any initial investigation done]

---

Walk me through finding the lockout source:

Step 1 — Find the PDC Emulator (all lockouts process here first):
```powershell
Get-ADDomainController -Discover -Service PdcEmulator
```

Step 2 — Search for lockout events on PDC:
```powershell
Get-WinEvent -ComputerName <PDC> -FilterHashtable @{
    LogName='Security'
    Id=4740
    StartTime=(Get-Date).AddHours(-24)
} | Select -First 20 | Format-List TimeCreated, Message
```

Step 3 — Identify the source workstation from Event 4740

Step 4 — On the source workstation, look for bad password sources:
- Mapped drives with old credentials
- Scheduled tasks with saved credentials
- Services running as this account
- Saved Windows credentials
- Mobile devices syncing to Exchange/OWA
- Browser saved passwords
- Old RDP sessions

Step 5 — Specific PowerShell to check:
```powershell
# Check scheduled tasks for the account
Get-ScheduledTask | Where-Object { $_.Principal.UserId -like "*username*" }

# Check services running as the account
Get-WmiObject Win32_Service | Where-Object { $_.StartName -like "*username*" }
```

Based on my environment, what should I check first?
```

---

## GPO Not Applying Troubleshooter

```
A Group Policy Object is not applying as expected.

EXPECTED:
[What setting should be applying, to what target (user/computer)]

ACTUAL:
[What is actually happening — setting not applied, wrong value, etc.]

TARGET:
- Computer or User policy?
- Target OU:
- GPO name:
- Any WMI filters or security filtering?

GPRESULT OUTPUT:
[Paste: gpresult /r or gpresult /h output from affected machine/user]

---

Diagnose the GPO application failure:

1. Interpret the gpresult output — what does it show about which GPOs are/aren't applying?
2. Common failure reasons for this pattern:
   - Security filtering (computer/user not in the security group)
   - WMI filter returning false
   - GPO linked to wrong OU
   - Loopback processing
   - Slow link detection disabling policy
   - GPO not linked or link disabled
   - Conflicting settings from higher-precedence GPO

3. Specific diagnostic commands:
```powershell
# Detailed HTML report
gpresult /h C:\Temp\gpresult.html /f
# Open in browser

# Force policy refresh
gpupdate /force

# Check specific GPO application
Get-GPResultantSetOfPolicy -ReportType HTML -Path C:\Temp\rsop.html

# Verify GPO replication
Get-GPO -Name "<GPO Name>" | Select-Object -ExpandProperty Id |
  ForEach-Object { Test-Path "\\<DC>\SYSVOL\<domain>\Policies\{$_}" }
```

4. Event log checks:
```
Event ID 1085 — GPO processing failed (with error details)
Event ID 1006 — GPO download failed
Event ID 1030 — GPO processing failed (Winlogon)
Source: Group Policy (Application and Services Logs > Microsoft > Windows > Group Policy > Operational)
```
```

---

## DNS Troubleshooter (AD-Integrated)

```
DNS is causing AD issues. Symptoms:
[Describe: logon failures, replication errors, DC location failures, etc.]

AD DNS ENVIRONMENT:
- DNS hosted on: [ ] DCs only [ ] Dedicated DNS servers [ ] Mixed
- Zone type: [ ] AD-Integrated [ ] Standard primary [ ] Not sure
- Forwarders configured: [yes/no/unknown]

---

Systematic DNS diagnosis for Active Directory:

```powershell
# 1. Verify DC can be found via DNS
nltest /dsgetdc:<domain.com> /force
nslookup <domain.com>

# 2. Check SRV records (critical for AD)
nslookup -type=SRV _ldap._tcp.dc._msdcs.<domain.com>
nslookup -type=SRV _kerberos._tcp.dc._msdcs.<domain.com>
nslookup -type=SRV _gc._tcp.<domain.com>

# 3. Run DCDiag DNS test
dcdiag /test:DNS /v /e /f:C:\Temp\dcdiag-dns.txt

# 4. Check DNS registration on each DC
ipconfig /registerdns
# Wait 15 min, then verify SRV records re-appeared

# 5. Check for DNS scavenging issues
# (Old stale records can cause DC location failures)
Get-DnsServerZone | Select ZoneName,IsReverseLookupZone,ZoneType

# 6. Verify DC has correct DNS server configured
Get-DnsClientServerAddress -InterfaceAlias Ethernet
# DCs should point to themselves FIRST, then another DC
```

Common AD DNS mistakes:
- DCs pointing to external DNS (not AD-integrated DNS)
- DCs pointing only to themselves with no secondary
- Missing or stale SRV records
- Scavenging not enabled (causing stale records to accumulate)
- Incorrect reverse lookup zones
```

---

**Tips:**
- For any auth issue: always check the PDC Emulator's Security log first — it processes all lockouts and some auth decisions
- `dcdiag /v` should be the first command run on any DC you suspect has issues
- Replication errors: fix the oldest errors first — newer ones often cascade from original failures
- GPO: HTML report from `gpresult /h` is 10x more readable than /r text output
- DNS: if in doubt, `dcdiag /test:DNS /v /e` — it checks all DCs automatically
