---
source: scratch
created: 2026-05-07
status: ideation
---

# Learn-with-Claude — wrap-up summary at close

> Post-grill version. Original draft surveyed options; this version is the
> agreed design.

## Context

Boris Cherny (creator of Claude Code) published a "tips as a skill" thread that
Reza Rezvani writes up in `todo/Boris Cherny's Claude Code Tips Are Now a
Skill.pdf`. Two ideas from that article shape this proposal:

1. **`Learning` and `Explanatory` output styles change how Claude *thinks*, not
   just how it writes.** `Explanatory` makes Claude state *why* it's making each
   change. `Learning` flips the script: Claude coaches you *through* the change
   rather than making it for you. These are pre-hoc, in-session modes.
2. **The tips are a stack, not a menu.** Each layer presupposes the previous;
   the value is the order, not just the contents.

The user-facing problem: at close, the workflow ships a change but doesn't
crystallise *what the user just learned*. Comprehension is left implicit. We
add a wrap-up step — `recap` — that consolidates concepts and decisions for
the human while the work is still warm.

The pre-hoc complement (Learning/Explanatory output styles during build) ships
together as a one-paragraph guidance note in the plugin README, since the post-
hoc and pre-hoc story is only complete when both halves are present.

---

## Distinction from `learn-from-mistakes`

Both skills extract knowledge from a completed change. Different audiences:

| Skill | Audience | Output | Source |
|---|---|---|---|
| `learn-from-mistakes` (existing) | Claude / project docs | Rules added under `docs/operations/`, `docs/engineering/`, gotcha files | Commit messages, diffs |
| `recap` (proposed) | The human shipping the change | A teaching summary printed in-session, optionally saved alongside the change | todo file, proposal, design, specs, git log |

`learn-from-mistakes` teaches *the project*. `recap` teaches *the user*.

---

## Primary intent

**(a) Comprehension consolidation.** The recap is a 30-second engagement check
for the user — "could you defend what you just shipped to a peer?" Five short
sections crystallise concepts, decisions, surprises, and growth pointers.

**(b) Durable record** is a side-effect when the user opts to save. The file
travels with the change (it's saved into `openspec/changes/{change-id}/`),
which means the OpenSpec archive carries it forward automatically.

Other framings (teaching others, pattern-spotting across changes,
celebration) are explicitly **not** in v1.

---

## Workflow position

Added as **Part 5** of `retrospective`. Default on, easy to skip with one
keystroke. Changelog moves to Part 6:

```
Part 1 — learn-from-mistakes      (default on)
Part 2 — change spec audit        (default on)
Part 3 — doc-lint                 (default on)
Part 4 — workflow-lint            (default on)
Part 5 — recap                    (default on, one-key skip)   ← new
Part 6 — changelog                (default off, release only)
```

Skill is also runnable standalone (`/spwf:recap [change-id]`) for ad-hoc
study sessions or when reviewing an archived change.

---

## Skill spec

### Name

`recap`. Slash command `/spwf:recap`. Bare-verb form, matches
`simplify`/`build`/`spec`/`close` family.

### Frontmatter

```yaml
---
name: recap
description: Post-ship — Generate a teaching summary of the just-shipped change for the human. Distils what was changed, which domain concepts were touched, the decisions made and why, and pointers for further learning. Distinct from learn-from-mistakes, which captures rules for the project; this captures takeaways for the user. Default Part 5 of the retrospective; runnable standalone via /spwf:recap [change-id or todo path].
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash, Write]
---
```

`Write` is included for the optional save step. No `Edit` — the skill never
modifies existing artefacts.

### Inputs (5 sources, self-contained)

```
1. todo/{slug}.md (or todo/BUG-{slug}.md)
2. openspec/changes/{change-id}/proposal.md
3. openspec/changes/{change-id}/design.md       (if exists)
4. openspec/changes/{change-id}/specs/*/spec.md
5. git log $(git merge-base HEAD main)..HEAD --format="%h %s%n%b"
```

Skill reads only these. No test files (spec audit covers that). No dependency
on `learn-from-mistakes`' output (recap reads commits directly for surprises).

For archived changes, paths fall back to `openspec/changes/archive/{change-id}/`.

### Argument handling

Matches `close`'s 3-form resolution:

| `$ARGUMENTS` | Resolution |
|---|---|
| Empty | Detect from current branch / most recent active change. Ask if ambiguous. |
| change-id | Look up `openspec/changes/{id}/`, fall back to `archive/{id}/` |
| todo path (e.g. `todo/BUG-x.md`) | Read frontmatter to derive change-id, then resolve as above |

When invoked as Part 5 of retrospective, the change-id is passed explicitly —
no detection needed.

### Output structure (5 sections)

```markdown
## Recap: {change-id} — {one-line title}

### What changed
{1–3 sentence summary in plain language. Names the user-visible delta.}

### Concepts touched
- **{Concept}** — {one sentence on what it means in this context}
{3–5 bullets. Domain-level vocabulary the user should now recognise.}

### Decisions (why this, not that)
- **{Decision}** → {why}. Alternative: {alt} ({why rejected}).
{2–4 bullets. Sourced from design.md decisions and non-trivial commits.}

### What surprised us
{1–2 bullets. Only present if commits surfaced surprises.}

### Read next
- {file in this repo with similar pattern, if any}
- {single external reference, only if meaningfully clarifying}
- The spec: `openspec/changes/{change-id}/`
```

### Anti-padding rules (baked into SKILL.md)

1. **Skip empty sections.** If `design.md` has no Decisions section, omit the
   Decisions section from the recap. State nothing rather than pad.
2. **Cap each section.** Concepts: 3–5. Decisions: 2–4. Read next: ≤3 (one
   in-repo, one external, one spec link).
3. **Bullet floor: 1.** If a section has at least one substantive bullet,
   include it. Don't force minimums.
4. **Forbid generic vocabulary.** "Concepts touched" must be domain-level
   terms (idempotency, eventual consistency, schema migration). Banned:
   "software engineering", "code quality", "best practices", "the codebase".
5. **Forbid LLM hedging phrases.** No "It is worth noting that…", "In
   conclusion…", "This change demonstrates…".
6. **Tiny-change escape hatch.** If the recap would be a single substantive
   bullet, print one line: "Recap skipped — change too small for concept
   extraction. {one-line summary}." Better admit small than fake big.

### Persistence

Default behaviour: print to session, do not save.

After printing, ask once:

> "Save this recap? [y/N]"

If yes, write to `openspec/changes/{change-id}/recap.md` (or
`openspec/changes/archive/{change-id}/recap.md` for archived changes). When
invoked from `close`'s retrospective, the file is saved *before* close's
archive step, so the recap travels with the change into the archive
automatically.

If `recap.md` already exists, ask before overwriting:

> "A recap already exists at {path}. Overwrite? [y/N]"

(This prompt only fires when save is opted in.)

### Presentation in retrospective Part 5

Inline. The full 5-section recap appears under `### Part 5 — Recap` as `####`
sub-sections. The recap *must* land in the user's eyes for the comprehension
intent to work — hiding it behind a file link defeats the purpose.

Standalone `/spwf:recap` invocations use top-level headings (`## Recap` and
`###` sub-sections) so the output renders as a self-contained document. The
skill detects which mode it's in and adjusts heading depth.

### Tone

Senior engineer briefing a junior. Concrete, specific, no hand-waving. Names
files and lines. No emoji. No celebration.

---

## Sample output (illustrative, the just-shipped forge abstraction)

```markdown
## Recap: forge-abstraction — GitLab-default with GitHub fallback

### What changed
`pr-create` and `pr-review` now auto-detect the active code-hosting forge from
`git remote` and dispatch to `glab` (GitLab) or `gh` (GitHub) accordingly. No
per-repo config needed for the common case.

### Concepts touched
- **Forge** — generic term covering GitHub, GitLab, Bitbucket, Gitea, Forgejo.
  Use when "GitHub" would be unnecessarily specific.
- **CLI dispatch over MCP** — for shell-shaped operations CLIs are more
  complete and faster than MCP servers; MCP is right for structured CRUD.
- **Auto-detection from intrinsic signals** — extracting routing info from
  data already present (`git remote get-url origin`) beats a config file the
  user has to maintain.
- **Vocabulary mapping** — same concept, different surface terms (PR vs MR,
  `#42` vs `!42`); the abstraction hides the surface, not the concept.

### Decisions (why this, not that)
- CLI dispatch over MCP servers → CLIs are mature for this surface, MCP
  servers are uneven. Alternative: GitHub MCP + GitLab MCP — rejected
  (latency, coverage gaps).
- Keep skill names `pr-create`/`pr-review` → muscle memory; reports adapt
  vocabulary internally.
- Fail-fast on missing CLI → consistent with the tracker abstraction; no
  silent fallback.

### What surprised us
- `glab` doesn't return additions/deletions in `mr view` — needs a separate
  `mr changes` call. Surfaced in the dispatch reference, not in skills.

### Read next
- Sibling abstraction: `plugins/spwf/skills/_shared/tracker-dispatch.md`
- The spec: `openspec/changes/{change-id}/`
```

---

## Learning modes (the pre-hoc complement)

A new subsection in `plugins/spwf/README.md`, one paragraph:

> ### Learning modes (in-session)
>
> Claude Code ships two output styles that change how Claude *thinks* during
> a session, not just how it writes:
>
> - **`Explanatory`** — Claude states *why* it's making each change as it
>   works. Useful when onboarding to an unfamiliar codebase or when a
>   teammate will read the diff cold and shouldn't have to reconstruct your
>   reasoning.
> - **`Learning`** — Claude coaches you through the change rather than
>   making it for you. Useful when you want to grow expertise on the topic
>   at hand, not just ship.
>
> These are most valuable during **capture**, **challenge**, and early
> **build** when forming understanding. The TDD-disciplined `build` loop
> runs faster in the default style.
>
> The post-hoc complement is `/spwf:recap` — at close, it crystallises
> concepts and decisions from a change you've already shipped.
>
> Set with the `--output-style` flag at launch, or `outputStyle` in
> `settings.json`. See [Claude Code output styles](https://docs.claude.com/en/docs/claude-code/output-styles).

---

## Implementation effort

Mechanical:

- New skill file: `plugins/spwf/skills/recap/SKILL.md`
- One-line update to `plugins/spwf/skills/retrospective/SKILL.md` adding Part 5
  and renumbering Part 5→6 for changelog
- One-line update to `plugins/spwf/skills/close/SKILL.md` description
- Plugin README: new "Forge integration"-style "Recap" line in the Atomic
  skills table, plus the new "Learning modes" subsection
- Root README: add `recap` to the workflow diagram (between Build and Close)
  and to the skill list
- Plugin version: spwf 1.6.0 → 1.7.0 (minor, new skill). spwf-agents
  unchanged.

No new agents. No new dependencies. No external services.

---

## Out of scope (deferred)

- "Reusable patterns" section — risks duplicating "Concepts touched" for the
  comprehension framing. Easy to add back later if missed.
- Cross-change concept index (collected views over time)
- Auto-tagging concepts for searchable knowledge base
- Spaced-repetition / Anki integration
- Tone configurability
- Hooks that auto-suggest `Learning` mode when transcripts show repeated
  "why" questions (claudemd-curator-style mining is a separate proposal)
- Teaching artefact framing (output optimised for distribution to others)
