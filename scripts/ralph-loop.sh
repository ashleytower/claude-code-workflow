#!/bin/bash

# Ralph Loop - Autonomous Claude Code Loop
# PRD-driven mode for hours of autonomous work
# Named after Ralph Wiggum - persistent, keeps going until done

set -e

# Source env for voice notifications
if [ -f ~/.claude/.env ]; then
    source ~/.claude/.env
fi

# Configuration
MAX_ITERATIONS=${RALPH_MAX_ITERATIONS:-50}
MAX_COST=${RALPH_MAX_COST:-100}
PRD_FILE=""
SIMPLE_TASK=""
MODE="simple"  # simple or prd

# State
ITERATION=0
STORIES_COMPLETED=0
PROGRESS_FILE="./progress.txt"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log() { echo -e "${BLUE}[Ralph]${NC} $1"; }
log_success() { echo -e "${GREEN}[Ralph]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[Ralph]${NC} $1"; }
log_error() { echo -e "${RED}[Ralph]${NC} $1"; }
log_story() { echo -e "${CYAN}[Story]${NC} $1"; }

# Voice notification
speak() {
    if [ -f "$HOME/.claude/scripts/speak.sh" ]; then
        "$HOME/.claude/scripts/speak.sh" "$1" &
    fi
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --prd)
                PRD_FILE="$2"
                MODE="prd"
                shift 2
                ;;
            --max-iterations)
                MAX_ITERATIONS="$2"
                shift 2
                ;;
            --max-cost)
                MAX_COST="$2"
                shift 2
                ;;
            *)
                SIMPLE_TASK="$1"
                shift
                ;;
        esac
    done
}

# Get next incomplete story from PRD
get_next_story() {
    if [ ! -f "$PRD_FILE" ]; then
        log_error "PRD file not found: $PRD_FILE"
        return 1
    fi

    # Find first story with passes: false
    jq -r '.stories[] | select(.passes == false) | .id' "$PRD_FILE" | head -1
}

# Get story details
get_story_details() {
    local story_id="$1"
    jq -r ".stories[] | select(.id == \"$story_id\")" "$PRD_FILE"
}

# Mark story as complete
mark_story_complete() {
    local story_id="$1"
    local temp_file=$(mktemp)

    jq "(.stories[] | select(.id == \"$story_id\")).passes = true" "$PRD_FILE" > "$temp_file"
    mv "$temp_file" "$PRD_FILE"

    log_success "Marked story $story_id as complete"
}

# Count remaining stories
count_remaining() {
    jq '[.stories[] | select(.passes == false)] | length' "$PRD_FILE"
}

# Count total stories
count_total() {
    jq '.stories | length' "$PRD_FILE"
}

# Append to progress file
log_progress() {
    local story_id="$1"
    local message="$2"

    echo "" >> "$PROGRESS_FILE"
    echo "## Iteration $ITERATION - Story $story_id" >> "$PROGRESS_FILE"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
    echo "$message" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
}

# Initialize progress file
init_progress() {
    if [ ! -f "$PROGRESS_FILE" ]; then
        echo "# Ralph Loop Progress" > "$PROGRESS_FILE"
        echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
        echo "PRD: $PRD_FILE" >> "$PROGRESS_FILE"
        echo "" >> "$PROGRESS_FILE"
    fi
}

# Build prompt for Claude
build_prompt() {
    local story_id="$1"
    local story_json=$(get_story_details "$story_id")
    local story_text=$(echo "$story_json" | jq -r '.story')
    local criteria=$(echo "$story_json" | jq -r '.acceptance_criteria | join("\n- ")')

    cat << EOF
You are working through a PRD backlog autonomously.

CURRENT STORY: $story_text

ACCEPTANCE CRITERIA:
- $criteria

INSTRUCTIONS:
1. Implement ONLY this story (nothing else)
2. Run tests to verify acceptance criteria
3. If tests fail, fix and retry
4. When done, output: STORY_COMPLETE

DO NOT:
- Work on other stories
- Make unrelated changes
- Stop without completing

PROGRESS FILE: Check ./progress.txt for context from previous iterations.

When finished, say exactly: STORY_COMPLETE
EOF
}

# Run PRD mode
run_prd_mode() {
    log "Starting PRD-driven Ralph Loop"
    log "PRD: $PRD_FILE"
    log "Max iterations: $MAX_ITERATIONS"

    init_progress
    speak "Ralph loop starting. Working through P R D."

    local total=$(count_total)
    log "Total stories: $total"

    while true; do
        ITERATION=$((ITERATION + 1))

        # Check iteration limit
        if [ $ITERATION -gt $MAX_ITERATIONS ]; then
            log_error "Max iterations reached ($MAX_ITERATIONS)"
            speak "Ralph loop stopped. Maximum iterations reached."
            exit 1
        fi

        # Get next story
        local story_id=$(get_next_story)

        if [ -z "$story_id" ]; then
            log_success "All stories complete!"
            speak "Ralph loop complete. All $total stories finished."

            # Final summary
            echo "" >> "$PROGRESS_FILE"
            echo "# COMPLETE" >> "$PROGRESS_FILE"
            echo "Finished: $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
            echo "Total iterations: $ITERATION" >> "$PROGRESS_FILE"
            echo "Stories completed: $STORIES_COMPLETED" >> "$PROGRESS_FILE"

            exit 0
        fi

        local remaining=$(count_remaining)
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "Iteration $ITERATION | Story: $story_id | Remaining: $remaining/$total"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Get story details for logging
        local story_text=$(get_story_details "$story_id" | jq -r '.story')
        log_story "$story_text"

        # Build and run prompt
        local prompt=$(build_prompt "$story_id")

        log "Running Claude..."
        local output=$(claude --print "$prompt" 2>&1) || true

        # Check if story complete
        if echo "$output" | grep -q "STORY_COMPLETE"; then
            log_success "Story $story_id completed!"
            mark_story_complete "$story_id"
            STORIES_COMPLETED=$((STORIES_COMPLETED + 1))

            # Log progress
            log_progress "$story_id" "Completed: $story_text"

            # Commit changes
            log "Committing changes..."
            git add -A
            git commit -m "feat: $story_text

Ralph Loop iteration $ITERATION
Story ID: $story_id

Co-Authored-By: Claude <noreply@anthropic.com>" || true

            speak "Story $story_id complete. $remaining remaining."
        else
            log_warning "Story $story_id not marked complete. Retrying..."
            log_progress "$story_id" "Incomplete - retrying next iteration"
        fi

        # Brief pause
        sleep 2
    done
}

# Run simple mode (original behavior)
run_simple_mode() {
    log "Starting simple Ralph Loop"
    log "Task: $SIMPLE_TASK"
    log "Max iterations: $MAX_ITERATIONS"

    speak "Ralph loop starting"

    while true; do
        ITERATION=$((ITERATION + 1))

        if [ $ITERATION -gt $MAX_ITERATIONS ]; then
            log_error "Max iterations reached"
            speak "Ralph loop stopped. Maximum iterations reached."
            exit 1
        fi

        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "Iteration $ITERATION / $MAX_ITERATIONS"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        log "Running Claude..."
        if claude "$SIMPLE_TASK"; then
            log_success "Claude completed iteration $ITERATION"
        else
            log_warning "Claude exited with non-zero status"
        fi

        # Check if done (clean git status)
        if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
            log_success "Task complete! (clean git status)"
            speak "Ralph loop complete. Task finished."
            exit 0
        fi

        log_warning "Uncommitted changes remain. Continuing..."
        sleep 2
    done
}

# Usage
usage() {
    cat << EOF
Ralph Loop - Autonomous Claude Code Execution

USAGE:
  ralph-loop.sh "task description"           # Simple mode
  ralph-loop.sh --prd ./prd.json             # PRD-driven mode

OPTIONS:
  --prd <file>           Use PRD JSON file for user stories
  --max-iterations <n>   Maximum iterations (default: 50)
  --max-cost <n>         Maximum cost in dollars (default: 100)

EXAMPLES:
  # Simple task
  ralph-loop.sh "Fix all TypeScript errors"

  # PRD-driven (for hours of autonomous work)
  ralph-loop.sh --prd ./prd.json --max-iterations 100

  # With custom limits
  RALPH_MAX_ITERATIONS=20 ralph-loop.sh --prd ./prd.json

PRD FORMAT:
  See ~/.claude/templates/prd.json for template

EOF
    exit 0
}

# Main
main() {
    if [ $# -eq 0 ]; then
        usage
    fi

    parse_args "$@"

    if [ "$MODE" = "prd" ]; then
        if [ ! -f "$PRD_FILE" ]; then
            log_error "PRD file not found: $PRD_FILE"
            exit 1
        fi
        run_prd_mode
    else
        if [ -z "$SIMPLE_TASK" ]; then
            log_error "No task provided"
            usage
        fi
        run_simple_mode
    fi
}

main "$@"
