#!/bin/bash
# ElevenLabs TTS Voice Notification Script
# Speaks messages with optional speed control
# Handles long text by chunking

# Configuration
SPEED=${TTS_SPEED:-1.15}  # Default 1.15x speed (change in ~/.claude/.env)
MAX_CHARS=4500            # ElevenLabs limit is ~5000, use 4500 for safety

# Source env file if API key not already set
if [ -z "$ELEVENLABS_API_KEY" ] && [ -f ~/.claude/.env ]; then
    source ~/.claude/.env
fi

# Find ffmpeg once
find_ffmpeg() {
    if command -v ffmpeg &> /dev/null; then
        echo "ffmpeg"
    elif [ -x /opt/homebrew/bin/ffmpeg ]; then
        echo "/opt/homebrew/bin/ffmpeg"
    elif [ -x /usr/local/bin/ffmpeg ]; then
        echo "/usr/local/bin/ffmpeg"
    fi
}

FFMPEG=$(find_ffmpeg)

speak_chunk() {
    local message="$1"
    local temp_file="/tmp/tts_$(date +%s%N).mp3"
    local fast_file="/tmp/tts_fast_$(date +%s%N).mp3"

    # Check for API key
    if [ -z "$ELEVENLABS_API_KEY" ]; then
        # Fallback to macOS say with speed
        local rate=$(echo "$SPEED * 180" | bc | cut -d. -f1)
        say -r "$rate" "$message"
        return
    fi

    # Escape message for JSON
    local escaped_message=$(echo "$message" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')

    # Use ElevenLabs TTS API to generate audio
    curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM" \
      -H "xi-api-key: $ELEVENLABS_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"text\": $escaped_message, \"model_id\": \"eleven_monolingual_v1\"}" \
      -o "$temp_file" 2>/dev/null

    # Check if file was created and is valid audio
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        # Fallback to macOS say
        local rate=$(echo "$SPEED * 180" | bc | cut -d. -f1)
        say -r "$rate" "$message"
        rm -f "$temp_file"
        return
    fi

    # Check if response is an error (JSON instead of audio)
    if head -c 1 "$temp_file" | grep -q '{'; then
        echo "ElevenLabs error: $(cat $temp_file)" >> /tmp/hammerspoon_speak.log
        local rate=$(echo "$SPEED * 180" | bc | cut -d. -f1)
        say -r "$rate" "$message"
        rm -f "$temp_file"
        return
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

speak() {
    local message="$1"
    local length=${#message}

    # Log the request
    echo "$(date): Text length: $length" >> /tmp/hammerspoon_speak.log

    # If short enough, speak directly
    if [ $length -le $MAX_CHARS ]; then
        speak_chunk "$message"
        return
    fi

    # Text is too long - chunk it
    local num_chunks=$(( (length + MAX_CHARS - 1) / MAX_CHARS ))
    echo "$(date): Chunking into $num_chunks parts" >> /tmp/hammerspoon_speak.log

    # Notify user about chunking (macOS notification)
    osascript -e "display notification \"Text is ${length} chars. Playing in ${num_chunks} chunks...\" with title \"Speaking Long Text\"" 2>/dev/null

    local offset=0
    local chunk_num=1

    while [ $offset -lt $length ]; do
        local chunk="${message:$offset:$MAX_CHARS}"

        # Try to break at sentence or word boundary
        if [ ${#chunk} -eq $MAX_CHARS ] && [ $((offset + MAX_CHARS)) -lt $length ]; then
            # Look for last sentence break
            local last_period=$(echo "$chunk" | grep -ob '\. ' | tail -1 | cut -d: -f1)
            local last_newline=$(echo "$chunk" | grep -ob $'\n' | tail -1 | cut -d: -f1)

            local break_at=""
            if [ -n "$last_period" ] && [ "$last_period" -gt $((MAX_CHARS / 2)) ]; then
                break_at=$((last_period + 2))
            elif [ -n "$last_newline" ] && [ "$last_newline" -gt $((MAX_CHARS / 2)) ]; then
                break_at=$((last_newline + 1))
            fi

            if [ -n "$break_at" ]; then
                chunk="${message:$offset:$break_at}"
            fi
        fi

        echo "$(date): Speaking chunk $chunk_num/${num_chunks} (${#chunk} chars)" >> /tmp/hammerspoon_speak.log
        speak_chunk "$chunk"

        offset=$((offset + ${#chunk}))
        chunk_num=$((chunk_num + 1))
    done

    # Notify completion
    osascript -e "display notification \"Finished reading ${num_chunks} chunks\" with title \"Done Speaking\"" 2>/dev/null
}

# Call the speak function with all arguments
speak "$@"
