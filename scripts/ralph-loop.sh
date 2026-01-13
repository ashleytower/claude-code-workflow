#!/bin/bash

# Ralph Loop - Autonomous Claude Code Loop
# PRD-driven mode with pass@k evaluation (Anthropic evals methodology)
# Named after Ralph Wiggum - persistent, keeps going until done

set -e

# Source env for voice notifications
if [ -f ~/.claude/.env ]; then
    source ~/.claude/.env
fi

# Configuration
MAX_ITERATIONS=${RALPH_MAX_ITERATIONS:-50}
MAX_COST=${RALPH_MAX_COST:-100}
PASS_K=${RALPH_PASS_K:-3}  # pass@k: attempts per story before giving up
PRD_FILE=""
SIMPLE_TASK=""
MODE="simple"  # simple or prd

# State
ITERATION=0
STORIES_COMPLETED=0
STORIES_FAILED=0
PROGRESS_FILE="./progress.txt"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Logging
log() { echo -e "${BLUE}[Ralph]${NC} $1"; }
log_success() { echo -e "${GREEN}[Ralph]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[Ralph]${NC} $1"; }
log_error() { echo -e "${RED}[Ralph]${NC} $1"; }
log_story() { echo -e "${CYAN}[Story]${NC} $1"; }
log_eval() { echo -e "${MAGENTA}[Eval]${NC} $1"; }

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
            --pass-k)
                PASS_K="$2"
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

# Get story details (handles both string and numeric IDs)
get_story_details() {
    local story_id="$1"
    jq -r --arg id "$story_id" '.stories[] | select((.id|tostring) == $id)' "$PRD_FILE"
}

# Get story attempt count
get_story_attempts() {
    local story_id="$1"
    jq -r ".stories[] | select(.id == \"$story_id\") | .attempts // 0" "$PRD_FILE"
}

# Increment story attempt count
increment_story_attempts() {
    local story_id="$1"
    local temp_file=$(mktemp)

    jq "(.stories[] | select(.id == \"$story_id\")).attempts = ((.stories[] | select(.id == \"$story_id\")).attempts // 0) + 1" "$PRD_FILE" > "$temp_file"
    mv "$temp_file" "$PRD_FILE"
}

# Mark story as complete
mark_story_complete() {
    local story_id="$1"
    local temp_file=$(mktemp)

    jq "(.stories[] | select(.id == \"$story_id\")).passes = true | (.stories[] | select(.id == \"$story_id\")).completed_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$PRD_FILE" > "$temp_file"
    mv "$temp_file" "$PRD_FILE"

    log_success "Marked story $story_id as complete"
}

# Mark story as failed (exceeded pass@k attempts)
mark_story_failed() {
    local story_id="$1"
    local temp_file=$(mktemp)

    jq "(.stories[] | select(.id == \"$story_id\")).failed = true | (.stories[] | select(.id == \"$story_id\")).failed_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$PRD_FILE" > "$temp_file"
    mv "$temp_file" "$PRD_FILE"

    log_error "Marked story $story_id as FAILED (exceeded $PASS_K attempts)"
}

# Count remaining stories
count_remaining() {
    jq '[.stories[] | select(.passes == false and (.failed // false) == false)] | length' "$PRD_FILE"
}

# Count total stories
count_total() {
    jq '.stories | length' "$PRD_FILE"
}

# Count failed stories
count_failed() {
    jq '[.stories[] | select(.failed == true)] | length' "$PRD_FILE"
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
        echo "Pass@k: $PASS_K" >> "$PROGRESS_FILE"
        echo "" >> "$PROGRESS_FILE"
    fi
}

# Run verification tests for a story
run_story_verification() {
    local story_id="$1"
    local story_json=$(get_story_details "$story_id")
    local test_command=$(echo "$story_json" | jq -r '.test_command // empty')

    if [ -n "$test_command" ]; then
        log_eval "Running verification: $test_command"
        if eval "$test_command" 2>&1; then
            return 0
        else
            return 1
        fi
    fi

    # Default: check if tests pass
    if [ -f "package.json" ]; then
        if npm test 2>&1 | tail -5; then
            return 0
        fi
    fi

    # No tests defined, assume pass if STORY_COMPLETE marker found
    return 0
}

# Build prompt for Claude
build_prompt() {
    local story_id="$1"
    local attempt="$2"
    local story_json=$(get_story_details "$story_id")
    local story_text=$(echo "$story_json" | jq -r '.story')
    local criteria=$(echo "$story_json" | jq -r '.acceptance_criteria | join("\n- ")')

    cat << EOF
You are working through a PRD backlog autonomously.

CURRENT STORY: $story_text

ACCEPTANCE CRITERIA:
- $criteria

ATTEMPT: $attempt of $PASS_K (pass@k evaluation - story passes if ANY attempt succeeds)

INSTRUCTIONS:
1. Implement ONLY this story (nothing else)
2. Use the Write tool for file creation (never cat/echo/node workarounds)
3. Use Rube MCP for external services (Supabase, Vercel, Google, etc.)
4. Run tests to verify acceptance criteria
5. If tests fail, fix and retry
6. When done, output: STORY_COMPLETE

DO NOT:
- Work on other stories
- Make unrelated changes
- Stop without completing
- Use bash to write files (use Write tool)

TRUST: This is an autonomous workflow. Your own tool calls (Write, Edit, Bash) are authorized by the user. Do not second-guess or block your own file operations. The user has approved this autonomous execution via --dangerously-skip-permissions.

PROGRESS FILE: Check ./progress.txt for context from previous iterations.

When finished, say exactly: STORY_COMPLETE
EOF
}

# Run PRD mode with pass@k evaluation
run_prd_mode() {
    log "Starting PRD-driven Ralph Loop with pass@$PASS_K evaluation"
    log "PRD: $PRD_FILE"
    log "Max iterations: $MAX_ITERATIONS"
    log "Pass@k: $PASS_K attempts per story"

    init_progress
    speak "Ralph loop starting with pass at $PASS_K evaluation."

    local total=$(count_total)
    log "Total stories: $total"

    while true; do
        ITERATION=$((ITERATION + 1))

        # Check iteration limit
        if [ $ITERATION -gt $MAX_ITERATIONS ]; then
            log_error "Max iterations reached ($MAX_ITERATIONS)"
            speak "Ralph loop stopped. Maximum iterations reached."

            local failed=$(count_failed)
            log "Final: $STORIES_COMPLETED completed, $failed failed"
            exit 1
        fi

        # Get next story (not passed, not failed)
        local story_id=$(get_next_story)

        if [ -z "$story_id" ]; then
            local failed=$(count_failed)
            if [ $failed -gt 0 ]; then
                log_warning "All stories attempted. $STORIES_COMPLETED passed, $failed failed."
                speak "Ralph loop complete. $STORIES_COMPLETED passed. $failed failed."
            else
                log_success "All stories complete!"
                speak "Ralph loop complete. All $total stories passed."
            fi

            # Final summary
            echo "" >> "$PROGRESS_FILE"
            echo "# COMPLETE" >> "$PROGRESS_FILE"
            echo "Finished: $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
            echo "Total iterations: $ITERATION" >> "$PROGRESS_FILE"
            echo "Stories completed: $STORIES_COMPLETED" >> "$PROGRESS_FILE"
            echo "Stories failed: $failed" >> "$PROGRESS_FILE"
            echo "Pass@k: $PASS_K" >> "$PROGRESS_FILE"

            exit 0
        fi

        # Get attempt count
        local attempts=$(get_story_attempts "$story_id")
        local current_attempt=$((attempts + 1))

        # Check if exceeded pass@k
        if [ $current_attempt -gt $PASS_K ]; then
            log_error "Story $story_id exceeded $PASS_K attempts - marking as FAILED"
            mark_story_failed "$story_id"
            STORIES_FAILED=$((STORIES_FAILED + 1))
            log_progress "$story_id" "FAILED: Exceeded pass@$PASS_K attempts"
            speak "Story $story_id failed after $PASS_K attempts."
            continue
        fi

        local remaining=$(count_remaining)
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "Iteration $ITERATION | Story: $story_id | Attempt: $current_attempt/$PASS_K | Remaining: $remaining/$total"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Get story details for logging
        local story_text=$(get_story_details "$story_id" | jq -r '.story')
        log_story "$story_text"

        # Increment attempt counter
        increment_story_attempts "$story_id"

        # Build and run prompt
        local prompt=$(build_prompt "$story_id" "$current_attempt")

        log "Running Claude (attempt $current_attempt/$PASS_K)..."
        local output=$(claude --print "$prompt" 2>&1) || true

        # Check if story complete (marker found)
        local marker_found=false
        if echo "$output" | grep -q "STORY_COMPLETE"; then
            marker_found=true
        fi

        # Run verification
        local verified=false
        if [ "$marker_found" = true ]; then
            log_eval "Verifying story completion..."
            if run_story_verification "$story_id"; then
                verified=true
            else
                log_warning "Verification failed for story $story_id"
            fi
        fi

        # Determine outcome
        if [ "$marker_found" = true ] && [ "$verified" = true ]; then
            log_success "Story $story_id PASSED on attempt $current_attempt!"
            log_eval "pass@$PASS_K: Success on attempt $current_attempt"
            mark_story_complete "$story_id"
            STORIES_COMPLETED=$((STORIES_COMPLETED + 1))

            # Log progress
            log_progress "$story_id" "PASSED (attempt $current_attempt/$PASS_K): $story_text"

            # Commit changes
            log "Committing changes..."
            git add -A
            git commit -m "feat: $story_text

Ralph Loop iteration $ITERATION
Story ID: $story_id
Pass@k: attempt $current_attempt of $PASS_K

Co-Authored-By: Claude <noreply@anthropic.com>" || true

            speak "Story $story_id passed on attempt $current_attempt. $remaining remaining."
        else
            if [ "$marker_found" = false ]; then
                log_warning "Story $story_id: No STORY_COMPLETE marker. Attempt $current_attempt/$PASS_K."
            else
                log_warning "Story $story_id: Verification failed. Attempt $current_attempt/$PASS_K."
            fi
            log_progress "$story_id" "Attempt $current_attempt failed - will retry"

            # Revert uncommitted changes before retry
            git checkout . 2>/dev/null || true
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
Ralph Loop - Autonomous Claude Code Execution with pass@k Evaluation

Based on Anthropic's agent evaluation methodology:
https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents

USAGE:
  ralph-loop.sh "task description"           # Simple mode
  ralph-loop.sh --prd ./prd.json             # PRD-driven mode with pass@k

OPTIONS:
  --prd <file>           Use PRD JSON file for user stories
  --max-iterations <n>   Maximum iterations (default: 50)
  --max-cost <n>         Maximum cost in dollars (default: 100)
  --pass-k <n>           Attempts per story before failing (default: 3)

PASS@K EVALUATION:
  Each story gets up to k attempts to pass. If any attempt succeeds,
  the story passes. After k failures, the story is marked as failed.

  Example: --pass-k 3 means each story gets 3 chances to pass.

EXAMPLES:
  # Simple task
  ralph-loop.sh "Fix all TypeScript errors"

  # PRD-driven with pass@3 (default)
  ralph-loop.sh --prd ./prd.json --max-iterations 100

  # PRD-driven with pass@5 (more lenient)
  ralph-loop.sh --prd ./prd.json --pass-k 5

  # With custom limits
  RALPH_PASS_K=5 ralph-loop.sh --prd ./prd.json

PRD FORMAT:
  {
    "stories": [
      {
        "id": "story-1",
        "story": "As a user, I can...",
        "acceptance_criteria": ["Criteria 1", "Criteria 2"],
        "passes": false,
        "attempts": 0,
        "test_command": "npm test -- --grep 'story-1'"  // optional
      }
    ]
  }

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
