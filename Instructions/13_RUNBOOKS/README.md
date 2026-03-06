# 13_RUNBOOKS — Active Directory Operational Runbooks

> Production-grade runbooks for AD operations. Every step is verified, every write command has a rollback. Built for L2+ engineers who need to execute under pressure.
>
> **Design principle**: Every runbook opens with a **Phase 0 — Information Gathering** step. Never proceed without answering those questions first.

---

## Runbook Index

### Operations & Maintenance

| # | File | Operation | Risk | Est. Time |
|---|------|-----------|------|-----------|
| 01 | [01-weekly-health-check.md](01-weekly-health-check.md) | Weekly AD health baseline | READ-ONLY | 45–60 min |
| 02 | [02-dc-promotion.md](02-dc-promotion.md) | Promote new Domain Controller | HIGH | 2–4 hours |
| 03 | [03-dc-decommission.md](03-dc-decommission.md) | Safely decommission a DC | HIGH | 2–3 hours |
| 04 | [04-krbtgt-rotation.md](04-krbtgt-rotation.md) | KRBTGT password rotation | MEDIUM | 3–4 hours |
| 06 | [06-fsmo-transfer.md](06-fsmo-transfer.md) | Transfer FSMO roles safely | HIGH | 1–2 hours |
| 07 | [07-replication-recovery.md](07-replication-recovery.md) | Recover from replication failures | HIGH | 1–4 hours |
| 08 | [08-ad-disaster-recovery.md](08-ad-disaster-recovery.md) | Full AD disaster recovery | CRITICAL | 4–24 hours |

### Troubleshooting

| # | File | Operation | Risk | Est. Time |
|---|------|-----------|------|-----------|
| 05 | [05-account-lockout-investigation.md](05-account-lockout-investigation.md) | Lockout source investigation | READ-ONLY | 30–60 min |
| 09 | [09-dns-troubleshooting.md](09-dns-troubleshooting.md) | DNS resolution & SRV record triage | READ-ONLY | 30–90 min |
| 10 | [10-kerberos-failure-triage.md](10-kerberos-failure-triage.md) | Kerberos auth failure by error code | READ-ONLY | 45–90 min |
| 11 | [11-gpo-not-applying.md](11-gpo-not-applying.md) | Group Policy not applying investigation | READ-ONLY | 30–75 min |
| 14 | [14-spn-delegation-troubleshooting.md](14-spn-delegation-troubleshooting.md) | SPN audit & Kerberos delegation fix | READ-ONLY | 45–90 min |
| 16 | [16-ad-cs-pki-troubleshooting.md](16-ad-cs-pki-troubleshooting.md) | AD CS / PKI certificate triage | READ-ONLY | 45–120 min |
| 17 | [17-entra-connect-sync-troubleshooting.md](17-entra-connect-sync-troubleshooting.md) | Entra Connect sync failures | READ-ONLY | 45–120 min |
| 18 | [18-conditional-access-troubleshooting.md](18-conditional-access-troubleshooting.md) | Conditional Access policy failures | READ-ONLY | 30–90 min |

### ETFC — End-to-End Functional Checks

| # | File | Operation | Risk | Est. Time |
|---|------|-----------|------|-----------|
| 12 | [12-forest-trust-etfc.md](12-forest-trust-etfc.md) | Forest trust full health validation | READ-ONLY | 45–90 min |
| 13 | [13-cross-forest-auth-troubleshooting.md](13-cross-forest-auth-troubleshooting.md) | Cross-forest authentication failure | READ-ONLY | 45–120 min |

### Security Audits

| # | File | Operation | Risk | Est. Time |
|---|------|-----------|------|-----------|
| 15 | [15-mdi-sensor-health-troubleshooting.md](15-mdi-sensor-health-troubleshooting.md) | MDI sensor health issues (all 29 alert types) | READ-ONLY | 30–120 min |
| 19 | [19-privileged-identity-tier-audit.md](19-privileged-identity-tier-audit.md) | Tier 0/1/2 & shadow admin audit | READ-ONLY | 60–120 min |

---

## Runbook Usage Standards

1. **Read the full runbook** before executing any step
2. **Complete Phase 0** — answer all information gathering questions before proceeding
3. **Capture a baseline** before any write operation
4. **Confirm change window** is open before writing
5. **Document** every command run and its output in the Jira ticket
6. **Stop and escalate** if you hit an unexpected result

## Risk Legend

| Level | Meaning |
|-------|---------|
| **READ-ONLY** | Zero risk, safe to run anytime |
| **LOW** | Easily reversed, minimal blast radius |
| **MEDIUM** | Recoverable with effort, test in lab first |
| **HIGH** | Significant blast radius, requires CAB approval |
| **CRITICAL** | Business-stopping if wrong, requires senior sign-off |

## Story Point Guide (for Jira cards linked to runbook execution)

| Runbook type | Suggested points |
|-------------|-----------------|
| READ-ONLY investigation only | 1–2 |
| Investigation + targeted fix | 2–4 |
| Multi-phase change with verification | 4 |
| Critical / disaster recovery | 8 → break into child stories |
