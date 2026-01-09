#!/bin/bash
# ElevenLabs TTS Voice Notification Script
# Speaks messages immediately without saving to disk

speak() {
    local message="$1"
    local temp_file="/tmp/tts_$(date +%s).mp3"

    # Use ElevenLabs TTS API to generate audio
    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM" \
      -H "xi-api-key: sk_d227dd8dd7701a491431a052f560bfaa6e5078005b22f003" \
      -H "Content-Type: application/json" \
      -d "{\"text\": \"$message\", \"model_id\": \"eleven_monolingual_v1\"}" \
      -o "$temp_file" 2>/dev/null

    # Play audio and clean up after it finishes
    if [ -f "$temp_file" ] && [ -s "$temp_file" ]; then
        afplay "$temp_file" 2>/dev/null
        rm -f "$temp_file"
    else
        # Fallback to macOS say if ElevenLabs fails
        say "$message" &
    fi
}

# Call the speak function with all arguments
speak "$@"
