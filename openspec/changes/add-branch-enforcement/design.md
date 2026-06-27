# Design: add-branch-enforcement

## Context

SPWF's golden path (capture → challenge → spec → approve-plan → build →
simplify → pr-create → pr-review → address-review → close) is a sequence
of commit-producing steps. Each step's skill commits to whatever branch
git happens to be on. There is no point in the workflow where branching
is the skill's primary concern, so it never happens deliberately — until
pr-create halts.

The fix needs to handle three regimes:

1. **Greenfield** — fresh capture-spec-build flow; should auto-branch and
   never let commits hit main.
2. **Mid-flow legacy** — projects with in-flight specs from before this
   change; commits are about to start (build) or already started.
3. **After-the-fact rescue** — significant work already on main, user
   discovers the problem at pr-create or later.

Each regime needs a different enforcement: greenfield needs a forward
guard at spec; legacy needs a forward guard at build; rescue needs a
recovery tool. None of these substitute for the others.

## Goals

- Spec commits land on `feature/{change-id}`, never on main, without the
  user having to think about it.
- Build refuses to commit on main when an active change exists.
- PR-create offers automated rescue instead of requiring manual moves.
- A single shared module owns the detect-state / auto-branch / rescue
  logic; calling skills delegate.
- Configurable opt-out (`.spwf/branch.yaml: enforce: false`) keeps the
  workflow usable for the rare "commit on main" case (solo projects,
  doc-only changes, hotfix flows).
- A standalone `/spwf:branch-rescue` skill exposes the recovery operation
  for ad-hoc use (e.g. user notices the problem outside pr-create).

## Non-Goals

- Hook-based enforcement (PreToolUse on git commit). Considered and
  rejected — see Decision 5.
- Remote-side enforcement (GitHub branch protection, GitLab push rules).
  These are orthogonal and live outside SPWF.
- Force-pushing to `origin/main` automatically. Rescue does the local-only
  safe moves and surfaces the force-push command for the user to run.
- Branching at capture, challenge, or approve-plan. Each rejected — see
  Decision 1.
- Renaming any existing skills.
- A central `/spwf:branch` orchestrator skill that all phases must
  remember to invoke. Considered and rejected — see Decision 5.

---

## Decisions

### 1. Layer 1 lives at spec, not capture / challenge / approve-plan / build

**Decision:** Auto-branching fires at `/spwf:spec` Step 5.5, between
OpenSpec change creation (Step 4 validation) and the spec commit (Step 6).

**Rationale:** Spec is the commitment point — ideation is over, OpenSpec
artefacts are real, a commit is imminent. Earlier phases handle work that
may never become a real change (capture's trivial-fix path; challenge's
abandoned ideations). Later phases let the spec commit leak to main:

| Phase considered | Why rejected |
|---|---|
| Capture | Handles trivial-fix path that never becomes a spec; over-eager. |
| Challenge | No commit yet; branching here only proves the slot is wrong. |
| Approve-plan | Spec's commit has already leaked to main. |
| Build | Spec's commit leaks; build's first task commit is one branch-creation too late. |

Spec auto-branching also makes branch naming mechanical: every OpenSpec
change has a `change-id`; `feature/{change-id}` is unambiguous.

### 2. Build's Phase 0 is a safety net, not the primary enforcement

**Decision:** `/spwf:build` adds a new Phase 0 that runs before Phase 1
(write-tests). If on main with an active change, halts with an auto-fix
offer.

**Rationale:** Layer 1 will catch greenfield. Layer 2 catches:
- Legacy specs written before this change shipped
- Imported specs from another project
- User manually checked out main between spec and build
- Layer 1 was bypassed via `.spwf/branch.yaml: auto_branch: never`

Build is the highest-volume committer (one commit per task; 5–20 per
change). A failure here is the most damaging single failure. Even if
Layer 1 catches 95% of cases, Layer 2 is worth the cost.

### 3. Layer 3 is rescue, not enforcement

**Decision:** `/spwf:pr-create` Check 1 replaces "halt with create-a-branch
first" message with an "offer to rescue automatically" prompt. The actual
work delegates to `/spwf:branch-rescue`.

**Rationale:** By the time pr-create runs with commits on main, Layer 1
and Layer 2 have both failed (or the user opted out). Halting with "fix
it yourself" is the current behaviour — and exactly the pain the user
described. Offering automated rescue at the natural failure-discovery
point converts an interruption into a workflow continuation.

The rescue is local-only safe: branch HEAD as `feature/{change-id}`,
reset local main to the pre-spec commit, push the new branch. Force-push
to `origin/main` (destructive to shared state) stays manual — the rescue
prints the exact command (`git push --force-with-lease origin main`) but
does not run it.

### 4. Branch naming convention: `feature/{change-id}`

**Decision:** Default branch name template is `feature/{change-id}` where
`{change-id}` is the OpenSpec change directory name (e.g.
`add-branch-enforcement` → `feature/add-branch-enforcement`). Prefix
configurable via `.spwf/branch.yaml: prefix:`.

**Rationale:** Symmetric naming makes downstream detection trivial: given
a change-id, the expected branch name is computable. Given a branch
name, the active change-id is recoverable. No mapping table; no
ambiguity. Matches the existing `feature/foo` convention common in git
workflows.

Alternative considered: derive from the spec title or from a `branch:`
field in the proposal frontmatter. Rejected — extra moving parts; the
change-id already plays this role.

### 5. Centralise in `_shared/branch-management.md`; reject single orchestrator and hooks

**Decision:** All three layers delegate to
`plugins/spwf/skills/_shared/branch-management.md`. The shared module
documents:
- `.spwf/branch.yaml` schema
- Detect-state decision table (on base / on target / on other branch)
- Auto-branch operation
- Rescue operation
- `auto_branch:` and `enforce:` semantics

**Rationale:** Mirrors the existing dispatch-abstraction pattern
(`tracker-dispatch.md`, `forge-dispatch.md`). One source of truth; each
skill references the relevant section. Same architecture; same auditing
surface.

Alternatives considered:

| Alternative | Why rejected |
|---|---|
| Single `/spwf:branch` orchestrator skill that all phases invoke | Easy to forget; defeats the autopilot orchestrator model; failure mode returns the first time a skill author skips the invocation. |
| Claude Code hook (PreToolUse on `git commit`) | Hooks run in bash without OpenSpec context; classifying "is this commit part of an SPWF flow?" reliably from a hook is brittle; false-positive rate on legitimate main commits is high. |
| Duplicate logic in each skill (spec/build/pr-create) | DRY violation; drift between layers as skills evolve independently. |

### 6. Auto-branch without prompting by default; configurable

**Decision:** `.spwf/branch.yaml: auto_branch:` accepts three values:
- `always` (default) — Layer 1 branches silently with a single visible
  confirmation line (`✓ Branched to feature/{change-id} (auto)`)
- `ask` — Layer 1 prompts before branching
- `never` — Layer 1 skips; Layer 2 catches with its halt-offer

**Rationale:** Asking every time trains users to mash 'y' — the prompt
stops protecting and starts annoying. Default to action; let the user
opt into ask-mode if they explicitly want it. The single visible line
keeps the action discoverable so first-time users notice and can
override.

### 7. Configurable opt-out via `.spwf/branch.yaml: enforce: false`

**Decision:** Setting `enforce: false` bypasses all three layers. The
workflow behaves identically to the pre-change baseline.

**Rationale:** Solo devs, doc-only changes, hotfix flows, projects with
team-specific branching conventions all need an out. Config-level
opt-out is the right granularity — per-skill flags would proliferate;
env vars are easy to forget; CLI flags don't carry across sessions.

The default is `enforce: true`. Existing projects upgrading without a
`.spwf/branch.yaml` file get enforcement; opting out is an explicit
file creation.

### 8. Rescue's "pre-spec commit" detection: grep for the spec commit subject

**Decision:** The rescue identifies the pre-spec commit by:

```
SPEC_COMMIT=$(git log main --grep "^spec: add OpenSpec change ${change-id}" \
                  --format=%H | head -1)
BASE_COMMIT=$(git rev-parse "${SPEC_COMMIT}^")
```

If no matching spec commit is found on main, the rescue prompts the user
to confirm the rescue base manually (`git log main --oneline`).

**Rationale:** Spec's commit message format is conventional
(`spec: add OpenSpec change {change-id}` — see
[`spec/SKILL.md` Step 6](../../../plugins/spwf/skills/spec/SKILL.md)).
That convention is fragile if a user edits the spec commit message,
but the manual-confirm fallback keeps the rescue useful in the
degraded case. Alternatives:

| Alternative | Why rejected |
|---|---|
| Reflog | Reflog is local; not robust across machines or after gc |
| `git merge-base HEAD origin/main` | Assumes `origin/main` hasn't moved; wrong on long-lived branches |
| Tag the pre-spec commit at spec time | Adds tag noise; tags are global namespace |
| Read `openspec/changes/{change-id}/.spwf-base` sidecar | Adds a state file; subject-line grep is simpler |

The subject-line approach is consistent with what the user already does
manually ("reset main to `a1ffdd7`, the pre-feature commit") — it
automates that exact reasoning.

### 9. Branch-drift detection in wfstatus is P2

**Decision:** `/spwf:wfstatus` adds a check:
- Active OpenSpec change exists (`openspec/changes/{id}/`)
- That change has incomplete tasks
- `feature/{id}` does not exist OR is not the current branch
- Commits on main beyond `origin/main` touch files in the change's
  affected areas

If all four hold, flag as P2 ("⚠ Branch drift — change `{id}` may be
committing to `main`. Run `/spwf:branch-rescue` to move commits.").

**Rationale:** Detects the failure this change is designed to prevent.
Useful for projects that upgrade mid-flow without having read the
release notes. Phase 6 of the build plan covers this.

### 10. pr-create points forward to close; it does not invoke it

**Decision:** `/spwf:pr-create`'s final report gains a "Next step" block
naming `/spwf:close` as the canonical post-merge action and stating that
the retrospective (learn-from-mistakes, spec audit, doc-lint,
workflow-lint, recap) runs *inside* close. pr-create does **not** call
close automatically.

**Rationale:** The downstream failure was an agent treating "merge and
close the ticket" as terminal because nothing in-flow named the next
step — the golden-path table in the README documents close, but the skill
running immediately before it does not hand off. A forward pointer fixes
the discoverability gap at the exact point the agent loses the thread.
Auto-invoking close is rejected: close is a human-gated, destructive
final phase (archives the change, transitions the ticket, deletes the
branch) and must not fire as a side effect of opening a PR — pr-create
explicitly does not even merge. A `workflow-lint` check (Phase 9) guards
against the pointer regressing: every phase orchestrator should name its
successor.

### 11. Spec carries the tracker ticket into the proposal; never invents one

**Decision:** `/spwf:spec` reads `ticket:` from the ideation file
frontmatter (written by `capture` / `issue-to-task`) and, when present,
emits a `**Tracker**: {ticket}` line in the proposal header block. When
absent, the line is omitted entirely — spec never prompts for or invents
a ticket. `close`'s Step 1 gains a proposal-frontmatter fallback so the
link survives if the todo file is later edited or moved.

**Rationale:** The ticket link already flows capture → todo → close, but
the OpenSpec artefact (which travels into the archive) drops it. Carrying
it into the proposal makes the archived change self-describing and gives
close a second source. Silent omission matters because most changes have
no tracker ticket (freeform `new-task` captures); prompting would add
friction to the common case. Header line over a `closes:` frontmatter key
because the existing proposal template uses prose `**Field**:` header
lines (`**Change ID**`, `**Status**`, `**Source**`) — `**Tracker**:` is
consistent; a YAML frontmatter block would be a new convention.

---

## Risks and Trade-offs

| Risk | Mitigation |
|---|---|
| Auto-branching surprises first-time users who didn't expect a branch. | Visible confirmation line; opt-out via `.spwf/branch.yaml`; documented prominently in root README. |
| Rescue's subject-line grep fails on edited spec commit messages. | Manual-confirm fallback (`git log main --oneline`) when grep returns no match. |
| Force-push to `origin/main` post-rescue can damage shared state if multiple devs work on main directly. | Rescue never runs the force-push; surfaces the exact command for the user to run when ready. |
| `.spwf/branch.yaml: enforce: false` becomes the de-facto default for users frustrated by the change. | Default ergonomics matter; auto-branch is silent except for the confirmation line. If `enforce: false` becomes common, that's signal to revisit defaults. |
| Branch already exists from a previous attempt (`feature/{change-id}` is taken). | Layer 1 detects and switches; Layer 2 detects and halts with "branch exists" message. |
| `main` is not the actual base branch (project uses `master` or `develop`). | `.spwf/branch.yaml: base:` overrides the base branch name. |
| Squash-merged PRs leave no "spec commit" on main for rescue to find. | Rescue falls back to manual-confirm when grep returns no match. Acceptable degradation. |

---

## Implementation Plan (summary; full breakdown in tasks.md)

- **Phase 1**: shared module foundation (`_shared/branch-management.md`)
  with config schema, detect-state, auto-branch, rescue operations.
- **Phase 2**: `branch-rescue` skill scaffold + operation; smoke test on
  a sandbox branch with planted commits.
- **Phase 3**: Layer 1 — spec/SKILL.md Step 5.5; smoke from main, from
  target branch, from other branch.
- **Phase 4**: Layer 2 — build/SKILL.md Phase 0; smoke from main, from
  feature branch, with branch-already-exists.
- **Phase 5**: Layer 3 — pr-create/SKILL.md Check 1 rescue offer; smoke
  the full rescue path end-to-end.
- **Phase 6**: capture's Step 0 note correction + wfstatus drift
  detection + plugins/spwf README updates.
- **Phase 7**: root README golden-path table update + `.spwf/branch.yaml`
  schema documented + version bump 1.14.0 → 1.15.0.
- **Phase 8**: Acceptance — full lifecycle smoke (greenfield, legacy,
  rescue, opt-out).
- **Phase 9**: Layer 4 — pr-create → close handoff block + workflow-lint
  successor-pointer check (Decision 10).
- **Phase 10**: spec carries `ticket:` into the proposal + close
  proposal-fallback resolution (Decision 11).

Phases 9–10 are independent of the branching layers (1–8) and of each
other; they may be built in any order relative to those phases. They were
folded into this change because they fix workflow-handoff seams adjacent
to the branching seam (see proposal § Scope addendum).

Phase ordering matters: the shared module must exist before any skill
delegates to it (Phase 1 before 2–5); the rescue operation is consumed
by both pr-create and the standalone skill (Phase 2 before 5).
