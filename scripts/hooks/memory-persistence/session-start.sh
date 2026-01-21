#!/bin/bash
# Session start hook: Load previous session context

MEMORY_DIR="$HOME/.claude/memory"
PROJECT_NAME=$(basename "$(pwd)")
MEMORY_FILE="$MEMORY_DIR/last_session_${PROJECT_NAME}.json"

if [ -f "$MEMORY_FILE" ]; then
  echo "Previous session found for $PROJECT_NAME"
  cat "$MEMORY_FILE"
  echo ""
  echo "Run /resume to continue where you left off"
else
  echo "startup hook success: Success"
fi
