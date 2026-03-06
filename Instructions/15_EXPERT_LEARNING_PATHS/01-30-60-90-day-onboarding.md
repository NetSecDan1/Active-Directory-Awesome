# 30/60/90 Day Active Directory Engineer Onboarding Plan

> For engineers who are new to managing a production AD environment. This plan takes you from "where is everything?" to "I can handle this on my own."

---

## Before Day 1 — Mindset

Active Directory is the backbone of your organization's identity. When it breaks, nothing works. You are now a custodian of a system that thousands of people depend on every day. This means:

- **Read-only first**: When in doubt, observe before touching
- **Document everything**: Write down what you find, what you change, what you learn
- **Ask before acting**: No question is too basic; a wrong change can cause a P0
- **Own your mistakes**: When something goes wrong, escalate fast and honestly

---

## DAYS 1-30: ORIENT — Know Your Environment

### Week 1: Discovery

**Goal**: Know exactly what you have.

- [ ] Get read access to all DCs and management tools
- [ ] Run `Get-ADDomain` and `Get-ADForest` — understand the output
- [ ] List all DCs: `Get-ADDomainController -Filter *`
- [ ] Understand the site topology: `Get-ADReplicationSite -Filter *`
- [ ] Read the existing documentation (if any). Note gaps.
- [ ] Run `14_HTML_POWERSHELL_REPORTS/Invoke-ADHealthReport.ps1` — your first baseline
- [ ] Run `14_HTML_POWERSHELL_REPORTS/Invoke-PrivilegedAccessReport.ps1` — know who has power

**Know by end of Week 1:**
- How many forests, domains, DCs, sites do you have?
- Where are the FSMO role holders?
- Is replication healthy right now?
- Who are the Domain Admins?

### Week 2: Core Services

**Goal**: Understand what's running and why.

- [ ] Read `02_AD_DEEP_DIVE_GUIDES/06-Domain-Controller-Health.md`
- [ ] Run DCDiag on every DC: `dcdiag /s:[DCname] /v`
- [ ] Check replication: `repadmin /replsummary` and `repadmin /showrepl`
- [ ] Run the weekly health check: `13_RUNBOOKS/01-weekly-health-check.md`
- [ ] Understand what each DC service does: NTDS, NETLOGON, KDC, DNS, DFSR
- [ ] Locate and read any existing runbooks your team has

**AI Learning Session (30 min):**
```
Use 11_MASTER_AI_PROMPTS/10-learning-acceleration-prompts.md → Prompt 2
Topic: "How Domain Controller services work and what fails when each stops"
```

### Week 3: Authentication

**Goal**: Understand how users log in.

- [ ] Read `02_AD_DEEP_DIVE_GUIDES/02-Authentication-Kerberos.md`
- [ ] Shadow a Tier 1/2 ticket: watch how a lockout investigation is done
- [ ] Run a lockout investigation yourself with guidance: `13_RUNBOOKS/05-account-lockout-investigation.md`
- [ ] Understand Event IDs: 4624, 4625, 4740, 4771, 4776
- [ ] Find your PDC Emulator — know why it matters for lockouts

**Know by end of Week 3:**
- What is Kerberos? What is NTLM? When does each run?
- What causes account lockouts and where do you look first?
- What is the PDC Emulator's role in lockout processing?

### Week 4: Group Policy

**Goal**: Understand how policy gets applied.

- [ ] Read `02_AD_DEEP_DIVE_GUIDES/04-Group-Policy.md`
- [ ] Run `gpresult /r` on a workstation and interpret the output
- [ ] Generate an HTML GPResult: `gpresult /h C:\Temp\gp.html`
- [ ] Run `14_HTML_POWERSHELL_REPORTS/Invoke-GPOReport.ps1` — inventory your GPOs
- [ ] Find one GPO that's causing an issue or recently changed — understand what it does

**30-Day Milestone Check:**
- [ ] Can you independently run the weekly health check?
- [ ] Can you investigate a basic account lockout?
- [ ] Do you know how to get help safely? (who to escalate to, which runbooks exist)
- [ ] Have you introduced yourself to the application teams that depend on AD?

---

## DAYS 31-60: OPERATE — Handle Routine Work

### Week 5-6: DNS & Replication

- [ ] Read `02_AD_DEEP_DIVE_GUIDES/01-Replication-Issues.md`
- [ ] Read `02_AD_DEEP_DIVE_GUIDES/03-DNS-Integration.md`
- [ ] Understand the link between DNS health and DC locator
- [ ] Interpret `repadmin /showrepl` output on your own
- [ ] Know what error code 1722, 8453, and 8524 mean without looking them up
- [ ] Handle your first replication issue (with senior oversight)

### Week 7-8: Security Basics

- [ ] Read `security-hardening.md`
- [ ] Read `02_AD_DEEP_DIVE_GUIDES/10-Security-Incident-Response.md`
- [ ] Run `14_HTML_POWERSHELL_REPORTS/Invoke-ADSecurityPostureReport.ps1`
- [ ] Understand what Kerberoasting is and how to find vulnerable accounts
- [ ] Know what the Protected Users group does and who should be in it
- [ ] Know what LAPS is and whether your org has it

**Own these tasks by Day 60:**
- [ ] Account unlock and lockout investigation — independently
- [ ] Weekly health check — independently
- [ ] Basic GPO troubleshooting with gpresult
- [ ] Handling password resets and account management
- [ ] Creating your first Jira ticket using `12_JIRA_TEMPLATES/TASK-template.md`

**60-Day Milestone Check:**
- [ ] Have you run the weekly health check at least 4 times?
- [ ] Can you explain to a non-technical stakeholder what AD does and why it matters?
- [ ] Do you know who the top 5 application owners are who depend on AD?
- [ ] Have you documented something about your environment that wasn't documented before?

---

## DAYS 61-90: GROW — Build Expertise

### Week 9-10: Advanced Troubleshooting

- [ ] Work through `11_MASTER_AI_PROMPTS/02-chain-of-thought-diagnostics.md` — all 5 prompts
- [ ] Shadow or lead your first P1 incident response
- [ ] Read `01_IDENTITY_P0_COMMAND/p0_incident_commander_prompt.md`
- [ ] Understand the blast radius framework: `01_IDENTITY_P0_COMMAND/blast_radius_analysis.md`
- [ ] Read and understand `13_RUNBOOKS/07-replication-recovery.md`

### Week 11-12: Architecture & Hybrid

- [ ] Read `building-ad.md` — understand design principles
- [ ] Read `03_HYBRID_IDENTITY/entra_connect.md`
- [ ] Read `04_ENTRA_ID/sign_in_troubleshooting.md`
- [ ] Understand how your org uses Entra ID and how it connects to on-prem AD
- [ ] Learn PHS vs PTA vs ADFS — why did your org choose what it chose?

**Own these tasks by Day 90:**
- [ ] Participate in an incident response (as a contributor, not just observer)
- [ ] Complete a change request through CAB using `12_JIRA_TEMPLATES/CHANGE-REQUEST-template.md`
- [ ] Present a 10-minute summary of your AD environment to your team
- [ ] Write or update one runbook based on something you learned

**90-Day Milestone Assessment:**

Ask yourself — can you answer these without looking anything up?
1. Where is the PDC Emulator and what are its 5 main functions?
2. What are the 5 FSMO roles and what does each do?
3. How do you find the source of an account lockout?
4. What does `repadmin /replsummary` tell you and what's "bad"?
5. What is Kerberos pre-authentication and why does disabling it matter?
6. Name 3 things that can prevent a GPO from applying to a computer.
7. What is the KRBTGT account and why would you rotate its password?

If you can answer all 7 confidently: you've graduated from Day 90 onboarding.

---

## Ongoing: Stay Sharp

- **Weekly**: Run the health check. Note trends. Open tickets for issues.
- **Monthly**: Review security posture report. Review privileged access.
- **Quarterly**: Run stale account cleanup. Review GPO list. Update runbooks.
- **Annually**: Rotate KRBTGT (see `13_RUNBOOKS/04-krbtgt-rotation.md`). Test DR backup restore.
- **Always**: Use `11_MASTER_AI_PROMPTS/` to accelerate learning on any topic you encounter.
