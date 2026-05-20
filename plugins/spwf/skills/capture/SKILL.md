---
# Qualification heuristic inspired by: https://skills.sh/obra/superpowers/brainstorming (obra superpowers)
# Bug investigation adapted from: https://skills.sh/obra/superpowers/systematic-debugging (obra superpowers)
# Adaptation: investigation-only — stops before implementation; produces an ideation artefact
# that feeds into Challenge → Spec → Build rather than fixing inline.
name: capture
description: Pre-phase orchestrator — accepts any input (issue tracker ticket, Slack message, file, or freeform description), classifies it as a bug or a change, then routes to the appropriate path. Bug path runs systematic root-cause investigation and produces todo/BUG-{slug}.md. Change path runs a lightweight qualification check and produces todo/{slug}.md. Both outputs feed /spwf:challenge.
disable-model-invocation: true
allowed-tools: [Read, Write, Glob, Grep, Bash, mcp__youtrack__*, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_search_issues, mcp__atlassian__jira_create_issue, mcp__atlassian__jira_update_issue]
---

# capture

Accept any input, classify it, and produce an ideation file ready for `/spwf:challenge`.

## Step 0 — Git context check

Lightweight scan of the current git state. Hard warnings interrupt with one
confirmation; soft notes print inline and continue. Clean state produces no
output — pristine repos see nothing.

### Collect

```bash
BRANCH=$(git branch --show-current)
DEFAULT_BASE=${DEFAULT_BASE:-main}
HAS_BASE=$(git show-ref --verify --quiet "refs/heads/$DEFAULT_BASE" && echo yes || echo no)
DIRTY_COUNT=$(git status --porcelain | wc -l | tr -d ' ')
LAST_COMMIT_DAYS=$(( ($(date +%s) - $(git log -1 --format=%ct 2>/dev/null || date +%s)) / 86400 ))
BEHIND=0
AHEAD=0
ALREADY_MERGED=no
if [ "$HAS_BASE" = "yes" ] && [ "$BRANCH" != "$DEFAULT_BASE" ] && [ "$BRANCH" != "master" ]; then
  BEHIND=$(git rev-list --count "HEAD..$DEFAULT_BASE" 2>/dev/null || echo 0)
  AHEAD=$(git rev-list --count "$DEFAULT_BASE..HEAD" 2>/dev/null || echo 0)
  git merge-base --is-ancestor HEAD "$DEFAULT_BASE" 2>/dev/null && ALREADY_MERGED=yes || true
fi
```

If the repo has no commits at all (`git log` fails), skip this step entirely.

### Smell rules

| Smell | Detection | Severity |
|---|---|---|
| Working tree has uncommitted changes | `DIRTY_COUNT > 0` | **Hard** |
| Branch is already merged into base (and isn't the base) | `ALREADY_MERGED == yes` and `AHEAD == 0` | **Hard** — the branch is leftover; new work should probably start fresh |
| Branch is very stale | `LAST_COMMIT_DAYS > 30` AND `BEHIND > 50` | **Hard** |
| Currently on `main` / `master` / base | `BRANCH == DEFAULT_BASE` or `master` | Soft note — capture writes ideation only; branching happens at spec/build |
| Branch is behind base | `BEHIND > 0` (and not already covered by stale rule) | Soft note |

### Hard warnings (interrupt with single confirmation)

If any hard smells fire, print them stacked under one warning header and ask
once:

```
⚠ Git smells detected:
  • Working tree has 3 uncommitted changes
  • Branch `old-feature` is already merged into main (29 commits behind)

Continue capture anyway? [Y/n]
```

Press enter / 'y' to proceed. 'n' aborts capture cleanly with no file
written. The warning is one prompt regardless of how many smells fired —
don't ask repeatedly.

### Soft notes (informational, no prompt)

For each soft note, print one line and continue:

```
ℹ On `main` — capture writes the ideation file; spec or build will branch.
ℹ Branch `feature/x` is 4 commits behind `main`.
```

### Skip conditions

Skip Step 0 entirely (no output, no checks) if:
- Not in a git repo (`git rev-parse --is-inside-work-tree` non-zero), OR
- The repo has no commits yet

This keeps brand-new projects and non-git contexts from tripping the smell
checks.

---

## Step 1 — Fetch input

Read `$ARGUMENTS`:

| Input pattern | Action |
|---|---|
| Empty | Ask: "What are you capturing? (issue tracker ticket key, file path, or describe it)" |
| Tracker ticket key (e.g. `ACAD-42`, `PROJ-123`) or `from {tracker} TICKET` | **Tracker** — dispatch to the configured tracker's `get_issue` per `_shared/tracker-dispatch.md` |
| File path ending `.md` | **File** — read existing file |
| `from slack` or input explicitly attributed to a Slack message | **Slack** — treat body as freeform; record source as `slack` |
| Anything else | **Freeform** — treat as-is |

For tracker fetches, extract: summary, description, acceptance criteria, issue type,
labels/tags, priority/state.

**Fail fast on missing tracker.** If the user supplied a ticket-shaped argument and
no tracker is available in this session, stop with the dispatch-resolved error and
do not silently fall back to freeform. "Available" depends on which kind of backend
is configured (see `_shared/tracker-dispatch.md`):

- **MCP backend** (`tracker: youtrack` / `jira`, or unset and one of the MCPs is
  configured): available iff the MCP's tools (`mcp__youtrack__*`,
  `mcp__atlassian__jira_*`, etc.) respond. If neither responds and `tracker:` is
  unset, halt with: *"No issue tracker MCP configured. Add YouTrack or Atlassian MCP
  in user settings, or set `tracker: none` in `.spwf/tracker.yaml` to skip tracker
  steps. (For an in-repo tracker, set `tracker: beads` and install spwf-beadsify.)"*
- **Skill backend** (`tracker: beads` and similar): available iff the backend
  module SKILL.md is loadable in this session. If `tracker: beads` is set but
  `spwf-beadsify` is not installed, halt with the verbatim error from
  `_shared/tracker-dispatch.md` § "Configured-but-not-installed error".

Tracker selection: see `_shared/tracker-dispatch.md`. The default probe is YouTrack
→ Jira (MCP backends only — skill backends are never auto-probed; they require an
explicit `tracker:` setting in `.spwf/tracker.yaml`).

---

## Step 2 — Classify: bug or change?

Apply in order — stop at the first confident match.

**Bug signals:**
- Tracker issue type is `Bug` (YouTrack `Type: Bug` / Jira `issuetype = Bug`)
- Input contains a stack trace (multi-line with file paths and line numbers)
- Input contains: `error`, `exception`, `crash`, `traceback`, `not working`, `broken`, `failing`, `regression`, `wrong`, `incorrect`, `500`, `null pointer`, `undefined is not`
- Input starts with `BUG:` or `FIX:`

**Change signals:**
- Tracker issue type is a feature/work category (YouTrack `Feature / Task / Epic` / Jira `Story / Task / Epic / Improvement`)
- Input contains: `add`, `implement`, `build`, `create`, `new feature`, `support`, `allow`, `as a user`
- Input describes a desired future state

**If ambiguous** — ask one question: *"Is this something that's broken, or something new to build?"* Then route accordingly.

---

## Bug path

### Phase 1 — Gather context

Collect as much of the following as is available:

- Error message and full stack trace (ask the user if not provided)
- Steps to reproduce consistently
- Recent git changes in the relevant area: `git log --oneline -20 -- {relevant paths}`
- Environment context (version, config, runtime)

For multi-component systems, identify at which boundary the failure occurs before assuming a root cause.

### Phase 2 — Root cause investigation

Trace backward from the symptom:

1. Read the error message and stack trace carefully — where does the trace originate?
2. Read the code at the failure site and its callers
3. Check git history for recent changes: `git log --oneline -10 -- {file}`
4. Look for similar working code — compare working vs broken

Document every difference found, however minor.

### Phase 3 — Pattern analysis

Find working code structurally similar to the broken code. Compare completely:

- What assumptions does the working code make that the broken code does not?
- What dependencies differ?
- What does the broken code do that the working code avoids?

### Phase 4 — Form a written hypothesis

Write a single, specific hypothesis:

```
Hypothesis: {The bug is caused by X, because Y. Evidence: Z.}
```

Rules:
- One hypothesis at a time — specific enough to be falsifiable
- Grounded in evidence from Phases 2–3, not assumption
- If three hypotheses fail to explain the evidence: stop and flag that the architecture may need re-examination

### Classify fix complexity

Before writing the artefact, assess the fix type:

| Fix type | Signals | Recommendation |
|---|---|---|
| **Content / config only** | Root cause is in database content, CMS page copy, a config file, or an environment variable — no code change required | Direct edit — no spec needed |
| **Trivial code fix** | Single-line change, obvious typo, missing null check | Fix directly, no spec needed |
| **Non-trivial code fix** | Multiple files, logic change, risk of regression | `/spwf:challenge` → Spec → Build |

Record the fix type in the artefact's `Rough scope` section.

### Produce bug artefact

Generate `todo/BUG-{slug}.md`:

```markdown
---
source: youtrack | jira | linear | slack | file | scratch
tracker: youtrack         # omit if source is slack | file | scratch
ticket: ACAD-42           # tracker-agnostic id; omit if no tracker ticket
created: YYYY-MM-DD
status: ideation
type: bug
---

# BUG: {Title}

## Context
{What is broken: observed behaviour vs expected behaviour}

## Reproduction
{Steps to reproduce consistently; "cannot reproduce" if applicable}

## Root cause hypothesis
{The written hypothesis from Phase 4 — specific and evidenced}

## Evidence
{Stack traces, error messages, relevant git log, working vs broken comparison}

## Affected area
{Files, components, or systems involved}

## Open questions
{What remains unclear; gaps that Challenge will surface}

## Rough scope
{Fix type: content/config only | trivial code fix | non-trivial code fix. What a fix would touch.}
```

---

## Change path

### Qualify

Lightweight check — catch obviously incomplete inputs before Challenge. Four checks:

| Check | Passes when |
|---|---|
| **Problem clarity** | There is a discernible problem or opportunity being addressed |
| **Actor** | There is at least one named or implied user/system affected |
| **Scope boundary** | It is roughly clear what is in scope (even if vague) |
| **Motivation** | There is a reason this matters (business value, user pain, technical debt) |

For each check that fails, ask **one targeted question** before continuing — never more than one per message.

**Limit:** After two clarifying questions, proceed regardless. Record remaining gaps as open questions — Challenge will surface them.

If the input clearly passes all four checks: proceed immediately, no questions.

### Produce ideation file

Generate `todo/{slug}.md`:

```markdown
---
source: youtrack | jira | linear | slack | file | scratch
tracker: youtrack         # omit if source is slack | file | scratch
ticket: ACAD-42           # tracker-agnostic id; omit if no tracker ticket
created: YYYY-MM-DD
status: ideation
---

# {Title}

## Context
{Problem or opportunity — from description or qualify dialogue}

## What we know
{Concrete facts, constraints, or acceptance criteria from the input}

## Open questions
{Gaps that remain after qualify; may be empty if input was complete}

## Rough scope
{What's in scope; note anything explicitly out of scope}
```

---

## Tracker prompt (non-tracker sources only)

After writing the artefact, if the source was **not** an issue tracker (i.e. slack, file,
or scratch), and a tracker MCP is configured, ask:

> "Is there a ticket for this? If not, I can create one — just give me the project key."

If `tracker: none` is set in `.spwf/tracker.yaml`, or no tracker MCP is configured
(neither `mcp__youtrack__*` nor `mcp__atlassian__jira_*` available), skip this step
entirely — no error.

If the user provides a project key:
- Dispatch to the configured tracker's `create_issue` operation per
  `_shared/tracker-dispatch.md`, with the artefact title as summary and
  hypothesis/context as description
- If MCP call fails (auth, network, bad project key): report the error verbatim and
  stop — do not pretend the ticket was created
- On success: add the resulting id to the artefact frontmatter
  (`ticket: {ID}`, `tracker: {tracker}`) and report the created ticket URL

If the user says no or skips: proceed without creating a ticket.

---

## Report

**Bug path:**
```
✓ Bug artefact created: todo/BUG-{slug}.md

Source: {youtrack ACAD-42 | jira PROJ-123 | slack | scratch}
Classified as: bug ({signal that triggered classification})
Hypothesis: {one-line summary}
Fix type: {content/config only | trivial code fix | non-trivial code fix}
Open questions: {count}

Recommended next step:
  {if content/config only}  → Direct edit — no spec needed. Location: {where to edit}
  {if trivial code fix}     → Fix directly, then /spwf:retrospective
  {if non-trivial}          → /spwf:challenge todo/BUG-{slug}.md
```

**Change path:**
```
✓ Ideation file created: todo/{slug}.md

Source: {youtrack ACAD-42 | jira PROJ-123 | slack | file path | scratch}
Classified as: change ({signal that triggered classification, or "confirmed by user"})
Qualify: {passed cleanly | 1 question asked | 2 questions asked — {N} gaps remain}
Open questions: {count}

Recommended next step: /spwf:challenge todo/{slug}.md
```

---

## Commit

After the report (and after the tracker prompt if applicable), propose a commit:

**Bug path message:**
```
chore: capture bug — {title}

Source: {source}
Signal: {signal that triggered bug classification}
Fix type: {content/config only | trivial code fix | non-trivial code fix}
Hypothesis: {one-line root cause}
{if any notable finding during investigation, e.g. "found recent commit X may have introduced this"}
```

**Change path message:**
```
chore: capture — {title}

Source: {source}
{key qualification decisions or constraints surfaced during capture}
{open questions count if > 0: N open questions remain for challenge}
```

Show `git status`, then ask: "Ready to commit? Confirm with 'yes' or edit the message first."

After confirming, run:

```bash
git add todo/{slug}.md   # or todo/BUG-{slug}.md
git commit -m "{confirmed message}"
```
