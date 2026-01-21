#!/bin/bash

# Ask LLM Council - Query multiple models via OpenRouter
# Usage: ./ask-llm-council.sh "Your question here"

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config locations (check repo first, then home)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CONFIG="$SCRIPT_DIR/../config/llm-council.json"
HOME_CONFIG="$HOME/.claude/config/llm-council.json"

if [ -f "$REPO_CONFIG" ]; then
    CONFIG_FILE="$REPO_CONFIG"
elif [ -f "$HOME_CONFIG" ]; then
    CONFIG_FILE="$HOME_CONFIG"
else
    echo -e "${YELLOW}[Council]${NC} No config found. Using defaults."
    CONFIG_FILE=""
fi

# Check for API key
if [ -z "$OPENROUTER_API_KEY" ]; then
    echo -e "${YELLOW}[Council]${NC} OPENROUTER_API_KEY not set."
    echo "Set it with: export OPENROUTER_API_KEY='your-key-here'"
    exit 1
fi

# Get question from args
QUESTION="$*"
if [ -z "$QUESTION" ]; then
    echo "Usage: $0 \"Your question here\""
    exit 1
fi

# Temp directory for responses
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Get model IDs from config or use defaults
get_model_id() {
    local model_name=$1
    local default=$2

    if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
        local id=$(jq -r ".models.$model_name.openrouter_id // \"$default\"" "$CONFIG_FILE")
        echo "$id"
    else
        echo "$default"
    fi
}

OPUS_ID=$(get_model_id "opus" "anthropic/claude-3-opus")
GPT_ID=$(get_model_id "gpt" "openai/gpt-4-turbo")
GEMINI_ID=$(get_model_id "gemini" "google/gemini-pro")
GROK_ID=$(get_model_id "grok" "x-ai/grok-2")
SONNET_ID=$(get_model_id "sonnet" "anthropic/claude-3-sonnet")

echo -e "${BLUE}[Council]${NC} Querying 5 models via OpenRouter..."
echo ""

# Function to query a model
query_model() {
    local model_id=$1
    local model_name=$2
    local output_file=$3

    response=$(curl -s "https://openrouter.ai/api/v1/chat/completions" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "Content-Type: application/json" \
        -H "HTTP-Referer: https://github.com/claude-code-workflow" \
        -d "{
            \"model\": \"$model_id\",
            \"messages\": [{\"role\": \"user\", \"content\": $(echo "$QUESTION" | jq -Rs .)}],
            \"max_tokens\": 1000
        }" 2>/dev/null)

    # Extract content from response
    content=$(echo "$response" | jq -r '.choices[0].message.content // .error.message // "No response"')

    echo "$content" > "$output_file"
    echo -e "${GREEN}[Council]${NC} $model_name responded"
}

# Query all models in parallel
query_model "$OPUS_ID" "Opus" "$TEMP_DIR/opus.txt" &
query_model "$GPT_ID" "GPT" "$TEMP_DIR/gpt.txt" &
query_model "$GEMINI_ID" "Gemini" "$TEMP_DIR/gemini.txt" &
query_model "$GROK_ID" "Grok" "$TEMP_DIR/grok.txt" &
query_model "$SONNET_ID" "Sonnet" "$TEMP_DIR/sonnet.txt" &

# Wait for all queries to complete
wait

echo ""
echo "=============================================="
echo -e "${CYAN}LLM COUNCIL RESPONSES${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}Question:${NC} $QUESTION"
echo ""
echo "----------------------------------------------"
echo ""

# Display responses
echo -e "${CYAN}### Claude Opus 4.5${NC}"
echo ""
cat "$TEMP_DIR/opus.txt"
echo ""
echo "----------------------------------------------"
echo ""

echo -e "${CYAN}### GPT-5.2${NC}"
echo ""
cat "$TEMP_DIR/gpt.txt"
echo ""
echo "----------------------------------------------"
echo ""

echo -e "${CYAN}### Gemini Pro 3${NC}"
echo ""
cat "$TEMP_DIR/gemini.txt"
echo ""
echo "----------------------------------------------"
echo ""

echo -e "${CYAN}### Grok 2${NC}"
echo ""
cat "$TEMP_DIR/grok.txt"
echo ""
echo "----------------------------------------------"
echo ""

echo -e "${CYAN}### Claude Sonnet 4.5${NC}"
echo ""
cat "$TEMP_DIR/sonnet.txt"
echo ""
echo "=============================================="
echo -e "${GREEN}[Council]${NC} All responses collected"
