---
source: scratch
created: 2026-06-29
status: ideation
---

# Branch-enforcement: real-project acceptance smokes

Residual acceptance tests carried out of the `add-branch-enforcement` change at
close time. The implementation shipped (spwf 1.15.0–1.18.0) and the deterministic
logic was sandbox-verified, but these 7 require a **live interactive session
against the installed plugin** (and, for the build ones, a repo with a real test
suite) — so they're tracked here for the real-project rollout rather than left as
stale unchecked tasks on an archived change.

## What we know

Carried from `add-branch-enforcement/tasks.md` (verbatim task ids):

- **3.6** — from `feature/some-other-thing`, `/spwf:spec my-test-change`: verify it asks once and proceeds per the answer (interactive prompt).
- **5.5** — from `main` with 5 commits + active change, `/spwf:pr-create`: rescue offer → runs rescue on Y → continues pre-flight on the new branch → surfaces force-push (interactive [Y/n] + forge).
- **8.1** — Greenfield full lifecycle: capture → challenge → spec → build; confirm no commit lands on `main`.
- **8.2** — Legacy mid-flow: simulate a pre-branching spec on main, `/spwf:build`; Phase 0 halts with the offer; accept and proceed on the new branch.
- **8.3** — Rescue via `/spwf:pr-create` end-to-end (interactive).
- **4.5 / 4.6** — `/spwf:build` Phase 0 halts on base / passes on feature branch. **N/A in the spwf repo itself** (no test suite for build's Red-Green cycle) — verify in a downstream project that has tests.

## Open questions

- For 8.1/8.2/4.5/4.6: which downstream project (with a real test suite) to use as the acceptance bed?

## Rough scope

Run the 7 in a consuming project after `/plugin update` to 1.18.0+. No code change expected — pure verification. If any fails, open a bug against the relevant skill.
