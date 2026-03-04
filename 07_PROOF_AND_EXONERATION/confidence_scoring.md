# Confidence Scoring Framework

## Quantifying Certainty in Identity Diagnostics

> **Principle**: Every conclusion must have a confidence score. Untethered opinions cause more damage than honest uncertainty.

---

## The Confidence Scale

### Scoring Definitions

| Score | Level | Meaning | Action Guidance |
|-------|-------|---------|-----------------|
| 95-100% | **CERTAIN** | Definitive evidence, no reasonable doubt | Proceed with remediation |
| 85-94% | **HIGH** | Strong evidence, minor gaps acceptable | Proceed with monitoring |
| 70-84% | **MEDIUM** | Good evidence, some validation needed | Test hypothesis before action |
| 50-69% | **LOW** | Evidence suggests but doesn't prove | Gather more evidence |
| 30-49% | **UNCERTAIN** | Multiple possibilities, limited evidence | Cannot act on this |
| 0-29% | **INSUFFICIENT** | Cannot form conclusion | Stop and collect data |

---

## Confidence Calculation Method

### The Evidence Multiplier Approach

```
CONFIDENCE CALCULATION:

Base Score: Start at 50% (uncertainty)

ADD points for:
+ Direct evidence (log entry, error code): +10-20 per source
+ Reproducible test result: +15-25
+ Multiple independent sources agreeing: +10-15
+ Pattern matches known failure mode: +10-15
+ Timeline correlation: +5-10

SUBTRACT points for:
- Missing critical data: -10-20
- Conflicting evidence: -15-25
- Unusual/rare failure mode: -5-10
- Cannot reproduce: -10-15
- Based on assumption: -10-20

FINAL SCORE: Sum (capped at 100)
```

### Example Calculation

```
SCENARIO: "DC1 replication failure is causing auth issues"

Base: 50%

Evidence:
+ repadmin shows DC1 failing: +15
+ Event 1864 on DC1: +15
+ Error 8453 in logs: +15
+ Affected users all in DC1 site: +10
+ Timeline matches DC1 problem start: +10

Deductions:
- Cannot test from affected client: -5
- Only checked 2 of 5 DCs: -10

FINAL: 50 + 65 - 15 = 100 (capped) → HIGH CONFIDENCE
```

---

## Evidence Strength Matrix

### By Evidence Type

| Evidence Type | Base Points | Notes |
|---------------|-------------|-------|
| **Error code from system** | +15-20 | Depends on specificity |
| **Event log entry** | +10-15 | With timestamp and details |
| **Successful diagnostic test** | +15-25 | Depending on directness |
| **Failed diagnostic test** | +10-15 | Proves negative |
| **Monitoring alert** | +10-15 | If correlated correctly |
| **User report** | +5-10 | Subjective, needs verification |
| **Pattern match** | +10-15 | If pattern is well-established |
| **Timeline correlation** | +5-10 | Suggestive, not definitive |
| **Configuration finding** | +10-20 | Depends on relevance |
| **Absence of errors** | +5-10 | Weaker than positive evidence |

### Evidence Quality Modifiers

| Factor | Modifier |
|--------|----------|
| Evidence is from affected system | +5 |
| Evidence is from multiple sources | +10 |
| Evidence is timestamped precisely | +5 |
| Evidence requires interpretation | -5 |
| Evidence is secondhand | -10 |
| Evidence is older than 24 hours | -5 |

---

## Confidence in Different Scenarios

### Diagnosis Confidence

```
DIAGNOSIS CONFIDENCE REQUIREMENTS:

To claim root cause with HIGH confidence (85%+):
□ At least one direct evidence source
□ No contradicting evidence
□ Pattern matches known failure mode OR
□ Reproducible test confirms

To proceed with MEDIUM confidence (70-84%):
□ Strong circumstantial evidence
□ No strong contradicting evidence
□ Hypothesis is plausible
□ Test plan exists to validate

Must STOP and gather more data if:
□ Confidence below 50%
□ Critical data is missing
□ Evidence is conflicting
□ Acting could cause harm
```

### Exoneration Confidence

```
EXONERATION CONFIDENCE REQUIREMENTS:

To exonerate with HIGH confidence (85%+):
□ All primary systems verified working
□ Multiple independent tests pass
□ Alternative cause identified OR
□ Complete evidence chain rules out identity

To exonerate with MEDIUM confidence (70-84%):
□ Primary systems verified working
□ No identity-related errors found
□ Evidence points to alternative cause

Cannot exonerate if:
□ Any identity test fails
□ Evidence is incomplete
□ Cannot rule out identity involvement
```

---

## Documenting Confidence

### Confidence Statement Template

```
CONFIDENCE STATEMENT

Conclusion: [Statement of finding]

Confidence Level: [Score]% - [Level Name]

Supporting Evidence:
1. [Evidence] (+X points)
2. [Evidence] (+X points)
3. [Evidence] (+X points)

Limiting Factors:
1. [Gap or uncertainty] (-X points)
2. [Gap or uncertainty] (-X points)

Net Assessment:
Base (50) + Supports (Y) - Limits (Z) = [Score]%

What Would Increase Confidence:
- [Additional evidence needed]
- [Additional test needed]

What Would Decrease Confidence:
- [Contradicting evidence if found]
- [Failed test if it occurred]
```

### Example Confidence Statement

```
CONFIDENCE STATEMENT

Conclusion: The authentication failures are caused by expired
           KDC certificate on DC1.

Confidence Level: 92% - HIGH

Supporting Evidence:
1. Event 29 (KDC cert error) in System log (+20)
2. Certificate expired 2 hours before issue started (+15)
3. Auth works to DC2 and DC3 (+15)
4. Timeline matches exactly (+10)

Limiting Factors:
1. Haven't tested from all client types (-5)
2. DC1 has other warnings (unrelated) (-3)

Net Assessment:
Base (50) + Supports (60) - Limits (8) = 102% → 92% (conservative)

What Would Increase Confidence:
- Renew cert and verify resolution

What Would Decrease Confidence:
- If cert renewal doesn't fix the issue
```

---

## Confidence Communication

### How to Express Confidence

| Confidence | Say | Don't Say |
|------------|-----|-----------|
| 95%+ | "We have confirmed that..." | "We think maybe..." |
| 85-94% | "Evidence strongly indicates..." | "It's probably..." |
| 70-84% | "Available evidence suggests..." | "I believe that..." |
| 50-69% | "This is one possibility..." | "It must be..." |
| <50% | "We need more information..." | "I'm not sure but..." |

### In Reports and Updates

```
HIGH CONFIDENCE (85%+):
"Root cause has been identified as [X] with high confidence.
Evidence includes [key points]. Proceeding with remediation."

MEDIUM CONFIDENCE (70-84%):
"Evidence suggests [X] as the likely cause. We are [testing/
validating] before proceeding with remediation."

LOW CONFIDENCE (50-69%):
"Multiple possible causes exist. Current hypothesis is [X]
based on [limited evidence]. Gathering additional data."

INSUFFICIENT (<50%):
"Unable to determine cause with available information.
Need [specific data] before forming hypothesis."
```

---

## Confidence Traps to Avoid

### Common Mistakes

```
CONFIDENCE TRAPS:

1. ANCHORING BIAS
   First piece of evidence carries too much weight.
   Fix: Require minimum 3 evidence sources.

2. CONFIRMATION BIAS
   Only seeing evidence that supports initial guess.
   Fix: Actively look for contradicting evidence.

3. FALSE PRECISION
   "I'm 73.5% confident" - meaningless precision.
   Fix: Use defined confidence bands.

4. OVERCONFIDENCE
   "We've always seen this before" isn't evidence.
   Fix: Require current evidence, not history.

5. UNDERCONFIDENCE
   Excessive hedging when evidence is strong.
   Fix: Trust strong evidence chains.

6. EXPERTISE CONFIDENCE
   "I've been doing this 20 years" isn't evidence.
   Fix: Experience informs, evidence proves.
```

---

## Quality Assurance Checks

### Before Stating Any Confidence

```
CONFIDENCE QA CHECKLIST:

□ Have I explicitly listed my evidence?
□ Have I assigned reasonable point values?
□ Have I looked for contradicting evidence?
□ Have I identified what's missing?
□ Would another expert reach similar conclusion?
□ Have I avoided stating certainty from assumption?
□ Is my confidence appropriate for the evidence quality?
□ Have I documented how confidence could change?
```

### Peer Review Criteria

```
WHEN REVIEWING ANOTHER'S CONFIDENCE:

Ask:
- Is the evidence chain documented?
- Are the confidence points reasonable?
- Is anything overstated?
- Is anything understated?
- What evidence would I want?
- Do I agree with the conclusion?

Challenge if:
- Confidence seems high for evidence presented
- Critical evidence is missing
- Contradicting evidence is ignored
- Assumptions are treated as facts
```

---

## Related Documents

- [Truth and Confidence](../00_GLOBAL_GUARDRAILS/truth_and_confidence.md) - Overall truth framework
- [Evidence Checklists](evidence_checklists.md) - What evidence to collect
- [Proving Not AD or Entra](proving_not_ad_or_entra.md) - Exoneration framework
