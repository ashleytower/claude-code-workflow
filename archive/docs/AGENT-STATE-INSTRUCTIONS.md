# Agent State Management - Instructions for All Agents

**MANDATORY: All agents must follow these coordination rules**

---

## At Start of Agent Session

```bash
# 1. Check if previous agent left state
~/.claude/scripts/agent-state.sh read

# 2. Read the output
# If state exists, you'll see:
# {
#   "last_updated": "2026-01-08T...",
#   "current_agent": "@frontend",
#   "status": "completed",
#   "message": "UI components done",
#   "files_changed": ["app/page.tsx", "components/Button.tsx"],
#   "next_steps": ["Add backend API", "Connect to database"]
# }

# 3. Use this context
# - Review files_changed
# - Read those files to understand what was done
# - Follow next_steps from previous agent
```

## During Agent Work

Use TodoWrite to track progress so other agents can see:

```bash
# Update todos as you work
TodoWrite: {
  todos: [
    {content: "Implement API endpoints", status: "completed"},
    {content: "Add error handling", status: "in_progress"},
    {content: "Write tests", status: "pending"}
  ]
}
```

## At End of Agent Session (MANDATORY)

```bash
# Write your state for next agent
~/.claude/scripts/agent-state.sh write \
  "@your-agent-name" \
  "completed" \
  "Brief summary of what you did" \
  '["file1.ts", "file2.tsx"]' \
  '["Next step 1", "Next step 2"]'

# Example:
~/.claude/scripts/agent-state.sh write \
  "@backend" \
  "completed" \
  "Implemented Stripe API endpoints with webhook handling" \
  '["app/api/stripe/route.ts", "app/api/webhooks/route.ts", "lib/stripe.ts"]' \
  '["Frontend: Add checkout UI", "Testing: Verify webhook handling"]'
```

## Multi-Agent Workflow Example

```
Terminal 1 (@frontend):
1. Check state: No previous agent
2. Do work: Create UI components
3. Write state:
   - Status: "completed"
   - Files: ["app/checkout/page.tsx"]
   - Next: ["Backend: Add Stripe API"]

Terminal 2 (@backend):
1. Check state: Frontend completed
2. Read: app/checkout/page.tsx
3. Do work: Add Stripe API
4. Write state:
   - Status: "completed"
   - Files: ["app/api/stripe/route.ts"]
   - Next: ["Testing: Verify E2E flow"]

Terminal 3 (@verify-app):
1. Check state: Backend completed
2. Read: All changed files
3. Do work: E2E testing
4. Write state:
   - Status: "completed"
   - Next: ["Ready for PR"]
```

---

## Integration with Hooks

### StartSession Hook
Automatically prompts you to check agent state.

### PostToolUse Hook
Reminds you to update state after major operations.

### Stop Hook
Prompts you to write final state before stopping.

---

## State File Location

```
.claude/agent-state.json
```

**Format**:
```json
{
  "last_updated": "ISO-8601 timestamp",
  "current_agent": "@agent-name",
  "status": "completed|in_progress|blocked",
  "message": "Human-readable summary",
  "files_changed": ["file1", "file2"],
  "next_steps": ["step1", "step2"],
  "history": [
    {
      "agent": "@previous-agent",
      "status": "completed",
      "message": "Previous work",
      "timestamp": "...",
      "files_changed": [...],
      "next_steps": [...]
    }
  ]
}
```

---

## Why This Matters

**Without state management**:
- Agents don't know what previous agents did
- Duplicate work
- Conflicts
- Missing context

**With state management**:
- Seamless handoffs
- No duplicate work
- Context preservation
- Coordinated progress

---

## Commands Reference

```bash
# Read current state
~/.claude/scripts/agent-state.sh read

# Get last agent name
~/.claude/scripts/agent-state.sh last

# Get next steps
~/.claude/scripts/agent-state.sh next

# Write state (5 args)
~/.claude/scripts/agent-state.sh write <agent> <status> <message> <files_json> <steps_json>

# Clear state (start fresh)
~/.claude/scripts/agent-state.sh clear
```

---

**REMEMBER**: State management is MANDATORY, not optional. Always check state at start, always write state at end.
