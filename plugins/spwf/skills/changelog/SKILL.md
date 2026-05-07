---
name: changelog
description: Generates a human-readable changelog section from conventional commits. Determines the commit range automatically (since last tag, or between two tags), classifies commits into Breaking Changes / Added / Fixed / Security / Performance / Changed, and writes or proposes a new section in CHANGELOG.md following the Keep a Changelog format. Use before cutting a release, or call from the retrospective orchestrator as Part 5. Skips non-user-facing types (docs, test, chore, build, ci, refactor) by default.
disable-model-invocation: true
allowed-tools: [Read, Bash, Glob, Grep, Edit, Write]
---

# changelog

Generate a human-readable changelog section from conventional commits and write it to `CHANGELOG.md`.

## Usage

```
/spwf:changelog [ref]
```

- No argument — range is from the last git tag to HEAD (or last 30 commits if no tags exist)
- `v1.2.0` — range from that tag to HEAD
- `v1.1.0..v1.2.0` — explicit range between two tags
- `--all` — include internal commit types (docs, test, chore, refactor, build, ci)

## Step 1 — Determine commit range

```bash
# Last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

# All tags (for context)
git tag --sort=-version:refname 2>/dev/null | head -10

# Commits since last tag (or last 30 if no tags)
if [ -n "$LAST_TAG" ]; then
    git log "${LAST_TAG}..HEAD" --oneline
else
    git log --oneline -30
fi
```

If an explicit ref was passed as `$ARGUMENTS`, use that instead. Announce the detected range before proceeding:

```
Range: v1.1.0..HEAD (47 commits)
```

If the range yields zero commits, report that and stop.

## Step 2 — Collect raw commits

```bash
# Full conventional commit log with hash, date, author
git log "${RANGE}" \
    --format="%H%x09%as%x09%an%x09%s%x09%b" \
    --no-merges
```

Flags used:
- `--no-merges` — skip merge commits (they duplicate content from the commits they merged)
- `%H` — full hash (for linking)
- `%as` — author date (short YYYY-MM-DD)
- `%an` — author name
- `%s` — subject line (the conventional commit line)
- `%b` — body (checked for `BREAKING CHANGE:` footer)

Also capture any commits with `BREAKING CHANGE` in the body:
```bash
git log "${RANGE}" --no-merges --grep="BREAKING CHANGE" --format="%H%x09%s%x09%b"
```

## Step 3 — Parse and classify commits

### Conventional commit format

```
<type>[optional scope]: <description>  [optional #issue]

[optional body]

[optional footer: BREAKING CHANGE: <detail>]
```

Breaking change markers: `!` suffix on type (`feat!:`, `fix!:`) OR `BREAKING CHANGE:` in the footer.

### Type → changelog section mapping

| Commit type | Changelog section | Include by default |
|---|---|---|
| `feat` | Added | Yes |
| `fix` | Fixed | Yes |
| `security` | Security | Yes |
| `perf` | Performance | Yes |
| `BREAKING CHANGE` / `!` | Breaking Changes | Yes — always first |
| `refactor` | Changed | Only with `--all` |
| `docs` | — | Skipped |
| `test` | — | Skipped |
| `chore` | — | Skipped |
| `build` | — | Skipped |
| `ci` | — | Skipped |

### Parsing rules

1. Extract `type`, optional `scope`, and `description` from the subject using the pattern: `^(\w+)(\(\w[\w/-]*\))?(!)?:\s+(.+)$`
2. If the subject does not match the pattern (non-conventional commit), put it in a **Non-conventional** bucket for review — do not discard.
3. Scope (if present) appears in the changelog as bold prefix: `feat(auth):` → **auth**: description
4. Strip trailing issue references (`(#123)`, `fixes #456`, `(!42)`, `closes !42`) from the description for the main line; convert to a link if a forge remote is detectable per `_shared/forge-dispatch.md` (GitHub: `#N` → `/issues/N`; GitLab: `!N` → `/-/merge_requests/N`, `#N` → `/-/issues/N`).
5. Detect breaking changes in two ways:
   - `!` in the type: `feat!:` or `fix!:`
   - `BREAKING CHANGE:` line in the commit body

### Deduplication

If two or more commits describe the same logical change (common when a branch was not squash-merged), surface both hashes but suggest collapsing to a single entry. Do not silently deduplicate — the user should decide.

## Step 4 — Detect version and date

```bash
# Proposed version
NEXT_VERSION="${ARGUMENTS:-Unreleased}"

# Today's date
RELEASE_DATE=$(date -u +%Y-%m-%d)
```

If no version argument was given, use `[Unreleased]`. If the user passed a version like `v1.2.0`, use that as the heading.

Check for an existing `CHANGELOG.md`:
```bash
[ -f CHANGELOG.md ] && head -20 CHANGELOG.md || echo "CHANGELOG.md not found — will create"
```

## Step 5 — Format the changelog section

Use Keep a Changelog format (keepachangelog.com):

```markdown
## [1.2.0] — 2026-05-05

### Breaking Changes

- **auth**: JWT tokens now expire after 1 hour — update clients to handle 401 and refresh (#123)

### Added

- **dashboard**: Multi-language support for all labels (#145)
- Export to CSV from the reports page (#138)

### Fixed

- Pagination resets to page 1 when a filter changes (#142)
- Memory leak in WebSocket reconnection loop (#139)

### Security

- Upgraded axios to 1.7.4 (CVE-2021-3749) (#147)

### Performance

- Avatar images now served from CDN with 30-day cache headers (#136)
```

### Formatting rules

- Each entry is a single line. No sub-bullets, no paragraphs.
- Scope (if present) in bold at the start: `- **scope**: description`
- Breaking changes section always comes first, even if empty entries exist in other sections.
- If a section has no entries, omit the section heading entirely.
- Do not include the type prefix (`feat:`, `fix:`) in the entry text — the section heading carries that meaning.
- Write descriptions in past tense from the user's perspective: "Added X", not "Add X" and not "This commit adds X".
- Non-conventional commits go in a `### Other` section at the end for the user to review and reclassify manually.

### CHANGELOG.md structure (when creating from scratch)

```markdown
# Changelog

All notable changes to this project will be documented in this file.

This project follows [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] — 2026-05-05
...
```

When the file already exists, prepend the new section immediately after the `## [Unreleased]` heading (or after the `# Changelog` header if no Unreleased section exists). Do not overwrite previous sections.

## Step 6 — Propose, then write

Present the draft changelog section to the user before writing:

```
## Draft changelog — v1.2.0 (47 commits, 2026-04-01..HEAD)

[full formatted section here]

---
Non-conventional commits requiring manual review (N):
- abc1234: "wip stuff" — classify or skip?
- def5678: "Merge pull request #133 from feature/auth" — already captured via constituent commits

---
Write to CHANGELOG.md? (yes to apply, or give feedback)
```

Wait for explicit approval. On approval, prepend the section to `CHANGELOG.md` (creating the file if it doesn't exist). On feedback, revise and re-present.

## Output (after writing)

```
## Changelog updated

**File**: CHANGELOG.md
**Section**: v1.2.0 — 2026-05-05
**Commits processed**: 47
**Entries written**: 12 (Breaking: 1, Added: 5, Fixed: 4, Security: 1, Performance: 1)
**Skipped**: 31 (docs: 8, test: 6, chore: 12, non-conventional: 5)
**Manual review needed**: 2 non-conventional commits listed above

Next step: tag the release
  git tag -a v1.2.0 -m "Release v1.2.0"
  git push origin v1.2.0
```

## Gotchas

- **Non-squash merges produce multiple commits per feature.** If the team merges feature branches without squashing, the changelog will have many fine-grained commits. Surface this and suggest the user collapse related entries before writing. Do not auto-collapse — you cannot know what belongs together.
- **`git describe --tags` fails if no tags exist.** The fallback is the last 30 commits. Tell the user explicitly: "No tags found — showing last 30 commits. Tag your first release after this to anchor future changelogs."
- **Conventional commits are not enforced on most projects.** Any commit not matching the pattern goes to Non-conventional. If more than 30% of commits are non-conventional, tell the user — the changelog will be incomplete without better commit hygiene or a commit lint hook.
- **`[Unreleased]` section.** Some projects keep a running `[Unreleased]` section in CHANGELOG.md. If one exists, insert new entries into it rather than creating a new versioned heading. Only create a versioned heading when a version argument is explicitly passed.
- **Scope is optional and freeform.** `feat(auth/jwt):` is valid. Preserve the full scope string in bold, do not truncate.
- **Breaking change description must be user-actionable.** The `BREAKING CHANGE:` footer body (not the subject) often contains the migration detail. Use that body text in the changelog entry, not just the subject line.
- **`--no-merges` hides squash-merge commits on some workflows.** If the repo uses squash merges to main, merge commits ARE the only commits. In that case, drop `--no-merges` and filter manually by checking if the subject matches a conventional pattern.
- **Date to use.** Use the commit author date (`%as`), not today's date, for each entry. Use today's date only for the section heading (the release date).
