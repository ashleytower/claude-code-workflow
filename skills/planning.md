---
name: planning
description: Manus-style file-based planning for complex tasks
---

# Planning with Files

Use persistent markdown files as working memory. Context window = RAM (volatile). Filesystem = Disk (persistent).

## When to Use

- Multi-step tasks (3+ steps)
- Research tasks
- Building projects
- Any task requiring organization

## Quick Start

1. Copy templates to your project:
   ```bash
   cp ~/.claude/templates/*.md ./
   ```

2. Fill in task_plan.md with your phases

3. Work through phases, updating files as you go

## The 3 Files

| File | Purpose | When to Update |
|------|---------|----------------|
| `task_plan.md` | Phases, progress, decisions | After each phase |
| `findings.md` | Research, discoveries | After ANY discovery |
| `progress.md` | Session log, test results | Throughout session |

## Critical Rules

### 1. Create Plan First
Never start complex task without task_plan.md.

### 2. The 2-Action Rule
After every 2 view/browser/search operations, save findings to findings.md.

### 3. Read Before Decide
Before major decisions, re-read task_plan.md.

### 4. Log ALL Errors
Every error goes in task_plan.md. Prevents repetition.

### 5. Never Repeat Failures
```
if action_failed:
    next_action != same_action
```

## The 3-Strike Protocol

```
Attempt 1: Diagnose & fix
Attempt 2: Try different approach (NEVER same action)
Attempt 3: Rethink assumptions
After 3: Ask user for help
```

## 5-Question Reboot Test

Can you answer these?

1. Where am I? -> Current phase in task_plan.md
2. Where am I going? -> Remaining phases
3. What's the goal? -> Goal statement
4. What have I learned? -> findings.md
5. What have I done? -> progress.md

If yes, context is solid.

## Integration with /guide

/guide automatically uses this pattern for complex tasks.
