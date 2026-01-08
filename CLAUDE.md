# Global Claude Code Configuration

> Universal rules and workflows that apply to ALL projects
> Project-specific details belong in each project's ./CLAUDE.md file

## Quick Obligations (Non-Negotiable)

- **ALWAYS** check docs BEFORE any Write/Edit (enforced by hook - use /research or Grep/Read)
- **ALWAYS** verify approach exists in official docs (NO GUESSING)
- **ALWAYS** search existing codebase for patterns (Grep before Write)
- **ALWAYS** check CLAUDE.md for established patterns
- **ALWAYS** start with PRD for new projects (run `/create-prd`)
- **ALWAYS** verify dependencies are up-to-date (2026+)
- **ALWAYS** design UI mockups BEFORE implementing (run `/ui-design`)
- **ALWAYS** plan before implementing (Plan mode or `/plan`)
- **ALWAYS** verify after implementation (run `/verify-app`)
- **ALWAYS** treat bugs as system evolution opportunities (run `/system-evolve`)
- **NEVER** write code without checking docs first (hook enforces this)
- **NEVER** use outdated patterns or dependencies
- **NEVER** commit without passing tests
- **NEVER** celebrate or use emojis (facts only)

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

## Reference Docs (Load Only When Needed)

- API development: `~/.claude/reference/api-development.md`
- Frontend components: `~/.claude/reference/frontend-components.md`
- Mobile patterns: `~/.claude/reference/mobile-patterns.md`
- Database: `~/.claude/reference/database-schema.md`
- Testing: `~/.claude/reference/testing-strategy.md`
- Deployment: `~/.claude/reference/deployment.md`

## Quality Standards

- No `any` types without justification
- 80%+ test coverage for critical paths
- All linting must pass
- Auto-format on save (automated via hooks)

## Automation Rules

- **Command when**: Prompt used >2x
- **Subagent when**: Specialized expertise needed repeatedly
- **Update reference when**: Patterns emerge
- **Update CLAUDE.md when**: Learn from bugs

## Guided Workflow (Use /guide)

1. PRD → 2. Research → 3. UI Design → 4. Plan → 5. Context Reset → 6. Execute → 7. Verify → 8. Commit → 9. Learn

## Ralph Loop (Autonomous Execution)

**Continuous autonomous loop** - keeps running until task is actually complete, not just when Claude thinks it's done.

- **Outer loop**: Ralph verification loop (checks completion, restarts if needed)
- **Inner loop**: Standard Claude tool loop
- **Use case**: Large refactors, overnight autonomous development, mechanical tasks
- **Safety**: Max iterations, cost limits, completion verification

```bash
/ralph-loop "Migrate all components to TypeScript"
# Runs autonomously, voice notifies when complete
```

**Integration**: Combine with `/superpowers` for multi-repo overnight development

## Parallel Execution (5 Terminals)

- **Terminal 1**: Main (planning, coordination)
- **Terminals 2-5**: Agents (@frontend, @backend, @testing, @bash)
- Voice notifications alert when complete or need input!

## Commands Reference

| Command | Purpose |
|---------|---------|
| `/guide` | Step-by-step feature guidance (auto-detects new vs existing project) |
| `/create-prd` | Create product requirements |
| `/research` | Consult docs, find boilerplates |
| `/ui-design` | Design UI before coding |
| `/prime` | Load context for planning |
| `/plan` | Create structured execution plan |
| `/execute` | Execute plan (fresh context!) |
| `/commit-push-pr` | Automated git workflow |
| `/code-review` | Ruthless senior dev review |
| `/verify-app` | E2E testing and verification |
| `/learn` | **Save implementation as reusable skill** |
| `/parallel-branches` | Multi-branch parallel work |
| `/superpowers` | Multi-repo orchestration |
| `/system-evolve` | Learn from bugs, improve system |
| `/ralph-loop` | Autonomous loop until task complete |
| `/update-council` | Update LLM models to latest |
| `/self-update` | Update Claude Code and ecosystem |

## Agents Reference

- `@frontend`: UI development (enforces ui-design)
- `@backend`: API/server development
- `@orchestrator`: Quality check coordinator (auto-invoked)
- `@research-ui-patterns`: Deep UI research
- `@code-simplifier`: Post-implementation cleanup
- `@verify-app`: Comprehensive E2E verification
- `@react-native-expert`: RN expertise
- `@bash`: Long-running bash (context: fork, agent: bash)

## Authentication (Zero Time Waste)

**Use `/auth` skill - picks right solution automatically**

### Framework → Auth Solution
- Next.js (fast) → Clerk (1 day)
- Next.js (cheap) → Supabase (2 days, 5x free tier)
- React Native/Expo → Supabase (best mobile)
- FastAPI/Python → Supabase (Python SDK)
- Any framework → NextAuth.js (full control)

**CRITICAL**: Clerk + Supabase integration deprecated (April 2025). Choose one.

**Updates**: Auto-updates weekly (Sunday 3 AM). Manual: `~/.claude/scripts/update-auth-docs.sh`

## Institutional Knowledge

**Two types of learning:**

### 1. Bug/Issue Learning (via /system-evolve)
When you encounter bugs, use `/system-evolve` to capture fixes and update the system.

### 2. Success Learning (via /learn)
When you successfully implement integrations, use `/learn` to save as reusable skills.

**Saved Skills** (~/.claude/skills/):
- `auth.md` - Framework-aware auth (Clerk/Supabase)
- `stripe-payments.md` - Payment processing (when first implemented)
- `resend-emails.md` - Email service (when first implemented)
- `telegram-bot.md` - Bot integration (when first implemented)
- `uploadthing.md` - File uploads (when first implemented)

**Philosophy**: Build it once, save as skill, next time = instant copy-paste.

### Authentication
- 2026-01-08: Auth skill created with framework detection
- Clerk + Supabase integration deprecated (use one or the other)
- Always check latest docs (skill auto-updates weekly)

### React Native
(Add learnings as they emerge)

### Supabase
(Add learnings as they emerge)

### API Development
(Add learnings as they emerge)

### Performance
(Add learnings as they emerge)

## LLM Council (OpenRouter)

- **Opus 4.5** (`anthropic/claude-opus-4.5`): Complex planning, critical features, system architecture
  - Used by: @code-simplifier, @research-ui-patterns
- **GPT-5.2** (`openai/gpt-5.2`): General development, API implementation
  - Used by: @backend
- **Gemini Pro 3** (`google/gemini-3-pro`): Fast iterations, simple tasks, bash orchestration
  - Used by: @bash, @orchestrator
- **Grok 2** (`x-ai/grok-2`): Screenshot analysis, UI review, visual debugging
  - Available for visual tasks
- **Sonnet 4.5** (`anthropic/claude-sonnet-4.5`): Balanced speed/quality, frontend/mobile
  - Used by: @frontend, @react-native-expert, @verify-app

**Auto-updates**: Run `/update-council` or set up daily cron job to keep models current

Specify in agent frontmatter: `model: anthropic/claude-opus-4.5`

## Environment Variables

Copy `.env.example` to `.env` and fill in your API keys:

```bash
cp ~/.claude/.env.example ~/.claude/.env
# Edit ~/.claude/.env with your actual API keys
```

Then source the file in your shell:

```bash
source ~/.claude/.env
```

Required API keys (see `.env.example` for details):
- `OPENROUTER_API_KEY`: For LLM Council multi-model access
- `ELEVENLABS_API_KEY`: For voice notifications
- `GITHUB_TOKEN`: For git operations and PR creation
- `COMPOSIO_API_KEY`: For integrations (optional)
- `RUBE_API_KEY`: For workflow automation (optional)

## Notes

- All config committed to git for team sharing
- CLAUDE.md updated whenever Claude makes mistakes (institutional learning)
- Use Opus 4.5 (thinking enabled) for best results
- Voice notifications keep you informed even when away from desk
- YOLO mode enabled (--dangerously-skip-permissions) for autonomous execution

---

**Last Updated**: 2026-01-08
**Philosophy**: Boris's approach + Autonomous execution + Mandatory research before code + No fluff

**Critical Rules**:
- ALWAYS research docs before writing code (enforced by hook)
- NEVER guess implementations
- NEVER write code without checking existing patterns
- NO celebration messages, NO emojis, NO parties
- Check for Claude Code updates on startup
