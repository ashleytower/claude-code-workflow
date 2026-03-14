# AutoMemory Index

Persistent knowledge base across all Claude Code sessions and agent teams.
Last updated: 2026-02-22

## How This Works

- **Topics**: Gotchas, patterns, and learnings organized by subject
- **Research**: Notes from research agents sent into the world
- **Sessions**: Auto-saved session state (managed by hooks)

## Topic Files

| Topic | File | Description |
|-------|------|-------------|
| Vercel | [vercel.md](topics/vercel.md) | Deployment gotchas, config patterns |
| Railway | [railway.md](topics/railway.md) | Service setup, networking, deploys |
| Supabase | [supabase.md](topics/supabase.md) | Auth, RLS, edge functions, gotchas |
| Google Sheets | [google-sheets.md](topics/google-sheets.md) | Service accounts, API quirks |
| Git & GitHub | [git.md](topics/git.md) | Workflow notes, CI/CD patterns |
| General | [general.md](topics/general.md) | Cross-cutting learnings |
| Kie.ai | [kie-ai.md](topics/kie-ai.md) | Image generation API, model selection, prompts |
| OpenClaw Gateway | [openclaw-gateway.md](topics/openclaw-gateway.md) | Gateway stability, watchdog, migration gotchas |

## Research Notes

Research agents save findings here. Query with: `grep -rl "keyword" ~/.claude/memory/research/`

| Date | File | Description |
|------|------|-------------|
| 2026-03-12 | [funnels-landing-pages-mobile-bartending.md](research/2026-03-12-funnels-landing-pages-mobile-bartending.md) | Best converting funnels and landing pages for mobile bartending. Montreal competitor analysis, funnel sequences, photography best practices. |

## Rules

1. Before writing a note, check if a topic file exists. Append if so, create if not.
2. Every entry gets a date and one-line summary.
3. Keep entries concise -- 2-5 lines max per note.
4. Tag entries: `[gotcha]` `[pattern]` `[research]` `[decision]` `[debug]`
5. Prune duplicates when reading a file with 20+ entries.
