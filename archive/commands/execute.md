# Execute Command

**Purpose**: Execute a structured plan in a FRESH context (context reset pattern). This command is run in a NEW Claude Code session with ONLY the plan as context.

**Critical**: This command should ONLY be run in a fresh session after context reset!

## Usage

```bash
# In a FRESH Claude Code session
claude /execute .claude/plans/[feature-name].md

# Example
claude /execute .claude/plans/user-authentication.md
```

## Context Reset Pattern

**Planning Session** (Terminal 1, old session):
- Primed with full context
- Researched and designed
- Created comprehensive plan
- Plan saved to .claude/plans/[feature].md

**CLOSE THAT SESSION** ← Context reset!

**Execution Session** (Terminal 1, NEW session):
- NO priming
- NO exploration
- ONLY load: the plan file
- Execute step-by-step

**Why**: Keeps context light for better reasoning during implementation

## Process

### 1. Load the Plan (ONLY Context Needed!)

```bash
# Read the specified plan file
# This contains ALL context for execution:
# - Feature description
# - Research findings
# - Approved UI designs
# - Technical approach
# - Task breakdown
# - Code examples
# - Edge cases
# - Testing strategy
```

### 2. Execute Tasks Sequentially

For each task in the plan:

**2.1 Implement**
- Follow the task's implementation description
- Use code examples from plan (sourced from official docs/boilerplates)
- Create/modify specified files

**2.2 Verify**
- Run tests for this task
- Check for errors
- Verify functionality

**2.3 Report**
- Task completed
- Tests passing
- Any issues encountered

**2.4 Continue to Next Task**

### 3. Run Tests After Each Major Step

```bash
# After implementing each task
npm test
# OR
pytest

# Ensure no regressions
```

### 4. Final Verification

After all tasks complete:

```bash
# Type checking
npm run type-check
# OR
mypy .

# Linting
npm run lint
# OR
ruff check .

# All tests
npm test
# OR
pytest
```

### 5. Report Completion

```markdown
✅ EXECUTION COMPLETE

Feature: [Feature Name]
Plan: .claude/plans/[feature-name].md

Tasks Completed: 8/8
├─ ✓ Task 1: [name]
├─ ✓ Task 2: [name]
├─ ✓ Task 3: [name]
├─ ✓ Task 4: [name]
├─ ✓ Task 5: [name]
├─ ✓ Task 6: [name]
├─ ✓ Task 7: [name]
└─ ✓ Task 8: [name]

Files Changed: 12
Tests Added: 15
All Tests: ✓ Passing

Ready for:
- Code review: /code-review
- Commit: /commit-push-pr
```

## Integration with Multi-Terminal Workflow

During execution, you may spawn parallel agents:

```bash
# Main execution in Terminal 1
claude /execute .claude/plans/feature.md

# If plan says "Implement UI in parallel", spawn:
# Terminal 2
claude "@frontend 'Implement login screen per plan'"

# Terminal 3
claude "@backend 'Implement auth API per plan'"

# Terminal 4
claude "@bash 'npm install dependencies per plan'"

# All work in parallel!
# Voice notifications tell you when each completes
```

## Error Handling

### If Implementation Hits Blocker

```
⚠️ BLOCKER ENCOUNTERED

Task 3: Database migration failing
Error: [error message]

Attempted fixes:
1. [fix attempt]
2. [fix attempt]

Unable to proceed automatically.

Options:
1. Research the error (may need /research again)
2. Adjust the plan
3. Ask user for guidance
```

### If Tests Fail

```
❌ TESTS FAILING

Task 5: Added auth endpoint
Tests: 3 failing

Failures:
- test_auth_with_invalid_token: Expected 401, got 500
- test_auth_with_expired_token: [error]
- test_logout_clears_session: [error]

Debugging and fixing...
[Attempts to fix]

✓ Tests now passing
Continuing...
```

## Orchestrator Integration

When execution completes, Stop-Hook triggers orchestrator:
- Analyzes all changes
- Runs quality checks
- Invokes relevant agents
- Reports results

## In /guide Workflow

Phase 5: /guide instructs you to run /execute in fresh session

After /execute completes:
- Return to /guide
- Continue to Phase 6 (Verification)

## Example Execution

```bash
$ claude /execute .claude/plans/user-authentication.md

📖 Loading plan: user-authentication.md

Feature: User Authentication
Tasks: 8
Context: All required context loaded from plan

Starting execution...

---

Task 1/8: Install Supabase dependencies
├─ Running: npm install @supabase/supabase-js @supabase/auth-helpers-react-native
├─ ✓ Dependencies installed
└─ Tests: N/A (dependencies only)

Task 2/8: Create Supabase client
├─ Creating: src/lib/supabase.ts
├─ Implementation: [code following plan's example]
├─ ✓ File created
└─ Tests: ✓ Passing (2/2)

Task 3/8: Create auth context
├─ Creating: src/contexts/AuthContext.tsx
├─ Implementation: [code]
├─ ✓ File created
└─ Tests: ✓ Passing (5/5)

Task 4/8: Implement login screen UI
├─ Creating: src/screens/LoginScreen.tsx
├─ Following approved design from: .claude/designs/auth-screens.md
├─ ✓ File created
├─ ✓ Matches approved design
└─ Tests: ✓ Passing (8/8)

[... continues through all 8 tasks ...]

---

✅ ALL TASKS COMPLETE

Feature: User Authentication
Tasks Completed: 8/8
Files Changed: 12
Tests Added: 15
All Tests: ✓ 27/27 passing

Type Check: ✓ No errors
Lint: ✓ No issues

[Voice: "Execution complete"]

Ready for verification!
Run /code-review to get feedback
```

## Notes

- ALWAYS run in fresh session (context reset!)
- Plan contains all needed context
- Execute tasks in order (dependencies matter)
- Test after each task
- Report issues immediately
- Voice notification when complete
