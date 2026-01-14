---
name: update-council
description: Update LLM Council to latest models
model: sonnet
---

# Update Council - Keep LLM Models Current

Automatically updates your LLM Council configuration with the latest model versions from OpenRouter.

## What This Does

1. **Fetches** latest models from OpenRouter API
2. **Compares** with current configuration
3. **Updates** model IDs if newer versions available
4. **Applies** changes to all agent configurations
5. **Notifies** you of updates via voice

## Models Tracked

### Opus 4.5 (Complex Planning)
- **Current**: anthropic/claude-opus-4.5
- **Used by**: @code-simplifier, @research-ui-patterns
- **Purpose**: Complex planning, system architecture, critical features

### GPT-5.2 (General Development)
- **Current**: openai/gpt-5.2
- **Used by**: @backend
- **Purpose**: API implementation, general development

### Gemini Pro 3 (Fast Tasks)
- **Current**: google/gemini-3-pro
- **Used by**: @bash, @orchestrator
- **Purpose**: Fast iterations, simple tasks, bash orchestration

### Grok 2 (Visual Analysis)
- **Current**: x-ai/grok-2
- **Used by**: TBD
- **Purpose**: Screenshot analysis, UI review, visual debugging

### Sonnet 4.5 (Balanced)
- **Current**: anthropic/claude-sonnet-4.5
- **Used by**: @frontend, @react-native-expert, @verify-app
- **Purpose**: Balanced speed/quality, frontend/mobile development

## Usage

```bash
# Manual update
/update-council

# Or directly
~/.claude/scripts/update-llm-council.sh
```

## Automatic Updates

Set up daily automatic updates:

```bash
# Add to crontab
crontab -e

# Run daily at 3 AM
0 3 * * * ~/.claude/scripts/update-llm-council.sh
```

Or use launchd (macOS):

```xml
<!-- ~/.claude/config/com.claude.llm-update.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.llm-update</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/ashleytower/.claude/scripts/update-llm-council.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>
```

Then load it:

```bash
launchctl load ~/.claude/config/com.claude.llm-update.plist
```

## Update Process

### Step 1: Fetch Models

```bash
curl "https://openrouter.ai/api/v1/models" \
  -H "Authorization: Bearer $OPENROUTER_API_KEY"
```

### Step 2: Compare Versions

```bash
Current: anthropic/claude-opus-4.5
Latest:  anthropic/claude-opus-4.5
Status:  ✓ Up to date

Current: openai/gpt-5.2
Latest:  openai/gpt-5.3
Status:  ⚠️  Update available!
```

### Step 3: Update Config

```json
{
  "last_updated": "2026-01-08",
  "models": {
    "gpt": {
      "openrouter_id": "openai/gpt-5.3"
    }
  }
}
```

### Step 4: Update Agents

```bash
# Update @backend agent file
model: openai/gpt-5.3
```

### Step 5: Notify

```bash
[Voice: "LLM Council updated to latest models"]
```

## Update Log

Check update history:

```bash
cat ~/.claude/logs/llm-council-updates.log
```

Example output:

```
[2026-01-08 03:00:01] Starting LLM Council update...
[2026-01-08 03:00:02] Fetched latest models
[2026-01-08 03:00:03] SUCCESS: GPT updated: openai/gpt-5.2 → openai/gpt-5.3
[2026-01-08 03:00:04] Updated @backend to use openai/gpt-5.3
[2026-01-08 03:00:05] SUCCESS: ✅ LLM Council update complete!
```

## Rollback

If update causes issues:

```bash
# Restore backup
cp ~/.claude/config/llm-council.backup.json ~/.claude/config/llm-council.json

# Re-apply to agents
~/.claude/scripts/update-llm-council.sh
```

## Manual Model Selection

Override model for specific task:

```bash
# Use Opus for this task
claude --model anthropic/claude-opus-4.5 "Complex planning task"

# Use Gemini for fast iteration
claude --model google/gemini-3-pro "Quick fix"
```

## Cost Tracking

Different models have different costs:

| Model | Cost per 1M tokens (input/output) |
|-------|-----------------------------------|
| Opus 4.5 | $15 / $75 |
| GPT-5.2 | $10 / $30 |
| Gemini Pro 3 | $2 / $6 |
| Sonnet 4.5 | $3 / $15 |

Use cheaper models (Gemini) for simple tasks, expensive models (Opus) for critical work.

## Benefits

1. **Always current**: Get latest model improvements automatically
2. **Performance**: New models are often faster and better
3. **Features**: Access new capabilities as they're released
4. **Cost optimization**: Newer models often cheaper for same quality
5. **Zero manual work**: Set and forget

## Notes

- Requires OPENROUTER_API_KEY environment variable
- Backs up config before updating
- Safe to run anytime (idempotent)
- Voice notification on updates
- Logs all changes
- Can rollback if needed

---

**Philosophy**: Stay current automatically. Get best models without manual tracking.

**Sources:**
- [OpenRouter Models](https://openrouter.ai/models)
- [OpenRouter API Docs](https://openrouter.ai/docs)
