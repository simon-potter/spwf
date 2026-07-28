# Tasks: add-understand-skill

> **Authoritative Reference:** [`todo/Learn-my-code.md`](../../../todo/Learn-my-code.md)

> **On testing.** This change is skill and documentation artefacts, not
> executable code. There is no behavioural assertion to write about a
> conversation, so "tests" here are **structural assertions** — greppable checks
> that each artefact declares what the spec requires — plus `workflow-lint` and a
> final manual dogfood. See `design.md` § Testability. Phases 1–4 are assertable;
> Phase 5 is judgement-based by necessity.

## Phase 1 — The learner-profile convention

Ordered first: the skill reads this file, so its schema must exist before the
skill references it.

- [ ] 1.1 `plugins/spwf/skills/_shared/learner-profile.md` exists and documents
      the `.spwf/learner.md` schema (Level, Known, Open, Recurring blind spots),
      mirroring `_shared/project-priorities.md` in shape and tone
- [ ] 1.2 The convention doc states that level governs explanation depth and
      vocabulary only, and never reduces question rigour at any level
- [ ] 1.3 The convention doc records the scheduled review — reassess after ~5
      real runs, cut if unused
- [ ] 1.4 `.gitignore` contains `.spwf/learner.md` with a comment explaining why
      it differs from the committed `.spwf/priorities.md`

## Phase 2 — The understand skill

- [ ] 2.1 `plugins/spwf/skills/understand/SKILL.md` exists with frontmatter
      declaring `name: understand`, a description, and
      `disable-model-invocation: true`
- [ ] 2.2 `allowed-tools` is `[Read, Glob, Grep, Bash, Write, Edit]` — asserts
      `AskUserQuestion` is absent, with the reason stated in the body
- [ ] 2.3 Attribution header credits AnthonyPAlicea/skills and
      rohitg00/ai-engineering-from-scratch per house style (see `challenge`,
      `simplify`)
- [ ] 2.4 Resolves an empty argument, a change-id, a todo path, or a branch /
      commit range to a change; falls back to `openspec/changes/archive/` and
      halts naming both locations when neither matches
- [ ] 2.5 Reads `git diff --stat` and `git log` for the change's range, plus
      selective reads of significant changed files — never the full diff
- [ ] 2.6 Selects 3–5 structural changes to interview on and states which and why
- [ ] 2.7 Asks one question per message as plain conversational text, waiting
      for an answer before the next
- [ ] 2.8 Documents question shapes as derivation examples with an explicit
      "not a question bank" statement
- [ ] 2.9 States the fidelity target and its out-of-range list (null-check
      placement, guard clauses, individual error branches, naming)
- [ ] 2.10 Carries the rule that it must not re-ask what `recap` explained, with
      the Part 5 / Part 6 division table
- [ ] 2.11 Closes every interview with the navigation question ("if this
      misbehaves in six months, where do you look first?")
- [ ] 2.12 Treats "I don't know" as a recorded finding with no grade, penalty,
      or re-ask
- [ ] 2.13 Caps the session at ~8 questions and offers an exit at any point
- [ ] 2.14 Produces the orientation note (shape of change, where to look when
      things go wrong, still fuzzy, concepts touched) with no merge verdict
- [ ] 2.15 Produces a partial orientation note when the interview is abandoned
      partway rather than discarding the session
- [ ] 2.16 Offers to save to `openspec/changes/{change-id}/understanding.md`
- [ ] 2.17 Creates `.spwf/learner.md` on first run with one calibration
      question, never re-asked; updates Known / Open after each session
- [ ] 2.18 Declines to interview on a trivial change, stating so plainly

## Phase 3 — Retrospective integration

Each task in this phase leaves the part-numbering internally consistent.

- [ ] 3.1 `retrospective/SKILL.md` gains Part 6 invoking `understand` with the
      change-id passed explicitly, using a `[Y/n]` default-yes prompt that names
      something specific about the change
- [ ] 3.2 `retrospective/SKILL.md` renumbers `changelog` from Part 6 to Part 7
      throughout — header block, part list, frontmatter description
      ("Six-part" → "Seven-part"), and Report template
- [ ] 3.3 Declining Part 6 continues to Part 7, notes "Part 6 skipped" in the
      report, and surfaces that `/spwf:understand {change-id}` works later
- [ ] 3.4 `close/SKILL.md` reflects seven parts — Step 2's "All six parts run as
      normal" plus its list, and the frontmatter description
- [ ] 3.5 `changelog/SKILL.md` description corrected from "as Part 5" to Part 7
      (pre-existing bug: stale since `recap` took Part 5)

## Phase 4 — Documentation and release

- [ ] 4.1 `README.md` — `understand` added to the skill table, Close row updated
      for seven parts, `changelog` row corrected from "Part 6" to "Part 7",
      workflow diagram updated
- [ ] 4.2 `plugins/spwf/README.md` — skill table and Close row updated; the
      "Learning modes" subsection extended, since it currently names `recap` as
      *the* post-hoc complement
- [ ] 4.3 `plugins/spwf/.claude-plugin/plugin.json` bumped 1.19.0 → 1.20.0
- [ ] 4.4 `workflow-lint` passes with no P1 findings and does not flag
      `understand` as orphaned
- [ ] 4.5 `openspec validate add-understand-skill --strict` passes

## Phase 5 — Dogfood

Judgement-based; the only verification of interview *quality*. Cannot be
automated.

- [ ] 5.1 Run `/spwf:understand` against a real change in this repo. Pass
      condition: the "Where to look when things go wrong" section is
      substantive, no question was answerable only by whoever typed the code,
      and no question duplicated `recap`. Record the outcome; if it fails,
      the derivation method needs work, not the question list
