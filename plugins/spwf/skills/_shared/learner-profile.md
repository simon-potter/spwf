# Learner profile — shared convention

The back of the workflow (`recap`, `understand`) exists so the human keeps a
working grasp of code an agent wrote. Explanation pitched at the wrong level
fails in both directions — patronising when it over-explains, useless when it
assumes too much. This doc defines a small, personal, per-project record of what
the developer already understands, so `understand` can aim its questions and its
framing at the person actually in the chair.

**This is a generic capability, applied per install.** It ships with `spwf` and
runs against whatever project the plugin is installed in. Nothing about any one
project is hard-coded: the concepts recorded are whatever that project's changes
actually touched.

## The profile file: `.spwf/learner.md`

Lives beside `.spwf/priorities.md` and `.spwf/tracker.yaml`.

**Gitignored by default** — and this is the one place this convention diverges
from [`project-priorities.md`](project-priorities.md). `priorities.md` is a
team-shared statement of intent and is committed. This file is about a *person*:
it records what they don't yet understand. A committed record of an individual's
comprehension gaps is a liability in any shared repo, and reads as a
performance-review artefact nobody consented to. Skills that write it MUST
ensure `.spwf/learner.md` is present in `.gitignore` before writing.

Schema — keep it short, one screen:

```markdown
# Learner profile

## Level
{new | working | fluent} overall, with per-area overrides:
- {area, e.g. Postgres migrations} — {new | working | fluent}

## Known
Concepts demonstrated in a session, with the change that proved it.
- {concept} — {change-id}, {YYYY-MM-DD}

## Open
Gaps surfaced and not yet closed.
- {concept} — {change-id}, {YYYY-MM-DD}. To close: {what would}

## Recurring blind spots
Areas that have appeared under Open more than twice.
- {area}

_updated {YYYY-MM-DD} by /spwf:understand_
```

## What level governs — and what it must never govern

**Level changes the explanation depth and the vocabulary. It never changes the
rigour of the questions.**

| Level | Framing |
|---|---|
| `new` | More scaffolding. Name the concept before probing it. An analogy where one genuinely helps. |
| `working` | The default. Concept assumed; consequence probed. |
| `fluent` | Terser framing, straight to the tradeoff, fewer questions. |

Nobody gets *easier questions*. If level lowered the bar, the check would be
theatre and this file would become a record of flattery rather than of
understanding. A skill loading this profile MUST NOT use `level: new` as licence
to ask less of the developer — only to explain more around what it asks.

## Load protocol

A skill that anchors on the learner profile does this at the start of a session:

1. **If `.spwf/learner.md` exists:** read it. Use `## Level` to pitch framing and
   vocabulary. Use `## Known` to avoid re-explaining concepts already
   demonstrated. Use `## Open` and `## Recurring blind spots` to weight which
   areas are worth revisiting. Treat it as context, not gospel — the developer
   can override any of it in the moment.
2. **If it's absent:** ask a single calibration question, create the file, and
   never ask that question again. Ensure the `.gitignore` entry exists first.
3. **After the session:** move concepts the developer demonstrated into
   `## Known` with the change-id and date. Record gaps under `## Open` with what
   would close them. Promote an area into `## Recurring blind spots` once it has
   appeared under Open more than twice.

Level adjustment is **observed, not asked**. When a developer traces a
consequence without prompting, promote them on that area — and say so, so the
change is never silent. Never demote on a single weak answer; use
`## Recurring blind spots` for that signal instead.

## Scheduled review

> **Reassess this convention after ~5 real runs.** The profile is additive to
> the goal it serves rather than required by it — `understand` works without it,
> calibrating within a session from how the developer answers. It is also the
> component here most likely to rot: written every run, read rarely, drifting
> from reality as the developer's actual grasp moves on.
>
> Keep it only if *"which areas do I keep not understanding"* turns out to be
> information that gets used. If it hasn't earned its place by then, delete this
> convention and the `.spwf/learner.md` reads from the skills that load it.
