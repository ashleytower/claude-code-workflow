#!/bin/bash
# ElevenLabs TTS Voice Notification Script
# Speaks messages immediately without saving to disk

speak() {
    local message="$1"

    # Use ElevenLabs TTS API to generate and play audio immediately
    curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM" \
      -H "xi-api-key: sk_d227dd8dd7701a491431a052f560bfaa6e5078005b22f003" \
      -H "Content-Type: application/json" \
      -d "{\"text\": \"$message\", \"model_id\": \"eleven_monolingual_v1\"}" \
      --output - 2>/dev/null | afplay - 2>/dev/null
}

# Call the speak function with all arguments
speak "$@"
