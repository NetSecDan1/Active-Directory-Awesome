# 10 — Learning Acceleration Prompts for Active Directory Mastery

> **What this is**: AI prompts that turn any AI into a world-class AD instructor. Learn Kerberos in an afternoon. Understand replication in depth in a morning. Prepare for MS-102/AZ-800 in weeks, not months.

---

## PROMPT 1: Adaptive AD Learning Plan

```
You are an expert Active Directory instructor with 20+ years of experience. Create a personalized learning plan for me.

MY CURRENT LEVEL:
[Describe honestly: how long in IT, what AD tasks you do today, what confuses you, what you want to be able to do]

MY GOALS:
[e.g., "Pass AZ-800 exam", "Be the AD expert on my team", "Handle P0 incidents without help", "Design multi-forest architectures"]

MY CONSTRAINTS:
[e.g., "2 hours/day", "No lab environment", "Need to apply this at work immediately"]

CREATE:
1. Skill Gap Assessment — What I need to learn vs what I likely already know
2. Prioritized Learning Order — What to learn first (highest leverage skills)
3. Weekly Study Plan (4 weeks) — Specific topics per day
4. Hands-On Lab Exercises — What to practice in a safe environment
5. AI Practice Sessions — How to use AI to accelerate learning
6. Knowledge Check Questions — How to test myself
7. Milestone Assessments — How I'll know I've mastered each area

FORMAT: Structured week-by-week plan with daily topics and specific learning activities.
```

---

## PROMPT 2: Deep Concept Explainer — Kerberos

```
Explain Kerberos authentication in Active Directory to me. Use the following teaching approach:

LEVEL: [Beginner / Intermediate / Advanced]

TEACHING METHOD:
1. Start with a real-world analogy that makes the concept click
2. Then describe the actual technical flow with named parties (Client, KDC, Service)
3. Show the actual packets/messages with what's in each one
4. Explain what goes wrong and why (the top 5 Kerberos errors and their causes)
5. Connect to security: what do attackers exploit and how?
6. Give me 5 "Kerberos expert" things I should be able to do after learning this
7. End with 10 quiz questions to test my understanding

THEN: Ask me questions to check my understanding and correct any misconceptions.
```

---

## PROMPT 3: Deep Concept Explainer — AD Replication

```
Teach me Active Directory replication from fundamentals to expert level.

LEARNING PROGRESSION:

LEVEL 1 — WHY (Conceptual Foundation)
- Why does AD need replication?
- What exactly IS replicated? (Objects? Attributes? Everything?)
- What does "multi-master" mean and why is it powerful and dangerous?

LEVEL 2 — WHAT (The Data Model)
- What is the replication unit? (Attribute-level, not object-level — explain why this matters)
- What is a USN (Update Sequence Number) and how does it work?
- What is a high-watermark vector? An up-to-dateness vector?
- What is the difference between originating write and replicated write?

LEVEL 3 — HOW (The Mechanism)
- Walk me through a single attribute change propagating from DC1 → DC2 → DC3
- How does KCC (Knowledge Consistency Checker) build the topology?
- What is an ISTG and why does it matter?
- What is the difference between intra-site and inter-site replication?

LEVEL 4 — WHEN IT BREAKS (Failure Modes)
- USN Rollback — what causes it, why is it catastrophic, how to detect
- Lingering Objects — what they are, why they exist, how to clean up
- Replication error codes and their real meanings (1722, 8453, 8524, 8606, -2146893022)

LEVEL 5 — EXPERT SKILLS
- How to trace a specific change through replication using repadmin
- How to determine replication lag for a site
- How to identify which DC is authoritative for a change
- How to safely clean up a failed replication relationship

After each level, quiz me with 3 questions before moving to the next level.
```

---

## PROMPT 4: Scenario-Based Learning

```
Teach me Active Directory by walking me through realistic scenarios. After each scenario, explain the concepts demonstrated.

LEARNING FORMAT:
1. Present a realistic scenario (incident, design challenge, or operational task)
2. Let me attempt a response
3. Evaluate my response
4. Fill in what I missed with expert-level insight
5. Explain the underlying concepts
6. Give a harder version of the same scenario

SCENARIO SET — AUTHENTICATION FAILURES:

Scenario 1 (Easy):
"A single user calls the helpdesk: 'I can't log in to my workstation.' No other users are affected. What's your step-by-step troubleshooting process?"
[Wait for my response, then continue]

Scenario 2 (Medium):
"50 users in the Chicago office all lost access at 2 PM today. Remote users and other offices are fine. No recent AD changes. What could cause this and how do you investigate?"
[Wait for my response]

Scenario 3 (Hard):
"Kerberos is failing for all users authenticating to a specific application server. NTLM still works. The same users can Kerberos to other services. The error in event logs is KRB_AP_ERR_MODIFIED."
[Wait for my response]

Scenario 4 (Expert):
"A Microsoft Teams app suddenly can't authenticate to an internal web service. The service uses Windows Auth, the service account has a registered SPN, and it worked fine yesterday. The only change: the service account's password was reset yesterday afternoon."
[Wait for my response]

After all 4 scenarios: "What is the common thread connecting all these failures? What principle would make all of these problems easier to diagnose?"
```

---

## PROMPT 5: Interview Prep — AD Expert Level

```
Prepare me for an AD/Identity engineering interview at the Senior or Principal level. Ask me questions as if you're the interviewer. After each answer:
1. Rate my answer (Excellent / Good / Needs Work / Missing Key Points)
2. Tell me what a perfect answer includes
3. Add real-world context from production environments
4. Ask a follow-up to test deeper understanding

INTERVIEW TRACK: [Choose: Troubleshooting / Architecture / Security / Hybrid Identity / All]
LEVEL: [L4 Senior / L5 Principal / L6 Distinguished]
COMPANY TYPE: [Enterprise / Cloud-first startup / MSFT/Big Tech]

START with 3 warm-up questions, then 5 core technical questions, then 2 scenario questions, then 2 "deep dive on your answer" follow-ups.

Begin when ready.
```

---

## PROMPT 6: Concept Comparison — Make Me Choose

```
I want to understand tradeoffs in Active Directory design. For each comparison, explain:
1. What each option actually is (not just the name)
2. When you'd choose option A
3. When you'd choose option B
4. What the decision criteria are
5. What the common mistakes are when choosing

COMPARE THESE:
1. Password Hash Sync (PHS) vs Pass-Through Authentication (PTA) vs ADFS
2. Single domain vs multi-domain forest
3. Constrained Kerberos delegation vs Resource-Based Constrained Delegation (RBCD)
4. Fine-Grained Password Policy (PSO) vs Default Domain Password Policy
5. RODC vs Writable DC for branch offices
6. Azure Virtual DC vs physical DC for cloud workloads
7. Forest trust vs domain shortcut trust
8. FRS vs DFSR for SYSVOL (and why this matters in 2024)

After your explanations, ask me which I'd choose in 3 specific scenarios to test my understanding.
```

---

## PROMPT 7: The Socratic Method — AD Edition

```
Teach me [TOPIC] using the Socratic method. Do NOT give me information directly. Instead:
1. Ask me what I already know or think I know
2. Ask probing questions that reveal gaps
3. When I'm wrong, ask a question that makes me see why I'm wrong
4. When I'm right, ask a deeper question
5. Guide me to discover the answer rather than telling me

Do this until I can explain [TOPIC] accurately and completely in my own words.

Then test me: Ask me to explain it back to you as if teaching a junior engineer.

TOPIC: [e.g., "How Kerberos delegation works", "Why replication errors happen", "How GPO security filtering works", "What a USN rollback is"]
```

---

## PROMPT 8: Study Card Generator

```
Generate a set of expert-level Active Directory flashcards for spaced repetition learning.

FORMAT (Anki-compatible):
Front: [Concise question — what would appear on a Microsoft exam or interview]
Back: [Complete answer — concise but complete, including: core concept, why it matters, common gotcha]

GENERATE 20 CARDS for: [Topic]

Include mix of:
- Conceptual questions ("What is X?")
- Troubleshooting questions ("Event 4740 means...?")
- Command questions ("How do you check X with repadmin?")
- Design questions ("When would you use X over Y?")
- Gotcha questions ("What's wrong with doing X?")

TOPIC:
[e.g., "Kerberos errors and their causes", "Replication troubleshooting", "FSMO roles", "AD CS design", "Hybrid identity"]
```

---

## Study Tracks by Role

### Track 1: AD Helpdesk → L1 Engineer (2 weeks)
1. What is AD and why it exists (Prompt 2 at Beginner level)
2. Common user issues: lockouts, password resets, group membership
3. Basic PowerShell for AD: Get-ADUser, Get-ADComputer
4. Understanding event logs: 4740, 4625, 4624

### Track 2: L1 → L2 Engineer (4 weeks)
1. Kerberos fundamentals (Prompt 2 at Intermediate level)
2. GPO processing and troubleshooting
3. Replication concepts (Prompt 3)
4. DNS integration with AD
5. Scenario-based learning (Prompt 4)

### Track 3: L2 → L3 Senior Engineer (8 weeks)
1. Kerberos deep dive (Prompt 2 at Advanced level)
2. Replication internals (Prompt 3, all 5 levels)
3. Security concepts: attack paths and defenses
4. Hybrid identity fundamentals
5. Architecture tradeoffs (Prompt 6)
6. Interview prep (Prompt 5)

### Track 4: L3 → Principal/Architect (3 months)
1. Architecture review methodology (see 09-architecture-review-prompts.md)
2. Security architecture (attack and defend)
3. Enterprise design patterns
4. Hybrid identity advanced
5. Incident command and war room methodology
6. Executive communication
