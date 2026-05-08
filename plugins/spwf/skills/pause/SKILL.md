---
name: pause
description: Interrupt-safe context switch. Documents the current branch's state in the active todo file, commits and pushes the in-flight work with a structured commit message describing achievements and next steps, then switches to main ready for the next capture. Use when an urgent task interrupts mid-flight and a git worktree isn't an option. Argument optional; pass the next ticket reference (e.g. /spwf:pause ACAD-99) and the report includes a ready-made capture command.
disable-model-invocation: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# pause

Mid-flight context switch. The current branch's state is documented in the
active todo file, committed and pushed with a structured message, and the
user is left on `main` ready for the next capture.

The expected scenario: you are mid-build on a feature branch, an urgent bug
arrives, worktrees aren't an option (or aren't worth the friction), and you
need to step away cleanly. Resume later with `git checkout {branch}` —
`/spwf:wfstatus` will rehydrate context.

## Step 0 — Sanity checks

```bash
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || halt "Not in a git repo."

BRANCH=$(git branch --show-current)
DEFAULT_BASE=${DEFAULT_BASE:-main}

# Already on the base branch — nothing to switch from
if [ "$BRANCH" = "$DEFAULT_BASE" ] || [ "$BRANCH" = "master" ]; then
  halt "Already on \`$BRANCH\` — pause has nothing to switch from."
fi

# Anything to pause? Working tree dirty OR commits ahead of upstream
DIRTY=$(git status --porcelain | wc -l | tr -d ' ')
AHEAD=0
if git rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then
  AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
fi

if [ "$DIRTY" = "0" ] && [ "$AHEAD" = "0" ]; then
  halt "Nothing to pause — working tree is clean and \`$BRANCH\` is up to date with its upstream. Just run \`git checkout $DEFAULT_BASE\`."
fi
```

## Step 1 — Identify context

Collect, but do not act on yet:

- `BRANCH` — current branch
- **Active todo file** — most recent `todo/{slug}.md` or `todo/BUG-{slug}.md`
  whose name matches the branch name or change-id slug. If multiple
  candidates: take the most recently modified. If none: proceed with no
  todo update.
- **Active OpenSpec change** — derive from todo file frontmatter
  (`change-id` if present) or by directory match in `openspec/changes/`.
  Read its `tasks.md` if it exists.
- **Last task complete** — last `[x]` line in tasks.md.
- **Next task** — first `[ ]` line in tasks.md after the last `[x]`.
- **Uncommitted state** — `git status --short` parsed into modified, staged,
  and untracked counts.
- **Commits ahead of upstream** — `git log @{u}..HEAD --oneline`.

## Step 2 — Confirm scope of pause

Print a summary and confirm with one prompt:

```
Pause `{BRANCH}`?

Active todo:    todo/{slug}.md ({title})        | (no todo file matched)
OpenSpec:       {change-id} — {N}/{M} tasks complete | (no openspec change)
Last task:      {last [x] task description}      | (none yet)
Next task:      {next [ ] task description}      | (no tasks pending)

Working tree:   {N} modified, {M} staged, {K} untracked
Ahead of upstream: {N} commit(s)

Continue? [Y/n]
```

If 'n': abort cleanly, change nothing.

## Step 3 — Ask for the state note

The user's own words about what's in flight. This is the most important
content of the pause record — don't infer it from commits.

```
What's the state? One paragraph or a few lines describing what's in flight
and what to do next on resume:
```

Wait for input. If the user provides nothing, fall back to a generated
summary (last task complete + next task) but flag it as auto-generated.

## Step 4 — Update the todo file (if any)

Append a section to the active todo file. Do not overwrite earlier
sections. If the file already has a `## Pause —` section, append a new
one — multiple pauses build a journal.

```markdown
## Pause — {YYYY-MM-DD HH:MM}

### State
{user-provided note}

### Last task complete
{last [x] from tasks.md, or "no tasks completed yet"}

### Next task
{next [ ] from tasks.md, or "see ## Rough scope"}

### Uncommitted at pause
{list of modified/staged files; "(clean tracked tree)" if none}

### Untracked at pause
{list of untracked files; "(none)" if empty; this section omitted if no
untracked files existed}
```

If no active todo file was identified, skip this step. The pause commit
will still happen with the user's note in its body.

## Step 5 — Stage in-flight work

Show `git status` to the user. Two questions:

```
Stage modified and deleted tracked files for the pause commit? [Y/n]
```

Default yes — these are usually the in-flight work the user wants
preserved. If 'n', skip staging entirely (the pause commit will only
include the todo file update, if any).

If 'y' or enter:

```bash
git add -u                         # modified + deleted, no untracked
git add todo/{slug}.md 2>/dev/null # the pause section we just appended
```

If untracked files exist, ask separately:

```
Untracked files:
  scratch/notes.md
  experiments/poc.py

Include any of these in the pause commit? [N/y/select]
```

- 'n' or enter: skip them; they remain untracked locally.
- 'y': `git add` all untracked.
- 'select': list one by one and ask per file.

Default no on untracked because they're usually scratch / personal /
.env-style files that shouldn't be committed without thought.

## Step 6 — Commit

Construct a structured commit message:

```
wip: pause {change-id-or-branch} — {one-line summary derived from user note}

State at pause:
{user-provided state note, wrapped at 72 chars}

Achieved so far:
- {last [x] tasks, up to 5}
{or "- No tasks completed yet" if none}

Next on resume:
- {next [ ] task and any subsequent unchecked items, up to 3}
{or "- See ## Rough scope in todo file" if no tasks.md}

Pause point committed via /spwf:pause.
```

Show the message and ask:

```
Commit with this message? [Y/n/edit]
```

- enter or 'y': commit as shown.
- 'n': abort the pause; leave staged changes staged. Report what was done
  (todo file updated) and what the user can do manually.
- 'edit': open the message in `$EDITOR` for the user to refine, then
  commit.

```bash
git commit -m "{message}"
```

If commit fails (pre-commit hook, etc.): halt with the error. The user can
fix the hook issue and re-run. Per CLAUDE.md, do not pass `--no-verify`.

## Step 7 — Push

```bash
if git rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then
  git push
else
  git push --set-upstream origin {BRANCH}
fi
```

If push fails (diverged, force-pushed remote, no permission): halt with
the error and surface the remediation. Pause is only "done" when the work
is on the remote — without that, switching to main risks losing
context if the local clone is lost.

## Step 8 — Switch to base and pull

```bash
git checkout {DEFAULT_BASE}
git pull --ff-only
```

If checkout fails (it shouldn't, the working tree is now clean): halt.

If pull fails (diverged, conflicts on the base branch — rare but
possible): warn but proceed. The user is on the base branch, just not at
its latest. Note this in the report.

## Step 9 — Report

```
✓ Paused branch `{BRANCH}`
✓ Updated todo/{slug}.md with pause section          | — No todo file matched
✓ Pushed pause commit to origin/{BRANCH}
✓ Now on `{DEFAULT_BASE}` (latest)                    | ⚠ Now on `{DEFAULT_BASE}` ({M} commits behind origin/{DEFAULT_BASE} — pull failed: {reason})

To resume `{BRANCH}` later:
  git checkout {BRANCH}
  /spwf:wfstatus

Ready for next capture:
  /spwf:capture {arg}      ← if $ARGUMENTS was provided
  /spwf:capture            ← otherwise
```

If `$ARGUMENTS` was provided (e.g. `/spwf:pause ACAD-99`), the report's
"Ready for next capture" line shows the ready-made command with that
reference.

## Constraints

- **Never force-push.** If the remote has diverged (someone else pushed),
  halt — let the user resolve.
- **Never auto-add untracked.** Default no on untracked files; the user
  must opt in explicitly.
- **Never bypass pre-commit hooks.** If a hook fails, the pause is
  incomplete; report and halt.
- **Never mark OpenSpec tasks complete.** Pausing documents in-progress
  state; it does not change task completion status. Only `/spwf:build` (or
  the user manually) marks tasks `[x]`.
- **Always push before switching.** A pause that hasn't been pushed is
  one disk failure away from disappearing.

## Out of scope

- Resume orchestration. Use `git checkout {branch}` + `/spwf:wfstatus`. A
  dedicated `/spwf:resume` skill is deferred — most resume needs are
  covered by `wfstatus` reading the pause section in the todo file.
- Stash-style hidden state. Pause produces a real commit, not a stash.
  Stashes hide work; pause documents and shares it.
- Multiple concurrent pauses on the same branch. Each pause appends a new
  `## Pause —` section to the todo file; the most recent one is the
  current state. Older pause sections are journal entries.
