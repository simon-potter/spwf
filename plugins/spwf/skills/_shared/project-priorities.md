# Project priorities — shared convention

The front of the workflow (`capture`, `enrich`, `challenge`) judges whether work
is worth doing and which direction serves the goal. Those judgements are only as
good as their sense of *what this project actually cares about*. This doc defines
a small, committed, per-project snapshot of user and project priorities that
those skills load so the value/end-game calls reflect **this** project, not
generic instinct.

## The snapshot file: `.spwf/priorities.md`

Lives beside `.spwf/tracker.yaml`. **Committed** by default — it's a team-shared
statement of intent, and it travels to any project the skills run in. (A team
that prefers it local can gitignore it; the skills treat "absent" the same either
way.)

Schema — keep it short, one screen, ranked where noted:

```markdown
# Project priorities

## Mission / end game
{One or two sentences: what this project is ultimately for. The outcome, not the mechanism.}

## Primary users & the outcomes they want
- {user / operator / caller} — {the outcome they're hiring this project to deliver}
- ...

## Current priorities (ranked)
1. {what matters most right now — a theme, an objective, an OKR}
2. ...

## Explicit non-goals
- {things this project is deliberately NOT trying to do — the standing "not doing" list}

## Sources
{files this was derived from, e.g. docs/vision.md, README, ROADMAP.md}
_derived {YYYY-MM-DD} — refresh with `/spwf:enrich --refresh-priorities`_
```

## Load protocol

A skill that anchors on priorities does this at the start of a session:

1. **If `.spwf/priorities.md` exists:** read it. Use `## Mission`, `## Primary
   users`, and `## Current priorities` to weight the value/end-game judgement;
   use `## Explicit non-goals` as a standing non-goals list. Treat it as context,
   not gospel — the user can override.
2. **If it's stale** (the `_derived` date is old, or `## Sources` files have
   changed materially since): note it in one line and offer to refresh. Don't
   block on it.
3. **If it's absent:** offer to derive one (below). If the user declines, or a
   derivation finds nothing usable, continue without it — priorities anchoring is
   an enhancement, never a gate. Emit at most one soft note, never an error.

## Deriving the snapshot (first run / `--refresh-priorities`)

Scan the repo for stated intent, strongest signal first. Stop once you have
enough to fill the schema — this is a snapshot, not an audit:

| Look in | For |
|---|---|
| `docs/**` — esp. `vision*`, `strategy*`, `objectives*`, `okr*`, `roadmap*`, `product*`, `prd*`, `goals*` | mission, objectives, target users |
| `README*` (root and package READMEs) | what the project is, who it's for, "why this exists" |
| `ROADMAP*`, `OBJECTIVES*`, `OKR*`, `VISION*`, `MISSION*` at repo root | explicit priorities and non-goals |
| `CONTRIBUTING*`, `CLAUDE.md`, `.spwf/` | engineering priorities, standing constraints, what the team values |
| `package.json` / `pyproject.toml` / `composer.json` description, repo topics | one-line purpose when prose is thin |

Discovery commands (adapt to the repo):

```bash
ls docs/ 2>/dev/null
find docs -maxdepth 2 -iregex '.*\(vision\|strateg\|objective\|okr\|roadmap\|goal\|product\|prd\|mission\).*' 2>/dev/null
ls ROADMAP* OBJECTIVES* OKR* VISION* MISSION* 2>/dev/null
```

Then:

1. Draft `.spwf/priorities.md` from what you found, filling the schema. Quote or
   cite specific source files in `## Sources`.
2. **Show the draft and confirm before writing** — the user corrects mission,
   ranking, and non-goals. This is their statement, not yours; never invent
   priorities the sources don't support. Where a section has no evidence, leave a
   one-line `{unknown — confirm}` placeholder rather than guessing.
3. Write the confirmed file, stamp today's date in `_derived`, and offer to
   commit it (`chore: snapshot project priorities`).

If the scan finds nothing (no docs, bare README): say so, and offer to capture a
mission + top users interactively in 2-3 questions instead. Still optional.

## For downstream projects

This ships with `spwf`. Any project that installs the plugin gets the same
behaviour: the first enrich/capture/challenge that wants priorities offers to
derive `.spwf/priorities.md` from that project's own docs. Nothing is assumed
about the spwf repo's own priorities.
