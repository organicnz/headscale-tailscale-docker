#!/bin/bash
# DS_Store Check - Prevents committing macOS metadata files
# Usage: ds-store-check.sh

set -e

if git diff --cached --name-only | grep -q "\.DS_Store"; then
  echo "❌ ERROR: .DS_Store files should not be committed"
  echo ""
  echo "These are macOS system files that don't belong in version control."
  echo ""
  echo "Removing .DS_Store files from staging..."
  git diff --cached --name-only | grep "\.DS_Store" | xargs git restore --staged
  echo ""
  echo "✅ Removed .DS_Store files from staging"
  echo ""
  echo "To prevent this in the future, ensure .DS_Store is in .gitignore"
  echo ""
  exit 1
fi

echo "✅ No .DS_Store files"
