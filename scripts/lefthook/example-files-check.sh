#!/bin/bash
# Example Files Check - Verifies example files exist
# Usage: example-files-check.sh

set -e

echo "🔍 Checking for example files..."

MISSING_FILES=()

# Check for required example files
if [ ! -f ".env.example" ]; then
  MISSING_FILES+=(".env.example")
fi

if [ ! -f "headplane/config.yaml.example" ]; then
  MISSING_FILES+=("headplane/config.yaml.example")
fi

# Report missing files
if [ ${#MISSING_FILES[@]} -gt 0 ]; then
  echo "⚠️  WARNING: Missing example files:"
  for file in "${MISSING_FILES[@]}"; do
    echo "  - $file"
  done
  echo ""
  echo "Example files help others set up the project without exposing secrets."
fi

echo "✅ Example files check complete"
