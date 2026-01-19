# Resume Command

Pick up where the last session left off.

## Usage

```bash
/resume
```

## What It Does

1. Reads `session_state.md` for current task and next action
2. Reads `task_plan.md` for phase and progress
3. Checks git status for uncommitted work
4. Summarizes context and continues

## Process

### Step 1: Load Session State

```bash
# Check for planning files
if [ -f "session_state.md" ]; then
  echo "Found session_state.md"
fi
if [ -f "task_plan.md" ]; then
  echo "Found task_plan.md"
fi
```

Read these files:
- `session_state.md` - Current task, next action, blockers
- `task_plan.md` - Phases and progress
- `findings.md` - Research and decisions (if exists)

### Step 2: Check Git State

```bash
git status --porcelain
git log --oneline -3
git branch --show-current
```

### Step 3: Summarize and Continue

Output format:

```
RESUMING SESSION

Task: [from session_state.md]
Phase: [from task_plan.md]
Branch: [from git]
Last: [last action from session_state.md]
Next: [next action from session_state.md]

Uncommitted changes: [yes/no]
Blockers: [from session_state.md]

Continuing with: [next action]
```

Then execute the next action.

## If No Session State Found

```
No session_state.md found.

Options:
1. /prime - Load project context and start planning
2. /guide - Start guided workflow for new task
3. Describe what you want to work on
```

## Integration

- Run at start of any continuation session
- Updates session_state.md when done
- Works with /guide workflow
