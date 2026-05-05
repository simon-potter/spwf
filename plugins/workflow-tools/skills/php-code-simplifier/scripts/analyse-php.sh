#!/usr/bin/env bash
# analyse-php.sh — targeted PHP analysis on a specific file or directory
# Usage: ./scripts/analyse-php.sh <path> [--level=max]
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: analyse-php.sh <path> [--phpstan-level=8]"
    exit 1
fi

TARGET="$1"
PHPSTAN_LEVEL="${2:-8}"

echo "=== PHP Analysis: $TARGET ==="
echo ""

# PHPStan
if [ -f vendor/bin/phpstan ]; then
    echo "--- PHPStan (level $PHPSTAN_LEVEL) ---"
    vendor/bin/phpstan analyse --level="$PHPSTAN_LEVEL" --no-progress "$TARGET" 2>/dev/null || true
    echo ""
fi

# Psalm
if [ -f vendor/bin/psalm ]; then
    echo "--- Psalm ---"
    vendor/bin/psalm --no-progress --output-format=compact "$TARGET" 2>/dev/null || true
    echo ""
fi

# Check for debug output left in files
echo "--- Debug output check ---"
grep -rn "var_dump\|print_r\|dd(\|dump(\|ray(\|var_export" "$TARGET" --include="*.php" \
    && echo "⚠ Debug output found" \
    || echo "✓ No debug output"
echo ""

# Check for loose comparisons
echo "--- Loose comparison check ---"
LOOSE=$(grep -rn " == \| != " "$TARGET" --include="*.php" | grep -v "===\|!==" | wc -l)
if [ "$LOOSE" -gt 0 ]; then
    echo "⚠ $LOOSE potential loose comparisons (review for type-safety)"
    grep -rn " == \| != " "$TARGET" --include="*.php" | grep -v "===\|!==" | head -10
else
    echo "✓ No obvious loose comparisons"
fi
echo ""

# Check for error suppression
echo "--- Error suppression check ---"
SUPPRESS=$(grep -rn "@[a-z_]" "$TARGET" --include="*.php" | grep -v "phpstan\|psalm\|@throws\|@param\|@return\|@var\|@method\|@property\|@ " | wc -l)
if [ "$SUPPRESS" -gt 0 ]; then
    echo "⚠ $SUPPRESS potential error-suppression operators (@)"
    grep -rn "@[a-z_]" "$TARGET" --include="*.php" | grep -v "phpstan\|psalm\|@throws\|@param\|@return\|@var\|@method\|@property\|@ " | head -5
else
    echo "✓ No error suppression found"
fi
echo ""

# Check for SQL string interpolation
echo "--- SQL injection check ---"
SQL=$(grep -rn '"SELECT\|"INSERT\|"UPDATE\|"DELETE\|'\''SELECT\|'\''INSERT\|'\''UPDATE\|'\''DELETE' "$TARGET" --include="*.php" | grep '\$' | wc -l)
if [ "$SQL" -gt 0 ]; then
    echo "⚠ $SQL potential SQL string interpolations — review for injection risk"
    grep -rn '"SELECT\|"INSERT\|"UPDATE\|"DELETE' "$TARGET" --include="*.php" | grep '\$' | head -5
else
    echo "✓ No obvious SQL interpolation"
fi
