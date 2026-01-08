#!/bin/bash
# Weekly auth documentation update

AUTH_SKILL="$HOME/.claude/skills/auth.md"
BACKUP_DIR="$HOME/.claude/backups"
LOG_FILE="$HOME/.claude/logs/auth-updates.log"

mkdir -p "$BACKUP_DIR" "$HOME/.claude/logs"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Backup current version
backup_current() {
    if [ -f "$AUTH_SKILL" ]; then
        cp "$AUTH_SKILL" "$BACKUP_DIR/auth-$(date +%Y%m%d).md"
        log "Backed up current auth skill"
    fi
}

# Fetch latest versions
check_updates() {
    log "Checking for auth solution updates..."

    # Check Clerk version
    CLERK_LATEST=$(npm view @clerk/nextjs version 2>/dev/null)
    log "Clerk latest: $CLERK_LATEST"

    # Check Supabase version
    SUPABASE_LATEST=$(npm view @supabase/supabase-js version 2>/dev/null)
    log "Supabase latest: $SUPABASE_LATEST"

    # Check NextAuth version
    NEXTAUTH_LATEST=$(npm view next-auth version 2>/dev/null)
    log "NextAuth latest: $NEXTAUTH_LATEST"

    # Update the skill file with latest versions
    if [ -f "$AUTH_SKILL" ]; then
        # Update last updated date
        sed -i '' "s/\*\*Last updated\*\*:.*/\*\*Last updated\*\*: $(date +%Y-%m-%d)/" "$AUTH_SKILL"
        log "Updated auth skill with current date"
    fi
}

# Check for breaking changes
check_breaking_changes() {
    log "Checking for breaking changes..."

    # Search for deprecation notices
    CLERK_CHANGES=$(curl -s "https://clerk.com/changelog" | grep -i "breaking\|deprecat" | head -3)
    SUPABASE_CHANGES=$(curl -s "https://supabase.com/docs/guides/auth" | grep -i "breaking\|deprecat" | head -3)

    if [ -n "$CLERK_CHANGES" ] || [ -n "$SUPABASE_CHANGES" ]; then
        log "Breaking changes detected!"
        log "Clerk: $CLERK_CHANGES"
        log "Supabase: $SUPABASE_CHANGES"

        # Voice alert
        if [ -f "$HOME/.claude/scripts/speak.sh" ]; then
            "$HOME/.claude/scripts/speak.sh" "Auth breaking changes detected" &
        fi
    fi
}

# Main update process
main() {
    log "Starting auth docs weekly update"

    backup_current
    check_updates
    check_breaking_changes

    log "Auth docs update complete"
    log "---"
}

main "$@"
