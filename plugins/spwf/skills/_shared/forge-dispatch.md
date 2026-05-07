# Forge dispatch — shared reference

Single source of truth for how forge-touching skills (`pr-create`, `pr-review`, the
`changelog` issue-link converter) and the `pr-creator` / `reviewer` agents talk to
code-hosting platforms (GitHub, GitLab, etc.). Skills reference this document; they
do not repeat the dispatch table inline.

GitLab is the default. GitHub is supported. Bitbucket, Gitea, Forgejo, and others
slot in by adding a row — no skill rewrites required.

---

## Operating principle: fail fast

Skills do not paper over a missing forge CLI. They detect the active forge from the
git remote (or `.spwf/forge.yaml` override), pick the right CLI, and call it
directly.

| Situation | Skill behaviour |
|---|---|
| Forge action requested (e.g. `/spwf:pr-create`, `/spwf:pr-review 42`) and the matching CLI is installed and authenticated | Run it. |
| Same situation, but the CLI is missing or unauthenticated | **Fail fast** with a clear, actionable message. Do not silently fall back. |
| `forge: none` set in `.spwf/forge.yaml` | Refuse to run forge-touching skills with a clear "forge integration disabled for this repo" message. |
| `git remote` is missing entirely | Halt with: "No git remote configured — cannot determine forge." |

The mental model: configuring the forge CLI is the user's responsibility. Detecting
which CLI to use is the skill's responsibility.

---

## Configuration

`.spwf/forge.yaml` is **optional and minimal**. It exists only for self-hosted
GitLab on a non-`gitlab.*` domain, ambiguous remotes, or to opt out via
`forge: none`.

```yaml
# .spwf/forge.yaml — all fields optional
forge: gitlab              # github | gitlab | bitbucket | gitea | none
host: gitlab.example.com   # self-hosted host (auto-derived from git remote when possible)
default_base: main         # base branch for PR/MR creation (usually auto-detected from `git branch --show-current` against origin/HEAD)
```

Resolution order:

1. If the file exists and has the field, use it.
2. Else, detect from `git remote get-url origin` (rules below).
3. If detection is ambiguous, the skill asks once on first need and offers to save
   the answer to `.spwf/forge.yaml`.
4. If `forge: none` is set, all forge-touching skills refuse to run with a clear
   message.

**Auth tokens never live in this file.** They live in `gh auth login` /
`glab auth login` per-host. The repo carries no secrets and no per-host routing
beyond the optional `host:` field for self-hosted GitLab.

---

## Forge detection (default case)

When `.spwf/forge.yaml` is absent or `forge:` is unset, skills detect from
`git remote get-url origin`:

| Host pattern | Detected forge | CLI |
|---|---|---|
| `github.com` | GitHub | `gh` |
| `gitlab.com` | GitLab (cloud) | `glab` |
| `gitlab.*` (any subdomain or company-prefixed host) | GitLab (self-hosted) | `glab` with `GLAB_HOST` set |
| `bitbucket.org` | Bitbucket (future) | n/a yet |
| Other / no match | Ambiguous — ask once and persist | — |

Self-hosted GitLab on a custom domain that doesn't contain `gitlab` (e.g.
`code.example.com`) needs an explicit `.spwf/forge.yaml` entry. The skill offers to
write the file on first use after the user confirms.

---

## Operation contract

Every forge-touching skill needs at most three logical operations.

| Operation | What it returns | Used by |
|---|---|---|
| `view_request(ref)` | id, title, body, base, head, state, author, file/line counts | `pr-review` |
| `diff_request(ref)` | unified diff for the request | `pr-review` |
| `create_request(title, body, base?)` | URL of the new request | `pr-create` |

`{ref}` is either a number (`42`) or a full URL — both CLIs accept both.

GitHub calls these "Pull Requests"; GitLab calls them "Merge Requests". The
abstraction uses **request** to avoid favouring either vocabulary internally.
User-facing reports use the active forge's term (`PR #42` on GitHub, `MR !42` on
GitLab).

---

## Dispatch table

| Op | GitHub (`gh`) | GitLab (`glab`) |
|---|---|---|
| `view_request(ref)` | `gh pr view {ref} --json number,title,body,baseRefName,headRefName,state,author,additions,deletions,changedFiles` | `glab mr view {ref} --output json` (returns `iid`, `title`, `description`, `target_branch`, `source_branch`, `state`, `author.username`, `changes_count`) |
| `diff_request(ref)` | `gh pr diff {ref}` | `glab mr diff {ref}` |
| `create_request(title, body, base)` | `gh pr create --title "{title}" --body "{body}" [--base {base}]` | `glab mr create --title "{title}" --description "{body}" [--target-branch {base}]` |

Self-hosted GitLab: prepend `GLAB_HOST={host}` to every `glab` invocation, or run
`glab auth login --hostname {host}` once so the host is persisted in
`~/.config/glab-cli/config.yml`.

---

## JSON field normalisation

`pr-review` consumes the `view_request` output and produces a uniform internal
representation. The mapping:

| Internal field | GitHub (`gh pr view --json`) | GitLab (`glab mr view --output json`) |
|---|---|---|
| `id` | `number` | `iid` |
| `title` | `title` | `title` |
| `body` | `body` | `description` |
| `base` | `baseRefName` | `target_branch` |
| `head` | `headRefName` | `source_branch` |
| `state` | `state` | `state` (uppercase: `OPENED`/`CLOSED`/`MERGED`) |
| `author` | `author.login` | `author.username` |
| `files_changed` | `changedFiles` | `changes_count` |
| `additions` | `additions` | derived from `glab mr changes` (separate call) |
| `deletions` | `deletions` | derived from `glab mr changes` (separate call) |

For GitLab, additions/deletions stats may require an additional
`glab mr changes {ref}` call — the skill does this only when the report needs them
and only when the first call succeeded.

---

## Reference syntax

User-facing strings adapt to the active forge:

| Concept | GitHub | GitLab |
|---|---|---|
| Reference | `#42` | `!42` |
| URL path | `https://github.com/{org}/{repo}/pull/42` | `https://gitlab.com/{org}/{repo}/-/merge_requests/42` |
| Self-hosted URL | n/a (GH cloud only) | `https://{host}/{org}/{repo}/-/merge_requests/42` |

Reports use the active forge's syntax. Skill source code does not hard-code either —
the `id` field comes from the dispatch and the `#` / `!` prefix comes from the
forge type.

---

## CLI installation and auth

### `glab` (GitLab — default)

```bash
brew install glab                  # macOS
# or download from https://gitlab.com/gitlab-org/cli/-/releases
glab auth login                    # gitlab.com
glab auth login --hostname {host}  # self-hosted
```

Token scopes: `api`, `read_repository`, `write_repository`. Read-only review
workflows can use `read_api` + `read_repository`.

### `gh` (GitHub)

```bash
brew install gh                    # macOS
# or https://cli.github.com
gh auth login
```

Token scopes: `repo` covers PR view/create. For org-level workflows you may also
need `read:org`.

### Verifying auth

The dispatch helper checks auth with `{cli} auth status` before any forge action.
If unauthenticated, halt with the appropriate `{cli} auth login` instruction.

---

## Adding a new forge

To add Bitbucket, Gitea, Forgejo, or any other forge later:

1. Add a row to the **Detection** table mapping its host pattern to a forge name and
   CLI.
2. Add a column to the **Dispatch table** with the CLI's create/view/diff
   invocations and flag mappings.
3. Add a column to the **JSON field normalisation** table.
4. Note any reference-syntax quirks in the **Reference syntax** table.
5. Add an entry under **CLI installation and auth**.
6. No skill body changes required.
