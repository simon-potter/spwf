# Tasks: add-branch-enforcement

> **Authoritative Reference:** [`todo/branch-enforcement.md`](../../../todo/branch-enforcement.md)
> **Architecture Reference:** [`design.md`](./design.md) — Decisions 1 (Layer 1 at spec), 2 (Layer 2 at build), 3 (Layer 3 rescue), 5 (shared module pattern), 8 (rescue base detection).

## Phase 1 — Shared module foundation

- [ ] 1.1 `plugins/spwf/skills/_shared/branch-management.md` exists with valid Markdown structure and table of contents listing the five sections to follow
- [ ] 1.2 `.spwf/branch.yaml` schema documented in the shared module — fields `prefix` (default `feature/`), `base` (default `main`), `auto_branch` (`always | ask | never`, default `always`), `enforce` (`true | false`, default `true`). Each field documented with: type, default, valid values, when it takes effect
- [ ] 1.3 Detect-state decision table documented — three rows: `CURRENT == base` (action: auto-branch), `CURRENT == feature/{change-id}` (action: no-op), `CURRENT == other branch` (action: ask). Each row names which layer consumes it
- [ ] 1.4 Auto-branch operation documented — preconditions (working tree state allowed), action (`git checkout -b feature/{change-id}`), output (single visible confirmation line `✓ Branched to feature/{change-id} (auto)`), failure handling (uncommitted changes halt with clear message)
- [ ] 1.5 Rescue operation documented — three-step recipe (branch HEAD, reset local main, push new branch); explicit rule that force-push to `origin/main` is surfaced as a command string but never executed; subject-line grep with manual-confirm fallback for base-commit detection
- [ ] 1.6 "Reading order" subsection listing which skills consume each section so cross-references resolve to specific sections (not just the file)

## Phase 2 — branch-rescue skill (standalone + reusable)

- [ ] 2.1 `plugins/spwf/skills/branch-rescue/SKILL.md` exists with valid frontmatter — `name: branch-rescue`, `description`, `disable-model-invocation: true`, `allowed-tools: [Read, Bash]`
- [ ] 2.2 Skill body resolves the active change-id via `openspec list --json | jq -r '.[0].name'`. If no active change found, halts with a clear "no active change to rescue" message
- [ ] 2.3 Skill body resolves the pre-spec base commit via `git log main --grep "^spec: add OpenSpec change ${change-id}" --format=%H | head -1` then `git rev-parse ${commit}^`. If grep returns no match, falls back to interactive `git log main --oneline | head -20` + user selection
- [ ] 2.4 Skill performs the three local-only safe operations atomically — `git checkout -b feature/{change-id}` (from HEAD); `git checkout main && git reset --hard ${base}`; verifies `origin/main == ${base}` before declaring success
- [ ] 2.5 Skill surfaces the force-push command as plain text (no automatic execution): `Local main reset to ${base}. To publish: git push --force-with-lease origin main` — exactly that wording
- [ ] 2.6 Smoke test — sandbox setup: create a temp branch from main, plant 3 commits with subject prefix `spec:` / `feat:` / `fix:`, invoke the rescue operation, verify (a) HEAD is on the new feature branch with all 3 commits, (b) local main is at the pre-`spec:` commit, (c) origin/main unchanged

## Phase 3 — Layer 1: spec auto-branches

- [ ] 3.1 `plugins/spwf/skills/spec/SKILL.md` gains a new Step 5.5 "Ensure feature branch" between Step 4 (validate) and Step 6 (commit). The step delegates to `_shared/branch-management.md` § "Auto-branch operation"
- [ ] 3.2 Step 5.5's behaviour matches the detect-state table in Phase 1.3: on `base` → auto-branch; on `feature/{change-id}` → no-op; on other branch → ask once
- [ ] 3.3 Step 5.5 respects `.spwf/branch.yaml: auto_branch: never` (skip silently) and `enforce: false` (skip silently). Both opt-outs documented in the new step body
- [ ] 3.4 Smoke — from `main`, invoke `/spwf:spec my-test-change`: verify spec creates the change AND switches to `feature/my-test-change` AND the spec commit lands on `feature/my-test-change` (not on main)
- [ ] 3.5 Smoke — from `feature/my-test-change`, invoke `/spwf:spec my-test-change`: verify no branch operation occurs and the spec commit lands on the existing branch
- [ ] 3.6 Smoke — from `feature/some-other-thing`, invoke `/spwf:spec my-test-change`: verify the skill asks once and proceeds based on the answer

## Phase 4 — Layer 2: build verifies branch

- [ ] 4.1 `plugins/spwf/skills/build/SKILL.md` gains a new Phase 0 "Verify branch" before Phase 1 (write-tests). Phase 0 delegates to `_shared/branch-management.md` § "Detect-state decision table"
- [ ] 4.2 Phase 0 halts with offer when on `base` and an active change-id exists. The offer reads: "You're on `{base}` with active change `{change-id}`. Build will commit per task — that pollutes `{base}`. Switch to `feature/{change-id}` (I'll create it from HEAD)? [Y/n]"
- [ ] 4.3 On Y: Phase 0 runs `git checkout -b feature/{change-id}` (or `git checkout feature/{change-id}` if it exists ahead of HEAD). On n: halts with "Build cancelled — set `.spwf/branch.yaml: enforce: false` to commit on base intentionally"
- [ ] 4.4 Phase 0 respects `enforce: false` (skip silently)
- [ ] 4.5 Smoke — from `main` with an active change, `/spwf:build {change-id}`: verify Phase 0 halts with the expected offer
- [ ] 4.6 Smoke — from `feature/{change-id}`, `/spwf:build {change-id}`: verify Phase 0 passes silently and Phase 1 starts

## Phase 5 — Layer 3: pr-create offers rescue

- [ ] 5.1 `plugins/spwf/skills/pr-create/SKILL.md` Check 1 replaces "Cannot ship from main branch. Create a feature branch first" with a rescue offer
- [ ] 5.2 Rescue offer detects: active change-id, commits ahead of `origin/main`, pre-spec base commit. Presents the rescue plan inline (numbered steps with exact commands), then asks "Proceed with rescue? [Y/n]"
- [ ] 5.3 On Y: pr-create delegates to `branch-rescue` for the three local-only steps, then continues into Step 1b (security pre-flight) on the new feature branch
- [ ] 5.4 Rescue plan output explicitly mentions the manual force-push step at the end: "Local main is now diverged from origin/main. Push when ready: `git push --force-with-lease origin main`"
- [ ] 5.5 Smoke — from `main` with 5 commits ahead and an active change, `/spwf:pr-create`: verify Check 1 presents the rescue offer with correct base commit, runs rescue on Y, continues pre-flight on the new branch, surfaces the force-push command at the end

## Phase 6 — Capture cleanup + wfstatus branch-drift

- [ ] 6.1 `plugins/spwf/skills/capture/SKILL.md` Step 0 soft note updated — replace "spec or build will branch" with "spec will branch (or run /spwf:branch-rescue if commits already on main)". The note becomes truthful
- [ ] 6.2 `plugins/spwf/skills/wfstatus/SKILL.md` adds a "Branch drift" check — runs after the existing checks. Fires P2 if: active change exists, has incomplete tasks, `feature/{id}` does not exist OR is not checked out, and commits on `base` are ahead of `origin/base`
- [ ] 6.3 Branch-drift check output cites the active change-id and recommends `/spwf:branch-rescue` as the fix
- [ ] 6.4 Smoke — set up a project state matching the failure case (manually plant commits on `main` with an active change), run `/spwf:wfstatus`: verify the drift warning surfaces with the right change-id

## Phase 7 — Docs + version

- [ ] 7.1 Root `README.md` golden-path table reflects that branching happens at spec. Update the `Spec` row's "What it does" cell to mention `feature/{change-id}` auto-creation
- [ ] 7.2 Root `README.md` adds a short subsection (under "How it works" or similar) titled "Branching" describing the three layers and `.spwf/branch.yaml` overrides
- [ ] 7.3 `plugins/spwf/README.md` reflects the new branching contract — at least the `spec`, `build`, `pr-create`, `branch-rescue` rows are updated
- [ ] 7.4 `.spwf/branch.yaml` schema is documented in the shared module (delivered in Phase 1.2) AND linked from both READMEs
- [ ] 7.5 `plugins/spwf/.claude-plugin/plugin.json` version bumped 1.14.0 → 1.15.0. Bump lands in the Phase 7 commit, after Phases 1–6 are structurally complete

## Phase 8 — Acceptance (full lifecycle)

- [ ] 8.1 **Greenfield** — On a fresh feature branch, run `/spwf:capture` → `/spwf:challenge` → `/spwf:spec test-change` from `main`. Verify spec auto-branched to `feature/test-change`. Run `/spwf:build` and confirm Phase 0 passes silently. Confirm at no point did a commit land on `main`
- [ ] 8.2 **Legacy / mid-flow** — Simulate a legacy spec by manually creating `openspec/changes/legacy-test/` and committing a spec on main without branching. Run `/spwf:build legacy-test`. Verify Phase 0 halts with the expected offer. Accept (Y) and verify build proceeds on the new branch
- [ ] 8.3 **Rescue** — Simulate the failure mode: 5 commits on main with an active change. Run `/spwf:pr-create`. Verify Check 1 presents the rescue, runs local moves, surfaces force-push as manual step, and pr-create continues to security pre-flight on the new feature branch
- [ ] 8.4 **Opt-out** — Set `.spwf/branch.yaml: enforce: false`. Run `/spwf:spec opt-out-test` from `main`. Verify no branching occurs — spec commit lands on `main`. Restore `enforce: true` after the test
- [ ] 8.5 **Standalone rescue** — Outside the pr-create flow, with 3 commits on main and an active change, invoke `/spwf:branch-rescue` directly. Verify the same outcome as 8.3
- [ ] 8.6 **Branch-drift detection** — With the same state as 8.3 (commits on main, no feature branch), run `/spwf:wfstatus`. Verify the P2 branch-drift warning surfaces and points at `/spwf:branch-rescue`
