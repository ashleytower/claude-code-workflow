# Hooks Status - Complete System Overview

**Last Updated**: 2026-01-08
**Status**: ALL ACTIVE

---

## Hook Summary

| Hook Type | When Triggered | Purpose | Voice Alert |
|-----------|---------------|---------|-------------|
| **StartSession** | Session starts | Check updates, show agent state | No |
| **PreToolUse (Write/Edit)** | Before code | Check skills, enforce docs check | No |
| **PreToolUse (AskUserQuestion)** | Claude needs input | Alert user | ✓ "Need input" |
| **PostToolUse (Write/Edit)** | After code | Validate files, remind agent state | No |
| **PostToolUse (Bash)** | After bash | Auto-checkpoint | No |
| **Stop** | Session ends | Write agent state | ✓ "Done" |

---

## Detailed Hook Configuration

### 1. StartSession Hooks

**Purpose**: Initialize session with context and updates

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/scripts/check-updates.sh &",
      "comment": "Check for Claude Code updates"
    },
    {
      "type": "prompt",
      "prompt": "AGENT COORDINATION: Check for previous agent state...",
      "comment": "Show agent state from previous session"
    }
  ]
}
```

**What happens**:
1. ✓ Check for Claude Code updates (background)
2. ✓ Prompt to check agent state from previous session

**Voice**: None (silent initialization)

---

### 2. PreToolUse Hooks (Write/Edit)

**Purpose**: PREVENT HALLUCINATION - Force docs check before ANY code

```json
{
  "matcher": { "tools": ["Write", "Edit"] },
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/scripts/check-skills.sh",
      "comment": "ALWAYS check for available skills"
    },
    {
      "type": "prompt",
      "prompt": "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n🚨 MANDATORY PRE-CODE CHECKLIST - CANNOT BE BYPASSED 🚨\n\n1. ✓ READ official documentation\n2. ✓ CHECK existing codebase patterns\n3. ✓ CHECK available skills\n4. ✓ VERIFY approach in CLAUDE.md\n\nIF YOU SKIP ANY STEP: You will write incorrect code.\nIF YOU GUESS: You will introduce bugs.\nIF YOU IGNORE SKILLS: You waste time rebuilding.",
      "comment": "ABSOLUTE MANDATE: Cannot be bypassed"
    }
  ]
}
```

**What happens**:
1. ✓ Check for available skills (Stripe, Resend, etc.)
2. ✓ Show massive warning prompt with checklist
3. ✓ Claude MUST acknowledge before Write/Edit proceeds

**Voice**: None (but blocks action until acknowledged)

**This is the MOST CRITICAL hook** - prevents hallucination

---

### 3. PreToolUse Hooks (AskUserQuestion)

**Purpose**: Alert user when input needed

```json
{
  "matcher": { "tools": ["AskUserQuestion"] },
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/scripts/speak.sh 'Need input' &",
      "comment": "Voice alert: Claude needs your decision"
    }
  ]
}
```

**What happens**:
1. ✓ Voice says "Need input"
2. ✓ User alerted even if away from keyboard

**Voice**: ✓ "Need input"

---

### 4. PostToolUse Hooks (Write/Edit)

**Purpose**: Validate files and coordinate agents

```json
{
  "matcher": { "tools": ["Write", "Edit"] },
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/scripts/validate-files.sh ~/.claude/agents/*.md ... || true",
      "comment": "Auto-validate files after modification"
    },
    {
      "type": "prompt",
      "prompt": "If you are an agent: Update agent state for next agent...",
      "comment": "Remind to update agent state"
    }
  ]
}
```

**What happens**:
1. ✓ Validate all modified files (empty check, YAML check, etc.)
2. ✓ Auto-recover if corrupted
3. ✓ Remind to update agent state

**Voice**: None

---

### 5. PostToolUse Hooks (Bash)

**Purpose**: Auto-checkpoint after risky operations

```json
{
  "matcher": { "tools": ["Bash"] },
  "hooks": [
    {
      "type": "command",
      "command": "cd ~/.claude && git add -A && git commit -m 'Auto-checkpoint: After bash operation' --allow-empty &",
      "comment": "Auto-commit after risky bash operations"
    },
    {
      "type": "prompt",
      "prompt": "If you are an agent: Update agent state...",
      "comment": "Remind to update agent state"
    }
  ]
}
```

**What happens**:
1. ✓ Git commit after every bash operation
2. ✓ Full audit trail preserved
3. ✓ Can restore any state

**Voice**: None

---

### 6. Stop Hooks

**Purpose**: Finalize agent state and notify completion

```json
{
  "hooks": [
    {
      "type": "prompt",
      "prompt": "BEFORE STOPPING:\n\nIf you completed work for multi-agent workflow:\n1. Write final agent state with next steps\n2. Update TodoWrite with completion status\n3. Save any critical context for next agent",
      "comment": "Write final agent state"
    },
    {
      "type": "command",
      "command": "~/.claude/scripts/speak.sh 'Done' &",
      "comment": "Voice: Session done"
    }
  ]
}
```

**What happens**:
1. ✓ Prompt to write final agent state
2. ✓ Voice says "Done"
3. ✓ User alerted session complete

**Voice**: ✓ "Done"

---

## Voice Notification Coverage

### Currently Using Voice

| Event | Message | Hook |
|-------|---------|------|
| User input needed | "Need input" | PreToolUse (AskUserQuestion) |
| Session complete | "Done" | Stop |

### Where Voice COULD Be Added (Optional)

| Event | Potential Message | Benefit |
|-------|------------------|---------|
| Skill detected | "Skill available" | Alert before coding |
| File corrupted | "File corrupted, recovering" | Alert to data issue |
| Update available | "Update available" | Know about updates |
| Context at 70% | "Context at 70 percent" | Prevent token waste |
| Tests failed | "Tests failed" | Know about failures |
| Agent handoff | "Agent handoff" | Track progress |

**Current approach**: Minimal voice (only when user action needed)

**Reasoning**: Too many voice alerts = annoying

---

## Auto-Update Cron Jobs

**Status**: ✓ ACTIVE

```cron
# Auth docs: Every Sunday at 3 AM
0 3 * * 0 ~/.claude/scripts/update-auth-docs.sh

# LLM Council: Daily at 2 AM
0 2 * * * ~/.claude/scripts/update-llm-council.sh

# Self-update check: Daily at 1 AM
0 1 * * * ~/.claude/scripts/self-update.sh

# Cleanup old backups: Weekly on Monday at 4 AM
0 4 * * 1 find ~/.claude/backups -type d -mtime +30 -exec rm -rf {} +
```

**Logs**:
- `~/.claude/logs/auth-updates.log`
- `~/.claude/logs/llm-council-updates.log`
- `~/.claude/logs/self-updates.log`

---

## Testing Hooks

### Test 1: Mandatory Docs Check

```bash
# Try to write code without checking docs
# Hook should block with big warning

Expected: 🚨 MANDATORY PRE-CODE CHECKLIST prompt appears
```

### Test 2: Skill Detection

```bash
# In project with Stripe package
# Try to write Stripe code

Expected: 💡 AVAILABLE SKILLS DETECTED: stripe-payments.md
```

### Test 3: File Validation

```bash
# Corrupt a file
echo "" > ~/.claude/agents/test.md

# Write/Edit something
# Hook should auto-recover

Expected: File auto-restored from git
```

### Test 4: Voice Notifications

```bash
# Trigger AskUserQuestion
# Should hear "Need input"

# Complete session
# Should hear "Done"
```

### Test 5: Auto-Checkpoint

```bash
# Run bash command
# Check git log

Expected: New commit "Auto-checkpoint: After bash operation"
```

---

## Verification Command

```bash
~/.claude/scripts/verify-hooks.sh
```

**Checks**:
1. ✓ All mandatory hooks present
2. ✓ All scripts executable
3. ✓ Cron jobs installed
4. ✓ Hallucination prevention active
5. ✓ Data loss prevention active
6. ✓ Agent coordination active

---

## Hook Philosophy

**Mandatory vs Optional**:
- **Mandatory**: Docs check, skill detection, file validation (CANNOT skip)
- **Optional**: Voice alerts (can disable if annoying)

**Silent vs Loud**:
- **Silent**: Background operations (validation, checkpoints)
- **Loud**: User action needed (input required, session done)

**Blocking vs Non-Blocking**:
- **Blocking**: Mandatory docs check (waits for acknowledgment)
- **Non-Blocking**: Validation, checkpoints (runs in background)

---

## Current Status

✅ **All hooks active and verified**

**Protection levels**:
1. ✓ Hallucination prevention (mandatory docs check)
2. ✓ Data loss prevention (auto-validation + git)
3. ✓ Agent coordination (state management)
4. ✓ Auto-updates (cron jobs)
5. ✓ Voice notifications (minimal, targeted)

**No bypasses possible** - Hooks run before Claude can proceed with Write/Edit operations.
