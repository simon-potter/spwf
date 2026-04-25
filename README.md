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
| **Challenge** | `/workflow-tools:challenge todo/{slug}.md` | — | Surfaces gaps and ambiguities before they reach code | Resolved ideation file |
| **Spec** | `/workflow-core:spec todo/{slug}.md` | `openspec` CLI | Formalises the challenged idea into a structured spec | `openspec/changes/{id}/proposal.md`, `design.md`, `tasks.md`, `specs/` |
| **Approve plan** | `/workflow-core:approve-plan` | — | Quality check (blocking) + adversarial review via Skeptic/Architect/Minimalist lenses (advisory); explicit human go/no-go before building | Approved task list or flagged issues to resolve |
| **Build** | `/workflow-core:build` | `write-tests` → `opsx:apply` → `run-tests` → `debug-recovery` → `opsx:verify` | Red-Green-Verify per task, loops until all done; spec sign-off after all tasks complete | All tasks complete, tests green, spec aligned |
| **Simplify** (TDD Refactor) | `/workflow-core:simplify` | — | Clean up the implementation with tests as a safety net; flags judgment calls | Cleaner diff; flag list |
| **PR Create** | `/workflow-core:pr-create` | `gh pr create` | Pre-flight checks then PR creation; CI/CD owns the rest | PR URL |
| **PR Review** | `/workflow-core:pr-review <PR>` | `gh pr view`, `gh pr diff` | Structured review before merge; catches regressions and drift | Review report with verdict |
| **Retrospective** | `/workflow-tools:retrospective` | `learn-from-mistakes` → change spec audit → `doc-lint` | Extract learnings from commits; align spec artefacts with what was built; broad doc drift check | Updated learnings, aligned spec, doc quality report |

## Quality tools

A second class of skills sits outside the main workflow. These are cross-cutting maintenance tools — run them between sessions, on a cadence, or when something feels off. They don't produce code; they keep the workspace itself in good shape.

| Skill | Invoke | When to use |
|---|---|---|
| `claudemd-curator` | `/workflow-tools:claudemd-curator` | CLAUDE.md or AGENTS.md has grown, drifted, or is being ignored. Audits all instruction files, mines session transcripts for violated/dead rules, classifies content into L0–L4 layers, checks AGENTS.md sync state, then proposes a numbered diff — waits for approval before touching anything. Monthly or after `/init`. |
| `workflow-lint` | `/workflow-tools:workflow-lint` | Golden path feels out of sync — skill names changed, agents don't cover a phase, a cross-reference is broken. Sweeps the full plugin tree for coherence issues. |
| `agent-optimise` | `/workflow-tools:agent-optimise` | Agent descriptions or tool lists have drifted. Audits both plugin-scoped and user-scoped agents. |
| `doc-lint` | `/workflow-tools:doc-lint` | Documentation has accumulated drift — stale READMEs, broken links, misaligned specs. |

### `claudemd-curator` in depth

The curator runs a five-phase pipeline:

1. **Inventory** — reads every instruction file (project + global), counts lines, notes git-tracking status.
2. **Behavioural audit** — mines `~/.claude/projects/*.jsonl` transcripts; spawns Sonnet subagents to surface violated rules, candidate additions, and dead rules.
3. **Layer classification** — assigns every CLAUDE.md line to L0 (identity/map), L1 (Karpathy discipline), L2 (product-mode decision posture), L3 (pointers), or L4 (housekeeping), or marks it for removal.
4. **Sync verification** — checks AGENTS.md ↔ CLAUDE.md relationship: `OK_SYMLINK`, `OK_SHIM`, `DUAL` (drift risk), or `CLAUDE_ONLY`/`AGENTS_ONLY`.
5. **Propose, don't apply** — produces a numbered proposal and waits for explicit approval before editing anything.

Requires `jq` for transcript mining (see Prerequisites).

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

Every project that uses this workflow must be initialised before running `/workflow-core:spec`:

```bash
cd your-project
openspec init
```

If the `openspec/` directory is missing, `spec` will halt with a clear message.

### 3. GitHub CLI (for `pr-review` and `pr-create`)

```bash
brew install gh   # macOS — or: https://cli.github.com
gh auth login
```

### 4. Atlassian MCP (for `issue-to-task` only)

Required only if pulling from Jira. Not needed for any other skill. Configure the Atlassian MCP server in your Claude Code settings.

### 5. `jq` (for `claudemd-curator` only)

Required for transcript mining in the behavioural audit phase.

```bash
brew install jq   # macOS
apt-get install jq  # Debian/Ubuntu
```

---

## What's included

### `workflow-core` — Seven canonical phases

| Skill | Invoke | Phase |
|---|---|---|
| `spec` | `/workflow-core:spec` | 1 — Spec |
| `approve-plan` | `/workflow-core:approve-plan` | 2 — Approve plan |
| `write-tests` | `/workflow-core:write-tests` | 3 — Build (atomic) |
| `debug-recovery` | `/workflow-core:debug-recovery` | 3 — Build (atomic) |
| `build` | `/workflow-core:build` | 3 — Build (orchestrator) |
| `run-tests` | `/workflow-core:run-tests` | 3 — Build (atomic) |
| `pr-review` | `/workflow-core:pr-review <PR>` | 5 — PR Review |
| `simplify` | `/workflow-core:simplify` | 6 — Simplify |
| `pr-create` | `/workflow-core:pr-create` | 7 — PR Create |

### `workflow-tools` — Extended phases and quality tools

| Skill | Invoke | Phase |
|---|---|---|
| `capture` | `/workflow-tools:capture [source]` | Pre — Capture (orchestrator) |
| `debug` | `/workflow-tools:debug [ticket or description]` | Pre — Capture for bugs |
| `issue-to-task` | `/workflow-tools:issue-to-task` | Pre — Capture from Jira (atomic) |
| `new-task` | `/workflow-tools:new-task` | Pre — Capture from scratch (atomic) |
| `challenge` | `/workflow-tools:challenge [file]` | Gate — Challenge |
| `retrospective` | `/workflow-tools:retrospective` | Post — Retrospective (orchestrator) |
| `learn-from-mistakes` | `/workflow-tools:learn-from-mistakes` | Post — Retrospective (atomic) |
| `claudemd-curator` | `/workflow-tools:claudemd-curator` | Quality — instruction file audit and sync |
| `workflow-lint` | `/workflow-tools:workflow-lint` | Quality — golden path coherence audit |
| `agent-optimise` | `/workflow-tools:agent-optimise` | Quality — agent/skill audit |
| `doc-lint` | `/workflow-tools:doc-lint` | Quality — documentation drift check |

### `workflow-agents` — Specialist subagents

Twelve agents covering every workflow phase. Each is scoped to a single responsibility and right-sized to a model that matches the cognitive demand. Appear in `/agents` after install.

| Agent | Phase | Model |
|---|---|---|
| `capturer` | Pre — Capture | Haiku |
| `debugger` | Pre — Debug | Sonnet |
| `challenger` | Gate — Challenge | Sonnet |
| `specifier` | Spec | Sonnet |
| `approver` | Approve plan | Haiku |
| `builder` | Build | Sonnet |
| `tester` | Build — TDD execution | Sonnet |
| `tdd-expert` | Build — TDD advisory | Sonnet |
| `reviewer` | PR Review | Haiku |
| `simplifier` | Simplify | Haiku |
| `pr-creator` | PR Create | Haiku |
| `retrospector` | Post — Retrospective | Sonnet |
