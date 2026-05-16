---
# Adapted from: https://github.com/obra/superpowers — MIT licence, skill `receiving-code-review`.
# Authors: Jesse Vincent and the Prime Radiant team.
# Re-cast for the SPWorkflow as the step AFTER pr-review (or after a human reviewer
# leaves comments on the open PR/MR). No SKILL.md content is reproduced verbatim;
# the READ → UNDERSTAND → VERIFY → EVALUATE → ACT loop, the forbidden-phrase list,
# and the verify-before-implement posture are adapted concepts.
name: address-review
description: Phase 6.5 — Address Review. Turn review feedback into action. Sources feedback from either a local report file (e.g. {branch}-review.md from /spwf:pr-review or {branch}-self-review.md from /spwf:self-review) or fetched human comments on an open PR/MR. For each item runs READ → VERIFY → EVALUATE → implement-or-push-back, in priority order (blocking → important → nit). Forbids performative agreement ("you're absolutely right"). Use after pr-review, or whenever a reviewer leaves comments.
disable-model-invocation: true
allowed-tools: [Read, Edit, Grep, Glob, Bash]
---

# address-review

Turn a review report — or human comments on the open PR/MR — into committed fixes (or reasoned push-backs). This is the receiving side of the review cycle.

Source: [obra/superpowers — `receiving-code-review`](https://www.skills.sh/obra/superpowers/receiving-code-review) — "Code review requires technical evaluation, not emotional performance."

## Posture (non-negotiable)

Review feedback is a hypothesis about the code, not an instruction to obey. Every item gets evaluated against codebase reality before action.

**Required loop, per item:**

1. **READ** the full item without reacting.
2. **UNDERSTAND** — restate the requirement in your own words.
3. **VERIFY** — open the file, grep for the symbol, check the test coverage, read the surrounding context. Is the reviewer's premise actually true here?
4. **EVALUATE** — is this technically sound for *this* codebase? Does it break a working contract? Does it conflict with a decision already recorded in `openspec/changes/*/design.md`?
5. **ACT** — implement, push back with reasoning, or ask for clarification. Pick exactly one.

**Forbidden responses** (these violate the posture and produce slop):

- "You're absolutely right!"
- "Great point!"
- "Excellent feedback!"
- "Let me implement that now" — said before VERIFY/EVALUATE.

Acknowledge through action: a one-line description of the fix or the push-back beats any gratitude expression.

## Step 0: Resolve the feedback source

The skill takes one optional argument; resolution order:

| `$ARGUMENTS` value | Source |
|---|---|
| Empty | Look for `{branch}-review.md` then `{branch}-self-review.md` in the cwd. Halt with usage hint if neither exists. |
| A path ending in `.md` | Read that file as the report. |
| A number, or a `#`/`!`-prefixed ref, or a forge URL | Treat as PR/MR ref; fetch comments via the forge CLI. |

Usage hint on halt:

```
Usage: /spwf:address-review [report.md | <PR/MR number or URL>]

Examples:
  /spwf:address-review                            # auto-pick {branch}-review.md
  /spwf:address-review feature-foo-review.md      # explicit report file
  /spwf:address-review 42                         # fetch comments from PR/MR !42 / #42
  /spwf:address-review https://gitlab.com/org/repo/-/merge_requests/42
```

## Step 1: Load the feedback

### Path A — Report file

```bash
cat "$REPORT"
```

The report follows the `pr-review` / `self-review` shape — pull items out of the **Required Changes**, **Suggestions**, and **Questions** sections.

### Path B — Forge comments

Detect the active forge per `_shared/forge-dispatch.md` (auto-detect from `git remote get-url origin`, or read `.spwf/forge.yaml`).

**Fail fast on missing CLI.** Run `{cli} auth status`. If the required CLI (`glab` for GitLab, `gh` for GitHub) is missing or unauthenticated, halt with:

> *"Forge CLI `{cli}` not installed or not authenticated. Install (`brew install {cli}`) and run `{cli} auth login`. See `plugins/spwf/skills/_shared/forge-dispatch.md`."*

Dispatch the fetch:

```bash
# GitLab (default)
glab mr view "$REF" --comments

# GitHub
gh pr view "$REF" --comments
# Also fetch review-level threads (line comments aren't always in --comments output):
gh api repos/{owner}/{repo}/pulls/{REF}/comments --jq '.[] | {path, line, body, user: .user.login}'
```

Normalise each comment into an item with: `author`, `file` (if line-anchored), `line` (if line-anchored), `body`, `thread_id` (for replies).

## Step 2: Group by severity

Group items into **Blocking**, **Important**, **Nit**, **Question**, using these rules:

- Severity markers in the report (`🔴`, `🟡`, `🟢`, `💡`, `❓`) are authoritative.
- Forge comments don't carry severity — infer:
  - Contains "must", "blocking", "bug", "broken", "security", or marked as "Request changes" review → **Blocking**.
  - Contains "should", "missing tests", "error handling", "edge case" → **Important**.
  - Contains "nit", "minor", "style", "consider", "maybe" → **Nit**.
  - Ends with a question mark and asks for clarification → **Question**.
- When unsure, classify down (Important over Blocking). The skill errs toward fewer false blockers.

Print the grouping summary before processing:

```
Loaded {N} review items from {source}:
  🔴 Blocking:  {N}
  🟡 Important: {N}
  🟢 Nit:       {N}
  ❓ Question:  {N}

Working order: Blocking → Important → Nit. Questions handled inline as they block their parent item.
```

## Step 3: Process each item

Process in priority order: **Blocking first**, then **Important**, then **Nit**. Within a priority, easier fixes (single-file, no public API change) come before complex refactors — this surfaces wins fast and gives test signal on the rest.

For each item:

### 3a. READ + UNDERSTAND

Echo the item verbatim with its origin (file:line if anchored, or section in the report). Then restate the requirement in one line — your own words.

### 3b. VERIFY against codebase

Don't take the reviewer's premise on faith. Use:

- `Read` the named file at the named line.
- `Grep` for the symbol or pattern.
- Check test coverage: is there a test that pins the current behaviour? If you "fix" the code, will that test go red for the right reason?
- Check `openspec/changes/*/design.md` — is the current behaviour an explicit decision?

Record a one-line VERIFY result: "premise holds" / "premise wrong — {why}" / "needs clarification — {what}".

### 3c. EVALUATE

Decide which bucket the item lands in:

| Bucket | When | Action |
|---|---|---|
| **Implement** | Premise holds and fix is technically sound. | Edit code. Run targeted tests. Commit. |
| **Push back** | Premise wrong, fix would break a working contract, conflicts with a recorded design decision, or violates YAGNI ("proper implementation" of an unused feature). | Draft a one-paragraph response with the evidence. Do not edit code. |
| **Clarify** | Premise unclear, scope ambiguous, or you can't reproduce the issue. | Draft a specific question. Do not edit code. **Batch all clarifications into one reply** — partial understanding produces incoherent half-fixes. |
| **Defer** | Valid point, but out of scope for this PR (separate concern, larger refactor, existing-code issue). | Note in a `todo/REVIEW-{slug}.md` for later capture. Do not edit code in this PR. |

### 3d. ACT

**Implement path:**

```bash
# Make the fix using Edit
# Run targeted tests for the touched file(s) — not the full suite
# Stage and commit with a reference to the review item
```

Commit message template — short and concrete:

```
fix(review): {one-line description of what changed}

Addresses: {report path or PR ref}#{item-anchor or line ref}
```

If the item came from a forge thread with an ID, append `Thread: {thread_id}` so the reply (Step 4) can resolve it.

**Push back path:**

Draft the response *now* (do not post yet — collect into the Step 4 reply bundle). Format:

```
On {item-anchor}:
  Premise: {what the reviewer assumed}
  Reality: {what the codebase actually does, with evidence — file:line or test name}
  Therefore: keeping current behaviour because {one-line rationale}.
```

Technical reasoning only. No "respectfully", no "I think", no hedging. Cite tests and design decisions by name.

**Clarify path:**

Draft a specific question. Hold for Step 4 batching.

**Defer path:**

Append an entry to a new or existing `todo/REVIEW-{branch}.md`:

```markdown
- [ ] {one-line item} — from review of {ref}, deferred because {reason}
```

## Step 4: Reply / summarise

After all items are processed, produce one structured response.

### If feedback came from a report file

Update the report with a status column (or append a "Resolution" section):

```markdown
## Resolution — {today's date}

| Severity | Item | Disposition | Commit |
|---|---|---|---|
| 🔴 | {short item} | Implemented | {sha} |
| 🟡 | {short item} | Pushed back | — |
| 🟡 | {short item} | Clarification needed | — |
| 🟢 | {short item} | Deferred to todo/REVIEW-{branch}.md | — |

### Push-backs

{full text of each push-back}

### Clarifications needed

{batched list of questions}
```

### If feedback came from forge comments

Post **one** consolidated reply per thread (don't spray multiple short replies). For each thread, choose one of:

- **Implemented** — `glab mr note create {REF} --message "..."` / `gh pr comment {REF} --body "..."` referencing the commit SHA. One line, factual.
- **Pushed back** — post the technical-reasoning paragraph drafted in Step 3.
- **Clarification needed** — post the specific question.
- **Deferred** — note the disposition and link the follow-up todo.

If the forge supports thread resolution (`gh pr review --comment-id` / `glab` discussion APIs) and the disposition is **Implemented** or **Pushed back with acceptance**, resolve the thread.

### Always finish with a verdict line

```
✓ {N} items processed: {N_implemented} implemented, {N_pushedback} pushed back, {N_clarify} clarifications, {N_deferred} deferred.

Next:
  - {if clarifications pending}: wait for reviewer reply.
  - {if push-backs posted}: wait for reviewer reply.
  - {if all resolved}: re-run /spwf:pr-review {REF} to confirm clean, or proceed to /spwf:close.
```

## Acknowledgment, not gratitude

When a reviewer is right, describe the fix. Don't perform agreement. Compare:

- ❌ "You're absolutely right! Great catch, thank you so much. Let me implement that now."
- ✅ "Fixed in {sha} — replaced the unchecked `find()` with the safer `get_or_404()` per your note on `handlers/user.py:42`."

The second sentence proves you read, verified, and acted. The first proves nothing.

## Gotchas

- **Don't auto-accept "proper implementation" suggestions.** If a reviewer says "you should also add X for completeness", grep the codebase for actual usage of X first. If nothing depends on it, this is a YAGNI violation — push back.
- **Don't fix nits in the same commit as blockers.** Mixing severities makes the commit history unreadable when this PR is later bisected. Group nits into a single trailing `style: address review nits` commit.
- **Don't run the full test suite per item.** Run targeted tests for the file(s) you just touched; reserve the full suite for after all blockers are addressed. This keeps the loop tight.
- **One reply per thread, not per item.** Spraying short replies ("Done!", "Fixed!", "Yes!") makes the thread unreadable. Bundle related items into one structured comment.
- **Clarifications block their item, not the whole queue.** If item #3 needs clarification, skip it and continue with #4–#N. Come back when the reviewer replies. Don't stall the whole loop on one ambiguous comment.
- **Forge comment timestamps lie about freshness.** A "new" comment on an old PR may reference long-merged code. VERIFY the file:line still exists at the current HEAD before treating it as actionable.
- **The reviewer is not always right, but pushing back is expensive.** Reserve push-backs for cases where you have hard evidence (test, design doc, file:line). For weak-but-defensible cases, prefer Clarify over Push back.
