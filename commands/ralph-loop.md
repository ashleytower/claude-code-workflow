---
name: ralph-loop
description: Run autonomous loop until task complete
model: sonnet
---

# Ralph Loop - Autonomous Task Completion

Run this task in an autonomous loop until it's actually complete.

## How Ralph Loop Works

**Named after Ralph Wiggum** from The Simpsons - persistent, keeps going until done.

**Two loops**:
- **Inner loop**: Standard Claude tool loop
- **Outer loop**: Ralph verification loop that restarts if not complete

## Process

1. **Execute**: Run Claude with the task
2. **Verify**: Check if task is actually complete
3. **Decide**: If not complete, loop again
4. **Safety**: Stop at max iterations or cost

## Completion Verification

Automatic checks:
- Git status (no uncommitted changes)
- Tests passing
- Explicit completion markers

## Safety Limits

```bash
export RALPH_MAX_ITERATIONS=10  # Default: 10
export RALPH_MAX_COST=100       # Default: $100
```

## Usage

```bash
# Via command
/ralph-loop "Migrate all components to TypeScript"

# Direct script
~/.claude/scripts/ralph-loop.sh "Complete the PRD implementation"

# With custom limits
RALPH_MAX_ITERATIONS=20 /ralph-loop "Large refactor task"
```

## When to Use

✅ **Great for**:
- Large refactors
- Framework migrations
- Dependency upgrades across many files
- Overnight autonomous development
- Mechanical tasks with clear completion

❌ **Not ideal for**:
- Creative work requiring human judgment
- Tasks with ambiguous completion criteria
- Anything that needs immediate human review

## Example

```bash
/ralph-loop "Migrate all API endpoints from Express to Fastify"
```

Ralph will:
1. Start migration
2. Complete one iteration
3. Check if ALL endpoints migrated
4. If not, continue with next batch
5. Repeat until all done or limits hit
6. Voice notification when complete

## Integration with /guide

Ralph Loop is particularly effective when combined with `/guide`:

```bash
# Generate plan
/guide "Add authentication system"

# Execute with Ralph Loop
/ralph-loop "Implement the authentication system plan"
```

This ensures:
- Plan is clear (from /guide)
- Execution is autonomous (Ralph Loop)
- Completion is verified (Ralph Loop)

## Monitoring

Ralph Loop provides:
- Voice notifications per iteration
- Progress logging
- Cost tracking
- Completion verification status

## Mark Task Complete

To explicitly mark complete:

```bash
echo "COMPLETE" > /tmp/ralph-completion-$$.txt
```

Or let auto-detection handle it:
- Clean git status
- All tests passing

## Notes

- Runs in main context (uses your tokens)
- Voice notifications keep you informed
- Can run overnight on large tasks
- Saves hours of manual iteration
- Cost-conscious with limits

---

**Sources:**
- [Ralph Loop on GitHub](https://github.com/vercel-labs/ralph-loop-agent)
- [Ralph Wiggum Guide](https://paddo.dev/blog/ralph-wiggum-autonomous-loops/)
- [Autonomous Coding Guide](https://awesomeclaude.ai/ralph-wiggum)
