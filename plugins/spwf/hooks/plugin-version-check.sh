#!/usr/bin/env bash
# PostToolUse (Write|Edit) — warn when plugin.json is edited without bumping the version
input=$(cat)

if command -v jq &>/dev/null; then
    file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
    file_path=$(printf '%s' "$input" | python3 -c \
        "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
fi

[[ "$file_path" == *"plugin.json" ]] || exit 0

tmp=$(mktemp)
git show "HEAD:$file_path" > "$tmp" 2>/dev/null || { rm -f "$tmp"; exit 0; }

if command -v jq &>/dev/null; then
    old_ver=$(jq -r '.version // empty' "$tmp" 2>/dev/null)
    new_ver=$(jq -r '.version // empty' "$file_path" 2>/dev/null)
else
    old_ver=$(python3 -c "import json; print(json.load(open('$tmp')).get('version',''))" 2>/dev/null)
    new_ver=$(python3 -c "import json; print(json.load(open('$file_path')).get('version',''))" 2>/dev/null)
fi
rm -f "$tmp"

if [[ -n "$old_ver" && "$old_ver" == "$new_ver" ]]; then
    printf '\n⚠  plugin.json edited but version unchanged (%s).\n' "$new_ver" >&2
    printf '   Bump the version before pushing — downstream /plugin update only fires on a version increment.\n\n' >&2
fi
exit 0
