# Plugin Marketplace Setup Plan

> From empty repo to a working Claude Code plugin marketplace, installable as a single source of workflow skills and agents.

---

## Objectives

1. **Own the canonical source of truth** for skills and agents used across all Simon's projects — one marketplace to add, one command to refresh.
2. **Encode an extended engineering workflow** that adds pre-phase capture and post-ship learning around the seven-phase core — opinionated, first-person, not a copy of any reference.
3. **Ship complementary subagents** that are right-sized for each workflow phase, so Claude delegates automatically to the correct specialist.
4. **Keep installation friction near zero** — a new machine needs only `/plugin marketplace add` and a list of `/plugin install` calls to be fully set up.
5. **Make the marketplace self-describing** — new contributors (or a future LLM session) can read the repo and immediately understand what every plugin does and why.

---

## Workflow Coverage Map

All workflow steps are covered. Skills live in either `workflow-core` (all seven phases) or `workflow-tools` (extended phases). Where a phase skill is based on or seeded from `addyosmani/agent-skills` content, that is noted in the Attribution column — the skill still lives in `workflow-core`, not a separate plugin.

| Step | Command | Skill (plugin) | Attribution | Status |
|---|---|---|---|---|
| **[NEW] Capture idea** | `/capture` | `issue-to-task`, `new-task` (workflow-tools) | Original | Covered |
| **[NEW] Challenge idea** | `/challenge` | `grill-me` (workflow-tools) | Original | Covered |
| Define what to build | `/spec` | `task-to-spec` (workflow-core) | Original | Covered |
| Plan how to build it | `/plan` | `plan` (workflow-core) | Seeded from `planning-and-task-breakdown` (agent-skills, MIT) | Covered |
| Build incrementally | `/build` | `build` (workflow-core) + `opsx:*` (10 skills) + `test-creator` (workflow-core) | `build` seeded from `incremental-implementation` (agent-skills, MIT) | Covered |
| Prove it works | `/test` | `test` (workflow-core) | Seeded from `test-driven-development` (agent-skills, MIT) | Covered |
| Review before merge | `/review` | `pr-reviewer` (workflow-core) | Original, extends `code-review-excellence` | Covered |
| Simplify the code | `/code-simplify` | `simplify` (workflow-core) | Seeded from `code-simplification` (agent-skills, MIT) | Covered |
| Ship to production | `/ship` | `ship` (workflow-core) | Seeded from `git-workflow-and-versioning` (agent-skills, MIT) — PR creation only, CI/CD owns deploy | Covered |
| **[NEW] Learn from shipping** | `/retrospect` | `learn-from-mistakes` (workflow-tools) | Original | Covered |
| **[NEW] Maintain quality** | `/maintain` | `doc-lint`, `agent-optimise` (workflow-tools) | Original | Covered |

**Summary:** All steps covered across two plugins. 5 workflow-core skills are original first-party · 5 workflow-core skills are seeded from agent-skills (MIT, attributed per SKILL.md) · all workflow-tools skills are original.

**Attribution policy:** Any skill seeded from `addyosmani/agent-skills` carries a comment in its SKILL.md frontmatter: `# Source: https://github.com/addyosmani/agent-skills — MIT licence`. Simon's additions and adaptations accumulate on top.

---

## agent-skills Attribution

Five `workflow-core` phase skills are seeded from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT licensed). They are adapted and extended as Simon's own versions of those phases — not copied verbatim and not in a separate plugin.

| workflow-core skill | Seeded from | What Simon adds |
|---|---|---|
| `plan` | `planning-and-task-breakdown` | Opinionated output format tied to the ideation file and OpenSpec |
| `build` | `incremental-implementation` | Awareness of opsx skills as the implementation vehicle |
| `test` | `test-driven-development` | Distinction between test-creator (writing) and test (running) |
| `simplify` | `code-simplification` | Scoping rules specific to the codebase patterns |
| `ship` | `git-workflow-and-versioning` | PR-only scope — no deployment steps, CI/CD owns that |

Skills not used from agent-skills (and why): `shipping-and-launch` (too broad, covers full prod launch), `ci-cd-and-automation` (conflicts with CI/CD-owns-deploy principle), `api-and-interface-design` / `frontend-ui-engineering` / `performance-optimization` / `deprecation-and-migration` (situational, future plugins), `using-agent-skills` (meta, irrelevant).

---

## The Extended Workflow

Simon's workflow extends the seven-phase agent-skills reference by adding a **capture stage** before spec, a **challenge gate** between capture and spec, and a **retrospective stage** after ship. The core seven phases are preserved but supplemented rather than replaced.

```
Capture ─► Challenge ─► Spec ─► Plan ─► Build ─► Test ─► Review ─► Simplify ─► Ship ─► Retrospective
  (pre)      (gate)     (1)     (2)     (3)      (4)     (5)       (6)         (7)      (post)
```

### Core seven phases (aligned to agent-skills)

| Phase | Skill (workflow-core) | Origin | Principle |
|---|---|---|---|
| 1 `/spec` | `task-to-spec` | Original | Spec before code — freeze the outcome, not the implementation |
| 2 `/plan` | `plan` | Seeded from agent-skills | Small, atomic tasks — break the spec into independently testable slices |
| 3 `/build` | `build` + `opsx:*` + `test-creator` | `build` seeded from agent-skills; others original | One slice at a time — implement with tunnel vision on the current slice |
| 4 `/test` | `test` | Seeded from agent-skills | Tests are proof — running defined tests proves the slice is complete |
| 5 `/review` | `pr-reviewer` | Original | Improve code health — catch regressions and drift before merge |
| 6 `/code-simplify` | `simplify` | Seeded from agent-skills | Clarity over cleverness — remove every line not earning its place |
| 7 `/ship` | `ship` | Seeded from agent-skills | PR creation only — CI/CD owns the actual deploy |

### Extended phases (Simon-specific, no agent-skills equivalent)

| Phase | Simon's command | Nearest agent-skills skill | Principle |
|---|---|---|---|
| Pre (Jira) | `/issue-to-task` | `idea-refine` (partial) | Structured capture — a ticket becomes a thinking document, not a todo |
| Pre (scratch) | `/new-task` | `idea-refine` (partial) | Same as above without Jira input |
| Gate | `/grill-me` | *(none)* | Challenge before you commit — surface gaps before they reach code |
| Cross-cutting | `/doc-lint` | `documentation-and-adrs` (partial) | Enforcement, not just advice — docs must meet standards |
| Cross-cutting | `/agent-optimise` | *(none)* | The tooling is also code — CLAUDE.md, AGENTS.md should be reviewed |
| Post | `/learn-from-mistakes` | *(none)* | Strike while the context is hot — commit history is ephemeral knowledge |

---

## Skill Inventory and Alignment Analysis

Each of Simon's nine skills mapped to: its workflow phase, the existing `~/.claude` source it derives from, its agent-skills alignment, and any significant divergence.

| Skill name | Phase | Source in `~/.claude` | agent-skills equivalent | Alignment |
|---|---|---|---|---|
| `issue-to-task` | Pre-spec (Jira capture) | `jira-to-openspec` (adapted) | `idea-refine` (partial) | **Diverges**: source goes all the way to OpenSpec; this skill stops at a TODO ideation file, intentionally lighter |
| `new-task` | Pre-spec (scratch capture) | `jira-to-openspec` (structure only) | `idea-refine` (partial) | **Diverges**: agent-skills idea-refine is a conversation loop; this is a file-creation action |
| `grill-me` | Challenge gate | `grill-me` (direct copy) | *(no equivalent)* | **Unique**: agent-skills has no adversarial challenge step; this fills a real gap |
| `task-to-spec` | Spec (Phase 1) | `ideation-to-openspec` (renamed) | `spec-driven-development` | **Strongly aligned**: both formalize planning artefacts into structured specs; Simon's version outputs OpenSpec format specifically |
| `test-creator` | Test (Phase 4) | *(new skill)* | `test-driven-development` | **Aligned** in purpose; agent-skills TDD skill is forward-looking, test-creator is retrofit-focused — different scope |
| `pr-reviewer` | Review (Phase 5) | `code-review-excellence` (extended) | `code-review-and-quality` | **Strongly aligned**: extends the existing review skill with PR-specific context (open PRs, branch comparison) |
| `doc-lint` | Cross-cutting | `doc-lint` (direct copy) | `documentation-and-adrs` (partial) | **Diverges significantly**: agent-skills doc skill generates ADRs and docs; doc-lint enforces standards on existing docs — complementary, not competing |
| `agent-optimise` | Cross-cutting | *(new skill — combines `claude-validate` + `agent-architect` concerns)* | *(no equivalent)* | **Unique**: meta-tooling for Claude/Codex project setup; agent-skills has no self-referential setup review |
| `learn-from-mistakes` | Post-ship | `commits-to-knowledge` (renamed) | *(no equivalent)* | **Unique**: retrospective knowledge capture from git history; closes the loop that agent-skills leaves open |

### Key divergence notes

**`issue-to-task` vs `jira-to-openspec`:** The source skill jumps from Jira straight to a formal OpenSpec with full fidelity validation. The marketplace skill is intentionally lighter — it produces a TODO/ideation markdown file that can be challenged (`/grill-me`) and refined before being passed to `/task-to-spec`. The full OpenSpec generation is deferred to that later step. This preserves the Jira connection without forcing premature formalization.

**`grill-me` fills a real gap:** The agent-skills reference has no challenge or validation step between idea and spec. Simon's workflow explicitly gates on this — you do not move from an ideation file to a formal spec without running `/grill-me` first. This is a discipline the reference workflow lacks.

**`doc-lint` vs `documentation-and-adrs`:** These are complementary skills that should not be conflated. `documentation-and-adrs` is creative (write new docs, create ADRs). `doc-lint` is enforcement (validate existing docs meet standards, with auto-fix). Both have value; they serve different moments.

**`agent-optimise` is genuinely novel:** No reference implementation covers reviewing your own AI tooling setup. This skill analyses `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`, agent definitions, and skill frontmatter for quality, scope creep, conflicting instructions, and best-practice violations. It's the skill that keeps the other skills healthy.

---

## Scaffolded Repository Structure

```
plugin-marketplace-simon/
│
├── .claude-plugin/
│   └── marketplace.json              # Marketplace catalog
│
├── plugins/
│   │
│   ├── workflow-core/                # Seven-phase skills (original + agent-skills-seeded, see Attribution section)
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── skills/
│   │   │   ├── task-to-spec/         # Phase 1 /spec — original
│   │   │   │   └── SKILL.md
│   │   │   ├── plan/                 # Phase 2 /plan — seeded from agent-skills
│   │   │   │   └── SKILL.md
│   │   │   ├── build/                # Phase 3 /build — seeded from agent-skills
│   │   │   │   └── SKILL.md
│   │   │   ├── test-creator/         # Phase 3 /build — original (writes tests)
│   │   │   │   └── SKILL.md
│   │   │   ├── test/                 # Phase 4 /test — seeded from agent-skills (runs tests)
│   │   │   │   └── SKILL.md
│   │   │   ├── pr-reviewer/          # Phase 5 /review — original
│   │   │   │   └── SKILL.md
│   │   │   ├── simplify/             # Phase 6 /code-simplify — seeded from agent-skills
│   │   │   │   └── SKILL.md
│   │   │   └── ship/                 # Phase 7 /ship — seeded from agent-skills (PR only)
│   │   │       └── SKILL.md
│   │   └── README.md
│   │
│   ├── workflow-tools/               # Extended skills: capture, challenge, quality, retrospective (all original)
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── skills/
│   │   │   ├── issue-to-task/        # Pre-spec: Jira → ideation file
│   │   │   │   └── SKILL.md
│   │   │   ├── new-task/             # Pre-spec: scratch → ideation file
│   │   │   │   └── SKILL.md
│   │   │   ├── grill-me/             # Challenge gate: interrogate any file
│   │   │   │   └── SKILL.md
│   │   │   ├── doc-lint/             # Cross-cutting: enforce /docs standards
│   │   │   │   └── SKILL.md
│   │   │   ├── agent-optimise/       # Cross-cutting: audit Claude/Codex setup
│   │   │   │   └── SKILL.md
│   │   │   └── learn-from-mistakes/  # Post-ship: commits → documentation
│   │   │       └── SKILL.md
│   │   └── README.md
│   │
│   ├── workflow-agents/              # Subagents paired to each phase
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── agents/
│   │   │   ├── capturer.md           # Pre-phase: ticket or scratch to ideation
│   │   │   ├── specifier.md          # Phase 1: spec writing
│   │   │   ├── planner.md            # Phase 2: task breakdown
│   │   │   ├── builder.md            # Phase 3: slice implementation
│   │   │   ├── tester.md             # Phase 4: test writing and coverage
│   │   │   ├── reviewer.md           # Phase 5: PR and diff review
│   │   │   ├── simplifier.md         # Phase 6: dead-code and clarity
│   │   │   └── shipper.md            # Phase 7: deploy checklist
│   │   └── README.md
│   │
│   └── (future plugins go here)
│
├── todo/
│   └── Marketplace_setup.md          # This file
│
└── README.md                         # Installation guide
```

**Why two skill plugins:**
- `workflow-core` owns all seven canonical phases. Some skills are original (task-to-spec, pr-reviewer, test-creator), others are seeded from agent-skills and extended (plan, build, test, simplify, ship). All live here — one plugin, one namespace, one install.
- `workflow-tools` owns the extended phases and cross-cutting skills. All original. Personal tooling not intended for general distribution.

---

## Implementation Steps

### Phase 0 — Repo Initialisation

- [ ] Write `README.md` at repo root: what this marketplace is, who it is for, the single install command pair.
- [ ] Decide final marketplace name — `simon-marketplace` is the current working name. It appears in all install commands so should be stable.
- [ ] Confirm private vs public repo (affects whether GitHub source references work for others).

---

### Phase 1 — Marketplace Catalog

Create `.claude-plugin/marketplace.json`:

```json
{
  "name": "simon-marketplace",
  "owner": {
    "name": "Simon Potter",
    "email": "simon@academypl.us"
  },
  "metadata": {
    "description": "Simon's extended engineering workflow: capture, challenge, spec, plan, build, test, review, simplify, ship, learn",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "workflow-core",
      "source": "./plugins/workflow-core",
      "description": "Seven-phase workflow skills: task-to-spec, plan, build, test-creator, test, pr-reviewer, simplify, ship",
      "version": "0.1.0"
    },
    {
      "name": "workflow-tools",
      "source": "./plugins/workflow-tools",
      "description": "Extended workflow skills: issue-to-task, new-task, grill-me, doc-lint, agent-optimise, learn-from-mistakes",
      "version": "0.1.0"
    },
    {
      "name": "workflow-agents",
      "source": "./plugins/workflow-agents",
      "description": "Specialist subagents for each workflow phase",
      "version": "0.1.0"
    }
  ]
}
```

---

### Phase 2 — `workflow-core` Plugin

#### 2a. Plugin manifest

```json
{
  "name": "workflow-core",
  "description": "Seven opinionated skills for the task-to-spec → plan → build → test-creator → pr-reviewer → simplify → ship cycle",
  "version": "0.1.0",
  "author": { "name": "Simon Potter" }
}
```

#### 2b. Universal skill design rules

- `disable-model-invocation: true` on **all core phase skills** — workflow gates are user-triggered.
- Description field states the phase name, principle, and trigger: "Phase 1 — Spec. Use when you have a challenged ideation file and are ready to generate a formal OpenSpec."
- Skill body: numbered steps, one outcome per step, verification line at the end.
- `allowed-tools` scoped to the phase (see per-skill table below).
- Supporting files where genuinely needed: `task-to-spec` will reference an OpenSpec template; `ship` may reference a deploy checklist template.

#### 2c. Skill-by-skill details

| Skill | Source | `allowed-tools` | Key open decision |
|---|---|---|---|
| `task-to-spec` | `ideation-to-openspec` (renamed, logic preserved) | Read, Write, Bash (openspec CLI) | Where does the ideation file live — always `todo/`? |
| `plan` | *(new)* | Read, Write | What is the canonical plan format — `tasks.md`? TaskCreate tool calls? |
| `build` | *(new)* | Read, Edit, Write, Bash | How does the skill locate "the current task" from the plan? |
| `test-creator` | *(new)* | Read, Write, Bash, Grep, Glob | What counts as sufficient test coverage — line %? behaviour scenarios? |
| `pr-reviewer` | `code-review-excellence` (extended with PR context) | Read, Bash (gh pr *) | Does this always review the current branch's open PR, or accept a PR number as argument? |
| `simplify` | *(new)* | Read, Edit, Grep, Glob | Scope — whole file, changed lines, or named function? |
| `ship` | *(new)* | Read, Bash | What constitutes a "successful ship" for this context — health check, smoke test, monitoring check? |

---

### Phase 3 — `workflow-tools` Plugin

#### 3a. Plugin manifest

```json
{
  "name": "workflow-tools",
  "description": "Extended workflow skills: pre-phase capture, challenge gate, cross-cutting quality, and post-ship retrospective",
  "version": "0.1.0",
  "author": { "name": "Simon Potter" }
}
```

#### 3b. Skill-by-skill details

| Skill | Source | `disable-model-invocation` | `allowed-tools` | Key adaptation vs source |
|---|---|---|---|---|
| `issue-to-task` | `jira-to-openspec` (heavily adapted) | `true` | Read, Write, `mcp__atlassian__*` | Output is a TODO ideation file, **not** OpenSpec. Strips out the OpenSpec generation phases entirely. Preserves Jira fetch and content extraction. |
| `new-task` | `jira-to-openspec` (structure only) | `true` | Read, Write | No Jira fetch — asks user for idea description interactively. Same output format as `issue-to-task`. |
| `grill-me` | `grill-me` (direct copy, minor wording) | `true` | Read, Grep, Glob | Accepts a file path as `$ARGUMENTS` — defaults to the most recent file in `todo/` if no argument given. Source version is purely conversational; this version reads a file first. |
| `doc-lint` | `doc-lint` (direct copy) | `true` | Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion | No changes from source. Packaged here for distribution. |
| `agent-optimise` | *(new — synthesises `claude-validate` + `agent-architect`)* | `true` | Read, Glob, Grep, Bash | Audits CLAUDE.md scope/length, agent descriptions for trigger quality, skill frontmatter for correctness, settings.json for conflicts. Produces a prioritised fix list. |
| `learn-from-mistakes` | `commits-to-knowledge` (renamed) | `true` | Read, Glob, Grep, Bash, Edit, Write | No functional changes. Rename only — "commits-to-knowledge" is the right internal name; "learn-from-mistakes" is the user-facing command name. |

#### 3c. Ideation file format (shared output of `issue-to-task` and `new-task`)

Both pre-phase skills produce the same format so `/grill-me` and `/task-to-spec` can consume either without adaptation:

```
todo/{slug}.md
```

```markdown
---
source: jira | scratch
ticket: PROJ-123          # omit if scratch
created: YYYY-MM-DD
status: ideation
---

# {Title}

## Context
{Why this needs doing — 2-3 sentences}

## What we know
{Facts, constraints, requirements already understood}

## Open questions
{Things not yet decided — this is what /grill-me will attack}

## Rough scope
{High-level what needs to change — no implementation detail}
```

This format is intentionally lightweight. The heavy structure (OpenSpec) comes later, after the idea has been challenged.

---

### Phase 4 — `workflow-agents` Plugin

#### 4a. Plugin manifest

```json
{
  "name": "workflow-agents",
  "description": "Specialist subagents for each phase of the extended engineering workflow",
  "version": "0.1.0",
  "author": { "name": "Simon Potter" }
}
```

#### 4b. Agent-by-agent responsibilities

| Agent | Phase | Model | Tools | Core constraint |
|---|---|---|---|---|
| `capturer` | Pre-phase | Haiku | Read, Write, MCP Atlassian | Fetches and summarises only — does not interpret or suggest implementation |
| `specifier` | Phase 1 | Sonnet | Read, Write, Bash (openspec) | Asks clarifying questions, writes spec artefacts, refuses to suggest implementation |
| `planner` | Phase 2 | Haiku | Read, Write | Reads spec, produces atomic task list, validates each task is independently testable |
| `builder` | Phase 3 | Sonnet | All tools | Reads current task from plan, implements it, stops at task boundary |
| `tester` | Phase 4 | Sonnet | Read, Write, Bash | Reads code, writes tests, runs suite, reports pass/fail |
| `reviewer` | Phase 5 | Haiku | Read, Bash (gh pr *) | Reads diff/PR, produces structured review — no edits, one Write for report |
| `simplifier` | Phase 6 | Haiku | Read, Edit, Glob, Grep | Identifies candidates for removal — does not touch tests |
| `shipper` | Phase 7 | Haiku | Read, Bash | Runs deploy checklist, gates on all checks passing — does not deploy |

---

### Phase 5 — Migrating from `~/.claude` to Plugin

Several skills exist today as personal skills in `~/.claude/skills/`. They need to be:

1. Copied into the appropriate plugin directory with any adaptations noted above.
2. Left in place in `~/.claude/skills/` until the marketplace version is tested and confirmed working. Do not remove the originals until install is validated on the current machine.
3. Reconciled: once the plugin is installed and confirmed, the `~/.claude` copies become redundant. Archive them rather than delete — they are the authoritative source of the current behaviour.

| Existing personal skill | Target in marketplace | Action |
|---|---|---|
| `~/.claude/skills/grill-me/` | `workflow-tools/skills/grill-me/` | Copy + minor adaptation (file argument support) |
| `~/.claude/skills/ideation-to-openspec/` | `workflow-core/skills/task-to-spec/` | Copy + rename |
| `~/.claude/skills/commits-to-knowledge/` | `workflow-tools/skills/learn-from-mistakes/` | Copy + rename |
| `~/.claude/skills/code-review-excellence/` | `workflow-core/skills/pr-reviewer/` | Copy + extend with PR context |
| `~/.claude/skills/doc-lint/` | `workflow-tools/skills/doc-lint/` | Direct copy |
| `~/.claude/skills/jira-to-openspec/` | `workflow-tools/skills/issue-to-task/` | Heavily adapted (strip OpenSpec output, stop at ideation) |

Skills that are **new** (no existing source): `plan`, `build`, `simplify`, `ship`, `test-creator`, `new-task`, `agent-optimise`.

---

### Phase 6 — Local Testing

1. Load marketplace locally from repo root: `/plugin marketplace add ./`
2. Install all three plugins:
   ```
   /plugin install workflow-core@simon-marketplace
   /plugin install workflow-tools@simon-marketplace
   /plugin install workflow-agents@simon-marketplace
   ```
3. Walk through the full extended lifecycle with a toy task:
   - `/workflow-tools:new-task` → create ideation file
   - `/workflow-tools:grill-me todo/{file}.md` → challenge it
   - `/workflow-core:task-to-spec todo/{file}.md` → generate OpenSpec
   - `/workflow-core:plan` → break into tasks
   - opsx skills + `/workflow-core:test-creator` → implement slice + write tests
   - `/workflow-core:test` → run and verify tests
   - `/workflow-core:pr-reviewer` → review the branch
   - `/workflow-core:simplify` → clean up
   - `/workflow-core:ship` → create PR
   - `/workflow-tools:learn-from-mistakes` → extract learnings
4. Confirm agents appear in `/agents` with correct trigger descriptions.
5. `/reload-plugins` after any edits — no restart needed.

---

### Phase 7 — GitHub Hosting and Distribution

1. Push `main` to GitHub.
2. Tag `v0.1.0` once local testing passes.
3. Install command on a new machine:
   ```
   /plugin marketplace add simonpotter/plugin-marketplace-simon
   /plugin install workflow-core@simon-marketplace
   /plugin install workflow-tools@simon-marketplace
   /plugin install workflow-agents@simon-marketplace
   ```
4. Update command on any machine: `/plugin marketplace update simon-marketplace`

---

### Phase 8 — Growth (future plugins)

| Prospective plugin | What it would contain |
|---|---|
| `project-context` | Skills for CLAUDE.md generation, architecture snapshots, onboarding |
| `infra-tools` | Skills wrapping terraform/ansible recipes for the Spottmedia stack |
| `db-migrations` | Alembic migration workflow as installable skill set |
| `api-contract` | FastAPI/Nuxt contract enforcement patterns as portable skills |
| `security-scan` | SAST/Semgrep workflow as a portable skill |

---

## Decision Log (open items before starting)

1. **Ideation file location** — always `todo/`? Or project-configurable? This affects both capture skills and the grill-me argument default.
2. **Plan format** — `tasks.md` checklist, Claude Code TaskCreate tool calls, or something else? The `/build` skill's ability to find "the current task" depends on this.
3. **Marketplace name** — `simon-marketplace` is working but generic. It's embedded in every install command, so it should be stable.
4. **Private vs public repo** — affects GitHub source resolution for others.
5. **OpenSpec tooling assumption** — `task-to-spec` calls the `openspec` CLI. Is this installed on all target machines, or does it need to be bundled/documented as a prerequisite?
6. **`pr-reviewer` argument** — does it always review the current branch's open PR, or accept a PR number? `$ARGUMENTS` can handle both but the default matters.
7. **`agent-optimise` scope** — does this audit just the current project's `.claude/` directory, or also `~/.claude/`? Both? Configurable?

---

## Acceptance Criteria

The marketplace is "working" when:

- [ ] `marketplace.json` validates and is readable by Claude Code
- [ ] All `workflow-core` skills install and are invocable via `/workflow-core:<name>` (`task-to-spec`, `plan`, `build`, `test-creator`, `test`, `pr-reviewer`, `simplify`, `ship`)
- [ ] All `workflow-tools` skills install and are invocable via `/workflow-tools:<name>` (`issue-to-task`, `new-task`, `grill-me`, `doc-lint`, `agent-optimise`, `learn-from-mistakes`)
- [ ] All eight agents appear in `/agents` with correct trigger descriptions
- [ ] The full extended lifecycle (new-task → learn-from-mistakes) works end-to-end on a toy project
- [ ] A fresh machine can install everything with four commands (marketplace add + three plugin installs)
- [ ] `/plugin marketplace update simon-marketplace` picks up changes after a push
- [ ] Personal skills in `~/.claude` that are superseded by marketplace versions are confirmed redundant and archived

---

## Quick Reference: Key File Formats

**marketplace.json** — `.claude-plugin/marketplace.json` in repo root.

**plugin.json** — `<plugin-dir>/.claude-plugin/plugin.json`.

**SKILL.md** — `<plugin-dir>/skills/<skill-name>/SKILL.md`. YAML frontmatter + markdown body.

**Agent file** — `<plugin-dir>/agents/<agent-name>.md`. YAML frontmatter + system prompt markdown.

**Ideation file** — `todo/{slug}.md`. YAML frontmatter (source, ticket, created, status) + four sections.

**Install** — `/plugin marketplace add <github-user/repo>` or `/plugin marketplace add ./local-path`

**Skill invocation** — `/workflow-core:task-to-spec` · `/workflow-core:plan` · `/workflow-tools:grill-me <file>`

**Reload after edits** — `/reload-plugins`
