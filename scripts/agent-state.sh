#!/bin/bash
# Agent State Management
# Agents use this to leave progress for subsequent agents

STATE_FILE=".claude/agent-state.json"
PROJECT_DIR=$(pwd)

# Ensure state directory exists
mkdir -p "$PROJECT_DIR/.claude"

# Function: Read current state
read_state() {
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo "{}"
  fi
}

# Function: Write agent progress
write_progress() {
  local agent_name=$1
  local status=$2
  local message=$3
  local files_changed=$4
  local next_steps=$5

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Create state JSON
  local state=$(cat <<EOF
{
  "last_updated": "$timestamp",
  "current_agent": "$agent_name",
  "status": "$status",
  "message": "$message",
  "files_changed": $files_changed,
  "next_steps": $next_steps,
  "history": []
}
EOF
)

  # Read existing state
  if [ -f "$STATE_FILE" ]; then
    local existing=$(cat "$STATE_FILE")

    # Append to history using jq if available
    if command -v jq &> /dev/null; then
      state=$(echo "$existing" | jq --arg agent "$agent_name" \
                                     --arg status "$status" \
                                     --arg message "$message" \
                                     --arg timestamp "$timestamp" \
                                     --argjson files "$files_changed" \
                                     --argjson steps "$next_steps" \
        '.history += [{
          "agent": $agent,
          "status": $status,
          "message": $message,
          "timestamp": $timestamp,
          "files_changed": $files,
          "next_steps": $steps
        }] |
        .last_updated = $timestamp |
        .current_agent = $agent |
        .status = $status |
        .message = $message |
        .files_changed = $files |
        .next_steps = $steps')
    fi
  fi

  echo "$state" > "$STATE_FILE"
}

# Function: Get last agent's output
get_last_agent() {
  if [ -f "$STATE_FILE" ]; then
    if command -v jq &> /dev/null; then
      cat "$STATE_FILE" | jq -r '.current_agent // "none"'
    else
      grep "current_agent" "$STATE_FILE" | head -1 | cut -d'"' -f4
    fi
  else
    echo "none"
  fi
}

# Function: Get next steps from previous agent
get_next_steps() {
  if [ -f "$STATE_FILE" ]; then
    if command -v jq &> /dev/null; then
      cat "$STATE_FILE" | jq -r '.next_steps[]? // empty'
    fi
  fi
}

# Function: Clear state (start fresh)
clear_state() {
  if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
  fi
  echo "Agent state cleared"
}

# Function: Mark exploration as complete
mark_explored() {
  local exploration_file="/tmp/claude_exploration_${PWD//\//_}"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  echo "{\"explored\": true, \"timestamp\": \"$timestamp\", \"directory\": \"$PWD\"}" > "$exploration_file"
  echo "✅ Exploration marked complete for: $(basename $PWD)"
  echo "   Timestamp: $timestamp"
}

# Function: Check if exploration is complete
check_explored() {
  local exploration_file="/tmp/claude_exploration_${PWD//\//_}"

  if [ -f "$exploration_file" ]; then
    echo "✅ Codebase explored"
    cat "$exploration_file"
    exit 0
  else
    echo "❌ Codebase NOT explored yet"
    echo ""
    echo "Required actions:"
    echo "  1. Use Task(Explore) to examine codebase"
    echo "  2. Read actual implementation files"
    echo "  3. Run: ~/.claude/scripts/agent-state.sh mark-explored"
    exit 1
  fi
}

# Function: Clear exploration state (useful for testing)
clear_explored() {
  local exploration_file="/tmp/claude_exploration_${PWD//\//_}"

  if [ -f "$exploration_file" ]; then
    rm "$exploration_file"
    echo "✅ Exploration state cleared for: $(basename $PWD)"
  else
    echo "No exploration state to clear"
  fi
}

# Main command handler
case "$1" in
  read)
    read_state
    ;;
  write)
    write_progress "$2" "$3" "$4" "${5:-[]}" "${6:-[]}"
    ;;
  last)
    get_last_agent
    ;;
  next)
    get_next_steps
    ;;
  clear)
    clear_state
    ;;
  mark-explored)
    mark_explored
    ;;
  check-explored)
    check_explored
    ;;
  clear-explored)
    clear_explored
    ;;
  *)
    echo "Usage: agent-state.sh {read|write|last|next|clear|mark-explored|check-explored|clear-explored}"
    echo ""
    echo "Agent State Commands:"
    echo "  agent-state.sh read                           # Read current state"
    echo "  agent-state.sh last                           # Get last agent name"
    echo "  agent-state.sh next                           # Get next steps"
    echo "  agent-state.sh write '@frontend' 'completed' 'UI done' '[]' '[]'"
    echo "  agent-state.sh clear                          # Clear state"
    echo ""
    echo "Exploration Commands:"
    echo "  agent-state.sh mark-explored                  # Mark codebase as explored"
    echo "  agent-state.sh check-explored                 # Check if explored"
    echo "  agent-state.sh clear-explored                 # Clear exploration state"
    exit 1
    ;;
esac
