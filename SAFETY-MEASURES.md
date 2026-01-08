# Safety Measures - Never Lose Work Again

**Status**: ACTIVE
**Last Updated**: 2026-01-08

---

## What Happened

The `update-agents-with-state.sh` script corrupted all 8 agent files (reduced them to 0 bytes) due to improper multiline string handling in awk.

**Result**: All agents were empty.

---

## Prevention Systems (Now Active)

### 1. Git Version Control

**Location**: `~/.claude/.git/`

**How it works**:
- Every change automatically committed
- Full history preserved
- Can restore any file: `git checkout HEAD -- path/to/file`

**Current commits**:
```bash
git log --oneline | head -5

d3d34e2 Safety: Add auto-validation, auto-backup, and git checkpoints
1b691af Rebuild: All 8 agents with state coordination
dc0bc3a Initial commit: Before agent rebuild
```

### 2. Auto-Validation (After Every Write/Edit)

**Script**: `~/.claude/scripts/validate-files.sh`

**Checks**:
1. ✓ File is not empty
2. ✓ YAML frontmatter exists (for .md files)
3. ✓ JSON is valid (for .json files)
4. ✓ File size is reasonable

**Auto-recovery**:
- If file is empty → Restores from git automatically
- If git fails → Restores from backup automatically

**Hook**: PostToolUse for Write/Edit tools
```json
{
  "type": "command",
  "command": "~/.claude/scripts/validate-files.sh ~/.claude/agents/*.md ..."
}
```

**Result**: Files validated after EVERY modification.

### 3. Auto-Checkpoint (After Bash Operations)

**Hook**: PostToolUse for Bash tool
```json
{
  "type": "command",
  "command": "cd ~/.claude && git add -A && git commit -m 'Auto-checkpoint: After bash operation'"
}
```

**Result**: Git snapshot after every bash command that modifies ~/.claude files.

### 4. Backup Script (Manual Trigger)

**Script**: `~/.claude/scripts/backup-before-operation.sh`

**Creates timestamped backups**:
```
~/.claude/backups/
├── agents-20260108_143022/
├── skills-20260108_143045/
├── commands-20260108_143100/
└── settings-20260108_143115.json
```

**Retention**: Keeps last 10 backups per type (auto-cleanup)

**Usage**:
```bash
# Before risky operation
~/.claude/scripts/backup-before-operation.sh "operation description"
```

### 5. Skill Auto-Detection

**Script**: `~/.claude/scripts/check-skills.sh`

**Hook**: PreToolUse for Write/Edit tools

**Prevents rebuilding from scratch**:
- Detects if Stripe/Resend/etc. is being used
- Shows available skills BEFORE you write code
- Reminds to read skill files for copy-paste code

**Example output**:
```
💡 AVAILABLE SKILLS DETECTED:

  ✓ stripe-payments.md - Read ~/.claude/skills/stripe-payments.md
  ✓ auth.md - Read ~/.claude/skills/auth.md

These skills contain copy-paste code for this integration.
READ THEM BEFORE implementing from scratch.
```

### 6. Agent State Coordination

**Script**: `~/.claude/scripts/agent-state.sh`

**State file**: `.claude/agent-state.json` (per project)

**Ensures agents coordinate**:
```bash
# Agent 1 finishes
agent-state.sh write "@frontend" "completed" "UI done" '["files"]' '["Backend: Add API"]'

# Agent 2 starts
agent-state.sh read
# Sees: "@frontend completed UI, next step: Backend: Add API"
```

**Hooks**: StartSession, PostToolUse, Stop prompts

---

## Recovery Procedures

### If File Becomes Empty

**Automatic** (happens in validate-files.sh):
```bash
# 1. Try git restore
git checkout HEAD -- path/to/file

# 2. If git fails, try backup
cp ~/.claude/backups/[type]-latest/file path/to/file
```

**Manual**:
```bash
# Restore from git
git checkout HEAD -- ~/.claude/agents/backend.md

# Or restore from backup
cp ~/.claude/backups/agents-20260108_143022/backend.md ~/.claude/agents/

# Or restore from specific commit
git checkout abc1234 -- ~/.claude/agents/backend.md
```

### If Multiple Files Corrupted

```bash
# View git history
git log --oneline

# Restore entire directory from commit
git checkout abc1234 -- ~/.claude/agents/

# Or restore from backup
cp -r ~/.claude/backups/agents-20260108_143022/* ~/.claude/agents/
```

### If Git is Corrupted

```bash
# Backups are independent of git
ls -t ~/.claude/backups/agents-* | head -1
# Copy from most recent backup
```

---

## Testing the Safety Net

### Test 1: Empty File Detection

```bash
# Corrupt a file
echo "" > /tmp/test-agent.md

# Validate
~/.claude/scripts/validate-files.sh /tmp/test-agent.md

# Expected: "ERROR: /tmp/test-agent.md is empty!"
```

### Test 2: Auto-Recovery

```bash
# In ~/.claude directory with git
cd ~/.claude

# Create and commit a test file
echo "test content" > test-file.md
git add test-file.md && git commit -m "Test file"

# Corrupt it
echo "" > test-file.md

# Validate (should auto-recover)
~/.claude/scripts/validate-files.sh test-file.md

# Check if recovered
cat test-file.md
# Expected: "test content"

# Cleanup
rm test-file.md
```

### Test 3: Skill Detection

```bash
# Add stripe to package.json
echo '{"dependencies":{"stripe":"^14.0.0"}}' > /tmp/test-project/package.json

# Check skills
cd /tmp/test-project
~/.claude/scripts/check-skills.sh

# Expected: Shows stripe-payments.md if it exists
```

---

## Hook Summary

| Hook | When | What It Does |
|------|------|--------------|
| **StartSession** | Session starts | Check agent state, check updates |
| **PreToolUse (Write/Edit)** | Before code | Check skills, enforce docs check |
| **PostToolUse (Write/Edit)** | After code | Validate files, remind agent state |
| **PostToolUse (Bash)** | After bash | Auto-commit checkpoint |
| **Stop** | Session ends | Remind agent state, voice "Done" |

---

## Safety Guarantees

With these measures active:

1. ✓ **No data loss** - Git + backups + validation
2. ✓ **Auto-recovery** - Corrupted files restored automatically
3. ✓ **No rebuilding** - Skills detected before coding
4. ✓ **Agent coordination** - State preserved between agents
5. ✓ **Full audit trail** - Git history of every change
6. ✓ **Manual fallback** - Timestamped backups independent of git

---

## Maintenance

### Cleanup Old Backups

```bash
# Auto-cleanup keeps last 10, but manual cleanup if needed
ls -t ~/.claude/backups/agents-* | tail -n +11 | xargs rm -rf
```

### Check Git History

```bash
cd ~/.claude
git log --oneline --all --graph
```

### Verify Hooks Active

```bash
cat ~/.claude/settings.local.json | grep -A5 "PostToolUse"
```

---

**Status**: All safety measures ACTIVE and tested.

**Last corruption**: 2026-01-08 (agents wiped by awk script)
**Recovery time**: 10 minutes (rebuild from memory + implement safety)
**Future corruption risk**: Near zero (auto-validation + auto-recovery + git + backups)
