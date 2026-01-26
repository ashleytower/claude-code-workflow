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
3. **Pass?**: Mark complete, **COMMIT IMMEDIATELY**, move to next
4. **Fail?**: Revert changes, retry (up to k times)
5. **Exceeded k?**: Mark story FAILED, move to next

## MANDATORY: Commit After Every Iteration (ENFORCED)

**YOU MUST COMMIT AFTER EVERY SUCCESSFUL ITERATION. THIS IS NOT OPTIONAL.**

After each story/task passes verification:

```bash
# 1. Stage all changes
git add -A

# 2. Commit with descriptive message
git commit -m "feat(ralph): [Story ID] - [Brief description]

[What was implemented]
[What was tested]

Ralph Loop iteration [N] of [total]

Co-Authored-By: Claude <noreply@anthropic.com>"

# 3. Push to remote (prevents lost work)
git push
```

**FAILURE TO COMMIT = LOOP FAILURE**

If you complete work without committing:
- The iteration is NOT complete
- You MUST commit before proceeding
- Never output `<promise>COMPLETE</promise>` without a commit

**Why this matters:**
- Overnight runs can crash - commits preserve work
- User wakes up to committed code, not staged changes
- Each commit is a checkpoint that can be reverted independently

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

## MANDATORY: TDD Workflow (Test-Driven Development)

**Every story MUST follow TDD. No exceptions.**

```
┌─────────────────────────────────────────┐
│ 1. Write FAILING test first             │
│ 2. Run test - confirm it FAILS          │
│ 3. Implement minimum code to pass       │
│ 4. Run test - confirm it PASSES         │
│ 5. Refactor if needed                   │
│ 6. Commit + push                        │
└─────────────────────────────────────────┘
```

**Why TDD:**
- Tests define acceptance criteria precisely
- Prevents over-engineering
- Creates documentation automatically
- Ensures code is testable from the start

## MANDATORY: Context7 Before Library Changes

**Before modifying ANY file that imports external libraries, you MUST:**

1. Call `mcp__context7__resolve-library-id` for the library
2. Call `mcp__context7__query-docs` with your specific question
3. Verify API patterns match current documentation

**Required for these libraries:**
- `@google/genai` (Gemini API)
- `@supabase/supabase-js` (Supabase)
- `resend` (Email)
- `stripe` (Payments)
- `date-fns` (Date utilities)
- Any library you're not 100% certain about

**Skip Context7 lookup = hallucinated API patterns = wasted iterations**

## MANDATORY: Correct Working Directory

**Before starting ANY work, verify you're in the correct repo:**

```bash
# Check current directory
pwd

# Verify git remote matches expected repo
git remote -v

# If wrong, STOP and alert user
```

**Never create new git repos. Never init. Always work in the provided directory.**

## Tips for Success

1. **Small stories** - Each should be 1-2 hours max
2. **Clear acceptance criteria** - Claude needs to verify itself
3. **Good test coverage** - Feedback loops catch errors
4. **Review prd.json** - Garbage in = garbage out
5. **TDD always** - Test first, then implement
6. **Context7 always** - Check docs before using libraries

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

## ITERATION CHECKLIST (Must Complete Each Iteration)

Before outputting any promise token, verify ALL items:

**Pre-Implementation:**
- [ ] Verified working directory is correct (`pwd`, `git remote -v`)
- [ ] Checked Context7 for any libraries being used
- [ ] Wrote FAILING test first (TDD red phase)

**Implementation:**
- [ ] Test now PASSES (TDD green phase)
- [ ] Code refactored if needed (TDD refactor phase)
- [ ] No TypeScript errors (`npm run build` or type check)

**Commit:**
- [ ] `git add -A` executed
- [ ] `git commit` executed with descriptive message
- [ ] `git push` executed successfully
- [ ] Commit SHA logged to progress.txt

**Only after ALL items are checked can you output:**
```
<promise>STORY_N_COMPLETE</promise>
```

**If ANY item is unchecked, you are NOT done. Complete the checklist.**

---

**Named after Ralph Wiggum** - persistent, keeps going until done.
