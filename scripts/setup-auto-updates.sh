#!/bin/bash
# Set up all auto-update cron jobs

echo "Setting up auto-update cron jobs..."

# Get current crontab (if any)
TEMP_CRON=$(mktemp)
crontab -l 2>/dev/null > "$TEMP_CRON" || true

# Remove any existing claude cron jobs
grep -v "\.claude" "$TEMP_CRON" > "$TEMP_CRON.new" || true
mv "$TEMP_CRON.new" "$TEMP_CRON"

# Add new cron jobs
cat >> "$TEMP_CRON" << 'CRONEOF'
# Claude Code auto-updates

# Auth docs: Every Sunday at 3 AM
0 3 * * 0 ~/.claude/scripts/update-auth-docs.sh >> ~/.claude/logs/auth-updates.log 2>&1

# LLM Council: Daily at 2 AM
0 2 * * * ~/.claude/scripts/update-llm-council.sh >> ~/.claude/logs/llm-council-updates.log 2>&1

# Self-update check: Daily at 1 AM
0 1 * * * ~/.claude/scripts/self-update.sh >> ~/.claude/logs/self-updates.log 2>&1

# Cleanup old backups: Weekly on Monday at 4 AM
0 4 * * 1 find ~/.claude/backups -type d -mtime +30 -exec rm -rf {} + 2>/dev/null

CRONEOF

# Install new crontab
crontab "$TEMP_CRON"
rm "$TEMP_CRON"

echo ""
echo "✓ Cron jobs installed:"
echo ""
crontab -l | grep -A10 "Claude Code"

# Create logs directory
mkdir -p ~/.claude/logs

echo ""
echo "Logs will be written to:"
echo "  - ~/.claude/logs/auth-updates.log"
echo "  - ~/.claude/logs/llm-council-updates.log"
echo "  - ~/.claude/logs/self-updates.log"
echo ""
echo "Manual triggers:"
echo "  ~/.claude/scripts/update-auth-docs.sh"
echo "  ~/.claude/scripts/update-llm-council.sh"
echo "  ~/.claude/scripts/self-update.sh"
