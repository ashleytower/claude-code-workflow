# Claude Code Workflow

A clean, simple workflow for Claude Code based on Boris's approach + Manus-style file planning.

## Quick Start

```bash
# New project or feature
/guide "Build my app"

# Autonomous overnight work
/ralph-loop "Large migration task"
```

## Core Commands

| Command | Purpose |
|---------|---------|
| `/guide` | Step-by-step workflow (start here) |
| `/research` | Check docs before coding |
| `/learn` | Save implementation as reusable skill |
| `/verify-app` | Run tests before commit |
| `/commit-push-pr` | Ship it |
| `/ralph-loop` | Autonomous until complete |

## Planning Pattern

For complex tasks (3+ steps), create these files in your project:

```
task_plan.md   -> Phases, progress, decisions
findings.md    -> Research, discoveries, errors
progress.md    -> Session log, test results
```

Copy templates: `cp templates/*.md ./`

## Agents

| Agent | Use For |
|-------|---------|
| `@frontend` | UI development |
| `@backend` | API development |
| `@verify-app` | Run all tests |

## Skills

Check `skills/` before implementing integrations:
- `auth.md` - Authentication patterns
- `planning.md` - File-based planning
- More added via `/learn` after successful implementations

## Notifications

- **Voice** (ElevenLabs): Alerts when Claude needs input or finishes
- **macOS notifications**: Visual alerts

Setup: Set `ELEVENLABS_API_KEY` in environment, or fallback to macOS `say` command.

## Philosophy

```
Plan -> Research -> Execute -> Verify -> Learn
```

1. **Plan first** - Create task_plan.md before complex work
2. **Research first** - Read docs before writing code
3. **Test first** - Run /verify-app before commit
4. **Learn always** - Run /learn after new integrations

## Structure

```
├── CLAUDE.md          # Rules (read this)
├── settings.json      # Hooks configuration
├── commands/          # Slash commands
├── agents/            # Specialized agents
├── skills/            # Copy-paste code
├── templates/         # Planning file templates
├── scripts/           # Helper scripts
└── archive/           # Archived files (not deleted)
```

## Archive

Extra commands, agents, and docs moved to `archive/` - not deleted, just out of the way.
