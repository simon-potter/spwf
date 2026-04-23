# Tasks: add-plugin-marketplace

> **Authoritative Reference:** [`todo/Marketplace_setup.md`](../../../todo/Marketplace_setup.md) — consult for exact file contents, JSON schemas, allowed-tools configuration, and skill-by-skill details.

## Phase 0 — Repo Initialisation

- [ ] 0.1 Write `README.md` at repo root (what the marketplace is, who it is for, prerequisites section, single install command pair)
- [ ] 0.2 Create `.claude-plugin/` directory at repo root
- [ ] 0.3 Create `plugins/` directory at repo root

## Phase 1 — Marketplace Catalog

- [ ] 1.1 Create `.claude-plugin/marketplace.json` with the schema from `todo/Marketplace_setup.md → Phase 1` (name: `simon-marketplace`, three plugins: workflow-core, workflow-tools, workflow-agents, pluginRoot: `./plugins`)
- [ ] 1.2 Validate the JSON is well-formed

## Phase 2 — `workflow-core` Plugin (8 skills)

- [ ] 2.1 Create `plugins/workflow-core/.claude-plugin/plugin.json`
- [ ] 2.2 Create `plugins/workflow-core/README.md` describing the seven-phase coverage and agent-skills attribution policy
- [ ] 2.3 Scaffold `plugins/workflow-core/skills/` with subdirectories for all 8 skills: task-to-spec, plan, build, test-creator, test, pr-reviewer, simplify, ship

**skill: task-to-spec** (original — renamed from `ideation-to-openspec`)
- [ ] 2.4 Copy `~/.claude/skills/ideation-to-openspec/SKILL.md` into `plugins/workflow-core/skills/task-to-spec/SKILL.md`
- [ ] 2.5 Update frontmatter: rename, add phase annotation, set `disable-model-invocation: true`, set `allowed-tools: [Read, Write, Bash]`
- [ ] 2.6 Add openspec-directory check at top of skill body — halts with "OpenSpec not initialised. Run: openspec init" if `openspec/` is missing

**skill: plan** (seeded from `planning-and-task-breakdown`)
- [ ] 2.7 Write `plugins/workflow-core/skills/plan/SKILL.md` — reads and validates `openspec/changes/{change-id}/tasks.md`, surfaces task list for review before /build starts
- [ ] 2.8 Add attribution comment in frontmatter: `# Source: https://github.com/addyosmani/agent-skills — MIT licence`
- [ ] 2.9 Set `allowed-tools: [Read, Write]`, `disable-model-invocation: true`

**skill: build** (seeded from `incremental-implementation`)
- [ ] 2.10 Write `plugins/workflow-core/skills/build/SKILL.md` — locates first unchecked item in OpenSpec tasks.md, implements it, checks it off on completion; references opsx:* skills as the implementation vehicle
- [ ] 2.11 Add attribution comment
- [ ] 2.12 Set `allowed-tools: [Read, Edit, Write, Bash]`, `disable-model-invocation: true`

**skill: test-creator** (original — new skill, writes tests)
- [ ] 2.13 Write `plugins/workflow-core/skills/test-creator/SKILL.md` — reads code, generates test file covering behaviour scenarios (not line %); runs to confirm they pass
- [ ] 2.14 Set `allowed-tools: [Read, Write, Bash, Grep, Glob]`, `disable-model-invocation: true`

**skill: test** (seeded from `test-driven-development` — runs defined tests)
- [ ] 2.15 Write `plugins/workflow-core/skills/test/SKILL.md` — runs the existing test suite, reports pass/fail, stops on first failure
- [ ] 2.16 Add attribution comment
- [ ] 2.17 Set `allowed-tools: [Read, Bash]`, `disable-model-invocation: true`

**skill: pr-reviewer** (original — extends `code-review-excellence`)
- [ ] 2.18 Copy `~/.claude/skills/code-review-excellence/SKILL.md` into `plugins/workflow-core/skills/pr-reviewer/SKILL.md`
- [ ] 2.19 Extend with PR-specific context: reads `$ARGUMENTS` as PR reference, halts with usage hint if omitted, uses `gh pr view` / `gh pr diff` to fetch PR data
- [ ] 2.20 Set `allowed-tools: [Read, Bash]` (gh pr *), `disable-model-invocation: true`

**skill: simplify** (seeded from `code-simplification`)
- [ ] 2.21 Write `plugins/workflow-core/skills/simplify/SKILL.md` — identifies candidates for removal or clarification across changed files; never touches tests
- [ ] 2.22 Add attribution comment
- [ ] 2.23 Set `allowed-tools: [Read, Edit, Grep, Glob]`, `disable-model-invocation: true`

**skill: ship** (seeded from `git-workflow-and-versioning` — PR creation only)
- [ ] 2.24 Write `plugins/workflow-core/skills/ship/SKILL.md` — creates a PR via `gh pr create`; does not deploy; CI/CD owns deployment
- [ ] 2.25 Add attribution comment
- [ ] 2.26 Set `allowed-tools: [Read, Bash]` (gh pr create), `disable-model-invocation: true`

## Phase 3 — `workflow-tools` Plugin (6 skills)

- [ ] 3.1 Create `plugins/workflow-tools/.claude-plugin/plugin.json`
- [ ] 3.2 Create `plugins/workflow-tools/README.md` describing the extended phases and cross-cutting skills
- [ ] 3.3 Scaffold `plugins/workflow-tools/skills/` with subdirectories for all 6 skills

**skill: issue-to-task** (heavily adapted from `jira-to-openspec`)
- [ ] 3.4 Copy `~/.claude/skills/jira-to-openspec/SKILL.md` as starting point
- [ ] 3.5 Strip all OpenSpec generation phases — output is a `todo/{slug}.md` ideation file only (format: YAML frontmatter + Context + What we know + Open questions + Rough scope)
- [ ] 3.6 Preserve Jira fetch and content extraction logic
- [ ] 3.7 Set `allowed-tools: [Read, Write, mcp__atlassian__*]`, `disable-model-invocation: true`

**skill: new-task** (new — scratch capture, no Jira)
- [ ] 3.8 Write `plugins/workflow-tools/skills/new-task/SKILL.md` — asks user for idea description interactively; produces same ideation file format as `issue-to-task`
- [ ] 3.9 Set `allowed-tools: [Read, Write]`, `disable-model-invocation: true`

**skill: grill-me** (direct copy from `~/.claude/skills/grill-me`, minor adaptation)
- [ ] 3.10 Copy `~/.claude/skills/grill-me/SKILL.md` into `plugins/workflow-tools/skills/grill-me/SKILL.md`
- [ ] 3.11 Adapt to accept file path as `$ARGUMENTS` — if no argument, defaults to most recent file in `todo/`
- [ ] 3.12 Set `disable-model-invocation: true`, `allowed-tools: [Read, Grep, Glob]`

**skill: doc-lint** (direct copy)
- [ ] 3.13 Copy `~/.claude/skills/doc-lint/SKILL.md` into `plugins/workflow-tools/skills/doc-lint/SKILL.md` — no changes
- [ ] 3.14 Set `disable-model-invocation: true`, `allowed-tools: [Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion]`

**skill: agent-optimise** (new — synthesises claude-validate + agent-architect concerns)
- [ ] 3.15 Write `plugins/workflow-tools/skills/agent-optimise/SKILL.md` — audits both project `.claude/` and personal `~/.claude/`; covers CLAUDE.md scope/length, agent descriptions, skill frontmatter, settings.json conflicts; produces prioritised fix list
- [ ] 3.16 Set `disable-model-invocation: true`, `allowed-tools: [Read, Glob, Grep, Bash]`

**skill: learn-from-mistakes** (renamed from `commits-to-knowledge`)
- [ ] 3.17 Copy `~/.claude/skills/commits-to-knowledge/SKILL.md` into `plugins/workflow-tools/skills/learn-from-mistakes/SKILL.md` — rename only, no functional changes
- [ ] 3.18 Set `disable-model-invocation: true`, `allowed-tools: [Read, Glob, Grep, Bash, Edit, Write]`

## Phase 4 — `workflow-agents` Plugin (8 agents)

- [ ] 4.1 Create `plugins/workflow-agents/.claude-plugin/plugin.json`
- [ ] 4.2 Create `plugins/workflow-agents/README.md` describing each agent's phase and model assignment
- [ ] 4.3 Scaffold `plugins/workflow-agents/agents/` directory

- [ ] 4.4 Write `capturer.md` — Haiku, tools: [Read, Write, MCP Atlassian], fetches and summarises only — does not interpret or suggest implementation
- [ ] 4.5 Write `specifier.md` — Sonnet, tools: [Read, Write, Bash (openspec)], asks clarifying questions, writes spec artefacts, refuses to suggest implementation
- [ ] 4.6 Write `planner.md` — Haiku, tools: [Read, Write], reads spec, produces atomic task list, validates each task is independently testable
- [ ] 4.7 Write `builder.md` — Sonnet, tools: [All], reads current task from plan, implements it, stops at task boundary
- [ ] 4.8 Write `tester.md` — Sonnet, tools: [Read, Write, Bash], reads code, writes tests, runs suite, reports pass/fail
- [ ] 4.9 Write `reviewer.md` — Haiku, tools: [Read, Bash (gh pr *)], reads diff/PR, produces structured review — no edits, one Write for report
- [ ] 4.10 Write `simplifier.md` — Haiku, tools: [Read, Edit, Glob, Grep], identifies candidates for removal — does not touch tests
- [ ] 4.11 Write `shipper.md` — Haiku, tools: [Read, Bash], runs deploy checklist, gates on all checks passing — does not deploy

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
- [ ] 6.3 Verify all 8 `workflow-core` skills are invocable via `/workflow-core:<name>`
- [ ] 6.4 Verify all 6 `workflow-tools` skills are invocable via `/workflow-tools:<name>`
- [ ] 6.5 Verify all 8 agents appear in `/agents` with correct trigger descriptions
- [ ] 6.6 Run full extended lifecycle on a toy task:
  - `/workflow-tools:new-task` → ideation file created
  - `/workflow-tools:grill-me todo/{file}.md` → file challenged
  - `/workflow-core:task-to-spec todo/{file}.md` → OpenSpec generated
  - `/workflow-core:plan` → task list surfaces
  - opsx skills + `/workflow-core:test-creator` → slice implemented, tests written
  - `/workflow-core:test` → tests pass
  - `/workflow-core:pr-reviewer <PR>` → review produced
  - `/workflow-core:simplify` → code cleaned up
  - `/workflow-core:ship` → PR created
  - `/workflow-tools:learn-from-mistakes` → learnings extracted
- [ ] 6.7 Test `/reload-plugins` after an edit — confirm no restart needed

## Phase 7 — GitHub Hosting and Distribution

- [ ] 7.1 Push `main` branch to `Academy-Plus/plugin-marketplace-simon` (private)
- [ ] 7.2 Tag `v0.1.0` once all Phase 6 acceptance criteria pass
- [ ] 7.3 Test install on a second machine:
  - `/plugin marketplace add Academy-Plus/plugin-marketplace-simon`
  - `/plugin install workflow-core@simon-marketplace`
  - `/plugin install workflow-tools@simon-marketplace`
  - `/plugin install workflow-agents@simon-marketplace`
- [ ] 7.4 Test update path: make a change, push, run `/plugin marketplace update simon-marketplace` — confirm change picks up
