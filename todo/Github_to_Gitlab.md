---
source: scratch
created: 2026-05-07
status: ideation
---

# GitHub → GitLab (with multi-forge future)

## Context

The marketplace currently assumes GitHub via the `gh` CLI for everything PR-related.
In practice most of our work happens on GitLab (where pull requests are called *merge
requests* and the equivalent CLI is `glab`), and we may later want first-class support
for Bitbucket, Gitea, Forgejo, or others. We want GitLab to become the first-class
default, GitHub to remain a supported alternative (not removed), and the architecture
to be open to additional forges without another rewrite.

This is the same pattern we just applied to issue trackers (`todo/Jira_to_youtrack.md`)
— a thin abstraction over the forge with auto-detection from the existing git remote
and a fail-fast contract when the right CLI isn't installed.

---

## What we know — full inventory of GitHub / `gh` references

### A. Skills that invoke `gh` directly

| File | Lines | What it does |
|---|---|---|
| `plugins/spwf/skills/pr-review/SKILL.md` | 4, 30, 31, 34 | `gh pr view --json …`, `gh pr diff` to fetch PR data and produce a review report. Halts on `gh` failure. |
| `plugins/spwf/skills/pr-create/SKILL.md` | 4, 156–173 | `gh pr create --title … --body …` after pre-flight checks pass. |

### B. Agents that invoke `gh` directly

| File | Lines | What it does |
|---|---|---|
| `plugins/spwf-agents/agents/pr-creator.md` | 14, 44–55 | Mirror of pr-create skill — runs pre-flight, calls `gh pr create`. |
| `plugins/spwf-agents/agents/reviewer.md` | 15, 16 | Mirror of pr-review skill — `gh pr view`, `gh pr diff`. |

### C. Skills that reference GitHub semantically (no `gh` call) but encode forge assumptions

| File | Lines | What it encodes |
|---|---|---|
| `plugins/spwf/skills/pr-review/SKILL.md` | 24 | Example URL `https://github.com/org/repo/pull/42` in usage hint |
| `plugins/spwf/skills/pr-create/SKILL.md` | 127–131 | Tooling setup snippet recommends a GitHub Actions workflow for gitleaks |
| `plugins/spwf/skills/changelog/SKILL.md` | 105 | "Strip trailing issue references … convert to a link if **GitHub** remote is detectable" |

### D. Documentation referencing GitHub / `gh`

| File | Lines |
|---|---|
| `README.md` (root) | 23 (PR Create row), 24 (PR Review row), 109 (Prerequisite #3 heading "GitHub CLI"), 112 (`brew install gh`, `cli.github.com` URL), 113 (`gh auth login`) |
| `plugins/spwf/README.md` | 122 (attribution to `addyosmani/agent-skills` on GitHub — leave alone, it's a real source URL) |
| `todo/Marketplace_setup.md` | 55, 57, 61, 62, 64, 95, 101, 260, 261, 334, 421, 473, 475, 504, 539 |
| `todo/optimal-agentic-env.md` | 38, 40, 97, 127, 146, 155, 181, 201 — discusses GitHub MCP as a future addition |
| `openspec/changes/add-plugin-marketplace/proposal.md` / `tasks.md` / `design.md` / `specs/marketplace/spec.md` | multiple — historical record |

### E. AGENTS.md / `.github/` Copilot integration

`plugins/spwf/skills/claudemd-curator/scripts/sync-agents-md.sh:277-280` symlinks
`AGENTS.md` to `.github/copilot-instructions.md`. This is a **GitHub Copilot product**
file-location convention, not a GitHub-forge thing — Copilot reads the file regardless
of which forge hosts the repo. **Leave as-is.**

### F. Attribution URLs (do not change)

Many SKILL.md frontmatter comments and references doc lines link to
`https://github.com/{addyosmani,wshobson,anthropics,…}/...` as the **source** of seeded
material. These are real upstream URLs and stay as-is regardless of which forge our
own repo lives on. Affected files include:

- `plugins/spwf/skills/{approve-plan,build,run-tests,simplify,pr-create}/SKILL.md` (addyosmani attribution)
- `plugins/spwf/skills/{pr-review,challenge}/SKILL.md` (wshobson, mattpocock attribution)
- `plugins/spwf/skills/claudemd-curator/SKILL.md` and its references (anthropics, karpathy, sohaibt attribution)
- `plugins/spwf/skills/security-scan/references/sql-injection.md` (github copilot attribution)

### G. Things that DON'T need to change

- All `gh` invocations within skills/agents will be **replaced with abstracted calls**, but the underlying logic doesn't change.
- The `.github/copilot-instructions.md` symlink (Copilot product convention).
- All upstream attribution URLs.
- `git remote`, `git push`, `git log`, etc. — git itself is forge-agnostic.
- `migrate-to-spwf.sh` is a one-shot helper for a historical move; reference to a GitHub URL inside it is vestigial.

---

## Goal recap

1. **GitLab becomes first-class default.** All examples, prerequisites, and recommended
   prompts speak GitLab + `glab` first.
2. **GitHub remains supported.** Existing `gh` integration is preserved and selectable.
3. **Adding a third forge (Bitbucket, Gitea, Forgejo, …) is a one-file change**, not a
   marketplace-wide rewrite.
4. **No breaking change for downstream projects already on GitHub.** They keep working
   until they choose to switch.
5. **Auto-detection from `git remote`** wherever possible — most repos won't need any
   config file.

---

## Vocabulary nuance: PR vs MR

GitHub calls them **Pull Requests (PR)**, referenced as `#42`. GitLab calls them
**Merge Requests (MR)**, referenced as `!42`. Both communities understand "PR" and
"MR" interchangeably in conversation, but the canonical forge term differs.

| Concept | GitHub | GitLab | Bitbucket |
|---|---|---|---|
| Change request | Pull Request (PR) | Merge Request (MR) | Pull Request |
| Reference syntax | `#42` | `!42` | `#42` |
| CLI verb | `pr` | `mr` | `pr` (limited) |
| URL path | `/pull/42` | `/-/merge_requests/42` | `/pull-requests/42` |

**Decision needed:** keep skill names (`pr-create`, `pr-review`) as-is — they remain
the discoverable command surface — but treat them as forge-agnostic internally. Reports
use the active forge's vocabulary ("PR #42" on GitHub, "MR !42" on GitLab). Renaming
skills is a breaking change for muscle memory and isn't justified by the abstraction
work.

---

## Architecture options

### Option 1 — Replace `gh` with `glab`

Swap every `gh pr {view,diff,create}` for the `glab mr {view,diff,create}` equivalent.
Update docs.

- ✅ Smallest diff. No abstraction.
- ❌ Locks us in again. Repeats the same mistake one forge over.
- ❌ Breaks every downstream project currently on GitHub.

### Option 2 — Forge abstraction with auto-detection (recommended)

Introduce a thin "forge" concept that skills consult before any forge-specific call.
The default path is auto-detection from `git remote get-url origin`; a small optional
config file overrides for self-hosted instances.

- A new optional `.spwf/forge.yaml` declares the active forge and any forge-specific
  config (host URL for self-hosted GitLab, etc.).
- If the file is missing, skills detect the forge from the git remote URL.
- Skills' `Bash` invocations are wrapped in a small dispatch helper documented in
  `_shared/forge-dispatch.md` (next to `tracker-dispatch.md`).
- Reports and report templates use forge-appropriate vocabulary (`#42` for GitHub,
  `!42` for GitLab).

- ✅ Zero-config common case — most repos auto-detect correctly from `git remote`.
- ✅ GitLab becomes the canonical example; GitHub is just one branch.
- ✅ Adding Bitbucket/Gitea later is a new dispatch row + new CLI binding, no skill
  rewrites.
- ✅ Backwards-compatible — projects on GitHub keep working without changing anything.
- ⚠️ Each forge-touching skill has slightly more text (a small dispatch block instead
  of a one-line shell). Acceptable cost.

### Option 3 — MCP-based abstraction

Use a GitHub MCP server (Anthropic / community) and a GitLab MCP server, abstract over
their tool surface like we did for trackers.

- ✅ Consistent with the tracker abstraction shape.
- ❌ Adds two MCP server dependencies for what `gh` and `glab` already do well from a
  shell.
- ❌ MCP coverage of forge operations is uneven (some operations exist as named tools,
  others don't); CLIs are far more complete.
- ❌ Latency: shelling to a CLI is faster than round-tripping through MCP for simple
  view/diff/create operations.

**Verdict:** keep CLIs as the primary mechanism. MCP servers can be an *additional*
dispatch branch later (e.g. for environments where the CLI isn't available), but
they're not the right primary tool here. Trackers were natural MCP territory because
ticket fetch/transition is structured CRUD; PR creation is essentially shell.

### Option 4 — git push + URL hint, drop the CLI entirely

Don't shell out to any forge tool — just `git push` and report the URL the forge prints
on its first push response. User opens the browser; forge UI handles PR/MR creation.

- ✅ Zero forge-specific tooling.
- ❌ Loses pre-flight body composition (the OpenSpec/proposal-derived PR body).
- ❌ Loses structured PR review (`pr-review` needs to *read* PR data).
- ❌ Pushes the human into a browser at exactly the moment we want them watching the
  terminal.

**Verdict:** No. The CLIs earn their keep.

---

## Recommended approach: Option 2, phased

### Step 1 — Define the forge contract

Each forge plugs in by implementing three logical operations:

| Operation | Used by | GitHub (`gh`) | GitLab (`glab`) |
|---|---|---|---|
| `view_request(ref)` | `pr-review` | `gh pr view {ref} --json …` | `glab mr view {ref} --output json` |
| `diff_request(ref)` | `pr-review` | `gh pr diff {ref}` | `glab mr diff {ref}` |
| `create_request(title, body)` | `pr-create` | `gh pr create --title … --body …` | `glab mr create --title … --description …` (note: `--description`, not `--body`) |

Both CLIs accept either a number or a URL as the `{ref}`. The URL formats differ
(`/pull/42` vs `/-/merge_requests/42`); the CLI handles both in either case.

### Step 2 — Detection

When `.spwf/forge.yaml` is absent, skills detect the forge from `git remote get-url
origin`:

```
github.com               → forge: github, cli: gh
gitlab.com               → forge: gitlab, cli: glab
gitlab.{custom-domain}   → forge: gitlab (self-hosted), cli: glab + GLAB_HOST
ssh.dev.azure.com        → forge: azure (future)
bitbucket.org            → forge: bitbucket (future)
gitea.{custom}           → forge: gitea (future)
```

Heuristics:
- Match `github.com` → GitHub (cloud).
- Match `gitlab.` anywhere in the host → GitLab (cloud or self-hosted; pass the host
  through to `glab` via `GLAB_HOST`).
- Other hosts → ask the user once on first need; offer to save to `.spwf/forge.yaml`.

### Step 3 — Configuration

`.spwf/forge.yaml` is **optional and minimal** — exists only for self-hosted overrides
or when detection is ambiguous:

```yaml
# .spwf/forge.yaml — all fields optional
forge: gitlab            # github | gitlab | bitbucket | gitea | none
host: gitlab.example.com # self-hosted GitLab URL (auto-derived from git remote when possible)
default_base: main       # base branch for PR/MR creation (usually auto-detected)
```

Setting `forge: none` opts out of forge-touching skills entirely — `pr-create` and
`pr-review` will refuse to run with a clear "no forge configured" message. (Useful for
private mirrors, archive repos, or local-only experiments.)

### Step 4 — Add a shared reference document

Create `plugins/spwf/skills/_shared/forge-dispatch.md` (sibling of
`tracker-dispatch.md`). It contains:

- The fail-fast contract (mirroring the tracker abstraction)
- The detection rules
- The dispatch table (GitHub vs GitLab tool/flag mapping)
- CLI installation and auth notes (`gh auth login`, `glab auth login`, host config)
- Vocabulary mapping (PR/MR, `#`/`!`, URL paths)
- "Adding a new forge" walkthrough

### Step 5 — Skill changes

For each of `pr-create` and `pr-review`:

1. Replace hard-coded `gh pr …` invocations with a dispatch shell snippet that:
   - Reads `.spwf/forge.yaml` if present, else detects from `git remote`
   - Selects the right CLI binary (`gh` or `glab`)
   - Maps abstract flags (`--body` → `--description` for GitLab) to concrete ones
2. Update prose: "GitHub PR" → "PR / MR" (forge-agnostic).
3. Update example URL in `pr-review` usage hint to show both formats:
   - `https://github.com/org/repo/pull/42`
   - `https://gitlab.com/org/repo/-/merge_requests/42`
4. Update report templates to use forge-active reference syntax.
5. Update gitleaks tooling-setup snippet in `pr-create` to show both GitHub Actions and
   GitLab CI flavours (or just link to a forge-agnostic snippet).

### Step 6 — Agent changes

`plugins/spwf-agents/agents/pr-creator.md` and `reviewer.md`: same dispatch pattern as
the skills they wrap. Keep the names (these are user-discoverable in `/agents`); update
the descriptions to say "PR / MR" instead of "PR".

### Step 7 — Documentation

- Root `README.md`:
  - Rename Prerequisite #3 from "GitHub CLI" to "Forge CLI (`glab` for GitLab default;
    `gh` for GitHub)".
  - Update PR Create / PR Review rows to show both CLIs.
- `plugins/spwf/README.md`:
  - Add "Forge integration" section similar to the new "Issue tracker integration"
    section.
- `todo/optimal-agentic-env.md`: update Gap 6 / connect-apps note — GitLab is now
  first-class, not a sometime-future thing.

### Step 8 — Skill name decision

Keep `pr-create` and `pr-review` skill names as-is (forge-agnostic internally; users
keep their muscle memory). Reports and prose use the active forge's vocabulary.

---

## GitLab CLI — practical notes

- **`glab`** is GitLab's official CLI: <https://gitlab.com/gitlab-org/cli>. Maintained
  by GitLab the company, mature feature set, semantically aligned with `gh`.
- **Auth** via `glab auth login`. Token has the same scopes story as a GitHub PAT:
  `api`, `read_repository`, `write_repository`.
- **Self-hosted** is common — set `GLAB_HOST=gitlab.example.com` (env var) or run
  `glab auth login --hostname gitlab.example.com`. Multiple hosts are supported with
  separate auth contexts.
- **Flag differences from `gh`**:
  - `gh pr create --body "…"` ↔ `glab mr create --description "…"`
  - `gh pr view --json title,body,…` ↔ `glab mr view --output json` (returns full JSON
    structure; field names follow GitLab API conventions: `title`, `description`,
    `target_branch` (vs `baseRefName`), `source_branch` (vs `headRefName`),
    `additions`/`deletions` aren't always present without `--with-lfs` or similar)
  - `gh pr diff` ↔ `glab mr diff`
- **Reference syntax** in CLI: `glab mr view 42` works the same as `gh pr view 42`.
  URLs also work in both.

### Field name mapping (for JSON-driven review reports)

| Concept | `gh pr view --json` | `glab mr view --output json` |
|---|---|---|
| ID | `number` | `iid` |
| Title | `title` | `title` |
| Body | `body` | `description` |
| Base branch | `baseRefName` | `target_branch` |
| Head branch | `headRefName` | `source_branch` |
| State | `state` | `state` |
| Author | `author.login` | `author.username` |
| Files changed | `changedFiles` | `changes_count` |
| Additions | `additions` | (compute from diff) |
| Deletions | `deletions` | (compute from diff) |

The `pr-review` skill normalises both shapes into a uniform internal representation
before generating the report.

---

## GitHub MCP / GitLab MCP — explicit non-decision

Both Anthropic-published and community MCP servers exist for GitHub; community ones
exist for GitLab. They're useful for richer integration (issue management, CI run
status, releases) but **not in scope here**. The only goal is to free `pr-create` and
`pr-review` from a single-forge assumption. CLIs are the right tool for that. MCP
servers are addressable later as additional capabilities (e.g. a future `ci-status`
skill).

---

## Migration plan (phased)

**Phase 1 — schema-only, no behaviour change** (1 commit, low risk)
- Add `.spwf/forge.yaml` schema documentation (optional file)
- Add `forge-dispatch.md` reference covering detection and dispatch
- No skill changes; existing GitHub flows still work
- Bump plugin patch version

**Phase 2 — GitLab as alternative** (1 commit, additive only)
- Update `pr-create` and `pr-review` skills to dispatch via detection
- Update `pr-creator` and `reviewer` agents to match
- GitHub remains the default when detection lands on `github.com`
- Update root README Prerequisite #3
- Bump plugin minor version

**Phase 3 — flip the default for messaging** (1 commit)
- Reword examples in skills and READMEs to lead with GitLab/`glab`
- GitHub retained as a supported branch
- No behavioural change — auto-detection still gives users the right CLI per repo
- Bump plugin minor version

**Phase 4 — Bitbucket / Gitea / Forgejo (later, on demand)**
- Add a row to the dispatch table per new forge
- Add detection rule
- Document any CLI flag quirks
- No skill body changes if Phase 2's abstraction held

---

## Open questions

- **Does `glab` support all the JSON fields `pr-review` reads in one call, or do we
  need multiple calls?** Action: spike against a real GitLab repo, capture the JSON
  shape, write it into `forge-dispatch.md`. Worst case the review skill makes one
  extra call to `glab mr changes` for the diff stats.
- **Self-hosted GitLab detection — string-match `gitlab.` in the host, or be smarter?**
  String-match works for >95% of self-hosted GitLab installs (companies usually use
  `gitlab.{company}.com`). Edge cases (custom domain like `code.example.com`) need
  explicit `.spwf/forge.yaml`. **Recommendation:** start with string-match, ask once
  and persist on first ambiguous case.
- **Do we ship a migration helper for existing projects?** No — auto-detection makes
  most projects work without any config; the few that need overrides can write four
  lines of YAML.
- **Should the gitleaks setup snippet in `pr-create` show both GitHub Actions and
  GitLab CI flavours?** Yes, but compactly — link out to a longer reference rather
  than expand the inline output.
- **Do we keep "GitHub CLI" terminology anywhere as a literal?** Only in installation
  instructions for the `gh` branch and in upstream attribution URLs. All workflow
  prose says "forge CLI" or "PR / MR".
- **Skill rename to `request-create` / `request-review`?** No — too disruptive; the
  benefit doesn't justify breaking command memory.
- **Self-hosted GitLab token scoping for `pr-review`** — read-only token is enough
  (`read_api`, `read_repository`). `pr-create` needs `api` scope to create the MR.
  Document in setup notes.

## Rough scope

In scope:
- Two skill rewrites (`pr-create`, `pr-review`) to use forge dispatch
- Two agent updates (`pr-creator`, `reviewer`)
- New shared reference document for forge dispatch
- New optional `.spwf/forge.yaml` config schema
- Auto-detection from `git remote get-url origin`
- Root README + `plugins/spwf/README.md` updates
- Minor prose update in `changelog` skill (forge-aware issue-link conversion)
- Minor prose update in `pr-create` skill (gitleaks setup snippet covers both forges)

Out of scope (deferred):
- Bitbucket, Gitea, Forgejo (Phase 4, on demand)
- Forge MCP server integration
- Migration script
- Renaming skills
- Touching upstream attribution URLs
- Touching `.github/copilot-instructions.md` symlink (Copilot product convention,
  forge-independent)
- `migrate-to-spwf.sh` (one-shot helper, vestigial reference)
- OpenSpec archive directory
