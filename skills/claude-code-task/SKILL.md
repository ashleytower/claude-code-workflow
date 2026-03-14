---
name: claude-code-task
description: "Run Claude Code tasks in background with automatic result delivery. Zero OpenClaw tokens while Claude Code works. Launches via nohup, tracks sessions, delivers results to Telegram. Use when: launching background coding tasks, running long Claude Code sessions, async task execution."
---

# Claude Code Task

> Zero tokens while Claude Code works. Notification only on completion.

Launch Claude Code tasks in the background. The gateway is completely free while Claude Code runs -- no agent turns consumed. Results are delivered to Telegram automatically on completion.

## Quick Start

To launch a background Claude Code task:

```bash
bash ~/.claude/skills/claude-code-task/run-task.sh <project_dir> "<task_description>" [session_key]
```

Or via nohup for fire-and-forget:

```bash
nohup bash ~/.claude/skills/claude-code-task/run-task.sh /path/to/project "implement feature X" "$SESSION_KEY" &
```

## How It Works

1. **Launch**: `run-task.sh` starts `claude -p` in the background
2. **Execute**: Claude Code runs autonomously using Max plan OAuth (free)
3. **Complete**: Output saved to `/tmp/cc-<timestamp>-result.txt`
4. **Notify**: Results sent back to the originating session via gateway API
5. **Track**: Session registry at `~/.openclaw/claude_sessions.json` tracks all tasks

## Async Boundary Rule

**Critical**: Once you launch a Claude Code task, you MUST NOT block waiting for it. The task runs in a separate process. You can:
- Launch multiple tasks in parallel
- Continue with other work
- Check results later via session registry

## Session Registry

All launched tasks are tracked in `~/.openclaw/claude_sessions.json`:

```python
from session_registry import SessionRegistry

reg = SessionRegistry()

# Register a new session
reg.register("cc-1234567890", label="implement auth", project="/path/to/project")

# List recent sessions
for s in reg.recent(hours=24):
    print(f"{s['label']}: {s['status']}")

# Update session status
reg.update("cc-1234567890", status="completed", metadata={"exit_code": 0})
```

## Integration with Nightly Builder

The nightly builder can use `run-task.sh` instead of raw `claude -p` calls:

```bash
# Instead of:
claude -p "$PROMPT" --output-format text > "$OUTPUT" 2>&1 &

# Use:
bash ~/.claude/skills/claude-code-task/run-task.sh "$WORKTREE_DIR" "$PROMPT" "$SESSION_KEY" &
```

Benefits:
- Automatic result delivery to Telegram (no polling needed)
- Session tracking with labels and metadata
- Completion reports with exit code and output size
- Truncated output in notifications (first 2000 chars), full output on disk

## Claude Code Flags

The task runner uses these flags:

| Flag | Purpose |
|------|---------|
| `--dangerously-skip-permissions` | No interactive prompts (required for background) |
| `--output-format text` | Clean text output (no ANSI codes) |
| `-p` | Print mode (non-interactive) |

## Notification Format

On success:
```
Task completed!

Task: <first 150 chars of prompt>
Project: /path/to/project
Result (12345 bytes):

<first 2000 chars of output>

Full output: /tmp/cc-1234567890-result.txt
```

On failure:
```
Task failed (exit 1)

Task: <first 150 chars of prompt>
Project: /path/to/project

<error output>
```

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | This documentation |
| `run-task.sh` | Bash launcher (main entry point) |
| `session_registry.py` | Python session tracking module |

## Cost

Zero. Claude Code uses Max plan OAuth. The gateway consumes zero tokens while the task runs. Only the final notification costs one gateway message.
