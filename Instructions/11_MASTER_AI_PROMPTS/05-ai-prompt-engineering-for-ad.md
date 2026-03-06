# 05 — AI Prompt Engineering Mastery for Active Directory

> **What this is**: The meta-guide. How to get 10x better results from AI assistants when working on AD problems. Written for AD engineers who want to use AI as a true force multiplier — not just a search engine.

---

## The Gap Between Average and Elite AI Use

**Average AD engineer + AI**: "Why can't users log in?" → Gets generic troubleshooting steps.

**Elite AD engineer + AI**: Provides complete context, activates expert persona, requests structured diagnostic output, chains follow-up prompts based on findings → Gets expert-calibrated, actionable, environment-specific guidance.

The prompts are the difference.

---

## Principle 1: Context Is Everything

AI models have no knowledge of your environment. The more context you provide, the better the output.

### Minimal Context (Bad)
```
"Users can't log in. What's wrong?"
```
Result: Generic steps you already know.

### Rich Context (Good)
```
Domain: corp.contoso.com, Windows Server 2022 DFL
DCs: 8 DCs across 4 sites (US-East, US-West, EMEA, APAC)
Issue: Authentication failures for ~400 users in APAC site only
Started: ~45 minutes ago
No recent changes (scheduled maintenance window was last Thursday)
Error: "The trust relationship between this workstation and the primary domain failed" on Windows 11 clients
Not affected: Server 2019 machines in same site; all other sites working
Recent: Network maintenance on APAC router 2 hours ago (said to be "transparent")
Tools available: PowerShell, AD module, no Sentinel/MDI, Splunk available
```
Result: Targeted, site-specific, protocol-aware guidance.

### Context Template
```
Copy and fill this before every AD troubleshooting session:

ENVIRONMENT:
- Domain/Forest: [domain name, functional levels]
- DC Count & Sites: [N DCs across N sites]
- Hybrid: [Yes/No — if yes: AAD Connect v?, PHS/PTA/ADFS?]
- Tools Available: [PowerShell, LDP, ADSIEdit, Splunk, Sentinel, MDI, MDE]
- Constraints: [Change freeze / regulated environment / limited access]

ISSUE:
- What users/systems are affected: [count, description]
- What they're experiencing: [exact error messages]
- When it started: [exact time]
- What changed recently: [changes in last 24-48h]
- What you've already tried: [steps taken]
- What you've ruled out: [eliminated hypotheses]

DATA COLLECTED:
[Paste any command output here]
```

---

## Principle 2: Persona Activation

Different tasks need different expert mindsets. Explicitly activating a persona produces dramatically better outputs.

### Available Personas

| Persona | When to Use | Activation Phrase |
|---------|-------------|------------------|
| AD Diagnostician | Troubleshooting any AD issue | "You are a Microsoft CSS Principal for AD" |
| Incident Commander | P0/P1 incidents | "You are an Incident Commander running a war room" |
| Security Reviewer | Security assessments | "You are a red teamer reviewing AD for attack paths" |
| AD Architect | Design/architecture | "You are a Gartner-recognized AD Architect" |
| Change Advisor | Pre-change review | "You are a cautious CAB advisor reviewing a risky change" |
| Executive Translator | Stakeholder comms | "You are a CTO explaining a technical incident to the board" |
| Training Coach | Learning | "You are a patient AD instructor teaching me from scratch" |

### Persona Activation Examples

```
# For incidents:
"You are a Microsoft CSS Principal Support Engineer specializing in AD/Kerberos, currently running a P0 war room. Be decisive, terse, and safety-obsessed. Never recommend changes without confirming a change window. Format all output for rapid war room consumption."

# For architecture:
"You are a Principal AD Architect with 20 years experience designing multi-forest enterprise environments for Fortune 100 companies. I need architectural guidance, not troubleshooting. Think in terms of long-term maintainability, security, and operational excellence."

# For security:
"You are a red team operator specializing in Active Directory attacks. I am a defender and I want you to review our AD configuration and tell me exactly how you would exploit it, then help me close those paths."
```

---

## Principle 3: Chain-of-Thought Forcing

AI will shortcut to answers. Force it to reason step-by-step for complex AD problems.

### Forcing Phrases

```
# Force layer-by-layer analysis:
"Before answering, work through the AD networking stack from the bottom up: Network → DNS → DC Health → Authentication Protocol → Application."

# Force hypothesis ranking:
"List all possible causes ranked by likelihood with confidence percentages. Do not skip uncommon causes."

# Force evidence requirements:
"For each hypothesis, tell me exactly what evidence would confirm or rule it out. Be specific about event IDs, command outputs, and registry keys."

# Force safety checks:
"Before recommending any action, explicitly state its risk level (read-only/low/medium/high) and what could go wrong."

# Force completeness:
"Do not compress or skip steps. I'm running this during an incident and I need every step explicitly listed."
```

---

## Principle 4: Structured Output Requests

Get machine-parseable or human-scannable output instead of prose.

### Output Format Requests

```
# For diagnostic steps:
"Format as a numbered checklist. Each item: [Risk Level] Description | Command: `exact command` | Expected Output: what healthy looks like"

# For comparison:
"Format as a comparison table with columns: Approach | Pros | Cons | When to Use | Risk Level"

# For tickets:
"Format as a Jira card with these sections: Summary, Business Impact, Root Cause, Steps to Reproduce, Resolution, Prevention"

# For executive comms:
"Format as a 3-paragraph executive summary: What happened, Business impact, What we're doing. No technical jargon."

# For runbooks:
"Format as a numbered runbook with: Prerequisites, Steps (each with: Action, Command, Expected Result, Rollback), Verification, and Post-steps."
```

---

## Principle 5: The Refinement Loop

One prompt is rarely enough. Use follow-ups strategically.

### Effective Follow-Up Patterns

```
# Drill into a hypothesis:
"You ranked [Hypothesis X] as most likely. Assume it IS the cause. Give me the exact remediation steps."

# Challenge the answer:
"Play devil's advocate. What are the reasons [your recommendation] might be wrong or make things worse?"

# Get more detail:
"Step 3 in your remediation mentions [X]. Elaborate — what exactly does that command do, what could go wrong, and what's the rollback?"

# Get the alternative path:
"Your primary recommendation requires a change window. What can we do RIGHT NOW without any changes to reduce impact while we wait?"

# Validate understanding:
"I'm going to summarize what I think you said. Tell me if I'm wrong: [your summary]"

# Escalate complexity:
"Assume that approach didn't work. We ran [command] and got [output]. What's the next hypothesis?"
```

---

## Principle 6: Safety-First Prompting

Always encode safety into your prompts for AD work. AD is production-critical.

### Safety Encoding Patterns

```
# Always add to any troubleshooting prompt:
"Clearly mark every recommended command as either READ-ONLY (safe anytime) or WRITE (requires change window). Never mix them in the same step."

# For change guidance:
"I am in production with no change window. Only recommend read-only diagnostic steps. Save all write operations for a separate 'When I have a change window' section."

# For risky operations:
"Before recommending anything that touches FSMO, replication topology, schema, or trusts, state the blast radius if it goes wrong and require me to explicitly confirm before proceeding."

# Build in rollback by default:
"Every remediation step must include a rollback step. Format as: Do: [action] | Rollback: [how to undo]"
```

---

## Principle 7: Multi-Step Problem Decomposition

Complex AD problems often have multiple components. Break them apart.

### Decomposition Prompt
```
"This problem has multiple potential components. Before diving into solutions, break this problem into its independent sub-problems. For each sub-problem:
1. State what it is
2. State whether it's a root cause or a symptom
3. State whether it can be diagnosed independently
4. State the order in which sub-problems should be addressed

Then work through each sub-problem separately."
```

### Sequencing Prompt
```
"I need to fix [problem] but I must maintain service availability. Design a safe remediation sequence that:
1. Addresses the most impactful issue first
2. Verifies each step before proceeding
3. Has clear go/no-go criteria at each checkpoint
4. Can be paused and resumed if needed
5. Has a clear rollback point at each step"
```

---

## Principle 8: Knowledge Calibration

Make the AI calibrate what it knows vs. doesn't know.

### Calibration Prompt
```
"Before answering, rate your confidence on each of the following topics as it relates to my question (1-10):
- Your knowledge of the specific technology/version involved
- Whether your training data likely covers this specific error
- Whether there are known caveats, bugs, or KB articles I should check
- Whether the answer might have changed since your knowledge cutoff

Then answer with those calibrations in mind."
```

### Gap-Filling Prompt
```
"After your initial analysis, tell me:
1. What information would change your diagnosis if I provided it?
2. What Microsoft KB articles or documentation should I check?
3. What questions should I be asking that I'm not asking?
4. What are the most common mistakes engineers make when dealing with this type of issue?"
```

---

## Quick Prompt Formulas

### Formula 1: The Rapid Triage Prompt
```
[Persona] + [Rich Context] + [Specific Question] + [Output Format]
```

### Formula 2: The Deep Dive Prompt
```
[Persona] + [Rich Context] + "Use chain-of-thought to analyze [specific component]" + [Structured Output Request]
```

### Formula 3: The Safe Change Prompt
```
[Change Advisor Persona] + [Change Description] + "Identify all risks, required pre-checks, exact steps, rollback triggers, and rollback steps. Mark every command READ-ONLY or WRITE."
```

### Formula 4: The Escalation Prompt
```
"Previous troubleshooting summary: [what was tried]. Results: [what was found]. Current state: [where we are]. Next hypothesis to investigate: [what AI suggested]. Data collected: [command output]. What does this tell us and what's next?"
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| "Why can't users log in?" | No context, gets generic answer | Use the Context Template |
| "Fix our replication" | No data, AI guesses | Paste repadmin output first |
| Accepting first answer | AI may shortcut | Use follow-up refinement |
| Ignoring uncertainty | AI sounds confident even when wrong | Use calibration prompt |
| One big prompt | Complex problems need decomposition | Break into sub-prompts |
| No safety constraints | AI may suggest risky steps | Always encode safety |
| Copying commands without understanding | Dangerous in production | Ask "explain this command" |
