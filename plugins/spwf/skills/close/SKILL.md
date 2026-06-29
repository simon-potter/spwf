---
name: close
description: Final-phase orchestrator — wraps the full retrospective then permanently closes the change. Invokes /spwf:retrospective (learn-from-mistakes, spec audit, doc-lint, workflow-lint, recap teaching summary, optional changelog), then — after explicit confirmation — marks the todo file complete and moves it to todo/_done/, archives the OpenSpec change, transitions the linked issue tracker ticket to its done state (YouTrack default; Jira and others supported), and deletes the local feature branch with safety checks (default-on, conscious skip).
disable-model-invocation: true
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, mcp__youtrack__*, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_update_issue]
---

# close

Final phase of the SPWorkflow golden path. Retrospect, confirm, then permanently close the change.

```
Step 1  → identify the change (resolve $ARGUMENTS or context)
Step 1b → confirm merged + plan landing (record feature branch; DON'T switch yet)
Step 2  → retrospective       (runs on the feature branch — granular history intact)
Step 3  → confirm closure     (explicit human gate)
Step 4  → mark todo done      (status: complete + git mv to todo/_done/)
Step 5  → commit, then land on base (cherry-pick closure onto {base} + push)
Step 6  → close tracker ticket (if linked — dispatches per .spwf/tracker.yaml)
Step 7  → archive OpenSpec    (opsx:archive on {base}, then commit + push the move)
Step 8  → delete local branch  (default on, conscious skip with [Y/n])
```

> **Two competing requirements, and how the ordering satisfies both.**
> 1. **Learn from full history.** The retrospective (Step 2 — learn-from-mistakes,
>    recap) mines the change's *granular* commit history. After a squash-merge
>    that history survives only on the feature branch, so the retrospective MUST
>    run while the feature branch is still HEAD — **before** any switch to base.
> 2. **Closure must be durable.** Everything `close` then commits (status flip,
>    `todo/_done/` move, retrospective edits, archive) is permanent housekeeping;
>    committed on the merged feature branch it is lost when Step 8 deletes it.
>
> So the order is: retrospect on the feature branch (Step 2), commit the closure
> there (Step 5), then **cherry-pick that commit onto `{base}` and push** (Step
> 5) before archiving and deleting. Unlike feature code (which ships via PR),
> closure housekeeping is pushed straight to `{base}`. If `close` is already on
> `{base}` (feature branch deleted at merge time), it commits directly — the
> granular history is already gone, so the retrospective uses what remains.

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

**Ticket resolution fallback.** The todo file is the primary source for
`ticket:`. If it has no `ticket:` field, read the change's
`openspec/changes/{change-id}/proposal.md` and use its `**Tracker**:` header
line (written by `spec`) as a fallback. This keeps the tracker link alive even
if the todo file was edited or moved. If neither source has a ticket, treat the
change as having no linked ticket (Step 6 skips silently).

If `status` is already `complete`, report: "This change is already closed." and stop.

Confirm the OpenSpec change id: check `openspec/changes/` for a directory matching the change. If `$ARGUMENTS` provided a change id use it directly. If derived from the todo file, ask the user to confirm the mapping before proceeding.

---

## Step 1b — Confirm merge and plan where closure lands

`close` is the post-merge phase. Decide *now* where the closure commits will
land, but **do not switch branches yet** — Step 2's retrospective must run on the
feature branch while its granular commit history is still reachable.

Resolve the base from `.spwf/branch.yaml: base` (default `main`):

```bash
BASE=$(grep -E '^base:' .spwf/branch.yaml 2>/dev/null | awk '{print $2}'); BASE=${BASE:-main}
CURRENT=$(git branch --show-current)
```

**If already on `${BASE}`** (the feature branch was deleted at merge time) — set
`MODE=direct` and run `git pull --ff-only`. The granular history is gone with the
branch, so Step 2 will mine what remains on `${BASE}` (note this in the report).

**If on a feature branch** — set `MODE=port` and:

1. **Clean tree required.** If `git status --porcelain` is non-empty, halt:
   *"Commit or stash before closing."* Closure must not mix with stray edits.
2. **Confirm the change is merged to `${BASE}`** — closing before merge is what
   strands the commits. Try, in order:
   - `git merge-base --is-ancestor HEAD "${BASE}"` → merged (merge-commit / rebase / fast-forward).
   - Else (squash-merge breaks ancestry): `git cat-file -e "${BASE}:openspec/changes/{change-id}/proposal.md" 2>/dev/null` → the change's artefacts are on `${BASE}` ⇒ merged. (For a bug-only change with no OpenSpec dir, check the forge PR/MR state per [`_shared/forge-dispatch.md`](../_shared/forge-dispatch.md), or ask.)
   - If neither confirms, ask: *"Has `{change-id}` been merged to `${BASE}`? [y/N]"* — default **no**, and on no halt: *"Merge the PR/MR first, then re-run /spwf:close."*
3. **Record the feature branch** for Step 5's port and Step 8's deletion. Stay on it:

   ```bash
   FEATURE_BRANCH="${CURRENT}"
   ```

---

## Step 2 — Run retrospective

> Runs on the **current branch**. In `MODE=port` that is the feature branch, so
> learn-from-mistakes and recap see the change's full granular commit history —
> the reason the switch to `${BASE}` is deferred to Step 5. Do not switch
> branches before this step completes.

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
Retrospective complete. Ready to close this change permanently (on `{base}`).

The following will happen:
  1. todo/{slug}.md          → status: complete, moved to todo/_done/{slug}.md
  2. git commit + push       → "chore: close {change-id}" onto origin/{base}
  3. {ACAD-42}               → tracker state: {done_state}   ← only if ticket is linked
  4. openspec/changes/{id}/  → archived + committed + pushed (opsx:archive; runs only after tracker close succeeds)
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

## Step 5 — Commit closure, then land it on the base branch

### 5a. Commit on the current branch

Run `git status` to show what will be committed (the todo flip + move plus any retrospective spec/doc edits). Then commit:

```bash
git commit -m "chore: close {change-id}"
CLOSURE_SHA=$(git rev-parse HEAD)
```

If there is nothing to commit (clean tree), skip the commit silently, note "Nothing to commit," and skip the rest of Step 5.

### 5b. Land the closure commit on `${BASE}`

Closure is permanent repository housekeeping, not feature code — it must reach
`origin/${BASE}`, or it is lost when the feature branch is deleted (Step 8) or
the next time `${BASE}` is reset / re-cloned.

**`MODE=port`** (Step 5a committed on the feature branch) — move to base and
cherry-pick the closure commit across:

```bash
git checkout "${BASE}" && git pull --ff-only
git cherry-pick "${CLOSURE_SHA}"
git push origin "${BASE}"
```

The cherry-pick applies cleanly because `${BASE}` already holds the merged
feature content, so the closure commit touches the same file versions. **On a
cherry-pick conflict, stop and report** — do NOT proceed to Step 6. The feature
branch still holds the closure commit as a backup; the user resolves the
conflict, then re-runs from here. After this step the working tree is on
`${BASE}` for Steps 6–8.

**`MODE=direct`** (Step 5a committed on `${BASE}` already) — just push:

```bash
git push origin "${BASE}"
```

**Push rejected?** If `${BASE}` moved on the remote, `git pull --ff-only` and
retry. If `${BASE}` is a protected branch that refuses direct pushes, stop and
report — the closure commit is already made locally; the user lands it via their
protected-branch process. Nothing is lost.

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

**Commit and push the archive move.** `openspec archive` only moves files in the
working tree — it does not commit. Capture the move on `${BASE}` and push it, or
the archived state never reaches the remote:

```bash
git add -A
git commit -m "chore: archive {change-id}"
git push origin "${BASE}"
```

(Same protected-branch caveat as Step 5: if the push is refused, report and let
the user land it — the commit is already made locally.)

---

## Step 8 — Delete local feature branch

Final cleanup step. Default behaviour is to delete; skipping requires a
conscious 'n'.

### Identify the feature branch

After Step 1b the working tree is on `${BASE}`, so prefer the `FEATURE_BRANCH`
recorded there.

```bash
DEFAULT_BASE=${BASE:-main}
CANDIDATE="${FEATURE_BRANCH:-}"   # recorded in Step 1b when close switched off a feature branch
```

| Situation | Candidate branch |
|---|---|
| `FEATURE_BRANCH` was recorded in Step 1b | `FEATURE_BRANCH` is the candidate. (Reliable even after a squash-merge, where `git branch --merged` cannot see it.) |
| Not recorded, and current branch is not `main`/`master`/`DEFAULT_BASE` | the current branch is the candidate. |
| Not recorded, on `main`/`master` | Look at `git branch --merged main` for a branch matching the change-id slug (substring). If multiple, list and ask. |
| Branch already deleted (e.g. removed at merge time) or no candidate found | Skip this step silently. Note "No feature branch identified." in the report. |

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

   **Carve-out for the ported closure commit.** In `MODE=port` the feature
   branch carries the `CLOSURE_SHA` commit, which Step 5b already cherry-picked
   onto `${BASE}` and pushed. It will show here as one "unpushed" commit — that
   is expected and safe (its content lives on `${BASE}`). If the only unpushed
   commit is `CLOSURE_SHA` (compare `git rev-list {candidate}@{u}..{candidate}`
   against `CLOSURE_SHA`, or by patch-id), proceed without the warning; warn only
   if there are *other* unpushed commits.

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

### Closure (on `{base}`)
✓ todo/{slug}.md              → status: complete, moved to todo/_done/{slug}.md
✓ git commit + push           → chore: close {change-id} → origin/{base}
✓ openspec/changes/{id}/      → archived, committed + pushed → origin/{base}
{✓ {ticket}                   → {done_state}     | — No tracker ticket linked}
{✓ branch `{name}`            → deleted     | ⊘ branch `{name}` kept ({reason}) | — No feature branch identified}
{ℹ Remote `origin/{name}` still exists. Delete with `git push origin --delete {name}` if desired.}

### Recommended actions
{any unresolved items from retrospective that need follow-up}
```
