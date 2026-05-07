---
# Source: https://github.com/addyosmani/agent-skills — MIT licence
name: simplify
description: Phase 6 — Simplify. Review files changed on the current branch for dead code, unclear names, and unnecessary complexity. Apply safe unambiguous removals directly; flag judgment calls without touching them. Never touches test files.
disable-model-invocation: true
allowed-tools: [Read, Edit, Grep, Glob, Bash]
---

# simplify

Review changed files for unnecessary complexity. Apply safe, unambiguous simplifications. Flag anything that requires judgment. Never touch test files.

## Step 1: Find changed files

```bash
git diff --name-only main...HEAD
```

Exclude test files (any file matching `*.test.*`, `*_test.*`, `tests/`, `__tests__/`, `spec/`).

If no files remain after exclusion, report "No non-test files changed."

## Step 2: Review each file

Read each file. Look for:

### Apply directly — unambiguously correct removals

- Commented-out code blocks (code in comments, not documentation)
- Debug statements: `print(`, `console.log(`, `debugger`, `pprint(`
- Unused imports (only when certain — a symbol that appears nowhere else in the file)
- Duplicate blank lines (more than two consecutive blank lines)

### Flag without changing — requires judgment

- Unclear variable names — suggest a rename but do not apply
- Functions doing more than one thing — flag for splitting
- Magic numbers or strings — suggest named constants
- Deeply nested conditions (> 3 levels) — flag for flattening
- Dead function or class — one that appears to be unreachable (flag, don't delete)

## Step 3: Apply safe changes

Use the Edit tool for each safe removal identified in Step 2.

Make each edit minimal — remove the exact line or block, nothing more.

## Step 4: Produce the simplify report

```markdown
## Simplify Report

### Applied

- {file}:{line range}: {what was removed}

### Flagged (judgment needed)

- {file}:{line}: {issue} — {suggested fix}

### Clean

- {file}: No changes needed
```

If nothing was applied and nothing was flagged:

```
No simplification opportunities found in changed files.
```

## Step 5: Commit

If any changes were applied in Step 3, show `git diff --stat` and propose a commit:

```
refactor: simplify {change-id} — {brief description of what was removed}

{list the most significant removals — one line each}
{if any judgment-call flag is worth noting in git history: "flagged {X} in {file} for human review"}
{if a removal revealed something unexpected: note it here}
```

Ask: "Ready to commit? Confirm with 'yes' or edit the message first."

After confirming:

```bash
git add {changed files}
git commit -m "{confirmed message}"
```

If nothing was applied (report showed only flags), skip the commit: "Nothing to commit — no changes were applied."
