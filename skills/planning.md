---
name: planning
description: File-based planning for complex tasks. Use for multi-step work.
---

# Planning with Files

Context window = RAM (volatile). Filesystem = Disk (persistent).

## When to Use

- Multi-step tasks (3+ steps)
- Tasks spanning multiple sessions
- Anything requiring handoff

## The Files

| File | Purpose | When |
|------|---------|------|
| `task_plan.md` | Phases, decisions, errors | Start of task |
| `findings.md` | Research, discoveries | During research |
| `session_state.md` | Handoff between sessions | End of session |
| `progress.md` | Session log | During work |

## Quick Start

```bash
# Copy templates to project
cp ~/.claude/templates/task_plan.md ./
cp ~/.claude/templates/session_state.md ./

# Start work, update task_plan.md as you go

# End of session - update session_state.md
# Next session - /resume
```

## Rules

### 1. Create Plan First
No complex task without `task_plan.md`.

### 2. The 2-Action Rule
After 2 search/browse operations, save to `findings.md`.

### 3. Update Session State
Before ending, update `session_state.md` with next action.

### 4. Log Errors
Every error goes in `task_plan.md`. Prevents repetition.

### 5. 3-Strike Protocol
```
Attempt 1: Diagnose & fix
Attempt 2: Different approach
Attempt 3: Rethink assumptions
After 3: Ask user
```

## Session Handoff

End of session:
```markdown
# session_state.md
## Current Task
Building user auth

## Status
- Phase: 3 (TDD)
- Branch: feature/auth
- Blocked: no

## Next Action
Write test for password validation
```

Start of next session:
```bash
/resume
```

## Integration

- `/guide` uses these templates automatically
- `/resume` reads session_state.md
- TDD phase built into task_plan.md
