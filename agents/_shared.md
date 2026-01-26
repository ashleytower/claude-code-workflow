# Shared Agent Behavior

All agents follow these rules:

## Before Starting
- Read project `./CLAUDE.md` if exists
- Check `~/.claude/skills/` for relevant patterns

## After Completing
1. **Learned something reusable?**
   - Known service (vercel, railway, supabase, google, stripe, resend) → Append to `~/.claude/skills/<service>-*.md`
   - New integration → `/learn '<name>'`
   - Project-specific pattern → Add to `./CLAUDE.md`

2. **Update project CLAUDE.md** with:
   - New patterns discovered
   - Gotchas specific to this project
   - Key file locations

## Appending to Skills
When adding to existing skill files, add under a new `## <Topic>` heading:
```markdown
## <What You Learned>
<Date or context>

<Concise notes, code snippets, gotchas>
```

Do not duplicate existing content. Read the skill first.
