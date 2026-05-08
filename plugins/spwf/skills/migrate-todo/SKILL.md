---
name: migrate-todo
description: Cross-cutting — Audit a todo file, folder, or all of todo/ and bring legacy files into the SPWorkflow convention. Files with compliant frontmatter (source, created, status) are skipped. Legacy files get normalised frontmatter; files marked complete are moved to todo/_done/. Mirrors doc-lint's flag pattern — default reports only, --fix is interactive, --auto-fix applies safe transforms in batch. Pair with /spwf:close which moves completed todos to _done/ prospectively; this skill catches the retroactive backlog.
disable-model-invocation: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# migrate-todo

Audit `todo/` (or a scoped subset) and bring legacy files into the
SPWorkflow convention. Compliant files are skipped silently; partial or
legacy files get normalised frontmatter; completed files move to
`todo/_done/`.

This skill complements `/spwf:close` — close moves completed todos
prospectively when a change is wrapped up; migrate-todo catches the
retroactive backlog. It also complements `/spwf:spec`: spec converts
ideation → active OpenSpec; migrate-todo just normalises the file. It
does **not** fabricate OpenSpec archive entries for legacy completed
work.

## Usage

```bash
# Report only — list classifications, no changes
/spwf:migrate-todo

# Interactive fix — walk each non-compliant file with confirmation
/spwf:migrate-todo --fix

# Auto-fix — apply safe transforms in batch; status: still asked per file
/spwf:migrate-todo --auto-fix

# Quick check — frontmatter only; no _done/ moves
/spwf:migrate-todo --quick

# Scoped to a single file or directory
/spwf:migrate-todo todo/some-file.md
/spwf:migrate-todo legacy-imports/
```

## Step 1 — Resolve scope

Read `$ARGUMENTS`. Strip recognised flags (`--fix`, `--auto-fix`,
`--quick`) and treat anything else as a path:

| Path | Files to consider |
|---|---|
| Empty | `todo/*.md` (top-level only) |
| File path ending `.md` | The single file |
| Directory path | `*.md` files at that directory's top level (no recursion) |

Always exclude:
- `todo/_done/` and any subdirectory
- Non-`.md` files (PDFs, archives, design docs that aren't workflow todos)
- Files inside `openspec/` or `.git/`

If no `.md` files match, report "No files in scope." and exit cleanly.

## Step 2 — Parse frontmatter (block-scoped)

For each file, parse the leading YAML frontmatter block — **not** by
grepping the whole file. The naive `grep ^status:` pattern matches body
content like `Marketplace_setup.md` line 377, which contains
`status: ideation` in prose.

Block-scoped extraction:

```bash
# Extract lines between the first two `---` markers
awk '/^---$/{c++; next} c==1' {file}
```

Then parse the extracted block as YAML. If parsing fails (no opening
`---`, no closing `---`, malformed YAML inside) → classify as
**Malformed** (see Step 3).

Required keys: `source`, `created`, `status`. Read their values for
classification.

## Step 3 — Classify (in order; first match wins)

| Class | Detection | Action driver |
|---|---|---|
| **Compliant active** | All three required keys present; `status != complete` | Skip; report `✓` line |
| **Compliant complete** | All three required keys present; `status == complete` | Offer to move to `todo/_done/` (retroactive case) |
| **Partial frontmatter** | Frontmatter block exists; missing one or two required keys | Fill missing fields per mode rules |
| **No frontmatter** | No leading `---` block at all | Synthesise full frontmatter per mode rules |
| **Malformed frontmatter** | Opening `---` present but closing missing, or YAML invalid | Report and halt for that file. Do not auto-repair. |
| **Looks like a non-todo** | No frontmatter AND body opens with reference-doc shape (no `## Context` / `## What we know` / `## Open questions` style headings; reads as an article, design doc, or external import) | Prompt: "This looks like a reference doc, not a workflow todo. Migrate anyway? [y/N]" — default no |

### Inference rules for missing fields

When a field needs filling and the user hasn't provided it:

| Field | Inference (--auto-fix) | Interactive (--fix) |
|---|---|---|
| `source:` | `scratch` | Ask: "Source for this todo? `scratch` / `jira` / `youtrack` / `slack` / `file` (default: scratch)" |
| `created:` | `git log --diff-filter=A --format=%ai -- {file}` (first commit). Fallback: filesystem mtime via `stat -c %y {file}` (or `stat -f %SB` on macOS). Format as `YYYY-MM-DD`. | Same inference; show the inferred value and confirm |
| `status:` | **Never auto-infer.** Always prompt. | Ask: "Status for this todo? `ideation` / `analysis` / `challenged` / `split` / `complete` / `in-progress`" |

The asymmetry on `status:` is deliberate. The difference between
`complete` and `ideation` decides whether the file moves to `_done/` —
too consequential for `--auto-fix` to decide silently.

## Step 4 — Apply per mode

### Default mode (no flag)

Report only. Do not modify any file. The output is a summary table
classifying every file in scope.

### `--fix` mode

For each non-compliant file:

1. Show the file path, current frontmatter (or absence), and the proposed
   change (full frontmatter block to be written).
2. Prompt for any required user input (status, source choice when
   `--auto-fix` would default to `scratch`).
3. Ask `[Y/n/skip]` to apply, decline, or skip without comment.
4. If `Y`: apply via `Edit` (insert frontmatter at top of file, or replace
   existing block).
5. If a file is **Compliant complete**, after frontmatter is correct, ask
   `Move to todo/_done/{filename}? [Y/n]`.

### `--auto-fix` mode

For each non-compliant file:

1. If status is missing, ask once per file (no batching — judgement call).
2. For other missing fields, apply inferences silently (`source: scratch`,
   `created` from git log).
3. Apply the change.
4. For **Compliant complete**, move to `_done/` without prompting.

### `--quick` mode

Frontmatter check only. Skip the `_done/` move action even when a file is
compliant-complete. Useful when triaging without committing to file
moves.

## Step 5 — Move action (compliant complete → `todo/_done/`)

Only fires for files that have or have-just-acquired `status: complete`.

```bash
mkdir -p todo/_done
git mv todo/{filename} todo/_done/{filename}
```

Collision check before the move: if `todo/_done/{filename}` already
exists, halt for that file with:

> *"Collision: `todo/_done/{filename}` already exists. Resolve manually
> (rename or delete the older file) and re-run /spwf:migrate-todo."*

Never overwrite. Continue with other files.

If the file is not tracked by git (`git ls-files --error-unmatch {file}`
fails), fall back to plain `mv` and warn that the move isn't recorded in
git history.

## Step 6 — Report

### Default mode

```
## Migrate-todo audit — {scope path}

Compliant (skipped): {N}
  ✓ todo/{file}                  (source: {x}, status: {y})
  ...

Partial frontmatter: {N}
  ⚠ todo/{file}                  missing: {keys}

No frontmatter: {N}
  ⚠ todo/{file}                  legacy

Malformed: {N}
  ✗ todo/{file}                  {reason}

Looks like non-todo: {N}
  ? todo/{file}                  reference-doc shape — confirm to migrate

Compliant complete (retroactive _done/ move available): {N}
  • todo/{file}

Run with --fix for interactive remediation, --auto-fix for batch (status:
still asked per file), or --quick to check frontmatter without moving
files.
```

### --fix / --auto-fix modes

Per-file outcome lines as the skill works:

```
✓ todo/{file}                  already compliant
+ todo/{file}                  filled missing source: scratch
+ todo/{file}                  filled missing created: 2026-04-25
+ todo/{file}                  set status: complete (user-provided)
→ todo/{file}                  moved to todo/_done/{file}
✗ todo/{file}                  collision in _done/, skipped
- todo/{file}                  user declined migration
```

Final summary at the end:

```
## Migrate-todo summary

  {N} files scanned
  {N} skipped (compliant)
  {N} normalised (frontmatter)
  {N} moved to _done/
  {N} skipped (declined or collision)
  {N} halted (malformed)
```

### Commit suggestion

After non-trivial changes (any normalisation or move), suggest a commit
without auto-running it:

```bash
git status --short
git add todo/
git commit -m "chore: migrate-todo — {N} normalised, {N} moved to _done/"
```

User confirms before commit. Mirrors the workflow's "no surprise commits"
discipline.

## Idempotency

Re-running on already-compliant files is a no-op. The classification
phase is read-only; the only writes happen inside `--fix` / `--auto-fix`
when a file is non-compliant.

Specifically:

- A file that's already compliant emits `✓ compliant` and nothing else.
- A file already in `todo/_done/` is excluded from scope by the glob.
- The move-to-`_done/` action checks the destination doesn't exist
  before moving; never overwrites.
- Re-running the same `--auto-fix` produces zero diffs the second time.

## What this skill does NOT do

- **Synthesise OpenSpec archive entries** for legacy completed work.
  The archive directory's value is "proposal that was implemented and
  validated"; backfilling fabricates a paper trail. If you want formal
  retroactive coverage, invoke `/spwf:spec` manually on the now-normalised
  todo file.
- **Rename files** to slug conventions. Rename collisions are too
  case-by-case for the value gained. A future `--rename` flag could be
  added if usage demands it.
- **Merge legacy todos into existing active OpenSpec changes.** That's
  manual work — the migration just normalises and (optionally) moves.
- **Validate the `status:` vocabulary.** Real values include `ideation`,
  `analysis`, `challenged`, `split`, `complete`, `in-progress`. All
  non-`complete` values are treated as "active, skip-the-move". Vocabulary
  policing belongs in `workflow-lint` if anywhere.
- **Repair malformed YAML.** If parsing fails, halt for that file and
  let the user fix it manually. Auto-repair risks corrupting the file's
  intent.

## Constraints

- Never overwrite an existing `todo/_done/` file.
- Never auto-infer `status:` — always interactive.
- Never operate on files inside `todo/_done/` or any subdirectory.
- Never operate on non-`.md` files in scope.
- Never bypass the `todo-frontmatter-check.sh` hook (it fires non-blocking
  warnings during normalisation; expected and harmless).
- Never auto-commit. Suggest a commit at the end; user runs it.
