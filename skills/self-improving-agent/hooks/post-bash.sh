#!/usr/bin/env bash
# Self-improving agent: capture bash errors to episodic memory.
# Runs as PostToolUse hook for Bash tool. Receives JSON on stdin.
set -uo pipefail

MEMORY_DIR="$HOME/.claude/skills/self-improving-agent/memory"
EPISODIC_DIR="$MEMORY_DIR/episodic"
mkdir -p "$EPISODIC_DIR"

# Read hook input from stdin (JSON with tool_name, tool_input, tool_output, exit_code)
INPUT=$(cat 2>/dev/null || echo '{}')

EXIT_CODE=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_result',{}).get('exitCode', d.get('exit_code',0)))" 2>/dev/null || echo "0")

# Only capture failures
if [[ "$EXIT_CODE" == "0" ]] || [[ -z "$EXIT_CODE" ]]; then
    exit 0
fi

COMMAND=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command','unknown'))" 2>/dev/null || echo "unknown")
OUTPUT=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); r=d.get('tool_result',{}); print(str(r.get('stdout',''))[:500])" 2>/dev/null || echo "")
STDERR=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); r=d.get('tool_result',{}); print(str(r.get('stderr',''))[:500])" 2>/dev/null || echo "")

TODAY=$(date +%Y-%m-%d)
EPISODIC_FILE="$EPISODIC_DIR/${TODAY}-errors.jsonl"

# Append error to today's episodic log (JSONL format, one entry per line)
python3 -c "
import json, datetime
entry = {
    'timestamp': datetime.datetime.now().isoformat(),
    'type': 'bash_error',
    'exit_code': int('${EXIT_CODE}'),
    'command': '''${COMMAND}'''[:200],
    'output': '''${OUTPUT}'''[:300],
    'stderr': '''${STDERR}'''[:300],
    'cwd': '$(pwd)'
}
print(json.dumps(entry))
" >> "$EPISODIC_FILE" 2>/dev/null

# Prune episodic files older than 14 days
find "$EPISODIC_DIR" -name "*.jsonl" -mtime +14 -delete 2>/dev/null || true
