# CLAUDE.md Update Guidelines

Source: Anthropic `claude-md-management` plugin (Isabella He, isabella@anthropic.com).
Used verbatim under the official Anthropic claude-plugins-official repository (https://github.com/anthropics/claude-plugins-official).

## Core Principle

Only add information that will genuinely help future Claude sessions. The context window is precious — every line must earn its place.

## What TO Add

### 1. Commands/Workflows Discovered

Bash commands used or found during analysis that aren't already documented.

### 2. Gotchas and Non-Obvious Patterns

Quirks, workarounds, edge cases, "why we do it this way" for unusual patterns.

### 3. Package Relationships

How modules depend on each other; what order things must be done in.

### 4. Testing Approaches That Worked

Commands, patterns, environment requirements for running tests successfully.

### 5. Configuration Quirks

Non-obvious environment variables, setup steps, or configuration requirements.

## What NOT to Add

### 1. Obvious Code Info

`"The UserService class handles user operations"` — the model can read the code.

### 2. Generic Best Practices

`"Always write tests for new features"` — the model already knows this.

### 3. One-Off Fixes

References to specific commits or bugs unlikely to recur.

### 4. Verbose Explanations

Prefer one-liner summaries over paragraphs. If it takes more than two lines, it probably belongs in a linked doc, not inline.

## Diff Format for Proposed Updates

For each suggested change, show:

```markdown
### Update: ./CLAUDE.md

**Why:** [one-line reason]

```diff
+ ## Quick Start
+
+ ```bash
+ npm install
+ npm run dev  # Start development server on port 3000
+ ```
```
```

## Validation Checklist

Before including any proposed addition in the Phase 5 proposal, verify:

- [ ] Project-specific — not generic advice or obvious code info
- [ ] No generic best practices the model already knows
- [ ] No one-off fixes unlikely to recur
- [ ] Commands tested and working (or explicitly marked as unverified)
- [ ] File paths accurate
- [ ] Most concise possible expression — one line per concept where possible
- [ ] Would a new Claude session find this helpful?
