# Beads dogfood log

Running log of what happens when this repo uses Beadsify (`tracker: beads`)
for real work. See the "Beads integration test bed" section of
[`CLAUDE.md`](../CLAUDE.md) for why this exists.

**Entry format:** date · bd version · what was run · what happened · what was
expected · status (`open` / `→ {change-id}` / `README` / `wontfix`).

Newest entries at the bottom.

---

## 2026-10-05 · bd 1.3.0 · first real init

Context: `.beads/` and `.spwf/tracker.yaml` had been committed since May, but
every `bd` command failed with `no beads database found`. Ran
`bd init --skip-agents --skip-hooks --non-interactive --from-jsonl` on branch
`chore/beads-dogfood`.

1. **The database is local-only, so every new clone or machine starts broken.**
   `.beads/embeddeddolt/` is gitignored. A clone has the config and
   `issues.jsonl` but no database, so every `bd` call fails until someone runs
   init. Beadsify's tracker steps fail with that bare bd error, which doesn't
   say what to do. Expected: the backend preflight recognises this case and
   prints the safe init command.
   Status: open.

2. **The README's init command doesn't import existing issues.** Prerequisite 2
   gives `bd init --skip-agents --skip-hooks --non-interactive`. On a clone that
   already has `issues.jsonl`, you need `--from-jsonl` as well, or the history
   isn't loaded.
   Status: open → README.

3. **`bd init` still makes its own commit** (`bd init: initialize beads issue
   tracking`), touching `.gitignore`, `.beads/.gitignore` and
   `.beads/config.yaml`. The README already warns about this. Worth adding:
   run init on a branch, not on `main`.
   Status: open → README.

4. **`bd init` points Beads' sync at the project's git remote.** It set
   `sync.remote: "git+ssh://git@github.com/simon-potter/spwf.git"` in the
   committed `.beads/config.yaml`, plus a Dolt remote `origin`. So `bd dolt push`
   would push Dolt data into the GitHub repo. Nothing has pushed yet
   (`dolt.auto-push` is unset). The Beadsify README doesn't mention this.
   Decide whether SPWF wants it, and document it either way.
   Status: open.

5. **The forbidden-commands table was checked against bd 1.0.4.** We're now on
   1.3.0. The safe flags still worked: no `CLAUDE.md` or `AGENTS.md` written,
   no `.claude/settings.json` hooks added. Re-check the table and update the
   version it cites.
   Status: open → README.

6. **`issues.jsonl` holds 3 test tickets from May** (`spwf-4mp`
   json-output-probe, `spwf-ifu` stdin-body-test, `spwf-23p` "Test capture for Beadsify dispatch smoke"). They're
   leftovers from building the backend. Close them so `bd list` shows only real
   work.
   Status: done 2026-10-05 (`bd close`, see finding 11).

7. **Known: there's no "started" state.** The backend's `set_state` accepts
   only states that mean closed, so `capture`'s move to `start_state`
   (`In Progress`) always fails as a soft note. This is covered by the planned
   ticket-state change (Beads backend v2: `bd update --claim` / `--status` /
   `--if-status`).
   Status: → ticket-state change (not yet captured).

8. **dev-env doesn't provision `bd`.** Another machine set up from dev-env has
   no Beads; it's a manual install via `scripts/install-beads.sh`.
   Status: open (dev-env repo, not this one).

9. **Minor: on first run, `bd` prints a long notice about anonymous usage
   metrics** in the middle of command output. It's noise in skill transcripts.
   `bd metrics off` disables it. Consider mentioning it in the README.
   Status: open.

10. **Auto-export to `issues.jsonl` is off by default.** After
    `bd close` × 3 the file didn't change: `export.auto` was `false`. The
    Beadsify README (Prerequisite 4) says bd re-exports after every write and
    treats the file as the git audit trail, so it's wrong for 1.3.0. Fixed here
    with `bd config set export.auto true` (committed in `.beads/config.yaml`)
    and a one-off `bd export -o .beads/issues.jsonl`. Every Beadsify project
    needs this, so the safe-init instructions should include it.
    Status: open → README (and maybe the backend preflight).

11. **No spwf path to close a stray ticket.** Closing the three test tickets
    (finding 6) needed a plain `bd close <id> --reason …`. `close` only closes
    the ticket linked to a change, and `tracker-comment` can't change state.
    That's fine for cleanup. Note it in case it comes up for real work
    (duplicates, won't-do).
    Status: open. Finding 6 is now done.

12. **The backend's bash comes through broken when called with arguments.**
    Invoking `spwf-beadsify:tracker-backend` with
    `args: create_issue "" "<title>"` made Claude Code fill the `$1` / `$2` /
    `${2:-}` placeholders in every operation's code block with those
    arguments. `create_issue` came out as `title=""` (it would fail with
    "requires a non-empty title"). `add_comment`'s body and `set_state`'s
    state both became the ticket title. The model has to notice and rebuild
    the intended command; a less careful pass would run the broken code or
    report a bogus failure. Fix: don't use positional `$N` in SKILL.md code.
    Name the inputs in prose and use placeholder variables the caller sets,
    such as `{title}`, or move the code into `scripts/*.sh` called with
    arguments.
    Status: open (high — affects every Beads operation).

13. **The argument order doesn't match between dispatch and backend.**
    `tracker-dispatch.md` defines `create_issue(project, title, body)` and
    capture says to pass `project` as an empty string for Beads, but the
    backend reads its first argument as `title`. Even with finding 12 fixed,
    capture's call would put `""` in the title slot. Line the two up: the
    backend takes `project` first and ignores it, or the dispatch doc says
    Beads takes `(title, body)`.
    Status: open.

14. **Entry 7 confirmed on first real use.** capture created `spwf-uyh`, then
    `set_state("In Progress")` was rejected: "unsupported state 'In Progress'
    (v1 supports close-equivalent states…)". The ticket stays `open` while work
    is under way. The good news: `create_issue` with a 4.6k-character body via
    stdin worked, and `issues.jsonl` re-exported by itself (the entry-10 fix
    holds).
    Status: → `todo/ticket-state-enforcement.md` (`spwf-uyh`).
