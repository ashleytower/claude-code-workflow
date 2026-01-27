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

## External Services - ALWAYS USE MCP

**CRITICAL: NEVER ask the user to manually deploy, configure, or access external services. USE MCP TOOLS.**

### Rube MCP (Primary)
```
mcp__rube__RUBE_SEARCH_TOOLS    → Find the right tool
mcp__rube__RUBE_MANAGE_CONNECTIONS → Ensure connection active
mcp__rube__RUBE_MULTI_EXECUTE_TOOL → Execute the operation
```

**Available via Rube:** Supabase, Vercel, Google (Gmail/Calendar/Drive/Sheets), GitHub, Slack, Stripe, Resend

### Vercel MCP (Deployments)
```
mcp__claude_ai_Vercel__deploy_to_vercel → Deploy app
mcp__claude_ai_Vercel__list_projects → List projects
mcp__claude_ai_Vercel__get_deployment_build_logs → Check logs
mcp__claude_ai_Vercel__list_deployments → Deployment history
```

### V0 MCP (UI Generation)
```
v0_generate_ui → Generate UI from text prompt
v0_generate_from_image → Generate UI from design image
v0_chat_complete → Iterate on existing UI
v0_setup_check → Verify API connection
```

### Railway MCP (Backend)
```
mcp__railway__deploy → Deploy service
mcp__railway__list-services → List services
mcp__railway__get-logs → Check logs
mcp__railway__set-variables → Set env vars
```

**RULE: If an MCP tool exists, USE IT. Never tell user to "go to Vercel" or "go to Railway".**

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
