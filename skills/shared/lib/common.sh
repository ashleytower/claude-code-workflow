#!/bin/bash
# Shared utilities for Max AI Employee skills
# Sourced by: fb-group-monitor, reddit-engage, and other skill scripts
#
# Provides: logging, env checks, API clients (Claude, Supabase, Telegram, Rube),
#           dedup fingerprints, cron locking, browser automation handoff

# ============================================================================
# Logging
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

# ============================================================================
# Cron Lock (prevent concurrent runs)
# ============================================================================

cron_lock() {
    local name="${1:?cron_lock requires a name}"
    local lock_dir="${HOME}/.max-ai/locks"
    local lock_file="${lock_dir}/${name}.lock"
    mkdir -p "$lock_dir"

    if [[ -f "$lock_file" ]]; then
        local pid
        pid=$(cat "$lock_file" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            error "$name is already running (PID $pid). Exiting."
            exit 0
        else
            log "Stale lock for $name (PID $pid no longer running). Removing."
            rm -f "$lock_file"
        fi
    fi

    echo $$ > "$lock_file"

    trap "rm -f '$lock_file'" EXIT INT TERM
}

# ============================================================================
# Dependency Checks
# ============================================================================

check_dependencies() {
    local deps=(curl jq)
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

# check_env_vars [VAR1 VAR2 ...]
# If no args, checks a default set. If args provided, checks those.
check_env_vars() {
    local vars=("$@")

    if [[ ${#vars[@]} -eq 0 ]]; then
        vars=(SUPABASE_URL SUPABASE_SERVICE_KEY ANTHROPIC_API_KEY TELEGRAM_BOT_TOKEN)
    fi

    # Vars that warn but don't block execution
    local optional_vars=(TELEGRAM_BOT_TOKEN)

    local missing=()
    local warned=()
    for var in "${vars[@]}"; do
        local val="${!var:-}"
        if [[ -z "$val" ]]; then
            # Try common alternates
            case "$var" in
                SUPABASE_SERVICE_KEY)
                    val="${SUPABASE_SERVICE_ROLE_KEY:-}"
                    [[ -n "$val" ]] && export SUPABASE_SERVICE_KEY="$val"
                    ;;
                ANTHROPIC_API_KEY)
                    # Not required if Ollama is running
                    if curl -s --connect-timeout 1 "http://localhost:11434/api/tags" &>/dev/null; then
                        log "ANTHROPIC_API_KEY not set but Ollama is running (will use local scoring)"
                        export ANTHROPIC_API_KEY="ollama-fallback"
                        val="ollama-fallback"
                    fi
                    ;;
            esac
        fi
        if [[ -z "$val" ]]; then
            # Check if optional
            local is_optional=false
            for opt in "${optional_vars[@]}"; do
                [[ "$var" == "$opt" ]] && is_optional=true && break
            done
            if [[ "$is_optional" == "true" ]]; then
                warned+=("$var")
            else
                missing+=("$var")
            fi
        fi
    done

    if [[ ${#warned[@]} -gt 0 ]]; then
        log "WARNING: Optional env vars not set (features degraded): ${warned[*]}"
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing environment variables: ${missing[*]}"
        error "Set them in ~/.zshrc, max-ai-employee/.env, or export before running."
        exit 1
    fi
}

# ============================================================================
# Claude API
# ============================================================================

# call_claude_api <system_prompt> <user_prompt> [max_tokens]
# Returns the text response on stdout
call_claude_api() {
    local system_prompt="${1:?call_claude_api: system_prompt required}"
    local user_prompt="${2:?call_claude_api: user_prompt required}"
    local max_tokens="${3:-1024}"
    local model="${SCORING_MODEL:-claude-3-5-haiku-20251022}"
    local api_key="${ANTHROPIC_API_KEY:-}"

    if [[ -z "$api_key" ]]; then
        error "ANTHROPIC_API_KEY not set"
        return 1
    fi

    local payload
    payload=$(jq -n \
        --arg model "$model" \
        --arg system "$system_prompt" \
        --arg user "$user_prompt" \
        --argjson max_tokens "$max_tokens" \
        '{
            model: $model,
            max_tokens: $max_tokens,
            system: $system,
            messages: [{ role: "user", content: $user }]
        }')

    local response
    response=$(curl -s --connect-timeout 30 --max-time 120 \
        -X POST "https://api.anthropic.com/v1/messages" \
        -H "Content-Type: application/json" \
        -H "x-api-key: $api_key" \
        -H "anthropic-version: 2023-06-01" \
        -d "$payload" 2>/dev/null)

    if [[ -z "$response" ]]; then
        error "Claude API returned empty response"
        return 1
    fi

    local error_type
    error_type=$(echo "$response" | jq -r '.error.type // empty' 2>/dev/null)
    if [[ -n "$error_type" ]]; then
        local error_msg
        error_msg=$(echo "$response" | jq -r '.error.message // "unknown error"' 2>/dev/null)
        error "Claude API error ($error_type): $error_msg"
        return 1
    fi

    echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null
}

# call_ollama <system_prompt> <user_prompt> [max_tokens]
# Falls back to Claude API if Ollama is not available
call_ollama() {
    local system_prompt="${1:?}"
    local user_prompt="${2:?}"
    local max_tokens="${3:-1024}"

    # Try Ollama first (local)
    if curl -s --connect-timeout 2 "http://localhost:11434/api/tags" &>/dev/null; then
        local payload
        payload=$(jq -n \
            --arg system "$system_prompt" \
            --arg user "$user_prompt" \
            --argjson max_tokens "$max_tokens" \
            '{
                model: "llama3.2",
                messages: [
                    { role: "system", content: $system },
                    { role: "user", content: $user }
                ],
                stream: false,
                options: { num_predict: $max_tokens }
            }')

        local response
        response=$(curl -s --connect-timeout 10 --max-time 120 \
            -X POST "http://localhost:11434/api/chat" \
            -d "$payload" 2>/dev/null)

        local content
        content=$(echo "$response" | jq -r '.message.content // empty' 2>/dev/null)
        if [[ -n "$content" ]]; then
            echo "$content"
            return 0
        fi
    fi

    # Fallback to Claude
    log "Ollama not available, falling back to Claude API"
    call_claude_api "$system_prompt" "$user_prompt" "$max_tokens"
}

# ============================================================================
# Rube API (Composio MCP)
# ============================================================================

# rube_execute <tool_slug> <arguments_json> [description]
# Returns the tool response on stdout
rube_execute() {
    local tool_slug="${1:?rube_execute: tool_slug required}"
    local arguments="${2:?rube_execute: arguments JSON required}"
    local description="${3:-$tool_slug}"
    local rube_token="${RUBE_TOKEN:-${RUBE_API_KEY:-}}"

    if [[ -z "$rube_token" ]]; then
        error "RUBE_TOKEN not set"
        return 1
    fi

    log "Rube: executing $tool_slug ($description)"

    local payload
    payload=$(jq -n \
        --arg slug "$tool_slug" \
        --argjson args "$arguments" \
        '{
            tool_slug: $slug,
            arguments: $args
        }')

    local response
    response=$(curl -s --connect-timeout 30 --max-time 180 \
        -X POST "https://mcp.composio.dev/api/v1/execute" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $rube_token" \
        -d "$payload" 2>/dev/null)

    if [[ -z "$response" ]]; then
        error "Rube API returned empty response for $tool_slug"
        return 1
    fi

    local success
    success=$(echo "$response" | jq -r '.successful // false' 2>/dev/null)
    if [[ "$success" != "true" ]]; then
        local err_msg
        err_msg=$(echo "$response" | jq -r '.error // "unknown error"' 2>/dev/null)
        error "Rube API error for $tool_slug: $err_msg"
        # Fail-open: return the response anyway so callers can inspect it
    fi

    echo "$response"
}

# ============================================================================
# Supabase
# ============================================================================

# supabase_query <endpoint> <method> [data]
# endpoint: table name or RPC path (e.g., "leads", "rpc/my_function", "leads?id=eq.123")
# method: GET, POST, PATCH, DELETE
# data: JSON body (for POST/PATCH)
supabase_query() {
    local endpoint="${1:?supabase_query: endpoint required}"
    local method="${2:-GET}"
    local data="${3:-}"
    local url="${SUPABASE_URL:-}"
    local key="${SUPABASE_SERVICE_KEY:-${SUPABASE_SERVICE_ROLE_KEY:-}}"

    if [[ -z "$url" || -z "$key" ]]; then
        error "SUPABASE_URL or SUPABASE_SERVICE_KEY not set"
        return 1
    fi

    local full_url="${url}/rest/v1/${endpoint}"

    local curl_args=(
        -s --connect-timeout 10 --max-time 30
        -X "$method"
        -H "apikey: $key"
        -H "Authorization: Bearer $key"
        -H "Content-Type: application/json"
        -H "Prefer: return=representation"
    )

    if [[ -n "$data" && ("$method" == "POST" || "$method" == "PATCH") ]]; then
        curl_args+=(-d "$data")
    fi

    # For upserts
    if [[ "$method" == "POST" ]]; then
        curl_args+=(-H "Prefer: resolution=merge-duplicates,return=representation")
    fi

    local response
    response=$(curl "${curl_args[@]}" "$full_url" 2>/dev/null)

    if [[ -z "$response" ]]; then
        error "Supabase returned empty response for $method $endpoint"
        return 1
    fi

    echo "$response"
}

# ============================================================================
# Telegram
# ============================================================================

# send_telegram_message <text> [parse_mode]
send_telegram_message() {
    local text="${1:?send_telegram_message: text required}"
    local parse_mode="${2:-Markdown}"
    local bot_token="${TELEGRAM_BOT_TOKEN:-}"
    local chat_id="${TELEGRAM_CHAT_ID:-8076125560}"

    if [[ -z "$bot_token" ]]; then
        log "TELEGRAM_BOT_TOKEN not set, skipping Telegram message"
        log "Message would have been: ${text:0:100}..."
        return 0
    fi

    local payload
    payload=$(jq -n \
        --arg chat_id "$chat_id" \
        --arg text "$text" \
        --arg parse_mode "$parse_mode" \
        '{
            chat_id: $chat_id,
            text: $text,
            parse_mode: $parse_mode,
            disable_web_page_preview: true
        }')

    local response
    response=$(curl -s --connect-timeout 10 --max-time 15 \
        -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>/dev/null)

    local ok
    ok=$(echo "$response" | jq -r '.ok // false' 2>/dev/null)
    if [[ "$ok" != "true" ]]; then
        local desc
        desc=$(echo "$response" | jq -r '.description // "unknown error"' 2>/dev/null)
        error "Telegram send failed: $desc"
        return 1
    fi

    echo "$response"
}

# ============================================================================
# Deduplication
# ============================================================================

# generate_fingerprint <string>
# Returns an MD5 hash for dedup purposes
generate_fingerprint() {
    local input="${1:?generate_fingerprint: input required}"

    if command -v md5 &>/dev/null; then
        echo -n "$input" | md5
    elif command -v md5sum &>/dev/null; then
        echo -n "$input" | md5sum | awk '{print $1}'
    else
        # Fallback: use shasum
        echo -n "$input" | shasum -a 256 | awk '{print $1}'
    fi
}

# ============================================================================
# Browser Automation Handoff
# ============================================================================

# execute_browser_comments <pending_file> <platform>
# Writes instructions for Claude Code browser automation to pick up
execute_browser_comments() {
    local pending_file="${1:?execute_browser_comments: pending_file required}"
    local platform="${2:-reddit}"
    local handoff_dir="${HOME}/.max-ai/browser-queue"
    mkdir -p "$handoff_dir"

    if [[ ! -f "$pending_file" ]]; then
        error "Pending file not found: $pending_file"
        return 1
    fi

    local count
    count=$(jq 'length' "$pending_file" 2>/dev/null || echo "0")

    if [[ "$count" -eq 0 ]]; then
        log "No pending comments to post"
        return 0
    fi

    local queue_file="${handoff_dir}/${platform}-comments-$(date +%Y%m%d-%H%M%S).json"
    cp "$pending_file" "$queue_file"

    log "Queued $count $platform comments for browser automation: $queue_file"
    echo "$queue_file"
}

# ============================================================================
# Corrections Library (optional learning from edits)
# ============================================================================

# get_correction_rules <post_text> [limit]
# Returns correction patterns from Supabase (if table exists), or empty array
get_correction_rules() {
    local post_text="${1:-}"
    local limit="${2:-5}"

    if [[ "$DRY_RUN" == "true" || -z "$SUPABASE_URL" ]]; then
        echo "[]"
        return 0
    fi

    local response
    response=$(supabase_query "correction_rules?select=*&limit=${limit}&order=created_at.desc" "GET" 2>/dev/null)

    if [[ -z "$response" || "$response" == "null" ]]; then
        echo "[]"
        return 0
    fi

    # Check if it's an error (table doesn't exist)
    local is_error
    is_error=$(echo "$response" | jq -r '.code // empty' 2>/dev/null)
    if [[ -n "$is_error" ]]; then
        echo "[]"
        return 0
    fi

    echo "$response"
}

# store_correction <platform> <action> <post_text> <author> <draft> <edited> <source_id> <audit_table> [extra_data]
store_correction() {
    local platform="${1:-}"
    local action="${2:-}"
    local post_text="${3:-}"
    local author="${4:-}"
    local draft="${5:-}"
    local edited="${6:-}"
    local source_id="${7:-}"
    local audit_table="${8:-audit_log}"
    local extra_data="${9:-{\}}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would store correction for $platform $action"
        return 0
    fi

    local payload
    payload=$(jq -n \
        --arg platform "$platform" \
        --arg action "$action" \
        --arg post_text "${post_text:0:500}" \
        --arg author "$author" \
        --arg draft "$draft" \
        --arg edited "$edited" \
        --arg source_id "$source_id" \
        --arg user_id "${USER_ID:-}" \
        '{
            platform: $platform,
            action: $action,
            post_text: $post_text,
            author: $author,
            draft_text: $draft,
            edited_text: $edited,
            source_id: $source_id,
            user_id: $user_id,
            created_at: (now | todate)
        }')

    supabase_query "$audit_table" "POST" "$payload" >/dev/null 2>&1 || true
}

# ============================================================================
# Environment Auto-Loader
# ============================================================================

# Auto-load .env if it exists and vars aren't already set
_load_env() {
    local env_file="${HOME}/max-ai-employee/.env"
    if [[ -f "$env_file" ]]; then
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            # Strip quotes from value
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"
            # Only set if not already set
            if [[ -z "${!key:-}" ]]; then
                export "$key=$value"
            fi
        done < "$env_file"
    fi
}

# Auto-load on source
_load_env
