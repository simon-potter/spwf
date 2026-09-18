# Recap: `add-understand-skill`

_Retrospective Part 5, 2026-09-18._

## What changed

`/spwf:understand` now runs as Retrospective Part 6 — an interview that asks *you*
about a change you just shipped, rather than explaining it to you again. It picks
3–4 structure-anchored topics, explains each one before asking anything, checks
the explanation landed, and on uncertainty explains again by a different route. It
closes with a navigation question and writes an orientation note into the change.

Supporting it: `_shared/learner-profile.md`, a new shared convention backed by a
gitignored `.spwf/learner.md`, and a redaction step so quoted source never reaches
a committed artefact. `retrospective` grew from five parts to seven.

## Concepts touched

**Comprehension debt** — the gap between the *feeling* of understanding produced
by reading a good explanation and the *fact* of it. The proposal cites the split
directly: developers using AI for code-generation delegation score below 40% on
comprehension tests; those using it for conceptual inquiry score above 65%. The
difference is whether active engagement happened. `recap` produces the feeling;
this change adds the other half.

**Personal state outside the repo** — `.spwf/learner.md` is the first thing SPWF
keeps per-person rather than per-team, and it is gitignored on purpose: a
committed record of an individual's comprehension gaps reads as a
performance-review artefact nobody consented to.

## Decisions

Nine recorded in `design.md`. The load-bearing ones:

| # | Decision |
|---|---|
| 9 | Teach first; uncertainty triggers teaching, never a recorded gap — inverts the source skill it was adapted from |
| 2 | No `AskUserQuestion` in `allowed-tools` — that tool is structurally multiple-choice, and this is not a quiz |
| 3 | The pre-merge `--gate` mode was cut |
| 7 | Learner profile at `.spwf/learner.md` — project-scoped, gitignored |
| 8 | `recap` survives as a separate skill, with the merge flagged for revisiting |

Level governs explanation depth, never question rigour. Nobody gets easier
questions.

## What surprised us

**The first version failed its dogfood.** It was adapted from `do-i-understand`,
a *pre-merge accountability audit* that correctly refuses to explain — explaining
would launder the very gap the audit exists to expose. That posture was imported
wholesale along with the technique, and produced a session described as
*"difficult and abstract and not great for learning."* The fix took two commits
(`89743f5` spec, `b82dfa7` skill) and a rewrite around teach → check → deepen.

The learning generalises: **you can borrow a skill's technique without its
posture, but only if you notice the posture is there.** That warning now lives in
`understand/SKILL.md` itself, addressed to whoever tries to "improve" it back.

## Read next

[`plugins/spwf/skills/_shared/learner-profile.md`](../../../plugins/spwf/skills/_shared/learner-profile.md)
— it carries a scheduled review after ~5 real runs, and this change was the
first. Since `add-brief-skill` shipped it is also written by two skills rather
than one, and gained a `## Covered` section with a write-permission table.

## Postscript — closing this change

Two items surfaced while closing, both recorded rather than fixed in flight:

- **The `## Known` vocabulary collision.** `add-brief-skill` made `## Covered`
  mean *explained but not demonstrated*; this change's spec still called the
  contents of `## Known` "concepts covered". Fixed in `7554921` before archive,
  because this change archives first and the wording would have become the
  canonical `comprehension` capability definition.
- **`close` runs all seven retrospective parts on the feature branch**, but only
  Parts 1, 5 and 6 need the granular history. Parts 3 and 4 are whole-repo sweeps
  and give wrong answers on a stale branch — Part 4 here reported a missing skill
  that exists on `main`. Design flaw in `close`, not in this change.
