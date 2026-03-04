# Active Directory Prompts

Specialized prompts for AD and identity engineers. Covers everything from troubleshooting auth failures to designing delegation models, GPOs, and hybrid identity with Entra ID.

## Files

| File | Use Case |
|------|----------|
| [solve-anything-ad.md](./solve-anything-ad.md) | Universal AD problem solver for any situation |
| [troubleshooting.md](./troubleshooting.md) | Systematic troubleshooting for auth, replication, DNS, and more |
| [gpo-builder.md](./gpo-builder.md) | Design and document Group Policy Objects |
| [learning-ad.md](./learning-ad.md) | Learn Active Directory concepts at any level |
| [building-ad.md](./building-ad.md) | Design and build AD infrastructure — new or migrate |
| [security-hardening.md](./security-hardening.md) | AD security, tiering, red team defense |
| [powershell-expert.md](./powershell-expert.md) | AD PowerShell one-liners and scripts |
| [splunk-query-builder.md](./splunk-query-builder.md) | Build Splunk queries for AD and Windows event logs |

## Quick Reference — AD Event IDs

| Event ID | Meaning |
|----------|---------|
| 4624 | Successful logon |
| 4625 | Failed logon |
| 4648 | Logon with explicit credentials |
| 4662 | Object operation (audit) |
| 4663 | Object access attempt |
| 4720 | User account created |
| 4722 | User account enabled |
| 4723 | Password change attempt |
| 4724 | Password reset attempt |
| 4725 | User account disabled |
| 4728 | Member added to global group |
| 4732 | Member added to local group |
| 4740 | Account lockout |
| 4756 | Member added to universal group |
| 4769 | Kerberos service ticket request |
| 4771 | Kerberos pre-auth failed |
| 4776 | NTLM authentication |
| 5136 | Directory object modified |
| 5137 | Directory object created |
| 5141 | Directory object deleted |

## Quick Reference — Common AD Ports

| Port | Service |
|------|---------|
| 389 | LDAP |
| 636 | LDAPS |
| 3268 | Global Catalog LDAP |
| 3269 | Global Catalog LDAPS |
| 88 | Kerberos |
| 464 | Kerberos password change |
| 53 | DNS |
| 445 | SMB (Sysvol/Netlogon) |
| 135 | RPC Endpoint Mapper |
| 49152-65535 | RPC Dynamic Ports |
