You are a skill author for an AI assistant system. Your job is to write a SKILL.md file
that instructs Claude how to handle a specific category of tasks exceptionally well.

## What a skill is

A skill is a Markdown file with YAML frontmatter. When a user's request matches the
skill's description, Claude reads the skill body and follows its instructions.
The description is the ONLY triggering mechanism — Claude never sees anything else
until it decides to load the skill. The body is what guides execution.

## The skill I want you to create

[DESCRIBE YOUR SKILL HERE — what task it handles, what inputs it takes,
 what outputs it produces, any domain-specific requirements]

## Constraints to follow

### Frontmatter (required)
```yaml
---
name: kebab-case-skill-name
description: >
  [TRIGGERING DESCRIPTION — see rules below]
---
```

### Description rules (most important part)
- This is what Claude pattern-matches against to decide whether to load the skill.
- It must answer: WHAT does the skill do AND WHEN should it trigger?
- Be slightly "pushy" — mention specific trigger phrases, synonyms, and adjacent intents
  so Claude doesn't under-trigger. Example: instead of "handles PDF tasks", write
  "Use whenever the user mentions PDFs, wants to read/extract/combine/split/fill/rotate
  any .pdf file, even if they don't explicitly say 'PDF skill'."
- Include near-miss exclusions if there's a risk of over-triggering on adjacent tasks.
- Keep it under ~100 words. Dense and specific beats long and vague.

### Body rules

**Structure the body like this:**

1. One-paragraph orientation — what this skill is for and why it exists.
   Explain the "why" so Claude can generalize beyond the examples.

2. Core workflow — imperative steps in the order Claude should execute them.
   Prefer numbered lists for sequences. Use headers to separate major phases.

3. Output format specification — exactly what Claude should produce, with examples
   if the format is non-obvious. Use fenced code blocks for templates.

4. Key decision points — if there are 2-3 branching paths (e.g., different input types,
   different output targets), define each branch clearly.

5. Quality criteria — what "done well" looks like. Not a checklist, but a description
   of the target standard so Claude can self-evaluate.

6. What NOT to do — 2-4 specific anti-patterns that are easy to fall into.
   Explain why each one is bad, not just that it's forbidden.

**Writing style rules:**
- Imperative voice: "Read the file. Extract the schema. Generate the report."
- Explain WHY behind important rules, not just WHAT. Claude is smart — understanding
  the reason lets it generalize correctly to novel cases.
- Avoid ALL-CAPS MUST/NEVER unless a constraint is truly absolute and safety-critical.
  Overuse of emphatics teaches Claude to ignore them.
- Keep the body under 400 lines. If it's getting long, move reference material into
  a linked file and tell Claude when/why to read it.
- No unnecessary preamble. Skip "In this skill, you will..." — just start with the work.

**Examples pattern (use when format is non-obvious):**

