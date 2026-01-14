# Create PRD Command

**Purpose**: Take your voice rambling and convert it into a structured PRD with user stories for Ralph loop.

## Usage

```bash
# Voice record your ideas via Wispr, then:
/create-prd

# Or with specific output
/create-prd --output ./prd.json
```

## What It Does

1. **Listens** to your rambling feature ideas
2. **Extracts** the core requirements
3. **Outputs**:
   - `PRD.md` - Human-readable document
   - `prd.json` - Machine-readable for Ralph loop

## Process

### Step 1: Capture Ideas

You voice record (via Wispr) something like:

> "I want to build an app that tracks movies I've watched. It should have a search feature, I can mark movies as watched, rate them 1-5 stars, and see my watch history. Oh and dark mode would be nice."

### Step 2: Claude Converts

I take your rambling and produce:

**PRD.md** (human readable):
```markdown
# Movie Tracker App

## Overview
Personal movie tracking app with search, ratings, and watch history.

## Features
1. Movie search
2. Mark as watched
3. Rate 1-5 stars
4. View watch history
5. Dark mode theme

## Tech Stack
[Based on project or ask]
```

**prd.json** (for Ralph loop):
```json
{
  "project": "Movie Tracker",
  "stories": [
    {
      "id": "1",
      "story": "As a user, I can search for movies by title",
      "acceptance_criteria": [
        "Search input field on main screen",
        "Results appear as user types",
        "Shows movie poster, title, year"
      ],
      "priority": 1,
      "passes": false
    },
    {
      "id": "2",
      "story": "As a user, I can mark a movie as watched",
      "acceptance_criteria": [
        "Watch button on movie detail",
        "Watched movies show checkmark",
        "Watch date is recorded"
      ],
      "priority": 2,
      "passes": false
    }
  ]
}
```

### Step 3: Review & Refine

I'll show you the user stories and ask:
- Are these the right priorities?
- Any missing acceptance criteria?
- Should we split any stories smaller?

### Step 4: Start Ralph Loop

```bash
/ralph-loop --prd ./prd.json
# Go to sleep, wake up to features
```

## User Story Guidelines

**Good stories are:**
- Small (1-2 hours of work max)
- Verifiable (clear acceptance criteria)
- Independent (can be built alone)
- User-focused ("As a user, I can...")

**Bad stories:**
- "Build the authentication system" (too big)
- "Make it fast" (not verifiable)
- "Improve UX" (too vague)

## Examples

### Voice Input:
> "I need a dashboard that shows my sales data. Should have charts, filter by date range, export to CSV, and send weekly email reports."

### Output Stories:

| ID | Story | Priority |
|----|-------|----------|
| 1 | As a user, I can see a sales chart on the dashboard | 1 |
| 2 | As a user, I can filter sales data by date range | 2 |
| 3 | As a user, I can export sales data to CSV | 3 |
| 4 | As a user, I receive weekly sales email reports | 4 |

Each with 3-5 acceptance criteria.

## Integration with Workflow

```bash
# 1. Voice your ideas
[Wispr recording]

# 2. Create PRD
/create-prd

# 3. Review and approve stories
"Yes, looks good" or "Split story 3 into smaller pieces"

# 4. Start autonomous work
/ralph-loop --prd ./prd.json --max-iterations 50

# 5. Check in the morning
git log --oneline  # See all the commits
```

## Output Files

| File | Purpose | Used By |
|------|---------|---------|
| `PRD.md` | Human reference | You, planning |
| `prd.json` | Ralph backlog | `/ralph-loop --prd` |
| `progress.txt` | Sprint notes | Ralph (auto-created) |

## Notes

- Spend time on good acceptance criteria (garbage in = garbage out)
- Smaller stories = more commits = less lost work
- Ralph can handle 10-20 stories per session
- Voice notifications tell you when each story completes
