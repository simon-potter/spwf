# Proposal: Add `/spwf:understand` — a post-ship comprehension step

**Change ID**: `add-understand-skill`
**Status**: Draft
**Created**: 2026-07-28
**Source**: [todo/Learn-my-code.md](../../../todo/Learn-my-code.md)

---

## Why

The workflow ships changes but never establishes that the *developer*
understands them. `recap` (Retrospective Part 5) explains a change, but reading
a good explanation produces the feeling of understanding rather than the fact of
it — the gap now named **comprehension debt**. The supporting evidence is
direct: developers using AI for code-generation delegation score below 40% on
comprehension tests, while those using it for conceptual inquiry score above
65%. The difference is whether an act of active engagement happened.

The concrete cost is diagnostic, not moral: when a change an agent wrote
misbehaves months later, the developer has no instinct for where to look. This
change adds the active-engagement half — an interview that converts a summary
you read into a map you hold.

## What Changes

- **NEW** `plugins/spwf/skills/understand/SKILL.md` — post-ship comprehension
  interview. Structure-anchored (new modules, dependencies, interfaces, data
  flow), one question at a time, at orientation depth rather than
  implementation depth. Produces an orientation note and updates a learner
  ledger.
- **NEW** `plugins/spwf/skills/_shared/learner-profile.md` — convention doc for
  `.spwf/learner.md` (level + Known/Open concept ledger), mirroring the
  `_shared/project-priorities.md` shared-module pattern.
- **MODIFIED** `plugins/spwf/skills/retrospective/SKILL.md` — new Part 6
  invoking `understand`; `changelog` renumbered Part 6 → Part 7.
- **MODIFIED** `plugins/spwf/skills/close/SKILL.md` — Step 2 and the frontmatter
  description enumerate the retrospective parts; six → seven.
- **MODIFIED** `plugins/spwf/skills/changelog/SKILL.md` — **pre-existing bug.**
  Its description claims it is called "as Part 5"; it has been Part 6 since
  `recap` took that slot. Corrected to Part 7.
- **MODIFIED** `.gitignore` — add `.spwf/learner.md` (personal, not
  team-shared).
- **MODIFIED** `README.md`, `plugins/spwf/README.md` — skill tables, Close rows,
  `changelog` part number, and the existing "Learning modes" subsection, which
  currently names `recap` as *the* post-hoc complement.
- **MODIFIED** `plugins/spwf/.claude-plugin/plugin.json` — 1.19.0 → 1.20.0.

**Explicitly not changed:** `simplify`, `pr-create`, `recap`. A pre-merge
`--gate` mode touching the first two was designed and cut (see design.md).

## Impact

- **Affected areas**: `plugins/spwf/skills/` (one new skill, one new shared
  module, three modified skills), both READMEs, `.gitignore`, plugin manifest.
- **No breaking changes.** Additive. The retrospective renumber is internal to
  SPWF's own documentation; no external consumer references part numbers.
- **New runtime artefact**: `.spwf/learner.md`, created on first run, gitignored.
- **No new agents, dependencies, or external services.** The interview runs in
  the main session — a subagent would break one-question-at-a-time interaction.

---

## Decisions

All questions from the ideation file are resolved; none carried as TBD. The
decisions that shaped the design are recorded in `design.md`. Three residual
risks are carried forward explicitly rather than resolved:

- **Not conventionally testable** (high confidence). An interview has no
  deterministic output. Verification is structural (frontmatter, cross-refs,
  `workflow-lint`) plus dogfooding; there is no behavioural assertion to write.
- **Success unmeasurable at run time** (high confidence). "Instinct in six
  months" cannot be observed now. The proxy — whether the orientation note's
  "Where to look when things go wrong" section comes out substantive or empty —
  is weak but is all that exists.
- **Part 6 may be declined every time** (medium). Mitigated by a `[Y/n]`
  default-yes prompt carrying a change-specific reason. If still skipped after
  ~5 changes, cut the hook and keep standalone only.

## Success Criteria

1. `/spwf:understand` runs standalone against an active or archived change and
   produces an orientation note whose "Where to look when things go wrong"
   section is substantive.
2. Retrospective Part 6 offers the interview with a change-specific prompt and
   `[Y/n]` default-yes; declining is silent and noted in the report.
3. `.spwf/learner.md` is created on first run, gitignored, and accumulates
   Known/Open concepts across runs.
4. No question in a real run is answerable only by someone who typed the code,
   and none re-asks what `recap` explained in Part 5.
5. `openspec validate --strict` and `workflow-lint` both pass; the new skill is
   not flagged as orphaned.
