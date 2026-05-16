---
# Source (Pass 1, mechanical simplification): https://github.com/addyosmani/agent-skills — MIT licence.
# Source (Pass 2, pre-PR reviewer dispatch): https://github.com/obra/superpowers — MIT licence, skill `requesting-code-review`. Authors: Jesse Vincent and the Prime Radiant team.
# No SKILL.md content is reproduced verbatim from either source; only concepts (severity tiers, "review early, review often", local-diff dispatch shape) are adapted.
name: simplify
description: Phase 4 — Simplify + Self-Review. Two-pass cleanup of the current branch before PR. Pass 1 (mechanical) — review changed files for dead code, unclear names, and unnecessary complexity; apply safe unambiguous removals directly; flag judgment calls without touching them; never touch test files. Pass 2 (judgment) — dispatch the `reviewer` subagent in local-diff mode against the pinned commit range to catch correctness, security, missing-test, and contract issues while amend is still cheap. Produces a simplify report and a {branch}-self-review.md.
disable-model-invocation: true
allowed-tools: [Read, Edit, Grep, Glob, Bash, Task]
---

# simplify

Two passes on the current branch before opening a PR:

1. **Mechanical pass** — review changed files for unnecessary complexity. Apply safe, unambiguous simplifications. Flag anything that requires judgment. Never touch test files.
2. **Judgment pass** — dispatch the `reviewer` subagent against the pinned commit range for a deeper read (correctness, security, missing tests, contract drift). The subagent gets the openspec proposal + tasks as the intent baseline. Adapted from [obra/superpowers — `requesting-code-review`](https://www.skills.sh/obra/superpowers/requesting-code-review) — "review early, review often."

The two passes share the same input (the diff) but answer different questions: the mechanical pass asks "is this clean?", the judgment pass asks "is this right?". Both are pre-PR — by the time a human reviewer sees the request, the diff should already be tight and self-vetted.

## Pass 1 — Mechanical simplification

### Step 1: Find changed files

```bash
git diff --name-only main...HEAD
```

Exclude test files (any file matching `*.test.*`, `*_test.*`, `tests/`, `__tests__/`, `spec/`).

If no files remain after exclusion, report "No non-test files changed." Skip to Pass 2 — there may still be test-only changes worth reviewing.

### Step 2: Review each file

Read each file. Look for:

#### Apply directly — unambiguously correct removals

- Commented-out code blocks (code in comments, not documentation)
- Debug statements: `print(`, `console.log(`, `debugger`, `pprint(`
- Unused imports (only when certain — a symbol that appears nowhere else in the file)
- Duplicate blank lines (more than two consecutive blank lines)

#### Flag without changing — requires judgment

- Unclear variable names — suggest a rename but do not apply
- Functions doing more than one thing — flag for splitting
- Magic numbers or strings — suggest named constants
- Deeply nested conditions (> 3 levels) — flag for flattening
- Dead function or class — one that appears to be unreachable (flag, don't delete)

### Step 3: Apply safe changes

Use the Edit tool for each safe removal identified in Step 2.

Make each edit minimal — remove the exact line or block, nothing more.

### Step 4: Produce the simplify report

```markdown
## Simplify Report

### Applied

- {file}:{line range}: {what was removed}

### Flagged (judgment needed)

- {file}:{line}: {issue} — {suggested fix}

### Clean

- {file}: No changes needed
```

If nothing was applied and nothing was flagged, note "Pass 1: no mechanical simplifications found."

### Step 4a: Frontend follow-up hint (optional, advisory only)

If the changed-file list from Step 1 contains any of `.tsx`, `.jsx`, `.vue`, `.svelte`, `.css`, or `.scss`, append a single advisory line to the simplify report:

```
### Frontend follow-up (optional)

The diff touches frontend files. For design polish / a11y / anti-pattern detection
beyond mechanical cleanup, consider `/impeccable polish` (or `/impeccable audit`,
`/impeccable critique`).

If `impeccable` is not installed:
  /plugin marketplace add pbakaus/impeccable
  /plugin install impeccable@impeccable
```

Do not invoke `/impeccable polish` — it is a separate plugin owned by the user, run on their schedule. This step is informational only. If the diff has no frontend files, omit the section entirely.

### Step 5: Commit Pass 1 if anything was applied

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

If nothing was applied (report showed only flags), skip the commit and continue to Pass 2.

## Pass 2 — Reviewer subagent (judgment pass)

After mechanical cleanup, dispatch the `reviewer` agent in local-diff mode for a deeper read. The point is to catch correctness / security / missing-test / contract issues *now*, while amend is cheap, instead of after the PR is open.

### Step 6: Pin the commit range

The reviewer must see exactly what was reviewed. Capture SHAs after the Pass 1 commit (if any) so the report covers the simplified state.

```bash
BRANCH=$(git branch --show-current)
BASE=${1:-main}

HEAD_SHA=$(git rev-parse HEAD)
BASE_SHA=$(git merge-base "$BASE" HEAD)
RANGE="$BASE_SHA..$HEAD_SHA"

ADDS=$(git diff --shortstat "$RANGE" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)
DELS=$(git diff --shortstat "$RANGE" | grep -oE '[0-9]+ deletion'  | grep -oE '[0-9]+' || echo 0)
FILES=$(git diff --name-only "$RANGE" | wc -l)
```

**Triviality short-circuit**: if `ADDS + DELS < 10` AND `FILES <= 2`, skip the subagent dispatch and report:

```
Pass 2 skipped: diff is trivial (+{ADDS} -{DELS} across {FILES} file(s)).
Proceed to /spwf:pr-create — the human reviewer can eyeball this.
```

### Step 7: Gather context

Read each of these. Note which are absent (do not fabricate):

- `openspec/changes/*/proposal.md` — stated intent
- `openspec/changes/*/tasks.md` — what was supposed to be done
- `openspec/changes/*/design.md` — decisions made
- `git log $RANGE --oneline` — commit summary

If there is no openspec change in flight (hotfix branch, scratch work), record "no openspec change; intent derived from commit messages" and proceed.

### Step 8: Dispatch the reviewer subagent

Use the `Task` tool with `subagent_type=reviewer`. Compose the prompt from this template (fill every `{placeholder}`):

> **Mode: local-diff (pre-PR self-review)**
>
> Review the local branch before PR creation. Do **not** call `glab mr view` or `gh pr view` — there is no open request yet.
>
> **Branch**: `{BRANCH}` → `{BASE}`
> **Commit range**: `{BASE_SHA}..{HEAD_SHA}`
> **Size**: +{ADDS} -{DELS} across {FILES} files
>
> **Stated intent** (from `openspec/changes/{change-id}/proposal.md`, or "no openspec change"):
>
> ```
> {paste proposal summary verbatim, or the "no openspec change" note}
> ```
>
> **Tasks completed** (from `openspec/changes/{change-id}/tasks.md`):
>
> ```
> {paste the task list}
> ```
>
> **How to read the diff**: run `git diff {BASE_SHA}..{HEAD_SHA}` and read the unified output. Also run `git log {BASE_SHA}..{HEAD_SHA} --oneline` for commit-by-commit shape.
>
> **What to flag** (use these exact severities — they are required):
> - 🔴 **Critical** — must fix before opening PR (bugs, security holes, broken contracts, lost data paths)
> - 🟡 **Important** — should fix before opening PR (missing tests, missing error handling, unclear logic at trust boundaries, public API drift not in spec)
> - 🟢 **Minor** — nice to have, can defer (naming, micro-perf, comment quality)
>
> **Do not flag**:
> - Formatting / style — linters handle this
> - Existing code outside the diff — out of scope
> - Mechanical cleanup already done in Pass 1 (debug prints, dead imports, commented-out code)
> - Speculative refactors that aren't tied to a concrete defect
> - "What about X?" hypotheticals without a codebase-grounded example
>
> **Output**: write the report to `{BRANCH}-self-review.md` in the current directory using the standard pr-review report format. Include the pinned SHAs (`{BASE_SHA}..{HEAD_SHA}`) in the header so it's unambiguous what was reviewed. The Verdict line should be one of: `✅ Ready for PR`, `🔄 Fix Critical/Important before PR`, or `💬 Minor only — proceed at discretion`.

### Step 9: Display the combined verdict + recommend next step

After the subagent returns, read `{BRANCH}-self-review.md` and surface:

```
✓ Simplify complete.
  Pass 1 (mechanical): {N_applied} applied, {N_flagged} flagged
  Pass 2 (reviewer):   {N_critical} 🔴 Critical, {N_important} 🟡 Important, {N_minor} 🟢 Minor
  Range: {BASE_SHA}..{HEAD_SHA}  (+{ADDS} -{DELS} / {FILES} files)
  Reports:
    - simplify report (above)
    - {BRANCH}-self-review.md

Verdict: {agent's verdict line}
```

Then recommend (pick one — the conditions are mutually exclusive):

- **If Pass 2 Critical > 0**:
  ```
  Fix Critical findings before /spwf:pr-create.
  Run: /spwf:address-review {BRANCH}-self-review.md
  ```
- **If Pass 2 Critical == 0 and Important > 0**:
  ```
  No blockers. You can proceed to /spwf:pr-create, but consider:
    /spwf:address-review {BRANCH}-self-review.md
  ```
- **If Pass 2 is clean or skipped (trivial)**:
  ```
  Clean. Proceed: /spwf:pr-create
  ```

## Gotchas

- **Pass 1 commit shifts the SHA range for Pass 2.** That's intentional — the reviewer should see the simplified state, not the pre-simplification state. Capture SHAs *after* the Pass 1 commit.
- **Subagent tries to fetch a PR.** The reviewer agent's default path is `glab mr view`/`gh pr view`. The "Mode: local-diff" line and the explicit "do not call" instruction in the prompt are load-bearing — do not omit them. If the subagent returns an error about a missing PR ref, you forgot the mode line.
- **Stale SHAs after rebase.** If the user rebases or amends between simplify and pr-create, the self-review report references SHAs that no longer exist on the branch. The report header makes this detectable. When you spot a mismatch on a re-run, regenerate rather than reuse.
- **No openspec change in flight.** Hotfix or scratch branches will have nothing under `openspec/changes/`. Say so explicitly in the prompt ("no openspec change; intent from commit messages") rather than fabricating a proposal.
- **Large diffs and Haiku.** The reviewer agent runs on Haiku. For very large diffs (e.g. >1500 lines changed) Haiku may miss subtle cross-file issues. Note this in the report header and suggest a manual eyeball pass for hot paths.
- **The reports are not the action.** Pass 1 commits its own changes; Pass 2 only produces a report. Use `/spwf:address-review` to act on Pass 2 findings.
