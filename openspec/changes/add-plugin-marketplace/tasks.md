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

- [ ] 5.1 Confirm each copied/adapted skill behaves identically to its source by running it on a known input
- [ ] 5.2 Once validated: archive (do not delete) the following personal skills from `~/.claude/skills/`:
  - `grill-me/` → archive after `workflow-tools:grill-me` validated
  - `ideation-to-openspec/` → archive after `workflow-core:task-to-spec` validated
  - `commits-to-knowledge/` → archive after `workflow-tools:learn-from-mistakes` validated
  - `code-review-excellence/` → archive after `workflow-core:pr-reviewer` validated
  - `doc-lint/` → archive after `workflow-tools:doc-lint` validated
  - `jira-to-openspec/` → archive after `workflow-tools:issue-to-task` validated

## Phase 6 — Local Testing

- [ ] 6.1 Load marketplace locally: `/plugin marketplace add ./`
- [ ] 6.2 Install all three plugins:
  - `/plugin install workflow-core@simon-marketplace`
  - `/plugin install workflow-tools@simon-marketplace`
  - `/plugin install workflow-agents@simon-marketplace`
- [ ] 6.3 Verify all 11 `workflow-core` skills are invocable via `/workflow-core:<name>` — including both atomic skills (`incremental-implementation`, `test-runner`, `debug-recovery`) and orchestrators (`build`, `test`)
- [ ] 6.4 Verify all 6 `workflow-tools` skills are invocable via `/workflow-tools:<name>`
- [ ] 6.5 Verify all 8 agents appear in `/agents` with correct trigger descriptions
- [ ] 6.6 Run full extended lifecycle on a toy task:
  - `/workflow-tools:new-task` → ideation file created
  - `/workflow-tools:challenge todo/{file}.md` → file challenged
  - `/workflow-core:spec todo/{file}.md` → OpenSpec generated
  - `/workflow-core:approve-plan` → task list reviewed and approved
  - `/workflow-core:build` → write-tests (Red) → opsx:apply (Green) → run-tests (Verify) → opsx:verify (spec sign-off)
  - `/workflow-core:pr-review <PR>` → review produced
  - `/workflow-core:simplify` → code cleaned up
  - `/workflow-core:pr-create` → PR created
  - `/workflow-tools:learn-from-mistakes` → learnings extracted
- [ ] 6.7 Test `/reload-plugins` after an edit — confirm no restart needed

## Phase 7 — GitHub Hosting and Distribution

- [ ] 7.1 Push `main` branch to `Academy-Plus/spwf` (private)
- [ ] 7.2 Tag `v0.1.0` once all Phase 6 acceptance criteria pass
- [ ] 7.3 Test install on a second machine:
  - `/plugin marketplace add Academy-Plus/spwf`
  - `/plugin install workflow-core@simon-marketplace`
  - `/plugin install workflow-tools@simon-marketplace`
  - `/plugin install workflow-agents@simon-marketplace`
- [ ] 7.4 Test update path: make a change, push, run `/plugin marketplace update simon-marketplace` — confirm change picks up
