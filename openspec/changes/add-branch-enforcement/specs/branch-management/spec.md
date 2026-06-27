# Spec: branch-management

## ADDED Requirements

### Requirement: Spec auto-creates the feature branch

`/spwf:spec` SHALL ensure the active branch is `feature/{change-id}`
before emitting its commit, whenever `.spwf/branch.yaml: enforce: true`
(the default). The default prefix `feature/` and the default base `main`
SHALL be overridable via `.spwf/branch.yaml: prefix:` and `base:`
respectively.

#### Scenario: Spec from base branch

- **WHEN** the working tree is on the base branch (default `main`) and
  `/spwf:spec {change-id}` runs
- **AND** `.spwf/branch.yaml` is absent or `enforce: true`
- **AND** `.spwf/branch.yaml: auto_branch` is `always` (default) or absent
- **THEN** the skill SHALL run `git checkout -b feature/{change-id}` before
  the spec commit
- **AND** the spec commit SHALL land on `feature/{change-id}`, not on the
  base branch
- **AND** a single visible confirmation line `✓ Branched to feature/{change-id} (auto)`
  SHALL be emitted

#### Scenario: Spec from base branch with target branch already existing

- **WHEN** the working tree is on the base branch and `feature/{change-id}`
  already exists (e.g. from an interrupted prior spec attempt)
- **AND** `/spwf:spec {change-id}` runs with default config
- **THEN** the skill SHALL run `git checkout feature/{change-id}` (NOT
  `git checkout -b`) and proceed with the spec commit on the existing
  branch
- **AND** SHALL emit `✓ Switched to existing feature/{change-id}` as the
  confirmation line
- **AND** if the existing branch is behind HEAD (the base branch has
  commits not present on the branch tip), the skill SHALL halt with
  "branch exists but is behind HEAD — manual merge or rebase required"
  rather than auto-merging

#### Scenario: Spec already on the target branch

- **WHEN** the working tree is already on `feature/{change-id}` and
  `/spwf:spec {change-id}` runs
- **THEN** the skill SHALL NOT attempt any branch operation
- **AND** the spec commit SHALL land on the existing branch
- **AND** a single visible confirmation line `✓ Already on feature/{change-id}`
  SHALL be emitted

#### Scenario: Spec from a different feature branch

- **WHEN** the working tree is on a feature branch that is neither the
  base nor `feature/{change-id}`
- **AND** `/spwf:spec {change-id}` runs
- **THEN** the skill SHALL ask one question: "You're on `{current}`, not
  `{base}` and not `feature/{change-id}`. Spec on `{current}` or create
  `feature/{change-id}`?"
- **AND** SHALL proceed based on the user's answer
- **AND** SHALL NOT proceed silently — exactly one question, exactly one
  answer required

#### Scenario: Spec with auto_branch ask

- **WHEN** `.spwf/branch.yaml: auto_branch: ask` is set
- **AND** `/spwf:spec {change-id}` runs from the base branch
- **THEN** the skill SHALL prompt before branching: "Create branch
  `feature/{change-id}` from `{base}`? [Y/n]"
- **AND** SHALL respect the user's response (Y / enter → branch; n → stay
  on base, proceed with the spec commit)

#### Scenario: Spec with auto_branch never

- **WHEN** `.spwf/branch.yaml: auto_branch: never` is set
- **AND** `/spwf:spec {change-id}` runs from the base branch
- **THEN** the skill SHALL NOT attempt to branch
- **AND** the spec commit SHALL land on the base branch
- **AND** no warning SHALL be emitted (the user opted out explicitly)

---

### Requirement: Build halts on base branch with an active change

`/spwf:build` SHALL refuse to run on the base branch when an active
OpenSpec change exists, unless `.spwf/branch.yaml: enforce: false`.

#### Scenario: Build from base branch with active change

- **WHEN** the working tree is on the base branch
- **AND** `openspec/changes/{change-id}/` exists with incomplete tasks
- **AND** `/spwf:build {change-id}` runs
- **AND** `.spwf/branch.yaml: enforce: true` (the default)
- **THEN** Phase 0 of the build skill SHALL halt before Phase 1
- **AND** SHALL display: "You're on `{base}` with active change
  `{change-id}`. Build will commit per task — that pollutes `{base}`.
  Switch to `feature/{change-id}` (I'll create it from HEAD)? [Y/n]"
- **AND** on Y / enter: SHALL run `git checkout -b feature/{change-id}`
  (or `git checkout feature/{change-id}` if it exists ahead of HEAD)
- **AND** on n: SHALL halt with "Build cancelled — set
  `.spwf/branch.yaml: enforce: false` to commit on `{base}` intentionally"

#### Scenario: Build from feature branch matching the change-id

- **WHEN** the working tree is on `feature/{change-id}` and
  `/spwf:build {change-id}` runs
- **THEN** Phase 0 SHALL pass silently
- **AND** Phase 1 (write-tests) SHALL begin without further prompts

#### Scenario: Build with enforce false

- **WHEN** `.spwf/branch.yaml: enforce: false` is set
- **AND** `/spwf:build {change-id}` runs from the base branch
- **THEN** Phase 0 SHALL skip silently and Phase 1 SHALL begin
- **AND** the build SHALL commit on the base branch as today

---

### Requirement: PR-create offers automated rescue

`/spwf:pr-create` SHALL present an automated rescue offer (rather than
halting with a bare error) when it detects the failure state: on the
base branch, commits ahead of `origin/{base}`, and an active OpenSpec
change exists.

#### Scenario: Rescue offer when commits leaked to base

- **WHEN** the working tree is on the base branch
- **AND** `git log {base}..HEAD --oneline` is non-empty (≥ 1 commit ahead
  of `origin/{base}`)
- **AND** `openspec/changes/{change-id}/` exists
- **AND** `/spwf:pr-create` runs
- **THEN** Check 1 SHALL present a rescue plan with three numbered steps,
  the change-id, the resolved pre-spec base commit, and a final
  manual-step note for the force-push
- **AND** SHALL ask "Proceed with rescue? [Y/n]"
- **AND** on Y / enter: SHALL delegate to `/spwf:branch-rescue` for the
  three local-only operations
- **AND** on completion: SHALL continue into Step 1b (security
  pre-flight) on the newly-created `feature/{change-id}` branch
- **AND** SHALL surface as plain text (not auto-execute): "Local main is
  now diverged from origin/main. Push when ready: `git push --force-with-lease origin main`"

#### Scenario: Rescue declined

- **WHEN** the rescue offer is presented and the user responds n
- **THEN** pr-create SHALL halt with the legacy message ("Cannot ship
  from main branch. Create a feature branch first.") so users who
  prefer manual handling are not surprised by silent skipping

---

### Requirement: branch-rescue skill is callable standalone

A standalone skill `/spwf:branch-rescue` SHALL expose the rescue
operation for ad-hoc use outside the pr-create flow.

#### Scenario: Standalone rescue

- **WHEN** the user invokes `/spwf:branch-rescue` from the base branch
  with commits ahead of `origin/{base}` and an active OpenSpec change
- **THEN** the skill SHALL identify the change-id via `openspec list`
- **AND** SHALL identify the pre-spec base commit via
  `git log {base} --grep "^spec: add OpenSpec change ${change-id}" --format=%H | head -1` followed by `git rev-parse ${commit}^`
- **AND** SHALL run `git checkout -b feature/{change-id}` from current HEAD
- **AND** SHALL run `git checkout {base} && git reset --hard {pre-spec-commit}`
- **AND** SHALL print the force-push command for the user to run manually
- **AND** SHALL NOT execute `git push --force` automatically

#### Scenario: Rescue base detection falls back to manual confirm

- **WHEN** the rescue skill runs and
  `git log {base} --grep "^spec: add OpenSpec change ${change-id}"`
  returns no match
- **THEN** the skill SHALL display the last 20 commits via `git log {base} --oneline | head -20`
- **AND** SHALL prompt the user to enter the SHA of the pre-spec base
  commit
- **AND** SHALL proceed using the user-supplied SHA after a confirmation prompt
- **AND** SHALL NOT silently pick a fallback commit

#### Scenario: Rescue refuses with no active change

- **WHEN** the rescue skill runs and no active OpenSpec change is found
- **THEN** the skill SHALL halt with "No active OpenSpec change found — nothing to rescue"
- **AND** SHALL NOT modify any branch

---

### Requirement: Configurable opt-out via .spwf/branch.yaml

`.spwf/branch.yaml` SHALL accept four fields, each with a default that
preserves the new enforcement behaviour:

| Field | Type | Default | Effect when changed |
|---|---|---|---|
| `prefix` | string | `feature/` | Overrides the branch-name prefix used throughout |
| `base` | string | `main` | Overrides the base branch (e.g. `master`, `develop`) |
| `auto_branch` | enum | `always` | `ask` prompts before branching; `never` skips Layer 1 entirely (Layer 2 still catches) |
| `enforce` | bool | `true` | `false` bypasses all three layers — workflow behaves as pre-change baseline |

#### Scenario: enforce false bypasses all layers

- **WHEN** `.spwf/branch.yaml: enforce: false`
- **AND** any of `/spwf:spec`, `/spwf:build`, `/spwf:pr-create` runs
- **THEN** none of Layer 1 / 2 / 3 SHALL fire
- **AND** the skill SHALL behave identically to the pre-change baseline
- **AND** no warning SHALL be emitted (the user opted out explicitly)

#### Scenario: base override targets a non-main branch

- **WHEN** `.spwf/branch.yaml: base: develop`
- **AND** the workflow runs against a project using `develop` as the
  integration branch
- **THEN** all three layers SHALL treat `develop` as the base — auto-branch
  fires when on `develop`; build's Phase 0 fires when on `develop`;
  pr-create's rescue offer fires when on `develop`

#### Scenario: prefix override changes branch naming

- **WHEN** `.spwf/branch.yaml: prefix: spwf/`
- **AND** spec auto-branches for change-id `foo`
- **THEN** the resulting branch SHALL be `spwf/foo`, not `feature/foo`

---

### Requirement: Capture's Step 0 note is truthful

`/spwf:capture` SHALL update its Step 0 git-context soft note (currently
"capture writes ideation only; spec or build will branch") so that the
"branch" promise it makes is honoured by the skill named in the note.

#### Scenario: Capture soft note matches reality

- **WHEN** `/spwf:capture` runs on the base branch
- **AND** `.spwf/branch.yaml: enforce: true` (the default)
- **THEN** the soft note SHALL read "spec will branch
  (or run /spwf:branch-rescue if commits already on main)"
- **AND** SHALL NOT promise behaviour that no skill provides

---

### Requirement: wfstatus flags branch drift

`/spwf:wfstatus` SHALL detect and surface the failure state this change
prevents — when an active OpenSpec change has commits accumulating on
the base branch instead of on its feature branch.

#### Scenario: Drift surfaced as P2 warning

- **WHEN** `openspec/changes/{change-id}/` exists with incomplete tasks
- **AND** `feature/{change-id}` does not exist OR the current branch is
  not `feature/{change-id}`
- **AND** `git log origin/{base}..{base} --oneline` returns ≥ 1 commit
- **AND** at least one of those commits touches a path matching the
  affected areas listed in `openspec/changes/{change-id}/proposal.md`
- **THEN** `/spwf:wfstatus` SHALL emit a P2 warning:
  "⚠ Branch drift — change `{change-id}` may be committing to `{base}`.
   Run `/spwf:branch-rescue` to move commits."

#### Scenario: No drift when working tree is on the expected branch

- **WHEN** the current branch is `feature/{change-id}` and the change is
  active
- **THEN** `/spwf:wfstatus` SHALL NOT emit a drift warning regardless of
  commit volume on the feature branch
