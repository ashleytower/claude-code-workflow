#!/bin/bash
# Verification script - Returns error if exploration not done
# Used by hooks to enforce exploration before planning/documentation

CONTEXT_FILE="/tmp/claude_exploration_${PWD//\//_}"

if [ ! -f "$CONTEXT_FILE" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  WARNING: Codebase exploration not detected"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "If this is an existing project with code:"
    echo "  1. Use Task(Explore) to examine the codebase"
    echo "  2. Read key implementation files"
    echo "  3. Mark exploration complete:"
    echo "     ~/.claude/scripts/agent-state.sh mark-explored"
    echo ""
    echo "If this is a NEW project (no code yet):"
    echo "  - Exploration not required, proceed"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0  # Warning only, don't block
fi

echo "✅ Codebase exploration verified for: $(basename $PWD)"
exit 0
