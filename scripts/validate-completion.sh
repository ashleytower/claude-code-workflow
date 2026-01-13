#!/bin/bash

# Validate Completion - Stop hook that checks if work is actually done
# Returns 0 to allow stop, non-zero to continue working
# Based on Boris Cherny's Ralph Wiggum pattern

# Check for PRD file in current directory
PRD_FILE=$(find . -maxdepth 1 -name "prd-*.json" -type f | head -1)

if [ -n "$PRD_FILE" ]; then
    # PRD mode: check if all stories pass
    REMAINING=$(jq '[.stories[] | select(.passes == false and (.failed // false) == false)] | length' "$PRD_FILE" 2>/dev/null)

    if [ "$REMAINING" -gt 0 ] 2>/dev/null; then
        echo "PRD has $REMAINING incomplete stories. Continue working."
        exit 1  # Don't stop
    fi
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "Uncommitted changes detected. Continue working."
    exit 1  # Don't stop
fi

# Check if tests pass (if package.json exists)
if [ -f "package.json" ]; then
    if ! npm test --silent 2>/dev/null; then
        echo "Tests failing. Continue working."
        exit 1  # Don't stop
    fi
fi

# All checks passed - allow stop
echo "Work complete. Allowing stop."
exit 0
