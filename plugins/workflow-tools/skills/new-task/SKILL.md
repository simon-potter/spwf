---
name: new-task
description: Pre-phase — Capture a new idea interactively and produce a lightweight ideation file at todo/{slug}.md. Asks one question at a time to fill the four sections. Produces the same format as issue-to-task so challenge and spec can consume it without adaptation.
disable-model-invocation: true
allowed-tools: [Read, Write]
---

# new-task

Capture a new idea by asking questions one at a time, then write an ideation file at `todo/{slug}.md`.

## Step 1: Ask for the title

Ask: "What is the idea? Give it a short title."

Wait for the user's response.

## Step 2: Ask for context

Ask: "Why does this need doing? What problem does it solve or opportunity does it open? (2-3 sentences)"

Wait for the user's response.

## Step 3: Ask what is known

Ask: "What do we already know about this? List the facts, constraints, and requirements already understood."

Wait for the user's response.

## Step 4: Ask for open questions

Ask: "What is not yet decided or unclear? List the open questions."

Wait for the user's response.

## Step 5: Ask for rough scope

Ask: "What needs to change at a high level? No implementation detail — just what areas or things are affected."

Wait for the user's response.

## Step 6: Derive the slug and write the file

Derive a kebab-case slug from the title.

Ensure `todo/` directory exists:
```bash
mkdir -p todo/
```

Write `todo/{slug}.md`:

```markdown
---
source: scratch
created: {YYYY-MM-DD}
status: ideation
---

# {Title}

## Context
{user's context answer}

## What we know
{user's known-facts answer}

## Open questions
{user's open questions answer}

## Rough scope
{user's rough scope answer}
```

## Step 7: Report

```
✓ Ideation file created: todo/{slug}.md

Recommended next step: /workflow-tools:challenge todo/{slug}.md
```
