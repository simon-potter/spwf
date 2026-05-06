---
name: workflow-status
description: Shows where you are in your workflow right now — what you're most likely working on, what's incomplete, and what to pick up next. Uses heuristics across git state, OpenSpec changes, todo files, and project memory to produce a concise dashboard. Read-only. Use at the start of a session or whenever you've lost the thread. Fast — no subagents, no network calls.
disable-model-invocation: true
allowed-tools: [Read, Bash, Glob, Grep]
---

# workflow-status

Instant workflow orientation. Answers three questions: where am I, what's incomplete, and what should I do next?

## Usage

```
/spwf:workflow-status
```

No arguments. Run it, read the dashboard, start working.

## Step 1 — Collect signals

Run the scan script:

```bash
SKILL_ROOT="$(find ~/.claude -name 'status-scan.sh' \
    -path '*/workflow-status/scripts/*' 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo '')"

if [ -n "$SKILL_ROOT" ]; then
    bash "$SKILL_ROOT/status-scan.sh" 2>&1
else
    echo "status-scan.sh not found — running inline (see fallback below)"
fi
```

If the script is not found, collect signals inline:

```bash
# Git
git branch --show-current && git status --short && git stash list && git log --oneline -10

# OpenSpec
openspec list 2>/dev/null || ls openspec/changes/ 2>/dev/null

# Todo files
grep -l "^status:" todo/*.md 2>/dev/null | xargs -I{} sh -c 'echo "{}:"; head -6 "{}"'
```

## Step 2 — Apply heuristics

Synthesise the raw signals into a current-focus determination. Apply tests in confidence order — stop at the first that produces a high-confidence match.

### Confidence: High

Any of these alone is high confidence:

| Signal | Interpretation |
|---|---|
| Feature branch whose name matches an OpenSpec change with incomplete tasks | Actively implementing that change |
| Uncommitted files in a change's affected directories AND matching change has tasks left | Mid-task on that change |
| Git stash entry named after an OpenSpec change | Interrupted mid-change; needs resumption |

### Confidence: Medium

| Signal | Interpretation |
|---|---|
| Feature branch with no matching OpenSpec change | In-flight work not yet in a formal change |
| OpenSpec change with incomplete tasks, on main branch | Change started but branch may have been merged early |
| Todo file with `status: in-progress` or `status: challenged` | Ideation work in progress |
| Uncommitted changes on main | Quick fixes or exploratory work outside a formal change |

### Confidence: Low

| Signal | Interpretation |
|---|---|
| No uncommitted changes, on main, one change with remaining tasks | That change is the likely next thing |
| Multiple changes each with tasks remaining | Cannot determine priority automatically — present all and ask |
| No active changes, all todos at `status: ideation` | Nothing formally started; suggest picking up the most advanced todo |

### Determining "next task" within a change

When an OpenSpec change is the current focus, find the next concrete task:

1. Read the change's `tasks.md` — find the first `- [ ]` entry that is not a section heading
2. If the change has a `design.md` or `proposal.md`, confirm the task aligns with what was planned
3. If `openspec instructions apply --change <name>` is available, run it to get the canonical next-task instruction

## Step 3 — Format the dashboard

Produce a concise, scannable dashboard. No walls of text. Use tables and one-liners.

```
## Workflow Status — {YYYY-MM-DD}

### Current focus
{High | Medium | Low} confidence: **{change name or description}**
Signal: {one sentence explaining the heuristic that fired}

### Active OpenSpec changes

| Change | Progress | Last active | Status |
|---|---|---|---|
| {name} | {X/Y tasks} | {N days ago} | {In progress / Not started / Blocked} |

### Next task
{- [ ] exact task text from tasks.md}
Run: /opsx:apply {change-name}   OR   openspec instructions apply --change {change-name}

### Todo backlog

| File | Status | Ticket | Title |
|---|---|---|---|
| {file} | {status} | {ticket or —} | {title} |

(Sorted: challenged → analysis → in-progress → ideation)

### Git context
- Branch: {branch}
- Uncommitted: {N files, or "clean"}
- Stash: {entry names, or "empty"}
- Last commit: {hash} {subject} ({N days ago})

### Suggested action
{One clear sentence: what to do right now, including the exact command to run.}
```

### Suggested action heuristics

| Situation | Suggested action |
|---|---|
| High-confidence OpenSpec change in progress | `Run /opsx:apply {change}` to continue the next task |
| Stash entry for a change | `Run git stash pop` then `/opsx:apply {change}` to resume |
| Todo file at `status: challenged` | `Run /spwf:challenge {file}` to progress it to spec |
| Todo file at `status: ideation` | `Run /spwf:challenge {file}` to pressure-test it |
| All tasks complete, no todo files advanced | `Run /spwf:retrospective` — ship is done, debrief |
| Multiple competing changes, none obvious | Ask: "Which of these would you like to focus on?" and list them |
| Nothing active, nothing in backlog | `Run /spwf:new-task` to capture the next piece of work |

## Output notes

- **Confidence rating is an opinion, not a fact.** State it explicitly so the user can correct it.
- **If the dashboard produces a wrong reading, say so.** "Signal is ambiguous — most likely X but could also be Y" is more useful than false certainty.
- **Stale OpenSpec changes** (tasks.md last touched > 30 days ago with remaining tasks) should be flagged with a note: "⚠ stale — confirm this is still active before resuming."
- **Archived changes** are not shown unless explicitly requested. They are complete — not actionable.
- **Todo files without frontmatter** (no `status:` field) are shown with `status: unknown` and listed last.
- **If OpenSpec is not installed and there is no `openspec/changes/` directory**, skip the OpenSpec section entirely and note it. Rely on git and todo signals only.

## Gotchas

- **`openspec list` only shows active changes.** Archived changes are excluded. If the user is looking for a change they believe exists, check `openspec/changes/archive/` manually.
- **Task counts from `openspec list` may lag.** The CLI reads from `tasks.md` directly — if the file has been edited but the change hasn't been explicitly updated, counts may be stale. Cross-check with the raw task file.
- **A clean git state does not mean nothing is in progress.** OpenSpec tracks work at a higher level than git. A change can have many tasks remaining even when the working tree is clean.
- **Branch names are not always meaningful.** Teams that work directly on `main` or use PR-squash workflows will have no branch name signal. Fall back to OpenSpec and todo signals.
- **Multiple stash entries** may represent unrelated interrupted work. List all entries and ask the user which is relevant rather than assuming the top entry is the focus.
- **The `status: in-progress` field on todo files is self-reported.** It may not reflect actual activity. Cross-check with recent commits touching the same area.
