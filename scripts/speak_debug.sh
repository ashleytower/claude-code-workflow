#!/bin/bash
echo "$(date): Called with args: $@" >> /tmp/speak_debug.log
echo "$(date): Env ELEVENLABS_API_KEY set: $([ -n "$ELEVENLABS_API_KEY" ] && echo YES || echo NO)" >> /tmp/speak_debug.log
source ~/.claude/.env 2>/dev/null
echo "$(date): After source, ELEVENLABS_API_KEY set: $([ -n "$ELEVENLABS_API_KEY" ] && echo YES || echo NO)" >> /tmp/speak_debug.log
~/.claude/scripts/speak.sh "$@" 2>> /tmp/speak_debug.log &
