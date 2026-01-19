# Handoff Command

**Purpose**: Create a session handoff document to continue work in a fresh context.

## Usage

```bash
/handoff
# Creates handoff at ~/.claude/handoffs/NEXT_SESSION_START_HERE.md

/handoff "feature-name"
# Creates handoff at ~/.claude/handoffs/feature-name.md
```

## When to Use

- Context at 70%+ (Claude should auto-trigger, but you can force it)
- End of work session
- Before switching to a different task
- Anytime you want to preserve state

## What Claude Does

1. **Announce**: Speak "Creating handoff document"
2. **Summarize**: Current task, completed work, in progress, next steps
3. **Save**: Write to handoff file
4. **Confirm**: Speak "Handoff created. Safe to exit."

## Handoff Template

```markdown
# Session Handoff - [Date/Time]

## Current Task
[One line: what we're building]

## Status
- **Phase**: [Current /guide phase if applicable]
- **Branch**: [git branch]
- **Context Used**: [approximate %]

## Completed This Session
- [x] Item 1
- [x] Item 2

## In Progress
- [ ] Current work item

## Next Steps (Priority Order)
1. [Most important next action]
2. [Second action]
3. [Third action]

## Key Context for Next Session
- [Critical decision made]
- [Important file: path/to/file.ts]
- [Blocker or issue to be aware of]
- [API/integration details]

## Files Modified
- path/to/file1.ts - [what changed]
- path/to/file2.ts - [what changed]

## Commands to Resume

Option A (direct):
```
claude "Read this handoff and continue: ~/.claude/handoffs/NEXT_SESSION_START_HERE.md"
```

Option B (guided):
```
/guide
# Then point to handoff when asked
```
```

## Voice Notifications

- Start: "Creating handoff document"
- Complete: "Handoff created. Safe to exit."

## Notes

- Handoff should be detailed enough that a fresh Claude session can continue without asking questions
- Include specific file paths, not just descriptions
- Include any gotchas or things that didn't work
- If tests are failing, note which ones and why
