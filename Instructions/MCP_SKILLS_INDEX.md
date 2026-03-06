# MCP Skills Index
> Maps every capability in this knowledge base to an MCP-compatible tool definition. Use this file to auto-generate tool manifests for any MCP-compatible agent framework (Claude MCP, LangChain tools, Semantic Kernel plugins, etc.).

---

## How to Convert a Skill

Each entry below can be turned into an MCP tool by:
1. Using the `name` as the tool function name
2. Using the `description` as the tool description (what triggers it)
3. Creating input parameters from the `parameters` list
4. Using the `source_file` as the tool's implementation reference

---

## Core Diagnostic Skills

```yaml
- name: ad_diagnose_replication
  description: Diagnose Active Directory replication failures. Triggers on replication errors, USN rollback, lingering objects, or repadmin failures.
  source_file: 02_AD_DEEP_DIVE_GUIDES/01-Replication-Issues.md
  parameters:
    required:
      - name: error_code
        description: Specific replication error code (e.g., 8453, 8606, 8614) or "unknown"
      - name: affected_dc
        description: Hostname(s) of the failing domain controller(s)
      - name: scope
        description: Is the failure between two specific DCs, site-wide, or domain-wide?
    optional:
      - name: repadmin_output
        description: Output of repadmin /replsummary or /showrepl if already collected
  returns: Phase-by-phase diagnostic investigation with PowerShell commands and fix table

- name: ad_diagnose_kerberos
  description: Triage Kerberos authentication failures by error code. Triggers on 0x7, 0xC, 0x1F, 0x32, double-hop failures, or SPN errors.
  source_file: 13_RUNBOOKS/10-kerberos-failure-triage.md
  parameters:
    required:
      - name: error_code
        description: Kerberos error code (e.g., 0x7, 0x1F, 0x32) or Windows event ID
      - name: affected_user
        description: UPN or SamAccountName of the affected user, or "multiple users"
      - name: target_resource
        description: FQDN or name of the server/service the user is trying to reach
    optional:
      - name: auth_protocol
        description: Is it confirmed Kerberos or NTLM? Or unknown?
      - name: klist_output
        description: Output of klist from the client machine if available
  returns: Decision tree diagnosis, PowerShell investigation commands, fix table

- name: ad_diagnose_lockout
  description: Investigate account lockout source. Triggers on account locked out, repeated lockouts, or lockout storm.
  source_file: 13_RUNBOOKS/05-account-lockout-investigation.md
  parameters:
    required:
      - name: username
        description: SamAccountName of the locked-out account
      - name: domain
        description: Domain DNS name where the account lives
    optional:
      - name: frequency
        description: How often is it locking out? (every hour, every day, etc.)
      - name: recent_changes
        description: Any recent password changes, new devices, or software changes?
  returns: PDC Emulator event log analysis, source machine identification, fix matrix

- name: ad_diagnose_dns
  description: Triage DNS failures affecting AD. Triggers on DC locator failures, SRV record missing, clients can't find a DC, or replication partner resolution failures.
  source_file: 13_RUNBOOKS/09-dns-troubleshooting.md
  parameters:
    required:
      - name: symptom
        description: What is failing? (login, replication, app, all DNS?)
      - name: scope
        description: All clients? Specific subnet? Specific DC? Specific site?
      - name: dns_provider
        description: DNS platform in use (Infoblox, BlueCat, BIND, AD-integrated, etc.)
    optional:
      - name: recent_changes
        description: Recent DC changes, DHCP changes, IP changes, new DCs added?
  returns: nslookup/Resolve-DnsName test commands, SRV record validation, fix reference

- name: ad_diagnose_gpo
  description: Investigate Group Policy not applying. Triggers on GPO not applying, settings not taking effect, or gpresult showing denied.
  source_file: 13_RUNBOOKS/11-gpo-not-applying.md
  parameters:
    required:
      - name: target_type
        description: Is it a user, computer, or both that's affected?
      - name: gpo_name
        description: Name of the GPO that should be applying
      - name: target_name
        description: Username or computer name experiencing the issue
    optional:
      - name: gpresult_output
        description: Output of gpresult /R if already collected
      - name: ou_path
        description: OU path where the affected object lives
  returns: Decision tree, gpresult-first analysis, fix matrix for all denial reasons
```

---

## Operational Runbook Skills

```yaml
- name: run_krbtgt_rotation
  description: Execute KRBTGT password rotation procedure. Step-by-step with replication verification.
  source_file: 13_RUNBOOKS/04-krbtgt-rotation.md
  parameters:
    required:
      - name: domain
        description: Domain DNS name to rotate KRBTGT in
      - name: rotation_type
        description: Standard rotation or post-compromise emergency rotation?
      - name: change_window
        description: Scheduled change window start/end times
    optional:
      - name: previous_rotation_date
        description: Date of last KRBTGT rotation if known
  returns: Phase-by-phase rotation runbook with verification commands and rollback

- name: run_dc_promotion
  description: Execute Domain Controller promotion procedure.
  source_file: 13_RUNBOOKS/02-dc-promotion.md
  parameters:
    required:
      - name: new_dc_hostname
        description: Hostname of the server being promoted
      - name: domain
        description: Domain DNS name to join as a DC
      - name: site_name
        description: AD site the new DC should belong to
      - name: roles_to_hold
        description: Should this DC hold GC, DNS, RODC, or standard DC roles?
  returns: Pre-check phase, promotion commands, post-promotion verification

- name: run_fsmo_transfer
  description: Transfer FSMO roles between domain controllers.
  source_file: 13_RUNBOOKS/06-fsmo-transfer.md
  parameters:
    required:
      - name: roles_to_transfer
        description: Which FSMO roles? (PDC, RID, Infrastructure, Schema, Domain Naming — or all)
      - name: source_dc
        description: Current role holder DC hostname
      - name: target_dc
        description: Destination DC hostname
      - name: reason
        description: Planned transfer or emergency seizure?
  returns: Transfer commands with pre/post verification

- name: run_replication_recovery
  description: Recover from AD replication failures.
  source_file: 13_RUNBOOKS/07-replication-recovery.md
  parameters:
    required:
      - name: error_code
        description: Replication error code (8453, 8606, 8614, etc.) or "unknown"
      - name: affected_dcs
        description: Which DCs are failing to replicate?
      - name: scope
        description: Single link, DC-specific, site-wide, or all replication broken?
  returns: Decision tree → targeted recovery section → verification commands
```

---

## Security & Identity Skills

```yaml
- name: assess_spn_delegation
  description: Audit SPNs and Kerberos delegation configuration. Triggers on double-hop failures, SPN missing, duplicate SPNs, or KCD misconfiguration.
  source_file: 13_RUNBOOKS/14-spn-delegation-troubleshooting.md
  parameters:
    required:
      - name: service_account
        description: Service account or computer account to audit
      - name: symptom
        description: What is failing? (NTLM fallback, double-hop, SPN error, delegation denied?)
    optional:
      - name: target_resource
        description: The downstream resource the service needs to delegate to
      - name: delegation_type_needed
        description: KCD, RBKCD, Unconstrained, or Protocol Transition?
  returns: SPN audit commands, duplicate detection, delegation config verification

- name: validate_forest_trust
  description: End-to-end functional check of a forest trust. Triggers on cross-forest auth failures, trust health alerts, or post-provisioning validation.
  source_file: 13_RUNBOOKS/12-forest-trust-etfc.md
  parameters:
    required:
      - name: local_forest
        description: Local forest DNS name
      - name: remote_forest
        description: Remote/trusted forest DNS name
      - name: trust_direction
        description: BiDirectional, Inbound, or Outbound?
    optional:
      - name: selective_auth_enabled
        description: Is selective authentication enabled on this trust?
  returns: ETFC checklist, nltest/netdom commands, fix table

- name: troubleshoot_mdi_sensor
  description: Troubleshoot Microsoft Defender for Identity sensor health issues. Triggers on MDI health alert, sensor not communicating, or missing detections.
  source_file: 13_RUNBOOKS/15-mdi-sensor-health-troubleshooting.md
  parameters:
    required:
      - name: alert_name
        description: Exact MDI health alert text from security.microsoft.com
      - name: affected_sensor
        description: Hostname of the DC/server with the sensor issue
    optional:
      - name: sensor_version
        description: MDI sensor version if known
      - name: portal_screenshot
        description: Paste any additional detail from the portal alert
  returns: Per-alert diagnostic commands, root cause table, fix steps
```

---

## ITIL Change Management Skills

```yaml
- name: generate_itil_change_audit
  description: Generate a full ITIL pre-change audit including RFC, impact analysis, risk matrix, rollback plan, and CAB pack. Triggers on any request for change planning, risk assessment, CAB preparation, or "audit before change".
  source_file: 11_MASTER_AI_PROMPTS/11-itil-change-audit-prompts.md
  parameters:
    required:
      - name: change_description
        description: What is being changed? Be specific about the AD/identity component.
      - name: change_type
        description: Standard, Normal, or Emergency change?
      - name: environment
        description: Domain name, number of DCs, number of users affected
      - name: proposed_window
        description: Proposed change window date/time and duration
      - name: requestor
        description: Who is requesting the change?
    optional:
      - name: previous_incidents
        description: Any previous failures related to this type of change?
      - name: dependencies
        description: Known dependencies (apps, services, teams that must be notified)
  returns: Full ITIL CAB pack with RFC, impact analysis, risk matrix, rollback plan, comms plan, test plan

- name: generate_jira_card
  description: Generate a Jira card (incident, change request, epic, security finding, story, or task). Triggers on any request to create a ticket, card, or story.
  source_file: 11_MASTER_AI_PROMPTS/06-jira-card-generator-prompts.md
  parameters:
    required:
      - name: card_type
        description: incident / change_request / epic / security_finding / story / task
      - name: summary
        description: One-line summary of what the card is about
      - name: context
        description: Relevant technical context (what happened, what needs doing)
    optional:
      - name: priority
        description: P0/P1/P2/P3 for incidents, or High/Medium/Low for others
      - name: story_points
        description: Fibonacci estimate (1, 2, 4, 8) — if unknown, agent will suggest
  returns: Fully structured Jira card with all sections, acceptance criteria, story points
```

---

## Automation & Report Skills

```yaml
- name: generate_html_report
  description: Generate a PowerShell script that produces an HTML health dashboard. Triggers on requests for AD health reports, security posture reports, or visual dashboards.
  source_file: 14_HTML_POWERSHELL_REPORTS/
  parameters:
    required:
      - name: report_type
        description: health / security_posture / gpo / privileged_access / stale_accounts
      - name: target_domain
        description: Domain DNS name to run the report against
    optional:
      - name: output_path
        description: Where to save the HTML file (default: C:\Reports\)
      - name: include_sections
        description: Specific sections to include or exclude
  returns: Production-ready PowerShell script with colour-coded HTML output
```

---

## How to Register These as MCP Tools

```python
# Example: Auto-generate MCP tool definitions from this index
# Each entry above maps directly to an MCP tool schema

tool_schema = {
    "name": "ad_diagnose_kerberos",
    "description": "Triage Kerberos authentication failures by error code...",
    "input_schema": {
        "type": "object",
        "properties": {
            "error_code": {
                "type": "string",
                "description": "Kerberos error code (e.g., 0x7, 0x1F, 0x32) or Windows event ID"
            },
            "affected_user": {
                "type": "string",
                "description": "UPN or SamAccountName of the affected user"
            },
            "target_resource": {
                "type": "string",
                "description": "FQDN or name of the server/service the user is trying to reach"
            }
        },
        "required": ["error_code", "affected_user", "target_resource"]
    }
}
```
