#!/bin/bash
# Check if all phases in task_plan.md are complete
# Used by Stop hook to verify task completion

PLAN_FILE="task_plan.md"

if [ ! -f "$PLAN_FILE" ]; then
  exit 0  # No plan file, nothing to check
fi

# Count pending phases
PENDING=$(grep -c "Status:** pending" "$PLAN_FILE" 2>/dev/null || echo "0")
IN_PROGRESS=$(grep -c "Status:** in_progress" "$PLAN_FILE" 2>/dev/null || echo "0")

if [ "$PENDING" -gt 0 ] || [ "$IN_PROGRESS" -gt 0 ]; then
  echo "WARNING: Task not complete. $PENDING pending, $IN_PROGRESS in progress."
  exit 1
fi

exit 0
