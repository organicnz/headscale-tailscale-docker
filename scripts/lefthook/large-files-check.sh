#!/bin/bash
# Large Files Check - Warns about files over 1MB
# Usage: large-files-check.sh

set -e

echo "🔍 Checking for large files..."

# Find files larger than 1MB in staging
LARGE_FILES=$(git diff --cached --name-only | while read file; do
  if [ -f "$file" ]; then
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
    if [ "$size" -gt 1048576 ]; then  # 1MB in bytes
      echo "$file ($(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo "${size} bytes"))"
    fi
  fi
done)

if [ ! -z "$LARGE_FILES" ]; then
  echo ""
  echo "⚠️  WARNING: Large files detected:"
  echo "$LARGE_FILES"
  echo ""
  echo "Consider:"
  echo "  - Using Git LFS for large files"
  echo "  - Adding large files to .gitignore"
  echo "  - Compressing files before committing"
  echo "  - Storing large files externally"
  echo ""
fi

echo "✅ Large files check complete"
