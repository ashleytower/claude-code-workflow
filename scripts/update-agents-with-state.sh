#!/bin/bash
# Add agent state management instructions to all agents

AGENTS_DIR="$HOME/.claude/agents"

# Agent state section to add
AGENT_STATE_SECTION='
## 🔄 Multi-Agent Coordination (MANDATORY)

**Before starting work:**
```bash
# Check if previous agent left context
~/.claude/scripts/agent-state.sh read

# If state exists:
# 1. Read files_changed from previous agent
# 2. Review their work
# 3. Follow next_steps they specified
```

**After completing work:**
```bash
# Write state for next agent (MANDATORY)
~/.claude/scripts/agent-state.sh write \\
  "@agent-name" \\
  "completed" \\
  "Brief summary of what you did" \\
  '"'"'["file1.ts", "file2.ts"]'"'"' \\
  '"'"'["Next step for following agent"]'"'"'
```

**Full instructions**: Read ~/.claude/AGENT-STATE-INSTRUCTIONS.md

---
'

# Add to each agent file if not already present
for agent_file in "$AGENTS_DIR"/*.md; do
  if [ -f "$agent_file" ]; then
    agent_name=$(basename "$agent_file" .md)

    # Check if section already exists
    if ! grep -q "Multi-Agent Coordination" "$agent_file"; then
      echo "Updating $agent_name..."

      # Find the line after frontmatter (after second ---)
      # Insert agent state section there
      awk -v section="$AGENT_STATE_SECTION" '
        /^---$/ { count++ }
        count == 2 && !inserted {
          print
          print section
          inserted = 1
          next
        }
        { print }
      ' "$agent_file" > "$agent_file.tmp"

      mv "$agent_file.tmp" "$agent_file"
      echo "  ✓ Added agent state coordination to $agent_name"
    else
      echo "  - $agent_name already has coordination section"
    fi
  fi
done

echo ""
echo "All agents updated with state management instructions."
