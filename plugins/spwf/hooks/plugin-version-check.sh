#!/usr/bin/env bash
# PostToolUse (Write|Edit) — warn when plugin.json is edited without bumping the version
#
# Prerequisites: git (required), jq OR python3 (one must be present for JSON parsing)
input=$(cat)

# Require git
command -v git &>/dev/null || { printf '⚠  spwf hook: git not found — plugin-version-check skipped\n' >&2; exit 0; }

# Require jq or python3
if ! command -v jq &>/dev/null && ! command -v python3 &>/dev/null; then
    printf '⚠  spwf hook: jq and python3 both missing — plugin-version-check skipped\n' >&2
    exit 0
fi

# Extract file path from hook JSON
if command -v jq &>/dev/null; then
    file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
    file_path=$(printf '%s' "$input" | python3 -c \
        "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
fi

[[ "$file_path" == *"plugin.json" ]] || exit 0

# Convert absolute path to repo-relative (git show requires a repo-relative path)
git_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
rel_path="${file_path#"${git_root}"/}"

tmp=$(mktemp)
git show "HEAD:${rel_path}" > "$tmp" 2>/dev/null || { rm -f "$tmp"; exit 0; }

if command -v jq &>/dev/null; then
    old_ver=$(jq -r '.version // empty' "$tmp" 2>/dev/null)
    new_ver=$(jq -r '.version // empty' "$file_path" 2>/dev/null)
else
    # Pass paths as arguments to avoid shell-interpolation-in-Python-string bugs
    old_ver=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('version',''))" "$tmp" 2>/dev/null)
    new_ver=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('version',''))" "$file_path" 2>/dev/null)
fi
rm -f "$tmp"

if [[ -n "$old_ver" && "$old_ver" == "$new_ver" ]]; then
    printf '\n⚠  plugin.json edited but version unchanged (%s).\n' "$new_ver" >&2
    printf '   Bump the version before pushing — downstream /plugin update only fires on a version increment.\n\n' >&2
fi
exit 0
