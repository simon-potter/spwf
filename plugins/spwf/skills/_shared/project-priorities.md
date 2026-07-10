# Project priorities — shared convention

The front of the workflow (`capture`, `enrich`, `challenge`) judges whether work
is worth doing and which direction serves the goal. Those judgements are only as
good as their sense of *what this project actually cares about*. This doc defines
a small, committed, per-project snapshot of user and project priorities that
those skills load so the value/end-game calls reflect **this** project, not
generic instinct.

**This is a generic capability, applied per install.** It ships with `spwf` and
runs against whatever project the plugin is installed in — a web app, a mobile
app, a library, a CLI, a service, a data pipeline, a monorepo. Nothing about any
one project (including this repo) is hard-coded: the derivation *discovers* each
project's intent from that project's own artefacts and adapts to its shape. Two
rules make it adaptive rather than templated:

- **Infer the project's domain first, then look where that kind of project keeps
  intent.** A library states purpose in its README and API docs; a product app in
  a `product/`/PRD/roadmap; a data pipeline in its DAG/README; a service in its
  runbook/SLOs. Don't assume a `docs/` folder exists — read the repo's actual
  shape (manifests, top-level dirs, languages) and target the likely homes.
- **"Users" means whoever the software serves** — end users, API consumers,
  operators/on-call, downstream services, or the developers who depend on it.
  Name the real beneficiary for *this* project, not a generic persona.

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
{what this was derived from — files and/or tracker, e.g. README, docs/roadmap.md, YouTrack epics ACAD-* }
_derived {YYYY-MM-DD} — refresh with `/spwf:enrich --refresh-priorities`_
```

## Load protocol

A skill that anchors on priorities does this at the start of a session:

1. **If `.spwf/priorities.md` exists:** read it. Use `## Mission`, `## Primary
   users`, and `## Current priorities` to weight the value/end-game judgement;
   use `## Explicit non-goals` as a standing non-goals list. Treat it as context,
   not gospel — the user can override.
2. **Staleness check (responsive — make it concrete, not a vibe).** Read the
   `_derived {date}` stamp and the `## Sources` list, then test whether the
   project has moved on since:

   ```bash
   # have any of the cited source files changed since the snapshot was derived?
   git log --since="{derived-date}" --oneline -- {source files from ## Sources} | head
   # and has the project's stated intent surface grown new files it didn't cite?
   git log --since="{derived-date}" --oneline -- 'README*' 'docs/**' 'ROADMAP*' 'CHANGELOG*' | head
   ```

   If either shows material change (sources edited, a new roadmap/PRD landed, a
   pivot in the changelog), note it in one line and offer to refresh. Don't block.
3. **If it's absent:** offer to derive one (below). If the user declines, or a
   derivation finds nothing usable, continue without it — priorities anchoring is
   an enhancement, never a gate. Emit at most one soft note, never an error.

## Deriving the snapshot (first run / `--refresh-priorities`)

**Step A — read the repo's shape first, so you know where to look.** The right
sources differ by project type; discover the type before scanning for intent:

```bash
ls -A                                             # top-level dirs: docs/? product/? services/? packages/? apps/?
ls package.json pyproject.toml composer.json go.mod Cargo.toml pom.xml 2>/dev/null   # language & manifest → domain
git ls-files '*.md' | grep -iE 'readme|roadmap|vision|mission|objective|okr|goal|strateg|product|prd|charter|adr|decision|planning|design|runbook|slo' | head -40
```

A monorepo (multiple `packages/*` or `apps/*`) has intent per package *and* at the
root — capture the root mission plus the packages that matter. A bare repo with
only a README leans entirely on that README + the tracker (below).

**Step B — scan the likely homes, strongest signal first.** Stop once you can fill
the schema — this is a snapshot, not an audit:

| Source | Typical of | For |
|---|---|---|
| `README*` (root, and per-package in a monorepo) | every project | what it is, who it's for, "why this exists" |
| `ROADMAP* OBJECTIVES* OKR* VISION* MISSION* CHARTER* GOALS*` at root, or under `docs/` | teams that write intent down | explicit mission, priorities, non-goals |
| `docs/**`, esp. `product*`/`prd*`/`strategy*`, `adr*`/`decisions*`, `planning*`/`design*`, `runbook*`/`slo*` | product apps, services, larger teams | target users, roadmap, standing decisions, operational priorities |
| **The issue tracker** — open **epics / milestones / labels** via the configured backend (`_shared/tracker-dispatch.md`) | teams that plan in the tracker, not in docs | the *current* priorities, often more live than any doc |
| `CONTRIBUTING* CLAUDE.md AGENTS.md .cursor/rules .spwf/` | any | engineering priorities, standing constraints, what the team values |
| Manifest `description`/`keywords`, repo topics/`About` | libraries, CLIs | one-line purpose when prose is thin |

The tracker row matters most for adaptivity: many teams keep *zero* priority prose
in the repo and plan entirely in YouTrack/Jira/Beads. Since SPWF already dispatches
to the tracker, pull the top open epics/milestones as a first-class priority
source — for those projects it's the *only* accurate one. Skip silently if
`tracker: none` or no tracker is configured.

**Which step can read the tracker.** Only `capture` (and any Beads backend, which
is CLI-via-Bash) has tracker tools in its `allowed-tools`; `enrich` and `challenge`
are tracker-free by design. So: prefer to **derive/refresh the snapshot from
`capture`** — the first phase in the pipeline — where the tracker is reachable.
When `enrich`/`challenge` are the first to need it and the tracker isn't reachable
from there, derive from doc sources only and note in `## Sources` that tracker
epics weren't consulted (a later `capture` or `--refresh-priorities` from a
tracker-capable context can enrich it). Never silently drop the tracker as if it
had no priorities — say it wasn't read.

Then:

1. Draft `.spwf/priorities.md` from what you found, filling the schema. Quote or
   cite specific source files in `## Sources`.
2. **Show the draft and confirm before writing** — the user corrects mission,
   ranking, and non-goals. This is their statement, not yours; never invent
   priorities the sources don't support. Where a section has no evidence, leave a
   one-line `{unknown — confirm}` placeholder rather than guessing.
3. Write the confirmed file, stamp today's date in `_derived`, and offer to
   commit it (`chore: snapshot project priorities`).

If the scan *and* the tracker find nothing usable (no intent docs, bare README, no
epics): say so, and offer to capture a mission + top users interactively in 2-3
questions instead. Still optional — never fabricate priorities to fill the file.

## For downstream projects

This ships with `spwf` and is **project-neutral by construction**. Any repo that
installs the plugin gets the same behaviour: the first `enrich`/`capture`/`challenge`
that wants priorities infers *that* project's domain, scans *that* project's
artefacts and tracker, and drafts *that* project's `.spwf/priorities.md` for
confirmation. Nothing about the spwf repo — or any other project the skill has
seen — is assumed or carried across. If two very different projects both install
spwf, each gets a snapshot true to itself.
