#!/bin/bash
# Pre-compact hook: Save session state before context compaction

MEMORY_DIR="$HOME/.claude/memory"
SESSIONS_DIR="$MEMORY_DIR/sessions"
HANDOFF_DIR="$HOME/.claude/handoffs"
mkdir -p "$SESSIONS_DIR" "$HANDOFF_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PROJECT_NAME=$(basename "$(pwd)")

# Save current working directory context
cat > "$SESSIONS_DIR/last_session_${PROJECT_NAME}.json" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "project": "$PROJECT_NAME",
  "working_dir": "$(pwd)",
  "git_branch": "$(git branch --show-current 2>/dev/null || echo 'not a git repo')",
  "git_status": "$(git status --porcelain 2>/dev/null | head -20 | tr '\n' '|')"
}
EOF

# Create handoff file if in a project
if [ -f "package.json" ] || [ -f "Cargo.toml" ] || [ -f "go.mod" ] || [ -f "requirements.txt" ]; then
  HANDOFF_FILE="$HANDOFF_DIR/NEXT_SESSION_START_HERE.md"
  cat > "$HANDOFF_FILE" << EOF
# Session Handoff - $(date)

## Project
- **Name:** $PROJECT_NAME
- **Path:** $(pwd)
- **Branch:** $(git branch --show-current 2>/dev/null || echo 'N/A')

## Context Compacted
Session was compacted due to context limits. Review recent changes:

\`\`\`bash
git log --oneline -10
git status
\`\`\`

## Memory
Check AutoMemory for context from previous sessions:
\`\`\`bash
cat ~/.claude/memory/INDEX.md
\`\`\`

## Resume With
\`\`\`
/resume
\`\`\`
EOF
fi

echo "Session state saved to $SESSIONS_DIR"
