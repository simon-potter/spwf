# Tasks: add-understand-skill

> **Authoritative Reference:** [`todo/Learn-my-code.md`](../../../todo/Learn-my-code.md)

> **On testing.** This change is skill and documentation artefacts, not
> executable code. There is no behavioural assertion to write about a
> conversation, so "tests" here are **structural assertions** — greppable checks
> that each artefact declares what the spec requires — plus `workflow-lint` and a
> manual dogfood. See `design.md` § Testability.
>
> **Phase 4 (dogfood) runs before Phase 5 (docs and release) deliberately.** The
> structural assertions in Phases 1–3 can all pass while the interview is
> useless; Phase 4 is the only check on whether it works. Bumping the plugin
> version and rewriting both READMEs before that check would mean publishing a
> version number for a skill still liable to be rewritten.

## Phase 1 — The learner-profile convention

Ordered first: the skill reads this file, so its schema must exist before the
skill references it.

- [x] 1.1 `plugins/spwf/skills/_shared/learner-profile.md` exists and documents
      the `.spwf/learner.md` schema (Level, Known, Open, Recurring blind spots),
      mirroring `_shared/project-priorities.md` in shape and tone
- [x] 1.2 The convention doc states that level governs explanation depth and
      vocabulary only, and never reduces question rigour at any level; and
      records the scheduled review (reassess after ~5 real runs, cut if unused)
- [x] 1.3 `.gitignore` contains `.spwf/learner.md` with a comment explaining why
      it differs from the committed `.spwf/priorities.md`

## Phase 2 — The understand skill

Eight tasks, each a coherent section of one SKILL.md. Detail is carried as
sub-bullets rather than separate checkboxes — the file is written in one
editing session, so eighteen tick-boxes over it would be ceremony, not progress.

- [x] 2.1 **Frontmatter and attribution.** `plugins/spwf/skills/understand/SKILL.md`
      exists with `name: understand`, a description, and
      `disable-model-invocation: true`
      - `allowed-tools` is `[Read, Glob, Grep, Bash, Write, Edit]` — asserts
        `AskUserQuestion` is absent, with the reason stated in the body
      - Attribution header credits AnthonyPAlicea/skills and
        rohitg00/ai-engineering-from-scratch per house style (`challenge`,
        `simplify`)

- [x] 2.2 **Change resolution.** Resolves an empty argument, a change-id, a todo
      path, or a branch / commit range to a change
      - Falls back to `openspec/changes/archive/{change-id}/`
      - Halts naming both searched locations when neither matches, rather than
        interviewing on an unrelated change

- [x] 2.3 **Input reading and triage.** Reads `git diff --stat` and `git log` for
      the change's range, plus selective reads of significant changed files —
      never the full diff
      - Selects 3–5 structural changes to interview on, stating which and why
      - Declines to interview on a trivial change, stating so plainly

- [x] 2.4 **The interview procedure.** Asks one question per message as plain
      conversational text, waiting for an answer before the next
      - Documents question shapes as derivation examples with an explicit "not a
        question bank" statement
      - States the fidelity target and its out-of-range list (null-check
        placement, guard clauses, individual error branches, naming)
      - Carries the rule that it must not re-ask what `recap` explained, with the
        Part 5 / Part 6 division table
      - Treats "I don't know" as a recorded finding with no grade, penalty, or
        re-ask
      - Caps the session at ~8 questions and offers an exit at any point
      - Closes every interview with the navigation question ("if this misbehaves
        in six months, where do you look first?")

- [x] 2.5 **Secret redaction.** Masks credential-shaped values (API keys, tokens,
      passwords, cookies, connection strings, private keys) before they reach a
      question, the orientation note, or `.spwf/learner.md`
      - Surfaces a discovered hard-coded credential as a finding naming the file
        but not the value, not as an interview question
      - Load-bearing: the orientation note is saved to a committed, pushed path

- [x] 2.6 **Output artefact.** Produces the orientation note (shape of change,
      where to look when things go wrong, still fuzzy, concepts touched) with no
      merge verdict
      - Produces a partial note when the interview is abandoned partway rather
        than discarding the session
      - Offers to save to `openspec/changes/{change-id}/understanding.md`

- [x] 2.7 **Ledger creation.** Creates `.spwf/learner.md` on first run with one
      calibration question, never re-asked on later runs; ensures the `.gitignore`
      entry from 1.3 is present

- [x] 2.8 **Ledger update.** Moves demonstrated concepts to `Known` with change-id
      and date after each session, and records unresolved gaps under `Open` with
      what would close them

## Phase 3 — Retrospective integration

Ordered so part numbers stay internally consistent at every step: `changelog`
vacates Part 6 *before* the new Part 6 is inserted, so the file never holds two
Part 6s.

- [x] 3.1 `retrospective/SKILL.md` renumbers `changelog` from Part 6 to Part 7
      throughout — header block, part list, frontmatter description
      ("Six-part" → "Seven-part"), and Report template. Part 6 is left vacant
- [x] 3.2 `changelog/SKILL.md` description corrected from "as Part 5" to Part 7
      (pre-existing bug: stale since `recap` took Part 5)
- [x] 3.3 `retrospective/SKILL.md` gains Part 6 invoking `understand` with the
      change-id passed explicitly, using a `[Y/n]` default-yes prompt that names
      something specific about the change
- [x] 3.4 Declining Part 6 continues to Part 7, notes "Part 6 skipped" in the
      report, and surfaces that `/spwf:understand {change-id}` works later
- [x] 3.5 `close/SKILL.md` reflects seven parts — Step 2's "All six parts run as
      normal" plus its list, and the frontmatter description

## Phase 4 — Dogfood

Judgement-based; the only verification of interview *quality*. Cannot be
automated. Runs before docs and release so a failure here doesn't strand a
published version number.

- [ ] 4.1 Run `/spwf:understand` standalone against a real change in this repo.
      Pass condition: the "Where to look when things go wrong" section is
      substantive, no question was answerable only by whoever typed the code, and
      no question duplicated `recap`. Record the outcome
- [ ] 4.2 Run `/spwf:retrospective` end to end and confirm Part 6 fires with a
      change-specific prompt, and that declining continues cleanly to Part 7
- [ ] 4.3 If either dogfood fails, revise the SKILL.md derivation method (not the
      question list) and re-run before proceeding to Phase 5

## Phase 5 — Documentation and release

- [ ] 5.1 `README.md` — `understand` added to the skill table, Close row updated
      for seven parts, `changelog` row corrected from "Part 6" to "Part 7",
      workflow diagram updated
- [ ] 5.2 `plugins/spwf/README.md` — skill table and Close row updated; the
      "Learning modes" subsection extended, since it currently names `recap` as
      *the* post-hoc complement
- [ ] 5.3 `plugins/spwf/.claude-plugin/plugin.json` bumped 1.19.0 → 1.20.0
- [ ] 5.4 `workflow-lint` passes with no P1 findings and does not flag
      `understand` as orphaned
- [ ] 5.5 `openspec validate add-understand-skill --strict` passes
