#!/bin/bash

# Instagram Engagement - Monitor target accounts and draft helpful comments
# Mirrors reddit-engage pattern: discover -> score -> draft -> approve -> post

set -uo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="${SKILL_DIR}/config"
PHASES_DIR="${SCRIPT_DIR}/phases"
MAX_AI_DIR="${HOME}/.max-ai"
LOGS_DIR="${MAX_AI_DIR}/logs"
LOG_FILE="${LOGS_DIR}/instagram-engage.log"
OUTPUT_DIR="${MAX_AI_DIR}/instagram-engage"

# Environment variables
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_SERVICE_KEY="${SUPABASE_SERVICE_KEY:-}"
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-8076125560}"
RUBE_TOKEN="${RUBE_TOKEN:-${RUBE_API_KEY:-}}"
USER_ID="3ed111ff-c28f-4cda-b987-1afa4f7eb081"

# Defaults
CAMPAIGN="all"
MAX_COMMENTS_OVERRIDE=""
MANUAL_POSTS=""
MANUAL_CAMPAIGN=""
DRY_RUN=false

# Scoring model (fast + cheap)
SCORING_MODEL="claude-3-5-haiku-20251022"

# Date and time
RUN_DATE=$(date +%Y-%m-%d)
RUN_TIME=$(date +%H:%M:%S)

# Shared utilities (log, error, check_dependencies, check_env_vars,
# supabase_query, call_claude_api, send_telegram_message, generate_fingerprint)
source "$BASE_DIR/skills/shared/lib/common.sh"
cron_lock "instagram-engage"

# ============================================================================
# Argument Parsing
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --campaign)
                CAMPAIGN="$2"
                shift 2
                ;;
            --posts)
                MANUAL_POSTS="$2"
                shift 2
                ;;
            --max-comments)
                MAX_COMMENTS_OVERRIDE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                echo "Usage: instagram-engage.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --campaign <event-leads|managed-bar|voice-crm|all>  Campaign filter (default: all)"
                echo "  --posts <url1,@user2>                               Manual mode: specific posts/accounts"
                echo "  --max-comments <N>                                  Override daily comment limit (default: 10)"
                echo "  --dry-run                                           No API calls or writes"
                echo "  --help                                              Show this help"
                exit 0
                ;;
            *)
                error "Unknown argument: $1"
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    parse_args "$@"

    # Setup
    mkdir -p "$LOGS_DIR" "$OUTPUT_DIR"
    log "=========================================="
    log "Instagram Engagement - Starting"
    log "Campaign: $CAMPAIGN | Max Comments: ${MAX_COMMENTS_OVERRIDE:-10}"
    log "Manual Posts: ${MANUAL_POSTS:-none}"
    log "Dry Run: $DRY_RUN"
    log "=========================================="

    # Checks
    check_dependencies
    check_env_vars "SUPABASE_URL" "SUPABASE_SERVICE_KEY" "ANTHROPIC_API_KEY" "TELEGRAM_BOT_TOKEN" "RUBE_TOKEN"

    # Validate config
    if [[ ! -f "${CONFIG_DIR}/targets.json" ]]; then
        error "Config file not found: ${CONFIG_DIR}/targets.json"
        exit 1
    fi

    # Export shared variables for phase scripts
    export SCRIPT_DIR BASE_DIR SKILL_DIR CONFIG_DIR OUTPUT_DIR
    export SUPABASE_URL SUPABASE_SERVICE_KEY ANTHROPIC_API_KEY
    export TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID RUBE_TOKEN USER_ID
    export CAMPAIGN MAX_COMMENTS_OVERRIDE DRY_RUN
    export MANUAL_POSTS MANUAL_CAMPAIGN
    export SCORING_MODEL RUN_DATE RUN_TIME LOG_FILE

    # Source phase scripts
    source "${PHASES_DIR}/01-discover.sh"
    source "${PHASES_DIR}/02-score.sh"
    source "${PHASES_DIR}/03-engage.sh"

    # Manual mode: specific posts/accounts provided via --posts
    if [[ -n "$MANUAL_POSTS" ]]; then
        log "--- Manual Mode ---"
        MANUAL_CAMPAIGN="${CAMPAIGN}"
        export MANUAL_CAMPAIGN

        local posts
        posts=$(discover_manual_posts "$MANUAL_POSTS")

        if [[ -z "$posts" || "$posts" == "[]" ]]; then
            log "No posts found in manual mode"
            log "=========================================="
            log "Instagram Engagement - Complete (no posts)"
            log "=========================================="
            return 0
        fi

        local scored
        scored=$(score_instagram_posts "$posts" "${MANUAL_CAMPAIGN}")

        if [[ -n "$scored" && "$scored" != "[]" ]]; then
            scored=$(echo "$scored" | jq 'sort_by(-.engagement_score)')
            engage_instagram_posts "$scored"
        else
            log "No posts scored high enough for engagement"
        fi

        log "=========================================="
        log "Instagram Engagement - Complete"
        log "=========================================="
        return 0
    fi

    # Automatic mode: iterate campaigns
    local campaigns=()
    if [[ "$CAMPAIGN" == "all" ]]; then
        campaigns=($(jq -r 'keys[]' "$CONFIG_DIR/targets.json"))
    else
        campaigns=("$CAMPAIGN")
    fi

    # Phase 1 + 2: Discover and score per campaign
    local all_scored="[]"

    for campaign in "${campaigns[@]}"; do
        log "--- Campaign: $campaign ---"

        # Phase 1: Discover
        local posts
        posts=$(discover_instagram_posts "$campaign")

        if [[ -z "$posts" || "$posts" == "[]" ]]; then
            log "No posts found for $campaign"
            continue
        fi

        # Phase 2: Score
        local scored
        scored=$(score_instagram_posts "$posts" "$campaign")

        if [[ -n "$scored" && "$scored" != "[]" ]]; then
            all_scored=$(echo "$all_scored" "$scored" | jq -s '.[0] + .[1]')
        fi
    done

    # Sort all scored posts by engagement_score descending (across all campaigns)
    all_scored=$(echo "$all_scored" | jq 'sort_by(-.engagement_score)')

    local total_scored
    total_scored=$(echo "$all_scored" | jq 'length')
    log "Total scored posts across all campaigns: $total_scored"

    # Phase 3: Engage (once, across all campaigns, capped globally)
    if [[ "$total_scored" -gt 0 ]]; then
        engage_instagram_posts "$all_scored"
    else
        log "No posts to engage with. Done."
    fi

    log "=========================================="
    log "Instagram Engagement - Complete"
    log "=========================================="
}

# ============================================================================
# Entry Point
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
