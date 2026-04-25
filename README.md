# Simon's Plugin Marketplace

Simon's extended engineering workflow, packaged as three installable Claude Code plugins.

## The workflow

```
[Capture | Debug] → Challenge → Spec → Approve plan → Build → Simplify → PR Create → PR Review → Retrospective
    (pre)             (gate)     (1)        (2)          (3)      (4)          (5)        (6)        (post)
```

## Golden path

| Step | Command | Invokes | Why | Produces |
|---|---|---|---|---|
| **Capture** | `/workflow-tools:capture [source]` | Atlassian MCP (Jira mode) | Accepts a Jira ticket, existing file, or freeform description; runs a lightweight qualification check; one targeted question at a time for any gaps | `todo/{slug}.md` |
| **Debug** *(bug entry point)* | `/workflow-tools:debug [ticket or description]` | Atlassian MCP (Jira mode) | Systematic root-cause investigation before any fix; forms a written hypothesis; produces an artefact that feeds into the standard workflow | `todo/BUG-{slug}.md` |
| **Challenge** | `/workflow-tools:grill-me todo/{slug}.md` | — | Surfaces gaps and ambiguities before they reach code | Resolved ideation file |
| **Spec** | `/workflow-core:task-to-spec todo/{slug}.md` | `openspec` CLI | Formalises the challenged idea into a structured spec | `openspec/changes/{id}/proposal.md`, `design.md`, `tasks.md`, `specs/` |
| **Approve plan** | `/workflow-core:plan-signoff` | — | Quality check (blocking) + adversarial review via Skeptic/Architect/Minimalist lenses (advisory); explicit human go/no-go before building | Approved task list or flagged issues to resolve |
| **Build** | `/workflow-core:build` | `test-creator` → `openspec:apply` → `test-runner` → `debug-recovery` | Red-Green-Verify per task, loops until all done; confirms tests fail before implementing, green before proceeding | All tasks complete, tests green |
| **Simplify** (TDD Refactor) | `/workflow-core:simplify` | — | Clean up the implementation with tests as a safety net; flags judgment calls | Cleaner diff; flag list |
| **PR Create** | `/workflow-core:ship` | `gh pr create` | Pre-flight checks then PR creation; CI/CD owns the rest | PR URL |
| **PR Review** | `/workflow-core:pr-reviewer <PR>` | `gh pr view`, `gh pr diff` | Structured review before merge; catches regressions and drift | Review report with verdict |
| **Retrospective** | `/workflow-tools:retrospective` | `learn-from-mistakes` → change spec audit → `doc-lint` | Extract learnings from commits; align spec artefacts with what was built; broad doc drift check | Updated learnings, aligned spec, doc quality report |

---

## Install

```bash
/plugin marketplace add Academy-Plus/plugin-marketplace-simon
/plugin install workflow-core@simon-marketplace
/plugin install workflow-tools@simon-marketplace
/plugin install workflow-agents@simon-marketplace
```

## Update

```bash
/plugin marketplace update simon-marketplace
```

## Local install (from this repo)

```bash
/plugin marketplace add ./
/plugin install workflow-core@simon-marketplace
/plugin install workflow-tools@simon-marketplace
/plugin install workflow-agents@simon-marketplace
```

---

## Prerequisites

Before any workflow skill will function correctly:

### 1. Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

### 2. OpenSpec CLI

The entire spec → plan → build chain depends on OpenSpec.

```bash
npm install -g openspec
```

Every project that uses this workflow must be initialised before running `/workflow-core:task-to-spec`:

```bash
cd your-project
openspec init
```

If the `openspec/` directory is missing, `task-to-spec` will halt with a clear message.

### 3. GitHub CLI (for `pr-reviewer` and `ship`)

```bash
brew install gh   # macOS — or: https://cli.github.com
gh auth login
```

### 4. Atlassian MCP (for `issue-to-task` only)

Required only if pulling from Jira. Not needed for any other skill. Configure the Atlassian MCP server in your Claude Code settings.

---

## What's included

### `workflow-core` — Seven canonical phases

| Skill | Invoke | Phase |
|---|---|---|
| `task-to-spec` | `/workflow-core:task-to-spec` | 1 — Spec |
| `plan-signoff` | `/workflow-core:plan-signoff` | 2 — Plan sign-off |
| `incremental-implementation` | `/workflow-core:incremental-implementation` | 3 — Build (atomic) |
| `test-creator` | `/workflow-core:test-creator` | 3 — Build (atomic) |
| `debug-recovery` | `/workflow-core:debug-recovery` | 3 — Build (atomic) |
| `build` | `/workflow-core:build` | 3 — Build (orchestrator) |
| `test-runner` | `/workflow-core:test-runner` | 4 — Test (atomic) |
| `test` | `/workflow-core:test` | 4 — Test (orchestrator) |
| `pr-reviewer` | `/workflow-core:pr-reviewer <PR>` | 5 — Review |
| `simplify` | `/workflow-core:simplify` | 6 — Simplify |
| `ship` | `/workflow-core:ship` | 7 — Ship |

### `workflow-tools` — Extended phases

| Skill | Invoke | Phase |
|---|---|---|
| `issue-to-task` | `/workflow-tools:issue-to-task` | Pre — Capture (Jira) |
| `new-task` | `/workflow-tools:new-task` | Pre — Capture (scratch) |
| `grill-me` | `/workflow-tools:grill-me [file]` | Gate — Challenge |
| `doc-lint` | `/workflow-tools:doc-lint` | Cross-cutting |
| `agent-optimise` | `/workflow-tools:agent-optimise` | Cross-cutting |
| `learn-from-mistakes` | `/workflow-tools:learn-from-mistakes` | Post — Retrospective |

### `workflow-agents` — Specialist subagents

Eight agents auto-assigned to workflow phases. Appear in `/agents` after install.
