# Change Risk Matrix

## Decision Authority & Blast Radius Control for Identity Operations

> **Critical**: During a P0 incident, every action has consequences. This matrix defines what the AI can recommend, what requires human approval, and what is absolutely forbidden during an active incident.

---

## Action Classification System

### Classification Levels

| Level | Icon | Meaning | AI Authority |
|-------|------|---------|--------------|
| **SAFE** | `[SAFE]` | Read-only, no state change, no risk | Can recommend and guide execution |
| **ADVISORY** | `[ADVISORY]` | Low risk but changes state | Can recommend, human executes |
| **APPROVAL REQUIRED** | `[APPROVAL]` | Moderate risk, reversible | Must get explicit approval before recommending |
| **ELEVATED APPROVAL** | `[ELEVATED]` | High risk, may be irreversible | Requires senior engineer + change management |
| **FORBIDDEN** | `[FORBIDDEN]` | Extreme risk, potentially catastrophic | Never recommend during P0 |

---

## Active Directory Operations Matrix

### Domain Controller Operations

| Operation | Classification | Blast Radius | Justification |
|-----------|---------------|--------------|---------------|
| `dcdiag /v` | `[SAFE]` | None | Read-only diagnostic |
| `repadmin /replsummary` | `[SAFE]` | None | Read-only status |
| `repadmin /showrepl` | `[SAFE]` | None | Read-only status |
| `nltest /dsgetdc` | `[SAFE]` | None | Read-only query |
| `Get-ADDomainController` | `[SAFE]` | None | Read-only query |
| **Restart NETLOGON service** | `[ADVISORY]` | Single DC | May cause brief auth failures to that DC |
| **Restart DNS service** | `[ADVISORY]` | Single DC | May cause brief resolution failures |
| **Restart NTDS service** | `[APPROVAL]` | Single DC | DC temporarily unavailable |
| **Reboot Domain Controller** | `[APPROVAL]` | Single DC | DC offline during reboot |
| `repadmin /syncall /force` | `[ADVISORY]` | Network bandwidth | Forces immediate replication |
| **Force KCC recalculation** | `[ADVISORY]` | Replication topology | May change connections |

### FSMO Role Operations

| Operation | Classification | Blast Radius | Justification |
|-----------|---------------|--------------|---------------|
| `netdom query fsmo` | `[SAFE]` | None | Read-only query |
| **Transfer FSMO role** | `[APPROVAL]` | Domain/Forest | Role moves to new DC |
| **Seize FSMO role** | `[ELEVATED]` | Domain/Forest | Irreversible, original holder must never return |
| **Seize Schema Master** | `[ELEVATED]` | Entire Forest | Irreversible, forest-wide impact |
| **Seize RID Master** | `[ELEVATED]` | Domain | Risk of duplicate SIDs |

### Replication Operations

| Operation | Classification | Blast Radius | Justification |
|-----------|---------------|--------------|---------------|
| Check replication status | `[SAFE]` | None | Read-only |
| `repadmin /replicate` (single) | `[ADVISORY]` | Single DC pair | Forces one replication |
| `repadmin /syncall /A /e` | `[APPROVAL]` | All DCs | Forces enterprise-wide replication |
| **Remove lingering objects (advisory)** | `[ADVISORY]` | Target DC | Read-only detection |
| **Remove lingering objects (delete)** | `[APPROVAL]` | Target DC | Permanent deletion |
| **Force authoritative restore** | `[ELEVATED]` | Domain/Forest | May overwrite newer changes |

### Account Operations

| Operation | Classification | Blast Radius | Justification |
|-----------|---------------|--------------|---------------|
| `Get-ADUser` queries | `[SAFE]` | None | Read-only |
| `Unlock-ADAccount` | `[ADVISORY]` | Single user | Low risk, easily reversible |
| `Reset-ADPassword` | `[ADVISORY]` | Single user | User loses access until informed |
| `Disable-ADAccount` | `[ADVISORY]` | Single user | Reversible |
| **Reset krbtgt password (first)** | `[ELEVATED]` | All Kerberos auth | Major impact, planned activity |
| **Reset krbtgt password (second)** | `[ELEVATED]` | All Kerberos auth | Invalidates all tickets |
| **Mass password reset** | `[ELEVATED]` | All affected users | Major business disruption |

### Secure Channel Operations

| Operation | Classification | Blast Radius | Justification |
|-----------|---------------|--------------|---------------|
| `Test-ComputerSecureChannel` | `[SAFE]` | None | Read-only test |
| `Test-ComputerSecureChannel -Repair` | `[ADVISORY]` | Single computer | Usually safe, may fail |
| **Reset DC machine account** | `[APPROVAL]` | Single DC | DC may lose trust |
| `netdom resetpwd` on DC | `[APPROVAL]` | Single DC | Replication must be working |

### Metadata & Cleanup Operations

| Operation | Classification | Blast Radius | Justification |
|-----------|---------------|--------------|---------------|
| **Metadata cleanup (ntdsutil)** | `[ELEVATED]` | Domain | Permanent removal, cannot undo |
| **Force remove DC from AD** | `[ELEVATED]` | Domain | Must be certain DC won't return |
| **Delete orphaned objects** | `[APPROVAL]` | Varies | Must verify orphaned status |

---

## Hybrid Identity Operations Matrix

### Azure AD Connect

| Operation | Classification | Blast Radius | Justification |
|-----------|---------------|--------------|---------------|
| `Get-ADSyncScheduler` | `[SAFE]` | None | Read-only |
| View sync errors | `[SAFE]` | None | Read-only |
| `Start-ADSyncSyncCycle -Delta` | `[ADVISORY]` | Sync cycle | Normal operation |
| `Start-ADSyncSyncCycle -Initial` | `[APPROVAL]` | Full resync | Resource intensive, may take hours |
| **Disable sync scheduler** | `[APPROVAL]` | All sync stops | Objects diverge |
| **Enable staging mode** | `[APPROVAL]` | Sync stops export | Safe but sync stops |
| **Disable staging mode** | `[ELEVATED]` | Becomes active | May cause conflicts if another active |
| **Reinstall AAD Connect** | `[ELEVATED]` | All sync | Major operation |

### Password Sync & Writeback

| Operation | Classification | Blast Radius | Justification |
|-----------|---------------|--------------|---------------|
| Check PHS status | `[SAFE]` | None | Read-only |
| Force password sync for user | `[ADVISORY]` | Single user | Usually safe |
| **Disable password hash sync** | `[ELEVATED]` | All password sync | Users may lose cloud access |
| **Disable password writeback** | `[ELEVATED]` | SSPR functionality | Users can't reset passwords |

---

## Certificate Services Operations

| Operation | Classification | Blast Radius | Justification |
|-----------|---------------|--------------|---------------|
| View CA status | `[SAFE]` | None | Read-only |
| View certificate templates | `[SAFE]` | None | Read-only |
| Publish CRL manually | `[ADVISORY]` | CRL consumers | Normal operation |
| **Revoke certificate** | `[APPROVAL]` | Certificate holder | Permanent, affects holder |
| **Modify certificate template** | `[APPROVAL]` | All new issuances | Changes enrollment behavior |
| **Renew CA certificate** | `[ELEVATED]` | All issued certs | Major PKI operation |
| **Restore CA from backup** | `[ELEVATED]` | All PKI operations | Major recovery |

---

## Forbidden During Active P0

These operations are **NEVER** recommended during an active P0 incident:

```
ABSOLUTELY FORBIDDEN DURING P0:

[ ] Schema modifications
[ ] Domain/forest functional level changes
[ ] Trust relationship creation or deletion
[ ] AD Sites and Services topology changes (new sites, site links)
[ ] GPO creation or major modification
[ ] FSMO role seizure (unless loss confirmed and approved)
[ ] Demoting domain controllers
[ ] Promoting new domain controllers
[ ] Forest recovery procedures
[ ] Migration operations (FRS to DFS-R, etc.)
[ ] Adding or removing domains
[ ] Bulk object deletions
[ ] Security principal migrations
[ ] Disabling all members of critical groups
```

---

## Approval Workflow Templates

### Standard Approval Request

```
APPROVAL REQUEST - [Operation Name]

CLASSIFICATION: [APPROVAL] / [ELEVATED]
REQUESTED BY: [Name]
DATE/TIME: [Timestamp]

CURRENT INCIDENT: [P0/P1/P2/P3]
INCIDENT TICKET: [Number]

OPERATION DETAILS:
- Action: [Exact operation]
- Target: [Specific target - DC, user, etc.]
- Expected outcome: [What should happen]
- Blast radius: [What could be affected]

JUSTIFICATION:
- Why is this necessary?
- What alternatives were considered?
- What is the risk of NOT doing this?

ROLLBACK PLAN:
- How to reverse if needed
- Time required for rollback
- Dependencies for rollback

APPROVERS REQUIRED:
- [ ] Senior AD Engineer
- [ ] Change Manager (if outside emergency)
- [ ] Security (if security-related)
- [ ] Business stakeholder (if user impact)

APPROVAL STATUS: [PENDING / APPROVED / DENIED]
```

### Emergency Override Protocol

```
EMERGENCY OVERRIDE - P0 ONLY

This protocol is for situations where:
- Standard approval timeline will cause unacceptable business damage
- The issue is actively causing widespread outage
- Senior decision-maker is unavailable

REQUIREMENTS FOR EMERGENCY OVERRIDE:
1. Document the emergency clearly
2. Obtain verbal approval from available senior resource
3. Document who approved and when
4. Execute with another engineer as witness
5. Full documentation within 1 hour of action
6. Formal review within 24 hours

OVERRIDE AUTHORITY:
- Identity Team Lead or above
- On-call senior engineer
- Incident Commander

STILL FORBIDDEN EVEN WITH OVERRIDE:
- Schema modifications
- Forest-level changes
- Actions with unknown blast radius
```

---

## Blast Radius Assessment Framework

Before recommending any `[APPROVAL]` or `[ELEVATED]` action:

```
BLAST RADIUS ASSESSMENT:

1. DIRECT IMPACT
   - What systems/users are directly affected?
   - How many? (Quantify)
   - What functionality is lost?

2. INDIRECT IMPACT
   - What depends on the affected systems?
   - Cascading failures possible?
   - Cross-team dependencies?

3. TEMPORAL IMPACT
   - How long will impact last?
   - Is it immediate or delayed?
   - When will normal service resume?

4. REVERSIBILITY
   - Can this be undone?
   - How long to reverse?
   - What is lost if reversed?

5. BUSINESS IMPACT
   - Revenue affected?
   - Customer-facing?
   - Regulatory implications?
   - Reputational risk?

BLAST RADIUS SCORE: [LOW / MEDIUM / HIGH / CRITICAL]
```

---

## Related Documents

- [Truth and Confidence](truth_and_confidence.md) - When to stop and ask
- [Safe Troubleshooting Rules](safe_troubleshooting_rules.md) - What is always safe
- [Executive Translation](../01_IDENTITY_P0_COMMAND/executive_translation.md) - Communicating risk
