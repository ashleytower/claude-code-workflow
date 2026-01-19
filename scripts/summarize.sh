#!/bin/bash
# Summarize text using Claude Haiku via OpenRouter, then speak it

# Source env file
if [ -f ~/.claude/.env ]; then
    source ~/.claude/.env
fi

# Check for API key
if [ -z "$OPENROUTER_API_KEY" ]; then
    ~/.claude/scripts/speak.sh "OpenRouter API key not set"
    exit 1
fi

TEXT="$1"

if [ -z "$TEXT" ]; then
    ~/.claude/scripts/speak.sh "No text provided"
    exit 1
fi

# Escape text for JSON
ESCAPED_TEXT=$(echo "$TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g' | tr '\n' ' ')

# Call OpenRouter with Claude Haiku (cheap and fast)
RESPONSE=$(curl -s "https://openrouter.ai/api/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -d "{
    \"model\": \"anthropic/claude-3-haiku\",
    \"messages\": [
      {
        \"role\": \"user\",
        \"content\": \"Summarize this in 1-2 sentences, be concise:\\n\\n$ESCAPED_TEXT\"
      }
    ],
    \"max_tokens\": 150
  }")

# Extract the summary from response
SUMMARY=$(echo "$RESPONSE" | grep -o '"content":"[^"]*"' | head -1 | sed 's/"content":"//; s/"$//')

if [ -z "$SUMMARY" ]; then
    ~/.claude/scripts/speak.sh "Could not summarize the text"
    exit 1
fi

# Speak the summary
~/.claude/scripts/speak.sh "$SUMMARY"
