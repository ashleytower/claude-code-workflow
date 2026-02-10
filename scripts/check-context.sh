#!/bin/bash
# Context window monitor - alerts at 70%

CONTEXT_FILE="${CONTEXT_FILE:-/tmp/claude-context-$$}"
MAX_TOKENS=200000
WARN_THRESHOLD=140000  # 70%

# Get current token count from env or calculate
CURRENT_TOKENS="${CLAUDE_CONTEXT_TOKENS:-0}"

if [ "$CURRENT_TOKENS" -gt "$WARN_THRESHOLD" ]; then
    PERCENT=$((CURRENT_TOKENS * 100 / MAX_TOKENS))

    echo "⚠️  CONTEXT WARNING: ${PERCENT}% full ($CURRENT_TOKENS / $MAX_TOKENS tokens)"
    echo ""
    echo "Action required:"
    echo "1. Summarize current work"
    echo "2. Write to document"
    echo "3. Clear context (exit + restart)"
    echo "4. OR fork to new agent/terminal"

    # Voice alert
    if [ -f "$HOME/.claude/scripts/speak.sh" ]; then
        "$HOME/.claude/scripts/speak.sh" "Context at ${PERCENT} percent. Consider forking." &
    fi

    exit 1
fi

exit 0
