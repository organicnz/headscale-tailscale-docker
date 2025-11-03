#!/bin/bash
# Environment File Check - Prevents committing .env file
# Usage: env-check.sh

set -e

if git diff --cached --name-only | grep -q "^\.env$"; then
  echo "❌ ERROR: .env file should not be committed!"
  echo ""
  echo "The .env file contains sensitive credentials and secrets."
  echo ""
  echo "To fix this:"
  echo "  git restore --staged .env"
  echo ""
  echo "Instead, update .env.example with placeholder values."
  echo ""
  exit 1
fi

echo "✅ .env is not being committed"
