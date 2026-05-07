# spwf

28 engineering workflow skills covering the full cycle: capture, challenge, spec, plan, build, test, review, simplify, ship, learn, and quality maintenance. All skills set `disable-model-invocation: true` — explicit user-triggered checkpoints, not autonomous suggestions.

## Two-tier architecture

Skills are organised in two named tiers within the single `skills/` directory:

- **Atomic skills** — single-responsibility capabilities with descriptive names. Can be invoked directly or composed by orchestrators.
- **Orchestrator skills** — short action names that compose one or more atomic skills. Their body explicitly names the atomics they invoke.

## Core workflow skills

### Orchestrator skills

| Skill | Invoke | Composes |
|---|---|---|
| `capture` | `/spwf:capture [source]` | Classifies input as bug or change → bug path: investigation + `todo/BUG-{slug}.md`; change path: `issue-to-task` / `new-task` + `todo/{slug}.md` |
| `build` | `/spwf:build` | `write-tests` (Red) → `opsx:apply` (Green) → `run-tests` (Verify) → `debug-recovery` on failure → `opsx:verify` (spec sign-off) → recommends `simplify` (Refactor) |
| `retrospective` | `/spwf:retrospective` | `learn-from-mistakes` → change spec audit → `doc-lint` → `workflow-lint` → `changelog` (release only). Called automatically by `close`. |
| `close` | `/spwf:close [todo/{slug}.md]` | `retrospective` → mark todo complete → `opsx:archive` → Jira transition to Done |

### Atomic skills

| Skill | Invoke | Phase / Responsibility |
|---|---|---|
| `wfstatus` | `/spwf:wfstatus` | Pre — Session orientation: where am I, what's next |
| `issue-to-task` | `/spwf:issue-to-task` | Pre — Capture from Jira |
| `new-task` | `/spwf:new-task` | Pre — Capture from scratch |
| `challenge` | `/spwf:challenge [file]` | Gate — Surface gaps before committing to spec |
| `grill-me` | `/spwf:grill-me [file]` | Gate — Challenge (deprecated: use `challenge`) |
| `spec` | `/spwf:spec` | 1 — Convert ideation file into full OpenSpec change proposal |
| `approve-plan` | `/spwf:approve-plan` | 2 — Quality-check task list; human sign-off gate |
| `write-tests` | `/spwf:write-tests` | 3 — Red phase: write failing tests before implementation |
| `run-tests` | `/spwf:run-tests` | 3 — Run full test suite; stop on first failure |
| `debug-recovery` | `/spwf:debug-recovery` | 3 — Diagnose failing test or broken build; minimal fix |
| `simplify` | `/spwf:simplify` | 4 — Remove dead code and unnecessary complexity |
| `pr-create` | `/spwf:pr-create` | 5 — Pre-flight checks then PR creation |
| `pr-review` | `/spwf:pr-review <PR>` | 6 — Fetch and review a PR; structured report |
| `learn-from-mistakes` | `/spwf:learn-from-mistakes` | Post — Extract learnings from commits |
| `changelog` | `/spwf:changelog [ref]` | Post — Release notes from conventional commits |

## Quality tools

Cross-cutting maintenance tools — run between sessions, on a cadence, or when something feels off. They don't produce code; they keep the workspace in good shape.

| Skill | Invoke | Responsibility |
|---|---|---|
| `workspace-health` | `/spwf:workspace-health` | Periodic health check: agentlint scan + behavioural audit + sync check. Produces P1/P2/P3 action report. |
| `claudemd-curator` | `/spwf:claudemd-curator` | Audit, refactor, and sync CLAUDE.md and AGENTS.md. Five-phase pipeline: inventory → behavioural audit → layer classification → sync check → proposal. |
| `workflow-lint` | `/spwf:workflow-lint` | Golden path coherence audit: step↔skill coverage, agent coverage, cross-reference validity. |
| `agent-optimise` | `/spwf:agent-optimise` | Lightweight agent/skill audit. Use when agentlint is unavailable or as a quick spot-check. |
| `doc-lint` | `/spwf:doc-lint` | Documentation drift check: stale READMEs, broken links, misaligned specs. |
| `security-scan` | `/spwf:security-scan [path]` | Deep security review: OWASP Top 10 + SQL injection across PHP, Python, JS, Go. |
| `dep-audit` | `/spwf:dep-audit` | Multi-ecosystem dependency CVE audit (npm, Composer, pip, cargo, govulncheck, bundle). Docker Compose-aware. |
| `php-code-simplifier` | `/spwf:php-code-simplifier [path]` | PHP-aware safe refactor: guard clauses, match, nullsafe, null coalescing, debug removal. |
| `php-code-quality-reviewer` | `/spwf:php-code-quality-reviewer [path]` | PHP bad-practice analysis: correctness, security, performance, maintainability. |

## Recommended external skills

| Skill | Source | When referenced |
|---|---|---|
| `semgrep` | `trailofbits/skills` | Invoked as `/trailofbits:semgrep`. Referenced by `pr-create` for deep SAST review and by `approve-plan` when security-sensitive tasks are flagged. |

## Ideation file format

Both `issue-to-task` and `new-task` produce the same lightweight ideation file at `todo/{slug}.md`. This is the input to `challenge` and `spec`.

```markdown
---
source: jira | scratch
ticket: PROJ-123          # omit if scratch
created: YYYY-MM-DD
status: ideation
---

# {Title}

## Context
## What we know
## Open questions
## Rough scope
```

## Attribution

Five skills are seeded from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT licence). Each carries an attribution comment in its SKILL.md frontmatter.

| Skill | Source |
|---|---|
| `approve-plan` | `planning-and-task-breakdown` |
| `run-tests` | `test-driven-development` |
| `simplify` | `code-simplification` |
| `pr-create` | `git-workflow-and-versioning` |
| `build` | `incremental-implementation` (upstream orchestrator pattern) |
