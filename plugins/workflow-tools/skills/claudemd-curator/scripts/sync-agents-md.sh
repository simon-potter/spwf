#!/usr/bin/env bash
# sync-agents-md.sh
#
# Verify, create, or repair the AGENTS.md ↔ CLAUDE.md relationship at the repo
# root and (optionally) recursively for nested AGENTS.md files in a monorepo.
#
# Usage:
#   ./sync-agents-md.sh check                  # Report state, no changes
#   ./sync-agents-md.sh migrate [--mode=symlink|shim] [--recursive]
#   ./sync-agents-md.sh sister-tools           # Symlink Copilot/Cursor rules to AGENTS.md
#
# Exit codes:
#   0 = OK (nothing to do, or migration succeeded)
#   1 = drift / dual content detected (check mode)
#   2 = neither file exists
#   3 = invalid arguments
#
# Pattern (April 2026 best practice):
#   AGENTS.md is canonical. CLAUDE.md is either:
#     - a symlink to AGENTS.md (when no Claude-specific content is needed)
#     - a small shim file starting with "See @AGENTS.md" plus Claude-only additions
#       (skills, hooks, compact instructions, model effort hints)
#
# As of late April 2026, Claude Code does NOT officially read AGENTS.md natively
# (anthropics/claude-code#34235). The shim/symlink workaround is required.

set -euo pipefail

# ---------- Output helpers ----------

if [ -t 1 ]; then
  C_RESET='\033[0m'
  C_BOLD='\033[1m'
  C_GREEN='\033[32m'
  C_YELLOW='\033[33m'
  C_RED='\033[31m'
  C_BLUE='\033[34m'
  C_DIM='\033[2m'
else
  C_RESET='' C_BOLD='' C_GREEN='' C_YELLOW='' C_RED='' C_BLUE='' C_DIM=''
fi

ok()    { printf "${C_GREEN}✓${C_RESET} %s\n" "$1"; }
warn()  { printf "${C_YELLOW}!${C_RESET} %s\n" "$1"; }
err()   { printf "${C_RED}✗${C_RESET} %s\n" "$1" >&2; }
info()  { printf "${C_BLUE}ℹ${C_RESET} %s\n" "$1"; }
hdr()   { printf "\n${C_BOLD}%s${C_RESET}\n" "$1"; }

# ---------- State detection ----------

# Returns one of: OK_SYMLINK | OK_SHIM | DUAL | CLAUDE_ONLY | AGENTS_ONLY | NEITHER
detect_state() {
  local dir="$1"
  local claude="$dir/CLAUDE.md"
  local agents="$dir/AGENTS.md"

  local has_claude=0 has_agents=0 claude_is_link=0
  [ -e "$claude" ] && has_claude=1
  [ -e "$agents" ] && has_agents=1
  [ -L "$claude" ] && claude_is_link=1

  if [ $has_claude -eq 0 ] && [ $has_agents -eq 0 ]; then
    echo "NEITHER"; return
  fi
  if [ $has_claude -eq 0 ] && [ $has_agents -eq 1 ]; then
    echo "AGENTS_ONLY"; return
  fi
  if [ $has_claude -eq 1 ] && [ $has_agents -eq 0 ]; then
    echo "CLAUDE_ONLY"; return
  fi

  # Both exist
  if [ $claude_is_link -eq 1 ]; then
    local target
    target="$(readlink "$claude")"
    if [ "$target" = "AGENTS.md" ] || [ "$target" = "$agents" ]; then
      echo "OK_SYMLINK"; return
    else
      echo "DUAL"; return  # symlink points elsewhere — treat as drift
    fi
  fi

  # Both real files. Is CLAUDE.md a shim?
  # Heuristic: small (<25 lines) AND first non-blank line references AGENTS.md
  local lines first_line
  lines="$(wc -l < "$claude" | tr -d ' ')"
  first_line="$(grep -v '^[[:space:]]*$' "$claude" | head -1 || true)"
  if [ "$lines" -lt 25 ] && \
     printf '%s' "$first_line" | grep -qiE '(see|read).*@?AGENTS\.md'; then
    echo "OK_SHIM"; return
  fi

  echo "DUAL"
}

# Compute size delta + a quick word-overlap signal between two files
diff_summary() {
  local a="$1" b="$2"
  local a_lines b_lines
  a_lines="$(wc -l < "$a" | tr -d ' ')"
  b_lines="$(wc -l < "$b" | tr -d ' ')"
  printf "    AGENTS.md: %s lines  |  CLAUDE.md: %s lines\n" "$a_lines" "$b_lines"
  # Count distinct (changed) lines as a rough drift signal.
  # diff exits 1 when files differ, which would trip pipefail — disable it locally.
  local common
  common="$( set +o pipefail
             diff --unchanged-line-format='' --old-line-format='' --new-line-format='X' "$a" "$b" 2>/dev/null \
               | wc -c | tr -d ' '
           )"
  common="${common:-0}"
  printf "    Distinct lines (rough drift signal): ~%s\n" "$common"
}

# ---------- Subcommands ----------

cmd_check() {
  local recursive="${1:-no}"
  local exit_code=0
  local found_dual=0

  hdr "Checking AGENTS.md ↔ CLAUDE.md sync"

  # Find all directories containing AGENTS.md or CLAUDE.md
  local dirs
  if [ "$recursive" = "yes" ]; then
    dirs="$(
      { find . -name AGENTS.md -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null
        find . -name CLAUDE.md -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null
      } | xargs -n1 dirname 2>/dev/null | sort -u
    )"
  else
    dirs="."
  fi

  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    local state
    state="$(detect_state "$dir")"
    local label="$dir"
    [ "$dir" = "." ] && label="(repo root)"

    case "$state" in
      OK_SYMLINK)
        ok "$label — CLAUDE.md → AGENTS.md (symlink, no drift possible)"
        ;;
      OK_SHIM)
        ok "$label — CLAUDE.md is a shim referencing AGENTS.md"
        info "    Inspect the Claude-specific section for drift if it has grown."
        ;;
      DUAL)
        warn "$label — DUAL: both files exist as full content. Drift risk."
        diff_summary "$dir/AGENTS.md" "$dir/CLAUDE.md"
        found_dual=1
        ;;
      AGENTS_ONLY)
        warn "$label — AGENTS.md exists, no CLAUDE.md. Claude Code will not load it."
        info "    Run: $0 migrate --mode=symlink (or --mode=shim) to fix."
        ;;
      CLAUDE_ONLY)
        warn "$label — CLAUDE.md exists, no AGENTS.md. Other tools (Codex, Cursor) won't see your rules."
        info "    Run: $0 migrate to make AGENTS.md canonical."
        ;;
      NEITHER)
        [ "$dir" = "." ] && info "$label — no agent instruction files yet."
        ;;
    esac
  done <<< "$dirs"

  [ $found_dual -eq 1 ] && exit_code=1
  return $exit_code
}

cmd_migrate() {
  local mode="symlink"
  local recursive="no"
  while [ $# -gt 0 ]; do
    case "$1" in
      --mode=symlink) mode="symlink" ;;
      --mode=shim)    mode="shim" ;;
      --recursive)    recursive="yes" ;;
      *) err "Unknown migrate flag: $1"; exit 3 ;;
    esac
    shift
  done

  hdr "Migrating to AGENTS.md-canonical (mode: $mode)"

  local dirs
  if [ "$recursive" = "yes" ]; then
    dirs="$(
      { find . -name AGENTS.md -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null
        find . -name CLAUDE.md -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null
      } | xargs -n1 dirname 2>/dev/null | sort -u
    )"
  else
    dirs="."
  fi

  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    local state
    state="$(detect_state "$dir")"
    local label="$dir"
    [ "$dir" = "." ] && label="(repo root)"

    case "$state" in
      OK_SYMLINK|OK_SHIM)
        ok "$label — already canonical, skipping"
        ;;
      CLAUDE_ONLY)
        info "$label — promoting CLAUDE.md to AGENTS.md"
        mv "$dir/CLAUDE.md" "$dir/AGENTS.md"
        create_claude_pointer "$dir" "$mode"
        ;;
      AGENTS_ONLY)
        info "$label — creating CLAUDE.md ($mode) pointing at AGENTS.md"
        create_claude_pointer "$dir" "$mode"
        ;;
      DUAL)
        warn "$label — DUAL: not auto-merging (would lose content). Manual action required:"
        info "    1. Diff $dir/CLAUDE.md against $dir/AGENTS.md"
        info "    2. Merge the union into AGENTS.md (tool-agnostic content)"
        info "    3. Either delete CLAUDE.md (then re-run this command), or"
        info "       trim CLAUDE.md to a shim with Claude-only content only"
        ;;
      NEITHER)
        : # nothing to do
        ;;
    esac
  done <<< "$dirs"
}

create_claude_pointer() {
  local dir="$1" mode="$2"
  local claude="$dir/CLAUDE.md"

  # Remove any existing CLAUDE.md (including stale symlink)
  [ -e "$claude" ] || [ -L "$claude" ] && rm -f "$claude"

  case "$mode" in
    symlink)
      ( cd "$dir" && ln -s "AGENTS.md" "CLAUDE.md" )
      ok "  Created symlink: $claude → AGENTS.md"
      ;;
    shim)
      cat > "$claude" <<'EOF'
See @AGENTS.md for the canonical agent instructions for this repository.

# Claude Code-specific notes

<!--
This shim file holds Claude Code-only content. AGENTS.md is the source of truth
for everything tool-agnostic (commands, architecture, conventions, boundaries).

Add ONLY content here that:
  - Depends on Claude Code as the runtime (skills, hooks, plugins)
  - Is operational tuning (compact instructions, model/effort hints, subagent routing)
  - Would not make sense to a Codex/Cursor/Copilot user

Anything else belongs in AGENTS.md.
-->
EOF
      ok "  Created shim: $claude"
      info "  Edit it to add Claude-specific content (skills, hooks, compact instructions, etc.)"
      ;;
  esac
}

cmd_sister_tools() {
  hdr "Symlinking sister-tool rule files to AGENTS.md"

  if [ ! -f AGENTS.md ]; then
    err "AGENTS.md does not exist at repo root. Run '$0 migrate' first."
    exit 2
  fi

  # GitHub Copilot
  mkdir -p .github
  ln -sfn ../AGENTS.md .github/copilot-instructions.md
  ok ".github/copilot-instructions.md → ../AGENTS.md"

  # Cursor
  mkdir -p .cursor/rules
  ln -sfn ../../AGENTS.md .cursor/rules/main.mdc
  ok ".cursor/rules/main.mdc → ../../AGENTS.md"

  # Gemini CLI
  ln -sfn AGENTS.md GEMINI.md
  ok "GEMINI.md → AGENTS.md"

  # Windsurf
  ln -sfn AGENTS.md .windsurfrules
  ok ".windsurfrules → AGENTS.md"

  echo
  info "On Windows, ensure git core.symlinks=true so symlinks survive checkout:"
  info "    git config core.symlinks true"
}

# ---------- Main ----------

usage() {
  cat <<EOF
Usage: $0 <command> [options]

Commands:
  check [--recursive]                Report sync state. Exit 1 if DUAL detected.
  migrate [--mode=symlink|shim]      Migrate to AGENTS.md-canonical pattern.
          [--recursive]              (default mode: symlink)
  sister-tools                       Symlink Copilot/Cursor/Gemini/Windsurf rules to AGENTS.md.
  help                               Show this help.

Examples:
  $0 check
  $0 check --recursive
  $0 migrate --mode=shim
  $0 migrate --recursive --mode=symlink
  $0 sister-tools
EOF
}

[ $# -eq 0 ] && { usage; exit 3; }

case "${1:-}" in
  check)
    shift
    if [ "${1:-}" = "--recursive" ]; then
      cmd_check yes
    else
      cmd_check no
    fi
    ;;
  migrate)
    shift
    cmd_migrate "$@"
    ;;
  sister-tools)
    cmd_sister_tools
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    err "Unknown command: $1"
    usage
    exit 3
    ;;
esac
