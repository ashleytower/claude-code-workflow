# Claude Code Workflow

Based on Boris's approach (creator of Claude Code).

## Exploration-First (Best Practice)

**For existing projects, prefer reading code before editing:**

1. Use Read to examine files you're about to edit
2. Check existing patterns with Grep before creating new files
3. Review CLAUDE.md for project-specific conventions

**Good habits:**
- Read the file before editing it
- Check for similar patterns in the codebase
- Cite files/lines when discussing architecture

**Note:** This is guidance for quality, not a blocker. Proceed with edits when you have sufficient context.

---

## Best Practices

**Quality habits (not blockers):**
- Read files before editing them
- Check docs when implementing new integrations
- Search codebase for existing patterns
- Use Rube MCP for external services (Supabase, Vercel, Google)
- Run tests after making changes
- Keep dependencies up-to-date

**Style:**
- No emojis in code or responses
- Facts only, no celebration messages

## External Services (Rube MCP)

**Prefer Rube MCP tools for external services:**

```
mcp__rube__RUBE_SEARCH_TOOLS    → Find the right tool
mcp__rube__RUBE_MANAGE_CONNECTIONS → Ensure connection active
mcp__rube__RUBE_MULTI_EXECUTE_TOOL → Execute the operation
```

**Available integrations:**
- Supabase (migrations, queries, RLS)
- Vercel (deploy, env vars, domains)
- Google (Gmail, Calendar, Drive, Sheets)
- GitHub (issues, PRs, actions)
- Slack (messages, channels)
- Stripe (payments, customers)
- Resend (emails)

**Why:** Rube handles auth, rate limits, and errors.

## Mindset & Process

**PRD-First**: Single document defines entire scope
**Research-First**: Docs + boilerplates before coding
**UI-First**: Mockups + approval before implementation
**Plan → Context Reset → Execute**: Optimal context management
**System Evolution**: Fix the system, not just the bug

## CLAUDE.md Philosophy

**Global (~/.claude/CLAUDE.md)**: LEAN (<200 lines)
- Universal rules that apply everywhere
- Cross-project conventions
- Automation triggers

**Project-Specific (./CLAUDE.md)**: COMPREHENSIVE
- Tech stack details, architecture, APIs, schema, components
- Everything specific to that project

## Tech Stack Overview

- **React Native/Mobile**: TypeScript, Expo SDK, FlashList, React Navigation
- **Python/FastAPI**: Type hints, Pydantic v2, async/await
- **TypeScript/Next.js**: App Router, Server Components, strict mode
- **Supabase/PostgreSQL**: RLS for ALL tables, database functions

**Detailed conventions**: See `.claude/reference/` docs and project CLAUDE.md

| Skill | Purpose | When to Call |
|-------|---------|--------------|
| `Skill(research)` | Check docs, find patterns | Before any new code |
| `Skill(auth)` | Authentication patterns | Adding auth to any framework |
| `Skill(planning)` | Manus-style file planning | Complex multi-step tasks |
| `Skill(guide)` | Step-by-step workflow | Starting a feature |
| `Skill(learn)` | Save implementation | After successful build |
| `Skill(verify-app)` | Run all tests | Before commit |
| `Skill(commit-push-pr)` | Git workflow | Ship the code |
| `Skill(ralph-loop)` | Autonomous execution | Long-running tasks |
| `Skill(init-project)` | Generate project CLAUDE.md | New project setup |

---

## Boris's Setup (What This Follows)

1. **5 Claudes in parallel** - Numbered tabs 1-5, system notifications
2. **Opus 4.5 with thinking** - Best model, less steering
3. **Plan mode first** - shift+tab twice, get plan right
4. **Auto-accept mode** - Let Claude 1-shot it
5. **Verify the work** - Most important thing for quality
6. **Slash commands** - /commit-push-pr dozens of times daily
7. **Shared CLAUDE.md** - Update when Claude does something wrong

## The Workflow

```
1. Plan mode (shift+tab twice)
   -> Go back and forth until plan is right

2. Research ALWAYS (mandatory)
   -> Skill(research) OR Context7 MCP
   -> NO CODE WITHOUT DOCS

3. Execute
   -> Auto-accept mode, let Claude work

4. Simplify (optional)
   -> @code-simplifier to clean up

5. Verify
   -> Skill(verify-app)
   -> This 2-3x's quality

6. Commit
   -> Skill(commit-push-pr)

7. Learn (optional)
   -> Skill(learn) to save for next time
```

## Agents

| Agent | Use For |
|-------|---------|
| `@frontend` | UI work |
| `@backend` | API work |
| `@verify-app` | Run all tests |
| `@code-simplifier` | Clean up after implementation |

## Planning Files (For Complex Tasks)

```
task_plan.md   -> Phases, progress, decisions
findings.md    -> Research, discoveries, errors
progress.md    -> Session log, test results
```

## Rules

1. **DOCS FIRST** - Call Skill(research) or Context7 before code
2. **Plan first** - Good plan = 1-shot implementation
3. **Verify always** - Give Claude feedback loop
4. **Update CLAUDE.md** - When Claude does something wrong

## Notifications

- Voice alert when Claude needs input
- Voice alert when task complete
- macOS notification popup

## Quick Start

```bash
# New project? Generate CLAUDE.md first
/init-project

# Then start guided workflow
/guide "Build my feature"

# Or just use Plan mode
# shift+tab twice -> plan -> execute
```

Required API keys (see `.env.example` for details):
- `OPENROUTER_API_KEY`: For LLM Council multi-model access
- `ELEVENLABS_API_KEY`: For voice notifications
- `GITHUB_TOKEN`: For git operations and PR creation
- `COMPOSIO_API_KEY`: For integrations (optional)
- `RUBE_API_KEY`: For workflow automation (optional)

## Voice & Notifications (Global)

**Setup (2026-01-09):**
- ✅ ElevenLabs voice: `~/.claude/scripts/speak.sh` (all projects)
- ✅ Visual notifications: `~/.claude/scripts/notify.sh` (all projects)
- ✅ WhisperFlow: Voice input (user has installed)

**When agent needs input:**
- 🔊 Speaks: "I need your input"
- 📱 Shows: macOS notification

## Permissions (Global)

**Strategy:** Auto-approve 95% of operations, block dangerous 5%

**Always asks before:**
- Stripe/payment operations
- Sending emails (Resend)
- Production deploys (`vercel --prod`)
- Force pushes (`git push --force`)
- Database resets (`supabase db reset`)
- Recursive deletes (`rm -rf`)

**Auto-approves:**
- Read/Write/Edit files
- Tests, builds, dev
- Normal git operations
- Installing packages
- All MCP tools (except blocked ones)

**See:** `~/.claude/settings.local.json` for full list (154 allow, 22 deny rules)

## Notes

- All config committed to git for team sharing
- CLAUDE.md updated whenever Claude makes mistakes (institutional learning)
- Use Opus 4.5 (thinking enabled) for best results
- Voice + visual notifications keep you informed
- Permission system protects money, emails, production

---

**Last Updated**: 2026-01-09
**Philosophy**: Boris's approach + Autonomous execution + Mandatory research before code + No fluff

**Critical Rules**:
- ALWAYS research docs before writing code (enforced by hook)
- NEVER guess implementations
- NEVER write code without checking existing patterns
- NO celebration messages, NO emojis, NO parties
- Check for Claude Code updates on startup
