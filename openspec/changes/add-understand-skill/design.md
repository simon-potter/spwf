# Design: `add-understand-skill`

Technical decisions and rejected alternatives. Sourced from
[`todo/Learn-my-code.md`](../../../todo/Learn-my-code.md) and its
`/spwf:challenge` pass.

---

## The goal that constrains everything else

**When something breaks in six months, the developer has an instinct for where
to look and why.** Navigational understanding, not accountability, and
explicitly not hand-coded-level fidelity. Several decisions below exist only
because this sentence was pinned down; earlier drafts optimised for a different
goal and produced a materially different skill.

---

## Decision 1 — Socratic interview, not a quiz

**Chosen:** open questions, one at a time, ungraded, plain conversational text.

**Rejected:** multiple-choice quiz with a score (the `check-understanding`
model).

Three reasons, in order of force:

1. **An MCQ over a recap you just read tests recognition, not understanding.**
   The answer sits in the text above. This is precisely the fluency illusion the
   skill exists to defeat — a scored format would *certify* the problem.
2. **The examiner wrote the code.** The agent generated the change, wrote the
   recap, sets the questions and marks them. A scored format makes that conflict
   of interest load-bearing.
3. **Consistency.** `challenge` is already a one-question-at-a-time Socratic
   interview. Two skills, same idiom, opposite ends of the golden path.

The MCQ format is not discarded outright — it is re-homed to a deferred
`--recall` mode for spaced retention checks over past changes, where there is no
diff to be accountable for and gradability is appropriate.

## Decision 2 — No `AskUserQuestion` in `allowed-tools`

Direct consequence of Decision 1. `AskUserQuestion` is structurally
multiple-choice (2–4 options), so using it would reintroduce the MCQ format
under a different name. `challenge` faces the identical problem and resolves it
the same way — `allowed-tools: [Read, Write, Grep, Glob, Bash]`, questions asked
as plain text.

## Decision 3 — The pre-merge `--gate` mode is cut

**Chosen:** one hook, at Retrospective Part 6. `simplify` and `pr-create`
untouched.

**Rejected, in order:**

- **`pr-create` pre-flight.** It declares `allowed-tools: [Read, Bash]` (cannot
  write an artefact), every step is a mechanical pass/halt check, and it sets an
  explicit precedent against exactly this: *"Do not invoke `/spwf:close`
  automatically. pr-create points forward only."* The house pattern for an
  interactive skill near a phase is a next-step pointer, not an inline call.
- **`simplify` Pass 3.** A much better structural fit — `simplify` already pins
  `BASE_SHA..HEAD_SHA` after its Pass 1 commit and already short-circuits
  trivial diffs.
- **Cut entirely** — chosen once the goal was restated. The gate's whole
  justification was *actionability*: find the gap while it is still fixable.
  Under a navigational goal nothing needs fixing, so the justification
  evaporated. Shipping one well-placed hook beats two competing opt-in prompts
  for the same skill.

## Decision 4 — Structure-anchored, not design-anchored or line-anchored

**Chosen:** questions derived from the *shape* of what changed — new modules,
new dependencies, changed interfaces, altered data flow, newly-wired
connections.

**Rejected:**

- **Design-anchored** (questions from `design.md` decisions). The gap being
  closed is *what the agent decided on its own* — and those decisions by
  definition are not in `design.md`, because nobody wrote them there. A
  design-anchored interview probes decisions the developer already made
  themselves, which are the ones they already understand.
- **Line-anchored** (the `do-i-understand` model: verbatim snippets, re-derived
  line numbers, region-by-region interrogation). Correct for pre-merge
  accountability; wrong fidelity for navigation. Ruled out explicitly: *"it
  doesn't need to be line for line perfect… not variable name level gotchas."*

**Consequence:** the skill reads `git diff --stat` plus selective reads of the
significant changed files, not the full diff. This also disposes of the
large-diff edge case for free — reading every line would be gathering fidelity
the interview has already decided not to use.

## Decision 5 — The artefact is an orientation map, not an attestation

Earlier drafts borrowed `do-i-understand`'s "Author's understanding" block:
verbatim quoting, evidence ladder, a "Ready to merge" verdict. That artefact
exists so a *reviewer* can distinguish the author's words from an AI's. There is
no reviewer here — the audience is future-you — so verbatim quoting and the
merge verdict both drop.

"Where to look when things go wrong" is the section carrying the purpose. If an
interview produces nothing for it, the interview failed regardless of how the
other questions went.

## Decision 6 — Part 5 / Part 6 division of labour is an enforced rule

Surfaced by the premortem. Running an interview 90 seconds after `recap`
explained the same change is lecture-then-test: the developer answers from
short-term memory and learns nothing. This is the same recognition-not-recall
failure used to reject the MCQ format in Decision 1, and it is the single
biggest risk in the design.

| | `recap` (Part 5) | `understand` (Part 6) |
|---|---|---|
| Covers | **what** changed and **why** | **consequence** and **navigation** |
| Answers | "what did this do?" | "where do I look when it breaks?" |
| Mode | prints, you read | asks, you answer |

`recap` never answers "where would you look", so Part 6 has genuine uncovered
material. The rule — *do not re-ask what `recap` just explained* — belongs in
SKILL.md as a non-negotiable, not as an aspiration.

The corollary is stated openly in the skill: **standalone-later is the stronger
mode.** Spaced retrieval outperforms immediate retrieval; the close hook exists
so the option is visible while the change is on the developer's mind, not
because close is pedagogically optimal.

## Decision 7 — Learner profile at `.spwf/learner.md`, project-scoped, gitignored

**Chosen:** the plugin owns the convention
(`_shared/learner-profile.md`, mirroring `_shared/project-priorities.md`); the
data file lives in the target project beside `priorities.md` and `tracker.yaml`,
so it survives `/plugin update`.

**Gitignored**, unlike `priorities.md`. That file is a team-shared statement of
intent; this one is personal. A committed record of an individual's
comprehension gaps is a liability in any shared repo.

**Known trade-off:** project-scoped *and* gitignored is the safest combination
and the least durable — a fresh clone starts empty and re-asks the calibration
question. Accepted. The escape hatch, if it bites, is a "level global, gaps
per-project" split.

**Level calibration governs explanation depth, never rigour.** `new` gets more
scaffolding, `fluent` gets terser framing — nobody gets easier questions. If
level lowered the bar the check would be theatre and the ledger a record of
flattery. This rule ships verbatim in SKILL.md.

**Scheduled review.** The ledger is the one component additive to the stated
goal rather than required by it, and the most likely thing here to rot. Review
after ~5 real runs; cut if "which areas do I keep not understanding" is not
information actually used. The skill works without it, calibrating within a
session from how the developer answers.

## Decision 8 — `recap` survives as a separate skill

**Rejected:** merging both into one explain-then-verify skill. `recap` is cheap,
passive and savable as a document; there are many changes where the summary is
all that is wanted, and it stays default-on at close. `understand` reads
`recap`'s output as context when present but does not hard-depend on it —
standalone runs against archived changes have no recap in session.

---

## Testability

**This change cannot be verified by conventional behavioural tests, and the task
list reflects that.** An interview has no deterministic output; there is no
assertion to write about a conversation. Three verification layers substitute:

1. **Structural assertions** (greppable, and what most tasks assert): frontmatter
   fields, absence of `AskUserQuestion`, presence of each non-negotiable rule,
   cross-reference validity, part-number consistency across the four files that
   enumerate retrospective parts.
2. **`workflow-lint`** — the repo's existing tool for exactly this class of
   check: step↔skill coverage, orphaned skills, stale names, diagram↔table
   consistency.
3. **Dogfooding** — running the skill against a real change on this repo. This
   is the only verification of the interview *quality*, and it is subjective.

Task 5.1 is therefore a manual dogfood step with a judgement-based pass
condition, not an automated assertion. This is a genuine property of the work,
not a gap in planning.
