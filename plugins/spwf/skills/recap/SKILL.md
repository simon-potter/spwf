---
name: recap
description: Post-ship — Generate a teaching summary of the just-shipped change for the human. Distils what was changed, which domain concepts were touched, the decisions made and why, the surprises that surfaced, and pointers for further learning. Distinct from learn-from-mistakes, which captures rules for the project; this captures takeaways for the user. Default Part 5 of the retrospective; runnable standalone via /spwf:recap [change-id or todo path].
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash, Write]
---

# recap

Crystallise what the user just shipped — concepts, decisions, surprises, and
growth pointers — in a 30-second engagement check. Companion to
`learn-from-mistakes`: that captures rules for the project, this captures
takeaways for the human.

## Step 1 — Resolve the change

Read `$ARGUMENTS`. Accept any of:

| Input | Resolution |
|---|---|
| Empty | Detect from current branch / most recent active change. Ask if ambiguous. |
| change-id (e.g. `add-plugin-marketplace`) | Look up `openspec/changes/{id}/`, fall back to `openspec/changes/archive/{id}/` |
| Todo path ending `.md` | Read frontmatter to derive change-id; resolve as above |

When invoked as Part 5 of `retrospective`, the change-id is passed explicitly
— skip detection.

If the change directory cannot be resolved, halt:

```
Cannot find change "{arg}" in openspec/changes/ or openspec/changes/archive/.
```

## Step 2 — Detect invocation mode

The skill renders at different heading depths depending on context:

- **Standalone** (`/spwf:recap …`) — top-level: `## Recap` and `###` sub-sections.
- **As Part 5 of retrospective** — nested: header is already `### Part 5 — Recap`, so the recap's sub-sections render at `####`.

Detect by checking whether the caller passed a `--retrospective-part` marker (or
equivalent context flag). When in doubt, default to standalone (top-level
headings).

## Step 3 — Read the 5 sources

Read in order. Skip any that don't exist; do not fail.

```
1. todo/{slug}.md (or todo/BUG-{slug}.md) — original Context, What we know
2. openspec/changes/{change-id}/proposal.md — problem and chosen solution
3. openspec/changes/{change-id}/design.md (if exists) — Decisions sections
4. openspec/changes/{change-id}/specs/*/spec.md — concrete behaviour
5. git log $(git merge-base HEAD main)..HEAD --format="%h %s%n%b"
```

For archived changes, the openspec paths fall back to
`openspec/changes/archive/{change-id}/`.

Do **not** read:
- Test files (spec audit covers verification of behaviour against spec)
- The full diff (too verbose; commit messages carry the abstractions you need)
- `learn-from-mistakes` output (recap reads commits directly for surprises;
  no coupling)

## Step 4 — Assemble the recap

Five sections, in this order. Apply the anti-padding rules in Step 5
throughout.

### What changed

One to three sentences. Plain language. Names the user-visible delta.

### Concepts touched

3–5 bullets. Each concept is a domain-level vocabulary term the user should
now recognise in similar code. Format:

```
- **{Concept}** — {one sentence on what it means in the context of this change}
```

Examples of acceptable concepts: idempotency, eventual consistency, schema
migration, rate limiting, optimistic locking, OAuth flow, dependency
inversion, vocabulary mapping, fail-fast.

Examples of **banned** generic vocabulary: "software engineering", "code
quality", "best practices", "the codebase", "good design".

### Decisions (why this, not that)

2–4 bullets. Sourced from `design.md` Decisions sections plus non-trivial
commit messages. Format:

```
- **{Decision}** → {why}. Alternative considered: {alt} ({why rejected}).
```

If `design.md` has no Decisions section and commit messages don't capture
real tradeoffs, **omit this section entirely**. Don't invent decisions to
fill space.

### What surprised us

1–2 bullets. Mined from commit messages — typically `fix:` commits that
revealed a wrong assumption, or `refactor:` commits that emerged after
implementation. Format:

```
- {What was assumed} → {what turned out to be true}. {Brief consequence.}
```

If no commits surfaced surprises, **omit this section entirely**. Empty is
better than padded.

### Read next

At most 3 entries:
- One file in this repo with a similar pattern, if any (`{path}` — what to
  notice)
- One external reference, only if meaningfully clarifying (library docs,
  RFC, blog) — never more than one
- The spec: `openspec/changes/{change-id}/`

If there is no genuinely useful in-repo reference and no external one, list
only the spec link.

## Step 5 — Anti-padding rules

These rules are non-negotiable. Apply them throughout Step 4.

1. **Skip empty sections.** If a section has no real material, omit it
   entirely. Print nothing rather than pad with filler.
2. **Cap each section.** Concepts: 3–5. Decisions: 2–4. Read next: ≤3.
3. **Bullet floor: 1.** If a section has at least one substantive bullet,
   include it. Don't force minimums.
4. **Forbid generic vocabulary.** "Concepts touched" entries must be
   domain-level terms. See the banned list above.
5. **Forbid hedging phrases.** Banned: "It is worth noting that…", "In
   conclusion…", "This change demonstrates…", "Overall…", "It should be
   noted…", "Importantly…".
6. **Tiny-change escape hatch.** If the recap would amount to a single
   substantive bullet across all sections combined, abandon the structured
   format and print one line:

   ```
   Recap skipped — change too small for concept extraction. {one-line summary}
   ```

   Better to admit small than fake big.

## Step 6 — Print the recap

Format the assembled sections at the appropriate heading depth (Step 2).
Standalone:

```markdown
## Recap: {change-id} — {one-line title}

### What changed
…

### Concepts touched
- **…** — …

### Decisions (why this, not that)
- **…** → …

### What surprised us
- …

### Read next
- `…` — …
- {external link, if any}
- The spec: `openspec/changes/{change-id}/`
```

When invoked as Part 5 of retrospective, the skill prints under the
existing `### Part 5 — Recap` heading and uses `####` for its sub-sections.

## Step 7 — Offer to save

After the recap is printed, ask once:

> "Save this recap? [y/N]"

Default is no. If the user does not say "yes" (or "y"), skip silently.

If yes, write to `openspec/changes/{change-id}/recap.md` (or
`openspec/changes/archive/{change-id}/recap.md` for archived changes) using
top-level headings (the file is a self-contained document).

If `recap.md` already exists at that path, ask before overwriting:

> "A recap already exists at {path}. Overwrite? [y/N]"

If the user does not say "yes", skip silently. If yes, overwrite.

When invoked from `close`'s retrospective, the file is saved *before*
close's archive step, so the recap travels into the archive automatically.

## Tone

Senior engineer briefing a junior. Concrete, specific, no hand-waving. Names
files and lines. No emoji. No celebration. No filler.

## Report (when invoked standalone)

After Step 7 completes:

```
✓ Recap printed for {change-id}
{✓ Saved to {path} | — Not saved}
```

When invoked as Part 5 of retrospective, no separate report — the recap
itself is the report.
