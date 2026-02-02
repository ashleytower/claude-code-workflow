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

## Skills - ALWAYS CHECK FIRST

**Before implementing anything new:**
1. Check `~/.claude/skills/` for existing skills
2. If no local skill exists, search skills.sh: `npx skills search <keyword>`
3. Install useful skills: `npx skills add -g -y <owner/repo@skill>`

**When user asks "how do I do X" or needs specialized capability:**
- ALWAYS run `npx skills search <relevant-keywords>` first
- Present found skills and offer to install
- Browse: https://skills.sh/

## Learning Rules
After solving something reusable:
1. **Known service?** (vercel, railway, supabase, google) → Append to existing skill
2. **New service?** → Create new skill via `/learn`
3. **Project-specific?** → Add to project's `./CLAUDE.md`

Existing skills to append to:
- `vercel-*.md`, `supabase-*.md`, `google-*.md`, `railway-*.md`

## External Services - MANDATORY MCP USAGE

**YOU MUST USE MCP TOOLS. THIS IS NOT OPTIONAL.**

When user says ANY of these phrases, IMMEDIATELY use Rube MCP. Do NOT say "I can't access that" or "you'll need to do that manually":

| User Says | You Do |
|-----------|--------|
| "deploy to Vercel", "push to Vercel", "ship it" | Use Rube → Vercel deploy |
| "check Supabase", "query the database", "look at the data" | Use Rube → Supabase |
| "check Google Docs", "look at the doc", "read the spreadsheet" | Use Rube → Google Drive/Docs/Sheets |
| "send an email", "email them" | Use Rube → Gmail or Resend |
| "check my calendar", "schedule it" | Use Rube → Google Calendar |
| "post to Slack", "message the channel" | Use Rube → Slack |
| "check GitHub", "look at the PR", "check issues" | Use Rube → GitHub |
| "check Stripe", "look at payments" | Use Rube → Stripe |

### Rube MCP - USE THIS FIRST

**Every agent MUST use Rube for external services. No exceptions. No "I can't do that."**

```
mcp__rube__RUBE_SEARCH_TOOLS       → Find the right tool (search first!)
mcp__rube__RUBE_MANAGE_CONNECTIONS → Ensure connection is active
mcp__rube__RUBE_MULTI_EXECUTE_TOOL → Execute the operation
```

**Workflow:**
1. `RUBE_SEARCH_TOOLS` with service name (e.g., "vercel deploy", "supabase query")
2. `RUBE_MANAGE_CONNECTIONS` to verify/establish connection
3. `RUBE_MULTI_EXECUTE_TOOL` to run the operation

**Available Services:** Vercel, Supabase, Google (Gmail/Calendar/Drive/Sheets), GitHub, Slack, Stripe, Resend

### Other MCP Tools (Use if Rube doesn't have it)

**Vercel MCP:**
```
mcp__claude_ai_Vercel__deploy_to_vercel → Deploy
mcp__claude_ai_Vercel__list_projects → List projects
mcp__claude_ai_Vercel__get_deployment_build_logs → Check logs
```

**V0 MCP:**
```
v0_generate_ui → Generate UI from text
v0_generate_from_image → Generate UI from image
v0_chat_complete → Iterate on UI
```

**Railway MCP:**
```
mcp__railway__deploy → Deploy
mcp__railway__list-services → List services
mcp__railway__get-logs → Check logs
```

**Tally MCP:**
```
mcp__tally__* → Create forms, get responses, set webhooks
```

**NEVER say "I can't access external services." You CAN. Use Rube MCP.**

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
