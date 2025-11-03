#!/bin/bash
# Commit Message Format Validator
# Usage: commit-msg-format.sh <commit-msg-file>

set -e

COMMIT_MSG_FILE="$1"

if [ -z "$COMMIT_MSG_FILE" ] || [ ! -f "$COMMIT_MSG_FILE" ]; then
  echo "❌ ERROR: Commit message file not found"
  exit 1
fi

# Read commit message
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Remove comments and whitespace
COMMIT_MSG_CLEAN=$(echo "$COMMIT_MSG" | sed '/^#/d' | tr -d '[:space:]')

# Check if commit message is empty
if [ -z "$COMMIT_MSG_CLEAN" ]; then
  echo "❌ ERROR: Commit message cannot be empty"
  echo ""
  echo "Please provide a meaningful commit message describing your changes."
  echo ""
  exit 1
fi

# Get first line (subject) length
FIRST_LINE=$(echo "$COMMIT_MSG" | head -1)
MSG_LENGTH=${#FIRST_LINE}

# Check minimum length
if [ "$MSG_LENGTH" -lt 10 ]; then
  echo "❌ ERROR: Commit message too short (minimum 10 characters)"
  echo ""
  echo "Current message: \"$FIRST_LINE\""
  echo "Length: $MSG_LENGTH characters"
  echo ""
  echo "Please provide a more descriptive commit message."
  echo ""
  exit 1
fi

# Check if message starts with common prefixes (optional suggestion)
if echo "$FIRST_LINE" | grep -qE "^(fix|feat|docs|style|refactor|test|chore|perf|ci|build|revert):" 2>/dev/null; then
  echo "✅ Commit message format OK (conventional commits style detected)"
else
  echo "✅ Commit message format OK"
fi
