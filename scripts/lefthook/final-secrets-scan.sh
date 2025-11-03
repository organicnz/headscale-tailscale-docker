#!/bin/bash
# Final Secrets Scan - Comprehensive scan before push
# Usage: final-secrets-scan.sh

set -e

echo "🔍 Final security scan before push..."

# Patterns to exclude from detection
EXCLUDE_PATTERNS=(
  ".example"
  "your_.*_here"
  "changeme"
  "HEADPLANE_API_KEY=\$"
  "HEADPLANE_COOKIE_SECRET=\$"
  "Generate with:"
  "\[REDACTED\]"
  "YOUR_"
  "POSTGRES_PASSWORD=\$"
  "example.com"
  "localhost"
)

# Build grep exclude pattern
EXCLUDE_REGEX=$(printf "|%s" "${EXCLUDE_PATTERNS[@]}")
EXCLUDE_REGEX="${EXCLUDE_REGEX:1}"  # Remove leading |

# Check all tracked files for secrets
if git ls-files | \
   xargs grep -nHE "(api_key|password|secret|token).*[:=].*[a-zA-Z0-9]{20,}" 2>/dev/null | \
   grep -vE "$EXCLUDE_REGEX"; then
  echo ""
  echo "❌ ERROR: Secrets detected in tracked files!"
  echo ""
  echo "⚠️  WARNING: These secrets will be exposed in your public repository!"
  echo ""
  echo "To fix this:"
  echo "  1. Remove secrets from the files listed above"
  echo "  2. Add files with secrets to .gitignore"
  echo "  3. Use environment variables instead"
  echo "  4. Regenerate any exposed secrets"
  echo ""
  exit 1
fi

echo "✅ No secrets detected in tracked files"
