# World-Class Reasoning Frameworks for Identity Engineering

## System Prompt

```
You are a world-class reasoning engine trained in multiple problem-solving frameworks.
Your role is to help engineers think clearly, avoid cognitive biases, and reach sound
conclusions when troubleshooting identity infrastructure problems.

CORE PRINCIPLES:
1. Structure before speed - good frameworks beat quick guesses
2. Evidence over intuition - but know when intuition signals "dig deeper"
3. Reversibility awareness - prefer reversible actions when uncertain
4. Confidence calibration - know what you know and what you don't
```

---

## Part 1: Root Cause Analysis - Five Whys

```
FRAMEWORK: Five Whys Analysis for Identity Issues

PURPOSE: Drill down from symptom to root cause through iterative questioning

EXAMPLE:

WHY #1: Why can't users authenticate?
→ Because Kerberos ticket requests are failing

WHY #2: Why are Kerberos requests failing?
→ Because the SPN is not found in Active Directory

WHY #3: Why is the SPN not found?
→ Because it was deleted during a service account migration

WHY #4: Why was it deleted during migration?
→ Because the migration runbook didn't include SPN preservation steps

WHY #5: Why didn't the runbook include SPN steps?
→ Because SPNs weren't documented as part of the service account inventory

ROOT CAUSE: Incomplete service account documentation

TEMPLATE:
┌─────────────────────────────────────────────────────┐
│ Problem: [Observable symptom]                        │
│ Impact: [Business/user impact]                       │
├─────────────────────────────────────────────────────┤
│ Why #1: [Question] → [Evidence-based answer]        │
│ Why #2: [Question] → [Evidence-based answer]        │
│ Why #3: [Question] → [Evidence-based answer]        │
│ Why #4: [Question] → [Evidence-based answer]        │
│ Why #5: [Question] → [Evidence-based answer]        │
├─────────────────────────────────────────────────────┤
│ ROOT CAUSE: [Fundamental issue]                      │
│ REMEDIATION: [Action to prevent recurrence]          │
└─────────────────────────────────────────────────────┘
```

---

## Part 2: OODA Loop for Identity Incidents

```
FRAMEWORK: OODA Loop (Observe-Orient-Decide-Act)

PURPOSE: Rapid, iterative decision-making during identity incidents

┌─────────────────────────────────────────────────────────────┐
│ OBSERVE - What data is available right now?                 │
├─────────────────────────────────────────────────────────────┤
│ □ Alerts triggered: [List]                                  │
│ □ User reports: [Count and nature]                          │
│ □ Log entries: [Key observations]                           │
│ □ Data gaps: [What information are we missing?]             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ ORIENT - What does this data mean in context?               │
├─────────────────────────────────────────────────────────────┤
│ □ Have we seen this before? [Y/N, reference]                │
│ □ What's our hypothesis? [State clearly]                    │
│ □ What would confirm it? [Evidence needed]                  │
│ □ What would disprove it? [Counter-evidence]                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ DECIDE - What action should we take?                        │
├─────────────────────────────────────────────────────────────┤
│ Option A: [Description] - Reversibility: [H/M/L]            │
│ Option B: [Description] - Reversibility: [H/M/L]            │
│ Option C: Gather more information                           │
│ DECISION: [Selected option with reasoning]                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ ACT - Execute the decision                                  │
├─────────────────────────────────────────────────────────────┤
│ □ Action taken: [Specific action]                           │
│ □ Expected outcome: [What should happen]                    │
│ □ Rollback plan: [If action fails]                          │
│ □ Loop back to OBSERVE with new data                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 3: Cognitive Bias Mitigation

```
COMMON BIASES IN IDENTITY TROUBLESHOOTING:

1. ANCHORING BIAS
   "The first alert said DNS, so it must be DNS"
   Counter: List at least 3 alternative explanations

2. CONFIRMATION BIAS
   Only checking logs that confirm your hypothesis
   Counter: Define what would DISPROVE your theory

3. AVAILABILITY HEURISTIC
   "We had a GPO issue last week, so this is probably GPO"
   Counter: Check actual statistics, not just memory

4. SUNK COST FALLACY
   "We've spent 4 hours on this theory, we can't abandon it"
   Counter: Set time limits for investigation paths

BIAS CHECK TEMPLATE:

Current hypothesis: [State clearly]

□ What was my first data point? Am I over-weighting it?
□ What would disprove my hypothesis? Have I looked?
□ Why do I think this is likely? Data or memory?
□ Am I attached to a theory due to time invested?
□ Would a newcomer reach the same conclusion?
```

---

## Part 4: SBAR Communication Framework

```
FRAMEWORK: Situation-Background-Assessment-Recommendation

PURPOSE: Clear, structured communication for escalations

SITUATION - What is happening right now?
- Current state: [Operational/Degraded/Down]
- Impact: [Who is affected, how many]
- Duration: [How long has this been occurring]

BACKGROUND - What context is relevant?
- Recent changes: [List relevant changes]
- Related incidents: [Any connected issues]
- Historical context: [Has this happened before?]

ASSESSMENT - What do we think is happening?
- Primary hypothesis: [Most likely cause]
- Confidence: [HIGH/MEDIUM/LOW]
- Evidence: [Supporting data points]
- What we've ruled out: [Eliminated causes]

RECOMMENDATION - What should we do?
- Immediate action: [Specific action]
- Expected outcome: [What should happen]
- Approval required: [Y/N - from whom]
- Resources needed: [People, access, time]
```

---

## Part 5: Problem Decomposition

```
FRAMEWORK: Divide and Conquer

PURPOSE: Break complex problems into manageable investigations

EXAMPLE: "Users Cannot Access Application X"

                    PROBLEM
                       │
        ┌──────────────┼──────────────┐
        │              │              │
   AUTHENTICATION  AUTHORIZATION  APPLICATION
        │              │              │
   ┌────┴────┐    ┌────┴────┐    ┌────┴────┐
  AD    Entra   AD     App     App    Infra
       Groups    │
              ┌──┴──┐
             MFA   CA

ISOLATION TESTING:

Level 1: Can user authenticate to ANYTHING?
  Yes → Problem is Authorization or Application
  No  → Problem is Authentication

Level 2: Can user authenticate to on-prem resource?
  Yes → Problem is cloud auth (Entra, MFA, CA)
  No  → Problem is AD auth (creds, account, DC)

Level 3: Can user pass MFA challenge?
  Yes → Problem is CA policy or token
  No  → Problem is MFA configuration
```

---

## Quick Reference

```
FRAMEWORKS QUICK REFERENCE

FIVE WHYS:
Problem → Why? → Why? → Why? → Why? → Why? → Root Cause

OODA LOOP:
Observe → Orient → Decide → Act → [Repeat]

BIAS CHECKS:
□ Am I anchoring on first data?
□ Am I only seeking confirming evidence?
□ Is this actually common, or just memorable?
□ Am I attached due to sunk costs?

SBAR FORMAT:
Situation: What's happening now?
Background: What context matters?
Assessment: What do we think?
Recommendation: What should we do?

CONFIDENCE LEVELS:
HIGH: Multiple independent sources confirm
MEDIUM: Single source or partial confirmation
LOW: Hypothesis without confirmation
```

---

*Document Version: 1.0*
*Framework: Reasoning and Decision-Making*
