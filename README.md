# SPWorkflow

Simon's engineering workflow, packaged as two installable Claude Code plugins.

## The workflow

```
[status] → [Capture] → Challenge → Spec → Approve plan → Build → Simplify → PR Create → PR Review → Close
 (orient)    (pre)      (gate)      (1)        (2)          (3)      (4)          (5)        (6)       (post)
```

## Golden path

| Step | Command | Invokes | Why | Produces |
|---|---|---|---|---|
| **Orient** | `/spwf:wfstatus` | — | Start of session: where am I, what's incomplete, what's next — heuristics across git state, OpenSpec changes, and todo backlog | Dashboard + suggested next action |
| **Capture** | `/spwf:capture [source]` | Atlassian MCP (Jira mode) | Accepts a Jira ticket, file, or freeform description; classifies as bug or change automatically. Bug path: systematic root-cause investigation → hypothesis. Change path: lightweight qualification, one question at a time. | `todo/{slug}.md` or `todo/BUG-{slug}.md` |
| **Challenge** | `/spwf:challenge todo/{slug}.md` | — | Surfaces gaps and ambiguities before they reach code | Resolved ideation file |
| **Spec** | `/spwf:spec todo/{slug}.md` | `openspec` CLI | Formalises the challenged idea into a structured spec | `openspec/changes/{id}/proposal.md`, `design.md`, `tasks.md`, `specs/` |
| **Approve plan** | `/spwf:approve-plan` | — | Quality check (blocking) + adversarial review via Skeptic/Architect/Minimalist lenses (advisory); explicit human go/no-go before building | Approved task list or flagged issues to resolve |
| **Build** | `/spwf:build` | `write-tests` → `opsx:apply` → `run-tests` → `debug-recovery` → `opsx:verify` | Red-Green-Verify per task, loops until all done; spec sign-off after all tasks complete | All tasks complete, tests green, spec aligned |
| **Simplify** (TDD Refactor) | `/spwf:simplify` | — | Clean up the implementation with tests as a safety net; flags judgment calls | Cleaner diff; flag list |
| **PR Create** | `/spwf:pr-create` | `dep-audit` · `gh pr create` | Pre-flight checks (gitleaks, semgrep, dep-audit across all ecosystems + Docker) then PR creation; CI/CD owns the rest | PR URL |
| **PR Review** | `/spwf:pr-review <PR>` | `gh pr view`, `gh pr diff` | Structured review before merge; catches regressions and drift | Review report with verdict |
| **Retrospective** | `/spwf:retrospective` | `learn-from-mistakes` → change spec audit → `doc-lint` → `workflow-lint` → `changelog` (release only) | Extract learnings from commits; align spec artefacts with what was built; broad doc drift check; optional changelog generation for releases. Called automatically by Close. | Updated learnings, aligned spec, doc quality report |
| **Close** | `/spwf:close [todo/{slug}.md]` | `retrospective` → `opsx:archive` → Atlassian MCP | Final phase — runs the full retrospective then, after explicit confirmation, marks the todo file complete, archives the OpenSpec change, and closes the linked Jira ticket | Closed todo, archived change, Jira ticket Done |

## Quality tools

A second class of skills sits outside the main workflow. These are cross-cutting maintenance tools — run them between sessions, on a cadence, or when something feels off. They don't produce code; they keep the workspace itself in good shape.

| Skill | Invoke | When to use |
|---|---|---|
| `workspace-health` | `/spwf:workspace-health` | Monthly cadence: full health check combining agentlint structural scan, behavioural audit from session transcripts, and AGENTS.md sync check. Produces a P1/P2/P3 action report. Advisory only — tells you what's broken and which tool to run. |
| `claudemd-curator` | `/spwf:claudemd-curator` | CLAUDE.md or AGENTS.md has grown, drifted, or is being ignored. Five-phase pipeline: agentlint inventory → transcript mining for violated/dead rules → layer classification (L0–L4) + Anthropic 100-point quality score → AGENTS.md sync check → numbered proposal. Waits for approval before touching anything. Monthly or after `/init`. |
| `security-scan` | `/spwf:security-scan [path]` | Deep security review before a sensitive merge or when auditing a legacy codebase. Covers all OWASP Top 10 categories and SQL injection patterns across PHP, Python, JS, and Go. Complements the automated dep-audit gate in `pr-create`. |
| `dep-audit` | `/spwf:dep-audit` | Multi-ecosystem dependency CVE audit (npm, Composer, pip, cargo, govulncheck, bundle audit) with Docker Compose awareness — detects running containers and runs audit tools inside them if not available on the host. Also scans images via Trivy/Grype/Docker Scout when available. |
| `php-code-quality-reviewer` | `/spwf:php-code-quality-reviewer [path]` | Read-only PHP bad-practice analysis grouped into five risk categories: Correctness, Security, Performance, Maintainability, and Modern PHP. Framework-aware (Laravel, Symfony, WordPress). Confidence-graded findings with tabular output. |
| `php-code-simplifier` | `/spwf:php-code-simplifier [path]` | PHP-aware safe refactor: applies guard clauses, nullsafe `?->`, `match` over `switch`, null coalescing, and debug-statement removal directly; flags type hints, enums, readonly, and constructor promotion for human review. Never touches test files. |
| `workflow-lint` | `/spwf:workflow-lint` | Golden path feels out of sync — skill names changed, agents don't cover a phase, a cross-reference is broken. Sweeps the full plugin tree for coherence issues. |
| `agent-optimise` | `/spwf:agent-optimise` | Lightweight agent/skill audit without external dependencies. Audits both plugin-scoped and user-scoped agents for description quality, tool scope, and model assignment. Use when agentlint is not available or as a quick spot-check. |
| `doc-lint` | `/spwf:doc-lint` | Documentation has accumulated drift — stale READMEs, broken links, misaligned specs. |

### `claudemd-curator` in depth

The curator runs a five-phase pipeline:

1. **Inventory** — reads every instruction file (project + global), runs optional agentlint scan for structural quality scores, counts lines, notes git-tracking status.
2. **Behavioural audit** — mines `~/.claude/projects/*.jsonl` transcripts; spawns Sonnet subagents to surface violated rules, candidate additions, and dead rules.
3. **Layer classification + quality score** — assigns every CLAUDE.md line to L0 (identity/map), L1 (Karpathy discipline), L2 (product-mode decision posture), L3 (pointers), or L4 (housekeeping); scores the file against the Anthropic 100-point rubric (six dimensions, A–F grade).
4. **Sync verification** — checks AGENTS.md ↔ CLAUDE.md relationship: `OK_SYMLINK`, `OK_SHIM`, `DUAL` (drift risk), or `CLAUDE_ONLY`/`AGENTS_ONLY`.
5. **Propose, don't apply** — produces a numbered proposal with quality scores and waits for explicit approval before editing anything.

Requires `jq` for transcript mining (see Prerequisites).

---

## Install

```bash
/plugin marketplace add Academy-Plus/spwf
/plugin install spwf@spwf
/plugin install spwf-agents@spwf
```

## Update

```bash
/plugin marketplace update spwf
```

## Local install (from this repo)

```bash
/plugin marketplace add ./
/plugin install spwf@spwf
/plugin install spwf-agents@spwf
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

Every project that uses this workflow must be initialised before running `/spwf:spec`:

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

### 5. `jq` (for `claudemd-curator` and `workspace-health`)

Required for transcript mining in the behavioural audit phase.

```bash
brew install jq   # macOS
apt-get install jq  # Debian/Ubuntu
```

### 6. Security tools (optional — used by `dep-audit`, `security-scan`, `pr-create`)

These are not required to use the workflow but enable the security pre-flight gate in `pr-create` and deeper on-demand analysis:

| Tool | Used by | Install |
|---|---|---|
| `gitleaks` | `pr-create` secret scan | `brew install gitleaks` |
| `semgrep` | `pr-create` SAST, `security-scan` | `pip install semgrep` |
| `trivy` | `dep-audit` image scan | `brew install trivy` |
| `grype` | `dep-audit` image scan (alternative) | `brew install grype` |
| `pip-audit` | `dep-audit` Python | `pip install pip-audit` |
| `cargo-audit` | `dep-audit` Rust | `cargo install cargo-audit` |
| `govulncheck` | `dep-audit` Go | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| `agentlint` | `workspace-health`, `claudemd-curator` | `npm install -g @agent-lint/cli` |

---

## What's included

### `spwf` — 27 workflow skills

| Skill | Invoke | Phase / Responsibility |
|---|---|---|
| `wfstatus` | `/spwf:wfstatus` | Pre — Session orientation |
| `capture` | `/spwf:capture [source]` | Pre — Capture (orchestrator); auto-classifies bugs vs changes |
| `issue-to-task` | `/spwf:issue-to-task` | Pre — Capture from Jira (atomic) |
| `new-task` | `/spwf:new-task` | Pre — Capture from scratch (atomic) |
| `challenge` | `/spwf:challenge [file]` | Gate — Challenge |
| `grill-me` | `/spwf:grill-me [file]` | Gate — Challenge (deprecated: use `challenge`) |
| `spec` | `/spwf:spec` | 1 — Spec |
| `approve-plan` | `/spwf:approve-plan` | 2 — Approve plan |
| `write-tests` | `/spwf:write-tests` | 3 — Build (atomic) |
| `debug-recovery` | `/spwf:debug-recovery` | 3 — Build (atomic) |
| `build` | `/spwf:build` | 3 — Build (orchestrator) |
| `run-tests` | `/spwf:run-tests` | 3 — Build (atomic) |
| `simplify` | `/spwf:simplify` | 4 — Simplify |
| `pr-create` | `/spwf:pr-create` | 5 — PR Create |
| `pr-review` | `/spwf:pr-review <PR>` | 6 — PR Review |
| `learn-from-mistakes` | `/spwf:learn-from-mistakes` | Post — Retrospective (atomic) |
| `changelog` | `/spwf:changelog [ref]` | Post — Release notes from conventional commits (atomic) |
| `retrospective` | `/spwf:retrospective` | Post — Retrospective (orchestrator) |
| `workspace-health` | `/spwf:workspace-health` | Cross-cutting — periodic health check |
| `claudemd-curator` | `/spwf:claudemd-curator` | Cross-cutting — instruction file audit and sync |
| `workflow-lint` | `/spwf:workflow-lint` | Cross-cutting — golden path coherence audit |
| `agent-optimise` | `/spwf:agent-optimise` | Cross-cutting — agent/skill audit |
| `doc-lint` | `/spwf:doc-lint` | Cross-cutting — documentation drift check |
| `security-scan` | `/spwf:security-scan [path]` | On-demand — OWASP Top 10 + deep SQL injection review |
| `dep-audit` | `/spwf:dep-audit` | On-demand / pre-PR — dependency CVE audit, Docker-aware |
| `php-code-simplifier` | `/spwf:php-code-simplifier [path]` | On-demand — PHP safe refactor |
| `php-code-quality-reviewer` | `/spwf:php-code-quality-reviewer [path]` | On-demand — PHP bad-practice analysis |

### `spwf-agents` — 13 specialist subagents

Fourteen agents covering every workflow phase. Each is scoped to a single responsibility and right-sized to a model that matches the cognitive demand. Appear in `/agents` after install.

| Agent | Phase | Model |
|---|---|---|
| `capturer` | Pre — Capture (bugs + changes) | Sonnet |
| `challenger` | Gate — Challenge | Sonnet |
| `specifier` | Spec | Sonnet |
| `approver` | Approve plan | Haiku |
| `builder` | Build | Sonnet |
| `tester` | Build — TDD execution | Sonnet |
| `tdd-expert` | Build — TDD advisory | Sonnet |
| `simplifier` | Simplify | Haiku |
| `pr-creator` | PR Create | Haiku |
| `reviewer` | PR Review | Haiku |
| `retrospector` | Post — Retrospective | Sonnet |
| `php-code-simplifier` | On-demand — PHP safe refactor | Sonnet |
| `php-code-quality-reviewer` | On-demand — PHP bad-practice analysis | Sonnet |
