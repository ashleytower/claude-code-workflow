#!/bin/bash
# macOS notification script
# Usage: notify.sh "message" "title"

MESSAGE="${1:-Claude Code Alert}"
TITLE="${2:-Claude Code}"

# Send macOS notification
osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Glass\""
