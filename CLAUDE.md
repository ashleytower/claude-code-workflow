# Claude Code Rules

## Style
No emojis. No celebration. Facts only. Read before editing. Summarize when done.

## Workflow
1. Plan first (shift+tab x2)
2. Research docs before coding
3. Implement
4. `@code-reviewer` then `/verify-app`
5. `/commit-push-pr`

## Commands
`/guide` `/research` `/verify-app` `/commit-push-pr` `/learn` `/resume`

## Agents
`@frontend` `@backend` `@code-reviewer` `@verify-app` `@code-simplifier`

## Skills
Check `~/.claude/skills/` before implementing integrations.

## Learning Rules
After solving something reusable:
1. **Known service?** (vercel, railway, supabase, google) → Append to existing skill
2. **New service?** → Create new skill via `/learn`
3. **Project-specific?** → Add to project's `./CLAUDE.md`

Existing skills to append to:
- `vercel-*.md`, `supabase-*.md`, `google-*.md`, `railway-*.md`

## External Services (Rube MCP)
```
RUBE_SEARCH_TOOLS → Find tool
RUBE_MANAGE_CONNECTIONS → Connect
RUBE_MULTI_EXECUTE_TOOL → Execute
```

## Browser Testing
```bash
agent-browser open <url>
agent-browser snapshot -i
agent-browser click @e1
```

## Context Management
Compact when: repeated reads, resolved errors cleared, exploration done.

## Session Handoff
End: update `~/.claude/handoffs/NEXT_SESSION_START_HERE.md`
Start: `/resume`

## Permissions
Auto-approves most. Blocks: Stripe, Resend, prod deploys, force push, db reset.
