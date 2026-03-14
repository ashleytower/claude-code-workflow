#!/usr/bin/env bash
# Self-improving agent: consolidate session errors into semantic patterns.
# Runs as Stop hook. Summarizes today's errors for future sessions.
set -uo pipefail

MEMORY_DIR="$HOME/.claude/skills/self-improving-agent/memory"
EPISODIC_DIR="$MEMORY_DIR/episodic"
SEMANTIC_FILE="$MEMORY_DIR/semantic-patterns.json"

mkdir -p "$MEMORY_DIR"

TODAY=$(date +%Y-%m-%d)
EPISODIC_FILE="$EPISODIC_DIR/${TODAY}-errors.jsonl"

# Only run if there were errors today
if [[ ! -s "$EPISODIC_FILE" ]]; then
    exit 0
fi

ERROR_COUNT=$(wc -l < "$EPISODIC_FILE" | tr -d ' ')
if [[ "$ERROR_COUNT" -eq 0 ]]; then
    exit 0
fi

# Initialize semantic patterns file if missing
if [[ ! -f "$SEMANTIC_FILE" ]]; then
    echo '{"patterns":[],"last_updated":"'$TODAY'"}' > "$SEMANTIC_FILE"
fi

# Extract unique error commands from today for the session summary
UNIQUE_ERRORS=$(python3 -c "
import json, sys, collections
errors = []
with open('$EPISODIC_FILE') as f:
    for line in f:
        line = line.strip()
        if line:
            try:
                errors.append(json.loads(line))
            except:
                pass

# Group by command prefix (first word)
cmds = collections.Counter()
for e in errors:
    cmd = e.get('command','').split()[0] if e.get('command','').strip() else 'unknown'
    cmds[cmd] += 1

for cmd, count in cmds.most_common(10):
    print(f'{count}x {cmd}')
" 2>/dev/null)

# Write session summary to working memory
WORKING_DIR="$MEMORY_DIR/working"
mkdir -p "$WORKING_DIR"
echo "Session $(date +%H:%M): $ERROR_COUNT error(s) captured" > "$WORKING_DIR/last-session.txt"
if [[ -n "$UNIQUE_ERRORS" ]]; then
    echo "$UNIQUE_ERRORS" >> "$WORKING_DIR/last-session.txt"
fi
