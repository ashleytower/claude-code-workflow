# Claude Code Workflow

Based on Boris's approach (creator of Claude Code).

## CRITICAL RULE: NO CODE WITHOUT DOCS

**Before ANY Write or Edit, you MUST use one of these:**

| Tool | When to Use |
|------|-------------|
| `Skill(research)` | General research, any topic |
| `Skill(auth)` | Authentication implementation |
| `Skill(planning)` | Complex task planning |
| `mcp__context7__resolve-library-id` | Find library in Context7 |
| `mcp__context7__query-docs` | Get docs from Context7 |
| `WebFetch` | Official docs URL |

**You must cite your source.** This is enforced by hook. No exceptions.

---

## Callable Skills (Use Skill Tool)

| Skill | Purpose | When to Call |
|-------|---------|--------------|
| `Skill(research)` | Check docs, find patterns | Before any new code |
| `Skill(auth)` | Authentication patterns | Adding auth to any framework |
| `Skill(planning)` | Manus-style file planning | Complex multi-step tasks |
| `Skill(guide)` | Step-by-step workflow | Starting a feature |
| `Skill(learn)` | Save implementation | After successful build |
| `Skill(verify-app)` | Run all tests | Before commit |
| `Skill(commit-push-pr)` | Git workflow | Ship the code |
| `Skill(ralph-loop)` | Autonomous execution | Long-running tasks |

---

## Boris's Setup (What This Follows)

1. **5 Claudes in parallel** - Numbered tabs 1-5, system notifications
2. **Opus 4.5 with thinking** - Best model, less steering
3. **Plan mode first** - shift+tab twice, get plan right
4. **Auto-accept mode** - Let Claude 1-shot it
5. **Verify the work** - Most important thing for quality
6. **Slash commands** - /commit-push-pr dozens of times daily
7. **Shared CLAUDE.md** - Update when Claude does something wrong

## The Workflow

```
1. Plan mode (shift+tab twice)
   -> Go back and forth until plan is right

2. Research ALWAYS (mandatory)
   -> Skill(research) OR Context7 MCP
   -> NO CODE WITHOUT DOCS

3. Execute
   -> Auto-accept mode, let Claude work

4. Simplify (optional)
   -> @code-simplifier to clean up

5. Verify
   -> Skill(verify-app)
   -> This 2-3x's quality

6. Commit
   -> Skill(commit-push-pr)

7. Learn (optional)
   -> Skill(learn) to save for next time
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

## Rules

1. **DOCS FIRST** - Call Skill(research) or Context7 before code
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
Skill(guide) "Build my feature"

# Or use slash command
/guide "Build my feature"

# Or just use Plan mode
# shift+tab twice -> plan -> execute
```
