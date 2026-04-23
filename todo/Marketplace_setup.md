# Plugin Marketplace Setup Plan

> From empty repo to a working Claude Code plugin marketplace, installable as a single source of workflow skills and agents.

---

## Objectives

1. **Own the canonical source of truth** for skills and agents used across all Simon's projects — one marketplace to add, one command to refresh.
2. **Encode the seven-phase engineering workflow** as opinionated, first-person skills rather than copying the addyosmani reference verbatim.
3. **Ship complementary subagents** that are right-sized for each workflow phase, so Claude delegates automatically to the correct specialist.
4. **Keep installation friction near zero** — a new machine needs only `/plugin marketplace add` and a list of `/plugin install` calls to be fully set up.
5. **Make the marketplace self-describing** — new contributors (or a future LLM session) can read the repo and immediately understand what every plugin does and why.

---

## The Seven Workflow Phases

These map to the seven commands but are interpreted through the lens of how Simon actually works, not the reference repo.

| Phase | Command | Principle | Intent |
|---|---|---|---|
| 1 | `/spec` | Spec before code | Freeze the outcome, not the implementation |
| 2 | `/plan` | Small, atomic tasks | Break the spec into slices that can each be proved complete |
| 3 | `/build` | One slice at a time | Implement with tunnel vision on the current slice only |
| 4 | `/test` | Tests are proof | A feature is not done until a test confirms it |
| 5 | `/review` | Improve code health | Catch regressions, smell, and drift before merge |
| 6 | `/simplify` | Clarity over cleverness | Remove every line that is not earning its place |
| 7 | `/ship` | Faster is safer | Smaller deploys expose fewer blast radii |

---

## Scaffolded Repository Structure

```
plugin-marketplace-simon/
│
├── .claude-plugin/
│   └── marketplace.json          # Marketplace catalog (the registry)
│
├── plugins/
│   │
│   ├── workflow-skills/          # Seven-phase skill set (one plugin, seven skills)
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── skills/
│   │   │   ├── spec/
│   │   │   │   └── SKILL.md
│   │   │   ├── plan/
│   │   │   │   └── SKILL.md
│   │   │   ├── build/
│   │   │   │   └── SKILL.md
│   │   │   ├── test/
│   │   │   │   └── SKILL.md
│   │   │   ├── review/
│   │   │   │   └── SKILL.md
│   │   │   ├── simplify/
│   │   │   │   └── SKILL.md
│   │   │   └── ship/
│   │   │       └── SKILL.md
│   │   └── README.md
│   │
│   ├── workflow-agents/          # Subagents that pair with each phase
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── agents/
│   │   │   ├── specifier.md      # Spec phase specialist
│   │   │   ├── planner.md        # Breakdown and task atomisation
│   │   │   ├── builder.md        # Implementation, slice-aware
│   │   │   ├── tester.md         # Test-writing and coverage auditor
│   │   │   ├── reviewer.md       # Code health, diff reviewer
│   │   │   ├── simplifier.md     # Readability and dead-code removal
│   │   │   └── shipper.md        # Deploy checklist and verification
│   │   └── README.md
│   │
│   └── (future plugins go here as independent directories)
│
├── todo/
│   └── Marketplace_setup.md      # This file
│
└── README.md                     # Marketplace-level installation guide
```

**Key structural rules:**
- `marketplace.json` lives at `.claude-plugin/marketplace.json` — this is what Claude Code reads when users add the marketplace.
- Each plugin is a self-contained directory with its own `.claude-plugin/plugin.json`.
- Skills and agents are split into separate plugins. This means users can install skills-only or agents-only without coupling.
- All plugin source paths in `marketplace.json` are relative (`./plugins/workflow-skills`) so the repo is location-independent.

---

## Implementation Steps

### Phase 0 — Repo Initialisation

- [ ] Confirm `main` branch is set as default and protected (already done by git init).
- [ ] Write `README.md` at repo root: what this marketplace is, who it is for, and the single install command.
- [ ] Decide on marketplace name. This becomes the `@name` suffix users type when installing, e.g. `/plugin install workflow-skills@simon-marketplace`. **Reserved names to avoid:** `claude-code-marketplace`, `agent-skills`, `anthropic-*`.

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
    "description": "Simon's standard workflow skills and agents for Claude Code",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "workflow-skills",
      "source": "./plugins/workflow-skills",
      "description": "Seven-phase engineering workflow skills",
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

**Validation:** run `claude --plugin-dir ./plugins/workflow-skills` to confirm local load before tagging a release.

---

### Phase 2 — `workflow-skills` Plugin

#### 2a. Plugin manifest

```json
// plugins/workflow-skills/.claude-plugin/plugin.json
{
  "name": "workflow-skills",
  "description": "Seven opinionated skills for the spec→plan→build→test→review→simplify→ship cycle",
  "version": "0.1.0",
  "author": { "name": "Simon Potter" },
  "repository": "https://github.com/simonpotter/plugin-marketplace-simon"
}
```

#### 2b. Skill design principles (to carry into every SKILL.md)

- `disable-model-invocation: true` on **all seven** — these are deliberate workflow gates, not ambient suggestions. You invoke them, Claude does not decide when to run a deploy.
- Each skill's description must name the phase and the principle: "Use when starting a new feature or task. Forces a written spec before any code is written."
- Skill body: numbered steps, one outcome per step, verification line at the end. No prose waffle.
- Supporting files only where genuinely needed (e.g. `/spec` may have a `template.md` that defines the canonical spec format).
- `allowed-tools` scoped to what the phase actually needs — `/ship` needs Bash, `/spec` needs only Read and Write.

#### 2c. Skill-by-skill work items

| Skill | Key decisions to make while writing |
|---|---|
| `/spec` | What format does a spec file take? Where does it live? What fields are mandatory? |
| `/plan` | What is the output format for a task breakdown? (e.g. GitHub issues, markdown checklist, task tool calls?) |
| `/build` | How does "one slice at a time" get enforced? Reference the current plan file. |
| `/test` | What counts as proof? (unit, integration, e2e threshold?) What triggers test runs? |
| `/review` | What does a review report look like? Does it diff against main or a PR? |
| `/simplify` | Scope: whole file, changed lines, or explicitly named function? What is the output? |
| `/ship` | What is the deploy checklist for this context? What constitutes a successful ship? |

---

### Phase 3 — `workflow-agents` Plugin

#### 3a. Plugin manifest

```json
// plugins/workflow-agents/.claude-plugin/plugin.json
{
  "name": "workflow-agents",
  "description": "Specialist subagents for each phase of the engineering workflow",
  "version": "0.1.0",
  "author": { "name": "Simon Potter" }
}
```

#### 3b. Agent design principles

- Each agent's `description` field is the most critical thing to get right — Claude uses it to decide when to delegate. Front-load the trigger condition.
- Restrict tools to what each phase actually needs. `reviewer.md` should be read-only except for a single Write to produce a report file. `builder.md` gets full tools.
- Set `model` explicitly where appropriate — Haiku for read-heavy phases (`specifier`, `reviewer`), Sonnet for implementation phases (`builder`, `tester`).
- Agents in the `workflow-agents` plugin do **not** preload skills by default. Skills are invoked by the user. Keep agents and skills loosely coupled.
- Each agent file (`.md`) follows the Claude Code AGENT.md format: YAML frontmatter (`name`, `description`, `model`, `tools`, optional `color`) followed by the system prompt in markdown.

#### 3c. Agent-by-agent responsibilities

| Agent | Role and key constraints |
|---|---|
| `specifier` | Asks clarifying questions, writes the spec file, refuses to suggest implementation. Read+Write only. |
| `planner` | Reads the spec, produces an atomic task list, validates each task is independently testable. Read+Write only. |
| `builder` | Reads the current task from the plan, implements it, stops at the task boundary. Full tools. |
| `tester` | Reads code, writes tests, runs the test suite, reports pass/fail. Bash + Read + Write. |
| `reviewer` | Reads diff or changed files, produces a structured review. Read only + single Write for report. |
| `simplifier` | Reads code, identifies candidates for removal or simplification, does not touch tests. Read + Edit. |
| `shipper` | Runs deploy checklist, reports status, gates on all checks passing. Bash + Read. |

---

### Phase 4 — Local Testing

Before pushing to GitHub for distribution:

1. Load the marketplace locally: `/plugin marketplace add ./` (from repo root)
2. Install each plugin: `/plugin install workflow-skills@simon-marketplace` and `/plugin install workflow-agents@simon-marketplace`
3. Run through each skill manually with a toy project to verify invocation works
4. Confirm agents appear in `/agents` and descriptions match trigger intent
5. Reload with `/reload-plugins` after any edits — no restart needed

---

### Phase 5 — GitHub Hosting and Distribution

1. Push `main` to GitHub (repo can be private; Claude Code can access private repos if the user has authenticated git).
2. Add the remote source to `marketplace.json` where appropriate — for external installs, the `source` can reference a GitHub repo path:
   ```json
   { "source": { "source": "github", "repo": "simonpotter/plugin-marketplace-simon", "subdir": "plugins/workflow-skills" } }
   ```
3. Tag releases with semver: `v0.1.0` for first working set.
4. The install command for a new machine becomes:
   ```
   /plugin marketplace add simonpotter/plugin-marketplace-simon
   /plugin install workflow-skills@simon-marketplace
   /plugin install workflow-agents@simon-marketplace
   ```
5. Updates on any machine: `/plugin marketplace update simon-marketplace`

---

### Phase 6 — Growth (future plugins)

These are not in scope for the initial build but are natural next additions to the marketplace:

| Prospective plugin | What it would contain |
|---|---|
| `project-context` | Skills for CLAUDE.md generation, doc-lint, architecture snapshots |
| `infra-tools` | Skills wrapping terraform/ansible recipes specific to the Spottmedia stack |
| `db-migrations` | The alembic-migration-specialist workflow as an installable skill set |
| `api-contract` | The fastapi-nuxt-contract-enforcer patterns as portable skills |
| `security-scan` | The SAST/Semgrep workflow as a portable skill |

Each becomes a new directory under `plugins/` and a new entry in `marketplace.json` — the marketplace schema scales horizontally without any structural changes.

---

## Decision Log (open items before starting)

These need a decision before writing the first SKILL.md:

1. **Spec file format** — markdown frontmatter file? OpenSpec format? Plain prose? Where does it live in a project?
2. **Plan format** — Claude Code task tool calls? A `tasks.md` checklist? GitHub issues? This affects the `/build` skill's ability to reference the current slice.
3. **Marketplace name** — `simon-marketplace` is readable but generic. Consider something more permanent since it is embedded in install commands.
4. **Private vs public repo** — affects whether GitHub source references work for others or only for you.
5. **Version strategy** — single version for all plugins, or independent versioning per plugin?

---

## Acceptance Criteria

The marketplace is "working" when:

- [ ] `marketplace.json` validates and is readable by Claude Code
- [ ] All seven skills install and are invocable via `/workflow-skills:<name>`
- [ ] All seven agents appear in `/agents` and match their trigger descriptions
- [ ] A fresh machine can install everything with three commands (marketplace add + two plugin installs)
- [ ] `/plugin marketplace update simon-marketplace` picks up changes after a push

---

## Quick Reference: Key File Formats

**marketplace.json** — lives at `.claude-plugin/marketplace.json` in the repo root.

**plugin.json** — lives at `<plugin-dir>/.claude-plugin/plugin.json`.

**SKILL.md** — lives at `<plugin-dir>/skills/<skill-name>/SKILL.md`. YAML frontmatter + markdown body.

**Agent file** — lives at `<plugin-dir>/agents/<agent-name>.md`. YAML frontmatter + system prompt markdown.

**Install command** — `/plugin marketplace add <github-user/repo>` or `/plugin marketplace add ./local-path`

**Skill invocation** — `/workflow-skills:spec` (namespaced by plugin name)

**Reload after edits** — `/reload-plugins`
