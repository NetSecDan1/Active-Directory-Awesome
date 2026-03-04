# Microsoft Certification Prep: AZ-800 & MS-102

> AI-accelerated study guides for the two most relevant Microsoft certifications for AD/Identity engineers. Beat the exams and actually learn the content deeply — not just exam tricks.

---

## Which Exam First?

| Exam | Focus | Ideal For |
|------|-------|-----------|
| **AZ-800** — Administering Windows Server Hybrid Core Infrastructure | On-prem AD, DNS, DHCP, Storage, Hyper-V, Hybrid | AD engineers moving toward hybrid |
| **MS-102** — Microsoft 365 Administrator Expert | Entra ID, M365, Compliance, Security | Engineers managing Entra/M365 |

**Recommendation**: AZ-800 first if you're on-prem heavy. MS-102 first if you're already hybrid/cloud.

---

## AZ-800 EXAM PREP

### Exam Blueprint (as of 2025)

| Domain | Weight | Key Topics |
|--------|--------|-----------|
| Deploy and manage AD DS on-premises and in Azure | ~25% | Domain/forest design, DC promotion, DFL, RODC, Azure AD DS |
| Manage Windows Server and workloads in a hybrid environment | ~20% | Azure Arc, Azure Hybrid services, Windows Admin Center |
| Manage virtual machines and containers | ~15% | Hyper-V, Azure Migrate, containers |
| Implement and manage an on-premises and hybrid networking infrastructure | ~20% | DNS, DHCP, IPAM, BGP basics |
| Manage storage and file services | ~20% | DFS, FSRM, Storage Spaces, Azure File Sync |

### AZ-800 High-Value Study Topics (Identity Focus)

**Domain: AD DS On-Premises and in Azure**

```
High-probability exam topics:
✓ When to use RODC vs writable DC
✓ FSMO role functions and placement best practices
✓ Domain and forest functional level features per version
✓ AD DS on Azure IaaS (VM-based DCs) — when and how
✓ Azure AD DS (managed service) — limitations vs on-prem
✓ AD replication: intra-site vs inter-site, KCC, ISTG
✓ Group Policy: processing order, precedence, filtering
✓ Fine-Grained Password Policies (PSOs)
✓ LAPS configuration and management
✓ AD recycle bin — enabling and using
✓ Protected Users security group
```

**AI Study Session — AZ-800:**
```
Paste into Claude/GPT:

"I'm studying for AZ-800. Teach me [TOPIC] with these constraints:
- Focus on what Microsoft tests, not just what's technically interesting
- Give me 5 exam-style questions after explaining the concept
- Tell me the common wrong answers and why they're wrong
- Use real-world scenarios that match what the exam tests"

Topics to cycle through:
1. FSMO roles — functions, placement, transfer vs seizure
2. RODC — when to use, PRP, filtered attribute set
3. Group Policy — processing order, security filtering, WMI filters, loopback
4. DNS scavenging — when and how to configure
5. Azure AD DS — what it can and can't do vs on-prem AD
6. AD replication — USN, USN rollback, lingering objects
7. Fine-Grained Password Policies — how to create, apply, precedence
```

### AZ-800 Practice Questions — AD Domain

```
Test yourself — answer without looking:

1. You need to ensure branch office users can authenticate even when the WAN is down.
   What DC type should you deploy at the branch?
   → RODC. Caches subset of passwords locally per PRP.

2. A company has a child domain and a parent domain. The Infrastructure Master for the
   child domain is on a DC that is also a Global Catalog. Only one GC exists.
   Is this a problem?
   → YES — unless ALL DCs are GCs. IM needs to compare its data with GC data.
   If IM is on GC when not all DCs are GC = cross-domain membership display issues.

3. What Windows Server 2016 domain functional level feature prevents accidental deletion
   of domain controllers?
   → Active Directory Recycle Bin + Protected from Accidental Deletion flag.
   DFL 2008 R2 = AD Recycle Bin.

4. What is the maximum password age in a Fine-Grained Password Policy?
   → Configurable — can be different from Default Domain Policy. Min precedence value wins.

5. Which FSMO role is responsible for generating RID pools for DCs?
   → RID Master. DCs get pools of 500 RIDs at a time.

6. You want to prevent Kerberos delegation from a specific server.
   What group should you add the server's computer account to?
   → Protected Users (for users/computers) — disables delegation entirely.
   Or: Set "Account is sensitive and cannot be delegated" on the account.
```

---

## MS-102 EXAM PREP

### Exam Blueprint (as of 2025)

| Domain | Weight | Key Topics |
|--------|--------|-----------|
| Deploy and manage a Microsoft 365 tenant | ~25% | Tenant setup, licensing, service health |
| Implement and manage identity and access | ~35% | Entra ID, MFA, Conditional Access, PIM, SSPR |
| Manage security and threats | ~25% | MDO, MDE, Defender for Cloud Apps, Purview |
| Manage compliance | ~15% | DLP, retention, eDiscovery |

### MS-102 High-Value Study Topics (Identity Focus)

```
Must-know for the exam:

Entra ID:
✓ License requirements (P1 vs P2 vs Free) for each feature
✓ Conditional Access policy components (signals → decisions → controls)
✓ Named locations — IP ranges, countries, MFA trusted IPs
✓ Authentication strengths — when to require FIDO2 vs MFA vs passwordless
✓ Sign-in risk vs user risk — what each means, how policies differ
✓ SSPR — registration requirements, authentication methods, writeback

PIM (Privileged Identity Management) — VERY heavily tested:
✓ Eligible vs Active assignment
✓ Activation workflow: request → approve → time-limited access
✓ Access reviews for privileged roles
✓ Alert types PIM generates

Hybrid Identity:
✓ PHS vs PTA vs ADFS — trade-offs, when to use each
✓ Password writeback — what requires it (SSPR, PIM hybrid)
✓ AAD Connect health monitoring
✓ Seamless SSO — how it works, prerequisites
✓ Staged rollout — what it is, which features support it

Multi-factor Authentication:
✓ MFA methods: FIDO2, Microsoft Authenticator, OATH tokens, SMS, voice
✓ MFA registration vs enforcement via Conditional Access vs Security Defaults
✓ Number matching and additional context (anti-MFA-fatigue)
✓ Temporary Access Pass — use case, configuration
```

**AI Study Session — MS-102:**
```
"I'm studying for MS-102. I need to deeply understand Conditional Access.
Teach me:
1. The exact components of a CA policy (Assignments → Access Controls)
2. The difference between 'Require MFA' and 'Require authentication strength'
3. How Sign-in Risk integrates with CA (requires which license?)
4. Common exam scenarios: guest access, break-glass accounts, compliant device requirements
5. Give me 5 scenario-based questions in the style of the MS-102 exam"
```

### MS-102 Practice Questions — Entra/Identity

```
Test yourself:

1. A user's account is at HIGH risk in Entra ID Protection. You want to force them to
   change their password immediately. What's the correct configuration?
   → User Risk Policy set to HIGH risk → Require password change.
   (Requires Entra ID P2 license)

2. You want to require FIDO2 security key for all Global Administrators.
   What CA policy control do you use?
   → Access Controls → Grant → Require authentication strength → select/create strength
   requiring FIDO2.

3. PIM requires approval for a role activation. The approver is unavailable.
   How long does the request stay pending before expiring?
   → 24 hours (configurable, default is 24h).

4. An organization uses PHS. A user changes their on-premises AD password.
   How long until the new password works in Entra ID?
   → Within 2 minutes (near real-time sync).
   Exception: if it's the first sync after initial install, up to 30 minutes.

5. What Entra ID feature allows you to grant a user temporary MFA bypass
   when they've lost their authenticator?
   → Temporary Access Pass (TAP) — time-limited, one-time use passcode.
```

---

## Study Schedule Template (8 Weeks)

| Week | AZ-800 Focus | MS-102 Focus | Practice |
|------|-------------|-------------|---------|
| 1 | AD DS design, FSMO, functional levels | Entra ID fundamentals, license tiers | 20 Q each |
| 2 | Replication, DNS, DHCP | Conditional Access deep dive | 30 Q each |
| 3 | GPO, LAPS, Fine-Grained Policies | PIM — eligible vs active, access reviews | 30 Q each |
| 4 | RODC, AD CS, trusts | Hybrid identity: PHS/PTA/ADFS | 30 Q each |
| 5 | Azure AD DS, Azure Arc, hybrid mgmt | MFA, SSPR, Entra ID Protection | 40 Q each |
| 6 | Storage, DFS, Azure File Sync | MDO, MDE, Defender for Cloud Apps | 40 Q each |
| 7 | Full practice exam (AZ-800) | Full practice exam (MS-102) | Review misses |
| 8 | Targeted review of weak areas | Targeted review of weak areas | Exam day |

---

## Exam Day Tips

- **Read scenarios carefully** — Microsoft tests what you would do, not just what you know
- **Eliminate obviously wrong answers** — usually 2 of 4 are clearly wrong
- **Watch for "FIRST" and "ONLY"** — these constrain the answer significantly
- **License-sensitive questions** — always note if P1 or P2 is in scope
- **Know your roll-ups** — what features are included at each tier

---

## Resources

- **Official learning paths**: [Microsoft Learn](https://learn.microsoft.com) — free, exam-aligned
- **Practice exams**: MeasureUp (official) — worth the cost for final prep
- **John Savill's YouTube** — exceptional deep dives on AZ-800 and MS-102 topics
- **This repo**: `02_AD_DEEP_DIVE_GUIDES/` covers ~60% of AZ-800 AD content
- **AI sessions**: Use `11_MASTER_AI_PROMPTS/10-learning-acceleration-prompts.md` Prompt 5 (Interview Prep) as exam prep
