---
name: tracker-comment
description: Post an audience-aware comment on an existing tracker issue (YouTrack default; Jira and others supported). Classifies the audience as human (e.g. product manager) or record (technical/posterity), rewrites accordingly, and posts via the tracker dispatch. Human comments are succinct plain English with at most one clear ask; record comments allow full technical detail. Use when sending a status update, asking for feedback, or logging a decision on a tracker thread.
disable-model-invocation: true
allowed-tools: [Read, Write, Bash, AskUserQuestion, mcp__youtrack__*, mcp__atlassian__jira_get_issue, mcp__atlassian__jira_add_comment]
---

# tracker-comment

Post an audience-aware comment on an existing tracker issue. The skill
classifies whether the comment is for a real person (e.g. a product
manager) or for the record (technical/posterity), rewrites human-targeted
comments to be plain, succinct, and ask-driven, and posts via the
existing tracker dispatch.

This is **distinct from `capture`'s `create_issue`** (which records new
issues for the team) — `tracker-comment` posts to existing issue threads,
typically to update a stakeholder or log progress.

## Step 1 — Resolve the issue id

Read `$ARGUMENTS`. The first whitespace-separated token is the issue id
or option flag; the rest is the draft comment text (if provided
inline).

| Input | Resolution |
|---|---|
| Empty | Read `ticket:` from the active todo file (most recent in `todo/` matching the current branch or change-id; falls back to `todo/_done/` for archived). If found, use it. Else ask. |
| Issue id (e.g. `ACAD-42`, `PROJ-123`) | Use directly. |
| Todo path ending `.md` | Read frontmatter `ticket:` field. |

If no issue id can be resolved, halt with: *"No tracker issue id
provided and none found in the active todo file. Pass an id (e.g.
`/spwf:tracker-comment ACAD-42 your draft comment`) or run from a repo
with a todo file containing a `ticket:` field."*

Recognised flags (strip from `$ARGUMENTS` before parsing the rest):
- `--for=human` / `--for=record` — override audience classification
- `--draft` — save the prepared comment to disk instead of posting
- `--no-fetch` — skip the `get_issue` call that grounds context
  (faster but less informed; rarely needed)

## Step 2 — Verify tracker MCP and fetch issue context

Resolve the active tracker per `_shared/tracker-dispatch.md`. If no
tracker MCP is configured (and `tracker:` isn't `none`), **fail fast**
with the standard message:

> *"No issue tracker MCP configured. Configure YouTrack or Atlassian
> MCP, or set `tracker: none` in `.spwf/tracker.yaml` to opt out."*

If `tracker: none` is set, halt with: *"Tracker integration is opted out
for this repo (`tracker: none`). Cannot post a comment."*

Unless `--no-fetch` was passed, fetch the issue:

```
get_issue(id="{ticket}")
```

Capture: title, type, current state, reporter, recent commenter
usernames if returned, labels. This grounds audience classification
(e.g. issue type "Feature Request" with non-technical reporter
strongly suggests human-target).

If the fetch fails, surface the tracker error verbatim and stop —
posting a comment to an issue you can't even read is suspicious.

## Step 3 — Get the draft comment text

If the user provided text inline after the issue id in `$ARGUMENTS`,
use that as the draft.

Otherwise prompt:

> "What's the comment? Paste or type the draft (multi-line OK; finish
> with a blank line and Enter):"

Wait for input. An empty draft halts with: *"No draft text provided.
Cancelled."*

## Step 4 — Classify audience

Reason about the audience using the cues below. **Do not use regex;
this is a model-reasoning task** — read the draft, the issue context,
and judge.

**Human-target cues** (favour `human` classification):
- `@-mentions` of named people in the draft
- Direct questions to a named recipient: "@bob, can you confirm…",
  "PM Sarah — does this match what you wanted?"
- Phrases like "need feedback", "could you confirm", "let me know",
  "want your view on", "checking with you before…"
- Short, conversational tone (under ~200 words, no code blocks)
- Issue context: reporter or active commenters appear non-technical
  (e.g. usernames matching `pm.*`, `product.*`, `design.*`,
  `support.*`)
- Issue type "Feature Request", "Customer Issue", "User Story" with
  non-engineering reporter

**Record-target cues** (favour `record` classification):
- Phrases like "for the record", "documenting", "log:", "for
  posterity", "noting that", "leaving this for future me"
- Heavy code blocks (≥2 in the draft) without addressing anyone
- Many file references (≥3 paths) without a question
- Timeline/incident-report shape
- Issue type "Bug" with technical reporter, no @-mentions in draft

**Cost-asymmetric default when unsure: `human`.** Rewriting a
record-style comment to plain English is cheap; posting a wall of
code to a PM is expensive. When the cues are mixed or weak, treat as
`human` and let the user override.

If `--for=human` or `--for=record` was passed, trust it without
re-classifying.

If the cues are *genuinely* split (e.g. the draft has code blocks AND
an @-mention to a named person), ask the user:

> "Audience for this comment is mixed. Is this primarily for: a real
> person (rewrite plain), or the record (light cleanup)?"

Use the loaded `AskUserQuestion` tool with the two clear options.

## Step 5 — If audience is `human`: rewrite

Apply these rules. They mirror `recap`'s anti-padding regime
(`plugins/spwf/skills/recap/SKILL.md` Step 5) but adapted for
stakeholder communication.

1. **Plain language in the draft's working language.** If the draft is
   in French, rewrite in French. Don't translate. The "plain English"
   shorthand is "plain language at a non-technical reading level"
   regardless of which language.
2. **At most one short code block.** Only include if the question
   genuinely requires code. Otherwise paraphrase: *"the login flow"*
   instead of pasting the function.
3. **At most one file reference.** Format as `path/to/file` (no line
   numbers unless specifically requested by the recipient).
4. **One clear ask at the end.** What do you want the recipient to do?
   Confirm, decide, review, sign off. Make it the last sentence and
   make it explicit.
5. **Max ~150 words.** If the original is longer, distil. Stakeholders
   read scanning, not reading.
6. **Friendly tone.** Conversational, not corporate. "Hi @Bob — quick
   check before we close this:" is better than "Dear stakeholder, we
   require your sign-off on the following matter:".
7. **Banned hedging phrases.** No: "It is worth noting that…", "In
   conclusion…", "This change demonstrates…", "Overall…", "It should
   be noted…", "Importantly…", "Please note that…".
8. **Banned generic vocabulary.** No: "the codebase", "best
   practices", "industry standard", "as you may know".
9. **Preserve `@-mentions` exactly.** Both Jira and YouTrack render
   them with autocomplete linkage; don't paraphrase a `@bob` to
   "Bob".
10. **Preserve formatting that helps a human reader** — short bullet
    lists are fine; numbered steps for an action sequence are fine.
    What you're cutting is verbosity, not structure.

Show the rewrite alongside the original. Format:

```
─── Original draft ───────────────────────────────────────
{original text}

─── Rewrite (audience: human) ────────────────────────────
{rewritten text}

({N} → {M} words, audience inferred from: {1-2 cue phrases})
```

## Step 6 — If audience is `record`: light cleanup only

- Trim trailing whitespace
- Normalise code-fence formatting (` ``` ` not ` ```` `; closing fence
  present)
- Fix obvious typos (e.g. doubled words "the the")
- Allow technical detail and full length
- **Do not impose any length cap or banned-phrase rule** — record
  comments are for posterity, not stakeholders

Show the cleaned text:

```
─── Comment (audience: record) ───────────────────────────
{cleaned text}

(audience inferred from: {1-2 cue phrases}; light cleanup applied)
```

## Step 7 — Length sanity check

If the prepared text exceeds ~32,000 characters (Jira's documented
comment limit; YouTrack is similar), halt with:

> *"Prepared comment is {N} chars; tracker max is ~32KB. Split into
> multiple comments or shorten before posting."*

Do not auto-truncate.

## Step 8 — Confirm before posting

Prompt:

```
Post this comment to {tracker} {issue-id}? [Y/n/edit]
```

- `Y` (or enter): proceed to Step 9.
- `n`: cancel cleanly. Report: *"Cancelled. No comment posted."*
- `edit`: open `$EDITOR` (or `$VISUAL`) on a temp file containing the
  prepared text. On save, use the saved content. **If the saved file
  is empty (zero bytes or whitespace only), treat as cancel** — do
  not post empty comments.

## Step 9 — Post via `add_comment`

Dispatch per `_shared/tracker-dispatch.md`:

```
add_comment(id="{ticket}", body="{prepared text}")
```

- **YouTrack**: tool name resolved at runtime via the `mcp__youtrack__*`
  glob (the JetBrains MCP server advertises its comment-posting tool
  at handshake; the model picks the right one).
- **Jira**: `mcp__atlassian__jira_add_comment`.

If the call fails (closed issue, auth, network, rate limit): surface
the tracker error verbatim and stop. Do not retry, do not silently
swallow, do not pretend success.

## Step 10 — `--draft` mode (alternative to Step 9)

If `--draft` was passed, do NOT call `add_comment`. Instead:

```bash
mkdir -p todo/.tracker-drafts
DRAFT_PATH="todo/.tracker-drafts/${TICKET}-$(date +%Y-%m-%d-%H%M).md"
```

Write the prepared text to `$DRAFT_PATH`, including a small header
recording: ticket id, timestamp, audience classification, original
draft (preserved at the bottom for re-edit).

Drafts accumulate (the timestamp suffix is unique to the minute;
collisions are rare and tolerable). The hidden `.tracker-drafts/`
directory is excluded from active todo scans (`challenge`, `spec`,
`wfstatus` use top-level `todo/*.md` globs that don't recurse).

Report: *"✓ Draft saved: {path}. Run `/spwf:tracker-comment {ticket}`
again with the draft text to post."*

## Step 11 — Report

```
✓ Posted comment on {tracker} {ticket}
  Audience:    {human | record}
  Length:      {N} words ({M} chars)
  URL:         {issue url + comment anchor if available}

  Original:    {N_orig} words
  Posted:      {N_posted} words ({delta} change)
```

For `--draft` mode, report the saved path instead of the post URL.

## Constraints

- Never post empty comments.
- Never auto-truncate over-length text.
- Never bypass the `--for=` override — the user knows their audience
  better than the model when they tell you.
- Never silently fall back if the tracker MCP is unavailable.
- Never change the language of the draft (no English translation).
- Never strip `@-mentions` during cleanup.
- Never retry a failed `add_comment` call.

## Out of scope

- Editing existing comments (`update_comment`) — v1 only adds new
  comments. Editing is a separate operation and rarely needed.
- Multi-issue cross-posting. Comment per call.
- GitHub/GitLab PR-comment integration (forge comments are a separate
  scenario; pr-create / pr-review cover the PR/MR itself).
- Reading entire issue thread for richer audience inference. v1 reads
  only the issue itself via `get_issue`. A `--with-thread` flag could
  be added later if real cases demand it.
- Clipboard URL copy on success (v2).
- Comment templates ("post the standard 'PR is up for review' message").

## Relationship to other skills

- **`recap`** — sister skill for audience-aware writing. Recap is for
  the user (concept consolidation at close); tracker-comment is for
  stakeholders (status updates posted to tracker). Same primitive
  (audience-aware writing), different audience and channel. The
  banned-phrases list is shared.
- **`capture`** — different scenario (creates new issues). Capture's
  `create_issue` body is for the team/record by default and is not
  routed through audience-check.
- **`close`** — close uses `set_state` only (no body); does not
  invoke this skill. After running `close`, you may want to post a
  completion update on the linked issue — `/spwf:tracker-comment` is
  the right manual follow-up if a stakeholder needs to know.
- **`tracker-comment-nudge.sh` hook** — fires `PreToolUse` on tracker
  write tools and warns if the body looks heavy-technical. The hook
  is advisory; it suggests this skill but doesn't force its use.
