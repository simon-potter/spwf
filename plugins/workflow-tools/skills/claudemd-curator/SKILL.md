---
# Source: claudemd-curator skill, synthesising three published references:
#   Karpathy's CLAUDE.md (forrestchang/andrej-karpathy-skills) — L1 discipline block
#   product-mode (sohaibt/product-mode) — L2 decision posture block
#   ykdojo review-claudemd (skills.sh/ykdojo/claude-code-tips) — behavioural feedback loop
# Scripts: scripts/mine-conversations.sh, scripts/sync-agents-md.sh
# References: references/layer-model.md, references/karpathy-block.md,
#             references/product-mode-block.md, references/anti-patterns.md
name: claudemd-curator
description: Audits, refactors, and keeps CLAUDE.md and AGENTS.md healthy and in sync. Use whenever the user mentions reviewing, refactoring, optimising, slimming, or auditing CLAUDE.md or AGENTS.md, asks "what should be in my CLAUDE.md", wants to migrate to AGENTS.md, suspects rule drift, complains that Claude is ignoring instructions, or has just initialised a repo with /init and wants the output cleaned up. Also trigger when the user mentions context-token bloat, rule violations across sessions, dead rules, or symlink/shim setup between AGENTS.md and CLAUDE.md. Apply this skill before any other CLAUDE.md edit so the curation pass runs first.
disable-model-invocation: true
allowed-tools: [Read, Write, Bash, Glob, Grep, Agent]
---

# CLAUDE.md Curator

Keep CLAUDE.md and AGENTS.md lean, layered, in sync, and grounded in what actually happens during sessions.

This skill does four things in order: **inventory**, **behavioural audit**, **layer classification**, **sync verification**, then proposes a diff. It does not edit files until the user approves.

## Prerequisites

- **`jq`** — required by `scripts/mine-conversations.sh` for JSONL parsing. Install with `brew install jq` or `apt-get install jq`.
- **Scripts** — `scripts/mine-conversations.sh` and `scripts/sync-agents-md.sh` must be executable. If not: `chmod +x scripts/mine-conversations.sh scripts/sync-agents-md.sh`.
- **Transcripts** — Phase 2 behavioural audit requires `~/.claude/projects/` to be populated. On a fresh install, Phase 2 produces an empty findings section (graceful, not a failure).

## When to use

- User asks to review, refactor, slim, optimise, or audit CLAUDE.md or AGENTS.md.
- After running `/init` and wanting the auto-generated file cleaned up (it always includes obvious things Claude can infer from the codebase).
- When the user reports Claude ignoring rules, drifting late in sessions, or behaving inconsistently across sessions.
- On a periodic cadence (monthly is the typical interval).
- When migrating a repo to the AGENTS.md standard or setting up multi-tool support (Codex, Cursor, Copilot, Gemini CLI alongside Claude Code).

Do **not** trigger this skill for one-off rule additions ("please remember we use pnpm") — those are direct edits.

## Key concepts

### The three-source synthesis

Three published references inform this skill, each addressing a different layer:

| Source | Addresses | What it adds to CLAUDE.md |
|---|---|---|
| Karpathy's CLAUDE.md (`forrestchang/andrej-karpathy-skills`) | Coding discipline | Think before coding · Simplicity first · Surgical changes · Goal-driven execution |
| `sohaibt/product-mode` | Decision posture | User/JTBD anchor · One-way vs two-way doors · Written tradeoffs · "Merged ≠ done" |
| ykdojo `review-claudemd` (`skills.sh/ykdojo/claude-code-tips`) | Feedback loop | Mine `~/.claude/projects/*.jsonl` for violations, candidate additions, dead rules |

Karpathy is for the engineer; product-mode is for the team; ykdojo closes the loop. Use all three.

### The layer model (L0–L4)

Every line in CLAUDE.md should be classifiable into exactly one layer. If it isn't, it's bloat or it belongs in a pointer.

- **L0 — Identity & map.** What this repo is, where things live. ~10 lines.
- **L1 — Discipline.** Karpathy's four. ~15 lines.
- **L2 — Decision posture.** product-mode contributions. ~20 lines.
- **L3 — Pointers.** `@imports`, `.claude/rules/*.md` with `paths:` frontmatter, skill names, agent guides. Pointers, not content.
- **L4 — Housekeeping.** Compact instructions, model/effort hints, subagent routing.

Total target: under 200 lines for the project-level CLAUDE.md, under 100 lines for `~/.claude/CLAUDE.md`.

Full layer definitions including templates and examples are in `references/layer-model.md`.

### AGENTS.md ↔ CLAUDE.md sync (the practical answer for 2026)

As of late April 2026, Claude Code does **not** officially read AGENTS.md natively (issue `anthropics/claude-code#34235` open, dup of #6235). Operative pattern:

1. **AGENTS.md is canonical.** Holds tool-agnostic content: commands, architecture map, code conventions, boundaries.
2. **CLAUDE.md is one of two things:**
   - A **symlink** to AGENTS.md (`ln -s AGENTS.md CLAUDE.md`) when there is nothing Claude-specific.
   - A **shim file** that starts with `See @AGENTS.md` and then adds only Claude-specific content (skills loaded, hook references, compact instructions, model/effort hints).
3. **Other tools symlink to AGENTS.md too:** `.github/copilot-instructions.md`, `.cursor/rules/main.mdc`, etc. One source of truth, many filenames.
4. **Nested AGENTS.md** in subdirectories is supported by Claude Code, Codex, OpenCode. Use them for monorepo subprojects with genuinely distinct conventions.

The script `scripts/sync-agents-md.sh` handles symlink setup and verification.

## Application

Run the four phases in order. Do not skip phases.

### Phase 1 — Inventory

Read every relevant file. Do not assume contents from filenames.

```bash
# At the project root
ls -la CLAUDE.md AGENTS.md CLAUDE.local.md 2>/dev/null
ls -la .claude/rules/ .claude/skills/ .claude/agents/ .claude/hooks/ 2>/dev/null
ls -la docs/agent-guides/ 2>/dev/null  # if the user follows the Groff convention

# Global
ls -la ~/.claude/CLAUDE.md ~/.claude/agents/ ~/.claude/skills/ 2>/dev/null
```

For each markdown file found, count lines and characters. CLAUDE.md over 300 lines is a code smell; over 500 is a problem. Note any files that are git-tracked vs gitignored.

Check for the AGENTS.md sync pattern:

```bash
# Is CLAUDE.md a symlink, a shim, or a fully separate file?
[ -L CLAUDE.md ] && echo "symlink → $(readlink CLAUDE.md)"
[ -f CLAUDE.md ] && [ ! -L CLAUDE.md ] && head -3 CLAUDE.md
```

### Phase 2 — Behavioural audit (ykdojo-style)

Mine the project's actual session history to find what's broken in practice.

First, locate the `mine-conversations.sh` script:

```bash
CURATOR_SCRIPTS="$(find ~/.claude -name 'mine-conversations.sh' \
  -path '*/claudemd-curator/scripts/*' 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo '')"
```

If `$CURATOR_SCRIPTS` is non-empty, run:

```bash
TRANSCRIPT_DIR="$("$CURATOR_SCRIPTS/mine-conversations.sh" -n 15)"
```

The script handles the path conversion (slashes → dashes) and the JSONL parsing. It writes transcripts to a temp directory and prints the path on stdout.

If `$CURATOR_SCRIPTS` is empty (scripts not installed on the Claude Code path), do the transcript extraction inline:
- Find `~/.claude/projects/` directory corresponding to the current project path.
- Use `jq` directly to parse the `.jsonl` files into `USER:` / `ASSISTANT:` text.

For each batch of transcripts, spawn a Sonnet subagent with this exact prompt template:

```
Read three things, in order:
1. Global CLAUDE.md: ~/.claude/CLAUDE.md (if it exists)
2. Project CLAUDE.md and AGENTS.md (if they exist)
3. Conversation transcripts: <list of files>

Then, against BOTH instruction files, identify:
1. INSTRUCTIONS VIOLATED — existing rules the agent broke. Quote the rule and the violation.
2. CANDIDATE ADDITIONS — LOCAL — patterns the project repeatedly needed that aren't in the project file.
3. CANDIDATE ADDITIONS — GLOBAL — patterns that recurred and apply across all the user's projects.
4. POTENTIALLY OUTDATED — rules that don't seem to apply anymore, were never followed, or contradict newer patterns.

For each finding, cite at least one transcript and one quote. Bullet points only. No preamble.
```

Batch by file size: large transcripts (>100KB) one or two per agent, medium (10–100KB) three to five, small (<10KB) up to ten. If the user has fewer than five transcripts in `~/.claude/projects/`, do the analysis inline without subagents.

### Phase 3 — Layer classification & content audit

For every line currently in CLAUDE.md, assign a layer (L0–L4) or mark for removal. Apply these tests in order — first failure wins:

1. **Linter test.** Could a deterministic tool enforce this? (Format, lint, type-check, pre-commit.) → Remove. Move to tooling.
2. **Inferability test.** Could the model infer this in three `grep` or `ls` calls? ("This is a TypeScript project", "We use Vite") → Remove.
3. **Universality test.** Does this apply to *every* task in this repo, or only specific tasks? → Specific tasks go in `.claude/rules/<scope>.md` with `paths:` frontmatter for lazy loading, or `docs/agent-guides/<topic>.md` referenced from L3.
4. **Discipline (L1) test.** Is this Karpathy-coded? (Think → simplify → surgical → verify.) → Keep, in L1, in canonical wording. See `references/karpathy-block.md`.
5. **Posture (L2) test.** Is this product-mode-coded? (User/JTBD, reversibility, written tradeoff, done = user-observable.) → Keep, in L2.
6. **Map (L0) test.** Is this directory layout, tech stack, or the one-line "what is this repo" sentence? → Keep, in L0, terse.
7. **Pointer (L3) test.** Could this be a single line like `@docs/agent-guides/migrations.md` or `Read .claude/rules/api-conventions.md when touching src/api/`? → Convert to pointer.
8. **Housekeeping (L4) test.** Compaction instructions, model effort, subagent routing? → Keep, in L4.

Anything that fails all eight tests is bloat.

Full layer definitions, templates, and a worked 280→65 line refactor example are in `references/layer-model.md`. Anti-patterns with rationale are in `references/anti-patterns.md`.

### Phase 4 — Sync verification & repair

Locate the `sync-agents-md.sh` script:

```bash
CURATOR_SCRIPTS="$(find ~/.claude -name 'sync-agents-md.sh' \
  -path '*/claudemd-curator/scripts/*' 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo '')"
```

If found, run:

```bash
"$CURATOR_SCRIPTS/sync-agents-md.sh" check
```

If not found, perform equivalent checks inline using `ls -la`, `readlink`, and `head`.

The script reports four states:
- `OK_SYMLINK` — CLAUDE.md → AGENTS.md, no drift possible.
- `OK_SHIM` — CLAUDE.md is a small file beginning with `See @AGENTS.md`. Inspect for drift in the Claude-specific section.
- `DUAL` — both files exist as full content. **Drift risk.** Diff them and propose one of: convert CLAUDE.md to symlink, convert to shim, or merge.
- `CLAUDE_ONLY` / `AGENTS_ONLY` — only one exists. Propose creating the other (or the symlink) per the chosen pattern.

### Phase 5 — Propose, don't apply

Produce a single artefact: a side-by-side proposal showing current → proposed CLAUDE.md and current → proposed AGENTS.md, plus a numbered list of behavioural-audit findings with the user's accept/reject decision required for each. Wait for explicit approval before editing files.

Format the proposal as:

```
## Proposed changes

### Removals (N)
- [path:line] <content> — reason: <linter | inferable | not universal | bloat>

### Layer reassignments (N)
- L? → L? — <content>

### Behavioural-audit findings (N from M sessions)
- [VIOLATED] <rule> — observed N times — proposed rewording: <new rule>
- [ADD-LOCAL] <pattern> — observed N times — proposed text: <new rule>
- [ADD-GLOBAL] <pattern> — observed N times across <N> projects — proposed text: <new rule>
- [DEAD] <rule> — never followed; observed bypassed N times — propose remove

### Sync action
- <one of: NO_CHANGE | CONVERT_TO_SYMLINK | CONVERT_TO_SHIM | MERGE | CREATE_AGENTS_MD>

### Final files
- AGENTS.md: <line-count>, layers L0–L3 represented
- CLAUDE.md: <line-count>, layers L1, L2, L4 + pointer to AGENTS.md
```

## Examples

### Example 1: typical bloated `/init`-generated CLAUDE.md

User runs `/init` in a Next.js + Postgres repo. Output is 280 lines. Phase 3 classification finds: 90 lines of style rules (linter test fails), 40 lines describing the package.json (inferability test fails), 60 lines of generic "best practices" (universality test fails — they apply only to specific kinds of work and belong in `.claude/rules/`). Final CLAUDE.md is 65 lines. Behavioural audit on three weeks of sessions finds two repeatedly-violated rules — one rewording proposed, one removed because it was never going to be followed and pretending it was a rule was the actual problem.

### Example 2: dual-file drift

Repo has a 250-line CLAUDE.md and a 180-line AGENTS.md. Phase 4 reports `DUAL` with substantial drift. Phase 5 proposal: AGENTS.md absorbs the 90% of CLAUDE.md content that is tool-agnostic (commands, architecture, conventions); CLAUDE.md becomes a 25-line shim covering Claude-specific items only (skills loaded, compact instructions, effort hint). Sister files (`copilot-instructions.md`, Cursor rules) symlinked to AGENTS.md.

### Example 3: ykdojo loop alone

User asks for a behavioural audit but doesn't want a full refactor. Run Phase 1 (minimal — just the two files) + Phase 2 (full transcript mining), skip Phase 3 and Phase 4, deliver only the four bullet-point sections (violated, add-local, add-global, outdated). User picks which to apply manually.

## Common pitfalls

- **Treating `/init` output as a starting point instead of a draft to delete.** Most of what `/init` writes is inferable. Be ruthless.
- **Putting code-style rules in CLAUDE.md.** Style is a linter's job. The model is in-context-learning from the existing codebase already; a few `grep` calls outperform a wall of style instructions and don't burn context every turn.
- **Keeping both CLAUDE.md and AGENTS.md as full files "for safety".** That guarantees drift. Pick symlink or shim and commit.
- **Letting a behavioural-audit rule be "added" without rewording.** If the rule was already there and got violated, adding the same rule again won't help. Reword it more specifically, or move it earlier in the file, or convert it to a hook.
- **Skipping the inventory of `.claude/rules/`.** Path-scoped rules with `paths:` YAML frontmatter are lazy-loaded — they don't count against the always-on context budget. Many things that look like CLAUDE.md candidates belong here instead.
- **Running this skill mid-task.** It mines the project's transcripts; running mid-session pollutes its own findings. Run between sessions.
- **Forgetting `~/.claude/CLAUDE.md`.** Global CLAUDE.md applies to every project. It's the most leveraged file the user has, and it's almost always neglected. Audit it on the same cadence as project files.
- **Assuming Claude Code reads AGENTS.md natively.** It doesn't, as of late April 2026. Some third-party guides claim it does — they're wrong or premature. Use the symlink/shim pattern.

## References

Deeper material is in `references/` — load on demand:

- `references/layer-model.md` — Full L0–L4 definitions, templates, worked examples.
- `references/karpathy-block.md` — Canonical wording for the L1 discipline block, ready to paste.
- `references/product-mode-block.md` — Canonical wording for the L2 decision-posture block.
- `references/anti-patterns.md` — Specific things to remove, with rationale.

Scripts in `scripts/` — execute when needed:

- `scripts/mine-conversations.sh` — Extract recent transcripts from `~/.claude/projects/`. Requires `jq`.
- `scripts/sync-agents-md.sh` — Verify, create, or repair AGENTS.md ↔ CLAUDE.md sync.

External references the skill is grounded in:

- Karpathy's CLAUDE.md: `https://github.com/forrestchang/andrej-karpathy-skills/blob/main/CLAUDE.md`
- product-mode: `https://github.com/sohaibt/product-mode` and the announcement post at `https://www.masteringproducthq.com/p/what-karpathys-claudemd-misses-and`
- ykdojo's review-claudemd: `https://skills.sh/ykdojo/claude-code-tips/review-claudemd`
- HumanLayer's "Writing a good CLAUDE.md": `https://www.humanlayer.dev/blog/writing-a-good-claude-md`
- Groff's three-tier documentation architecture: `https://www.groff.dev/blog/implementing-claude-md-agent-skills`
- AGENTS.md status & Claude Code tracking issue: `https://github.com/anthropics/claude-code/issues/34235`
