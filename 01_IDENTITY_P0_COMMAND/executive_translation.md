# Executive Translation Mode

## Business Impact Communication for Identity Incidents

> **Key Principle**: Executives don't care about Kerberos. They care about: Who is blocked? What's the cost? When will it be fixed? What are you doing about it?

---

## The Executive Communication Framework

### The Four Questions Every Executive Asks

```
EXECUTIVE MENTAL MODEL:

┌─────────────────────────────────────────────────────────────────┐
│ 1. WHO IS AFFECTED?                                             │
│    • Employees? Customers? Partners? Executives themselves?     │
│    • How many? Which groups? VIPs?                             │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. WHAT CAN'T THEY DO?                                          │
│    • Specific business activities blocked                       │
│    • Revenue generation affected?                               │
│    • Customer service impacted?                                 │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. WHEN WILL IT BE FIXED?                                       │
│    • Honest estimate                                            │
│    • What are the dependencies?                                 │
│    • When is the next update?                                   │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. WHAT ARE YOU DOING?                                          │
│    • Clear action plan                                          │
│    • Who is working on it?                                      │
│    • What's the mitigation while fixing?                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Technical-to-Business Translation Dictionary

### Authentication Failures

| Technical Term | Executive Translation |
|---------------|----------------------|
| "Kerberos authentication is failing" | "Employees cannot log into their computers or access company applications" |
| "NTLM fallback is occurring" | "Login is working but is slower and less secure than normal" |
| "KDC is unavailable" | "The system that validates employee identities is offline" |
| "TGT cannot be obtained" | "Users cannot prove who they are to the system" |
| "Service ticket failure" | "Users can log in but cannot access specific applications" |

### Active Directory Issues

| Technical Term | Executive Translation |
|---------------|----------------------|
| "Domain Controller is offline" | "One of the central login servers is down; users may experience delays" |
| "All DCs in site are down" | "The [location] office cannot access any company systems" |
| "Replication failure" | "Changes made in one location aren't being shared to other locations; some users may see outdated information" |
| "FSMO role holder unavailable" | "A critical infrastructure component is offline; certain administrative tasks cannot be performed" |
| "Secure channel broken" | "A computer has lost its trusted connection to the network and cannot function normally" |

### Hybrid Identity Issues

| Technical Term | Executive Translation |
|---------------|----------------------|
| "Azure AD Connect sync failure" | "New employees cannot access cloud applications like Microsoft 365; existing users are unaffected" |
| "Password hash sync delayed" | "Recent password changes aren't working for cloud applications yet" |
| "PTA agent failure" | "Cloud application logins are failing because they can't verify passwords against our systems" |
| "Federation service down" | "Single sign-on to cloud applications is not working; users need to log in manually" |

### Security Incidents

| Technical Term | Executive Translation |
|---------------|----------------------|
| "Credential compromise suspected" | "An attacker may have obtained employee login credentials; we're taking protective action" |
| "DCSync attack detected" | "An attacker may be attempting to copy our entire user database; immediate action required" |
| "Golden Ticket detected" | "An attacker has potentially gained permanent, undetectable access; full security reset may be required" |
| "Krbtgt reset required" | "We need to invalidate all login sessions to ensure security; users will need to log in again" |

---

## Executive Update Templates

### Template 1: Initial Notification (First 5 Minutes)

```
SUBJECT: [P1/P2] Identity Issue - [Location/Scope] - [Time]

WHAT'S HAPPENING:
[One sentence in plain English]
Example: "Employees at our Chicago office cannot log into their computers."

WHO IS AFFECTED:
• Approximately [X] employees
• [Location(s) or department(s)]
• [Customer impact: Yes/No]

CURRENT IMPACT:
• [What specific work is blocked]
• [Revenue systems affected: Yes/No]

WHAT WE'RE DOING:
• Team is actively investigating
• Initial focus: [One sentence]

NEXT UPDATE: [Time, typically 30 minutes]

---
Incident Commander: [Name]
Incident #: [Number]
```

### Template 2: Progress Update (Every 30-60 Minutes)

```
SUBJECT: UPDATE - [Incident Title] - [Status: Investigating/Mitigating/Resolving]

STATUS: [One word: RED/YELLOW/GREEN]

SINCE LAST UPDATE:
• [What we learned]
• [What we did]
• [Current state]

CURRENT IMPACT:
• Users affected: [Number] (↑/↓/→ from last update)
• Duration so far: [X hours]
• Customer impact: [Status]

ROOT CAUSE:
• [Confirmed/Suspected/Under Investigation]
• [One sentence explanation if known]

PATH TO RESOLUTION:
• Current step: [What we're doing now]
• Next step: [What comes after]
• Estimated resolution: [Time if known, or "investigating"]

NEXT UPDATE: [Time]

---
Incident Commander: [Name]
```

### Template 3: Mitigation/Resolution Notification

```
SUBJECT: [MITIGATED/RESOLVED] - [Incident Title]

STATUS: [MITIGATED - Impact reduced / RESOLVED - Fully fixed]

SUMMARY:
• Issue began: [Time]
• Issue mitigated/resolved: [Time]
• Total duration: [X hours/minutes]
• Users affected: [Number]

WHAT HAPPENED:
[2-3 sentences in plain English explaining what went wrong]

WHAT WE DID:
[2-3 sentences explaining the fix]

CURRENT STATE:
• [Full service restored / Partial service / Monitoring]
• [Any ongoing work]

PREVENTION:
• [What will prevent this from happening again]
• [When preventive measures will be implemented]

POST-INCIDENT REVIEW: [Scheduled for DATE/TIME]

---
Incident Commander: [Name]
```

---

## Language Patterns for Executives

### DO Use:

```
GOOD EXECUTIVE LANGUAGE:

✓ "Employees cannot access [specific thing]"
✓ "This affects approximately [X] people"
✓ "We expect to resolve this by [time]"
✓ "The team is [specific action]"
✓ "This does/does not affect customers"
✓ "This does/does not affect revenue systems"
✓ "We have a workaround: [describe]"
✓ "Root cause is [simple explanation]"
✓ "Next update at [specific time]"
```

### DON'T Use:

```
BAD EXECUTIVE LANGUAGE:

✗ Jargon: "KDC", "TGT", "NTDS", "Kerberos", "LDAP" without explanation
✗ Vague scope: "Some users" (How many?)
✗ Vague timeline: "Soon", "ASAP", "Working on it"
✗ Blame: "The network team caused..." (Irrelevant during incident)
✗ Uncertainty as status: "We're not sure what's happening"
✗ Technical details: "The USN rollback caused..." (Too much detail)
✗ Acronym soup: "The PTA to AAD is failing due to ADFS STS issues"
```

---

## Scenario-Based Executive Messaging

### Scenario: Authentication Outage (Widespread)

```
FOR EXECUTIVES:

What's Happening:
"Employees company-wide cannot log into their computers or access
internal applications. This began at [time]."

Business Impact:
"Approximately [X] employees are unable to work. This includes
[customer service/sales/critical function]. We estimate this is
costing approximately $[X] per hour in lost productivity."

What We're Doing:
"Our identity team is actively working on the issue. We've
identified [the likely cause] and are [specific action]. We have
engaged [vendor if applicable]."

Timeline:
"Based on current information, we expect to restore service by
[time]. We will provide updates every [30 minutes]."
```

### Scenario: Security Incident (Credential Compromise)

```
FOR EXECUTIVES:

What's Happening:
"We detected suspicious activity that suggests an unauthorized
party may have obtained employee credentials. We are taking
immediate protective action."

Business Impact:
"As a precaution, some employees may experience login interruptions
while we secure the environment. This is intentional and necessary."

What We're Doing:
"We are working with our security team to contain the incident,
identify affected accounts, and reset credentials as needed.
We have engaged [forensics/legal/law enforcement as applicable]."

What You Need to Know:
"[If required] You will receive separate communication about any
potential data exposure. At this time, [we have/have not] found
evidence of data access."

Communication:
"[Employee/customer communication has been/will be sent at TIME]"
```

### Scenario: Partial Degradation (Some Impact)

```
FOR EXECUTIVES:

What's Happening:
"A portion of our login infrastructure is experiencing issues.
Most employees are unaffected, but employees in [location/group]
are experiencing login delays or failures."

Business Impact:
"Approximately [X] employees ([Y]% of workforce) may experience
difficulties. [Critical systems/customer systems] are operating
normally."

What We're Doing:
"We're routing affected users to backup systems while we repair
the issue. Most users should not notice any disruption."

Timeline:
"We expect full restoration within [time]. Affected users should
try logging in again in [X minutes]."
```

---

## Stakeholder Notification Matrix

### Who to Notify Based on Impact

| Impact Level | Notify | Timing | Method |
|--------------|--------|--------|--------|
| 1-10 users | Help Desk Manager | Within 1 hour | Teams/Email |
| 11-100 users | IT Director | Within 30 min | Phone/Teams |
| 100-1000 users | CIO/VP | Within 15 min | Phone |
| 1000+ users | C-Suite, Comms | Immediately | Phone + Exec Bridge |
| Customer impact | CCO, Legal | Immediately | Phone |
| Security incident | CISO, Legal | Immediately | Phone + Secure Channel |

### Communication Frequency

| Incident Severity | Update Frequency |
|-------------------|-----------------|
| P0 (Critical) | Every 30 minutes during active incident |
| P1 (High) | Every 60 minutes |
| P2 (Medium) | Every 2 hours |
| Ongoing (multi-day) | 2x daily (AM and PM) |

---

## Answering Tough Executive Questions

### "When will this be fixed?"

```
IF YOU KNOW:
"Based on our current diagnosis, we expect to restore service by
[TIME]. I'll update you if that changes."

IF YOU DON'T KNOW:
"We're still determining the root cause. I'll have a better
estimate within [30 minutes/1 hour]. In the meantime, we're
[specific mitigation action]."

NEVER SAY:
"I don't know" (without a follow-up)
"Soon" (too vague)
"It depends" (sounds like an excuse)
```

### "How did this happen?"

```
IF YOU KNOW:
"[Brief, non-blaming explanation]. We'll have a full analysis
after we resolve the immediate issue."

IF YOU DON'T KNOW:
"We're still investigating the root cause. Our priority right now
is restoring service. We'll have a complete analysis in our
post-incident review."

NEVER SAY:
"[Person/Team] made a mistake" (blame)
"This shouldn't have happened" (doesn't help)
"We don't know" (without commitment to find out)
```

### "Why wasn't this prevented?"

```
GOOD RESPONSE:
"That's an important question. Once we resolve this incident,
we'll conduct a thorough review to understand what we can do
differently. I'll share those findings with you."

NEVER SAY:
"It wasn't my team's fault"
"We don't have the budget for better systems"
"This was unforeseeable" (usually not true)
```

---

## Related Documents

- [Blast Radius Analysis](blast_radius_analysis.md) - Calculating impact
- [P0 Incident Commander](p0_incident_commander_prompt.md) - Overall incident management
- [Timeline Reconstruction](timeline_reconstruction.md) - Understanding what happened
