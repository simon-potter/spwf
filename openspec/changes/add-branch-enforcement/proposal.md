# Proposal: Enforce feature-branching at the right phase of the SPWF golden path

**Change ID**: `add-branch-enforcement`
**Status**: Draft
**Created**: 2026-05-31
**Source**: [todo/branch-enforcement.md](../../../todo/branch-enforcement.md)

---

## Why

The SPWF workflow has no explicit branching step. Capture's Step 0 promises
"spec or build will branch" — neither does. The only enforcement is
`/spwf:pr-create`'s halt-if-on-main check, which fires *after* 5–20 commits
have already landed on main. Users repeatedly perform the same destructive
manual rescue (move commits to a feature branch, reset main, push) when
shipping. This is workflow drift, fixed by adding branching as a
first-class concern of the golden path — with defence in depth so single
failure points don't reintroduce the problem.

**Scope addendum (2026-06-27, downstream feedback).** A project using SPWF
reported its agent shipped a change and "closed the ticket" without ever
running the retrospective. Investigation showed the close-out machinery
already exists (`/spwf:close` runs the full retrospective; `/spwf:capture`
records the `ticket:`) — but two seams let an agent fall off the path:
(1) `/spwf:pr-create` ends with no forward pointer to `/spwf:close`, so an
agent executing "merge and close" literally has nothing in-flow telling it
retrospective is the next step; (2) `/spwf:spec` does not carry the
ideation file's `ticket:` into the proposal, so the tracker link is absent
from the OpenSpec artefact (it survives only in the todo file). Both are
workflow-handoff gaps adjacent to the branching seam this change already
fixes, so they are folded in here rather than tracked separately.

## What Changes

- **NEW** `plugins/spwf/skills/_shared/branch-management.md` — centralised
  detect-state / auto-branch / rescue logic + `.spwf/branch.yaml` schema.
  Mirrors the `tracker-dispatch.md` / `forge-dispatch.md` shared-module
  pattern.
- **NEW** `plugins/spwf/skills/branch-rescue/SKILL.md` — standalone skill
  exposing the rescue operation (move commits to feature branch + reset
  local main) for when the failure has already occurred. Also invoked by
  pr-create's new offer.
- **MODIFIED** `plugins/spwf/skills/spec/SKILL.md` — Layer 1. Add Step 5.5
  "Ensure feature branch" between OpenSpec creation and the commit so the
  spec commit lands on `feature/{change-id}`, not on main.
- **MODIFIED** `plugins/spwf/skills/build/SKILL.md` — Layer 2. Add Phase 0
  "Verify branch" that halts if on main with an active change, offering
  auto-fix.
- **MODIFIED** `plugins/spwf/skills/pr-create/SKILL.md` — Layer 3. Check 1
  replaces bare halt with rescue offer; calls `/spwf:branch-rescue`.
- **MODIFIED** `plugins/spwf/skills/capture/SKILL.md` — fix the misleading
  "spec/build will branch" soft note; the promise becomes true.
- **MODIFIED** `plugins/spwf/skills/wfstatus/SKILL.md` — flag branch drift
  (active change with commits on main, no `feature/{change-id}`).
- **MODIFIED** root `README.md` — make branching visible in the
  golden-path table.
- **MODIFIED** `plugins/spwf/README.md` — document the new branching
  contract and `.spwf/branch.yaml`.
- **MODIFIED** `plugins/spwf/skills/pr-create/SKILL.md` — Layer 4
  (handoff). Final output gains a "Next step" block naming `/spwf:close`
  as the canonical post-merge action, stating that retrospective runs
  inside close. Does not invoke close automatically — points forward only.
- **MODIFIED** `plugins/spwf/skills/spec/SKILL.md` — carry the ideation
  file's `ticket:` into `proposal.md` (a `**Tracker**:` header line) when
  present; omit silently when absent.
- **MODIFIED** `plugins/spwf/skills/close/SKILL.md` — Step 1 ticket
  resolution gains a proposal-frontmatter fallback so the tracker link
  survives even if the todo file is edited or moved.
- **MODIFIED** `plugins/spwf/skills/workflow-lint/SKILL.md` — add a
  coherence check that each phase orchestrator names its successor phase
  (flags a missing pr-create → close pointer as P2).
- **NEW SCHEMA** `.spwf/branch.yaml` — documented inside the shared module:
  `prefix:`, `base:`, `auto_branch: ask | always | never`,
  `enforce: true | false`.
- **VERSION BUMP** `plugins/spwf/.claude-plugin/plugin.json` 1.14.0 → 1.15.0
  (minor — meaningful behaviour change with explicit opt-out path).

## Impact

- **Affected areas**: 8 spwf skills modified (spec, build, pr-create,
  capture, wfstatus, close, workflow-lint, plus the new branch-rescue),
  2 new skill/module files, 2 READMEs updated, new optional config file.
- **No breaking changes** — defaults preserve current ability to opt out
  (`.spwf/branch.yaml: enforce: false`). First spec invocation post-upgrade
  auto-branches; that's the one visible behaviour change without explicit
  opt-out. Capture/challenge/approve-plan/simplify behave identically.
- **Dependencies on consumers** — none. Projects that prefer the old
  behaviour set `enforce: false` in `.spwf/branch.yaml`.

---

## Decisions

Settled during Challenge (resolved in the ultrathink session 2026-05-31 — see
[todo/branch-enforcement.md](../../../todo/branch-enforcement.md) § Challenge
decisions):

- **Layer 1 lives at spec, not capture/approve-plan/build.** Spec is the
  commitment point; branching at capture is over-eager (capture handles
  trivial fixes that never become real changes); branching at build/approve
  lets the spec commit leak to main.
- **Auto-branch without ask by default.** Asking trains users to mash 'y'.
  Configurable via `.spwf/branch.yaml: auto_branch:`.
- **Branch naming: `feature/{change-id}`** symmetric with the OpenSpec
  change-id. Prefix configurable.
- **Rescue is destructive on `origin/main` — manual force-push only.** Layer 3
  does local-only safe moves and surfaces the force-push command without
  running it.
- **Defence in depth, not single enforcement point.** Hooks rejected
  (brittle, can't read OpenSpec state); single `/spwf:branch` orchestrator
  rejected (easy to forget).
- **Configurable opt-out is required.** Solo / tiny-change use cases need a
  way out.

Open (TBD — settle during design.md):

- **Rescue's "pre-spec commit" detection algorithm.** Possible approaches:
  (a) grep commit log for `spec: add OpenSpec change {change-id}` subject,
  use parent; (b) read git reflog for the branch's first divergence from
  `origin/main`; (c) take the merge-base of HEAD with `origin/main`. Pin
  during design with reproducibility / robustness in mind.
- **Branch-drift detection in wfstatus.** Algorithm: if `openspec/changes/{id}/`
  exists, has incomplete tasks, AND `feature/{id}` doesn't exist OR isn't
  checked out — flag. Resolve corner cases during design (squash-merged
  changes; archived changes leaving no active change-id; user manually
  named branch differently).
- **Backward-compat for legacy specs in flight.** Projects upgrading
  mid-flow have specs without `feature/{change-id}` branches. Layer 2's
  build entry catches this — verify the message wording covers "your spec
  predates this enforcement; can I create the branch from HEAD?" so the
  experience isn't confusing.

## Success Criteria

With this change shipped:

1. Running `/spwf:spec X` from `main` lands the spec commit on
   `feature/X`, not on main. Confirmed by `git log main..HEAD` showing
   the spec commit only on the feature branch post-spec.
2. Running `/spwf:build X` from `main` with an active change halts and
   offers to switch/create `feature/X`. Confirmed by reading the new
   Phase 0 output.
3. Running `/spwf:pr-create` from `main` with N commits ahead detects the
   pre-spec commit, branches HEAD as `feature/{change-id}`, and resets
   local main without touching `origin/main`. Confirmed by `git log` on
   both refs post-rescue and the absence of any `git push --force` in
   the trace.
4. `.spwf/branch.yaml: enforce: false` bypasses all three layers — the
   workflow behaves as today. Confirmed by toggling and running a spec.
5. `/spwf:wfstatus` flags a project that has an active change but is
   committing on main as P2. Confirmed by deliberate setup.
6. Capture's Step 0 soft note matches reality (no longer misleading).
7. Backward-compat: a legacy spec (predates this change) building on main
   gets the same Layer 2 offer as a fresh spec on main — same UX.
8. `/spwf:pr-create` ends by naming `/spwf:close` as the next step and
   stating retrospective runs inside it. Confirmed by reading the
   pr-create terminal output; an agent following the flow can no longer
   "close the ticket" without the retrospective being surfaced.
9. Running `/spwf:spec X` from an ideation file with `ticket: ACAD-42`
   produces a `proposal.md` carrying `**Tracker**: ACAD-42`; an ideation
   file with no `ticket:` produces a proposal with no Tracker line.
   Confirmed by inspecting both proposals.
