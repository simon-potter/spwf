---
# Source (Pass 1, mechanical simplification): https://github.com/addyosmani/agent-skills — MIT licence.
# Source (Pass 1, DRY/reuse + deslop lenses): https://github.com/brianlovin/agent-config — skills `simplify` and `deslop`. Concepts adapted (rule-of-three DRY, reuse-existing-helper, AI over-engineering patterns: defensive bloat / `as any` / YAGNI, "explicit > compact" restraint).
# Source (Pass 2, pre-PR reviewer dispatch): https://github.com/obra/superpowers — MIT licence, skill `requesting-code-review`. Authors: Jesse Vincent and the Prime Radiant team.
# No SKILL.md content is reproduced verbatim from any source; only concepts (severity tiers, "review early, review often", local-diff dispatch shape, DRY/deslop lenses) are adapted.
name: simplify
description: Phase 4 — Simplify + Self-Review. Two-pass cleanup of the current branch before PR. Pass 1 (mechanical) reviews changed files through three lenses — mechanical removals, DRY/reuse (rule of three; reuse existing helpers), and deslop (AI over-engineering: defensive bloat, `as any`, YAGNI) — applying safe unambiguous changes and flagging judgment calls, with a restraint guardrail (explicit > compact); never touches test files. Pass 2 (judgment) dispatches the `reviewer` subagent in local-diff mode against the pinned commit range to catch correctness, security, missing-test, contract, and reuse/DRY issues while amend is still cheap. Produces a simplify report and a {branch}-self-review.md.
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

Read each file through three lenses. For the reuse lens, also read the shared
util / helper modules adjacent to the change. Apply only unambiguously-safe
changes directly; flag everything that needs judgment.

#### Lens 1 — Mechanical (apply directly)

- Commented-out code blocks (code in comments, not documentation)
- Debug statements: `print(`, `console.log(`, `debugger`, `pprint(`
- Unused imports (only when certain — a symbol that appears nowhere else in the file)
- Duplicate blank lines (more than two consecutive)
- Redundant comments that merely restate the code, or break the file's comment style (deslop)

Clarity smells — **flag, don't apply**: unclear names (suggest a rename),
functions doing more than one thing (flag for splitting), magic numbers/strings
(suggest a named constant), nesting > 3 deep (flag for flattening), dead /
unreachable function or class (flag, don't delete).

#### Lens 2 — DRY / reuse

Remove duplication and reuse what already exists — without manufacturing the
wrong abstraction (see Restraint).

- **Apply directly:** an exact-duplicate block already present verbatim elsewhere in the *same file* that collapses with zero behaviour change.
- **Flag — rule of three:** copy-paste-with-variation appearing **3+ times** — suggest one helper and name where it should live. Two occurrences that may diverge: leave them.
- **Flag — reinvention:** new code that re-implements something the repo already provides. `grep` the adjacent `*/utils`, `*/shared`, `*/lib`, and same-directory modules; if a helper exists, flag "call `{existing}` instead of the new inline copy."
- **Flag — scattered source of truth:** the same constant / type / data shape duplicated across files — suggest a single definition.

#### Lens 3 — Deslop (AI over-engineering)

Agent-written diffs accumulate defensive bloat. Flag these (apply only when the fix is trivial and local):

- Defensive checks or `try`/`catch` abnormal for that area — especially on trusted, already-validated codepaths.
- `as any` / type-escape casts that paper over a real type — fix the type, don't cast.
- Speculative generality — a config flag, parameter, or abstraction layer with a **single caller** and no current use (YAGNI).
- Code or comments whose style is inconsistent with the surrounding file (align if trivial; else flag).

#### Restraint — what NOT to simplify

Simplify for clarity and maintainability, **not line count**. Leave it alone when:

- The change trades an explicit form for a clever/compact one that reads worse — **explicit > compact**.
- Duplication appears only **twice** and the cases may diverge — a little duplication is cheaper than the wrong abstraction; don't abstract yet.
- A helper or abstraction is load-bearing or aids readability even if it looks "extra."

This restraint is what stops the DRY and deslop lenses from over-firing.

### Step 3: Apply safe changes

Use the Edit tool for each safe removal identified in Step 2.

Make each edit minimal — remove the exact line or block, nothing more.

### Step 4: Produce the simplify report

```markdown
## Simplify Report

### Applied

- {file}:{line range}: {what was removed}

### Flagged (judgment needed)

- {file}:{line}: [{clarity | DRY | deslop}] {issue} — {suggested fix}

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
> **Also weigh reuse, DRY, and over-engineering** (Important if they add real maintenance cost, else Minor) — these complement Pass 1's mechanical sweep:
> - **Reuse:** new code re-implementing an existing repo helper — name the helper to call instead.
> - **DRY:** the same logic duplicated 3+ times (rule of three) — name where the single helper should live. (Do NOT flag duplication that appears only twice, or abstractions that would couple unrelated cases — a little duplication beats the wrong abstraction.)
> - **Over-engineering (deslop):** defensive checks / `try`/`catch` on trusted codepaths, `as any` casts papering over a real type, single-caller abstractions or unused config (YAGNI).
>
> **Do not flag**:
> - Formatting / style — linters handle this
> - Existing code outside the diff — out of scope
> - Mechanical cleanup already done in Pass 1 (debug prints, dead imports, commented-out code)
> - Speculative refactors that aren't tied to a concrete duplication or defect
> - "What about X?" hypotheticals without a codebase-grounded example
> - DRY consolidation that would create a premature/forced abstraction (explicit > compact)
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
