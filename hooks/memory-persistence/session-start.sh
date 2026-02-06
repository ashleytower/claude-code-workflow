#!/bin/bash
# Session start hook: Load previous session context + memory index

MEMORY_DIR="$HOME/.claude/memory"
SESSIONS_DIR="$MEMORY_DIR/sessions"
LOG_FILE="$HOME/.claude/hook-log.txt"
PROJECT_NAME=$(basename "$(pwd)")
MEMORY_FILE="$SESSIONS_DIR/last_session_${PROJECT_NAME}.json"

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

# Show memory topics with recent entries
if [ -d "$MEMORY_DIR/topics" ]; then
  TOPIC_COUNT=$(ls "$MEMORY_DIR/topics/"*.md 2>/dev/null | wc -l | tr -d ' ')
  if [ "$TOPIC_COUNT" -gt 0 ]; then
    echo ""
    echo "AutoMemory: $TOPIC_COUNT topic files available. Check ~/.claude/memory/INDEX.md"
  fi
fi
