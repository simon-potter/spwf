---
source: scratch
created: 2026-05-31
status: complete
---

# Enforce feature-branching at the right phase of the SPWF golden path

## Context

The SPWF workflow currently has **no explicit branching step**. The
capture skill's Step 0 prints a soft note when on main — *"capture writes
ideation only; spec or build will branch"* — but neither spec nor build
actually branches. The only enforcement is `/spwf:pr-create`'s Check 1
("Cannot ship from main branch"), which fires *after* 5–20 commits have
already landed on main. Users routinely end up needing to manually move
commits to a feature branch and reset main — a destructive rescue done
by hand every time.

The user described the recurring scenario verbatim:

> "all of this work is committed directly on main — the build loop never
> created a feature branch. pr-create will need a branch to open a PR
> against main. ... I can move the change commits onto a feat/X branch
> (and reset main to a1ffdd7, the pre-feature commit) so there's a clean
> PR diff."

This is workflow drift, not a skill bug. The fix needs to land structurally.

## What we know

**Where commits enter the workflow today (and the gap each step leaks):**

| Phase | Skill | Commits? | Branching today |
|---|---|---|---|
| Capture | `/spwf:capture` | 1 (ideation file) | Soft note only, **promises** spec/build will branch |
| Challenge | `/spwf:challenge` | 1 (decisions back into todo) | No |
| Spec | `/spwf:spec` | 1 (`spec: add OpenSpec change`) | **No — first real leak** |
| Approve-plan | `/spwf:approve-plan` | 0 | No |
| Build | `/spwf:build` | N (one per task; 5–20 typical) | **No — biggest leak** |
| Simplify | `/spwf:simplify` | 0–1 (mechanical pass) | Assumes branch via `git diff main...HEAD`, doesn't create |
| PR-create | `/spwf:pr-create` | 0 (creates the PR) | **Halts if on main — only enforcement, too late** |

**The model we agreed on — three-layer defence:**

1. **Layer 1 — Spec auto-branches (strong default).** Spec is the commitment point: ideation is over, OpenSpec artefacts are real, a commit lands. Spec's new Step 5.5 ensures `feature/{change-id}` exists and we're on it before its Step 6 commit. Symmetric naming (change-id ↔ branch name).
2. **Layer 2 — Build verifies branch on entry.** Phase 0 (new). Catches legacy specs, imported work, manual checkout-to-main after spec. Halts with auto-fix offer.
3. **Layer 3 — PR-create offers auto-rescue instead of bare halt.** When the failure has already happened (commits on main with an active change), detect the pre-spec commit, branch HEAD as `feature/{change-id}`, reset local main. Force-push to `origin/main` stays manual — destructive shared-state action.

**Plus one extraction:** centralise the detect/auto-branch/rescue logic in
`plugins/spwf/skills/_shared/branch-management.md` (mirrors the
`tracker-dispatch.md` / `forge-dispatch.md` shared-module pattern).

**Plus one new skill:** `/spwf:branch-rescue` exposes the rescue
operation for standalone use (when a user discovers the problem outside
the pr-create flow).

## Challenge decisions

Resolved during the ultrathink interview (2026-05-31):

- **Layer 1 lives at spec, not capture, approve-plan, or build.**
  - Not capture: capture handles trivial fixes that never become real
    changes; branching there is over-eager.
  - Not approve-plan: spec's commit would already have leaked to main.
  - Not build: spec's commit still leaks if branching waits until build.
  - Spec is the natural commitment point — OpenSpec artefacts being
    created *is* the inflection from ideation to commitment.

- **Auto-branch without asking by default; escape hatch is config not
  prompt.** Asking trains users to mash 'y'. `.spwf/branch.yaml` exposes
  `auto_branch: ask | always | never` (default `always` for SPWF
  projects; `ask` for first-time users). The single visible line
  `✓ Branched to feature/{change-id} (auto)` keeps the action discoverable.

- **Branch naming: `feature/{change-id}`** symmetric with the OpenSpec
  change-id. Prefix configurable via `.spwf/branch.yaml: prefix:` if a
  project uses a different convention; default `feature/`.

- **Rescue is destructive on `origin/main` — manual force-push only.**
  Layer 3 does the local-only safe moves (branch HEAD, reset local
  main, push new branch). It surfaces the exact
  `git push --force-with-lease origin main` command but does not run it.
  Shared-state destruction stays a human decision.

- **Defence in depth, not a single point.** Hooks were considered and
  rejected (can't read OpenSpec state cleanly; brittle). A single
  `/spwf:branch` orchestrator was considered and rejected (easy to
  forget; defeats the autopilot model). Three layers + shared module
  is the architecture.

- **Configurable opt-out is required.** Solo devs and tiny-spec'd work
  may want to commit on main. `.spwf/branch.yaml: enforce: false`
  bypasses all three layers. Default `true`.

- **Capture's misleading soft note is fixed in the same change.** Once
  spec auto-branches, the note becomes true. Either keep it ("spec
  will branch") or drop it entirely. The change updates it.

- **`/spwf:wfstatus` flags branch drift.** When an active change has
  build tasks but no `feature/{change-id}` branch exists, surface as
  a P2 warning. Detects the failure that this enforcement is designed
  to prevent — useful when the change ships before users have updated.

## Rough scope

**In scope:**

- **NEW** `plugins/spwf/skills/_shared/branch-management.md` — centralised
  detect-state / auto-branch / rescue logic + `.spwf/branch.yaml` schema
- **NEW** `plugins/spwf/skills/branch-rescue/SKILL.md` — standalone
  skill exposing the rescue operation (also called by pr-create)
- **MODIFIED** `plugins/spwf/skills/spec/SKILL.md` — add Step 5.5
  "Ensure feature branch" between OpenSpec creation (Step 4) and
  commit (Step 6)
- **MODIFIED** `plugins/spwf/skills/build/SKILL.md` — add Phase 0
  "Verify branch" with halt + auto-fix offer if on main
- **MODIFIED** `plugins/spwf/skills/pr-create/SKILL.md` — Check 1
  replaces bare halt with rescue offer; wires to `/spwf:branch-rescue`
- **MODIFIED** `plugins/spwf/skills/capture/SKILL.md` — fix or drop
  the misleading "spec/build will branch" soft note
- **MODIFIED** `plugins/spwf/skills/wfstatus/SKILL.md` — add branch-drift
  detection
- **MODIFIED** root `README.md` golden-path table — make branching
  visible in the workflow description
- **MODIFIED** `plugins/spwf/README.md` — reflect the new branching
  contract; document `.spwf/branch.yaml`
- **VERSION BUMP** `plugins/spwf/.claude-plugin/plugin.json`
  1.14.0 → 1.15.0 (minor — meaningful behaviour change, opt-out exists)

**Out of scope:**

- Hook-based enforcement (rejected — see decisions)
- Remote-side enforcement (GitHub branch-protection rules are
  orthogonal; not SPWF's domain)
- Renaming any existing skills (no `pr-create` → `pr-ship` etc.)
- Touching `_shared/forge-dispatch.md` (branching is git-state, not
  forge-state)

**No breaking changes** — defaults preserve current behaviour for
existing projects until they invoke spec/build/pr-create after upgrade.
First spec invocation post-upgrade auto-branches; that's the only
visible change without explicit opt-out.
