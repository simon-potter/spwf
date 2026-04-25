#!/usr/bin/env bash
# mine-conversations.sh
#
# Extract recent Claude Code session transcripts for the current project from
# ~/.claude/projects/ into a temp directory for behavioural-audit analysis.
#
# Usage:
#   ./mine-conversations.sh                  # 15 most recent, default project (cwd)
#   ./mine-conversations.sh -n 30            # 30 most recent
#   ./mine-conversations.sh -p /path/to/proj # explicit project path
#   ./mine-conversations.sh -e <session-id>  # exclude a specific session (e.g., the current one)
#
# Output:
#   Prints the temp directory path on stdout.
#   Each transcript is written as <session-id>.txt with USER:/ASSISTANT: prefixes.
#   Sorted by ls -lhS so the largest (most substantive) appear first.
#
# Source: adapted from ykdojo/claude-code-tips review-claudemd skill.

set -euo pipefail

N=15
PROJECT_PATH="$(pwd)"
EXCLUDE_SESSION=""

while getopts "n:p:e:h" opt; do
  case $opt in
    n) N="$OPTARG" ;;
    p) PROJECT_PATH="$OPTARG" ;;
    e) EXCLUDE_SESSION="$OPTARG" ;;
    h)
      sed -n '2,18p' "$0"
      exit 0
      ;;
    *) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Convert project path to ~/.claude/projects/ folder name (slashes → dashes, leading dash stripped from absolute path)
FOLDER_NAME="$(echo "$PROJECT_PATH" | sed 's|/|-|g' | sed 's|^-||')"
CONVO_DIR="$HOME/.claude/projects/-$FOLDER_NAME"

if [ ! -d "$CONVO_DIR" ]; then
  echo "ERROR: No conversation directory found at $CONVO_DIR" >&2
  echo "Expected for project path: $PROJECT_PATH" >&2
  echo "" >&2
  echo "Available project folders:" >&2
  ls "$HOME/.claude/projects/" 2>/dev/null | head -10 >&2 || echo "  (none)" >&2
  exit 1
fi

# jq is required for reliable JSONL parsing
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required but not installed." >&2
  echo "Install with: brew install jq  (or apt-get install jq)" >&2
  exit 1
fi

SCRATCH="/tmp/claudemd-review-$(date +%s)"
mkdir -p "$SCRATCH"

EXTRACTED=0
for f in $(ls -t "$CONVO_DIR"/*.jsonl 2>/dev/null | head -"$N"); do
  basename=$(basename "$f" .jsonl)

  # Skip the excluded session (typically the current one)
  if [ -n "$EXCLUDE_SESSION" ] && [ "$basename" = "$EXCLUDE_SESSION" ]; then
    continue
  fi

  # Parse JSONL: extract user prompts and assistant text content, skip empty assistant turns
  jq -r '
    if .type == "user" then
      "USER: " + (
        if (.message.content | type) == "string" then
          .message.content
        elif (.message.content | type) == "array" then
          (.message.content | map(select(.type == "text") | .text) | join("\n"))
        else
          ""
        end
      )
    elif .type == "assistant" then
      "ASSISTANT: " + (
        (.message.content // []) | map(select(.type == "text") | .text) | join("\n")
      )
    else
      empty
    end
  ' "$f" 2>/dev/null \
    | grep -v "^ASSISTANT: $" \
    | grep -v "^USER: $" \
    > "$SCRATCH/${basename}.txt"

  # Drop the file if extraction produced nothing useful
  if [ ! -s "$SCRATCH/${basename}.txt" ]; then
    rm -f "$SCRATCH/${basename}.txt"
  else
    EXTRACTED=$((EXTRACTED + 1))
  fi
done

if [ "$EXTRACTED" -eq 0 ]; then
  echo "ERROR: No transcripts could be extracted from $CONVO_DIR" >&2
  rmdir "$SCRATCH" 2>/dev/null || true
  exit 1
fi

# Print listing sorted by size (largest = most substantive first), then the path
echo "# Extracted $EXTRACTED transcripts to $SCRATCH" >&2
echo "" >&2
echo "# Sorted by size (largest first):" >&2
ls -lhS "$SCRATCH" >&2
echo "" >&2

# stdout (single line, parseable): the scratch dir path
echo "$SCRATCH"
