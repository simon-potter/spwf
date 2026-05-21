---
name: close
description: Final-phase orchestrator — wraps the full retrospective then permanently closes the change. Invokes /spwf:retrospective (learn-from-mistakes, spec audit, doc-lint, workflow-lint, recap teaching summary, optional changelog), then — after explicit confirmation — marks the todo file complete and moves it to todo/_done/, archives the OpenSpec change, transitions the linked issue tracker ticket to its done state (YouTrack default; Jira and others supported), and deletes the local feature branch with safety checks (default-on, conscious skip).
disable-model-invocation: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, mcp__youtrack__*, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_update_issue]
---

# close

Final phase of the SPWorkflow golden path. Retrospect, confirm, then permanently close the change.

```
Step 1 → identify the change (resolve $ARGUMENTS or context)
Step 2 → retrospective       (all 6 parts, including recap teaching summary)
Step 3 → confirm closure     (explicit human gate)
Step 4 → mark todo done      (status: complete + git mv to todo/_done/)
Step 5 → commit changes      (git commit captures status edit + path move atomically)
Step 6 → close tracker ticket (if linked — dispatches per .spwf/tracker.yaml)
Step 7 → archive OpenSpec    (opsx:archive; runs only after tracker close succeeds)
Step 8 → delete local branch  (default on, conscious skip with [Y/n])
```

---

## Step 1 — Identify the change

Read `$ARGUMENTS`. Accept any of:

| Input | Resolution |
|---|---|
| `todo/BUG-{slug}.md` or `todo/{slug}.md` | Use this todo file directly |
| OpenSpec change id (e.g. `add-plugin-marketplace`) | Derive todo file from context or ask |
| Empty | Detect from context (most recently completed change) or ask |

Read the identified todo file. Extract:
- `status:` field
- `ticket:` field (if present)
- The title

If `status` is already `complete`, report: "This change is already closed." and stop.

Confirm the OpenSpec change id: check `openspec/changes/` for a directory matching the change. If `$ARGUMENTS` provided a change id use it directly. If derived from the todo file, ask the user to confirm the mapping before proceeding.

---

## Step 2 — Run retrospective

Invoke `spwf:retrospective` with the change id.

All six parts run as normal:
1. learn-from-mistakes      (rules for the project — atomic)
2. change spec audit         (align OpenSpec artefacts with what was built)
3. doc-lint                  (broad project docs drift check)
4. workflow-lint             (full golden path coherence sweep)
5. recap                     (teaching summary for the user; default on, one-key skip)
6. changelog                 (optional — only if preparing a release)

Wait for retrospective to complete before proceeding.

---

## Step 3 — Closure confirmation gate

Present a summary of what will be permanently changed, then ask for a single yes/no:

```
Retrospective complete. Ready to close this change permanently.

The following will happen:
  1. todo/{slug}.md          → status: complete, moved to todo/_done/{slug}.md
  2. git commit              → "chore: close {change-id}" (staged files + todo update + move)
  3. openspec/changes/{id}/  → archived (opsx:archive)
  4. {ACAD-42}               → tracker state: {done_state}   ← only if ticket is linked
  5. local branch `{name}`   → deleted (with safety checks; conscious skip available)

Type "yes" to close, anything else to stop.
```

If the user does not say "yes" (or "y"): stop and report "Closure cancelled — nothing was changed."

---

## Step 4 — Mark todo complete and move to `todo/_done/`

### 4a. Edit status

Edit the todo file. Change the frontmatter field:

```
status: ideation  →  status: complete
```

or whatever the current value is. Set it to `complete`. Do not touch any other frontmatter fields or body content.

### 4b. Move to `todo/_done/`

Once the status edit is made, move the file out of the active todo
directory and into the completed archive:

```bash
mkdir -p todo/_done
git mv {todo-path} todo/_done/{filename}
```

Where `{todo-path}` is the file's current location (e.g. `todo/{slug}.md`
or `todo/BUG-{slug}.md`) and `{filename}` is its basename.

**Collision check before moving.** If `todo/_done/{filename}` already
exists (prior failed close, or duplicate slug across changes), halt with:

> *"Collision: `todo/_done/{filename}` already exists. Resolve manually
> (rename or delete the older file) and re-run /spwf:close."*

Do not auto-resolve — the existing file may be load-bearing context the
user needs to inspect.

The status edit and the move both land in Step 5's closure commit
atomically (`git mv` stages both the deletion of the old path and the
addition of the new path; `git commit` records them together with the
status change).

If the file is not tracked by git for some reason
(`git ls-files --error-unmatch {todo-path}` fails), fall back to plain
`mv` and warn that the move isn't recorded in git history.

---

## Step 5 — Commit closure changes

Run `git status` to show the user what will be committed (includes the todo file update and any retrospective spec/doc edits). Then commit:

```bash
git commit -m "chore: close {change-id}"
```

If there is nothing to commit (`git status` shows a clean tree), skip silently and note "Nothing to commit."

Do not push — that remains the user's explicit action.

---

## Step 6 — Close tracker ticket

Tracker close runs **before** OpenSpec archive (Step 7). Rationale: if the
tracker transition fails after archive already succeeded, you end up with an
archived change and an open ticket — exactly the drift this ordering prevents.
Failed transitions are recoverable; failed un-archives are not.

Decision tree:

| `ticket:` in frontmatter? | Tracker available for this project? | `tracker: none` set? | Action |
|---|---|---|---|
| no | — | — | Skip silently (no tracker action implied). Report "No tracker ticket linked." |
| yes | — | yes | Skip silently (user has opted out). |
| yes | no | no | **Fail fast.** "Cannot close `{ticket}` — configured tracker is not available in this session. For an MCP-backed tracker, configure YouTrack/Atlassian MCP; for a skill-based tracker (e.g. `tracker: beads`), install the owning plugin (e.g. `/plugin install spwf-beadsify@spwf`); or set `tracker: none` in `.spwf/tracker.yaml`." |
| yes | yes | no | Run the transition. |

"Tracker available" is determined per `_shared/tracker-dispatch.md`: an MCP
backend is available when its tools respond; a skill-based backend is available
when its backend module SKILL.md is loadable in the current session.

Resolve the active tracker and `done_state` from `.spwf/tracker.yaml` (defaults
documented in `_shared/tracker-dispatch.md`). Dispatch via that document.

Verify the issue exists, then apply the done state:

```
get_issue(id="{ticket}")
set_state(id="{ticket}", state="{done_state}")
```

Tracker-specific notes:

- **YouTrack** uses field-set commands (`State {done_state}`); the dispatch handles this.
- **Jira** uses named transitions; `done_state` should match an available transition
  ("Done" or "Closed" typically). If neither matches, report the available transitions
  and ask the user which to use.
- **Beads** (skill backend, via `spwf-beadsify`) accepts the close-equivalent state
  set (`close`/`closed`/`Closed`/`done`/`Done`); all map to `bd close <id>`. The
  backend rejects other values with a clear error.

If the dispatch call fails for any reason (auth, network, unknown state, bd error):
report the error verbatim and stop. **Do not proceed to Step 7** — the OpenSpec
archive must not run while the tracker is still open. Leave the ticket-transition
row as failed in the report and surface the error to the user.

---

## Step 7 — Archive OpenSpec change

Runs only after Step 6 has succeeded (or was skipped silently). If Step 6 reported
a failure, stop — do not archive.

```bash
openspec archive --change "{change-id}"
```

If the archive command itself fails, report the error and stop — a failed archive
leaves the change in `openspec/changes/` and is recoverable by re-running once the
underlying issue is resolved.

---

## Step 8 — Delete local feature branch

Final cleanup step. Default behaviour is to delete; skipping requires a
conscious 'n'.

### Identify the feature branch

```bash
CURRENT=$(git branch --show-current)
DEFAULT_BASE=${DEFAULT_BASE:-main}
```

| Situation | Candidate branch |
|---|---|
| `CURRENT` is not `main`/`master`/`DEFAULT_BASE` | `CURRENT` is the candidate. |
| `CURRENT` is `main`/`master` | Look at `git branch --merged main` for branches related to the change-id slug (substring match). If multiple, list and ask. |
| No candidates found | Skip this step silently. Note "No feature branch identified." in the report. |

### Safety checks (halt or warn on each)

Run in order. Halt on any failure unless noted.

1. **Working tree clean?**

   ```bash
   test -z "$(git status --porcelain)"
   ```

   If dirty: halt with *"Working tree has uncommitted changes — commit or
   stash before deleting branch. Step 8 skipped."* The other closure steps
   already ran; only branch deletion is skipped.

2. **Currently on the branch we'd delete?**

   If `CURRENT == candidate`: ask before switching.

   ```
   You are currently on `{candidate}`. To delete it I need to switch to
   `{DEFAULT_BASE}` and pull latest. Switch and pull? [Y/n]
   ```

   If 'n': skip Step 8 silently. The branch stays.
   If 'y' (or enter): `git checkout {DEFAULT_BASE} && git pull --ff-only`.
   If pull fails (diverged, conflicts): halt with the error and skip Step 8.

3. **Branch is merged?**

   Try ancestor check first (works for merge-commit and rebase-merge):

   ```bash
   git merge-base --is-ancestor {candidate} {DEFAULT_BASE}
   ```

   If exit 0: merged. Proceed to safety check 4.

   If non-zero: ancestor check failed (likely squash-merge). Try the forge
   in order:
   - If a tracker `ticket:` is present and a forge CLI is configured per
     `_shared/forge-dispatch.md`, run `{cli} pr/mr list --head {candidate}`
     to find the most recent PR/MR for this branch.
     - If state is `merged`: treat as merged (squash-merge case).
     - If state is `open`: halt with *"PR/MR for `{candidate}` is still open
       — branch deletion skipped."*
     - If state is `closed-not-merged`: halt with *"PR/MR for `{candidate}`
       was closed without merging — branch deletion skipped to preserve
       work."*
   - If forge CLI is not available: ask the user

     ```
     Cannot auto-detect merge status of `{candidate}`. Has the change been
     merged? [y/N]
     ```

     Default no (preserve the branch on uncertainty). If 'y': proceed
     treating as merged.

4. **No unpushed commits?**

   ```bash
   git rev-list --count {candidate}@{u}..{candidate} 2>/dev/null
   ```

   If `> 0` (branch has commits not on its upstream): warn with the count
   and ask:

   ```
   ⚠ `{candidate}` has {N} commit(s) not pushed to its upstream. These
   will be lost if you delete the branch. Continue with deletion anyway?
   [y/N]
   ```

   Default no.

   If the branch has no upstream tracking ref at all, treat that as
   "nothing to push" and proceed silently — local-only branches don't have
   anything to lose at the remote level.

### Confirm and delete

Print a summary and confirm:

```
Branch: {candidate}
Tip:    {short-hash} {subject} ({relative-date})
Status: {merged via ancestor | merged via PR | user-confirmed merged}

Delete local branch `{candidate}`? [Y/n]
```

If 'n': skip silently. The branch stays. Note "Branch kept" in the report.

If 'y' or enter:

```bash
git branch -d {candidate}
```

If git refuses (squash-merge and the local view doesn't see ancestry):

```
git branch -d` refused: `{candidate}` is not ancestor-merged in the local
view. This is normal for squash-merged PRs where the merge commit on
{DEFAULT_BASE} doesn't share ancestry with the branch tip.

Force delete with `git branch -D`? [y/N]
```

Default no. If 'n': keep the branch and report "Branch kept (force delete
declined)". If 'y': run `git branch -D {candidate}`.

### Remote tracking branch

After successful local delete, check whether a stale remote-tracking ref
exists:

```bash
git ls-remote --exit-code origin {candidate} 2>/dev/null
```

- If `exit 0` (remote branch still exists): note in the report
  *"Remote branch `origin/{candidate}` still exists. Delete with `git push origin --delete {candidate}` if desired."* Do not delete remote
  automatically — that's a destructive shared-state action and stays in the
  user's hands.
- If non-zero (remote already gone): silent.

Run `git remote prune origin` after a successful local delete to clean up
stale remote-tracking refs locally.

---

## Report

```
## Closed: {change-id}

### Retrospective
{brief summary of retrospective findings — learnings count, drift items, doc issues, workflow issues}

### Closure
✓ todo/{slug}.md              → status: complete, moved to todo/_done/{slug}.md
✓ git commit                  → chore: close {change-id}
✓ openspec/changes/{id}/      → archived
{✓ {ticket}                   → {done_state}     | — No tracker ticket linked}
{✓ branch `{name}`            → deleted     | ⊘ branch `{name}` kept ({reason}) | — No feature branch identified}
{ℹ Remote `origin/{name}` still exists. Delete with `git push origin --delete {name}` if desired.}

### Recommended actions
{any unresolved items from retrospective that need follow-up}
```
