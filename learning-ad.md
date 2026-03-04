# Learning Active Directory

**Use Case:** Learn Active Directory from scratch or level up specific knowledge areas. Adaptive to any experience level.
**Techniques:** Concept layering, hands-on labs, analogy-based learning, certification prep

---

## The AD Learning Path

```
You are an expert AD instructor who has trained IT professionals from helpdesk to architect level. You know how concepts connect and what order to learn them.

MY CURRENT LEVEL:
[ ] Complete beginner (IT background but never touched AD)
[ ] Basic user (can manage users/groups but don't understand the underlying concepts)
[ ] Intermediate (comfortable with day-to-day tasks, want to understand deeply)
[ ] Advanced (understand most things, want expert/architect level knowledge)

MY GOAL:
[e.g., pass AZ-800, become the AD admin at my company, understand how attacks work, design enterprise AD]

TIME AVAILABLE:
[Hours per week, and total weeks]

---

Design my personalized Active Directory learning plan:

## 1. Prerequisite Check
What should I already understand before diving into AD? (Networking basics, Windows server basics, DNS, etc.)

## 2. Learning Sequence
Order the topics from foundational to advanced. Explain WHY this order — what does each concept unlock?

### Foundation (Week 1-2)
- What AD actually is and does (vs. what it's often described as)
- Domains, forests, and trusts
- The role of Domain Controllers
- LDAP basics — the directory model
- DNS and why it's the backbone of AD

### Authentication Deep Dive (Week 3-4)
- Kerberos: TGT, TGS, how tickets work
- NTLM: when and why it's still used
- Authentication flows: what actually happens when you log in
- Service accounts and SPNs

### Administration (Week 5-6)
- OU structure and why it matters
- Group Policy: design, application, troubleshooting
- Delegation of control
- FSMO roles — what they do and why they matter

### Security (Week 7-8)
- AD attack surface: what attackers target and why
- Kerberoasting, Pass-the-Hash, Golden Tickets — understand to defend
- Admin tiering model
- Monitoring and detection

### Advanced Topics (Week 9+)
- Sites and replication
- AD schema and attributes
- Hybrid identity with Entra ID
- Federation and ADFS
- AD certificate services (PKI)

## 3. Hands-On Labs
For each topic: what to build in a home lab to reinforce the concept.

## 4. Mental Models
The 3-5 analogies that make AD concepts click.

## 5. Resources
Best resources for my level (Microsoft Learn, books, YouTube, courses).
```

---

## Concept Explainer (On Demand)

```
Explain [AD CONCEPT] to me.

My current understanding: [what you think you know]
Context: [why you need to understand this]

Cover:
1. What it is in plain English (no acronym soup until concepts are clear)
2. Why it exists — what problem does it solve?
3. How it works — the key mechanism, not every detail
4. A concrete analogy I can use to remember it
5. How it interacts with [related concepts I care about]
6. The most common misconception about it
7. When it matters in practice — real scenarios where understanding this helps

Stop and check: does this make sense? Then give me one question to test my understanding.
```

---

## Kerberos Explainer (Most Requested)

```
Explain Kerberos authentication in Active Directory step by step.

I want to understand:
1. Why Kerberos was invented (what's wrong with sending passwords directly?)
2. The three parties: Client, KDC (AS + TGS), Service
3. The authentication dance step by step — what message goes where and why
4. What a TGT is and why it matters
5. What a Service Ticket is and how the service uses it
6. Why Kerberos is considered secure (what it proves without revealing)
7. The weakness that Kerberoasting exploits
8. What "pre-authentication" is and why disabling it is dangerous

Use an analogy (hotel key card, passport+boarding pass, etc.) to make the flow intuitive. Then give me the technical details.
```

---

## Lab Design Prompt

```
Design a home lab for learning [AD TOPIC / certification prep].

I have:
- Hardware: [RAM, CPU, storage available]
- Virtualization: [Hyper-V / VMware / VirtualBox]
- Licenses: [Windows eval? MSDN/Visual Studio subscription?]

Design:
1. VM inventory (what to build and why)
2. Network topology (how VMs connect)
3. Build sequence (what to install in what order)
4. Configuration checklist per VM
5. Labs to run on this environment for maximum learning
6. How to simulate attacks safely (if security focused)

Keep it minimal — just enough to learn the concepts, not a full enterprise replica.
```

---

## Certification Prep Prompt

```
I'm preparing for [AZ-800 / AZ-801 / MS-102 / SC-300 / other].

Exam: [name]
Test date: [when]
Current knowledge: [self-assessment]

Create:
1. Exam skill breakdown by domain with weighting
2. Which topics I probably know well vs. which to focus on
3. Daily study plan for the remaining time
4. Top 10 practice scenarios for this exam (not questions — scenarios to understand deeply)
5. Common "gotcha" questions this exam is known for
6. The 5 concepts most candidates get wrong
```

---

**Tips:**
- Build a lab — reading about AD is worth 20% of what hands-on is worth
- The best sequence: Install a DC → Break it → Fix it → Understand why it broke
- Don't memorize — understand the why, and the what follows
- The most important AD concept to really internalize: the Kerberos authentication flow
- For SC-300/Entra: know how Entra Connect sync works — it's on every exam
