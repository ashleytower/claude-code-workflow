#!/bin/bash

# Validate Completion - Stop hook for informational purposes only
# NEVER blocks - just logs status for awareness
# Based on Boris Cherny's Ralph Wiggum pattern

# This script is INFORMATIONAL ONLY - always exits 0
# Tests should be run explicitly via /verify-app, not on every stop

# Check for PRD file in current directory
PRD_FILE=$(find . -maxdepth 1 -name "prd-*.json" -type f 2>/dev/null | head -1)

if [ -n "$PRD_FILE" ]; then
    # PRD mode: check if all stories pass
    REMAINING=$(jq '[.stories[] | select(.passes == false and (.failed // false) == false)] | length' "$PRD_FILE" 2>/dev/null)

    if [ "$REMAINING" -gt 0 ] 2>/dev/null; then
        echo "[Info] PRD has $REMAINING incomplete stories remaining."
    fi
fi

# Check for uncommitted changes (informational only)
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    CHANGED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    echo "[Info] $CHANGED uncommitted changes."
fi

# Always exit 0 - never block the agent
exit 0
