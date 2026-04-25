---
# Adapted from: https://github.com/mattpocock/skills/grill-me (via npx skills@latest add mattpocock/skills/grill-me). Added $ARGUMENTS file path support and file-first read step.
name: challenge
description: Gate — Challenge a plan, ideation file, or design relentlessly. Accepts a file path as $ARGUMENTS (defaults to the most recent file in todo/ if omitted). Reads the file first, then interviews until all open questions are resolved. Use before spec to ensure the idea is ready to formalise.
disable-model-invocation: true
allowed-tools: [Read, Grep, Glob]
---

# challenge

Read the target file. Then interview relentlessly about every aspect of the plan until all open questions are resolved.

## Step 1: Identify the target file

If `$ARGUMENTS` contains a file path, read that file.

If no argument given, find the most recently created file in `todo/`:

```bash
ls -t todo/*.md | head -1
```

Read the file completely.

## Step 2: Begin the interview

Walk through every aspect of the plan — every decision, every assumption, every open question — asking one question at a time.

For each question:
- Provide your recommended answer based on what you know from the codebase and context
- Wait for the user to confirm, override, or expand
- Do not move to the next question until the current one is resolved

Work through these categories in order, but skip any that are already clearly resolved in the file:

1. **Ambiguous requirements** — any "what we know" item that could be interpreted multiple ways
2. **Open questions** — the explicitly listed ones in the file, one by one
3. **Scope creep risks** — things the rough scope implies but doesn't state
4. **Hidden dependencies** — other systems, people, or decisions this depends on
5. **Failure modes** — what could go wrong at each step
6. **Success definition** — is "done" clearly defined?

If a question can be answered by exploring the codebase, explore it before asking.

## Step 3: Continue until done

Keep going until every branch of the decision tree is resolved. Do not summarise prematurely. Do not accept vague answers — if the answer raises another question, ask it.

The interview is complete only when there are no remaining open questions and the rough scope is unambiguous enough to write a spec from.

## Step 4: Summarise

Once complete:

```
Challenge complete. All questions resolved.

Key decisions made:
- {decision 1}
- {decision 2}
...

Recommended next step: /workflow-core:spec todo/{slug}.md
```
