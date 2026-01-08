#!/bin/bash
# Check for Claude Code updates at startup

CHANGELOG_URL="https://raw.githubusercontent.com/anthropics/claude-code/refs/heads/main/CHANGELOG.md"
CACHE_FILE="$HOME/.claude/cache/last-version.txt"
CACHE_DIR="$HOME/.claude/cache"

mkdir -p "$CACHE_DIR"

# Get current version
CURRENT=$(claude --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")

# Fetch latest from changelog
LATEST=$(curl -s "$CHANGELOG_URL" | grep -m1 "## Version" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

# Check if we've already notified about this version
if [ -f "$CACHE_FILE" ]; then
    LAST_NOTIFIED=$(cat "$CACHE_FILE")
else
    LAST_NOTIFIED="0.0.0"
fi

# Compare versions
if [ "$CURRENT" != "$LATEST" ] && [ "$LAST_NOTIFIED" != "$LATEST" ]; then
    echo "Update available: $CURRENT → $LATEST"
    echo "$LATEST" > "$CACHE_FILE"

    # Voice alert
    if [ -f "$HOME/.claude/scripts/speak.sh" ]; then
        "$HOME/.claude/scripts/speak.sh" "Claude Code update available" &
    fi

    # Show what's new
    curl -s "$CHANGELOG_URL" | sed -n "/## Version $LATEST/,/## Version/p" | head -30

    echo ""
    echo "Run: npm install -g @anthropic-ai/claude-code@latest"
fi
