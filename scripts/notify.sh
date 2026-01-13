#!/bin/bash
# Global notification script for Claude Code
# Sends both macOS notifications and iTerm2 alerts

MESSAGE="$1"
TITLE="${2:-Claude Code}"

# iTerm2 notification (works on macOS)
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
  echo -e "\033]9;${MESSAGE}\007"
fi

# macOS native notification
osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\"" 2>/dev/null

exit 0
