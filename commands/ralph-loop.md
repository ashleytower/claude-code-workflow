---
name: ralph-loop
description: Run autonomous loop with pass@k evaluation
model: sonnet
---

# Ralph Loop - Autonomous Task Completion with pass@k

Run tasks autonomously with Anthropic's agent evaluation methodology.

Based on: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents

## How pass@k Works

**Pass@k** measures the likelihood an agent succeeds in k attempts. If ANY attempt passes, the story passes. After k failures, the story is marked failed.

- `pass@1`: Must succeed first try (strict)
- `pass@3`: 3 attempts to succeed (default, recommended)
- `pass@5`: 5 attempts (lenient)

## Process

1. **Execute**: Run Claude with story
2. **Verify**: Run tests / check markers
3. **Pass?**: Mark complete, commit, move to next
4. **Fail?**: Revert changes, retry (up to k times)
5. **Exceeded k?**: Mark story FAILED, move to next

## Configuration

```bash
export RALPH_MAX_ITERATIONS=50  # Default: 50
export RALPH_MAX_COST=100       # Default: $100
export RALPH_PASS_K=3           # Default: 3 attempts per story
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

## CRITICAL: File Writing Rules

**ALWAYS use the Write tool for file creation. NEVER use:**
- `cat > file << 'EOF'`
- `node -e "fs.writeFileSync(...)"`
- `echo ... > file`
- `python -c "open(...).write(...)"`

These bash workarounds trigger false-positive security detection and stop the loop.

**Correct approach:**
```
Write(file_path: "path/to/file.ts", content: "...")
```

## CRITICAL: External Service Integration

**ALWAYS use Rube MCP tools for external services. NEVER use direct CLI/API calls.**

Available via `mcp__rube__RUBE_SEARCH_TOOLS`:
- **Supabase**: Database operations, migrations, RLS policies
- **Vercel**: Deployments, environment variables, domains
- **Google**: Gmail, Calendar, Drive, Sheets
- **GitHub**: Issues, PRs, repos, actions
- **Slack**: Messages, channels, users
- **Stripe**: Payments, customers, subscriptions
- **Resend**: Email sending

**Workflow:**
1. `mcp__rube__RUBE_SEARCH_TOOLS` - Find the right tool
2. `mcp__rube__RUBE_MANAGE_CONNECTIONS` - Ensure connection active
3. `mcp__rube__RUBE_MULTI_EXECUTE_TOOL` - Execute the operation

**Example - Supabase migration:**
```
# DON'T: supabase db push
# DO: Use RUBE_SEARCH_TOOLS to find Supabase migration tools
```

**Example - Vercel deploy:**
```
# DON'T: vercel deploy
# DO: Use RUBE_SEARCH_TOOLS to find Vercel deployment tools
```

## Notes

- Runs in main context (uses your tokens)
- Voice notifications keep you informed
- Can run overnight on large tasks
- Saves hours of manual iteration
- Cost-conscious with limits
- Uses Write tool for all file creation (no bash workarounds)

---

**Sources:**
- [Ralph Loop on GitHub](https://github.com/vercel-labs/ralph-loop-agent)
- [Ralph Wiggum Guide](https://paddo.dev/blog/ralph-wiggum-autonomous-loops/)
- [Autonomous Coding Guide](https://awesomeclaude.ai/ralph-wiggum)
