# GPO Builder

**Use Case:** Design, document, and troubleshoot Group Policy Objects with expert guidance.
**Techniques:** GPO design principles, precedence analysis, security filtering, WMI filters

---

## GPO Design Prompt

```
You are a Group Policy expert with deep knowledge of Windows GPO design, security hardening baselines (CIS, DISA STIG, Microsoft Security Baselines), and enterprise deployment patterns.

I need to create a GPO to accomplish: [WHAT YOU WANT TO CONFIGURE]

Target: [Users / Computers / Both]
Target OU scope: [which OUs should this apply to?]
Environment: [Domain functional level, Windows versions of targets]
Existing GPO structure: [Brief description of current GPO hierarchy if relevant]

---

Design the GPO:

## 1. Recommended Approach
Should this be a User policy, Computer policy, or both? Single GPO or multiple? Explain the rationale.

## 2. GPO Name Convention
Suggest a name following best practices (e.g., [Scope]-[Category]-[Description]-[v1])

## 3. Settings to Configure
For each setting I need:
- Policy path (exact location in GPMC)
- Setting name
- Recommended value
- Why this value (not just "enable it")
- Any dependencies or prerequisites

## 4. Security Filtering
Who should this GPO apply to?
- Default: Authenticated Users (all computers/users in the OU)
- Restricted: specific security group (recommended for targeted deployment)
Recommended security group setup for this GPO.

## 5. WMI Filter (if needed)
If this should only apply to specific OS versions or hardware:
```
SELECT * FROM Win32_OperatingSystem WHERE Version LIKE "10.%" AND ProductType = "1"
```
Provide the exact WMI query for my use case.

## 6. Precedence Considerations
Where should this GPO be linked and at what precedence? Will it conflict with any common existing GPOs?

## 7. Testing Plan
How to safely test this GPO before broad deployment:
- Test OU approach
- Pilot group approach
- Verification commands

## 8. Documentation Block
Generate documentation for this GPO:
```
GPO Name:
Purpose:
Created: [DATE]
Owner:
Linked to:
Security Filter:
WMI Filter:
Key Settings:
  -
  -
Last Reviewed:
Change History:
  - [DATE]: Created
```
```

---

## Common GPO Recipes

### Password Policy (Fine-Grained)

```
Help me configure a Fine-Grained Password Policy (PSO) for:
Target group: [e.g., service accounts, admin accounts]
Requirements: [e.g., 24-char min, complexity, no expiry OR 90-day expiry]

Provide:
1. PowerShell to create the PSO
2. PowerShell to apply it to the target group
3. PowerShell to verify it's applied correctly
4. How to check effective policy for a specific account
```

```powershell
# Create PSO example
New-ADFineGrainedPasswordPolicy -Name "ServiceAccounts-PSO" `
  -Precedence 10 `
  -MinPasswordLength 24 `
  -ComplexityEnabled $true `
  -ReversibleEncryptionEnabled $false `
  -PasswordHistoryCount 24 `
  -MaxPasswordAge ([TimeSpan]::Zero) `  # No expiry
  -MinPasswordAge (New-TimeSpan -Days 1) `
  -LockoutThreshold 5 `
  -LockoutDuration (New-TimeSpan -Minutes 30) `
  -LockoutObservationWindow (New-TimeSpan -Minutes 30)

# Apply to group
Add-ADFineGrainedPasswordPolicySubject -Identity "ServiceAccounts-PSO" -Subjects "Service_Accounts_Group"

# Verify
Get-ADUserResultantPasswordPolicy -Identity <username>
```

---

### Security Baseline GPO

```
I want to apply a security baseline to [Workstations / Servers / DCs].

Generate GPO settings for the Microsoft Security Baseline / CIS Benchmark Level [1/2] for [Windows 10/11 / Server 2019 / Server 2022].

Focus on these categories:
[ ] Account policies
[ ] Audit policies (Advanced Audit Policy Configuration)
[ ] Windows Firewall
[ ] Windows Defender settings
[ ] Remote Desktop settings
[ ] User Rights Assignment
[ ] Security Options

For each setting: policy path, recommended value, and the security reason behind it.
```

---

### Audit Policy GPO

```
Design an Advanced Audit Policy Configuration GPO to capture:
- All logon/logoff events (success and failure)
- Account management changes
- Privilege use by admin accounts
- Object access on sensitive shares/files
- GPO changes
- AD object changes

Provide:
1. The exact audit subcategory settings (Advanced Audit Policy, not legacy)
2. Recommended event log sizes
3. The Splunk/SIEM queries to use these events effectively
4. Any performance considerations

Format as a table: Subcategory | Success | Failure | Notes
```

---

## GPO Troubleshooting — RSOP Analysis

```
My GPO is not applying correctly. Here is my gpresult output:

[PASTE GPRESULT /R OR HTML CONTENT]

Tell me:
1. Which GPOs are applied and in what order?
2. Which GPOs are being filtered out and why?
3. Are there any error events?
4. What is the winning GPO for [specific setting]?
5. What should I check next?
```

---

**Tips:**
- Never link GPOs to the domain root if you can avoid it — link to specific OUs
- Test GPOs on a single computer in a test OU first, always
- Use "Starter GPOs" as templates for common baselines
- Block Inheritance + Enforced = Enforced always wins (except local policy)
- WMI filters: test the query in WMI Explorer before deploying
- Security filtering: remove Authenticated Users, add your target group — reduces unnecessary processing
