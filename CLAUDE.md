# Claude Code Workflow

Based on Boris's approach (creator of Claude Code).

## CRITICAL RULE: NO CODE WITHOUT DOCS

**Before ANY Write or Edit:**

1. Check docs using Context7 MCP:
   - `mcp__context7__resolve-library-id` (find library)
   - `mcp__context7__query-docs` (get docs)

2. Or use `/research "topic"`

3. Or use WebFetch on official docs

**You must be able to cite your source.**

This is enforced by hook. No exceptions.

---

## Boris's Setup (What This Follows)

1. **5 Claudes in parallel** - Numbered tabs 1-5, system notifications
2. **Opus 4.5 with thinking** - Best model, less steering
3. **Plan mode first** - shift+tab twice, get plan right
4. **Auto-accept mode** - Let Claude 1-shot it
5. **Verify the work** - Most important thing for quality
6. **Slash commands** - /commit-push-pr dozens of times daily
7. **Shared CLAUDE.md** - Update when Claude does something wrong

## Core Commands

| Command | Purpose |
|---------|---------|
| `/guide` | Step-by-step workflow guidance |
| `/research` | Check docs before coding |
| `/learn` | Save implementation as skill |
| `/verify-app` | Test before commit |
| `/commit-push-pr` | Ship it |
| `/ralph-loop` | Autonomous until complete |

## The Workflow

```
1. Plan mode (shift+tab twice)
   -> Go back and forth until plan is right

2. Research ALWAYS
   -> /research "topic" OR Context7 MCP
   -> NO CODE WITHOUT DOCS

3. Execute
   -> Auto-accept mode, let Claude work

4. Simplify (optional)
   -> @code-simplifier to clean up

5. Verify
   -> Tests, type check, build
   -> This 2-3x's quality

6. Commit
   -> /commit-push-pr

7. Learn (optional)
   -> /learn "integration-name"
```

## Agents

| Agent | Use For |
|-------|---------|
| `@frontend` | UI work |
| `@backend` | API work |
| `@verify-app` | Run all tests |
| `@code-simplifier` | Clean up after implementation |

## Planning Files (For Complex Tasks)

```
task_plan.md   -> Phases, progress, decisions
findings.md    -> Research, discoveries, errors
progress.md    -> Session log, test results
```

## Skills

Check `skills/` before implementing. Copy-paste code for common integrations.

## Rules

1. **DOCS FIRST** - No code without checking documentation
2. **Plan first** - Good plan = 1-shot implementation
3. **Verify always** - Give Claude feedback loop
4. **Update CLAUDE.md** - When Claude does something wrong

## Notifications

- Voice alert when Claude needs input
- Voice alert when task complete
- macOS notification popup

## Quick Start

```bash
# Start guided workflow
/guide "Build my feature"

# Or just use Plan mode
# shift+tab twice -> plan -> execute
```
