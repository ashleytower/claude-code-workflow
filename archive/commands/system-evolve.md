---
name: system-evolve
description: Learn from bugs and improve the system
model: opus
---

# System Evolve - Institutional Learning

Fix the system, not just the bug. Capture learnings so mistakes don't repeat.

## Philosophy

**"Every bug is a system failure"**

- Bug happened → System didn't prevent it
- Fixed bug → But will it happen again?
- System evolution → Update CLAUDE.md, add hooks, create guards

**We don't just fix bugs. We evolve the system to prevent entire classes of bugs.**

## When to Use

After encountering ANY of these:

- ❌ **Bugs**: Something broke that shouldn't have
- ❌ **Manual fixes**: Had to fix what Claude wrote
- ❌ **Multiple attempts**: Took 3+ tries to get right
- ❌ **Integration issues**: Components didn't work together
- ❌ **Performance problems**: Code was slow/inefficient
- ❌ **Pattern violations**: Didn't follow established patterns
- ❌ **Missing safeguards**: No validation caught bad data
- ❌ **Repeated mistakes**: Same issue happened before

## Process

### Step 1: Capture the Issue

```markdown
## What Happened?

Describe the bug/issue:
- What broke?
- What was the symptom?
- What caused it?
- How was it discovered?
```

### Step 2: Root Cause Analysis

**5 Whys technique**:

```markdown
## Root Cause

1. Why did the bug occur?
   → Because validation was missing

2. Why was validation missing?
   → Because we didn't have a pattern for it

3. Why didn't we have a pattern?
   → Because this is a new API integration

4. Why didn't Claude know to add validation?
   → Because CLAUDE.md doesn't mention API validation

5. **Root cause**: No documented pattern for API validation
```

### Step 3: System Updates

Based on root cause, update the system:

#### A. Update CLAUDE.md (Institutional Knowledge)

Add to appropriate section:

```markdown
## API Development

**Learnings**:
- Always validate external API responses
  - Check for null/undefined
  - Validate expected shape
  - Handle error responses
  - Example: Use Zod schemas for validation
```

#### B. Add Hooks (Automated Enforcement)

Create hooks to catch issues automatically:

```json
{
  "PreToolUse": [{
    "matcher": {"tools": ["Write", "Edit"]},
    "hooks": [{
      "type": "prompt",
      "prompt": "If writing API integration code: Did you add response validation? Use Zod schema or similar."
    }]
  }]
}
```

#### C. Create Reference Docs

If pattern is complex, create reference doc:

```bash
# Create reference
~/.claude/reference/api-integration-patterns.md
```

#### D. Update Commands/Agents

If command/agent should enforce this:

```markdown
# In /research command
- Check API documentation
- **Verify response schemas**
- Look for error codes
```

### Step 4: Verify Prevention

Test that system now prevents this issue:

```bash
# Try to reproduce the issue
# System should now catch it earlier
```

### Step 5: Document Learning

Add to CLAUDE.md Institutional Knowledge section:

```markdown
## Institutional Knowledge

### API Development

**2026-01-08**: Supabase storage.upload() returns nested data
- Response: `{data: {data: {...}}}`
- Must unwrap twice
- Added validation hook

**2026-01-07**: React Native KeyboardAvoidingView iOS only
- Android handles automatically
- Must use Platform.select
- Added to mobile-patterns reference
```

## Example: Real System Evolution

### Issue
Claude wrote Supabase RLS policies but didn't ENABLE them. Tables had policies defined but not enforced.

### Root Cause
CLAUDE.md mentioned "RLS policies" but not the critical ENABLE step.

### System Updates

**1. Updated CLAUDE.md**:
```markdown
## Database

**Learnings**:
- RLS policies must be ENABLED, not just defined
  - Define: `CREATE POLICY ...`
  - Enable: `ALTER TABLE users ENABLE ROW LEVEL SECURITY;`
  - Check: `SELECT * FROM pg_tables WHERE tablename='users';` (rowsecurity=true)
```

**2. Added Hook**:
```json
{
  "PostToolUse": [{
    "matcher": {"tools": ["Write"]},
    "hooks": [{
      "type": "prompt",
      "prompt": "If you created RLS policies: Did you ENABLE RLS on the table? (ALTER TABLE ... ENABLE ROW LEVEL SECURITY)"
    }]
  }]
}
```

**3. Created Reference**:
`~/.claude/reference/database-schema.md` with complete RLS checklist

**4. Updated @database-expert agent**:
```markdown
## RLS Verification

Check:
1. [ ] Policy defined (CREATE POLICY)
2. [ ] RLS enabled (ALTER TABLE ... ENABLE)
3. [ ] Policy active (pg_policies query)
```

### Result
System now catches RLS mistakes automatically. Won't happen again.

## System Evolution Checklist

After fixing any issue:

- [ ] Root cause identified (5 whys)
- [ ] CLAUDE.md updated (Institutional Knowledge)
- [ ] Hooks added (if automatable)
- [ ] Reference docs created (if complex)
- [ ] Commands/agents updated (if relevant)
- [ ] Prevention verified (test system catches it)
- [ ] Learning documented (with date)

## Integration with Stop Hook

Stop hook prompts you:

```bash
"Did we encounter issues requiring /system-evolve?"
```

Don't skip this! Each evolution makes the system smarter.

## Integration with Ralph Loop

```bash
# Ralph Loop encounters repeated issue
# → Stop and evolve
/system-evolve "Ralph Loop keeps failing on X"

# → Update system
# → Resume Ralph Loop
# → Issue prevented
```

## Compound Effect

**One system evolution prevents hundreds of future bugs.**

After 10 evolutions:
- CLAUDE.md is comprehensive
- Hooks catch common mistakes
- Reference docs cover patterns
- System is robust

**This is how you build a system that rarely makes mistakes.**

## Voice Notification

```bash
~/.claude/scripts/speak.sh "System evolution complete. Knowledge captured."
```

## Notes

- Uses Opus (best reasoning for analysis)
- Most important command for long-term quality
- Each evolution prevents entire classes of bugs
- Creates institutional knowledge
- Compounds over time
- Makes future development faster and safer

---

**Philosophy**: "Systems, not individuals." Build a system that prevents mistakes, not just fixes them.

**Sources:**
- [Ralph Wiggum: Autonomous Loops](https://paddo.dev/blog/ralph-wiggum-autonomous-loops/)
- [Awesome Claude: Learning Systems](https://awesomeclaude.ai/ralph-wiggum)
