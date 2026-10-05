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
   Status: open.

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
