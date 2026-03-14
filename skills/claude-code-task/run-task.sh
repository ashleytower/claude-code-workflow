#!/bin/bash
# Run a Claude Code task in background, notify OpenClaw when done.
# Usage: run-task.sh <project_dir> <task_description> [session_key]
#
# Zero tokens while Claude Code works. Notification only on completion.

PROJECT_DIR="${1:-.}"
TASK="$2"
SESSION_KEY="${3:-}"
TASK_ID="cc-$(date +%s)"
OUTPUT_FILE="/tmp/${TASK_ID}-result.txt"

# Ensure project dir exists and has git
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR" || exit 1
[ -d .git ] || git init -q

# Register session
if [ -f "$HOME/.claude/skills/claude-code-task/session_registry.py" ]; then
    python3 -c "
from session_registry import SessionRegistry
import sys
sys.path.insert(0, '$HOME/.claude/skills/claude-code-task')
reg = SessionRegistry()
reg.register('$TASK_ID', label='${TASK:0:100}', project='$PROJECT_DIR')
" 2>/dev/null
fi

# Force Max plan OAuth (unset API key so Claude Code uses subscription)
unset ANTHROPIC_API_KEY

# Run Claude Code
claude -p "$TASK" \
  --dangerously-skip-permissions \
  --output-format text \
  > "$OUTPUT_FILE" 2>&1

EXIT_CODE=$?

# Truncate output for notification (first 2000 chars)
RESULT=$(head -c 2000 "$OUTPUT_FILE")
FULL_SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')

# Update session registry
if [ -f "$HOME/.claude/skills/claude-code-task/session_registry.py" ]; then
    python3 -c "
import sys
sys.path.insert(0, '$HOME/.claude/skills/claude-code-task')
from session_registry import SessionRegistry
reg = SessionRegistry()
reg.update('$TASK_ID', status='completed' if $EXIT_CODE == 0 else 'failed',
           metadata={'exit_code': $EXIT_CODE, 'output_file': '$OUTPUT_FILE', 'output_size': $FULL_SIZE})
" 2>/dev/null
fi

if [ $EXIT_CODE -eq 0 ]; then
    MSG="Claude Code task completed!\n\nTask: ${TASK:0:150}\nProject: $PROJECT_DIR\nResult (${FULL_SIZE} bytes):\n\n${RESULT}\n\nFull output: $OUTPUT_FILE"
else
    MSG="Claude Code task failed (exit $EXIT_CODE)\n\nTask: ${TASK:0:150}\nProject: $PROJECT_DIR\n\n${RESULT}"
fi

# Notify via gateway sessions_send (if session key provided)
if [ -n "$SESSION_KEY" ]; then
    TOKEN=$(python3 -c "import json; print(json.load(open('$HOME/.openclaw/openclaw.json'))['gateway']['auth']['token'])" 2>/dev/null)
    GW="http://localhost:18789"

    if [ -n "$TOKEN" ]; then
        python3 -c "
import json, urllib.request
msg = '''$MSG'''
data = json.dumps({
    'tool': 'sessions_send',
    'sessionKey': '$SESSION_KEY',
    'args': {'sessionKey': '$SESSION_KEY', 'message': msg}
}).encode()
req = urllib.request.Request('$GW/tools/invoke',
    data=data,
    headers={'Authorization': 'Bearer $TOKEN', 'Content-Type': 'application/json'})
try:
    urllib.request.urlopen(req, timeout=30)
except Exception:
    pass
" 2>/dev/null
    fi
fi

# Fallback: send via Telegram if no session key
if [ -z "$SESSION_KEY" ]; then
    TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
    TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        # Escape for Telegram
        SAFE_MSG=$(echo -e "$MSG" | head -c 3500)
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d text="$SAFE_MSG" \
            -d parse_mode="" \
            > /dev/null 2>&1
    fi
fi

exit $EXIT_CODE
