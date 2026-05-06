# L1 — Discipline block (canonical wording)

Paste this verbatim into CLAUDE.md as the L1 section. Do not paraphrase: the wording is dense for a reason. Source: Karpathy's CLAUDE.md (`forrestchang/andrej-karpathy-skills`), used under MIT-equivalent open license.

Adjust the heading depth (`##` → `###`) to match your file's existing hierarchy.

---

## Discipline

These guidelines bias toward caution over speed. For trivial tasks, use judgement.

### 1. Think before coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity first

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Test: would a senior engineer say this is overcomplicated? If yes, simplify.

### 3. Surgical changes

Touch only what you must. Clean up only your own mess.

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that *your* changes made unused.
- Don't remove pre-existing dead code unless asked.

Test: every changed line should trace directly to the user's request.

### 4. Goal-driven execution

Define success criteria. Loop until verified.

- "Add validation" → "Write tests for invalid inputs, then make them pass."
- "Fix the bug" → "Write a test that reproduces it, then make it pass."
- "Refactor X" → "Ensure tests pass before and after."

For multi-step tasks, state a brief plan:

```
1. <Step> → verify: <check>
2. <Step> → verify: <check>
3. <Step> → verify: <check>
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

These guidelines are working if: fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come *before* implementation rather than after mistakes.
