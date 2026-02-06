# Claude Code Rules

## Style
No emojis. Facts only. Read before editing. Summarize when done.

## Workflow
Plan first → Research → Implement → `@code-reviewer` → `/verify-app` → `/commit-push-pr`

## Commands
`/guide` `/research` `/verify-app` `/commit-push-pr` `/learn` `/memory` `/resume`

## Agents
`@frontend` `@backend` `@code-reviewer` `@verify-app` `@code-simplifier`

## Skills
Before implementing: check `~/.claude/skills/`, then `npx skills search <keyword>`

## External Services - USE RUBE MCP
For Vercel, Supabase, Google, Slack, GitHub, Stripe, Resend:
1. `RUBE_SEARCH_TOOLS` → find tool
2. `RUBE_MANAGE_CONNECTIONS` → verify connection
3. `RUBE_MULTI_EXECUTE_TOOL` → execute

Fallback MCPs: Vercel MCP, V0 MCP, Railway MCP, Tally MCP

## AutoMemory - ALL AGENTS MUST USE
Quick notes, gotchas, research findings persist in `~/.claude/memory/`.
- **Before starting work**: Read `~/.claude/memory/INDEX.md`, check relevant topic files
- **When you hit a non-obvious issue and fix it**: Append to `~/.claude/memory/topics/<topic>.md`
- **When doing research**: Save to `~/.claude/memory/research/YYYY-MM-DD-<topic>.md`
- **Tags**: `[gotcha]` `[pattern]` `[research]` `[decision]` `[debug]`
- **Format**: `### YYYY-MM-DD - Summary\n[tag] 2-5 line note.`
- **Agent teams**: All teammates read/write memory. Lead queries before assigning tasks.
- **Query**: `grep -rl "keyword" ~/.claude/memory/`
- **10+ notes on one service?** Graduate to `/learn` skill.

## Learning Rules
- Known service → Append to existing skill (`vercel-*.md`, etc.)
- New service → `/learn`
- Quick gotcha or finding → `~/.claude/memory/topics/<topic>.md`
- Research findings → `~/.claude/memory/research/`
- Project-specific → Project's `./CLAUDE.md`

## Session Handoff
End: update `~/.claude/handoffs/NEXT_SESSION_START_HERE.md`
Start: `/resume`

## Permissions
Blocks: Stripe, Resend, prod deploys, force push, db reset
