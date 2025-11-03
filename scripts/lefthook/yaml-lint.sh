#!/bin/bash
# YAML Syntax Validator - Checks YAML files for syntax errors
# Usage: yaml-lint.sh [files...]

set -e

echo "🔍 Validating YAML files..."

# Get staged YAML files
YAML_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(yml|yaml)$' || true)

if [ -z "$YAML_FILES" ]; then
  echo "✅ No YAML files to validate"
  exit 0
fi

# Check if Python is available for YAML validation
if ! command -v python3 &> /dev/null; then
  echo "⚠️  WARNING: python3 not found, skipping YAML validation"
  echo "Install Python to enable YAML validation"
  exit 0
fi

# Validate each YAML file
HAS_ERRORS=false
for file in $YAML_FILES; do
  if [ -f "$file" ]; then
    if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
      echo "❌ ERROR: Invalid YAML in $file"
      python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>&1 || true
      HAS_ERRORS=true
    fi
  fi
done

if [ "$HAS_ERRORS" = true ]; then
  echo ""
  echo "Fix the YAML syntax errors above and try again."
  exit 1
fi

echo "✅ YAML files are valid"
