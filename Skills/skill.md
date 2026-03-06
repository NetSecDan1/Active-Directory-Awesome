---
name: prompt-skill-author
description: >
Generates high-quality prompts and SKILL.md files for Claude. Use this skill
whenever the user wants to write, improve, or audit a prompt, system prompt,
operator prompt, or skill file — even if they say "make me a prompt for X",
"turn this into a skill", "write instructions for Claude to do Y", "how do I
prompt Claude to...", or "improve this prompt." Triggers on both prompt
engineering requests and skill authoring requests. Does NOT trigger for general
coding, document creation, or AD/identity tasks unless the goal is writing
instructions for Claude.
---

# Prompt & Skill Author

This skill produces two types of deliverables:

1. **Prompts** — system prompts, operator prompts, one-shot instructions, or
   reusable prompt templates for any Claude use case.
2. **SKILL.md files** — structured skill files Claude can use autonomously,
   following the progressive-disclosure skill format.

Both share the same authoring philosophy: lean, specific, rationale-first writing
that trusts the model to generalize rather than over-specifying with rigid rules.

---

## Determine deliverable type

Before writing anything, classify the request:

- User wants Claude to follow persistent instructions across a workflow → **SKILL.md**
- User wants a one-time or reusable prompt to send to Claude → **Prompt**
- User wants both → produce both, skill first

If it's ambiguous, ask one question: "Should Claude load this automatically when
it detects the task, or will you paste it in each time?"

---

## Authoring a Prompt

### Step 1 — Capture intent

Extract from the user's request (do not ask if inferrable):
- What task is Claude performing?
- Who is the audience for Claude's output?
- What format/length should the output be?
- Any safety, tone, or domain constraints?
- What does a bad output look like? (use as a negative anchor)

### Step 2 — Structure the prompt

Use this ordering:

```
<role>
One sentence: who Claude is and what it's doing.
</role>

<context>
Relevant background the model needs. Only include what changes behavior.
</context>

<task>
Imperative description of what to produce. Be specific about format,
length, and success criteria. Explain WHY constraints exist.
</task>

<output_format>
Exact structure if non-obvious. Include a short example if format is strict.
</output_format>

<safety> (only if relevant)
Read-only/change constraints, tone guardrails, escalation conditions.
</safety>
```

Drop any section that adds no signal. A prompt with two sections that are
tight is better than five sections with padding.

### Step 3 — Apply quality rules

- **One clear job per prompt.** If the prompt does three unrelated things, split it.
- **Explain the why** behind non-obvious constraints. "Use paged queries because
  forest-wide enumerations can stress LSASS" is stronger than "always use paged queries."
- **Positive + negative examples** beat abstract descriptions for format-critical outputs.
- **Avoid hedge stacking.** "Please try to generally consider possibly..." — cut it.
- **No ALL-CAPS MUST/NEVER** unless the constraint is safety-critical. Overuse
  trains the model to ignore emphasis.
- **End with the output, not meta-commentary.** Don't close with "I hope this helps."

### Step 4 — Deliver

Output the final prompt inside a fenced code block, ready to copy. Then add:

```
ASSUMPTIONS:
- [what you inferred about scope/audience/constraints]

THINGS THIS PROMPT DOES NOT HANDLE:
- [explicit gaps]

SUGGESTED TEST:
- [1-2 inputs to validate it works as intended]
```

---

## Authoring a SKILL.md

### Step 1 — Capture intent

Extract (do not ask if inferrable):
- What task does the skill enable?
- When should it trigger? (specific user phrases, contexts)
- What does good output look like?
- What environment/tools are available?
- What are the 2-3 most common ways this could go wrong?

### Step 2 — Write the frontmatter description (most important part)

The description is the ONLY signal Claude uses to decide whether to load the skill.
It must answer: **what does it do** AND **when should it fire**.

Rules:
- Be slightly pushy — list synonyms, adjacent phrasings, and related intents
- Include near-miss exclusions if over-trigger risk is real
- Keep it under 100 words
- All "when to use" logic lives here, not in the body

```yaml
---
name: kebab-case-name
description: >
  [What it does]. Use this skill whenever [specific trigger phrases],
  [adjacent phrasings], or [related intents] — even if the user doesn't
  explicitly say [skill name]. Does NOT trigger for [near-miss exclusions].
---
```

### Step 3 — Write the skill body

Structure in this order:

1. **Orientation paragraph** — what this skill is for and why it exists.
   One paragraph. Explain the goal so Claude can generalize.

2. **Workflow** — numbered imperative steps. Include decision branches inline
   (e.g., "If input is X, do A. If input is Y, do B.").

3. **Output specification** — exact format with a short example if non-obvious.

4. **Quality criteria** — what "done well" looks like. Not a checklist; a
   description of the target standard.

5. **Anti-patterns** — 2-4 specific failure modes with explanations of why
   each is bad. Understanding the why prevents adjacent mistakes.

6. **Bundled resources** (if applicable) — list any scripts or reference files
   Claude should use instead of rewriting from scratch.

Writing style:
- Imperative voice throughout
- Explain WHY for every non-obvious rule
- No preamble ("In this skill, you will...")
- Under 400 lines; move overflow to `references/` with a clear pointer
- No ALL-CAPS emphatics unless truly safety-critical

### Step 4 — Self-check the description

Before delivering, mentally run three test cases:

1. A user says [realistic trigger phrase] → should load ✓
2. A user says [different phrasing of same intent] → should load ✓
3. A user says [near-miss] → should NOT load ✓

Adjust description if any check fails.

### Step 5 — Deliver

Output the complete SKILL.md in a fenced code block. Then add:

```
TRIGGERING SELF-CHECK:
- "[example trigger 1]" → loads ✓
- "[example trigger 2]" → loads ✓
- "[near-miss]" → does not load ✓

TEST CASES (2-3 realistic prompts to validate):
1. [prompt]
2. [prompt]

KNOWN LIMITATIONS:
- [gaps, edge cases, dependencies not handled]
```

---

## Anti-patterns to avoid in all deliverables

- **Over-specifying the obvious** — don't enumerate every formatting detail Claude
  handles correctly by default. Trust the model on low-stakes decisions.
- **Redundant safety warnings** — one clear constraint beats five rewordings of it.
- **Generic descriptions** — "helps with tasks" never triggers. Be specific.
- **Instructions without rationale** — always explain why a non-obvious rule exists.
- **Skill that does too many things** — if scope creep makes the body exceed 400 lines,
  split into focused sub-skills.
- **Padding the output** — don't close with summaries of what you just wrote.
  Deliver the artifact, state the assumptions, stop.