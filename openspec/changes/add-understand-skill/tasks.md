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

- [x] 2.3 **Input reading and topic selection.** Reads `git diff --stat` and
      `git log` for the change's range, plus selective reads of significant
      changed files — never the full diff
      - Selects **3–4 topics** and announces position ("Topic 2 of 4")
      - Declines to run on a trivial change, stating so plainly
      - *Reopened after dogfood: was "3–5 changes to interview on".*

- [x] 2.4 **The teach → check → deepen cycle.** Replaces the interview
      procedure entirely. *Reopened after dogfood — see design.md Decision 9.*
      - **Explains every topic before asking anything about it.** Explanation is
        mandatory at every level; never opens a topic with a question
      - Check question is answerable from the explanation just given plus
        ordinary reasoning — never requires ungiven information, never a puzzle
      - **Any uncertainty routes back into teaching** by a *different* route than
        the first explanation; never records the gap and moves on
      - Records an item as open only after a second explanation fails
      - States the fidelity target and its out-of-range list (null-check
        placement, guard clauses, individual error branches, naming)
      - Carries the `recap` division of labour: what/why vs consequence/
        navigation, read vs taught
      - Closes with the navigation question, walking through the answer
        explicitly if the developer cannot give it

- [x] 2.5 **Secret redaction.** Masks credential-shaped values (API keys, tokens,
      passwords, cookies, connection strings, private keys) before they reach a
      question, the orientation note, or `.spwf/learner.md`
      - Surfaces a discovered hard-coded credential as a finding naming the file
        but not the value, not as an interview question
      - Load-bearing: the orientation note is saved to a committed, pushed path

- [x] 2.6 **Output artefact.** Produces the orientation note as a record of
      **what the developer now knows** — shape of the change, where to look when
      things go wrong, items still open after two explanations, concepts covered.
      No merge verdict, no score. *Reopened after dogfood: was an inventory of
      gaps.*
      - Produces a partial note when the session is abandoned partway
      - Offers to save to `openspec/changes/{change-id}/understanding.md`

- [x] 2.7 **Ledger creation and level semantics.** Creates `.spwf/learner.md` on
      first run with one calibration question, never re-asked; ensures the
      `.gitignore` entry from 1.3 is present
      - **Level gates explanation depth, not whether explanation happens.**
        *Reopened after dogfood: level previously adjusted question framing only,
        which made the calibration question inert.*

- [x] 2.8 **Ledger update.** Moves covered and confirmed concepts to `Known` with
      change-id and date; records under `Open` **only** items that survived two
      explanations. Announces level promotions rather than making them silently

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

- [x] 4.1 **Run 1 — FAILED (2026-07-29).** Ran standalone against
      `add-understand-skill`. Plugin discovery validated (local marketplace
      resolved the skill from the working tree). Structural criteria passed: the
      "Where to look" section was substantive and surfaced a genuinely new fact
      (`workflow-lint` cannot catch ordinal drift). **But the developer's verdict
      was "difficult and abstract and not great for learning"** — the session
      asked without explaining and treated two "I don't know"s as gaps to record
      rather than moments to teach. Root cause and correction in `design.md`
      Decision 9
- [x] 4.3 **Triggered by 4.1.** Revision is spec-level, not derivation-level:
      `specs/comprehension/spec.md` rewritten (11 requirements, 25 scenarios),
      `design.md` Decision 9 added, `proposal.md` success criteria reordered so
      "the developer reports having learned something" ranks first
- [x] 4.4 Rewrite `understand/SKILL.md` around the teach → check → deepen cycle
      (tasks 2.3, 2.4, 2.6, 2.7, 2.8 reopened)
- [x] 4.5 **Run 2** — re-run `/spwf:understand` standalone against a change the
      developer did *not* co-design (suggest archived
      `2026-06-29-add-branch-enforcement`), so the explanations get a fair test.
      Pass condition now leads with: did the developer learn something
- [ ] 4.6 Run `/spwf:retrospective` end to end and confirm Part 6 fires with a
      change-specific prompt, and that declining continues cleanly to Part 7

## Phase 5 — Documentation and release

- [x] 5.1 `README.md` — `understand` added to the skill table, Close row updated
      for seven parts, `changelog` row corrected from "Part 6" to "Part 7",
      workflow diagram updated
- [x] 5.2 `plugins/spwf/README.md` — skill table and Close row updated; the
      "Learning modes" subsection extended, since it currently names `recap` as
      *the* post-hoc complement
- [x] 5.3 `plugins/spwf/.claude-plugin/plugin.json` bumped 1.19.0 → 1.20.0
- [x] 5.4 `workflow-lint` passes with no P1 findings and does not flag
      `understand` as orphaned
- [x] 5.5 `openspec validate add-understand-skill --strict` passes
