# Project priorities

## Mission / end game
Give solo developers and small teams the speed of an AI coding assistant without
losing review, testing, or a clean git history — a repeatable, checkpoint-gated
path from "an idea" to a spec'd, tested, reviewed, cleanly-branched change, every
time. Delivered as Claude Code plugins (`spwf` + `spwf-agents`, optional
`spwf-beadsify`) that projects install and dogfood.

## Primary users & the outcomes they want
- **Solo devs & small teams using Claude Code** — a disciplined idea→ship pipeline
  they get by default, not only when they remember the steps; speed without giving
  up control of review, tests, and branching.
- **Maintainers of sibling workflow / plugin projects** — reusable, documented
  patterns they can adopt selectively (the `docs/handover/*` notes are written
  explicitly for this audience).
- **This repo, dogfooding itself** — edits under `plugins/` apply to the live
  session; the workflow must stay usable on its own development.

## Current priorities (ranked)
1. **Enrich the front of the workflow** — ideation → challenge, so ideas arrive
   well-shaped and value-anchored before any spec (the `enrich` phase + per-project
   priorities snapshot).
2. **Adapt high-quality external skills into SPWF's voice** rather than
   re-deriving — e.g. obra/superpowers, addyosmani/idea-refine — keeping each
   phase single-responsibility and human-gated.
3. **Keep the tracker/forge abstractions and Beadsify backend solid**, and keep
   READMEs + plugin versions current so downstream projects pick up changes via
   `/plugin update`.

## Explicit non-goals
- **Autonomous agent behaviour** — skills are explicit, user-triggered checkpoints
  (`disable-model-invocation: true`), not background suggestions.
- **Owning CI/CD or deployment** — the workflow stops at PR/MR creation and review;
  CI/CD owns the rest.
- **Locking to one tracker or forge** — tracker (YouTrack / Jira / Beads) and forge
  (GitHub / GitLab) stay abstracted and pluggable.

## Sources
README.md ("Why this exists", "Who it's for"), CLAUDE.md, docs/handover/*.md,
todo/ backlog (active exploration themes). Beads tracker consulted — only
beadsify smoke-test tickets present, no priority signal.
_derived 2026-07-10 — refresh with `/spwf:enrich --refresh-priorities`_
