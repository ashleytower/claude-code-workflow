---
name: ralph-tui
description: Visual TUI orchestrator for AI agent loops (alternative to ralph-loop)
model: sonnet
---

# Ralph TUI - Visual Agent Loop Orchestrator

A full terminal UI for orchestrating AI agent loops. Visual alternative to `/ralph-loop`.

## Quick Comparison

| Feature | /ralph-loop | /ralph-tui |
|---------|-------------|------------|
| Interface | Terminal text | Full TUI with live updates |
| pass@k retries | Yes (default 3) | No (1 attempt per task) |
| Cost limits | Yes ($100 default) | No |
| Voice notifications | Yes | Desktop notifications |
| Session recovery | Manual | Automatic crash recovery |
| Multi-agent | Claude only | Claude, OpenCode, Gemini, Codex, Kiro |
| Remote control | No | WebSocket multi-instance |
| Task tracking | prd.json only | prd.json + Beads (git-backed) |

## When to Use Each

| Scenario | Use |
|----------|-----|
| Need pass@k evaluation (retries) | `/ralph-loop` |
| Need cost limits | `/ralph-loop` |
| Want visual progress | `/ralph-tui` |
| Multi-agent fallback | `/ralph-tui` |
| Remote server orchestration | `/ralph-tui` |
| Session might crash/interrupt | `/ralph-tui` |

## Setup (First Time)

```bash
# Run interactive setup
ralph-tui setup
```

This creates `.ralph-tui/config.toml` with your preferences.

## Basic Usage

### Create a PRD (AI-guided)
```bash
ralph-tui create-prd --chat
```

### Run with existing prd.json
```bash
ralph-tui run --prd ./prd.json
```

### Run with Beads tracker
```bash
ralph-tui run --tracker beads --epic my-feature
```

### Resume interrupted session
```bash
ralph-tui resume
```

### Check status
```bash
ralph-tui status
```

## Commands Reference

| Command | Purpose |
|---------|---------|
| `ralph-tui setup` | Interactive project configuration |
| `ralph-tui create-prd --chat` | AI-guided PRD creation |
| `ralph-tui convert --to json ./prd.md` | Convert markdown PRD to JSON |
| `ralph-tui run` | Start execution |
| `ralph-tui resume` | Continue interrupted session |
| `ralph-tui status` | Check session state |
| `ralph-tui logs` | View iteration logs |
| `ralph-tui doctor` | Diagnose agent config issues |
| `ralph-tui plugins agents` | List available agents |
| `ralph-tui plugins trackers` | List available trackers |

## Run Options

```bash
ralph-tui run \
  --prd ./prd.json \        # PRD file
  --agent claude \          # Agent: claude, opencode, gemini, codex, kiro
  --model opus \            # Model override
  --iterations 50 \         # Max iterations (0 = unlimited)
  --headless \              # No TUI, structured logs
  --sandbox \               # Enable sandboxing
  --listen                  # Enable remote WebSocket listener
```

## TUI Controls

While running:
- `q` - Quit gracefully
- `p` - Pause execution
- `r` - Resume execution
- `Tab` - Switch panels
- Arrow keys - Navigate

## Configuration

**Project config**: `.ralph-tui/config.toml`
```toml
[agent]
defaultAgent = "claude"
fallbackAgents = ["opencode"]

[tracker]
defaultTracker = "json"

[execution]
maxIterations = 50
iterationDelay = 1000

[output]
outputDir = ".ralph-tui/iterations"
```

**Global config**: `~/.config/ralph-tui/config.toml`

## The 5-Step Cycle

```
1. SELECT  → Pick highest-priority unblocked task
2. BUILD   → Construct contextual prompt with codebase patterns
3. EXECUTE → Run AI agent with prompt
4. DETECT  → Check for <promise>COMPLETE</promise> signal
5. MOVE    → Mark done, log iteration, next task
```

## Remote Control

Control instances across machines:

```bash
# On server
ralph-tui run --listen --listen-port 7890

# On local machine
ralph-tui remote add prod server.example.com:7890 --token <token>
ralph-tui remote list
```

## Bundled Skills

```bash
ralph-tui skills list
ralph-tui skills install  # Install to ~/.claude/skills/
```

## Differences from /ralph-loop

### What ralph-tui does better:
- Visual real-time progress
- Automatic crash recovery
- Multi-agent support with fallback
- Git-backed task tracking (Beads)
- Remote orchestration

### What /ralph-loop does better:
- pass@k evaluation (multiple retries per story)
- Cost limits ($100 cap)
- Voice notifications
- Tighter integration with this workflow

## Migrating from /ralph-loop

Your existing `prd.json` works with both. The formats are compatible.

```bash
# Old way (still works)
/ralph-loop --prd ./prd.json

# New way (visual)
ralph-tui run --prd ./prd.json
```

## Troubleshooting

```bash
# Check agent config
ralph-tui doctor

# System info for bug reports
ralph-tui info -c

# View logs
ralph-tui logs --iteration 5
```

## Notes

- Installed globally via: `bun install -g ralph-tui`
- State stored in `.ralph-tui/` directory
- Does NOT replace /ralph-loop - use whichever fits your needs
- No cost tracking - monitor manually or use /ralph-loop for cost limits
