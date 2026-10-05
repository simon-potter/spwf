---
source: scratch
tracker: beads
ticket: spwf-uyh
created: 2026-10-05
status: ideation
---

# Enforce ticket state across the SPWF lifecycle

## Context

SPWF writes ticket state but never checks it. Only two points change a
ticket's state: `capture` / `issue-to-task` move it to `start_state`, and
`close` moves it to `done_state`. Nothing in between (spec, build, pr-create,
pause, wfstatus) reads or changes it. As a result the tracker can disagree
with the work, and other agents and people can't rely on it to see what's in
flight.

The problem showed up in this repo's analysis and in a full golden-path run in
a downstream project (YouTrack, FastAPI/Astro). There, `close` moved a ticket
to Done and archived the change with two tasks still unchecked. One of them
("verify the corrected claims are live in production") was genuinely not done.
That's the failure a tracker exists to prevent.

## What we know

**Current gaps** (references are to `main` at 5acf063):

1. **`close` doesn't check the current state.** Step 6 calls `get_issue` only to
   confirm the ticket exists, then `set_state(done_state)`. A ticket that was
   never started, was reopened, or is already closed is handled the same way.
2. **`set_state` isn't read back.** Jira and YouTrack can report success while
   ending in a different state (workflow conditions, a similar-sounding
   transition). Nothing calls `get_issue` afterwards to confirm.
3. **There's no in-review state.** `pr-create` leaves the ticket at In
   Progress until close, so the board can't tell "being built" from "waiting
   on review".
4. **Beads can't record "started".** `spwf-beadsify:tracker-backend` `set_state`
   accepts only states that mean closed, so `start_state: In Progress` always
   fails as a soft note. Beads tickets go straight from open to closed (see
   `docs/beads-dogfood.md` entry 7).
5. **No claim and no compare-and-set.** No assignee is set, so a second agent
   can't tell a ticket is taken. Two agents can overwrite each other's changes.
6. **No order of states.** capture's "already in start_state or later" rule has
   no config behind it; the model guesses what "later" means.
7. **`close` can mark Done with incomplete tasks.** The Step 3 gate never reads
   `tasks.md`. Step 7 runs `openspec archive <id> --yes`, which turns the
   "N incomplete task(s)" warning into a log line and carries on.
8. **`close`'s commits don't survive auto-fixing pre-commit hooks.** If
   detect-secrets, end-of-file-fixer or similar rewrites a file, the commit
   aborts. `openspec archive` writes spec files without a trailing newline, so
   end-of-file-fixer always triggers. A chained `git push` then prints
   "Everything up-to-date", which looks like success though nothing was
   committed.

**Proposed direction** (from the analysis; challenge and enrich should test it):

- **Ordered lifecycle in `.spwf/tracker.yaml`**, e.g.
  `states: [open, in_progress, in_review, done]`, mapped to each tracker's own
  state names. This replaces or extends `start_state` / `done_state`.
- **Two operations in `_shared/tracker-dispatch.md`:**
  - `assert_state(id, expected)` before a phase: halt on a wrong state, report
    the actual state, and offer to fix it;
  - `transition(id, from, to)`: set the state, read it back, and fail on
    mismatch.
- **A check at each phase boundary:**
  - capture: open → in_progress, and claim the ticket;
  - build: still in_progress, and still ours;
  - pr-create: in_progress → in_review;
  - close: check in_review (or in_progress) → done, then verify.
- **A task-disposition gate in `close` Step 3.** Read `tasks.md`; if any task is
  unchecked, print each one and require a disposition: a successor ticket
  (checked with `get_issue`) or an explicit waive. Retrospective Part 2 already
  audits `tasks.md` against what was built. It should produce a structured
  "carried forward" list that the gate reads, so the two steps don't each work
  it out. Don't let `--yes` hide the archive warning.
- **Hook-proof commits in `close` (Steps 5a and 7).** Attempt the commit. If it
  fails and the tree changed, inspect the change, re-stage, and retry once.
  Check with `git log -1` before pushing. Never treat push output as proof that
  a commit happened.
- **Beads backend v2.** `bd update` already supports what's needed:
  - `--claim` sets the assignee and in_progress in one atomic step;
  - `--if-status` / `--if-assignee` only update when the precondition holds
    (exit 13 on mismatch);
  - `-s <status>` sets states other than closed.
- **Drift report in `wfstatus`.** Compare each open todo's phase with its live
  ticket state and flag mismatches.
- **Optional: a PreToolUse hook** that blocks a `set_state` which would move a
  ticket backward.

## Open questions

- **Breaking change or aliases?** Should `states:` replace
  `start_state` / `done_state` (major bump), or keep them as aliases (minor)?
- **Wrong state at a phase boundary:** halt, or offer to fix it and continue?
  Should it differ per phase (capture is a courtesy today; close is
  load-bearing)?
- **Who can waive an unchecked task,** and where is the waiver recorded (todo
  file, tasks.md annotation, tracker comment)?
- **Jira:** transitions are per-workflow and not every state is reachable from
  every other. How does an ordered list map onto that, and what happens when a
  transition isn't available?
- **YouTrack:** do state-field commands need anything beyond a name map?
- **Should state checks live in the skills, in a hook, or both?** Hooks can't
  see phase context; skills can be skipped.
- **Claims across machines:** Beads claims are local to the database until
  synced (`docs/beads-dogfood.md` entry 4, the Dolt remote). Does claiming mean
  anything for multiple agents on different machines?
- **No linked ticket:** should any of this apply (e.g. the task-disposition gate
  still runs, the state checks don't)?
- **Scope:** is this one change, or should the close-gate / hook-proof-commit
  work ship first as its own change, since it doesn't depend on the state
  model?

## Rough scope

**In scope:**
- `_shared/tracker-dispatch.md` (contract: ordered states, `assert_state`,
  `transition` with read-back);
- `.spwf/tracker.yaml` schema;
- the skills `capture`, `issue-to-task`, `build`, `pr-create`, `close`,
  `retrospective` (Part 2 carried-forward output), `wfstatus`;
- `spwf-beadsify:tracker-backend` (v2 operations);
- READMEs and version bumps (spwf, spwf-beadsify, marketplace.json).

**Out of scope:**
- workflow-lint scoping, doc-lint scaffolding, run-tests "skipped is not green",
  and the workflow-lint count check. These are separate follow-up captures.
- A Linear backend.
- A spwf skill for closing stray tickets (`docs/beads-dogfood.md` entry 11).
