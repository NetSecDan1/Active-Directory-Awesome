# 13_RUNBOOKS — Active Directory Operational Runbooks

> Production-grade runbooks for AD operations. Every step is verified, every write command has a rollback. Built for L2+ engineers who need to execute under pressure.

---

## Runbook Index

| File | Operation | Risk | Est. Time |
|------|-----------|------|-----------|
| [01-weekly-health-check.md](01-weekly-health-check.md) | Weekly AD health baseline | READ-ONLY | 45-60 min |
| [02-dc-promotion.md](02-dc-promotion.md) | Promote new Domain Controller | HIGH | 2-4 hours |
| [03-dc-decommission.md](03-dc-decommission.md) | Safely decommission a DC | HIGH | 2-3 hours |
| [04-krbtgt-rotation.md](04-krbtgt-rotation.md) | KRBTGT password rotation | MEDIUM | 3-4 hours |
| [05-account-lockout-investigation.md](05-account-lockout-investigation.md) | Lockout source investigation | READ-ONLY | 30-60 min |
| [06-fsmo-transfer.md](06-fsmo-transfer.md) | Transfer FSMO roles safely | HIGH | 1-2 hours |
| [07-replication-recovery.md](07-replication-recovery.md) | Recover from replication failures | HIGH | 1-4 hours |
| [08-ad-disaster-recovery.md](08-ad-disaster-recovery.md) | Full AD disaster recovery | CRITICAL | 4-24 hours |

---

## Runbook Usage Standards

1. **Read the full runbook** before executing any step
2. **Capture a baseline** before any write operation
3. **Confirm change window** is open before writing
4. **Run pre-checks** — never skip Phase 0
5. **Document** every command run and its output
6. **Stop and escalate** if you hit an unexpected result

## Risk Legend
- **READ-ONLY** — Zero risk, safe anytime
- **LOW** — Easily reversed, minimal blast radius
- **MEDIUM** — Recoverable with effort, test in lab first
- **HIGH** — Significant blast radius, requires CAB approval
- **CRITICAL** — Business-stopping if wrong, requires senior sign-off
