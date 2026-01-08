#!/bin/bash
# Set up weekly cron job for auth docs update

echo "Setting up weekly auth docs update cron job..."

# Add to crontab (runs every Sunday at 3 AM)
(crontab -l 2>/dev/null; echo "0 3 * * 0 $HOME/.claude/scripts/update-auth-docs.sh") | crontab -

echo "Cron job added:"
crontab -l | grep update-auth-docs

echo ""
echo "Auth docs will update every Sunday at 3 AM"
echo "Manual update: ~/.claude/scripts/update-auth-docs.sh"
