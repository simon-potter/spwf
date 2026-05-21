---
source: scratch
created: 2026-05-21
status: ideation
---

# Review follow-ups — deferred from PR #1 (feature/add-beadsify-tracker)

Three suggestions surfaced during the post-7cb80ef in-session review that
were judged non-blocking and deferred from the PR's main scope. Capture
each as its own short task post-merge.

## What we know

- [ ] Document `.beads/interactions.jsonl` empty-file convention in `plugins/spwf-beadsify/README.md` — short note explaining the 0-byte tracked file is bd's high-water-mark marker for incremental JSONL export, not a stray file to be removed.
- [ ] Document `.beads/README.md` auto-refresh behaviour in `docs/dogfooding.md` — a future `bd` upgrade may rewrite this file; flag it so a noisy diff at upgrade time isn't a surprise.
- [ ] File the three Phase 5 deferred acceptance items (5.1 full lifecycle, 5.3 YouTrack regression, 5.4 missing-plugin error path) as Beads issues now that this project is dogfooding bd — so they don't get lost between merge and "first real use".

## Rough scope

All three are docs / planning hygiene, not code. None block release of the Beadsify v1.

## Open questions

- Should the lifecycle item (5.1) wait for `add-beadsify-build-loop` to land, since that change introduces `bd next` / `bd done` integration with `/spwf:build`? The ideation is at `todo/beadsify-build-loop.md`.
