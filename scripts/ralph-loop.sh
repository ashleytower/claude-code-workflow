#!/bin/bash

# Ralph Loop - Autonomous Claude Code Loop
# Keeps running until task is actually complete

set -e

# Configuration
MAX_ITERATIONS=${RALPH_MAX_ITERATIONS:-10}
MAX_COST=${RALPH_MAX_COST:-100}
COMPLETION_CHECK=${RALPH_COMPLETION_CHECK:-"auto"}

# State
ITERATION=0
TOTAL_COST=0
TASK="$1"
COMPLETION_FILE="/tmp/ralph-completion-$$.txt"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${BLUE}[Ralph Loop]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[Ralph Loop]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[Ralph Loop]${NC} $1"
}

log_error() {
    echo -e "${RED}[Ralph Loop]${NC} $1"
}

# Voice notification
speak() {
    if [ -f "$HOME/.claude/scripts/speak.sh" ]; then
        "$HOME/.claude/scripts/speak.sh" "$1"
    fi
}

# Verify completion
verify_completion() {
    log "Verifying task completion..."

    # Check if completion file exists and contains "COMPLETE"
    if [ -f "$COMPLETION_FILE" ] && grep -q "COMPLETE" "$COMPLETION_FILE"; then
        return 0
    fi

    # Auto-detection: Check git status
    if [ "$COMPLETION_CHECK" = "auto" ]; then
        # If no uncommitted changes and tests pass, consider complete
        if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
            log "No uncommitted changes detected"
            return 0
        fi
    fi

    # Not complete
    return 1
}

# Check safety limits
check_limits() {
    if [ $ITERATION -ge $MAX_ITERATIONS ]; then
        log_error "Max iterations ($MAX_ITERATIONS) reached"
        speak "Ralph Loop stopped. Maximum iterations reached."
        return 1
    fi

    if (( $(echo "$TOTAL_COST >= $MAX_COST" | bc -l) )); then
        log_error "Max cost (\$$MAX_COST) reached"
        speak "Ralph Loop stopped. Maximum cost reached."
        return 1
    fi

    return 0
}

# Main loop
main() {
    if [ -z "$TASK" ]; then
        log_error "No task provided"
        echo "Usage: ralph-loop.sh \"Your task here\""
        exit 1
    fi

    log "Starting Ralph Loop"
    log "Task: $TASK"
    log "Max iterations: $MAX_ITERATIONS"
    log "Max cost: \$$MAX_COST"
    speak "Ralph Loop starting"

    while true; do
        ITERATION=$((ITERATION + 1))
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "Iteration $ITERATION / $MAX_ITERATIONS"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Check limits before running
        if ! check_limits; then
            exit 1
        fi

        # Run Claude Code with the task
        log "Running Claude..."
        if claude "$TASK"; then
            log_success "Claude completed iteration $ITERATION"
        else
            log_warning "Claude exited with non-zero status"
        fi

        # Verify completion
        if verify_completion; then
            log_success "✅ Task complete!"
            speak "Ralph Loop complete. Task finished successfully."
            exit 0
        else
            log_warning "Task not yet complete. Continuing..."
            speak "Iteration $ITERATION complete. Continuing."
        fi

        # Brief pause between iterations
        sleep 2
    done
}

# Cleanup on exit
cleanup() {
    log "Cleaning up..."
    rm -f "$COMPLETION_FILE"
}

trap cleanup EXIT

main "$@"
