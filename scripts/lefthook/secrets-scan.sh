#!/bin/bash
# Secrets Scanner - Detects exposed secrets in staged files
# Usage: secrets-scan.sh [files...]

set -e

echo "🔍 Scanning for exposed secrets..."

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

# Check staged files for secrets
if git diff --cached --name-only | \
   xargs grep -nHE "(api_key|password|secret|token|key).*[:=].*[a-zA-Z0-9]{20,}" 2>/dev/null | \
   grep -vE "$EXCLUDE_REGEX"; then
  echo ""
  echo "❌ ERROR: Potential secrets detected in staged files!"
  echo ""
  echo "Please follow these steps:"
  echo "  1. Remove hardcoded secrets from the files above"
  echo "  2. Move secrets to .env file"
  echo "  3. Use environment variables in your config files"
  echo ""
  echo "Example:"
  echo "  Instead of:  api_key: \"abc123...\""
  echo "  Use:         api_key: \"\${API_KEY}\""
  echo ""
  exit 1
fi

echo "✅ No secrets detected"
