---
name: parallel-branches
description: Work on multiple git branches in parallel
model: sonnet
---

# Parallel Branches - Multi-Branch Development

Work on multiple features simultaneously across different git branches using parallel Claude sessions.

## Concept

**5 terminals, 5 branches, 5 features - all at once.**

Each terminal:
- Own git branch
- Own Claude session
- Own feature/task
- Independent progress

Voice notifications alert you when each completes.

## Setup

### Step 1: Plan Features

```bash
# Terminal 1 (Main)
/plan "
Feature 1: Add user authentication
Feature 2: Build dashboard UI
Feature 3: Implement API endpoints
Feature 4: Add database migrations
Feature 5: Write E2E tests
"
```

### Step 2: Create Branches

```bash
# Auto-create branches
git checkout -b feature/auth
git checkout -b feature/dashboard
git checkout -b feature/api
git checkout -b feature/database
git checkout -b feature/tests
```

### Step 3: Start Parallel Sessions

**Terminal 1: Authentication**
```bash
git checkout feature/auth
claude "@frontend 'Implement authentication UI'"
```

**Terminal 2: Dashboard**
```bash
git checkout feature/dashboard
claude "@frontend 'Build dashboard layout'"
```

**Terminal 3: API**
```bash
git checkout feature/api
claude "@backend 'Implement REST API endpoints'"
```

**Terminal 4: Database**
```bash
git checkout feature/database
claude "Create database migrations and RLS policies"
```

**Terminal 5: Tests**
```bash
git checkout feature/tests
claude "Write E2E tests for all features"
```

## Orchestration Script

Automate the setup:

```bash
#!/bin/bash
# ~/.claude/scripts/parallel-branches.sh

FEATURES=(
  "feature/auth:Implement authentication"
  "feature/dashboard:Build dashboard"
  "feature/api:Implement API"
  "feature/database:Database setup"
  "feature/tests:Write tests"
)

for feature in "${FEATURES[@]}"; do
  IFS=':' read -r branch task <<< "$feature"

  # Create branch
  git checkout -b "$branch" main

  # Open new terminal and start Claude
  osascript -e "tell application \"Terminal\" to do script \"cd $(pwd) && git checkout $branch && claude '$task'\""
done
```

## Integration with Ralph Loop

Each branch can run in Ralph Loop:

```bash
# Terminal 1
git checkout feature/auth
/ralph-loop "Complete authentication implementation"

# Terminal 2
git checkout feature/dashboard
/ralph-loop "Complete dashboard UI"

# ... etc
```

All branches progress autonomously, voice notifications alert when each completes.

## Monitoring Progress

### Check All Branches

```bash
# Terminal 1 (Main)
for branch in feature/*; do
  echo "=== $branch ==="
  git checkout "$branch"
  git status --short
  git log -1 --oneline
done
```

### Voice Status Updates

Each terminal speaks when complete:

```bash
# Terminal 1
"Authentication complete"

# Terminal 2
"Dashboard complete"

# Terminal 3
"API complete"
```

You know exactly when each finishes without watching terminals.

## Merging Strategy

### Option A: Sequential Merge (Safe)

```bash
# Main terminal
git checkout main

# Merge in order
git merge feature/database  # First: DB schema
git merge feature/api       # Second: API
git merge feature/auth      # Third: Auth
git merge feature/dashboard # Fourth: UI
git merge feature/tests     # Last: Tests

# Resolve conflicts as they arise
```

### Option B: Parallel PRs (Team)

```bash
# Each terminal creates PR
cd feature/auth && /commit-push-pr
cd feature/dashboard && /commit-push-pr
cd feature/api && /commit-push-pr
# ... etc

# Team reviews in parallel
# Merge when ready
```

### Option C: Integration Branch

```bash
# Create integration branch
git checkout -b integration/all-features main

# Merge all features
git merge feature/auth
git merge feature/dashboard
git merge feature/api
git merge feature/database
git merge feature/tests

# Resolve conflicts once
# Test integration
# Create single PR
```

## Conflict Resolution

When branches overlap:

```bash
# Run integration checks early
git checkout integration/test
git merge feature/auth
git merge feature/dashboard
# Conflicts found!

# Fix conflicts now while work continues
# Inform other terminals of changes
```

## Dependency Management

If features depend on each other:

```bash
# Feature 2 needs Feature 1
# Terminal 1: Complete Feature 1
git checkout feature/auth
# ... work completes

# Terminal 2: Wait for Feature 1, then merge
git checkout feature/dashboard
git merge feature/auth  # Get latest auth code
# ... continue work with auth available
```

## Example: Full Parallel Workflow

### 1. Plan (Terminal 1 - Main)

```bash
/plan "Build complete user management system"
# Outputs:
# - Auth (frontend + backend)
# - User profiles (UI)
# - Admin dashboard (UI)
# - User API (backend)
# - Database schema
# - Tests
```

### 2. Launch (Terminal 1 - Main)

```bash
/parallel-branches "
feature/auth:Authentication system
feature/profiles:User profile UI
feature/admin:Admin dashboard
feature/user-api:User API endpoints
feature/schema:Database migrations
feature/tests:E2E tests
"
```

This auto-creates branches and opens 5 new terminals.

### 3. Work (Terminals 2-6)

Each terminal works independently:

```
Terminal 2 (feature/auth):
  [Working on auth...]
  ✓ Login component
  ✓ Register component
  ✓ JWT handling
  [Voice: "Authentication complete"]

Terminal 3 (feature/profiles):
  [Working on profiles...]
  ✓ Profile page
  ✓ Edit profile form
  ✓ Avatar upload
  [Voice: "User profiles complete"]

... etc
```

### 4. Integration (Terminal 1 - Main)

```bash
# All complete! Merge them
git checkout main
git merge feature/schema    # DB first
git merge feature/user-api  # API second
git merge feature/auth      # Auth third
git merge feature/profiles  # UI fourth
git merge feature/admin     # UI fifth
git merge feature/tests     # Tests last

# Run integration verification
/verify-app

# All pass! Commit
/commit-push-pr "Complete user management system"
```

## Voice Notifications

Critical for parallel work:

```bash
# .claude/agents/frontend.md
hooks:
  Stop:
    - type: command
      command: "~/.claude/scripts/speak.sh 'Frontend complete on $(git branch --show-current)'"
```

You hear which branch completed without watching terminals.

## Safety Tips

1. **Create branches from main**: Ensure clean starting point
2. **Commit frequently**: Each terminal commits independently
3. **Test before merging**: Run /verify-app on each branch
4. **Merge in order**: Dependencies first, then dependents
5. **Integration testing**: Test merged result, not just individual branches

## When to Use

✅ **Great for**:
- Independent features
- Large refactors (split by module)
- Frontend + Backend (parallel dev)
- Multiple experiments (A/B testing)
- Urgent hotfixes (while main work continues)

❌ **Not ideal for**:
- Single feature (overkill)
- Highly coupled changes
- Shared file editing (conflicts)

## Notes

- Requires 5 terminal windows
- Each terminal = independent Claude session
- Voice notifications are essential
- Git branches keep work isolated
- Merge strategy depends on dependencies
- Can combine with Ralph Loop for autonomy
- Dramatically speeds up development

---

**Philosophy**: Parallelize everything possible. Modern CPUs have multiple cores; use them.
