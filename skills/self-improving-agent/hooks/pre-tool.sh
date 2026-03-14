#!/usr/bin/env bash
# Self-improving agent: pre-tool context tracking.
# Minimal - just ensures working memory dir exists for the session.
set -uo pipefail

WORKING_DIR="$HOME/.claude/skills/self-improving-agent/memory/working"
mkdir -p "$WORKING_DIR"

# Track session activity (lightweight counter)
COUNTER_FILE="$WORKING_DIR/tool-count.txt"
COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
echo $((COUNT + 1)) > "$COUNTER_FILE"
