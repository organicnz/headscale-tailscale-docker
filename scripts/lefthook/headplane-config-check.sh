#!/bin/bash
# Headplane Config Check - Prevents committing config with secrets
# Usage: headplane-config-check.sh

set -e

if git diff --cached --name-only | grep -q "^headplane/config.yaml$"; then
  echo "❌ ERROR: headplane/config.yaml contains secrets and should not be committed!"
  echo ""
  echo "This file contains API keys and cookie secrets."
  echo ""
  echo "To fix this:"
  echo "  git restore --staged headplane/config.yaml"
  echo ""
  echo "Use headplane/config.yaml.example instead for version control."
  echo ""
  exit 1
fi

echo "✅ headplane/config.yaml is not being committed"
