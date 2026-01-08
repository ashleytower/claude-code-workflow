#!/bin/bash

# Update LLM Council - Keep model IDs up to date
# Checks OpenRouter for latest model versions and updates config

set -e

CONFIG_FILE="$HOME/.claude/config/llm-council.json"
BACKUP_FILE="$HOME/.claude/config/llm-council.backup.json"
LOG_FILE="$HOME/.claude/logs/llm-council-updates.log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[LLM Council]${NC} $1"
    echo "[$(date)] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[LLM Council]${NC} $1"
    echo "[$(date)] SUCCESS: $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[LLM Council]${NC} $1"
    echo "[$(date)] WARNING: $1" >> "$LOG_FILE"
}

# Backup current config
backup_config() {
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        log "Backed up current config"
    fi
}

# Fetch latest models from OpenRouter
fetch_latest_models() {
    log "Fetching latest models from OpenRouter..."

    if [ -z "$OPENROUTER_API_KEY" ]; then
        log_warning "OPENROUTER_API_KEY not set. Cannot fetch latest models."
        return 1
    fi

    # Fetch models from OpenRouter API
    MODELS_JSON=$(curl -s "https://openrouter.ai/api/v1/models" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "Content-Type: application/json")

    if [ $? -ne 0 ]; then
        log_warning "Failed to fetch models from OpenRouter"
        return 1
    fi

    echo "$MODELS_JSON" > /tmp/openrouter-models.json
    log_success "Fetched latest models"
}

# Find latest version of a model
find_latest_version() {
    local provider=$1
    local model_name=$2

    # Search for model in fetched data
    LATEST=$(jq -r ".data[] | select(.id | contains(\"$provider/$model_name\")) | .id" /tmp/openrouter-models.json | head -1)

    if [ -n "$LATEST" ]; then
        echo "$LATEST"
    else
        echo ""
    fi
}

# Update config with latest models
update_config() {
    log "Checking for model updates..."

    # Read current config
    CURRENT_OPUS=$(jq -r '.models.opus.openrouter_id' "$CONFIG_FILE")
    CURRENT_GPT=$(jq -r '.models.gpt.openrouter_id' "$CONFIG_FILE")
    CURRENT_GEMINI=$(jq -r '.models.gemini.openrouter_id' "$CONFIG_FILE")
    CURRENT_GROK=$(jq -r '.models.grok.openrouter_id' "$CONFIG_FILE")
    CURRENT_SONNET=$(jq -r '.models.sonnet.openrouter_id' "$CONFIG_FILE")

    # Find latest versions
    LATEST_OPUS=$(find_latest_version "anthropic" "opus")
    LATEST_GPT=$(find_latest_version "openai" "gpt-5")
    LATEST_GEMINI=$(find_latest_version "google" "gemini")
    LATEST_GROK=$(find_latest_version "x-ai" "grok")
    LATEST_SONNET=$(find_latest_version "anthropic" "sonnet")

    UPDATES=0

    # Update Opus
    if [ -n "$LATEST_OPUS" ] && [ "$LATEST_OPUS" != "$CURRENT_OPUS" ]; then
        log_success "Opus updated: $CURRENT_OPUS → $LATEST_OPUS"
        jq ".models.opus.openrouter_id = \"$LATEST_OPUS\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
        UPDATES=$((UPDATES + 1))
    fi

    # Update GPT
    if [ -n "$LATEST_GPT" ] && [ "$LATEST_GPT" != "$CURRENT_GPT" ]; then
        log_success "GPT updated: $CURRENT_GPT → $LATEST_GPT"
        jq ".models.gpt.openrouter_id = \"$LATEST_GPT\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
        UPDATES=$((UPDATES + 1))
    fi

    # Update Gemini
    if [ -n "$LATEST_GEMINI" ] && [ "$LATEST_GEMINI" != "$CURRENT_GEMINI" ]; then
        log_success "Gemini updated: $CURRENT_GEMINI → $LATEST_GEMINI"
        jq ".models.gemini.openrouter_id = \"$LATEST_GEMINI\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
        UPDATES=$((UPDATES + 1))
    fi

    # Update Grok
    if [ -n "$LATEST_GROK" ] && [ "$LATEST_GROK" != "$CURRENT_GROK" ]; then
        log_success "Grok updated: $CURRENT_GROK → $LATEST_GROK"
        jq ".models.grok.openrouter_id = \"$LATEST_GROK\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
        UPDATES=$((UPDATES + 1))
    fi

    # Update Sonnet
    if [ -n "$LATEST_SONNET" ] && [ "$LATEST_SONNET" != "$CURRENT_SONNET" ]; then
        log_success "Sonnet updated: $CURRENT_SONNET → $LATEST_SONNET"
        jq ".models.sonnet.openrouter_id = \"$LATEST_SONNET\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"
        UPDATES=$((UPDATES + 1))
    fi

    # Update timestamp
    jq ".last_updated = \"$(date +%Y-%m-%d)\"" "$CONFIG_FILE" > /tmp/config.tmp && mv /tmp/config.tmp "$CONFIG_FILE"

    if [ $UPDATES -eq 0 ]; then
        log "No updates found. All models are current."
    else
        log_success "$UPDATES model(s) updated!"
    fi

    return $UPDATES
}

# Update agent files with new model IDs
update_agents() {
    log "Updating agent configurations..."

    # Read model IDs from config
    OPUS_ID=$(jq -r '.models.opus.openrouter_id' "$CONFIG_FILE")
    GPT_ID=$(jq -r '.models.gpt.openrouter_id' "$CONFIG_FILE")
    GEMINI_ID=$(jq -r '.models.gemini.openrouter_id' "$CONFIG_FILE")
    GROK_ID=$(jq -r '.models.grok.openrouter_id' "$CONFIG_FILE")
    SONNET_ID=$(jq -r '.models.sonnet.openrouter_id' "$CONFIG_FILE")

    # Update agents that use these models
    # @code-simplifier, @research-ui-patterns → Opus
    for agent in code-simplifier research-ui-patterns; do
        if [ -f "$HOME/.claude/agents/$agent.md" ]; then
            sed -i '' "s|^model:.*|model: $OPUS_ID|" "$HOME/.claude/agents/$agent.md"
            log "Updated @$agent to use $OPUS_ID"
        fi
    done

    # @backend → GPT
    if [ -f "$HOME/.claude/agents/backend.md" ]; then
        sed -i '' "s|^model:.*|model: $GPT_ID|" "$HOME/.claude/agents/backend.md"
        log "Updated @backend to use $GPT_ID"
    fi

    # @bash, @orchestrator → Gemini
    for agent in bash orchestrator; do
        if [ -f "$HOME/.claude/agents/$agent.md" ]; then
            sed -i '' "s|^model:.*|model: $GEMINI_ID|" "$HOME/.claude/agents/$agent.md"
            log "Updated @$agent to use $GEMINI_ID"
        fi
    done

    # @frontend, @react-native-expert, @verify-app → Sonnet
    for agent in frontend react-native-expert verify-app; do
        if [ -f "$HOME/.claude/agents/$agent.md" ]; then
            sed -i '' "s|^model:.*|model: $SONNET_ID|" "$HOME/.claude/agents/$agent.md"
            log "Updated @$agent to use $SONNET_ID"
        fi
    done

    log_success "Agent configurations updated"
}

# Voice notification
speak() {
    if [ -f "$HOME/.claude/scripts/speak.sh" ]; then
        "$HOME/.claude/scripts/speak.sh" "$1"
    fi
}

# Main
main() {
    log "Starting LLM Council update..."

    # Create log directory if needed
    mkdir -p "$HOME/.claude/logs"

    # Backup current config
    backup_config

    # Fetch latest models
    if fetch_latest_models; then
        # Update config
        if update_config; then
            # Update agent files
            update_agents

            log_success "✅ LLM Council update complete!"
            speak "LLM Council updated to latest models"
        else
            log_success "All models already up to date"
        fi
    else
        log_warning "Could not fetch latest models. Skipping update."
    fi

    # Cleanup
    rm -f /tmp/openrouter-models.json /tmp/config.tmp
}

main "$@"
