#!/bin/bash
# Parallel build setup with git worktrees
# Usage: parallel-build.sh <project-path> <branch1> <branch2> ...

set -e

PROJECT_PATH="${1:-.}"
shift
BRANCHES=("$@")

if [ ${#BRANCHES[@]} -eq 0 ]; then
  echo "Usage: parallel-build.sh <project-path> <branch1> <branch2> ..."
  echo "Example: parallel-build.sh . feature/auth feature/api feature/ui"
  exit 1
fi

cd "$PROJECT_PATH"
PROJECT_NAME=$(basename "$(pwd)")
WORKTREE_BASE="../${PROJECT_NAME}-worktrees"

mkdir -p "$WORKTREE_BASE"

echo "Setting up parallel worktrees for: ${BRANCHES[*]}"
echo "=================================================="

for branch in "${BRANCHES[@]}"; do
  WORKTREE_PATH="$WORKTREE_BASE/$branch"

  # Create branch if it doesn't exist
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "Creating branch: $branch"
    git branch "$branch"
  fi

  # Create worktree if it doesn't exist
  if [ ! -d "$WORKTREE_PATH" ]; then
    echo "Creating worktree: $WORKTREE_PATH"
    git worktree add "$WORKTREE_PATH" "$branch"
  else
    echo "Worktree exists: $WORKTREE_PATH"
  fi
done

echo ""
echo "=================================================="
echo "Worktrees ready. Start Claude in each:"
echo ""
for branch in "${BRANCHES[@]}"; do
  echo "  cd $WORKTREE_BASE/$branch && claude"
done
echo ""
echo "Or use tmux to run all in parallel:"
echo ""
echo "  tmux new-session -d -s build"
for i in "${!BRANCHES[@]}"; do
  branch="${BRANCHES[$i]}"
  if [ $i -eq 0 ]; then
    echo "  tmux send-keys -t build 'cd $WORKTREE_BASE/$branch && claude' Enter"
  else
    echo "  tmux split-window -t build -h"
    echo "  tmux send-keys -t build 'cd $WORKTREE_BASE/$branch && claude' Enter"
  fi
done
echo "  tmux select-layout -t build tiled"
echo "  tmux attach -t build"
