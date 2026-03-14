---
name: auto-memory
description: AutoMemory protocol for agents. Invoke at the start of any work session to load relevant memory, and self-monitor during work for auto-save triggers. Also covers agent team debrief at team shutdown.
---

# AutoMemory Protocol

Quick notes, gotchas, research findings persist in `~/.claude/memory/`. Agents self-monitor and save without being asked.

## Before Starting Work

1. Read `~/.claude/memory/INDEX.md`
2. Query relevant topic files: `grep -rl "keyword" ~/.claude/memory/`
3. If 10+ notes exist on a service, graduate to `/learn` skill

## Note Format

File location: `~/.claude/memory/topics/<topic>.md`

```
### YYYY-MM-DD - Summary
[tag] 2-5 line note.
```

Tags: `[gotcha]` `[pattern]` `[research]` `[decision]` `[debug]`

## Auto-Save Triggers

Save to `~/.claude/memory/topics/<topic>.md` AUTOMATICALLY when:

1. **Retry pattern** — You tried approach A, it failed, then approach B worked. Save what failed and why B worked.
2. **Docs were wrong/outdated** — API or docs said X, but reality was Y. Save the discrepancy.
3. **Config discovery** — A non-obvious env var, flag, or setting was needed. Save the exact config.
4. **Error decoding** — An error message was misleading or required research to understand. Save error -> real cause -> fix.
5. **Version/compat issue** — Something broke due to version mismatch or deprecation. Save versions and workaround.
6. **Wasted time** — Anything that took 3+ attempts to get right. Save the shortcut for next time.

Save to `~/.claude/memory/research/YYYY-MM-DD-<topic>.md` when:

7. **Research task** — You were sent to investigate something. Always save structured findings.
8. **Comparison made** — You evaluated 2+ options. Save the comparison and conclusion.

Do NOT wait to be asked. If a trigger fires, save immediately, then continue working.

## Agent Team Memory Rules

All teammates in an agent team read and write memory. Lead agent queries before assigning tasks.

## Agent Team Debrief (REQUIRED at team shutdown)

Before the lead cleans up a team, the lead MUST:

1. Ask each teammate: "What was harder than expected? What broke? What did you figure out?"
2. Compile a debrief to `~/.claude/memory/research/YYYY-MM-DD-team-debrief-<project>.md`:

```markdown
## What went smoothly
[Tasks that worked first try]

## What was hard
[Issues that required retries or workarounds]

## Key learnings
[Non-obvious fixes, gotchas, patterns discovered]

## Unresolved
[Anything still broken or unclear]
```

3. Ensure individual teammate learnings were saved to topic files during work
4. Report the debrief summary to the user

## Learning Routing

| Type | Where to save |
|------|--------------|
| Known service gotcha | Append to existing skill (`vercel-*.md`, etc.) |
| New service | `/learn` |
| Quick gotcha or finding | `~/.claude/memory/topics/<topic>.md` |
| Research findings | `~/.claude/memory/research/` |
| Project-specific | Project's `./CLAUDE.md` |

## Eval

**Trigger**: Agent discovers that `expo-router` v3 requires a different config for web than v2.

**Expected behavior**: Agent immediately saves a note to `~/.claude/memory/topics/expo-router.md` tagged `[gotcha]` with the version, the discrepancy, and the fix — without being asked — then continues working.
