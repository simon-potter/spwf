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
| `close` | `/spwf:close [todo/{slug}.md]` | `retrospective` (learn-from-mistakes → spec audit → `doc-lint` → `workflow-lint` → optional changelog) → mark todo complete → `opsx:archive` → tracker transition to done state (per `.spwf/tracker.yaml`; YouTrack default, Jira supported) |

### Atomic skills

| Skill | Invoke | Phase / Responsibility |
|---|---|---|
| `wfstatus` | `/spwf:wfstatus` | Pre — Session orientation: where am I, what's next |
| `pause` | `/spwf:pause [next-ref]` | Interrupt — Document state, commit + push in-flight work, switch to main ready for the next capture |
| `issue-to-task` | `/spwf:issue-to-task` | Pre — Capture from issue tracker (YouTrack default; Jira and others supported) |
| `new-task` | `/spwf:new-task` | Pre — Capture from scratch |
| `challenge` | `/spwf:challenge [file]` | Gate — Interview until all questions resolved; scope-sizing check recommends splitting or proceeding as one change |
| `grill-me` | `/spwf:grill-me [file]` | Gate — Challenge (deprecated: use `challenge`) |
| `spec` | `/spwf:spec` | 1 — Convert ideation file into full OpenSpec change proposal |
| `approve-plan` | `/spwf:approve-plan` | 2 — Quality-check task list; human sign-off gate |
| `write-tests` | `/spwf:write-tests` | 3 — Red phase: write failing tests before implementation |
| `run-tests` | `/spwf:run-tests` | 3 — Run full test suite; stop on first failure |
| `debug-recovery` | `/spwf:debug-recovery` | 3 — Diagnose failing test or broken build; minimal fix |
| `simplify` | `/spwf:simplify` | 4 — Remove dead code and unnecessary complexity |
| `pr-create` | `/spwf:pr-create` | 5 — Pre-flight checks then PR creation |
| `pr-review` | `/spwf:pr-review <PR>` | 6 — Fetch and review a PR; structured report |
| `learn-from-mistakes` | `/spwf:learn-from-mistakes` | Post — Extract learnings from commits (rules for the project) |
| `recap` | `/spwf:recap [change-id]` | Post — Teaching summary for the user: concepts touched, decisions made, surprises, growth pointers |
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
| `migrate-todo` | `/spwf:migrate-todo [path]` | Audit `todo/` for legacy files. Compliant frontmatter is skipped; partial/legacy files get normalised; `status: complete` files move to `todo/_done/`. Mirrors doc-lint flags (`--fix` interactive, `--auto-fix` batch). |
| `security-scan` | `/spwf:security-scan [path]` | Deep security review: OWASP Top 10 + SQL injection across PHP, Python, JS, Go. |
| `dep-audit` | `/spwf:dep-audit` | Multi-ecosystem dependency CVE audit (npm, Composer, pip, cargo, govulncheck, bundle). Docker Compose-aware. |
| `php-code-simplifier` | `/spwf:php-code-simplifier [path]` | PHP-aware safe refactor: guard clauses, match, nullsafe, null coalescing, debug removal. |
| `php-code-quality-reviewer` | `/spwf:php-code-quality-reviewer [path]` | PHP bad-practice analysis: correctness, security, performance, maintainability. |

## Hooks

Four hooks ship with the plugin and register automatically on install. All are advisory — they exit 0 and never block tool execution.

| Hook | Event | What it does |
|---|---|---|
| `uncommitted-changes` | `Stop` | Warns at session end if `git status` shows uncommitted changes |
| `plugin-version-check` | `PostToolUse Write\|Edit` | When `plugin.json` is modified, warns if the version field was not incremented |
| `todo-frontmatter-check` | `PostToolUse Write\|Edit` | When a `todo/*.md` file is written, validates `source`, `status`, and `created` frontmatter fields are present |
| `openspec-validate-nudge` | `PostToolUse Write\|Edit` | When `openspec/changes/**/tasks.md` is written, prints the `openspec validate {id} --strict` command |

**Prerequisites:** `git` must be in PATH. JSON parsing requires `jq` or `python3` — if neither is present the hook prints a named warning and skips rather than silently doing nothing.

## Recommended external skills

| Skill | Source | When referenced |
|---|---|---|
| `semgrep` | `trailofbits/skills` | Invoked as `/trailofbits:semgrep`. Referenced by `pr-create` for deep SAST review and by `approve-plan` when security-sensitive tasks are flagged. |

## Ideation file format

Both `issue-to-task` and `new-task` produce the same lightweight ideation file at `todo/{slug}.md`. This is the input to `challenge` and `spec`.

```markdown
---
source: youtrack | jira | linear | scratch
tracker: youtrack         # omit if scratch
ticket: ACAD-42           # tracker-agnostic id; omit if scratch
created: YYYY-MM-DD
status: ideation
---

# {Title}

## Context
## What we know
## Open questions
## Rough scope
```

## Forge integration

`pr-create` and `pr-review` (and the `pr-creator` / `reviewer` agents) are
forge-agnostic. The active forge is auto-detected from `git remote get-url
origin`:

- `github.com` → GitHub, uses `gh`
- `gitlab.com` or `gitlab.{anything}` → GitLab, uses `glab`
- Other / ambiguous → asked once and offered for save to `.spwf/forge.yaml`

GitLab is the default when both CLIs are installed and detection lands on a
GitLab host; GitHub is used when detection lands on a GitHub host. Neither CLI
present + a forge action requested = **fail fast** with installation
instructions. No silent fallback.

Optional `.spwf/forge.yaml` in the repo root (only needed for self-hosted
GitLab on a non-`gitlab.*` domain or to opt out):

```yaml
forge: gitlab              # github | gitlab | bitbucket | gitea | none
host: gitlab.example.com   # self-hosted host (auto-derived when possible)
default_base: main         # base branch for PR/MR creation (usually auto-detected)
```

Set `forge: none` to disable forge-touching skills entirely. Auth tokens live
in `gh auth login` / `glab auth login`, never in the repo. Full reference
(including JSON field normalisation between `gh --json` and
`glab --output json`, and how to add Bitbucket/Gitea/Forgejo): `skills/_shared/forge-dispatch.md`.

## Issue tracker integration

`capture`, `issue-to-task`, and `close` assume an issue tracker MCP is configured. If
it isn't and a tracker action is requested, the skill **fails fast** with an
actionable message — no silent fallback.

Default detection: probe `mcp__youtrack__*` then `mcp__atlassian__jira_*`. First match
wins. Override per-project in `.spwf/tracker.yaml` (all fields optional):

```yaml
tracker: youtrack          # youtrack | jira | linear | none
project: ACAD              # default project for create_issue
done_state: Done           # state name for close transition
```

Set `tracker: none` to opt out of tracker integration entirely. Auth tokens, URLs, and
multi-instance routing live in user-level Claude Code MCP settings — never in the repo.

Full reference: `skills/_shared/tracker-dispatch.md` (covers YouTrack setup, the
multi-instance `mcp_server:` override, the discovery session for pinning tool names,
and how to add Linear or other trackers).

## Learning modes (in-session)

Claude Code ships two output styles that change how Claude *thinks* during a
session, not just how it writes:

- **`Explanatory`** — Claude states *why* it's making each change as it works.
  Useful when onboarding to an unfamiliar codebase or when a teammate will
  read the diff cold and shouldn't have to reconstruct your reasoning.
- **`Learning`** — Claude coaches you through the change rather than making
  it for you. Useful when you want to grow expertise on the topic at hand,
  not just ship.

These are most valuable during **capture**, **challenge**, and early **build**
when forming understanding. The TDD-disciplined `build` loop runs faster in
the default style.

The post-hoc complement is `/spwf:recap` — at close, it crystallises concepts
and decisions from a change you've already shipped.

Set with the `--output-style` flag at launch, or `outputStyle` in
`settings.json`. See [Claude Code output styles](https://docs.claude.com/en/docs/claude-code/output-styles).

## Attribution

Five skills are seeded from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT licence). Each carries an attribution comment in its SKILL.md frontmatter.

| Skill | Source |
|---|---|
| `approve-plan` | `planning-and-task-breakdown` |
| `run-tests` | `test-driven-development` |
| `simplify` | `code-simplification` |
| `pr-create` | `git-workflow-and-versioning` |
| `build` | `incremental-implementation` (upstream orchestrator pattern) |
