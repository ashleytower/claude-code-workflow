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

## How PRD Mode Works

```
┌─────────────────────────────────────────┐
│ 1. Pick first story with passes: false  │
│ 2. Implement ONLY that story            │
│ 3. Run tests (verify acceptance)        │
│ 4. If pass: mark passes: true           │
│ 5. Commit the changes                   │
│ 6. Log to progress.txt                  │
│ 7. Voice notify: "Story N complete"     │
│ 8. Loop to next story                   │
│ 9. Until all done or max iterations     │
└─────────────────────────────────────────┘
```

## prd.json Format

```json
{
  "project": "Movie Tracker",
  "stories": [
    {
      "id": "1",
      "story": "As a user, I can search for movies",
      "acceptance_criteria": [
        "Search input on main screen",
        "Results show as user types",
        "Shows poster, title, year"
      ],
      "priority": 1,
      "passes": false
    }
  ]
}
```

## Options

```bash
--prd <file>           # PRD JSON file (enables PRD mode)
--max-iterations <n>   # Safety limit (default: 50)
--max-cost <n>         # Cost limit in dollars (default: 100)
```

## Files Created

| File | Purpose |
|------|---------|
| `prd.json` | Backlog (you create via /create-prd) |
| `progress.txt` | Sprint notes (Ralph creates) |

## Voice Notifications

- "Ralph loop starting"
- "Story 1 complete. 4 remaining."
- "Story 2 complete. 3 remaining."
- ...
- "Ralph loop complete. All stories finished."

Or:
- "Ralph loop stopped. Maximum iterations reached."

## When to Use

| Scenario | Use |
|----------|-----|
| Overnight feature work | PRD mode |
| Large refactor | Simple mode |
| Framework migration | Simple mode |
| Multi-feature sprint | PRD mode |
| Fix all type errors | Simple mode |

## Tips for Success

1. **Small stories** - Each should be 1-2 hours max
2. **Clear acceptance criteria** - Claude needs to verify itself
3. **Good test coverage** - Feedback loops catch errors
4. **Review prd.json** - Garbage in = garbage out

## Example Session

```bash
# Morning: Voice your ideas
"Build a todo app with add, complete, delete, and dark mode"

# Create PRD
/create-prd

# Review prd.json - 6 stories created
cat prd.json

# Start Ralph before bed
/ralph-loop --prd ./prd.json

# Morning: Check results
git log --oneline
# 6 commits, one per story

cat progress.txt
# Full log of what happened
```

## Safety

- Max 50 iterations by default
- Commits after each story (no lost work)
- Voice alerts keep you informed
- Clean exit if stuck

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

**Named after Ralph Wiggum** - persistent, keeps going until done.
