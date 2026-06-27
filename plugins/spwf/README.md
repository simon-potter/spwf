# spwf

34 engineering workflow skills covering the full cycle: capture, challenge, spec, plan, build, test, simplify (with self-review), ship, peer review, address review, learn, branch-rescue, and quality maintenance. All skills set `disable-model-invocation: true` — explicit user-triggered checkpoints, not autonomous suggestions.

## Two-tier architecture

Skills are organised in two named tiers within the single `skills/` directory:

- **Atomic skills** — single-responsibility capabilities with descriptive names. Can be invoked directly or composed by orchestrators.
- **Orchestrator skills** — short action names that compose one or more atomic skills. Their body explicitly names the atomics they invoke.

## Core workflow skills

### Orchestrator skills

| Skill | Invoke | Composes |
|---|---|---|
| `capture` | `/spwf:capture [source]` | Classifies input as bug or change → bug path: investigation + `todo/BUG-{slug}.md`; change path: `issue-to-task` / `new-task` + `todo/{slug}.md` |
| `build` | `/spwf:build` | Phase 0 verifies the feature branch (Layer 2 — halts/offers if on base with an active change) → `write-tests` (Red) → `opsx:apply` (Green) → `run-tests` (Verify) → `debug-recovery` on failure → `opsx:verify` (spec sign-off) → recommends `simplify` (Refactor) |
| `close` | `/spwf:close [todo/{slug}.md]` | `retrospective` (learn-from-mistakes → spec audit → `doc-lint` → `workflow-lint` → optional changelog) → mark todo complete → tracker transition to done state → `opsx:archive` (per `.spwf/tracker.yaml`; YouTrack default, Jira and Beads via spwf-beadsify also supported) |

### Atomic skills

| Skill | Invoke | Phase / Responsibility |
|---|---|---|
| `wfstatus` | `/spwf:wfstatus` | Pre — Session orientation: where am I, what's next |
| `pause` | `/spwf:pause [next-ref]` | Interrupt — Document state, commit + push in-flight work, switch to main ready for the next capture |
| `issue-to-task` | `/spwf:issue-to-task` | Pre — Capture from issue tracker (YouTrack default; Jira and Beads via spwf-beadsify also supported via tracker-dispatch) |
| `new-task` | `/spwf:new-task` | Pre — Capture from scratch |
| `challenge` | `/spwf:challenge [file]` | Gate — Interview until all questions resolved; scope-sizing check recommends splitting or proceeding as one change |
| `grill-me` | `/spwf:grill-me [file]` | Gate — Challenge (deprecated: use `challenge`) |
| `spec` | `/spwf:spec` | 1 — Convert ideation file into full OpenSpec change proposal; auto-creates `feature/{change-id}` before committing (Layer 1, see [Branching](#branching)); carries the ideation `ticket:` into the proposal `**Tracker**:` line |
| `approve-plan` | `/spwf:approve-plan` | 2 — Quality-check task list; human sign-off gate |
| `write-tests` | `/spwf:write-tests` | 3 — Red phase: write failing tests before implementation |
| `run-tests` | `/spwf:run-tests` | 3 — Run full test suite; stop on first failure |
| `debug-recovery` | `/spwf:debug-recovery` | 3 — Diagnose failing test or broken build; minimal fix |
| `simplify` | `/spwf:simplify` | 4 — Two-pass cleanup: (1) mechanical removal of dead code + unnecessary complexity; (2) `reviewer` subagent in local-diff mode against pinned commit range with openspec proposal + tasks as intent baseline (adapted from obra/superpowers `requesting-code-review`) |
| `pr-create` | `/spwf:pr-create` | 5 — Pre-flight checks then PR creation; if on base with commits, offers automated `branch-rescue` (Layer 3); ends by pointing at `/spwf:close` for the post-merge retrospective |
| `branch-rescue` | `/spwf:branch-rescue` | Recovery — moves commits that leaked onto the base branch onto `feature/{change-id}` and resets local base (local-only; surfaces the force-push command, never auto-pushes). Standalone or invoked by `pr-create`. See [Branching](#branching) |
| `pr-review` | `/spwf:pr-review <PR>` | 6 — Fetch and review a PR; structured report |
| `address-review` | `/spwf:address-review [report \| ref]` | 6.5 — Turn review feedback (report file or fetched PR/MR comments) into commits or reasoned push-backs; forbids performative agreement (adapted from obra/superpowers `receiving-code-review`) |
| `learn-from-mistakes` | `/spwf:learn-from-mistakes` | Post — Extract learnings from commits (rules for the project) |
| `recap` | `/spwf:recap [change-id]` | Post — Teaching summary for the user: concepts touched, decisions made, surprises, growth pointers |
| `tracker-comment` | `/spwf:tracker-comment [issue-id]` | On-demand — Post an audience-aware comment to the linked tracker issue. Classifies as human (rewrites for plain English, ≤150 words, one clear ask) or record (light cleanup, full technical detail allowed). |
| `changelog` | `/spwf:changelog [ref]` | Post — Release notes from conventional commits |

## Branching

Branching is enforced in three layers so commits never pile up on the base
branch by accident:

- **Layer 1 — `spec`** auto-creates `feature/{change-id}` before its commit.
- **Layer 2 — `build`** verifies the branch in Phase 0; halts with a switch
  offer if on the base with an active change.
- **Layer 3 — `pr-create` / `branch-rescue`** offers an automated rescue when
  work already leaked onto the base — local-only moves, force-push surfaced for
  manual execution.

Configure or opt out via an optional `.spwf/branch.yaml` (`prefix:`, `base:`,
`auto_branch: always | ask | never`, `enforce: true | false`). Full schema and
the detect-state / auto-branch / rescue logic:
[`skills/_shared/branch-management.md` § config schema](skills/_shared/branch-management.md#1-config-schema-spwfbranchyaml).

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

Five hooks ship with the plugin and register automatically on install. All are advisory — they exit 0 and never block tool execution. See `hooks/README.md` for conventions and how to add a new one.

| Hook | Event | What it does |
|---|---|---|
| `uncommitted-changes` | `Stop` | Warns at session end if `git status` shows uncommitted changes |
| `plugin-version-check` | `PostToolUse Write\|Edit` | When `plugin.json` is modified, warns if the version field was not incremented |
| `todo-frontmatter-check` | `PostToolUse Write\|Edit` | When a `todo/*.md` file is written, validates `source`, `status`, and `created` frontmatter fields are present |
| `openspec-validate-nudge` | `PostToolUse Write\|Edit` | When `openspec/changes/**/tasks.md` is written, prints the `openspec validate {id} --strict` command |
| `tracker-comment-nudge` | `PreToolUse` (tracker write tools) | Before a tracker write (`mcp__youtrack__*`, Jira create/update/add_comment), warns if the body looks heavy-technical (≥2 code blocks + >600 chars, or ≥1 code block + ≥5 file refs) and suggests `/spwf:tracker-comment` for audience-aware rewriting. Advisory only — never blocks. |

**Prerequisites:** `git` must be in PATH. JSON parsing requires `jq` or `python3` — if neither is present the hook prints a named warning and skips rather than silently doing nothing.

## Recommended external skills

| Skill | Source | When referenced |
|---|---|---|
| `semgrep` | `trailofbits/skills` | Invoked as `/trailofbits:semgrep`. Referenced by `pr-create` for deep SAST review and by `approve-plan` when security-sensitive tasks are flagged. |
| `impeccable` | `pbakaus/impeccable` | Invoked as `/impeccable polish`, `/impeccable audit`, `/impeccable critique`. Referenced by `simplify` as a follow-up recommendation when the diff touches frontend files (`.tsx`, `.jsx`, `.vue`, `.svelte`, `.css`, `.scss`). Optional — `simplify` surfaces the suggestion in its report but never calls the command, so the skill is fine if `impeccable` is not installed. |

Recommended external plugins are never bundled, never auto-installed, and never assumed-present by spwf skills. The skills that reference them surface the suggestion in their report output only — if the external plugin is not installed, the recommendation reads as informational. Install (per-user or per-project):

```bash
# Trail of Bits security skills
/plugin marketplace add trailofbits/skills
/plugin install semgrep@trailofbits

# Impeccable design quality skill (frontend)
/plugin marketplace add pbakaus/impeccable
/plugin install impeccable@impeccable
```

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

`capture`, `issue-to-task`, `tracker-comment`, and `close` dispatch to the active
tracker via `_shared/tracker-dispatch.md`. Two backend types are supported:

- **MCP backends** (YouTrack default, Jira supported) — auto-probed if `tracker:` is
  unset; explicit via `tracker: youtrack` / `tracker: jira`.
- **Skill backends** (Beads via `spwf-beadsify`) — opt-in only via `tracker: beads`;
  never auto-probed. Requires the [Beads CLI](https://github.com/gastownhall/beads)
  and the `spwf-beadsify` plugin installed.

If a tracker action is requested and the active tracker is unavailable, the skill
**fails fast** with an actionable, backend-type-aware message — no silent fallback.

Override per-project in `.spwf/tracker.yaml` (all fields optional):

```yaml
tracker: youtrack          # youtrack | jira | linear | beads | none
project: ACAD              # default project for create_issue (ignored for beads)
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

Several skills are seeded from external sources. Each carries an attribution comment in its SKILL.md frontmatter.

From [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT licence):

| Skill | Source |
|---|---|
| `approve-plan` | `planning-and-task-breakdown` |
| `run-tests` | `test-driven-development` |
| `simplify` | `code-simplification` |
| `pr-create` | `git-workflow-and-versioning` |
| `build` | `incremental-implementation` (upstream orchestrator pattern) |

From [obra/superpowers](https://github.com/obra/superpowers) (MIT licence; authors: Jesse Vincent and the Prime Radiant team):

| Skill | Source |
|---|---|
| `simplify` (Pass 2) | `requesting-code-review` — folded into simplify as the post-cleanup reviewer dispatch against local diff |
| `address-review` | `receiving-code-review` — verify-before-implement posture, no performative agreement |

No SKILL.md content from either upstream source is reproduced verbatim — concepts (severity tiers, "review early, review often", READ → VERIFY → EVALUATE loop, the forbidden-phrase list) are adapted into our own prose with this codebase's conventions. Upstream copyright notices are preserved via the frontmatter comments in each affected SKILL.md.
