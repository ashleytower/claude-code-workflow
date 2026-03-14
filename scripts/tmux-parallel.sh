#!/bin/bash
# Launch parallel Claude sessions in tmux
# Usage: tmux-parallel.sh <worktree1> <task1> <worktree2> <task2> ...
# Example: tmux-parallel.sh ./auth "Build auth" ./api "Build API"

set -e

SESSION_NAME="claude-parallel"

# Kill existing session if it exists
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# Parse arguments as pairs: path, task
declare -a PATHS
declare -a TASKS

while [ $# -gt 0 ]; do
  PATHS+=("$1")
  TASKS+=("${2:-Interactive}")
  shift 2 2>/dev/null || shift 1
done

if [ ${#PATHS[@]} -eq 0 ]; then
  echo "Usage: tmux-parallel.sh <path1> <task1> <path2> <task2> ..."
  echo ""
  echo "Examples:"
  echo "  tmux-parallel.sh ./auth 'Build auth system' ./api 'Build REST API'"
  echo "  tmux-parallel.sh ~/proj-worktrees/feature-1 '/ralph-loop Build feature'"
  exit 1
fi

echo "Starting $SESSION_NAME with ${#PATHS[@]} panes..."

# Create first pane
tmux new-session -d -s "$SESSION_NAME" -c "${PATHS[0]}"
tmux send-keys -t "$SESSION_NAME" "claude '${TASKS[0]}'" Enter

# Create additional panes
for i in $(seq 1 $((${#PATHS[@]} - 1))); do
  tmux split-window -t "$SESSION_NAME" -c "${PATHS[$i]}"
  tmux send-keys -t "$SESSION_NAME" "claude '${TASKS[$i]}'" Enter
  tmux select-layout -t "$SESSION_NAME" tiled
done

echo ""
echo "Sessions started. Attaching..."
echo "  Ctrl+B then arrow keys to switch panes"
echo "  Ctrl+B then D to detach (sessions keep running)"
echo ""

tmux attach -t "$SESSION_NAME"
