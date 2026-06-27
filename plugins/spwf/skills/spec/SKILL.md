---
# Adapted from: ~/.claude/skills/ideation-to-openspec/ — original by Simon Potter
name: spec
description: Phase 1 — Spec. Convert a challenged ideation file into a complete OpenSpec change proposal with fidelity validation. Use when you have a file in todo/ that has been through challenge and is ready to be formalised. Checks that openspec/ is initialised before starting.
disable-model-invocation: true
allowed-tools: [Read, Write, Bash]
---

# spec

Convert a challenged ideation file (in `todo/`) into a validated OpenSpec change proposal. Requires OpenSpec to be initialised in the current project.

## Step 0: Check prerequisites

```bash
test -d openspec/ || echo "MISSING"
```

If the `openspec/` directory does not exist, halt immediately:

```
OpenSpec not initialised. Run: openspec init
```

Do not proceed until the user runs `openspec init`.

## Step 1: Identify the source file

If `$ARGUMENTS` contains a file path, use it. Otherwise list files in `todo/` and use the most recently created ideation file (check `status: ideation` in frontmatter).

Read the source file completely.

Note the ideation file's `ticket:` frontmatter field if present (written by
`capture` / `issue-to-task` for tracker-sourced work). Carry it into the
proposal in Step 3. If there is no `ticket:` field, omit the Tracker line
entirely in Step 3 — do **not** prompt for or invent a ticket.

## Step 2: Determine change-id

Use a verb-led kebab-case slug: `add-`, `refactor-`, `update-`, `remove-`.

Verify uniqueness:
```bash
openspec list
```

## Step 3: Create OpenSpec structure

```bash
mkdir -p openspec/changes/{change-id}/specs/{capability}/
```

Generate these files:

### proposal.md

```markdown
# Proposal: {Title}

**Change ID**: `{change-id}`
**Status**: Draft
**Created**: {date}
**Source**: [todo/{slug}.md](../../../todo/{slug}.md)
**Tracker**: {ticket}   ← include ONLY if the ideation file had a `ticket:` field; omit this line entirely otherwise

---

## Why
{Problem or opportunity from the Context section — 1-2 sentences}

## What Changes
- {Bullet list from What we know + Rough scope}

## Impact
- **Affected areas**: {from Rough scope}
- **No breaking changes** / **BREAKING**: {if applicable}

---

## Decisions
{Any open questions from the ideation file — marked TBD}

## Success Criteria
{What "done" looks like — derived from Rough scope}
```

### design.md

Create only if the ideation file contains technical decisions, alternatives, or architectural rationale. Otherwise skip.

### tasks.md

Tasks must be structured for TDD. Each task describes a single, testable unit of behaviour. The build cycle writes failing tests for each task before implementing it, so every task must be implementable in one Red→Green cycle.

**Task quality rules:**
- One task = one behaviour = one set of tests
- Phrase tasks as outcomes, not activities: "Returns empty list when no items exist" not "Handle empty case"
- Order tasks so later tasks build on earlier passing tests — never break green
- Group related tasks into phases; each phase should leave the suite green when complete

```markdown
# Tasks: {change-id}

> **Authoritative Reference:** [`todo/{slug}.md`](../../../todo/{slug}.md)

## Phase 1 — {First logical group}

- [ ] 1.1 {Behaviour: what the code does when X}
- [ ] 1.2 {Behaviour: what the code does when Y}
```

### specs/{capability}/spec.md

```markdown
## ADDED Requirements

### Requirement: {name}

{Short description} SHALL {behaviour}.

#### Scenario: {description}

**WHEN** {trigger}
**THEN** {outcome}
```

## Step 4: Fidelity validation

Verify nothing from the ideation file was lost:

| Check | Target |
|---|---|
| Context captured | proposal.md Why section |
| What we know captured | proposal.md What Changes |
| Open questions addressed | proposal.md Decisions (TBD) |
| Rough scope decomposed | tasks.md |

## Step 5: Validate and report

```bash
openspec validate {change-id} --strict
```

Fix any validation errors, then report:
- Files created
- Any items from the ideation file needing a decision
- Suggested next step: `/spwf:approve-plan`

## Step 5.5: Ensure feature branch

Before committing, make sure the spec commit lands on `feature/{change-id}`,
not on the base branch. Delegates to
[`_shared/branch-management.md` §3 "Auto-branch operation"](../_shared/branch-management.md#3-auto-branch-operation).

Read `.spwf/branch.yaml` (defaults: `prefix: feature/`, `base: main`,
`auto_branch: always`, `enforce: true`) per
[§1](../_shared/branch-management.md#1-config-schema-spwfbranchyaml).

**Opt-outs (skip this step silently, no output):**
- `.spwf/branch.yaml: enforce: false`
- `.spwf/branch.yaml: auto_branch: never`

Otherwise classify the current branch per the
[detect-state table §2](../_shared/branch-management.md#2-detect-state-decision-table)
and act — emitting **exactly one** confirmation line:

| State | Action | Confirmation line |
|---|---|---|
| On `base` | `git checkout -b feature/{change-id}` (auto). If `auto_branch: ask`, prompt `Create branch feature/{change-id} from {base}? [Y/n]` first | `✓ Branched to feature/{change-id} (auto)` |
| On `feature/{change-id}` already | no-op | `✓ Already on feature/{change-id}` |
| `feature/{change-id}` exists but not checked out | `git checkout feature/{change-id}` (not `-b`). If the existing branch is behind HEAD, halt with `branch exists but is behind HEAD — manual merge or rebase required` | `✓ Switched to existing feature/{change-id}` |
| On another branch | Ask once: `You're on {current}, not {base} and not feature/{change-id}. Spec on {current} or create feature/{change-id}?` — proceed per the answer | (per answer) |

If the working tree carries uncommitted changes unrelated to the spec
artefacts about to be committed, halt per
[§3 failure handling](../_shared/branch-management.md#3-auto-branch-operation).

## Step 6: Commit

Show `git status` so the user sees all new spec artefacts, then propose a commit:

```
spec: add OpenSpec change {change-id}

{1-2 sentences summarising what the change delivers and why}

Artefacts: proposal.md, tasks.md, {N} spec scenarios{, design.md if created}
{if any open decisions remain: TBD decisions: {list them}}
{if any notable structural discovery during spec work, e.g. "split into 2 phases
because task 3 depends on task 1 completing fully"}
```

Ask: "Ready to commit? Confirm with 'yes' or edit the message first."

After confirming, stage all new spec artefacts and commit:

```bash
git add openspec/changes/{change-id}/
git commit -m "{confirmed message}"
```
