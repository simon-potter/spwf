# Workflow improvements — May 2026 session

This handover documents six interlocking improvements made to the SPWorkflow
marketplace in early May 2026. Each one started as a specific user request
and ended in shipped, versioned code that downstream projects pick up via
`/plugin marketplace update spwf`. The goal of this document is to let other
similar plugin/workflow projects benefit from the same patterns without
having to re-derive them.

The session moved spwf from `1.4.2` to `1.10.1` and spwf-agents from
`1.0.0` to `1.2.0`. Six commits land the substantive work; three more
land proposals and small alignments.

| Commit | What |
|---|---|
| `b184485` | Tracker abstraction (YouTrack default; Jira retained) |
| `dde0d89` | Forge abstraction (GitLab default; GitHub retained) |
| `5800c57` | `/spwf:recap` — teaching summary at close + Learning-modes guidance |
| `6908552` | Branch cleanup at close + git-smell check at capture |
| `9dc6f1a` | `/spwf:pause` — interrupt-safe context switch |
| `b1fa731` | `/spwf:migrate-todo` + close moves completed todos to `todo/_done/` |

If you're maintaining a sibling workflow plugin, reading this in order should
give you the architectural patterns and let you adopt selectively.

---

## 1. Tracker abstraction — YouTrack default, Jira retained

**Request.** *"Look at all references to Jira; in most of our use cases we
will be using YouTrack. Run YouTrack in parallel as an option (so we could
add others like Linear later) or, at a minimum, make it YouTrack not Jira."*

**Problem.** `capture`, `issue-to-task`, and `close` were hard-coded to the
Atlassian Jira MCP. Any team not on Jira had to either fork the skills or
not use them. The single-tracker assumption also leaked into prose
(`"Jira ticket"`), into frontmatter enums (`source: jira | scratch | …`), and
into hard-coded ticket-id examples (`PROJ-123`).

**What shipped.**
- New `plugins/spwf/skills/_shared/tracker-dispatch.md` — single source of
  truth for the operation contract (`get_issue` / `search_issues` /
  `create_issue` / `set_state`) with a dispatch table mapping each abstract
  operation to its YouTrack and Jira MCP tools.
- Three skills (`capture`, `issue-to-task`, `close`) now widen
  `allowed-tools` to the union of MCP namespaces and dispatch on the active
  tracker. Frontmatter `source:` enum widens; an explicit optional
  `tracker:` field disambiguates.
- Optional `.spwf/tracker.yaml` at repo root persists project-specific
  defaults (`tracker:`, `project:`, `done_state:`). All fields optional;
  asked-once-on-first-need otherwise.
- **Fail-fast contract.** When a tracker action is requested and no MCP
  responds, the skill halts with an actionable message. No silent
  fallback to a different mode.

**Architectural patterns to copy.**
- *Dispatch reference document* under `_shared/` is the canonical place for
  abstraction tables. Skills reference it; they don't repeat.
- *Optional minimal config file* (`.spwf/{x}.yaml`) for per-project
  defaults — the file exists only to persist answers the skill would
  otherwise ask. Auth and routing always live in user-level Claude Code
  MCP settings, never in the repo.
- *Per-instance reality* — YouTrack's MCP endpoint is per-installation
  (`{base-url}/mcp`); not a global URL. The dispatch reference documents
  this and provides a one-time setup walkthrough (instance URL, permanent
  token, MCP entry, discovery session for tool names).

**How to adopt.** If you're abstracting any external system (issue
tracker, monitoring, notification): create `_shared/{system}-dispatch.md`,
define an operation contract, populate the dispatch table per provider,
and have skills call abstract operations. Optional config file for
defaults; fail-fast on missing implementation.

---

## 2. Forge abstraction — GitLab default, GitHub retained

**Request.** *"Look at all references to GitHub. Run GitLab in parallel as
an option (so we could add others later) or, at a minimum, make it GitLab
not GitHub."*

**Problem.** `pr-create` and `pr-review` shelled out to `gh` directly. Any
team on GitLab had to fork the skills or use the GitHub-only flow. The
abstraction needed by trackers also applied here, but the substrate is
different — CLIs (`gh`, `glab`) instead of MCP servers, and there's a
better signal for auto-detection (the `git remote` URL).

**What shipped.**
- New `plugins/spwf/skills/_shared/forge-dispatch.md` documenting the
  operation contract (`view_request`, `diff_request`, `create_request`)
  with a dispatch table mapping each abstract op to concrete CLI
  invocations and flag mappings.
- `pr-create` and `pr-review` (and the `pr-creator` / `reviewer` agents)
  now resolve the active forge from `git remote get-url origin`, run
  `{cli} auth status`, fail fast on missing or unauthenticated CLI, and
  dispatch to the correct CLI with normalised flags.
- Optional `.spwf/forge.yaml` for self-hosted GitLab on non-`gitlab.*`
  domains, ambiguous remotes, or `forge: none` opt-out.
- JSON field normalisation table reconciles `gh --json` output (`number`,
  `body`, `baseRefName`, `headRefName`, `changedFiles`) with `glab
  --output json` output (`iid`, `description`, `target_branch`,
  `source_branch`, `changes_count`).
- Vocabulary mapping bakes in the GitHub-PR / GitLab-MR distinction:
  reports use the active forge's reference syntax (`#42` for GitHub,
  `!42` for GitLab) without the user having to think about it.

**Architectural patterns to copy.**
- *Auto-detect from intrinsic signals* before falling back to a config
  file. Most repos have a `git remote` already; making them write a
  `.spwf/forge.yaml` would be redundant. Detection rules: `github.com` →
  GitHub, `gitlab.com` or `gitlab.*` → GitLab, otherwise ask once and
  persist.
- *CLI dispatch can replace MCP dispatch* when the operations are
  shell-shaped (create / view / diff). CLIs are more complete and faster
  than current MCP servers for forge work; MCP is right for structured
  CRUD on stable schemas (which is why trackers are MCP).
- *Vocabulary mapping is part of the contract.* If two providers describe
  the same concept differently (PR vs MR, `#` vs `!`), the abstraction
  hides the surface, not the concept.

**How to adopt.** If you abstract over multiple CLIs, write a
`_shared/{x}-dispatch.md` with a JSON field normalisation table for any
shape divergence. Detect from `git remote` or another intrinsic signal
before requiring config. Keep skill names forge-agnostic
(`pr-create`/`pr-review` stays — internally agnostic, externally familiar).

---

## 3. `/spwf:recap` — teaching summary at close

**Request.** *"In the close/retrospective phase, add a mechanism to
summarise the key concepts in the task being completed for the user."*
Inspired by Boris Cherny's *Learning* / *Explanatory* output styles in
his Claude Code tips skill.

**Problem.** The retrospective at close already extracted rules for the
project (via `learn-from-mistakes`) but nothing crystallised takeaways for
the human. The user shipped the change but had no engagement check to
consolidate concepts, decisions, and surprises while context was warm.

**What shipped.**
- New `plugins/spwf/skills/recap/SKILL.md`. Five sections: What changed,
  Concepts touched, Decisions (why this not that), What surprised us,
  Read next.
- Default Part 5 of `retrospective` (one-key skip; changelog moved to
  Part 6). Inline rendering inside Part 5 — the recap *must* land in the
  user's eyes for comprehension to work; hiding it behind a file link
  defeats the purpose. Standalone-runnable as `/spwf:recap`.
- Save prompt default-no. When opted in, writes to
  `openspec/changes/{change-id}/recap.md` so it travels with the change
  into the OpenSpec archive automatically.
- **Anti-padding rules** baked into SKILL.md prompt: skip empty sections,
  per-section bullet caps (concepts 3–5, decisions 2–4, read-next ≤3),
  banned generic vocabulary ("software engineering", "best practices"),
  banned hedging phrases ("It is worth noting", "In conclusion"),
  tiny-change escape hatch (single substantive bullet → print one line).
- **"Learning modes" subsection** in `plugins/spwf/README.md` documenting
  Claude Code's `Explanatory` and `Learning` output styles for
  capture/challenge/early-build phases as the pre-hoc complement to
  recap.

**Architectural patterns to copy.**
- *Distinct learning targets — the project vs the user.* `learn-from-
  mistakes` writes to `docs/`; recap prints to the session. Same source
  data (commits, design.md), different audience.
- *Anti-padding rules in the prompt itself.* LLMs default to filling
  sections. Explicit instructions ("skip if no real material", "banned
  vocabulary list") move the floor up.
- *Inline presentation when comprehension is the goal.* Don't make the
  user open a file to engage with content that exists for engagement.
- *Pre-hoc / post-hoc complement.* Recap is post-hoc consolidation;
  output styles are pre-hoc coaching. Documenting both completes the
  story.

**How to adopt.** If you have a retrospective phase that extracts rules,
add a parallel comprehension step for the user. Keep the prompts
constrained — bullet caps and banned vocabulary turn into substantive
output instead of LLM filler.

---

## 4. Branch hygiene — close cleanup + capture smell check

**Request.** *"`/spwf:close` doesn't currently delete the local feature
branch even after PR and merge. Make it do so with sensible confirmations
and checks. `/spwf:capture` should also check for git smells if the branch
seems incorrect or stale and warn the user."*

**Problem.** Two related git-hygiene gaps at the start and end of the
workflow. After a PR was merged, the local feature branch lingered
indefinitely. At capture time, users sometimes started new work on a
stale branch, on `main` directly, or with uncommitted changes from
unrelated work — none of which the workflow caught.

**What shipped.**

*Close — Step 8 (delete local feature branch):*
- Identifies the candidate branch from current state (current branch if
  non-main; else `git branch --merged main` candidates).
- Four-stage safety: working tree clean → not currently on the branch
  (offer switch + pull) → branch is merged (ancestor check first; forge
  CLI fallback for squash-merge case via the existing forge dispatch;
  user confirmation as last resort) → no unpushed commits.
- `[Y/n]` default-delete; conscious 'n' to skip.
- `git branch -d` first; if refused (typical for squash-merge),
  explicit `[y/N]` for `git branch -D` (default no — force-delete is a
  separate decision needing explicit assent).
- Reports stale remote tracking refs without auto-deleting them — local
  cleanup is recoverable; remote delete is destructive shared state and
  stays in the user's hands.

*Capture — Step 0 (git smell check):*
- Runs before input fetch. Clean state produces no output; pristine
  repos see nothing.
- Hard warnings (interrupt with one stacked `[Y/n]` confirm): uncommitted
  changes, branch already merged into base and isn't the base, very
  stale branch (>30 days old AND >50 commits behind base).
- Soft notes (printed inline, no prompt): on `main`/`master`/base,
  branch is N commits behind base.
- Skip conditions: not in a git repo, repo has no commits yet.
  Brand-new projects pass through cleanly.

**Architectural patterns to copy.**
- *Asymmetric defaults.* Safe-delete prompt defaults yes (the cleanup
  the user wants); force-delete prompt defaults no (different decision,
  needs explicit assent).
- *One confirmation, many warnings.* When multiple smells fire in
  capture, stack them under one prompt. Don't ask N times.
- *Forge-aware fallbacks.* When local git can't tell merged state
  (squash-merge), fall back to forge CLI; only ask the user as last
  resort. Auto-detection beats interrogation.
- *Never auto-modify shared state.* Local branch delete is recoverable
  (commits live on remote). Remote branch delete is destructive shared
  state — never do it automatically; report and let the user decide.

**How to adopt.** The same four-stage safety pattern applies anywhere
you delete things: clean state → not currently using the thing → thing
is finished elsewhere → no pending work on the thing. The asymmetric
defaults (safe = yes, force = no) generalise to any cleanup operation.

---

## 5. `/spwf:pause` — interrupt-safe context switch

**Request.** *"A quality-of-life skill specifically about pausing to
switch context. Git worktrees are often not possible. Mid-flight on a
larger task, urgent bug arrives. Document current state in working docs,
detailed commit indicating what's been achieved and what's next, push,
switch back to main ready for the next capture."*

**Problem.** The interrupt scenario is common (urgent bug, customer
escalation, security issue) and worktrees aren't always available. Users
were either context-switching unsafely (lost in-flight work) or
ceremoniously (verbose manual journaling). Neither was good.

**What shipped.**
- New `plugins/spwf/skills/pause/SKILL.md`. Nine steps, but the user
  experience is: confirm scope → write a state note → confirm commit
  → done.
- Sanity halts: not in a git repo, already on base branch, nothing to
  pause (clean tree + up-to-date with upstream).
- Identifies context: branch, active todo file (matched by name), active
  OpenSpec change, last completed `[x]` and next `[ ]` task, uncommitted
  counts, commits ahead of upstream.
- Asks user for free-form state note in their own words — most important
  content of the pause record; not inferred from commits.
- Appends `## Pause — {timestamp}` section to active todo file; multiple
  pauses build a journal (never overwrites).
- Stages tracked changes default-yes; untracked default-no with explicit
  opt-in or per-file selection.
- Structured commit message: `wip: pause {ref} — {summary}` with State /
  Achieved / Next sections.
- Pushes (sets upstream if needed); never force-pushes; halts on diverged
  remote.
- Switches to base branch, pulls `--ff-only`.
- Optional `$ARGUMENTS` for ready-made next-capture command (e.g.
  `/spwf:pause ACAD-99` → suggests `/spwf:capture ACAD-99` in report).

**Architectural patterns to copy.**
- *Hard rules baked in.* Never force-push. Never auto-add untracked
  files. Never bypass pre-commit hooks. Never mark task progress on
  pause (pausing ≠ progress; only `/spwf:build` or the user marks tasks
  complete). Never let the pause escape locally — always push before
  switching.
- *User's own words for the most important content.* The state note is
  asked explicitly and never inferred. Inferred content is "achieved
  so far" and "next on resume" (extracted from tasks.md), surrounding
  the user's own paragraph.
- *Resume by convention, not orchestration.* `git checkout {branch}` +
  `/spwf:wfstatus` covers it — wfstatus already reads todo files. A
  dedicated `/spwf:resume` was deliberately deferred.

**How to adopt.** Any interrupt scenario benefits from this shape: hard
sanity checks, free-form state note, structured-yet-light commit message,
push-before-switch invariant. The hard rules ("never force-push") are
copy-paste invariants; the prompts and structure adapt to your domain.

---

## 6. `/spwf:migrate-todo` + close moves completed todos to `todo/_done/`

**Request.** *"A new quality-of-life skill that migrates a legacy todo
file/spec and turns it into a proper spec following our conventions. We
should be able to point it at a folder or specific file. Files with
correct frontmatter and status are skipped; others we attempt to
systematically integrate. Above and beyond that, when we close an issue,
it should probably move any completed todo files into todo/_done."*

**Problem.** Two interlocked gaps. (1) Projects adopting SPWorkflow arrive
with planning documents predating OpenSpec — there was no skill to audit
or normalise them. (2) `/spwf:close` marked a todo `status: complete` but
left the file in `todo/`, so over time `todo/` mixed live ideation with
completed work.

The two gaps had to ship together: closing the gap going forward (move on
close) without a one-shot migration leaves projects stuck with their
existing backlog; migrating without changing close means the backlog
refills.

**What shipped.**

*Close — Step 4 enhancement (`todo/_done/` move):*
- After the in-place `status: complete` edit:
  `mkdir -p todo/_done && git mv {todo-path} todo/_done/{filename}`.
- Collision check before moving: if `todo/_done/{filename}` already
  exists, halt with a clear message and let the user resolve manually.
  Never overwrite.
- The status edit and the move both land in Step 5's closure commit
  atomically.

*New `/spwf:migrate-todo` skill:*
- Six classification classes (first-match-wins): compliant active /
  compliant complete / partial frontmatter / no frontmatter / malformed /
  looks-like-non-todo (reference doc).
- doc-lint flag pattern (`--fix` interactive per-file, `--auto-fix` batch
  safe transforms, `--quick` frontmatter-only, default reports only,
  optional path arg).
- YAML-block-scoped frontmatter parsing (not whole-file grep — body
  prose like `Marketplace_setup.md:377` contains `status: ideation`
  outside the frontmatter block; naive grep would mis-match).
- **`status:` is never auto-inferred** — even in `--auto-fix`. The
  complete/ideation distinction drives the `_done/` move; too
  consequential to silent-default. `source:` and `created:` are
  inferred (scratch + git log first-commit date with mtime fallback).
- Idempotency guards: re-running on compliant files is a no-op; files
  in `todo/_done/` excluded from scope; move action checks destination
  doesn't exist.

**Why `_done/` is naturally safe.** `challenge`, `spec`, and `wfstatus`
all use top-level `todo/*.md` globs that don't recurse — files in
`todo/_done/` are correctly hidden from active scans without any other
skill changes. The frontmatter check hook still validates files in
subdirs (non-blocking warns).

**Architectural patterns to copy.**
- *Interlocked changes ship together.* Prospective fix (close moves
  going forward) + retroactive fix (migrate handles backlog) = one
  coherent unit. Don't ship halves.
- *Block-scoped parsing for frontmatter.* Body content can shadow
  frontmatter values. Parse the YAML block specifically, not the whole
  file with regex.
- *Out-of-scope discipline.* The migrator deliberately doesn't fabricate
  OpenSpec archive entries from legacy todos (the archive's value is
  "implemented & validated"; backfilling fakes a paper trail). It also
  doesn't rename files, doesn't merge into existing changes, doesn't
  validate status vocabulary. Keeping the scope tight made the design
  easy and the implementation small (~280 lines of SKILL.md).
- *Underscore-prefix subdirectory convention.* `_done/` is sorted last
  by most listers and signals "internal/archive" by convention.

**How to adopt.** If you have legacy artefacts that need to graduate
into a stricter convention: classify-first, normalise-second,
move-third. Mirror your existing lint skill's flag pattern for UX
consistency. Carefully separate auto-inferable fields from
judgement-dependent ones — the latter stay interactive in any mode.

---

## Cross-cutting patterns

These five patterns recurred across the session and are the load-bearing
abstractions for any sibling workflow plugin.

### `.spwf/{x}.yaml` — optional minimal config

`.spwf/tracker.yaml` and `.spwf/forge.yaml` follow the same rule:
**file is optional; all fields optional; asked-once-on-first-need otherwise**.
Auth tokens, secrets, and cross-instance routing live in user-level Claude
Code MCP settings — never in the repo. The repo carries only the routing
information (which tracker / which forge / which project / what default
state).

### `_shared/{x}-dispatch.md` — single source of truth for abstractions

Skills don't repeat dispatch tables inline. They reference `_shared/{x}-
dispatch.md` which holds the operation contract, the per-provider mapping,
provider-specific notes (auth, ID format, vocabulary quirks), and an
"adding a new provider" walkthrough. Adding a third provider becomes a
documentation row, not a skill rewrite.

### Fail-fast contract on missing dependencies

When a skill needs an external dependency (tracker MCP, forge CLI) and
it's not configured, halt with a clear, actionable message. **No silent
fallback to a different mode** — silence creates surprises. The actionable
message names the configuration step needed.

### Default-on with conscious skip

Default-on with one-key skip beats opt-in for cleanup operations. The user
asked for `[Y/n]` (default delete) on branch cleanup, mirroring the same
shape elsewhere. Both 'y' and 'n' are conscious; the default biases toward
the cleaner outcome. Force-delete and similar destructive variants flip
the default to `[y/N]` — different decision, different default.

### Auto-detect from intrinsic signals before requiring config

Detect the forge from `git remote get-url origin`. Detect the tracker
from which MCP is reachable. Detect the feature branch from current state.
Most repos have these signals already; making the user write a config file
to repeat what `git remote` already tells you is friction without payoff.
Optional config file is the override, not the default.

---

## Versions at end of session

- `spwf` plugin: `1.10.1` (was `1.4.2`)
- `spwf-agents` plugin: `1.2.0` (was `1.0.0`)
- 30 workflow skills, 13 specialist subagents
- 6 new shared reference documents in `plugins/spwf/skills/_shared/`
  (tracker-dispatch, forge-dispatch)

## Pre-existing drift not addressed

`/.claude-plugin/marketplace.json` shows `spwf` and `spwf-agents` at
`1.0.0` while plugin.json values are far ahead. This is unrelated to
this session's work and deserves its own small follow-up PR (or a hook
that auto-syncs).

## Pointers

| Topic | Where to look |
|---|---|
| Tracker abstraction | `plugins/spwf/skills/_shared/tracker-dispatch.md`, commits `b184485` and follow-ups |
| Forge abstraction | `plugins/spwf/skills/_shared/forge-dispatch.md`, commit `dde0d89` |
| Recap skill | `plugins/spwf/skills/recap/SKILL.md`, commit `5800c57` |
| Branch hygiene | `plugins/spwf/skills/close/SKILL.md` Step 8, `plugins/spwf/skills/capture/SKILL.md` Step 0, commit `6908552` |
| Pause skill | `plugins/spwf/skills/pause/SKILL.md`, commit `9dc6f1a` |
| Migrate-todo + `_done/` | `plugins/spwf/skills/migrate-todo/SKILL.md`, `plugins/spwf/skills/close/SKILL.md` Step 4, commit `b1fa731` |
| Original session proposals | `todo/Jira_to_youtrack.md`, `todo/Github_to_Gitlab.md`, `todo/learn-with-claude.md` |
