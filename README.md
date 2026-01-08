# Global Claude Code Workflow System

**Created**: 2026-01-08
**Philosophy**: Boris's vanilla approach + Top 1% Agentic Engineering + Latest Claude Code 2025 features

## ✅ What's Been Built (Core Infrastructure)

### Configuration Files
- ✅ `CLAUDE.md` - Global rules (192 lines - under 200 limit!)
- ✅ `settings.local.json` - YOLO mode + comprehensive hooks + voice notifications
- ✅ `scripts/speak.sh` - ElevenLabs TTS voice notifications

### Commands (8/12 Complete)
- ✅ `/create-prd` - Create product requirements document
- ✅ `/research` - Consult docs, find boilerplates (prevents hallucination!)
- ✅ `/code-review` - Ruthless senior dev code review
- ✅ `/commit-push-pr` - Automated git workflow with bash pre-computation
- ✅ `/ui-design` - Design mockups before implementation
- ✅ `/guide` - Step-by-step workflow coordinator (YOUR MAIN COMMAND!)
- ✅ `/prime` - Load context for planning sessions
- ⏳ `/plan` - Create structured execution plans (TODO)
- ⏳ `/execute` - Execute plans in fresh context (TODO)
- ⏳ `/parallel-branches` - Multi-branch parallel work (TODO)
- ⏳ `/superpowers` - Multi-repo orchestration (TODO)
- ⏳ `/verify-app` - E2E testing (TODO)
- ⏳ `/system-evolve` - Capture learnings from bugs (TODO)

### Subagents (2/7 Complete)
- ✅ `orchestrator` - Quality check coordinator (auto-invoked by Stop-Hook!)
- ✅ `frontend` - UI-first enforcement with design approval checks
- ⏳ `research-ui-patterns` - Deep UI research (YouTube, GitHub, Reddit, X) (TODO)
- ⏳ `verify-app` - Comprehensive E2E verification (TODO)
- ⏳ `code-simplifier` - Post-implementation cleanup (TODO)
- ⏳ `react-native-expert` - RN specialized expertise (TODO)
- ⏳ `bash-runner` - Long-running bash with notifications (TODO)

### Directories Created
- ✅ `~/.claude/scripts/` - Voice notification scripts
- ✅ `~/.claude/commands/` - Slash command workflows
- ✅ `~/.claude/agents/` - Specialized subagents
- ✅ `~/.claude/skills/` - Skills (ui-design to be added)
- ✅ `~/.claude/reference/` - Task-specific context docs (to be populated)

## 🎯 Core Workflow (Ready to Use NOW!)

Even though not everything is complete, you can start using the core workflow:

### Guided Development (Recommended)

```bash
# Start guided workflow
claude /guide

# Guides you through:
# 1. Create PRD (if needed)
# 2. Research (consult docs, find boilerplates)
# 3. UI design (approve mockups)
# 4. Plan (with /prime)
# 5. Execute
# 6. Verify
# 7. Commit
# 8. Learn
```

### Manual Development (If You Prefer)

```bash
# 1. Research first (prevents hallucination!)
claude /research "topic"

# 2. UI design (if UI feature)
claude /ui-design "component"

# 3. Prime for planning
claude /prime

# 4. Build feature
# [implementation happens]

# 5. Review
claude /code-review

# 6. Commit
claude /commit-push-pr
```

## 🔑 Key Features Working NOW

### YOLO Mode
- `dangerouslySkipPermissions: true` in settings.local.json
- Most operations run autonomously
- Voice alerts when you need to provide input

### Voice Notifications (ElevenLabs)
- "Starting agent task" - when agent begins
- "Agent task completed" - when agent finishes
- "ATTENTION. Claude needs your input NOW" - when you must respond
- "Session complete" - when workflow ends

### Auto Quality Checks (Orchestrator)
- Automatically runs when Claude finishes
- Analyzes git changes
- Invokes appropriate quality agents
- Reports issues before you commit

### UI-First Enforcement (Frontend Agent)
- Hook prevents UI code without approved design
- Enforces mockup approval workflow
- Compares implementation to approved design

### Self-Learning
- PostToolUse hook asks: "Was this fixing a struggle?"
- Stop hook reminds: "Run /system-evolve to capture learnings"
- Institutional knowledge grows over time

## 📋 API Keys & Environment Variables

Copy `.env.example` to `.env` and fill in your API keys:

```bash
cp ~/.claude/.env.example ~/.claude/.env
# Edit ~/.claude/.env with your actual API keys
```

Then source in your shell:

```bash
echo "source ~/.claude/.env" >> ~/.zshrc  # or ~/.bashrc
source ~/.zshrc
```

Required API keys (see `.env.example` for details):
- `OPENROUTER_API_KEY`: For LLM Council multi-model access
- `ELEVENLABS_API_KEY`: For voice notifications (optional)
- `GITHUB_TOKEN`: For git operations and PR creation
- `COMPOSIO_API_KEY`: For integrations (optional)
- `RUBE_API_KEY`: For workflow automation (optional)

## 🚀 Quick Start

### For a New Project

```bash
# 1. Start guided workflow
claude /guide

# Guides you through PRD creation, research, and first feature

# 2. Follow the prompts!
# Guide tells you exactly what to do at each step
```

### For an Existing Project

```bash
# 1. Create PRD documenting current state + what's next
claude /create-prd PRD.md

# 2. Start guided workflow for next feature
claude /guide
```

## ⏳ What Still Needs to Be Created

### Commands (5 remaining)
- `/plan` - Create structured execution plans
- `/execute` - Execute plans in fresh context
- `/parallel-branches` - Work on multiple branches simultaneously
- `/superpowers` - Multi-repo orchestration
- `/verify-app` - E2E testing
- `/system-evolve` - Capture learnings, improve system

### Subagents (5 remaining)
- `research-ui-patterns` - Deep UI research across platforms
- `verify-app` - Comprehensive E2E verification
- `code-simplifier` - Post-implementation cleanup
- `react-native-expert` - RN specialized expertise
- `bash-runner` - Long-running bash workflows

### Reference Docs (6 docs)
- `api-development.md` - API patterns, validation, security
- `frontend-components.md` - Component patterns, state management
- `mobile-patterns.md` - React Native specifics, performance
- `database-schema.md` - Supabase/PostgreSQL, RLS policies
- `testing-strategy.md` - Testing patterns, coverage
- `deployment.md` - CI/CD, builds, releases

### Skills (1 skill)
- `ui-design.md` - UI design workflow (consider using community version)

## 🎓 Next Steps

### This Session
Continue creating remaining commands and subagents

### Future Sessions
1. Populate reference docs with project learnings
2. Add institutional knowledge to CLAUDE.md as bugs are encountered
3. Install Ralph Wiggum plugin for autonomous long-running tasks
4. Configure MCP servers (Rube already in settings)
5. Test complete workflows end-to-end

## 📊 System Capabilities (When Complete)

### Multi-Terminal Parallel Execution
- Terminal 1: Main orchestration
- Terminals 2-5: Parallel agents (@frontend, @backend, @testing, @bash)
- Voice notifications coordinate work

### LLM Council (Multiple Models)
- Gemini Flash: Fast, cheap iterations
- Claude Opus 4.5: Complex planning
- GPT-4o: General development
- Grok Vision: UI/screenshot analysis

### Autonomous Long-Running Work (Ralph Wiggum)
- Multi-hour/multi-day execution
- Clear completion criteria
- Progress tracking
- Cost controls (max iterations)

### Intelligent Quality Checks (Orchestrator)
- Analyzes changes automatically
- Invokes relevant quality agents
- Parallel execution of checks
- Blocks commits if issues found

## 📖 Documentation

- **Plan**: `/Users/ashleytower/.claude/plans/peppy-strolling-prism.md` - Full implementation plan
- **This README**: Overview and status
- **Global Rules**: `CLAUDE.md` - Universal rules (<200 lines)
- **Commands**: Individual command documentation in `commands/`
- **Agents**: Individual agent configuration in `agents/`

## 🎤 Voice Notifications

Voice will alert you for:
- Agent starting/completing
- Need for user input
- Session completion
- Quality check results

Even when away from desk, you'll know when to return!

## 🔒 Safety

Even in YOLO mode:
- Destructive commands blocked (`rm -rf /`, `sudo`, `chmod 777`)
- Voice alerts for critical decisions
- Quality checks before commits
- Design approval before UI implementation

---

**Status**: Core infrastructure complete and working!
**Ready to use**: `/guide`, `/research`, `/ui-design`, `/code-review`, `/commit-push-pr`, `/prime`
**Next**: Create remaining commands/agents and test end-to-end workflow
