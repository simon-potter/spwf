# PR review cycle bookends — May 2026 (mid-month)

This handover documents the integration of two
[obra/superpowers](https://github.com/obra/superpowers) skills —
`requesting-code-review` and `receiving-code-review` — into the SPWorkflow
PR phase. It closes two long-standing gaps in the cycle (no pre-PR self-pass,
no defined response loop for review reports) and establishes a reusable
pattern for adapting external MIT-licensed skills into spwf.

The session moves spwf from `1.11.0` to `1.12.0` and spwf-agents from
`1.2.0` to `1.3.0`. One commit lands the substantive work.

| Commit | What |
|---|---|
| `cf33f1a` | Pre-PR self-review folded into `/spwf:simplify` (Pass 2) + new `/spwf:address-review` skill + dual-mode `reviewer` agent + `list_comments(ref)` forge op |

---

## 1. The gap on both sides of the PR phase

**Request.** *"For our PR review phase, I want to incorporate
[requesting-code-review](https://www.skills.sh/obra/superpowers/requesting-code-review)
and [receiving-code-review](https://www.skills.sh/obra/superpowers/receiving-code-review),
please look at our workflow steps, and how/where to incorporate them."*

**Problem.** The PR phase had unattended bookends.

- *Before* `pr-create`, nothing checked correctness / security / contract
  drift on the local branch. The first time anyone thought hard about the
  diff was when the human reviewer opened the PR — by which point amend
  was no longer cheap and a back-and-forth review cycle had started.
- *After* `pr-review` produced a report, nothing defined how to act on it.
  Items sat in `{branch}-review.md` with no convention for triage,
  implementation, or push-back. The same gap existed when a human
  reviewer left comments on the open PR/MR — no skill for "I just got
  feedback, now what."

The obra/superpowers skills exist for exactly these two postures:
"requesting" is about catching issues before they cascade; "receiving"
is about evaluating feedback technically rather than performatively.
Both are MIT-licensed and re-usable.

**Initial proposal (two new skills).** First pass added a standalone
`/spwf:self-review` skill at Phase 4.5 (pre-PR) and `/spwf:address-review`
at Phase 6.5 (post-review). User pushback: *"It feels like self-review
should be merged with simplify; address-review is correct."* The merged
shape is what shipped — `simplify` runs the reviewer dispatch as Pass 2
of the same skill that already touches the diff.

**What shipped.**

- **`plugins/spwf/skills/simplify/SKILL.md`** restructured as a two-pass step:
  - *Pass 1 (mechanical, unchanged behaviour)* — the original
    [addyosmani](https://github.com/addyosmani/agent-skills) cleanup pass:
    dead code, debug prints, unused imports, commented-out blocks.
    Test files excluded. Safe edits applied directly, judgment calls
    flagged. Pass 1 commits its own changes if any.
  - *Pass 2 (judgment, new)* — after the Pass 1 commit (if any), pins
    `{BASE_SHA}..{HEAD_SHA}` so the report is unambiguously tied to a
    snapshot. Gathers `openspec/changes/*/proposal.md`, `tasks.md`, and
    `design.md` as the intent baseline. Dispatches the `reviewer` agent
    via the `Task` tool with `subagent_type=reviewer` and an explicit
    `Mode: local-diff` marker in the prompt. Severity vocabulary is
    Critical / Important / Minor; the agent is told what *not* to flag
    (formatting, style, mechanical items already done in Pass 1,
    speculative refactors, "what about X?" hypotheticals).
  - *Triviality short-circuit* — Pass 2 is skipped when `additions +
    deletions < 10` AND `files ≤ 2`. Burning a subagent on a typo fix
    is waste.
  - *Combined verdict line* recommends one of three next steps based on
    the Pass 2 count: address-review for Critical, optional
    address-review for Important-only, or proceed straight to
    `pr-create`.

- **`plugins/spwf/skills/address-review/SKILL.md`** — new skill at
  Phase 6.5. Two-source feedback ingestion:
  - *Path A — local report file*. Reads `{branch}-review.md` or
    `{branch}-self-review.md` (from `/spwf:pr-review` or
    `/spwf:simplify` Pass 2 respectively).
  - *Path B — fetched PR/MR comments*. Dispatches `list_comments(ref)`
    via the forge-dispatch shared reference. GitLab is one call
    (`glab mr view --comments`); GitHub needs the supplementary
    `gh api repos/{owner}/{repo}/pulls/{ref}/comments` because review-
    thread line comments aren't always in `gh pr view --comments`
    output.
  - *Per-item loop is enforced*: **READ → UNDERSTAND → VERIFY →
    EVALUATE → ACT**. VERIFY is the load-bearing step — the reviewer's
    premise is checked against codebase reality (file:line still
    exists, test pinning current behaviour, design decision recorded)
    before any edit happens.
  - *Four buckets per item*: Implement / Push back / Clarify / Defer.
    The bucket determines the action. Clarifications block their own
    item but not the queue.
  - *Forbidden phrases* are listed in the SKILL.md as a non-negotiable
    posture rule: "You're absolutely right!", "Great point!", "Excellent
    feedback!", "Let me implement that now" (said before VERIFY).
    Acknowledgment is through action — a one-line description of the
    fix or push-back, not gratitude.
  - *One consolidated reply per thread*, never per item. Spraying
    "Done!", "Fixed!", "Yes!" replies on a forge thread is a known
    failure mode for AI-driven review responses.
  - *Push-back format is structured* (Premise / Reality / Therefore)
    with citations to file:line, tests, or design docs. No
    "respectfully", no hedging.

- **`plugins/spwf-agents/agents/reviewer.md`** — gained dual-mode dispatch.
  - *Forge mode* (unchanged): caller passes a PR/MR number or URL,
    agent calls `gh pr view`/`glab mr view`, writes `{branch}-review.md`.
  - *Local-diff mode* (new): caller passes `Mode: local-diff` plus
    pinned `{BASE_SHA}..{HEAD_SHA}` plus the openspec context inline
    in the prompt. Agent reads `git diff` instead of fetching a forge
    PR, writes `{branch}-self-review.md`. The agent halts rather than
    guessing if SHAs are missing — the *caller* must supply them.
  - *Verdict vocabulary differs by mode*: forge mode uses
    `✅ Approve | 🔄 Request changes | 💬 Comment`; local-diff uses
    `✅ Ready for PR | 🔄 Fix Critical/Important before PR | 💬 Minor only`.

- **`plugins/spwf/skills/_shared/forge-dispatch.md`** — added
  `list_comments(ref)` as a documented operation alongside view / diff /
  create_request. Dispatch table updated with the GitHub two-call
  pattern (issue-level comments via `gh pr view --comments` *and*
  review-thread line comments via `gh api .../pulls/{ref}/comments`).
  GitLab is one call.

**Architectural patterns to copy.**

- *Adapt external MIT-licensed skills by concept, not by copy.* The
  obra/superpowers SKILL.md content is not reproduced verbatim in
  spwf — the *concepts* (severity tiers, the READ → VERIFY → EVALUATE
  loop, the forbidden-phrase list) are re-cast into our own prose
  tied to *this* codebase's conventions (openspec context,
  forge-dispatch, reviewer subagent). This is below the substantial-
  portion threshold of MIT, but the licence + copyright + authors
  are preserved in five places anyway (SKILL.md frontmatter,
  SKILL.md body link, plugin README attribution table, top README
  workflow paragraph). When you can adapt rather than vendor,
  attribution is lighter and the result fits your conventions
  natively.
- *Fold-or-add is a real design decision.* The first pass added
  `/spwf:self-review` as Phase 4.5. The user pushed back: the pre-PR
  review naturally pairs with the diff-touching `simplify` pass, and
  adding a separate skill bloats the command surface for the same
  cognitive moment. Folding the *requesting* side into an existing
  skill kept the workflow at one extra command, not two. The
  *receiving* side stayed separate because its posture is distinct
  (verify-before-implement is a deliberate, slow loop; mixing it
  into another skill dilutes both). Rule of thumb: fold when two
  steps touch the same artifact at the same point in the workflow;
  separate when the posture is different.
- *Subagent dispatch with explicit mode markers.* The reviewer agent's
  dual-mode is driven by an explicit string in the caller's prompt
  (`Mode: local-diff`) plus pinned SHAs supplied by the caller. The
  agent does not infer mode from absence of arguments — it halts
  rather than guess. This is the same fail-fast contract used for
  tracker and forge dispatch.
- *Pinned commit SHAs for asynchronous review artefacts.* Reports
  produced now and consumed later (by a human, by another skill, by
  the same skill on a re-run) must reference *immutable* SHAs, not
  branch tips. Branch tips move under rebase; SHAs don't. The
  reviewer agent embeds `{BASE_SHA}..{HEAD_SHA}` in the report header
  so a later consumer can detect mismatch and regenerate.
- *Triviality short-circuit on subagent dispatch.* Burning a Haiku
  subagent on a diff that's smaller than a single screen is waste.
  The `< 10 lines AND ≤ 2 files` threshold short-circuits Pass 2 and
  tells the user to proceed. This is a general pattern for any
  optional dispatch: gate it on a cheap-to-compute heuristic.
- *Forbidden-phrase lists are non-negotiable posture rules.* Most of
  the address-review skill is workflow (READ, VERIFY, ACT). The
  forbidden-phrase list is the irreducible behavioural rule that
  separates this from generic "respond to feedback" prompts. When
  porting external behavioural skills, preserve their non-negotiable
  posture rules verbatim — that's where the value lives.
- *One consolidated reply per thread.* Forge threads with many short
  AI replies become unreadable. The skill enforces one structured
  reply per thread regardless of how many items were addressed.
  This is a general pattern for any AI-driven response loop on
  shared communication channels.

**How to adopt (for sibling workflow plugins).**

If you have a similar build → review → ship cycle and want the same
bookends:

1. *Pre-PR self-review.* Find your existing pre-PR cleanup step (in
   spwf it's `simplify`). Add a second pass that pins commit SHAs,
   gathers spec context, and dispatches a code-review subagent
   against the local diff. Use a triviality short-circuit. Don't add
   a separate command for it — fold into the cleanup step.
2. *Receiving review feedback.* Add a new skill (separate, not
   folded) that ingests feedback from either a local report file or
   fetched forge comments. Enforce a READ → VERIFY → EVALUATE → ACT
   loop. Define your forbidden-phrase list explicitly. Bucket items
   into Implement / Push back / Clarify / Defer. One reply per
   thread, not per item.
3. *Dual-mode review agent.* If you have a forge-PR review agent,
   extend it with a local-diff mode driven by an explicit prompt
   marker. The agent halts rather than infers mode. Output filenames
   differ by mode so the artefacts don't collide.
4. *Attribution.* If you're adapting external skills: name the
   source, name the licence, name the authors, state explicitly
   whether content is verbatim or adapted. Put attribution in the
   SKILL.md frontmatter (machine-readable), SKILL.md body
   (human-readable), and the plugin README attribution table
   (catalog-level). Three places, not one.

---

## Versions and pointers

| Plugin | Before | After |
|---|---|---|
| `spwf` | `1.11.0` | `1.12.0` |
| `spwf-agents` | `1.2.0` | `1.3.0` |

| Concern | Where to look |
|---|---|
| Two-pass simplify | `plugins/spwf/skills/simplify/SKILL.md` |
| Address review skill | `plugins/spwf/skills/address-review/SKILL.md` |
| Dual-mode reviewer agent | `plugins/spwf-agents/agents/reviewer.md` |
| `list_comments(ref)` op | `plugins/spwf/skills/_shared/forge-dispatch.md` |
| Workflow diagram + golden path | `README.md` lines 7–28 |
| Attribution tables | `plugins/spwf/README.md` (bottom) |

| External reference | URL |
|---|---|
| obra/superpowers — requesting-code-review | https://www.skills.sh/obra/superpowers/requesting-code-review |
| obra/superpowers — receiving-code-review | https://www.skills.sh/obra/superpowers/receiving-code-review |
| obra/superpowers repository (MIT) | https://github.com/obra/superpowers |
