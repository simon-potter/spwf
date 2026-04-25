# L2 — Decision posture block (canonical wording)

Paste this into CLAUDE.md as the L2 section if the repo involves product/feature work (vs pure tooling/library work). Source: distilled from `sohaibt/product-mode` (MIT licensed).

Adjust the heading depth to match your file. Trim or omit the principles that genuinely don't apply — but be honest about which ones don't.

---

## Decision posture

Before writing code, the thread must establish four things. After writing code, "done" has a specific meaning.

### 1. User and JTBD anchor

Before any solution, the conversation must contain:

- **Who is the user?** (Specific role or segment, not "users".)
- **What is their problem?** (In their words, not the product team's.)
- **What is the job to be done?** (The outcome they're hiring this feature to deliver.)

If a request arrives as a solution statement ("add a dashboard", "build an export", "create a settings page"), push it back to problem-first before designing. Ask: which user is in pain? What are they trying to do? Is this the cheapest way to address it?

### 2. Reversibility — one-way doors vs two-way doors

Before committing to an approach, classify it:

- **Two-way door (reversible):** local refactor, internal API rename, UI tweak we can revert. Decide fast, move on.
- **One-way door (costly to undo):** public API contract, data schema, pricing, brand, durable UX patterns users will learn. **Stop. Write tradeoffs. Get explicit sign-off before proceeding.**

When in doubt, treat the door as one-way.

### 3. Written tradeoffs with revisit triggers

For one-way doors, the decision record must contain:

- **The alternative considered** — at least one credible option we did not pick.
- **Why we picked this one** — the reason, in one or two sentences a stakeholder who disagrees can still articulate.
- **Revisit trigger** — a metric, date, or condition that would make us reopen the decision.

Test of a good tradeoff write-up: a stakeholder who disagrees with the choice can still articulate why we made it.

### 4. "Done" is user-observable

Done is not "merged". Done is not "tests pass". Done is not "the ticket is closed".

**Done = the user can do the thing, and it works, and we can see it working in production.**

Acceptance criteria must be writable at this level before work starts. If they can't be, the work isn't ready to start.

---

If you find yourself coding before any of the four are settled, stop and surface the gap.
