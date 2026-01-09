# Claude Code Workflow

## Core Commands

| Command | Purpose |
|---------|---------|
| `/guide` | Step-by-step workflow (start here) |
| `/research` | Check docs before coding |
| `/learn` | Save implementation as skill |
| `/verify-app` | Test before commit |
| `/commit-push-pr` | Ship it |
| `/ralph-loop` | Autonomous until complete |

## Planning Pattern (Manus-style)

For complex tasks (3+ steps), create these files in your project:

```
task_plan.md   -> Phases, progress, decisions
findings.md    -> Research, discoveries, errors
progress.md    -> Session log, test results
```

Templates: `templates/` | Auto-read before Write/Edit via hook.

## Agents

| Agent | Use For |
|-------|---------|
| `@frontend` | UI work (requires design first) |
| `@backend` | API work (security enforced) |
| `@verify-app` | Run all tests |

## Rules

1. **Plan first** - Create task_plan.md before complex work
2. **Research first** - Read docs before writing code
3. **Test first** - Run /verify-app before commit
4. **Learn always** - Run /learn after new integrations

## Skills (Copy-Paste Code)

Check `skills/` before implementing integrations.

## The 3-Strike Rule

```
Attempt 1: Fix the error
Attempt 2: Try different approach
Attempt 3: Rethink assumptions
After 3: Ask user for help
```

## Ralph Loop (Autonomous)

For large tasks that should run until actually complete:

```bash
/ralph-loop "Migrate all components to TypeScript"
```

Safety: Max 10 iterations, $100 cost limit. Voice notifies on complete.

## Quick Reference

```bash
# New project
/guide "Build my app"

# New feature
/guide "Add payments"

# Autonomous overnight
/ralph-loop "Large refactor task"
```

---

**Philosophy**: Plan -> Research -> Execute -> Verify -> Learn
