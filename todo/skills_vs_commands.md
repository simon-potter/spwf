---
created: 2026-04-24
status: analysis
---

# Skills vs Commands — Architectural Analysis

Documenting the distinction, what agent-skills actually does, where slash commands are heading, and what this means for our marketplace.

---

## 1. The Core Pattern We Missed: Commands Compose Multiple Skills

The key misunderstanding in our current design: **a workflow command is an orchestrator that composes multiple skills**. We built one monolithic SKILL.md per workflow stage instead.

### What agent-skills actually does

The `build` command in agent-skills is NOT a single skill. It explicitly composes three:

```
build command (.claude/commands/build.md):
  1. Invoke agent-skills:incremental-implementation
  2. Alongside agent-skills:test-driven-development (RED/GREEN cycle)
  3. If any step fails → agent-skills:debugging-and-error-recovery
```

The composition is **explicit and declarative** in the markdown body — the command literally says "invoke the `agent-skills:incremental-implementation` skill" and "alongside `agent-skills:test-driven-development`".

Skills are **atomic capabilities**. Commands are **workflow orchestrators**.

### What we built instead

```
workflow-core/skills/build/SKILL.md  ← monolithic
  Contains: implementation instructions
           + test references
           + task-finding logic
           + completion marking
```

Our `build` skill tries to be both the orchestrator AND all the atomic capabilities at once. This means:
- Skills can't be reused across different workflow stages
- The `build` stage can't cleanly hand off to `test` because they're separate monoliths
- No ability to conditionally invoke a `debug` skill if tests fail

### The correct pattern

```
workflow-core/
├── commands/
│   └── build.md       ← orchestrator: "invoke incremental-implementation,
│                          then test-creator, then if tests fail: debug-recovery"
└── skills/
    ├── incremental-implementation/SKILL.md  ← atomic: implement one task slice
    ├── test-creator/SKILL.md                ← atomic: write behaviour tests
    ├── debug-recovery/SKILL.md             ← atomic: diagnose and fix failures
    └── ...
```

---

## 2. Slash Command Deprecation — What's Actually Happening

Both Claude Code and Codex are deprecating the `.claude/commands/` slash command format — but **not** removing slash commands as a concept.

### The merge

Slash commands are being **unified into the skills system**:
- Old: `.claude/commands/plan.md` → `/plan` (markdown file, no metadata)
- New: `skills/plan/SKILL.md` with YAML frontmatter → also invocable as `/plan`

Backward compatibility is maintained. Existing `commands/` folders still work.

### Why: progressive disclosure

The real driver is a new capability: **skills can be autonomously invoked by Claude during reasoning**, not just by user `/trigger` input. This is called progressive disclosure.

- `disable-model-invocation: true` → user must explicitly type the slash command
- `disable-model-invocation: false` (or absent) → Claude can invoke the skill autonomously during reasoning

Traditional slash command files (`.claude/commands/`) can't participate in progressive disclosure. Skills can.

This means:
- Our `disable-model-invocation: true` on all workflow phase skills is correct — they're intentional user-triggered checkpoints
- Our agents (no `disable-model-invocation`) can be invoked autonomously by Claude — this is the right call for specialist subagents

### For our design

The deprecation means: **`skills/` is the right layer to build on, not `commands/`**. Our approach of putting everything in SKILL.md files is aligned with where both platforms are going.

The remaining question is just: should those skills be monolithic (current) or atomic with composition (agent-skills pattern)?

---

## 3. What This Means for Our Marketplace

### Problem: monolithic skills can't compose

Our current skills are designed as self-contained stages. This works fine for a simple sequential workflow, but breaks down when:
- A stage needs to conditionally invoke a sub-skill (e.g., build → debug if tests fail)
- A skill needs to be reused across stages (test-creator is needed in both build and standalone test-writing)
- You want to selectively install only some capabilities without getting the full stage

### We've partially solved this via agents

The `workflow-agents` plugin actually addresses composition differently: each agent is already scoped to one atomic responsibility and can be autonomously combined by Claude. The `builder.md` agent doesn't try to also test — it defers to `tester.md`.

But the skills don't have this separation.

### Recommendation

**Short term (keep current structure):** The monolithic skills work for the stated purpose — user-triggered workflow checkpoints. For personal workflow tooling this is acceptable. The agents handle the autonomy layer.

**Medium term (refactor to composable structure):** If we want to follow the agent-skills pattern properly:

1. **Rename current skills** to descriptive names: `plan/` → `planning-workflow/`, `build/` → `incremental-implementation/`, etc.
2. **Split build into three skills**: `incremental-implementation`, `test-creator`, `debug-recovery`
3. **Add `commands/` to each plugin** for the short user-facing orchestrators
4. **Update plugin.json** with `"commands": "./commands"`
5. **Commands reference skills** explicitly: "invoke `workflow-core:incremental-implementation`, then `workflow-core:test-creator`…"

The resulting structure:

```
workflow-core/
├── commands/                         ← user-facing (short names, orchestrators)
│   ├── plan.md                       → /workflow-core:plan
│   ├── build.md                      → /workflow-core:build  (composes 3 skills)
│   ├── test.md                       → /workflow-core:test
│   ├── simplify.md                   → /workflow-core:simplify
│   └── ship.md                       → /workflow-core:ship
├── skills/                           ← atomic capabilities (descriptive names)
│   ├── planning-workflow/SKILL.md
│   ├── incremental-implementation/SKILL.md
│   ├── test-creator/SKILL.md
│   ├── debug-recovery/SKILL.md
│   ├── test-runner/SKILL.md
│   ├── code-review/SKILL.md
│   ├── code-simplification/SKILL.md
│   ├── pr-creation/SKILL.md
│   └── task-to-spec/SKILL.md
└── .claude-plugin/plugin.json
    → "commands": "./commands"
```

---

## 4. Summary

| Question | Answer |
|---|---|
| Do workflow stages call multiple skills? | **Yes** — in agent-skills, `build` composes 3 skills. We have monolithic stages instead. |
| Have we accommodated this? | **Partially** — via agents (which are atomic and composable). Skills are monolithic. |
| Are slash commands deprecated? | **Unified into skills**, not removed. `.claude/commands/` still works but skills are the future. |
| Is our `skills/` approach right? | **Yes** — SKILL.md format is the correct layer to build on going forward. |
| Is our `disable-model-invocation: true` right? | **Yes** — workflow gates should be user-triggered checkpoints. |
| What should we fix? | Either keep monolithic skills (acceptable for personal tooling) or refactor to commands + atomic skills (better architecture, matches agent-skills pattern). |

---

## Open Decision

**Do we refactor workflow-core to use the commands + atomic skills pattern before publishing, or ship the current monolithic structure and refactor as part of a v0.2?**

Arguments for refactoring now:
- Marketplace is not yet published (no migration cost)
- Agent-skills compatibility: anyone who knows agent-skills will expect this structure
- Enables proper skill reuse (test-creator used in both build and standalone)

Arguments for keeping current:
- Works functionally — monolithic skills do what they say
- Simpler to explain and maintain
- The agents layer already provides composability for autonomous workflows
- Can refactor incrementally without breaking the user-facing command names
