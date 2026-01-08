# Boris's Claude Code Approach

> This guide explains how your setup aligns with Boris's (creator of Claude Code) approach

## ✅ What You Have (Aligned with Boris)

### 1. Multiple Parallel Sessions
- **Boris**: Runs 5 terminals in parallel
- **You**: Set up for 5 terminals (@frontend, @backend, @orchestrator, @bash, main)
- **How**: Number tabs 1-5, use voice alerts to know when each needs input

### 2. Model Selection
- **Boris**: Uses Opus 4.5 with thinking for everything
- **You**: LLM Council set up with Opus 4.5 for critical tasks
- **Why**: Better at tool use, less steering needed, faster in the end

### 3. Shared CLAUDE.md
- **Boris**: Team shares one CLAUDE.md, checked into git
- **You**: Global CLAUDE.md at `~/.claude/CLAUDE.md`
- **Process**: Update whenever Claude makes mistakes → prevents repeat issues

### 4. Plan Mode First
- **Boris**: Most sessions start in Plan mode (shift+tab twice)
- **You**: `/plan` command + Plan mode available
- **Why**: Good plan = 1-shot implementation

### 5. Slash Commands for Inner Loops
- **Boris**: Uses /commit-push-pr dozens of times daily
- **You**: All core commands built (/commit-push-pr, /verify-app, etc.)
- **Why**: Avoid repeated prompting, makes Claude reusable

### 6. Subagents for Common Workflows
- **Boris**: code-simplifier, verify-app, etc.
- **You**: All 8 agents built (@frontend, @backend, @verify-app, etc.)
- **Why**: Automate common workflows for most PRs

### 7. PostToolUse Hook for Formatting
- **Boris**: Formats code automatically
- **You**: Can add formatter hook (removed prompts for now)
- **Why**: Avoid formatting errors in CI

### 8. Pre-Allow Safe Commands
- **Boris**: Uses /permissions, NOT --dangerously-skip-permissions
- **You**: Using dangerouslySkipPermissions for full automation
- **Note**: Boris's approach is safer, yours is more autonomous

### 9. MCP Servers for Tools
- **Boris**: Slack MCP, bq CLI, Sentry, etc.
- **You**: Slack MCP enabled, Rube/Composio available
- **Why**: Claude uses all your tools seamlessly

### 10. Ralph Wiggum for Long Tasks
- **Boris**: Uses ralph-wiggum plugin for very long tasks
- **You**: `/ralph-loop` command built with full implementation
- **Why**: Autonomous overnight development

### 11. Verification is Critical
- **Boris**: "Most important thing for great results"
- **You**: `/verify-app` command + @verify-app agent
- **Why**: Feedback loop 2-3x's quality

### 12. Chrome Extension for Testing
- **Boris**: Tests every change in browser
- **You**: Chrome MCP available for browser automation
- **Why**: End-to-end verification

## 🎯 Your Voice Alert Setup

**What triggers voice alerts:**
1. **Claude needs YOUR decision** → `AskUserQuestion` tool → "Hey! I need your input"
2. **Session completes** → Stop hook → "Session complete. Ready for your review"

**What DOESN'T trigger alerts:**
- Permission prompts (auto-accepted with dangerouslySkipPermissions)
- Tool usage (Claude just does it)
- Background agent work (voice notifies only when complete)

## 📋 Recommended Workflow

### Standard Feature Development

```bash
# Terminal 1 (Main)
/plan "Add user authentication"
# Review plan, get it right
# Switch to auto-accept mode (if not already)

# System auto-invokes agents in parallel
# @backend → API implementation
# @frontend → UI implementation
# Voice alerts when each completes

# When all done
/verify-app
# Voice: "Session complete"

# If all passes
/commit-push-pr
```

### Autonomous Overnight Development

```bash
# Before bed
/ralph-loop "Migrate all API endpoints to v2"

# Go to sleep
# Ralph Loop runs autonomously
# Voice alerts if it needs decisions (rare)

# Morning: Check results
# Ralph notifies completion
```

### Multi-Repo Coordinated Work

```bash
# Terminal 1 (Main)
/superpowers my-app "Add GraphQL support"

# Terminals 2-6 open automatically
# Backend, Frontend, Mobile, Infra, Docs all parallel
# Voice alerts when each completes

# Integration verification
# All repos updated together
```

## 🔧 Key Settings

**Current setup (`~/.claude/settings.local.json`):**

```json
{
  "permissionMode": "auto",
  "dangerouslySkipPermissions": true,  // Full automation
  "permissions": {
    "deny": [
      "Bash(rm -rf /)",    // Safety guards
      "Bash(sudo:*)",
      "Bash(chmod 777:*)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": { "tools": ["AskUserQuestion"] },
        "hooks": [{
          "type": "command",
          "command": "~/.claude/scripts/speak.sh 'Hey! I need your input' &"
        }]
      }
    ],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/scripts/speak.sh 'Session complete' &"
      }]
    }]
  }
}
```

## 💡 Boris's Tips

1. **Give Claude a way to verify its work** - This 2-3x's quality
2. **Good plan is really important** - Plan mode before execution
3. **Invest in verification** - Different for each domain (tests, browser, simulator)
4. **Update CLAUDE.md when Claude makes mistakes** - Prevents repeats
5. **Use subagents for common workflows** - Automate the inner loop

## 🚀 Your Advantages Over Boris

1. **Ralph Loop** - Full autonomous execution system
2. **LLM Council** - Multiple models optimized per task
3. **System Evolution** - Built-in learning from bugs
4. **Multi-repo orchestration** - `/superpowers` command
5. **Auto-updating** - Models and ecosystem stay current

## 📊 Comparison

| Feature | Boris | You |
|---------|-------|-----|
| Multiple terminals | ✓ | ✓ |
| Opus 4.5 | ✓ | ✓ (+ Council) |
| Shared CLAUDE.md | ✓ | ✓ |
| Plan mode first | ✓ | ✓ |
| Slash commands | ✓ | ✓ (16 commands) |
| Subagents | ✓ | ✓ (8 agents) |
| Formatting hook | ✓ | Ready to add |
| Safe permissions | ✓ | Full automation |
| MCP servers | ✓ | ✓ |
| Ralph Wiggum | ✓ | ✓ Enhanced |
| Verification | ✓ | ✓ |
| Chrome testing | ✓ | ✓ |
| **Ralph Loop** | Plugin | ✗ **Full system** |
| **System evolution** | Manual | ✗ **Automated** |
| **Multi-repo** | Manual | ✗ **Orchestrated** |
| **Auto-updates** | Manual | ✗ **Automated** |

## 🎓 Next Steps

1. **Test voice alerts**: Try a task that uses AskUserQuestion
2. **Try Ralph Loop**: `/ralph-loop "Small task"` overnight
3. **Run verification**: `/verify-app` after implementing
4. **Evolve the system**: `/system-evolve` when bugs happen
5. **Keep models current**: `/update-council` (or set up cron)

---

**Your setup is Boris-aligned + enhanced with autonomous features!**
