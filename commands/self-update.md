---
name: self-update
description: Update Claude Code and all systems
model: sonnet
---

# Self-Update - Stay Current Automatically

Comprehensive update system that keeps Claude Code, LLM models, dependencies, and knowledge up to date.

## What Gets Updated

### 1. Claude Code CLI

```bash
# Check for new versions
Current: 1.2.3
Latest:  1.3.0

# Auto-update if available
npm install -g @anthropic-ai/claude-code@latest
```

### 2. LLM Council Models

```bash
# Update to latest model versions
Opus 4.5 → Opus 4.6
GPT-5.2 → GPT-5.3
Gemini Pro 3 → Gemini Pro 4
```

### 3. Important Dependencies

```bash
# Check critical deps
- Node.js version
- TypeScript
- Global npm packages
- System tools (jq, etc.)
```

### 4. Anthropic News

```bash
# Fetch latest from Anthropic
- New model releases
- API changes
- Feature announcements
- Breaking changes
```

### 5. Reference Docs

```bash
# Keep knowledge current
- React Native best practices
- Next.js patterns
- TypeScript tips
- Supabase updates
```

### 6. Breaking Changes

```bash
# Detect deprecated patterns
- Outdated React patterns
- Deprecated APIs
- Old npm packages
```

## Usage

```bash
# Manual update
/self-update

# Or directly
~/.claude/scripts/self-update.sh
```

## Automatic Updates

### Daily Updates (Recommended)

```bash
# Crontab (runs daily at 3 AM)
0 3 * * * ~/.claude/scripts/self-update.sh
```

### Weekly Updates

```bash
# Crontab (runs Sunday at 3 AM)
0 3 * * 0 ~/.claude/scripts/self-update.sh
```

### Using launchd (macOS)

```xml
<!-- ~/.claude/config/com.claude.self-update.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.self-update</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/ashleytower/.claude/scripts/self-update.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
        <key>Weekday</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>
```

Load it:

```bash
launchctl load ~/.claude/config/com.claude.self-update.plist
```

## Update Process

### Step 1: Check Claude Code

```bash
Current: claude-code@1.2.3
Latest:  claude-code@1.3.0

Update available! [Y/n]
```

### Step 2: Update LLM Models

```bash
Fetching latest models from OpenRouter...

Updates found:
- GPT: openai/gpt-5.2 → openai/gpt-5.3 ✓
- Gemini: google/gemini-3-pro → google/gemini-4-pro ✓

Updating agent configurations...
```

### Step 3: Check Dependencies

```bash
Node.js: v20.10.0 ✓
npm: 10.2.0 ✓
TypeScript: 5.3.3 ✓
jq: 1.7 ✓
```

### Step 4: Anthropic News

```bash
🔔 New updates from Anthropic!

- Claude 4.5 Opus now available
- Improved code generation
- Extended context window to 500K

View full changelog: https://anthropic.com/news
```

### Step 5: Summary

```bash
✅ Self-update complete!

Updates applied:
- Claude Code: 1.2.3 → 1.3.0
- LLM Models: 2 updated
- Dependencies: All current

Next update: 2026-01-09
```

## Update Log

View update history:

```bash
cat ~/.claude/cache/last-update-summary.txt
```

Example:

```markdown
# Self-Update Summary
Date: 2026-01-08 03:00:00

## Updates Applied
✓ Claude Code CLI (1.2.3 → 1.3.0)
✓ GPT model (5.2 → 5.3)
✓ Gemini model (3 → 4)

## Checks Passed
✓ Dependencies current
✓ No breaking changes

## Next Steps
- Review Anthropic news
- Test new model performance
- Update docs if needed

Next update: 2026-01-09
```

## Notifications

Voice alerts for important updates:

```bash
"Claude Code updated to version 1.3.0"
"Two LLM models updated"
"New updates from Anthropic. Check terminal."
```

## Benefits

1. **Always current**: Get latest features automatically
2. **Security**: Stay on patched versions
3. **Performance**: Benefit from optimizations
4. **Knowledge**: Learn about new capabilities
5. **Zero effort**: Set and forget

## Integration with System-Evolve

When updates introduce breaking changes:

```bash
# Self-update detects breaking change
⚠️ Breaking change detected in React 19

# Use system-evolve to handle it
/system-evolve "React 19 migration"

# Update CLAUDE.md with new patterns
# Create hooks to prevent old patterns
# Update reference docs
```

## Manual Checks

Between automated updates:

```bash
# Check specific component
/self-update --check cli
/self-update --check models
/self-update --check deps
/self-update --check news
```

## Rollback

If update causes issues:

```bash
# Rollback Claude Code
npm install -g @anthropic-ai/claude-code@1.2.3

# Rollback LLM models
cp ~/.claude/config/llm-council.backup.json ~/.claude/config/llm-council.json
~/.claude/scripts/update-llm-council.sh

# Report issue
github.com/anthropics/claude-code/issues
```

## Notes

- Safe to run anytime (idempotent)
- Backs up configs before updating
- Voice notifications for important updates
- Logs all changes
- Respects semver (no breaking auto-updates)
- Can rollback if needed

---

**Philosophy**: Stay current automatically. Learn continuously. Evolve with the ecosystem.

**Set it and forget it**: Enable daily auto-updates and never think about it again.
