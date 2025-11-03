#!/bin/bash
# Gitignore Check - Verifies critical patterns are ignored
# Usage: gitignore-check.sh

set -e

echo "🔍 Checking .gitignore..."

# Required patterns in .gitignore
REQUIRED_PATTERNS=(
  ".env"
  "headplane/config.yaml"
  "data/"
  "*.log"
)

MISSING_PATTERNS=()

# Check for each required pattern
for pattern in "${REQUIRED_PATTERNS[@]}"; do
  if ! grep -qF "$pattern" .gitignore 2>/dev/null; then
    MISSING_PATTERNS+=("$pattern")
  fi
done

# Report missing patterns
if [ ${#MISSING_PATTERNS[@]} -gt 0 ]; then
  echo "⚠️  WARNING: Missing patterns in .gitignore:"
  for pattern in "${MISSING_PATTERNS[@]}"; do
    echo "  - $pattern"
  done
  echo ""
  echo "Consider adding these patterns to .gitignore to prevent"
  echo "accidentally committing sensitive or unnecessary files."
  echo ""
fi

echo "✅ .gitignore check complete"
