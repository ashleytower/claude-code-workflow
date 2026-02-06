# Memory Command

**Purpose**: Save and query persistent notes across sessions and agent teams. Lightweight counterpart to `/learn` (which saves polished integration skills).

## Usage

```bash
# Save a note to a topic
/memory save "vercel" "Vercel builds fail silently when env vars have trailing spaces"

# Save research findings
/memory research "livekit-scaling" "Findings from investigating LiveKit horizontal scaling"

# Query memory for a keyword
/memory query "google sheets"

# List all topics
/memory list

# Prune a topic file (remove duplicates, stale entries)
/memory prune "vercel"
```

## How It Works

### Memory Location
```
~/.claude/memory/
├── INDEX.md              # Master index linking all topic files
├── topics/               # Gotchas, patterns, decisions by subject
│   ├── vercel.md
│   ├── railway.md
│   ├── supabase.md
│   ├── google-sheets.md
│   ├── git.md
│   └── general.md
├── research/             # Research agent findings
│   ├── 2026-02-06-livekit-scaling.md
│   └── 2026-02-10-auth-providers.md
└── sessions/             # Auto-saved session state (managed by hooks)
    └── last_session_*.json
```

### Save a Note

When `/memory save <topic> <note>` is invoked:

1. Check if `~/.claude/memory/topics/<topic>.md` exists
2. If yes, append the note with today's date and a tag
3. If no, create the file, add it to INDEX.md, then write the note
4. Tags: `[gotcha]` `[pattern]` `[research]` `[decision]` `[debug]`

Format for each entry:
```markdown
### YYYY-MM-DD - One-line summary
[tag] Detailed note. 2-5 lines max.
```

### Save Research

When `/memory research <topic> <description>` is invoked:

1. Create `~/.claude/memory/research/YYYY-MM-DD-<topic>.md`
2. Write structured research notes:
   - **Question**: What was being investigated
   - **Findings**: Key discoveries (bulleted)
   - **Sources**: URLs, docs, repos referenced
   - **Actionable**: What to do with this knowledge
3. Add a one-line entry to the relevant topic file linking to the research

### Query Memory

When `/memory query <keyword>` is invoked:

1. Search all files in `~/.claude/memory/` recursively for the keyword
2. Return matching entries with file paths and context
3. If nothing found, say so -- do not fabricate memories

### Prune

When `/memory prune <topic>` is invoked:

1. Read the topic file
2. Remove duplicate entries (same insight, different wording)
3. Remove entries that are now captured in a `/learn` skill file
4. Consolidate related entries
5. Keep the file under 50 entries

## Auto-Save Triggers

Agents do NOT wait to be told. These triggers fire automatically during work:

### Trigger 1: Retry Pattern
You tried approach A, it failed, then approach B worked.
- Save: what failed, why, and what worked instead.
- Tag: `[gotcha]`

### Trigger 2: Docs Were Wrong
API or docs said X, but reality was Y.
- Save: the discrepancy and the actual behavior.
- Tag: `[gotcha]`

### Trigger 3: Config Discovery
A non-obvious env var, flag, or config setting was required.
- Save: the exact config that was needed.
- Tag: `[pattern]`

### Trigger 4: Error Decoding
An error message was misleading or took research to understand.
- Save: error message → real cause → fix.
- Tag: `[debug]`

### Trigger 5: Version/Compat Issue
Something broke due to version mismatch or deprecation.
- Save: the versions involved and the workaround.
- Tag: `[gotcha]`

### Trigger 6: Wasted Time
Anything that took 3+ attempts to get right.
- Save: the shortcut for next time.
- Tag: `[gotcha]`

### Trigger 7: Research Task
You were sent to investigate something.
- Save: structured findings to `research/YYYY-MM-DD-<topic>.md`
- Tag: `[research]`

### Trigger 8: Comparison Made
You evaluated 2+ options and made a choice.
- Save: the comparison and conclusion.
- Tag: `[decision]`

### DO NOT save:
- Obvious things (e.g., "npm install installs packages")
- One-time debugging steps that won't recur
- User-specific preferences (those go in CLAUDE.md)

## Integration with Agent Teams

When working in an agent team:
1. **All teammates** read memory at start, write during work (triggers above are mandatory)
2. **Research teammates** save findings to `research/` with structured notes
3. **Implementation teammates** save gotchas to `topics/` as they encounter them
4. **The lead** queries memory before assigning tasks to check for known issues

### Team Debrief (REQUIRED before team cleanup)

Before the lead shuts down a team, the lead MUST run a debrief:

1. **Ask each teammate**: "What was harder than expected? What broke? What did you figure out?"
2. **Compile a debrief** to `~/.claude/memory/research/YYYY-MM-DD-team-debrief-<project>.md`:
   - **What went smoothly**: Tasks completed first try
   - **What was hard**: Issues requiring retries or workarounds
   - **Key learnings**: Non-obvious fixes, gotchas, patterns
   - **Unresolved**: Anything still broken or unclear
3. **Verify**: Check that individual teammate learnings were saved to topic files
4. **Report**: Summarize the debrief to the user before cleanup

## Integration with /learn

`/memory` and `/learn` are complementary:
- `/memory` = quick notes, raw findings, gotchas (append-only, lightweight)
- `/learn` = polished, structured integration skills (curated, reusable code)

When a topic in memory accumulates 10+ entries about the same service, consider running `/learn` to graduate it into a proper skill file.

## Voice Notification

```bash
# After memory save
"Note saved to [topic]"
```
