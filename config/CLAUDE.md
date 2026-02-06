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
- **Tags**: `[gotcha]` `[pattern]` `[research]` `[decision]` `[debug]`
- **Format**: `### YYYY-MM-DD - Summary\n[tag] 2-5 line note.`
- **Agent teams**: All teammates read/write memory. Lead queries before assigning tasks.
- **Query**: `grep -rl "keyword" ~/.claude/memory/`
- **10+ notes on one service?** Graduate to `/learn` skill.

### Auto-Save Triggers (agents must self-monitor)
Save to `~/.claude/memory/topics/<topic>.md` AUTOMATICALLY when any of these happen:
1. **Retry pattern**: You tried approach A, it failed, then approach B worked. Save what failed and why B worked.
2. **Docs were wrong/outdated**: API or docs said X, but reality was Y. Save the discrepancy.
3. **Config discovery**: A non-obvious env var, flag, or setting was needed. Save the exact config.
4. **Error decoding**: An error message was misleading or required research to understand. Save error → real cause → fix.
5. **Version/compat issue**: Something broke due to version mismatch or deprecation. Save versions and workaround.
6. **Wasted time**: Anything that took 3+ attempts to get right. Save the shortcut for next time.

Save to `~/.claude/memory/research/YYYY-MM-DD-<topic>.md` when:
7. **Research task**: You were sent to investigate something. Always save structured findings.
8. **Comparison made**: You evaluated 2+ options. Save the comparison and conclusion.

Do NOT wait to be asked. If a trigger fires, save immediately, then continue working.

### Agent Team Debrief (REQUIRED at team shutdown)
Before the lead cleans up a team, the lead MUST:
1. Ask each teammate: "What was harder than expected? What broke? What did you figure out?"
2. Compile a debrief to `~/.claude/memory/research/YYYY-MM-DD-team-debrief-<project>.md` with:
   - **What went smoothly**: Tasks that worked first try
   - **What was hard**: Issues that required retries or workarounds
   - **Key learnings**: Non-obvious fixes, gotchas, patterns discovered
   - **Unresolved**: Anything still broken or unclear
3. Ensure individual teammate learnings were saved to topic files during work
4. Report the debrief summary to the user

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
