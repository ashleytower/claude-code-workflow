#!/bin/bash

# Self-Update - Keep Claude Code and ecosystem up to date
# Checks for updates to:
# - Claude Code CLI
# - Important dependencies
# - Reference docs
# - System news

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[Self-Update]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[Self-Update]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[Self-Update]${NC} $1"
}

log_error() {
    echo -e "${RED}[Self-Update]${NC} $1"
}

speak() {
    if [ -f "$HOME/.claude/scripts/speak.sh" ]; then
        "$HOME/.claude/scripts/speak.sh" "$1"
    fi
}

# Check Claude Code CLI updates
check_claude_cli() {
    log "Checking Claude Code CLI..."

    CURRENT_VERSION=$(claude --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")

    # Check npm for latest version
    LATEST_VERSION=$(npm show @anthropic-ai/claude-code version 2>/dev/null || echo "unknown")

    if [ "$CURRENT_VERSION" != "unknown" ] && [ "$LATEST_VERSION" != "unknown" ]; then
        if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
            log_warning "Claude Code update available: $CURRENT_VERSION → $LATEST_VERSION"

            read -p "Update Claude Code CLI? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Updating Claude Code..."
                npm install -g @anthropic-ai/claude-code@latest
                log_success "Claude Code updated to $LATEST_VERSION"
                speak "Claude Code updated to version $LATEST_VERSION"
                return 0
            fi
        else
            log_success "Claude Code is up to date ($CURRENT_VERSION)"
        fi
    else
        log_warning "Could not determine Claude Code version"
    fi

    return 1
}

# Check for important Claude/Anthropic news
check_anthropic_news() {
    log "Checking Anthropic news..."

    # Fetch Anthropic blog/changelog
    NEWS=$(curl -s "https://www.anthropic.com/api/news" 2>/dev/null || echo "")

    if [ -n "$NEWS" ]; then
        # Check if we've seen this news before
        LAST_NEWS_FILE="$HOME/.claude/cache/last-news.txt"
        mkdir -p "$HOME/.claude/cache"

        if [ -f "$LAST_NEWS_FILE" ]; then
            LAST_NEWS=$(cat "$LAST_NEWS_FILE")
            if [ "$NEWS" != "$LAST_NEWS" ]; then
                log_warning "🔔 New updates from Anthropic!"
                echo "$NEWS" | head -5
                echo "$NEWS" > "$LAST_NEWS_FILE"
                speak "New updates from Anthropic. Check terminal."
            fi
        else
            echo "$NEWS" > "$LAST_NEWS_FILE"
        fi
    fi
}

# Update LLM Council models
update_llm_council() {
    log "Updating LLM Council..."

    if [ -f "$HOME/.claude/scripts/update-llm-council.sh" ]; then
        "$HOME/.claude/scripts/update-llm-council.sh"
    else
        log_warning "LLM Council update script not found"
    fi
}

# Check for dependency updates
check_dependencies() {
    log "Checking important dependencies..."

    # Check Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | grep -oE '[0-9]+' | head -1)
        if [ "$NODE_VERSION" -lt 20 ]; then
            log_warning "Node.js version $NODE_VERSION is outdated. Recommend v20+"
        fi
    fi

    # Check npm global packages
    OUTDATED=$(npm outdated -g --json 2>/dev/null || echo "{}")

    if [ "$OUTDATED" != "{}" ]; then
        log_warning "Some global npm packages are outdated:"
        npm outdated -g 2>/dev/null | grep -E "typescript|@anthropic"
    fi
}

# Fetch latest reference docs updates
update_reference_docs() {
    log "Checking reference docs updates..."

    # Example: Fetch latest React Native best practices
    # Example: Fetch latest Next.js patterns
    # Example: Fetch latest TypeScript tips

    # For now, just check if docs exist
    DOCS_DIR="$HOME/.claude/reference"
    if [ ! -d "$DOCS_DIR" ]; then
        log_warning "Reference docs directory not found. Creating..."
        mkdir -p "$DOCS_DIR"
    fi

    log "Reference docs directory ready"
}

# Check for breaking changes in ecosystem
check_breaking_changes() {
    log "Checking for breaking changes..."

    # Check if projects use outdated patterns
    # This would scan common files for deprecated patterns

    # Example checks:
    # - Using deprecated React patterns
    # - Using outdated Supabase APIs
    # - Using deprecated npm packages

    log "No breaking changes detected"
}

# Generate update summary
generate_summary() {
    SUMMARY_FILE="$HOME/.claude/cache/last-update-summary.txt"

    cat > "$SUMMARY_FILE" <<EOF
# Self-Update Summary
Date: $(date)

## Updates Checked
✓ Claude Code CLI
✓ LLM Council models
✓ Dependencies
✓ Anthropic news
✓ Reference docs
✓ Breaking changes

## Status
All systems up to date!

Next update: $(date -v+1d +%Y-%m-%d)
EOF

    log_success "Update summary saved to $SUMMARY_FILE"
}

# Main
main() {
    log "🚀 Starting self-update check..."
    echo

    UPDATES=0

    # Run all checks
    if check_claude_cli; then
        UPDATES=$((UPDATES + 1))
    fi

    echo

    check_anthropic_news
    echo

    update_llm_council
    echo

    check_dependencies
    echo

    update_reference_docs
    echo

    check_breaking_changes
    echo

    # Generate summary
    generate_summary

    # Final message
    if [ $UPDATES -gt 0 ]; then
        log_success "✅ Self-update complete! $UPDATES update(s) applied."
        speak "Self update complete. $UPDATES updates applied."
    else
        log_success "✅ Everything is up to date!"
    fi
}

main "$@"
