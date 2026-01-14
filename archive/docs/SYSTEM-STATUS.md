# System Status - No Nonsense

**Last updated**: 2026-01-08
**Claude Code version**: Check on startup

---

## ✅ What's Configured

### Startup Checks
- **Update check**: Runs automatically, checks GitHub changelog
- **Voice alert**: If update available
- **Auto-notification**: Won't bug you if already notified

### Mandatory Research Before Code
- **Hook**: PreToolUse on Write/Edit
- **Enforces**: Check docs, grep codebase, read CLAUDE.md
- **NO GUESSING**: Hard stop if research not done

### All Agents Have Research Skill
- @frontend - has research
- @backend - has research
- @react-native-expert - has research
- @verify-app - has research
- @bash - has research
- @orchestrator - has research
- @code-simplifier - has research
- @research-ui-patterns - has research

### Voice Alerts (Minimal)
- Need input: "Need input"
- Session done: "Done"
- Agent done: "Task done"
- Update available: "Claude Code update available"

**NO celebrations. NO fluff. Just facts.**

### Permissions
- Full automation: `dangerouslySkipPermissions: true`
- Wildcard patterns (NEW in 2.1.0): `Bash(npm *)`, `Bash(git *)`, etc.
- Safety denies: rm -rf /, sudo, chmod 777, dd

---

## 🆕 Claude Code 2.1.0 Features (Latest)

### Hot Reload
- Skills update without restart
- Edit skill → Immediately available
- No session restart needed

### Fork Context
- Skills run in isolated sub-agent environments
- Better resource management
- Cleaner context

### Thinking Display
- Real-time thinking blocks in transcript mode
- See reasoning as it happens

### Wildcard Bash Patterns
- `Bash(npm *)` - all npm commands
- `Bash(git *)` - all git commands
- More flexible than individual commands

### MCP `list_changed` Notifications
- Tools update dynamically
- No reconnection needed
- Better MCP integration

### Better Permission UX
- Cleaner labels
- Contextual design
- Easier to understand prompts

### Security Fix
- Resolved debug log data exposure
- Sensitive data no longer leaks

### Fixes
- File discovery when resuming sessions
- LSP tool reliability
- Bash command permission handling
- OAuth token refresh race conditions
- macOS code-sign warning (Chrome)

---

## 📋 Commands Available

All `/command-name` ready to use:

**Core Workflow:**
- /guide
- /create-prd
- /research ← **Uses research skill**
- /ui-design
- /prime
- /plan
- /execute
- /commit-push-pr
- /code-review
- /security-review

**Advanced:**
- /verify-app
- /system-evolve
- /parallel-branches
- /superpowers
- /ralph-loop ← **Autonomous overnight**
- /update-council
- /self-update

---

## 🎯 Skills Available

All agents can invoke:
- **research** - Mandatory docs check before code

Add more in `~/.claude/skills/*.md`

---

## 🔄 Auto-Update Flow

1. **Startup**: Check GitHub changelog
2. **Compare**: Current vs Latest
3. **Notify**: If update available (once per version)
4. **Voice**: "Claude Code update available"
5. **Show**: What's new from changelog
6. **Remind**: Run `npm install -g @anthropic-ai/claude-code@latest`

---

## 🚫 What's NOT Configured

**Deliberately removed:**
- Celebration messages
- Emoji spam
- Unnecessary prompts
- Blocking hooks (except mandatory research)

**Why**: Get work done. No distractions.

---

## 📖 How Research Works

### Before Every Write/Edit

1. **Hook triggers**: "Did you check docs?"
2. **Agent must**: Call research skill OR use Grep/Read/WebFetch
3. **Research skill**:
   - WebSearch official docs
   - Grep existing patterns
   - Read CLAUDE.md
   - Find GitHub examples
   - Return: Exact approach from docs

4. **Then**: Write code based on findings
5. **NOT allowed**: Guessing, outdated patterns, assumptions

### Example Flow

```bash
User: "Add authentication"

Agent: [Triggered PreToolUse hook]
Agent: Calling research skill...
Research: Checked Next.js 15 docs
Research: Found auth pattern in codebase
Research: CLAUDE.md says use NextAuth
Research: GitHub example with 10k stars found
Agent: Implementing based on NextAuth docs...
```

---

## 🎛️ Settings File

`~/.claude/settings.local.json`

**Key settings:**
- `dangerouslySkipPermissions: true` - Full automation
- `StartSession` hook - Update check
- `PreToolUse` hook - Mandatory research
- `Stop` hook - Voice "Done"
- Wildcard bash patterns

---

## 🔍 Troubleshooting

**Research hook blocking me:**
- Good. It's working.
- Did you actually check docs?
- Use /research command
- Or grep/read existing code first

**Voice alerts not working:**
- Check `~/.claude/scripts/speak.sh` exists
- Verify ElevenLabs API key
- Test: `~/.claude/scripts/speak.sh "test"`

**Update check annoying:**
- It only notifies once per version
- Runs in background (&)
- Update to stop notifications: `npm install -g @anthropic-ai/claude-code@latest`

---

## 📊 System Health

Check these to verify everything works:

```bash
# Commands exist
ls ~/.claude/commands/

# Skills exist
ls ~/.claude/skills/

# Agents have research
grep "skills:" ~/.claude/agents/*.md

# Update check works
~/.claude/scripts/check-updates.sh

# Voice works
~/.claude/scripts/speak.sh "test"
```

---

**Status**: Production ready. No fluff. Build things.
