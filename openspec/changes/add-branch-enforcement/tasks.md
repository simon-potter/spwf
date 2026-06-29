# Tasks: add-branch-enforcement

> **Authoritative Reference:** [`todo/branch-enforcement.md`](../../../todo/branch-enforcement.md)
> **Architecture Reference:** [`design.md`](./design.md) — Decisions 1 (Layer 1 at spec), 2 (Layer 2 at build), 3 (Layer 3 rescue), 5 (shared module pattern), 8 (rescue base detection).
>
> **Closed at 51/58 (2026-06-29).** Implementation shipped in spwf 1.15.0–1.18.0; deterministic logic sandbox-verified. The 7 still-unchecked items (3.6, 4.5, 4.6, 5.5, 8.1, 8.2, 8.3) are live-interactive / test-suite-dependent acceptance smokes — extracted to [`todo/branch-enforcement-acceptance.md`](../../../todo/branch-enforcement-acceptance.md) for real-project verification rather than fake-completed here.

## Phase 1 — Shared module foundation

- [x] 1.1 `plugins/spwf/skills/_shared/branch-management.md` exists with valid Markdown structure and table of contents listing the five sections to follow
- [x] 1.2 `.spwf/branch.yaml` schema documented in the shared module — fields `prefix` (default `feature/`), `base` (default `main`), `auto_branch` (`always | ask | never`, default `always`), `enforce` (`true | false`, default `true`). Each field documented with: type, default, valid values, when it takes effect
- [x] 1.3 Detect-state decision table documented — three rows: `CURRENT == base` (action: auto-branch), `CURRENT == feature/{change-id}` (action: no-op), `CURRENT == other branch` (action: ask). Each row names which layer consumes it
- [x] 1.4 Auto-branch operation documented — preconditions (working tree state allowed), action (`git checkout -b feature/{change-id}`), output (single visible confirmation line `✓ Branched to feature/{change-id} (auto)`), failure handling (uncommitted changes halt with clear message)
- [x] 1.5 Rescue operation documented — three-step recipe (branch HEAD, reset local main, push new branch); explicit rule that force-push to `origin/main` is surfaced as a command string but never executed; subject-line grep with manual-confirm fallback for base-commit detection
- [x] 1.6 "Reading order" subsection listing which skills consume each section so cross-references resolve to specific sections (not just the file)

## Phase 2 — branch-rescue skill (standalone + reusable)

- [x] 2.1 `plugins/spwf/skills/branch-rescue/SKILL.md` exists with valid frontmatter — `name: branch-rescue`, `description`, `disable-model-invocation: true`, `allowed-tools: [Read, Bash]`
- [x] 2.2 Skill body resolves the active change-id via `openspec list --json | jq -r '.[0].name'`. If no active change found, halts with a clear "no active change to rescue" message
- [x] 2.3 Skill body resolves the pre-spec base commit. Validates `${change-id}` against `^[a-z][a-z0-9-]+$` (OpenSpec slug rules) before any substitution; runs `git log "${base}" --grep "^spec: add OpenSpec change ${change-id}$" --format=%H | head -1` then `git rev-parse "${commit}^"`. If grep returns no match, falls back to interactive `git log "${base}" --oneline | head -20` plus user-supplied SHA plus an explicit confirmation prompt. (Hyphens in OpenSpec slugs are regex-literal so the grep pattern is safe given the upstream validation; this follows Beadsify's Decision 7 safe-subprocess pattern.)
- [x] 2.4 Skill performs the three local-only safe operations atomically — `git checkout -b feature/{change-id}` (from HEAD); `git checkout main && git reset --hard ${base}`; verifies `origin/main == ${base}` before declaring success
- [x] 2.5 Skill surfaces the force-push command as plain text (no automatic execution): `Local main reset to ${base}. To publish: git push --force-with-lease origin main` — exactly that wording
- [x] 2.6 Smoke test — sandbox setup: create a temp branch from main, plant 3 commits with subject prefix `spec:` / `feat:` / `fix:`, invoke the rescue operation, verify (a) HEAD is on the new feature branch with all 3 commits, (b) local main is at the pre-`spec:` commit, (c) origin/main unchanged

## Phase 3 — Layer 1: spec auto-branches

- [x] 3.1 `plugins/spwf/skills/spec/SKILL.md` gains a new Step 5.5 "Ensure feature branch" between Step 4 (validate) and Step 6 (commit). The step delegates to `_shared/branch-management.md` § "Auto-branch operation"
- [x] 3.2 Step 5.5 implements all three primary branches of the detect-state table — on `base` (run `git checkout -b feature/{change-id}`, emit `✓ Branched to feature/{change-id} (auto)`), on `feature/{change-id}` (no-op, emit `✓ Already on feature/{change-id}`), on other branch (ask once, proceed per the user's answer). Each branch SHALL emit exactly one visible confirmation line per Phase 1.4
- [x] 3.3 Step 5.5 respects `.spwf/branch.yaml: auto_branch: never` (skip silently) and `enforce: false` (skip silently). Both opt-outs documented in the new step body
- [x] 3.4 Smoke — from `main`, invoke `/spwf:spec my-test-change`: verify spec creates the change AND switches to `feature/my-test-change` AND the spec commit lands on `feature/my-test-change` (not on main)
- [x] 3.5 Smoke — from `feature/my-test-change`, invoke `/spwf:spec my-test-change`: verify no branch operation occurs and the spec commit lands on the existing branch
- [ ] 3.6 Smoke — from `feature/some-other-thing`, invoke `/spwf:spec my-test-change`: verify the skill asks once and proceeds based on the answer
- [x] 3.7 Step 5.5 detects when `feature/{change-id}` already exists (e.g. from an interrupted prior spec attempt) and switches to it via `git checkout feature/{change-id}` rather than failing on `git checkout -b`. If the existing branch is behind HEAD, the skill SHALL halt with "branch exists but is behind HEAD — manual merge or rebase required" rather than auto-merging. Mirrors Phase 0's branch-exists handling (4.3)
- [x] 3.8 Smoke — pre-create `feature/test-change` on the sandbox, then invoke `/spwf:spec test-change` from `main`: verify the skill emits `✓ Switched to existing feature/test-change` and the spec commit lands on the existing branch (no `checkout -b` crash)

## Phase 4 — Layer 2: build verifies branch

- [x] 4.1 `plugins/spwf/skills/build/SKILL.md` gains a new Phase 0 "Verify branch" before Phase 1 (write-tests). Phase 0 delegates to `_shared/branch-management.md` § "Detect-state decision table"
- [x] 4.2 Phase 0 halts with offer when on `base` and an active change-id exists. The offer reads: "You're on `{base}` with active change `{change-id}`. Build will commit per task — that pollutes `{base}`. Switch to `feature/{change-id}` (I'll create it from HEAD)? [Y/n]"
- [x] 4.3 On Y: Phase 0 runs `git checkout -b feature/{change-id}` (or `git checkout feature/{change-id}` if it exists ahead of HEAD). On n: halts with "Build cancelled — set `.spwf/branch.yaml: enforce: false` to commit on base intentionally"
- [x] 4.4 Phase 0 respects `enforce: false` (skip silently)
- [ ] 4.5 Smoke — from `main` with an active change, `/spwf:build {change-id}`: verify Phase 0 halts with the expected offer
- [ ] 4.6 Smoke — from `feature/{change-id}`, `/spwf:build {change-id}`: verify Phase 0 passes silently and Phase 1 starts

## Phase 5 — Layer 3: pr-create offers rescue

- [x] 5.1 `plugins/spwf/skills/pr-create/SKILL.md` Check 1 replaces "Cannot ship from main branch. Create a feature branch first" with a rescue offer
- [x] 5.2 Rescue offer detects: active change-id, commits ahead of `origin/main`, pre-spec base commit. Presents the rescue plan inline (numbered steps with exact commands), then asks "Proceed with rescue? [Y/n]"
- [x] 5.3 On Y: pr-create delegates to `branch-rescue` for the three local-only steps, then continues into Step 1b (security pre-flight) on the new feature branch
- [x] 5.4 Rescue plan output explicitly mentions the manual force-push step at the end: "Local main is now diverged from origin/main. Push when ready: `git push --force-with-lease origin main`"
- [ ] 5.5 Smoke — from `main` with 5 commits ahead and an active change, `/spwf:pr-create`: verify Check 1 presents the rescue offer with correct base commit, runs rescue on Y, continues pre-flight on the new branch, surfaces the force-push command at the end

## Phase 6 — Capture cleanup + wfstatus branch-drift

- [x] 6.1 `plugins/spwf/skills/capture/SKILL.md` Step 0 soft note updated — replace "spec or build will branch" with "spec will branch (or run /spwf:branch-rescue if commits already on main)". The note becomes truthful
- [x] 6.2 `plugins/spwf/skills/wfstatus/SKILL.md` adds a "Branch drift" check — runs after the existing checks. Fires P2 if: active change exists, has incomplete tasks, `feature/{id}` does not exist OR is not checked out, and commits on `base` are ahead of `origin/base`
- [x] 6.3 Branch-drift check output cites the active change-id and recommends `/spwf:branch-rescue` as the fix
- [x] 6.4 Smoke — set up a project state matching the failure case (manually plant commits on `main` with an active change), run `/spwf:wfstatus`: verify the drift warning surfaces with the right change-id

## Phase 7 — Docs + version

- [x] 7.1 Root `README.md` golden-path table reflects that branching happens at spec. Update the `Spec` row's "What it does" cell to mention `feature/{change-id}` auto-creation
- [x] 7.2 Root `README.md` adds a short subsection (under "How it works" or similar) titled "Branching" describing the three layers and `.spwf/branch.yaml` overrides
- [x] 7.3 `plugins/spwf/README.md` reflects the new branching contract — at least the `spec`, `build`, `pr-create`, `branch-rescue` rows are updated
- [x] 7.4 Both READMEs (root + `plugins/spwf/`) add a one-line cross-link to `_shared/branch-management.md § config schema` near the install or config sections. The schema itself is delivered in 1.2; this task is the cross-link only
- [x] 7.5 `plugins/spwf/.claude-plugin/plugin.json` version bumped 1.14.0 → 1.15.0. Bump lands in the Phase 7 commit, after Phases 1–6 are structurally complete

## Phase 8 — Acceptance (full lifecycle)

> **Sandbox protocol for Phase 8 (and 2.6).** Every smoke test in this phase runs destructive git operations (`reset --hard`, mass branch moves, force-push surfacing). Each test SHALL be executed in a `git worktree add` scratch worktree (or an equivalent isolated clone), NOT against the live working tree's `main`. Clean up the worktree after each test.

- [ ] 8.1 **Greenfield** — On a fresh feature branch, run `/spwf:capture` → `/spwf:challenge` → `/spwf:spec test-change` from `main`. Verify spec auto-branched to `feature/test-change`. Run `/spwf:build` and confirm Phase 0 passes silently. Confirm at no point did a commit land on `main`
- [ ] 8.2 **Legacy / mid-flow** — Simulate a legacy spec by manually creating `openspec/changes/legacy-test/` and committing a spec on main without branching. Run `/spwf:build legacy-test`. Verify Phase 0 halts with the expected offer. Accept (Y) and verify build proceeds on the new branch
- [ ] 8.3 **Rescue** — Simulate the failure mode: 5 commits on main with an active change. Run `/spwf:pr-create`. Verify Check 1 presents the rescue, runs local moves, surfaces force-push as manual step, and pr-create continues to security pre-flight on the new feature branch
- [x] 8.4 **Opt-out** — Set `.spwf/branch.yaml: enforce: false`. Run `/spwf:spec opt-out-test` from `main`. Verify no branching occurs — spec commit lands on `main`. Restore `enforce: true` after the test
- [x] 8.5 **Standalone rescue** — Outside the pr-create flow, with 3 commits on main and an active change, invoke `/spwf:branch-rescue` directly. Verify the same outcome as 8.3
- [x] 8.6 **Branch-drift detection** — With the same state as 8.3 (commits on main, no feature branch), run `/spwf:wfstatus`. Verify the P2 branch-drift warning surfaces and points at `/spwf:branch-rescue`
- [x] 8.7 **Failure modes** — exercise three known failure paths: (a) uncommitted changes block auto-branch — confirm Phase 1.4's "uncommitted changes halt" message fires; (b) rescue base detection finds no matching spec commit — confirm the manual-confirm fallback (2.3) prompts the user, uses their SHA, and runs only after confirmation; (c) branch-already-exists divergence — confirm "branch exists but is behind HEAD" halt from 3.7 fires when the state is set up to trigger it

## Phase 9 — Layer 4: pr-create → close handoff (Decision 10)

> **Folded-in scope.** Fixes the downstream report where an agent "closed the ticket" without running the retrospective. Independent of Phases 1–8. See [`design.md`](./design.md) Decision 10.

- [x] 9.1 `plugins/spwf/skills/pr-create/SKILL.md` final report (after the PR/MR URL is printed) gains a "Next step" block naming `/spwf:close` as the canonical post-merge action. The block states that close runs the retrospective (learn-from-mistakes, spec audit, doc-lint, workflow-lint, recap) and then archives the change + transitions the tracker ticket
- [x] 9.2 The Next-step block explicitly states that "merge and close the ticket" is NOT complete until `/spwf:close` runs — the retrospective is part of close, not an optional extra. Exact wording documented in the skill body
- [x] 9.3 pr-create SHALL NOT invoke `/spwf:close` automatically — it points forward only (close is a human-gated destructive final phase; pr-create does not even merge). This non-action is stated in the skill body so a future author does not "helpfully" auto-chain it
- [x] 9.4 `plugins/spwf/skills/workflow-lint/SKILL.md` adds a coherence check: every phase orchestrator skill names its successor phase in its terminal output. The check fires P2 if `pr-create` lacks a forward pointer to `close`. Documented in workflow-lint's check list
- [x] 9.5 `plugins/spwf/README.md` pr-create row (and root `README.md` golden-path pr-create row) note that pr-create ends by pointing at `/spwf:close`. (Cross-link only; the block itself is delivered in 9.1)
- [x] 9.6 Smoke — run `/spwf:pr-create` to completion against a sandbox PR: verify the output ends with the `/spwf:close` next-step block, and that the block names the retrospective. Verify close was NOT auto-invoked

## Phase 10 — Spec carries the tracker ticket into the proposal (Decision 11)

> **Folded-in scope.** Makes the archived OpenSpec change self-describing about its tracker ticket. Independent of Phases 1–9. See [`design.md`](./design.md) Decision 11.

- [x] 10.1 `plugins/spwf/skills/spec/SKILL.md` Step 1 reads the `ticket:` field from the ideation file frontmatter (written by `capture` / `issue-to-task`) when present, and carries it forward to Step 3
- [x] 10.2 Step 3's `proposal.md` template gains a `**Tracker**: {ticket}` line in the header block (alongside `**Change ID**` / `**Status**` / `**Created**` / `**Source**`), populated from the ideation `ticket:` when present
- [x] 10.3 When the ideation file has no `ticket:` field, spec SHALL omit the `**Tracker**:` line entirely — it SHALL NOT invent a ticket and SHALL NOT prompt for one. Documented in the step body
- [x] 10.4 `plugins/spwf/skills/close/SKILL.md` Step 1 ticket resolution gains a fallback: when the todo file has no `ticket:`, read `**Tracker**:` from `openspec/changes/{change-id}/proposal.md`. Todo file remains the primary source; proposal is the fallback
- [x] 10.5 Smoke — (a) capture a tracker ticket (`ticket:` present) → `/spwf:spec`: verify `proposal.md` carries `**Tracker**: {id}`; (b) `new-task` freeform (no `ticket:`) → `/spwf:spec`: verify `proposal.md` has no `**Tracker**:` line; (c) delete the `ticket:` from the todo and run `/spwf:close`: verify it resolves the ticket from the proposal fallback
