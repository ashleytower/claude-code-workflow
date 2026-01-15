# Claude Code Workflow

A clean, simple workflow for Claude Code based on Boris's approach + TDD + file-based planning.

## Quick Start

```bash
# New project or feature
/guide "Build my app"

# Resume from last session
/resume

# Autonomous overnight work
/ralph-loop "Large migration task"
```

## Core Commands

| Command | Purpose |
|---------|---------|
| `/guide` | Step-by-step workflow (start here) |
| `/resume` | Pick up where last session left off |
| `/research` | Check docs before coding |
| `/verify-app` | Run tests before commit |
| `/commit-push-pr` | Ship it |
| `/learn` | Save implementation as reusable skill |
| `/ralph-loop` | Autonomous until complete |

## Planning Files

For complex tasks (3+ steps), copy templates to your project:

```bash
cp ~/.claude/templates/task_plan.md ./
cp ~/.claude/templates/session_state.md ./
```

| File | Purpose |
|------|---------|
| `task_plan.md` | Phases, decisions, errors |
| `session_state.md` | Handoff between sessions |
| `findings.md` | Research, discoveries |
| `progress.md` | Session log |

## Workflow

```
1. /guide "feature"     -> Start guided workflow
2. Plan mode            -> Get plan right (shift+tab x2)
3. Research             -> Skill(research) - docs first
4. TDD                  -> Write failing test first
5. Implement            -> Minimal code to pass
6. /verify-app          -> Run full test suite
7. /commit-push-pr      -> Ship it
8. Update session_state -> For next session
```

## Session Handoff

End of session - update `session_state.md`:
```markdown
## Current Task
Building user auth

## Next Action
Write test for password validation
```

Start of next session:
```bash
/resume
```

## Agents

| Agent | Use For |
|-------|---------|
| `@frontend` | UI development |
| `@backend` | API development |
| `@verify-app` | Run all tests |

## Skills

Check `skills/` before implementing integrations:
- `auth.md` - Authentication patterns
- `tdd.md` - Test-driven development
- `planning.md` - File-based planning
- More added via `/learn` after successful implementations

## Structure

```
├── CLAUDE.md          # Rules (read this)
├── commands/          # Slash commands
├── skills/            # Copy-paste code
├── agents/            # Specialized agents
├── templates/         # Planning file templates
└── archive/           # Archived files
```

## Philosophy

```
Plan -> Research -> TDD -> Implement -> Verify -> Ship -> Handoff
```

1. **Plan first** - Create task_plan.md before complex work
2. **Research first** - Read docs before writing code
3. **Test first** - Write failing test before implementation
4. **Handoff always** - Update session_state.md before ending
