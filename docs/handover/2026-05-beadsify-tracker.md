# Beadsify tracker — May 2026 (late month)

This handover captures durable learnings from
[#1 — feat(spwf-beadsify): add Beads as optional tracker-dispatch backend](https://github.com/simon-potter/spwf/pull/1),
which shipped the `spwf-beadsify` plugin and routed the `tracker: beads`
backend through `_shared/tracker-dispatch.md` without rewriting any host
skill bodies. Most spec-level decisions live in
`openspec/changes/archive/YYYY-MM-DD-add-beadsify-tracker/design.md` — this
note focuses on process learnings that should outlive the change.

The session shipped `spwf-beadsify` v0.1.0 and bumped `spwf` 1.13 → 1.14
(new skill-based dispatch backend type).

| Commit (squash) | What |
|---|---|
| `3eb72ce` | Plugin scaffold + tracker-dispatch backend type + skill-backend awareness in capture / tracker-comment / issue-to-task / close / capturer agent |

---

## 1. Adding a backend type requires a caller sweep

The original spec said "existing skills work unchanged via dispatch."
That was structurally true but operationally false: every host skill had
its own inline preflight gate that hard-coded `mcp__youtrack__*` /
`mcp__atlassian__jira_*` presence as the existence test for "is a tracker
configured". With `tracker: beads` set and no MCP loaded, those gates
returned "No issue tracker MCP configured" and short-circuited dispatch
before it ran.

The reviewer surfaced this in **five separate rounds**:

| Round | Caller missed | Commit |
|---|---|---|
| 1 | `capture` input-side preflight | `49b55ad` |
| 1 | `tracker-comment` Step-2 preflight | `49b55ad` |
| 1 | `capturer` agent description | `49b55ad` |
| 1 | `close` decision-table column | `400cebb` (bundled with Finding-3 swap) |
| 2 | `capture` **output-side** tracker-prompt section | `abd6f8a` |
| 3 | `issue-to-task` (skill missed entirely in round 1) | `f28aaec` |

**Lesson.** When adding a new backend type to a dispatch abstraction,
audit callers in one sweep — not piecemeal per review round. The grep
pattern is wider than "find every place that calls dispatch": find every
place that gates on *backend availability*, including:

- Step-1/Step-2 preflight checks ("Fail fast on missing MCP")
- Frontmatter `allowed-tools:` lists (Bash is needed for skill backends)
- Agent description text (downstream agent registries gate on this)
- Decision tables that ask "is X configured?"
- Post-action prompts that ask "want me to also create a ticket?"
  (the round-2 miss — easy to forget because they're not on the
  fail-fast path)

Generic grep for this repo:

```bash
grep -rn 'mcp__youtrack\|mcp__atlassian\|"No issue tracker MCP\|tracker MCP' \
  plugins/spwf/ plugins/spwf-agents/
```

If the dispatch contract supports two backend types, every match should
either be removed or split into a backend-aware branch.

---

## 2. Section renames need a back-reference grep

`20073b0` renamed README's "Optional add-on: Beadsify (in development)"
to "Optional add-on: Beadsify" (post-merge state correction). Two sibling
docs still quoted the **old** title verbatim:

- `README.md:236-238` — a callout that referenced the section by its old
  name (fixed in `600d485`)
- `plugins/spwf-beadsify/README.md:5` — "See the parent project's
  `README.md` § 'Optional add-on: Beadsify (in development)'" (fixed in
  `5ea3ef3`)

Both fixes were one-line changes. Both were missed in the rename because
the rename grep was for the section header itself, not for back-references
that quoted it.

**Lesson.** When renaming a section header, grep for two patterns:

1. The full old title (catches headers and TOC entries)
2. The distinguishing phrase from the old title (catches back-references
   in prose that quote it partially)

For this case, `grep -rn '(in development)'` would have found both
back-references in one sweep. Repo-wide is fine — the false-positive
rate on phrases like "(in development)" is low enough that human triage
is cheap.

---

## 3. Confirmation-gate prompts must mirror execution order verbatim

The PR's Finding-3 fix swapped tracker-close (Step 5) and OpenSpec
archive (Step 6) inside `close/SKILL.md`. Failed tracker transitions
are recoverable; failed un-archives are not — so tracker close must
happen first.

The body steps were swapped. The outline was renumbered. The internal
"Step N references" were updated. But the **Step-3 confirmation gate
prompt** — the irreversible-action review the user sees before any of
those steps run — still listed them in the old order. The user could
have said "yes" expecting archive-then-close and got close-then-archive.

Fix: `e967a93`. Items 3 and 4 of the gate now match Steps 6 and 7's
execution order, and the dependency rationale ("runs only after tracker
close succeeds") is in the gate text too.

**Lesson.** When reordering steps inside a skill that has a
confirmation-gate preview, grep the same skill for any list that
enumerates the affected steps. The preview is part of the skill's
public contract; the body steps are the implementation. Treat them as
two views of the same plan that must stay in sync, like ORM model
fields and database migrations.

Generic grep pattern when touching a `close`- or `apply`-style skill:

```bash
grep -n -A 20 'Type "yes"\|Type \"yes\"\|confirmation gate' \
  plugins/spwf/skills/{skill-name}/SKILL.md
```

---

## 4. Address-review's VERIFY step paid off on stale-review pushback

Mid-cycle, the reviewer re-posted the same three round-3 findings
against a commit that had already addressed them. The address-review
skill's posture — *"Review feedback is a hypothesis about the code, not
an instruction to obey"* — said: VERIFY at HEAD before acting.

All three findings were resolved at HEAD; the reviewer was reviewing
against a stale snapshot. Instead of phantom re-fixes, the response was
evidence-based pushback: file paths, line numbers, current text excerpts,
and the commit SHAs that landed each fix.

**Lesson.** This is the address-review skill working as designed —
worth flagging here only because the pushback path is rarely exercised
and is easy to second-guess in the moment. Trust the verify step:

- File:line exists at HEAD with the new text → fixed
- Test asserts the new behaviour → fixed
- The reviewer is reading a snapshot from before the fix landed → say so,
  cite the SHA, and ask them to re-pull

Push-backs are expensive when wrong and cheap when right. The asymmetry
is worth the cost of VERIFY every time.

---

## 5. Per-project tracker prefix surfaced at integration time

The spec assumed Beads ids would be `bd-<hash>`. Running `bd init` in this
repo (Phase 5) revealed bd uses the **project directory name** as the
prefix by default. For this repo: `spwf-<hash>`. For an "auth" project:
`auth-<hash>`.

Fix in `c0b91eb`: regex went from `^bd-[a-z0-9]+$` to
`^[a-z0-9]+(-[a-z0-9]+)+$` — prefix-agnostic, requires at least one
hyphen, shell-injection-safe regardless of prefix. Spec, design, and the
backend SKILL all updated.

**Lesson.** When integrating an external tool, exercise the actual
command at least once before drafting regexes that assert on its output.
The "obvious" id format is often wrong; the cost of catching it at
integration time (a respec) is much higher than catching it during
ideation. For this change, a single `bd init` followed by `bd q "test"`
on a scratch directory would have surfaced the prefix model in five
minutes.

---

## 6. zsh `$status` is read-only — use `$rc` for return-code capture

The Phase-2 backend skill used `$status=$?` after each `bd` subprocess
to capture the return code. That works in bash but is silently broken in
zsh — `$status` is a read-only special variable; assignment fails with
no error. The Phase-5 smoke test caught it.

Fix in `a7ef27f`: renamed to `$rc` throughout. Added a "shell-portability
note" to Decision 7's safe-invocation pattern so future skill authors
don't reintroduce the bug.

**Lesson.** When writing portable shell snippets in SKILL.md files
(which run under whichever shell the user has — bash on most Linux,
zsh on most macOS), avoid using shell special-variable names as
locals. `$status`, `$pipestatus`, `$lineno`, `$random` are all
read-only in zsh. `$rc` (return-code) is universally safe.

This belongs as a one-liner in any future "Skill-authoring conventions"
doc, alongside Decision 7's safe-subprocess pattern.

---

## Summary — what to look for next time

When the next change extends a dispatch abstraction or renames a
user-visible artefact:

1. ☐ **Caller sweep**: grep for every gate-style preflight that asserts
   on the old set of backends. Update all in one commit.
2. ☐ **Back-reference grep**: when renaming a section/header, grep for
   the distinguishing phrase from the old name (not just the full title).
3. ☐ **Confirmation gate sync**: when reordering steps in a skill with a
   preview prompt, treat the gate text as part of the contract — grep
   for it.
4. ☐ **Integration probe before regex**: exercise the tool once before
   asserting on its output format.
5. ☐ **Shell portability**: no `$status`/`$pipestatus`/`$lineno` as
   locals — use `$rc`.
6. ☐ **Trust VERIFY**: when a review feels stale, check HEAD before
   acting. Pushback with evidence beats phantom re-fixes.
