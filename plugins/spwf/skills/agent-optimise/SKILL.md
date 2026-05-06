---
name: agent-optimise
description: Cross-cutting — Audit both the project .claude/ and personal ~/.claude/ for quality issues. Covers CLAUDE.md scope and length, agent descriptions, skill frontmatter, and settings.json conflicts. Always audits both scopes. Produces a prioritised P1/P2/P3 fix list.
disable-model-invocation: true
allowed-tools: [Read, Glob, Grep, Bash]
---

# agent-optimise

Audit the full Claude/Codex tooling surface — both project-level and personal — for quality, bloat, and conflicts. Produce a prioritised fix list.

## Why both scopes

Agent bloat accumulates in both places. Seeing only one scope produces a misleading picture — a conflict between project and personal settings is invisible if you only audit one. The combined surface is always small enough to audit in one pass.

## Step 1: Collect all files

```bash
# Project scope
find .claude/ -type f 2>/dev/null
ls .claude/settings.json 2>/dev/null

# Personal scope
find ~/.claude/ -type f 2>/dev/null
ls ~/.claude/settings.json 2>/dev/null
```

Also check for Codex equivalents:
```bash
find .codex/ -type f 2>/dev/null
find ~/.codex/ -type f 2>/dev/null
```

## Step 2: Audit CLAUDE.md files

For each CLAUDE.md found:

**Length check:**
- Project CLAUDE.md > 200 lines: flag P2 (can be 300 if well-structured)
- Component/subdirectory CLAUDE.md > 150 lines: flag P1
- Personal `~/.claude/CLAUDE.md` > 400 lines: flag P2

**Scope check:**
- Does it contain project-specific paths, commands, or names that would be wrong in another project? Flag if in personal `~/.claude/`.
- Does it contain personal preferences (communication style, workflow opinions) that belong in personal config but are in project config? Flag P3.
- Does it duplicate instructions that are already in a parent CLAUDE.md? Flag P2.

**Content quality:**
- Are there contradictory instructions (e.g., "always do X" and "never do X")? Flag P1.
- Are there instructions that reference tools, commands, or files that no longer exist? Flag P2.
- Are there verbose multi-paragraph explanations that could be one line? Flag P3.

## Step 3: Audit agent definitions

For each agent .md file in `.claude/agents/` or `~/.claude/agents/`:

**Description quality:**
- Is the description one sentence? (Good) Multiple sentences? (Flag P3 — descriptions should be concise)
- Does the description use trigger keywords that are too broad (e.g., "use when working on code")? Flag P2.
- Does the description overlap significantly with another agent's description? Flag P1.

**Tool scope:**
- Does the agent have `[*]` or `[All]` tools when it only needs 3-4? Flag P2.
- Does the agent have tools that conflict with its stated purpose? Flag P1.

**Model assignment:**
- Is a simple extraction task using Opus? Flag P2 (use Haiku).
- Is a complex implementation task using Haiku? Flag P1 (use Sonnet or Opus).

## Step 4: Audit skill frontmatter

For each SKILL.md in `.claude/skills/` or `~/.claude/skills/`:

**disable-model-invocation:**
- Is it set? If not, skill may trigger autonomously — flag P2 for workflow skills.

**allowed-tools:**
- Is it set? Unscoped skills can use any tool — flag P2.
- Are tools listed that the skill body never uses? Flag P3.

**name and description:**
- Does the name match the directory name? Flag P1 if not.
- Is the description specific enough to route correctly? Flag P2 if vague.

## Step 5: Audit settings.json

For each settings.json found (project and personal):

```bash
cat .claude/settings.json 2>/dev/null
cat ~/.claude/settings.json 2>/dev/null
```

Check for:
- Conflicting keys between project and personal (personal overrides project — is that intended?)
- Tool permissions that are overly broad
- Hooks that reference commands that no longer exist

## Step 6: Produce the fix list

```markdown
## Agent Optimise Report

**Scopes audited**: project (.claude/) + personal (~/.claude/)
**Date**: {date}

---

### P1 — Fix now (correctness or conflict issues)

- [ ] {file}: {issue} — {recommended fix}

### P2 — Fix soon (quality or bloat issues)

- [ ] {file}: {issue} — {recommended fix}

### P3 — Fix when convenient (polish)

- [ ] {file}: {issue} — {recommended fix}

---

### Summary

| Location | Files audited | P1 | P2 | P3 |
|---|---|---|---|---|
| .claude/ | {n} | {n} | {n} | {n} |
| ~/.claude/ | {n} | {n} | {n} | {n} |
```

Do not apply any fixes. The fix list is for the user to act on.
