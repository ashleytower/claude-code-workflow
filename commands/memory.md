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

## Auto-Save Rules (for CLAUDE.md)

All agents -- lead, teammates, and research agents -- follow these rules:

### MUST save a memory note when:
- A build/deploy fails for a non-obvious reason and you find the fix
- An API behaves differently than documented
- A workaround is needed for a library/service bug
- A configuration took multiple attempts to get right
- You discover an undocumented requirement or dependency

### MUST save research notes when:
- Sent to investigate a topic, tool, or service
- Comparing multiple approaches or libraries
- Finding pricing, limits, or compatibility info

### DO NOT save:
- Obvious things (e.g., "npm install installs packages")
- One-time debugging steps that won't recur
- User-specific preferences (those go in CLAUDE.md)

## Integration with Agent Teams

When working in an agent team:
1. **All teammates** can read and write to `~/.claude/memory/`
2. **Research teammates** save findings to `research/` with structured notes
3. **Implementation teammates** save gotchas to `topics/` as they encounter them
4. **The lead** should query memory before assigning tasks to check for known issues
5. At team shutdown, the lead reviews if any significant learnings should be captured

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
