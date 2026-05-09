#!/usr/bin/env bash
# PreToolUse — nudge to use /spwf:tracker-comment when a tracker write looks
# like it has heavy technical content (likely unsuitable for a non-technical
# reader). Advisory only — never blocks the call.
#
# Fires on: mcp__youtrack__* (glob), mcp__atlassian__jira_create_issue,
# mcp__atlassian__jira_update_issue, mcp__atlassian__jira_add_comment
#
# AND-logic thresholds (deliberately conservative — fewer false positives is
# better than crying wolf):
#   (code_blocks >= 2) AND (length > 600)
#   OR (code_blocks >= 1) AND (file_refs >= 5)
#
# Prerequisites: jq OR python3 (one must be present), grep (universal)
input=$(cat)

if ! command -v jq &>/dev/null && ! command -v python3 &>/dev/null; then
    printf '⚠  spwf hook: jq and python3 both missing — tracker-comment-nudge skipped\n' >&2
    exit 0
fi

# Extract tool_name and the body field (one of body|description|text|comment)
if command -v jq &>/dev/null; then
    tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
    body=$(printf '%s' "$input" | jq -r '
        .tool_input.body
        // .tool_input.description
        // .tool_input.text
        // .tool_input.comment
        // empty')
else
    tool_name=$(printf '%s' "$input" | python3 -c \
        "import json,sys; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null)
    body=$(printf '%s' "$input" | python3 -c \
        "import json,sys; d=json.load(sys.stdin).get('tool_input',{}); print(d.get('body') or d.get('description') or d.get('text') or d.get('comment') or '')" 2>/dev/null)
fi

# Short-circuit on read-shape YouTrack tools (we only care about writes)
case "$tool_name" in
    *get_issue*|*search_issues*|*list_issues*|*find_issues*|*read_issue*)
        exit 0
        ;;
esac

# No body field? Not a comment-shape call. Exit silently.
[[ -z "$body" ]] && exit 0

# Count signals
code_blocks=$(printf '%s' "$body" | grep -cE '^```' || true)
# Each ``` is one fence; pairs are blocks. Round down — partial fences likely indicate inline code
code_blocks=$(( code_blocks / 2 ))

file_refs=$(printf '%s' "$body" | grep -ohE '[A-Za-z0-9_./-]+\.(py|js|ts|tsx|jsx|md|sh|rb|go|rs|java|kt|swift|c|cpp|h|hpp|cs|php|html|css|scss|yml|yaml|json|toml|sql|tf)\b' | wc -l)
file_refs=$(printf '%d' "${file_refs:-0}")

length=${#body}

# AND-logic thresholds
trigger=0
reason=""

if (( code_blocks >= 2 )) && (( length > 600 )); then
    trigger=1
    reason="multi-block, long"
elif (( code_blocks >= 1 )) && (( file_refs >= 5 )); then
    trigger=1
    reason="code + heavy file referencing"
fi

if (( trigger == 0 )); then
    exit 0
fi

# Emit advisory (stderr, ⚠ prefix, exit 0 — purely advisory)
printf '\n⚠  spwf: tracker write detected with heavy technical content (%s)\n' "$reason" >&2
printf '   %d code block(s), %d file ref(s), %d chars.\n' "$code_blocks" "$file_refs" "$length" >&2
printf '   If this is for a non-technical reader (e.g. a PM), consider running\n' >&2
printf '   /spwf:tracker-comment first — it audience-checks and rewrites.\n' >&2
printf '   This is non-blocking; the tool call will proceed.\n\n' >&2

exit 0
