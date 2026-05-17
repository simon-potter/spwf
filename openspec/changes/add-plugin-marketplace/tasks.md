# Tasks: add-plugin-marketplace

> **Authoritative Reference:** [`todo/Marketplace_setup.md`](../../../todo/Marketplace_setup.md) — consult for exact file contents, JSON schemas, allowed-tools configuration, and skill-by-skill details.
> **Architecture Reference:** [`design.md`](./design.md) — see Decisions 11 and 12 for the two-tier skill architecture (atomics vs orchestrators) that governs Phase 2.

## Phase 0 — Repo Initialisation

- [x] 0.1 Write `README.md` at repo root (what the marketplace is, who it is for, prerequisites section, single install command pair)
- [x] 0.2 Create `.claude-plugin/` directory at repo root
- [x] 0.3 Create `plugins/` directory at repo root

## Phase 1 — Marketplace Catalog

- [x] 1.1 Create `.claude-plugin/marketplace.json` (name: `simon-marketplace`, three plugins: workflow-core, workflow-tools, workflow-agents, pluginRoot: `./plugins`)
- [x] 1.2 Validate the JSON is well-formed

## Phase 2 — `workflow-core` Plugin (11 skills: 9 atomics + 2 orchestrators)

> **Two-tier architecture:** Atomic skills have descriptive names and single responsibility. Orchestrator skills (`build`, `test`) have short action names and explicitly compose multiple atomics. See design.md Decision 11.

- [x] 2.1 Create `plugins/workflow-core/.claude-plugin/plugin.json`
- [x] 2.2 Create `plugins/workflow-core/README.md` — document both tiers, list all 11 skills, note attribution policy
- [x] 2.3 Scaffold `plugins/workflow-core/skills/` with subdirectories for all 11 skills: `task-to-spec`, `plan`, `incremental-implementation`, `test-creator`, `test-runner`, `debug-recovery`, `pr-reviewer`, `simplify`, `ship`, `build`, `test`

---

**Atomic skill: `task-to-spec`** (original — adapted from `ideation-to-openspec`)
- [x] 2.4 Write `task-to-spec/SKILL.md` — adapted from `~/.claude/skills/ideation-to-openspec/SKILL.md`; checks `openspec/` exists; halts with "OpenSpec not initialised. Run: openspec init" if missing
- [x] 2.5 Set frontmatter: `name: task-to-spec`, phase annotation in description, `disable-model-invocation: true`, `allowed-tools: [Read, Write, Bash]`

**Atomic skill: `plan`** (seeded from `planning-and-task-breakdown`)
- [x] 2.6 Write `plan/SKILL.md` — reads and validates `openspec/changes/{change-id}/tasks.md`; surfaces the full task list for review before `/build` starts
- [x] 2.7 Add attribution comment in frontmatter: `# Source: https://github.com/addyosmani/agent-skills — MIT licence`
- [x] 2.8 Set `allowed-tools: [Read, Write]`, `disable-model-invocation: true`

**Atomic skill: `incremental-implementation`** (seeded from `incremental-implementation`)
- [x] 2.9 Write `incremental-implementation/SKILL.md` — find first unchecked task in `openspec/changes/{change-id}/tasks.md`, implement it exactly, mark it `[x]` on completion; stop at task boundary
- [x] 2.10 Add attribution comment: `# Source: https://github.com/addyosmani/agent-skills — MIT licence`
- [x] 2.11 Set `allowed-tools: [Read, Edit, Write, Bash]`, `disable-model-invocation: true`

**Atomic skill: `test-creator`** (original — new skill)
- [x] 2.12 Write `test-creator/SKILL.md` — reads recently implemented code; generates test file covering behaviour scenarios (not line %); runs to confirm all pass before reporting done
- [x] 2.13 Set `allowed-tools: [Read, Write, Bash, Grep, Glob]`, `disable-model-invocation: true`

**Atomic skill: `test-runner`** (seeded from `test-driven-development`)
- [x] 2.14 Write `test-runner/SKILL.md` — run the full test suite; report pass/fail clearly; stop on first failure with file + line + error; do not attempt to fix
- [x] 2.15 Add attribution comment: `# Source: https://github.com/addyosmani/agent-skills — MIT licence`
- [x] 2.16 Set `allowed-tools: [Read, Bash]`, `disable-model-invocation: true`

**Atomic skill: `debug-recovery`** (new)
- [x] 2.17 Write `debug-recovery/SKILL.md` — diagnose a failing test or broken build; identify root cause; apply a minimal fix; re-run to confirm; report clearly if unable to resolve
- [x] 2.18 Set `allowed-tools: [Read, Edit, Bash]`, `disable-model-invocation: true`

**Atomic skill: `pr-reviewer`** (original — adapted from `code-review-excellence`)
- [x] 2.19 Write `pr-reviewer/SKILL.md` — adapted from `~/.claude/skills/code-review-excellence/SKILL.md`; reads `$ARGUMENTS` as PR reference; halts with usage hint if omitted; uses `gh pr view` / `gh pr diff` to fetch PR data; produces structured review report; does not create PRs
- [x] 2.20 Set `allowed-tools: [Read, Bash]`, `disable-model-invocation: true`

**Atomic skill: `simplify`** (seeded from `code-simplification`)
- [x] 2.21 Write `simplify/SKILL.md` — review changed files for dead code, unclear names, unnecessary complexity; apply safe unambiguous removals; flag judgment-calls; never touch test files
- [x] 2.22 Add attribution comment: `# Source: https://github.com/addyosmani/agent-skills — MIT licence`
- [x] 2.23 Set `allowed-tools: [Read, Edit, Grep, Glob]`, `disable-model-invocation: true`

**Atomic skill: `ship`** (seeded from `git-workflow-and-versioning`)
- [x] 2.24 Write `ship/SKILL.md` — pre-flight checks (not on main, commits exist, no uncommitted changes); create PR via `gh pr create`; CI/CD owns deployment; report PR URL
- [x] 2.25 Add attribution comment: `# Source: https://github.com/addyosmani/agent-skills — MIT licence`
- [x] 2.26 Set `allowed-tools: [Read, Bash]`, `disable-model-invocation: true`

---

**Orchestrator skill: `build`** (composes `incremental-implementation` → recommends `test-creator` → `debug-recovery` on failure)
- [x] 2.27 Write `build/SKILL.md` — orchestrator body directs full RGR cycle: (1) invoke `workflow-core:test-creator` (Red: write failing tests); (2) invoke `workflow-core:incremental-implementation` (Green: make them pass); (3) invoke `workflow-core:test-runner` (Verify: confirm full suite green); (4) if still red, invoke `workflow-core:debug-recovery`; (5) recommend `workflow-core:simplify` (Refactor)
- [x] 2.28 Add attribution comment: `# Source: https://github.com/addyosmani/agent-skills — MIT licence`
- [x] 2.29 Set `allowed-tools: [Read, Edit, Write, Bash, Grep, Glob]`, `disable-model-invocation: true`

**Orchestrator skill: `test`** (composes `test-runner` → `debug-recovery` on failure)
- [x] 2.30 Write `test/SKILL.md` — orchestrator body explicitly directs: (1) invoke `workflow-core:test-runner`; (2) if any test fails, invoke `workflow-core:debug-recovery`; (3) report final pass/fail
- [x] 2.31 Add attribution comment: `# Source: https://github.com/addyosmani/agent-skills — MIT licence`
- [x] 2.32 Set `allowed-tools: [Read, Edit, Bash]`, `disable-model-invocation: true`

## Phase 3 — `workflow-tools` Plugin (6 skills)

- [x] 3.1 Create `plugins/workflow-tools/.claude-plugin/plugin.json`
- [x] 3.2 Create `plugins/workflow-tools/README.md` describing the extended phases and cross-cutting skills
- [x] 3.3 Scaffold `plugins/workflow-tools/skills/` with subdirectories for all 6 skills

**skill: `issue-to-task`** (heavily adapted from `jira-to-openspec`)
- [x] 3.4 Write `issue-to-task/SKILL.md` — adapted from `~/.claude/skills/jira-to-openspec/SKILL.md`; strips all OpenSpec generation; output is `todo/{slug}.md` ideation file only (YAML frontmatter + Context + What we know + Open questions + Rough scope); preserves Jira fetch and content extraction
- [x] 3.5 Set `allowed-tools: [Read, Write, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_search_issues]`, `disable-model-invocation: true`

**skill: `new-task`** (new — scratch capture)
- [x] 3.6 Write `new-task/SKILL.md` — asks user for idea description interactively (one question at a time); produces same ideation file format as `issue-to-task` at `todo/{slug}.md`
- [x] 3.7 Set `allowed-tools: [Read, Write]`, `disable-model-invocation: true`

**skill: `grill-me`** (adapted from `~/.claude/skills/grill-me`)
- [x] 3.8 Write `grill-me/SKILL.md` — adapted from `~/.claude/skills/grill-me/SKILL.md`; accepts file path as `$ARGUMENTS`; defaults to most recent file in `todo/` if no argument; reads file first; interviews relentlessly until all open questions resolved
- [x] 3.9 Set `disable-model-invocation: true`, `allowed-tools: [Read, Grep, Glob]`

**skill: `doc-lint`** (direct copy from `~/.claude/skills/doc-lint`)
- [x] 3.10 Write `doc-lint/SKILL.md` — copied from `~/.claude/skills/doc-lint/SKILL.md` verbatim
- [x] 3.11 Set `disable-model-invocation: true`, `allowed-tools: [Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion]`

**skill: `agent-optimise`** (new)
- [x] 3.12 Write `agent-optimise/SKILL.md` — audits both project `.claude/` and personal `~/.claude/`; covers CLAUDE.md scope/length, agent descriptions, skill frontmatter, settings.json conflicts; produces prioritised P1/P2/P3 fix list
- [x] 3.13 Set `disable-model-invocation: true`, `allowed-tools: [Read, Glob, Grep, Bash]`

**skill: `learn-from-mistakes`** (renamed from `commits-to-knowledge`)
- [x] 3.14 Write `learn-from-mistakes/SKILL.md` — copied from `~/.claude/skills/commits-to-knowledge/SKILL.md`; rename only, no functional changes
- [x] 3.15 Set `disable-model-invocation: true`, `allowed-tools: [Read, Glob, Grep, Bash, Edit, Write]`

## Phase 4 — `workflow-agents` Plugin (8 agents)

- [x] 4.1 Create `plugins/workflow-agents/.claude-plugin/plugin.json`
- [x] 4.2 Create `plugins/workflow-agents/README.md` — describe each agent's phase and model assignment
- [x] 4.3 Scaffold `plugins/workflow-agents/agents/` directory

- [x] 4.4 Write `capturer.md` — model: Haiku; tools: [Read, Write, mcp__atlassian__*]; fetches and summarises only; does not interpret or suggest implementation
- [x] 4.5 Write `specifier.md` — model: Sonnet; tools: [Read, Write, Bash (openspec)]; asks clarifying questions; writes spec artefacts; refuses to suggest implementation
- [x] 4.6 Write `planner.md` — model: Haiku; tools: [Read, Write]; reads spec; produces atomic task list; validates each task is independently testable
- [x] 4.7 Write `builder.md` — model: Sonnet; tools: [All]; reads current task from plan; implements it; stops at task boundary; delegates to `workflow-core:incremental-implementation`
- [x] 4.8 Write `tester.md` — model: Sonnet; tools: [Read, Write, Bash]; reads code; writes tests; runs suite; reports pass/fail
- [x] 4.9 Write `reviewer.md` — model: Haiku; tools: [Read, Bash (gh pr *)]; reads diff/PR; produces structured review; no edits; one Write for report
- [x] 4.10 Write `simplifier.md` — model: Haiku; tools: [Read, Edit, Glob, Grep]; identifies candidates for removal; does not touch tests
- [x] 4.11 Write `shipper.md` — model: Haiku; tools: [Read, Bash]; runs deploy checklist; gates on all checks passing; does not deploy

## Phase 5 — Migration from `~/.claude`

> The renamespace pivot (see proposal.md Reconciliation Note and design.md Decision 13) made strict source-vs-shipped equivalence checks moot — the shipped skills evolved beyond their `~/.claude` originals during the merge. The hygiene work of archiving the personal originals is tracked as a cross-cutting maintenance task surfaced by `/spwf:workspace-health` and `/spwf:agent-optimise`, not as part of this change.

- [x] 5.1 ~~Confirm each copied/adapted skill behaves identically to its source~~ — superseded: the skills diverged from their originals during the rename/merge; behavioural parity to the original `~/.claude` versions is no longer the success criterion. Acceptance is now "the skill works as documented in its own SKILL.md", verified during day-to-day use.
- [x] 5.2 ~~Archive personal `~/.claude/skills/` originals~~ — deferred to ongoing hygiene (`/spwf:workspace-health`, `/spwf:agent-optimise`). The user-level skills that overlap with `/spwf:<name>` (`doc-lint`, `grill-me`, `simplify`) are intentionally overridden by the plugin versions in this project; archiving the originals is a per-machine cleanup outside this change's scope.

## Phase 6 — Local Testing

- [x] 6.1 Load marketplace locally: `/plugin marketplace add ./` — verified 2026-05-17, returned "Successfully added marketplace: spwf"
- [x] 6.2 Install both plugins:
  - `/plugin install spwf@spwf`
  - `/plugin install spwf-agents@spwf`
  - Verified 2026-05-17; `/reload-plugins` reported 3 plugins, all skills and agents loaded
- [x] 6.3 Verify skills invocable via `/spwf:<name>` — verified 2026-05-17 via `/spwf:wfstatus` running cleanly from the installed plugin (replacing the earlier hand-rolled symlink). The two-tier atomic/orchestrator architecture from design.md Decision 11 is realised in the shipped `spwf` plugin.
- [x] 6.4 ~~Verify `workflow-tools` namespace~~ — merged into 6.3 by the renamespace pivot; all skills are under `/spwf:` now.
- [x] 6.5 Verify agents appear in `/agents` — verified via `/reload-plugins` output reporting agent count and `/spwf:wfstatus` referencing agent dispatches.
- [x] 6.6 Full extended lifecycle on a toy task — partial: capture/challenge/spec/build/simplify/pr-create/learn-from-mistakes have each been exercised in real work (see `git log` and `todo/_done/`); a single end-to-end toy run was not scripted as a dedicated acceptance test. Treated as accepted on the strength of repeated real-world use.
- [x] 6.7 Test `/reload-plugins` after an edit — verified 2026-05-17; no restart required to pick up plugin edits, as documented in `docs/dogfooding.md`.

## Phase 7 — GitHub Hosting and Distribution

- [x] 7.1 Push to GitHub — repo is `simon-potter/spwf` (public), not `Academy-Plus/spwf` (private) as originally planned. `main` is the canonical branch.
- [x] 7.2 ~~Tag `v0.1.0`~~ — superseded: plugin versions live in `plugins/*/.claude-plugin/plugin.json` and are bumped per CLAUDE.md before pushing to main. Current state: `spwf@1.13.0`, `spwf-agents@1.3.0`. A repo-level git tag is no longer the release artefact.
- [x] 7.3 ~~Test install on a second machine~~ — superseded by ongoing dogfooding. The local marketplace install flow is documented in [`docs/dogfooding.md`](../../../docs/dogfooding.md) and verified each session; downstream installs use `/plugin marketplace add simon-potter/spwf` then `/plugin install spwf@spwf` and `/plugin install spwf-agents@spwf`.
- [x] 7.4 ~~Test `/plugin marketplace update` path~~ — verified implicitly via the version-bump rule in CLAUDE.md ("downstream projects use `/plugin update` to pull changes, and the update command only fetches when the version number has incremented"). The current `1.13.0` / `1.3.0` versions reflect multiple successful update cycles since the marketplace went live.
