#!/bin/bash
# Session start hook: Load previous session context

MEMORY_DIR="$HOME/.claude/memory"
LOG_FILE="$HOME/.claude/hook-log.txt"
PROJECT_NAME=$(basename "$(pwd)")
MEMORY_FILE="$MEMORY_DIR/last_session_${PROJECT_NAME}.json"

# Log that hook fired
echo "[$(date)] SessionStart hook fired for $PROJECT_NAME" >> "$LOG_FILE"

if [ -f "$MEMORY_FILE" ]; then
  echo "Previous session found for $PROJECT_NAME"
  cat "$MEMORY_FILE"
  echo ""
  echo "Run /resume to continue where you left off"
else
  echo "startup hook success: Success"
fi
