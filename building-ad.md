# Building Active Directory

**Use Case:** Design and build new AD infrastructure, migrate domains, add sites, or redesign an existing environment.
**Techniques:** AD design principles, naming conventions, site topology, OU design, delegation model

---

## New AD Design Prompt

```
You are a Microsoft-certified Active Directory architect. I need to design [new AD forest / new domain / domain restructure / site design].

REQUIREMENTS:
- Organization type: [size, industry, geographic locations]
- User count: [total and by location]
- Server count: [total and by location]
- Applications: [key apps that integrate with AD — Exchange, M365, SAP, etc.]
- Cloud: [Entra ID / M365 hybrid required? Yes/No]
- Regulatory: [compliance requirements — HIPAA, PCI, SOX, etc.]
- Existing infrastructure: [what exists today if migrating/extending]

CONSTRAINTS:
- Network: [WAN links between sites — speed and reliability]
- IT team: [size and AD expertise level]
- Budget: [hardware/licensing constraints]

---

Design the Active Directory infrastructure:

## 1. Forest & Domain Design
- Single domain or multi-domain? Justify.
- Forest trust requirements
- Domain naming strategy
- UPN suffix strategy

## 2. OU Structure Design
Design the OU hierarchy following these principles:
- Separate OUs for GPO application vs. administration delegation
- Computers by function (servers vs. workstations) and location
- Users by department or role
- Service accounts in dedicated OU
- Staging OU for new object processing

```
[Domain.com]
├── [STAGING] — new objects land here before being moved
├── COMPUTERS
│   ├── Servers
│   │   ├── Tier0 (DCs, PKI, ADFS)
│   │   ├── Tier1 (Member servers)
│   │   └── Tier1-[Location]
│   ├── Workstations
│   │   ├── Managed
│   │   └── [Location]
│   └── Servers-Decommission
├── USERS
│   ├── [Department]
│   └── ...
├── SERVICE ACCOUNTS
├── GROUPS
│   ├── Security-[Department]
│   ├── Distribution-[Name]
│   └── Roles-[Role]
├── ADMIN ACCOUNTS
│   ├── Tier0-Admins
│   ├── Tier1-Admins
│   └── Tier2-Admins
└── [COMPANY]-Disabled
```

## 3. DC Placement & Site Design
- DC count per site (minimum 2 per site with users)
- Global Catalog placement
- Site link design (cost, replication schedule)
- Sites and Services topology

## 4. DNS Design
- AD-integrated DNS zones
- Primary/secondary structure
- Forwarder configuration
- Stub zones for trusts
- Reverse lookup zones

## 5. FSMO Role Placement
- Schema Master: [recommended DC]
- Domain Naming Master: [recommended DC]
- PDC Emulator: [recommended DC — put on best-connected DC]
- RID Master: [recommended DC]
- Infrastructure Master: [recommended DC — NOT on GC if multi-domain]

## 6. Group Policy Design
- Core GPO structure
- Baseline GPOs
- Naming convention: [Scope]-[Category]-[Description]-[v1]
- Recommended GPO count target (fewer is better)

## 7. Admin Model & Delegation
Who can do what:
- Domain Admins: Only for AD administration tasks
- Help Desk: Unlock accounts, reset passwords
- Server admins: Manage specific OUs
- Application owners: Manage their service accounts

Delegation tasks and delegation script.

## 8. Hybrid Identity (if applicable)
- Entra Connect design (sync vs. federation)
- Attribute filtering strategy
- UPN alignment
- Password hash sync vs. PTA vs. ADFS

## 9. Implementation Sequence
What order to build this in. What to test at each stage before proceeding.
```

---

## Migration Planning Prompt

```
I need to migrate from [source AD environment] to [target AD environment].

Source: [describe current environment — OS levels, domain structure, number of objects]
Target: [desired end state]
Reason for migration: [domain consolidation, OS upgrade, acquisition, etc.]
Objects to migrate: [users, computers, groups, GPOs, other]
Applications: [AD-integrated apps that need special handling]
Timeline: [when must this be complete?]

Design the migration approach:

1. Discovery — what to inventory before migrating
2. Migration tool selection (ADMT, Quest Migration Manager, native tools)
3. SID history considerations
4. Cutover strategy (big bang vs. phased)
5. DNS and trust requirements during migration
6. Rollback plan
7. User communication plan
8. Application remediation sequence
9. Verification checklist post-migration
```

---

## Site Topology Design

```
My organization has these physical locations:
[List locations with approximate user/server counts and WAN link speeds between them]

Design AD Sites and Services topology:
1. Site definitions (one site per subnet block generally)
2. Subnet assignments
3. Site link objects and costs
4. Site link bridges
5. DC placement in each site
6. Preferred bridgehead servers
7. Replication schedule recommendations

Output as:
- Sites list with subnets
- Site links table (from → to, cost, schedule)
- DC placement table (site, DC name, GC: Y/N, FSMO roles)
```

---

**Tips:**
- OU design: optimize for GPO application and delegation, not org chart representation
- More than 20 GPOs linked to a domain is a design smell — redesign before adding more
- DCs should NEVER be used for anything else (no apps, no file sharing, no WSUS)
- Sites and Services: cost 100 = preferred, cost 200 = backup link — use relative costs
- Entra Connect: install on a member server, never on a DC
- Domain prep: test adprep /forestprep and /domainprep in staging before production
