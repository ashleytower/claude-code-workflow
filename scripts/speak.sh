#!/bin/bash
# ElevenLabs TTS Voice Notification Script
# Speaks messages with optional speed control

# Configuration
SPEED=${TTS_SPEED:-1.15}  # Default 1.15x speed (change in ~/.claude/.env)

# Source env file if API key not already set
if [ -z "$ELEVENLABS_API_KEY" ] && [ -f ~/.claude/.env ]; then
    source ~/.claude/.env
fi

speak() {
    local message="$1"
    local temp_file="/tmp/tts_$(date +%s).mp3"
    local fast_file="/tmp/tts_fast_$(date +%s).mp3"

    # Check for API key
    if [ -z "$ELEVENLABS_API_KEY" ]; then
        # Fallback to macOS say with speed (words per minute, 200 = 1.1x)
        local rate=$(echo "$SPEED * 180" | bc | cut -d. -f1)
        say -r "$rate" "$message" &
        return
    fi

    # Use ElevenLabs TTS API to generate audio
    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM" \
      -H "xi-api-key: $ELEVENLABS_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"text\": \"$message\", \"model_id\": \"eleven_monolingual_v1\"}" \
      -o "$temp_file" 2>/dev/null

    # Check if file was created
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        # Fallback to macOS say
        local rate=$(echo "$SPEED * 180" | bc | cut -d. -f1)
        say -r "$rate" "$message" &
        return
    fi

    # Find ffmpeg (check Homebrew paths)
    FFMPEG=""
    if command -v ffmpeg &> /dev/null; then
        FFMPEG="ffmpeg"
    elif [ -x /opt/homebrew/bin/ffmpeg ]; then
        FFMPEG="/opt/homebrew/bin/ffmpeg"
    elif [ -x /usr/local/bin/ffmpeg ]; then
        FFMPEG="/usr/local/bin/ffmpeg"
    fi

    # Speed up with ffmpeg if available and speed != 1.0
    if [ -n "$FFMPEG" ] && [ "$SPEED" != "1.0" ] && [ "$SPEED" != "1" ]; then
        "$FFMPEG" -y -i "$temp_file" -filter:a "atempo=$SPEED" "$fast_file" 2>/dev/null
        if [ -f "$fast_file" ] && [ -s "$fast_file" ]; then
            afplay "$fast_file" 2>/dev/null
            rm -f "$fast_file"
        else
            afplay "$temp_file" 2>/dev/null
        fi
    else
        afplay "$temp_file" 2>/dev/null
    fi

    rm -f "$temp_file"
}

# Call the speak function with all arguments
speak "$@"
