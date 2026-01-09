---
name: ralph-loop
description: Autonomous loop for hours of unattended work
model: sonnet
---

# Ralph Loop - Autonomous Development

Run Claude autonomously for hours. Go to sleep, wake up to commits.

## Two Modes

### Simple Mode (original)
```bash
/ralph-loop "Fix all TypeScript errors"
```
Loops until git is clean. Good for migrations/refactors.

### PRD Mode (for hours of autonomous work)
```bash
/ralph-loop --prd ./prd.json
```
Works through user stories, commits after each. This is what you want for feature development.

## Quick Start

```bash
# 1. Voice your ideas (Wispr)
"I want an app that tracks movies, with search, ratings, and dark mode"

# 2. Create PRD with user stories
/create-prd

# 3. Review the prd.json, adjust if needed

# 4. Start Ralph
/ralph-loop --prd ./prd.json --max-iterations 50

# 5. Go to sleep. Wake up to commits.
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

## Integration

Works with existing skills:
- `/create-prd` - Creates the prd.json
- `/verify-app` - Called internally for tests
- `/learn` - Save integrations after (manually)

---

**Named after Ralph Wiggum** - persistent, keeps going until done.
