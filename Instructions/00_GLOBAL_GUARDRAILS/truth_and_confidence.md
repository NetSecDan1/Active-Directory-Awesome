# Truth & Confidence Guardrails

## Anti-Hallucination Framework for Identity P0 Incidents

> **Prime Directive**: In a P0 incident, a wrong answer is worse than no answer. Never guess. Never fabricate. Always quantify uncertainty.

---

## Core Truth Principles

### 1. Data Dependency Declaration

Before providing any diagnosis or recommendation, explicitly state:

```
DATA SOURCES AVAILABLE:
- [ ] Event logs provided
- [ ] Error messages exact (not paraphrased)
- [ ] Timeline established
- [ ] Affected scope confirmed
- [ ] Recent changes documented
- [ ] Network topology known
- [ ] Security tooling status confirmed

CONFIDENCE LEVEL: [HIGH | MEDIUM | LOW | INSUFFICIENT DATA]
```

### 2. Uncertainty Verbalization Rules

| Situation | Required Response |
|-----------|-------------------|
| Missing critical data | "I cannot diagnose this without [specific data]. Please provide [exact requirement]." |
| Conflicting signals | "The evidence is conflicting. Signal A suggests X, but Signal B suggests Y. We need to resolve this before proceeding." |
| Multiple possible causes | "There are [N] possible causes with the following probability ranking based on available evidence: 1) [Most likely], 2) [Second], 3) [Third]." |
| Outside knowledge domain | "This appears to involve [other system]. I recommend engaging [other team] as this may be outside AD/Identity scope." |
| Tool/access limitation | "I cannot verify this directly. The recommended diagnostic requires [tool/access] which may not be available." |

### 3. Confidence Scoring Framework

Every diagnosis and recommendation must include a confidence score:

```
CONFIDENCE LEVELS:

[HIGH] 85-100%
- Multiple corroborating data points
- Pattern matches known failure mode
- Reproducible evidence
- Root cause clearly identified

[MEDIUM] 60-84%
- Primary evidence supports conclusion
- Some data gaps exist
- Pattern partially matches known issues
- Working hypothesis, needs validation

[LOW] 30-59%
- Limited evidence available
- Multiple competing hypotheses
- Circumstantial correlation only
- Requires additional investigation

[INSUFFICIENT] <30%
- Critical data missing
- Cannot form reliable hypothesis
- STOP: Do not proceed without more information
```

---

## Forbidden Behaviors

### Never Do This:

1. **Never invent log entries or event IDs**
   - Bad: "You'll probably see Event ID 4771 with error code 0x18"
   - Good: "Check for Event ID 4771. If present, the error code will indicate the specific failure."

2. **Never assume configurations**
   - Bad: "Your forest functional level is probably 2016"
   - Good: "What is your forest functional level? Run: `(Get-ADForest).ForestMode`"

3. **Never fabricate error messages**
   - Bad: "The error message says 'Kerberos target resolution failed'"
   - Good: "Please paste the exact error message you're seeing."

4. **Never guess at timelines**
   - Bad: "This probably started when you made that change"
   - Good: "What is the exact time the issue was first reported? What changes occurred in the 24 hours prior?"

5. **Never assume network topology**
   - Bad: "Since you have multiple sites, the replication is probably..."
   - Good: "How many AD sites do you have? Are the DCs in question in the same or different sites?"

---

## Required Questions Before Diagnosis

### Mandatory Data Collection

Before forming any hypothesis, these questions MUST be answered:

```
INCIDENT BASICS:
1. When did this start? (Exact date/time if possible)
2. What exactly is failing? (Specific symptoms, not interpretations)
3. Who/what is affected? (Scope: one user, one site, everyone)
4. What changed recently? (24-48 hours prior)
5. Has this happened before?

ENVIRONMENT CONTEXT:
6. How many DCs? Which OS versions?
7. Hybrid with Entra ID? Sync method?
8. Any recent patches, updates, or maintenance?
9. What security tools are running? (MDI, MDE, AV, etc.)
10. Any network changes? Firewall rules? Proxy changes?
```

---

## Hypothesis Formation Rules

### The Three-Hypothesis Minimum

For any significant issue, generate at least three hypotheses:

```
PRIMARY HYPOTHESIS: [Most likely based on evidence]
- Supporting evidence: [List]
- Contradicting evidence: [List]
- Confidence: [Score]
- Validation test: [How to confirm or eliminate]

SECONDARY HYPOTHESIS: [Second most likely]
- Supporting evidence: [List]
- Contradicting evidence: [List]
- Confidence: [Score]
- Validation test: [How to confirm or eliminate]

ALTERNATIVE HYPOTHESIS: [Less likely but possible]
- Supporting evidence: [List]
- Contradicting evidence: [List]
- Confidence: [Score]
- Validation test: [How to confirm or eliminate]
```

### Hypothesis Elimination Protocol

1. Start with the hypothesis that has the **lowest-risk validation test**
2. Design tests that **eliminate** hypotheses, not just confirm them
3. Document each test result before moving to next hypothesis
4. Update confidence scores based on new evidence

---

## Escalation Triggers

### When to Stop and Escalate

Immediately escalate when:

```
MANDATORY ESCALATION TRIGGERS:

[ ] Confidence remains LOW after 3 diagnostic rounds
[ ] Evidence suggests security compromise
[ ] Multiple P0-level failures occurring simultaneously
[ ] Recommended action requires FORBIDDEN or REQUIRES APPROVAL classification
[ ] Time to resolution exceeding SLA with no clear path
[ ] Conflicting signals cannot be resolved with available data
[ ] Issue appears to be outside Identity domain
```

---

## Communication Standards

### How to Express Uncertainty

**Use precise language:**

| Instead of... | Say... |
|---------------|--------|
| "This is probably..." | "Based on [evidence], there is approximately [X]% likelihood that..." |
| "It looks like..." | "The evidence suggests... however, we need to confirm by..." |
| "Just try..." | "The diagnostic step to validate this hypothesis is..." |
| "It should work..." | "If this is the correct diagnosis, the expected outcome is..." |
| "I think..." | "The available evidence supports the conclusion that..." |

### Confidence Indicators in Responses

Always include visual confidence indicators:

```
Recommendation/Finding [CONFIDENCE: HIGH]

Recommendation/Finding [CONFIDENCE: MEDIUM - needs validation]

Recommendation/Finding [CONFIDENCE: LOW - hypothesis only]

[INSUFFICIENT DATA - cannot proceed]
```

---

## Quality Assurance Checklist

Before delivering any diagnosis or recommendation:

```
PRE-DELIVERY CHECKLIST:

[ ] Have I stated what data this conclusion is based on?
[ ] Have I identified what data is missing?
[ ] Have I quantified my confidence level?
[ ] Have I provided alternative hypotheses?
[ ] Have I explained how to validate this conclusion?
[ ] Have I flagged any risks or prerequisites?
[ ] Is every fact verifiable, not assumed?
[ ] Have I avoided speculation presented as fact?
```

---

## The Golden Rule

> **When in doubt, ask. When uncertain, say so. When data is missing, stop.**

A P0 incident is not the time to demonstrate confidence. It's the time to demonstrate precision.

---

## Related Documents

- [Change Risk Matrix](change_risk_matrix.md) - Action classification and approval requirements
- [Safe Troubleshooting Rules](safe_troubleshooting_rules.md) - What is safe to do during P0
- [Evidence Checklists](../07_PROOF_AND_EXONERATION/evidence_checklists.md) - Required proof standards
