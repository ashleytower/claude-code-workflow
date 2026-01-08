# Global CLAUDE.md System - Implementation Plan

## Overview
Recreate your deleted global CLAUDE.md setup with a fresh, streamlined approach combining:
- **Boris's workflow** - Parallel execution, verification loops, 1-shot workflows
- **Latest Claude Code features** (2025) - Context forking, subagent hooks, bash subagent
- **PRD-First Development** - Product requirement docs as north star
- **Modular Rules Architecture** - Task-specific context in .claude/reference/
- **System Evolution Mindset** - Treat every bug as a system improvement opportunity

This replaces the old 29-skill setup with a concise, team-shareable configuration focused on your core workflows.

## Key Principles (Top 1% Agentic Engineering)

### 1. PRD-First Development
- **Always start with a PRD** - Single document defines entire scope
- **North star for all features** - Every feature references the PRD
- **Split into cycles** - Break PRD into manageable feature chunks
- **Brownfield adaptation** - Document what exists + what's next

### 2. Plan → Context Reset → Execute
- **Planning session**: Prime → conversation → create structured plan
- **ALWAYS restart conversation** between planning and execution
- **Execution session**: Just feed the plan document, no priming
- **Why**: Keeps context light for better reasoning during coding

### 3. Modular Rules Architecture
- **Keep global rules lightweight** (<200 lines)
- **Task-specific context** in .claude/reference/
- **Reference section** in CLAUDE.md points to task-specific docs
- **Only load when needed** - Protect context window aggressively

### 4. Command-ify Everything
- **Prompt twice = make a command** - Saves thousands of keystrokes
- **Share workflows** - Team benefits from reusable patterns
- **Inline bash** - Pre-compute to minimize round trips

### 5. System Evolution Mindset
- **Fix the system, not just the bug**
- **Every bug is an opportunity** to improve rules/commands/process
- **Self-reflection after features** - What could we improve?
- **Compound learning** - Agent gets stronger over time

### 6. Boris's Core Tenets
- **Plan first, execute second** - Use Plan mode for non-trivial changes
- **Verification loops are non-negotiable** - Test everything before committing
- **Parallel execution** - Run multiple Claude instances simultaneously
- **1-shot workflows** - Minimize round trips with pre-computation

## Tech Stacks to Support
- React Native / Mobile (iOS/Android)
- Python / FastAPI / PydanticAI
- TypeScript / Node.js / Next.js
- Supabase / PostgreSQL

## File Structure to Create

```
~/.claude/
├── CLAUDE.md                          # Global institutional knowledge (LIGHTWEIGHT)
├── settings.local.json                # Enhanced with permissions, hooks, MCP
├── reference/                         # NEW - Task-specific context
│   ├── api-development.md            # When working on APIs
│   ├── frontend-components.md        # When building UI
│   ├── mobile-patterns.md            # React Native specific
│   ├── database-schema.md            # Supabase/PostgreSQL
│   ├── testing-strategy.md           # Testing patterns
│   └── deployment.md                 # CI/CD, builds, releases
├── commands/                          # NEW - Slash command workflows
│   ├── create-prd.md                 # PRD-first workflow
│   ├── prime.md                      # Load context at session start
│   ├── plan.md                       # Create structured plan
│   ├── execute.md                    # Execute a plan
│   ├── commit-push-pr.md             # Git workflow automation
│   ├── code-review.md                # Senior dev code review simulation
│   ├── parallel-branches.md          # Multi-branch parallel work
│   ├── verify-app.md                 # E2E testing
│   ├── superpowers.md                # Multi-repo orchestration
│   └── system-evolve.md              # Reflect and improve system
├── agents/                            # NEW - Specialized subagents
│   ├── code-simplifier.md            # Post-implementation cleanup
│   ├── verify-app.md                 # Detailed E2E verification
│   ├── react-native-expert.md        # RN specialized expertise
│   └── bash-runner.md                # Long-running bash workflows
└── plans/                             # Structured plans for execution
    └── [dynamic plan files]
```

## Latest Claude Code Features (2025) to Leverage

### Context Forking for Skills/Commands
Add to any skill/command frontmatter to run in isolated context:
```markdown
---
context: fork
model: haiku  # Optional: specify model (defaults to main session model)
agent: bash   # Optional: run within specific subagent type
---
```

**Benefits**:
- Doesn't consume main session context
- Auto hot-reloads when you edit skills (no restart needed)
- Can use faster models for specific tasks

### Subagent Hooks
Define hooks in agent frontmatter for pre/post tool use and stop events:

```markdown
---
name: cloudflare-deploy
description: Deploy to Cloudflare Workers
hooks:
  PreToolUse:
    matcher: "Bash(.*wrangler deploy.*)"
    hooks:
      - type: command
        command: "tsc --noEmit && echo 'Types valid'"
  PostToolUse:
    matcher: "Bash(.*wrangler deploy.*)"
    hooks:
      - type: command
        command: "curl https://api.example.com/health && echo 'Health check passed'"
  Stop:
    hooks:
      - type: command
        command: "osascript -e 'display notification \"Deploy complete\"'"
---
```

**Use cases**:
- Deploy agents: Type check before deploy, health check after
- Test runner agents: Split 100 tests across 10 agents, capture failures
- Research agents: Block write operations in certain directories

### Bash Subagent
Specialized subagent for bash operations:
```bash
@bash npm run build
# Runs in isolated context, passes results back to main session
```

Can be assigned in skill frontmatter:
```markdown
---
agent: bash
---
```

### Skill Usage in Subagents
Allow subagents to trigger skills by adding to agent frontmatter:
```markdown
---
skills: [find-todos, github-release-notes]
---
```

### Other Quality-of-Life Features
- **Wildcard matching**: `Bash(*install*)` matches any install command
- **Ctrl+B**: Move all bash commands and subagents to background at once
- **Skills as slash commands**: Just type `/skill-name` (auto-complete available)
- **Hook "once" option**: `once: true` makes hook run only first time
- **Language parameter**: Set default response language in settings.json
- **/plan command**: Toggle plan mode on/off
- **Permission denied handling**: Subagents now try alternatives instead of stopping

## Implementation Steps

### Step 1: Create Global CLAUDE.md (Lightweight!)
**Location**: `~/.claude/CLAUDE.md`

**CRITICAL**: Keep this <200 lines. Use reference/ directory for detailed context.

**Structure** (inspired by jessfraz's AGENTS.md):

1. **Quick Obligations** - Non-negotiable rules
   - ALWAYS start with PRD for new projects
   - ALWAYS plan before implementing (Plan mode for complex changes)
   - ALWAYS context reset between planning and execution
   - **ALWAYS consult official docs BEFORE writing code** (no hallucination!)
   - **ALWAYS search for boilerplates/existing repos first** (don't start from scratch)
   - **ALWAYS verify dependencies/patterns are up-to-date** (things change fast!)
   - ALWAYS verify after implementation
   - ALWAYS treat bugs as system evolution opportunities
   - NEVER skip verification loops
   - NEVER write code without consulting docs
   - NEVER use outdated patterns or dependencies
   - NEVER commit without running tests

2. **Mindset & Process**
   - PRD-first development: Define scope before coding
   - Plan → context reset → execute cycle
   - Design for 1-shot execution (minimize round trips)
   - Pre-compute in bash before tool calls
   - Protect context window aggressively
   - Verify, then verify again

3. **CLAUDE.md Philosophy**
   - **Global ~/.claude/CLAUDE.md**: LEAN (<200 lines)
     - Universal rules that apply everywhere
     - Cross-project conventions
     - Automation triggers
   - **Project-specific ./CLAUDE.md**: COMPREHENSIVE
     - Project's tech stack details
     - Architecture documentation
     - API endpoints, database schema
     - Component patterns
     - Everything project-specific

4. **Project Structure**
   - `~/path/to/project/` - Main project directory
   - `PRD.md` - Product requirements document (north star)
   - `CLAUDE.md` - Project-specific rules (detailed!)
   - `.claude/reference/` - Task-specific context docs
   - `.claude/plans/` - Structured execution plans

4. **Tech Stack Overview**
   - React Native/Expo, TypeScript/Next.js, Python/FastAPI, Supabase
   - **For detailed conventions**: See `.claude/reference/` docs

5. **Reference Section** (Load context only when needed)
   ```
   - API development: .claude/reference/api-development.md
   - Frontend components: .claude/reference/frontend-components.md
   - Mobile patterns: .claude/reference/mobile-patterns.md
   - Database: .claude/reference/database-schema.md
   - Testing: .claude/reference/testing-strategy.md
   - Deployment: .claude/reference/deployment.md
   ```

6. **Commands to Run**
   - Dev frontend: `npm run dev` or `npx expo start`
   - Dev backend: `uvicorn main:app --reload` or `npm run dev`
   - Tests: `pytest` or `npm test`
   - Format: `prettier --write .` or `black .`
   - Lint: `eslint .` or `ruff check .`

7. **Quality Standards**
   - No 'any' types without justification
   - 80%+ test coverage for critical paths
   - All linting must pass
   - Auto-format on save

8. **Institutional Knowledge** (Evolves over time)
   - Team learnings go here
   - Common mistakes we've made
   - Known issues and workarounds
   - Performance patterns discovered

9. **Automation Rules**
   - Create command when: prompt used >2x
   - Create subagent when: specialized expertise needed repeatedly
   - Update reference docs when: patterns emerge for task types

### Step 2: Create Reference Directory (Task-Specific Context)
**Location**: `~/.claude/reference/`

This is where detailed, task-specific context lives. Each file is 500-1000 lines of deep expertise.

**Purpose**: Keep global CLAUDE.md lightweight while having comprehensive context available when needed.

#### 2.1 `api-development.md`
- FastAPI/Node.js API patterns
- Request/response schemas
- Authentication/authorization
- Error handling
- Database query patterns
- API versioning
- OpenAPI/Swagger docs

#### 2.2 `frontend-components.md`
- React/React Native component patterns
- State management (Zustand/Redux)
- Props design
- Performance optimization
- Accessibility
- Styling conventions

#### 2.3 `mobile-patterns.md`
- React Native/Expo specific patterns
- Platform differences (iOS/Android)
- Navigation patterns
- Image handling
- Performance (FlashList, memoization)
- Deep linking
- Push notifications

#### 2.4 `database-schema.md`
- Supabase/PostgreSQL schema
- RLS policies (examples)
- Migration patterns
- Query optimization
- Indexes
- Triggers and functions

#### 2.5 `testing-strategy.md`
- Unit test patterns
- Integration test patterns
- E2E test setup
- Mocking strategies
- Coverage requirements
- CI/CD integration

#### 2.6 `deployment.md`
- Build processes
- Environment configuration
- CI/CD pipelines
- Rollback procedures
- Health checks
- Monitoring

### Step 3: Create Slash Commands Directory
**Location**: `~/.claude/commands/`

#### Core Workflow Commands

#### 3.1 `/create-prd` Command
**Purpose**: PRD-first development - create product requirement document

**Process**:
1. Have conversation with Claude about what to build
2. When aligned, run `/create-prd [output-file]`
3. Creates structured PRD with:
   - Target users
   - Mission statement
   - In scope / out of scope
   - Architecture overview
   - Feature breakdown
   - Success criteria

**Template sections**:
```markdown
# Project Name

## Target Users
Who is this for?

## Mission
What problem does this solve?

## In Scope
What we're building in this iteration

## Out of Scope
What we're explicitly NOT building

## Architecture
Tech stack, key components, data flow

## Features
Detailed breakdown of features to build

## Success Criteria
How do we know we're done?
```

#### 3.2 `/prime` Command
**Purpose**: Load context at start of every planning session

**Process**:
1. Read PRD.md to understand project scope
2. Read CLAUDE.md for rules and reference pointers
3. Explore codebase structure
4. Load relevant reference docs based on what we're working on
5. Ready to answer: "Based on the PRD, what should we build next?"

**Bash pre-computation**:
```bash
# Gather project context
git log --oneline -10
git status --porcelain
find . -type f -name "*.md" | head -20
ls -la src/ 2>/dev/null || ls -la app/ 2>/dev/null
```

#### 3.3 `/plan` Command
**Purpose**: Create structured execution plan

**Process**:
1. Already primed and discussed feature
2. Run `/plan [feature-name]`
3. Creates detailed plan at `.claude/plans/[feature-name].md`
4. Includes:
   - Feature description
   - User story
   - Context to reference (files, APIs, patterns)
   - Task-by-task breakdown
   - Testing strategy
   - Verification steps

**Output**: Structured plan ready for context reset + execution

#### 3.4 `/execute` Command
**Purpose**: Execute a structured plan (used in FRESH context)

**Critical**: This command is run in a NEW session (context reset!)

**Process**:
1. Read specified plan file (ONLY context needed)
2. Execute tasks sequentially
3. Run tests after each major step
4. Create commit when feature complete
5. Report results

**No priming needed** - plan contains all context

#### 3.5 `/commit-push-pr` Command
**Purpose**: Automate git status → commit → push → PR creation

**Key Innovation**: Bash pre-computation to gather ALL git context upfront

**Bash Pre-Computation Block**:
```bash
#!/bin/bash
BRANCH=$(git branch --show-current)
STATUS=$(git status --porcelain)
DIFF_STAT=$(git diff --cached --stat || git diff --stat)
DIFF_FILES=$(git diff --cached --name-only || git diff --name-only)
RECENT_COMMITS=$(git log --oneline -5)
REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "none")

# Auto-detect commit type from files
if echo "$DIFF_FILES" | grep -q "test"; then
  COMMIT_TYPE="test"
elif echo "$DIFF_FILES" | grep -q "\.md$"; then
  COMMIT_TYPE="docs"
else
  COMMIT_TYPE="feat"
fi

echo "Branch: $BRANCH"
echo "Files changed: $(echo "$DIFF_FILES" | wc -l)"
echo "Suggested type: $COMMIT_TYPE"
echo "Diff stat: $DIFF_STAT"
```

**Workflow**:
1. Stage all changes: `git add -A`
2. Generate conventional commit message from diff analysis
3. Commit with `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>`
4. Push to remote (handle new branches with `-u origin`)
5. Create PR if not on main/master: `gh pr create --fill`
6. Report commit SHA and PR URL

**Error Handling**:
- Pre-commit hook failed: Show error, fix issues, create NEW commit (never amend on failure)
- Push failed: Suggest `git pull --rebase`
- PR creation failed: Provide manual `gh` command

#### 3.6 `/code-review` Command
**Purpose**: Simulate ruthless senior dev code review

**User's exact request**: "Do a git diff and pretend you're a senior dev doing a code review and you HATE this implementation. What would you criticize? What edge cases am I missing?"

**Process**:
1. Run `git diff` to get all changes
2. Analyze with senior dev mindset (critical, thorough)
3. Look for:
   - Logic errors and edge cases
   - Performance issues
   - Security vulnerabilities
   - Type safety problems
   - Error handling gaps
   - Testing gaps
   - Code complexity and maintainability
   - Naming and conventions
   - Race conditions and concurrency issues
   - Memory leaks
   - Accessibility issues (for UI)

**Tone**: Brutally honest. Point out everything wrong.

**Output format**:
```markdown
# Code Review - [Branch Name]

## Critical Issues (Must Fix)
- Issue 1: Description + code reference
- Issue 2: ...

## Edge Cases Missing
- Edge case 1: What happens when...?
- Edge case 2: ...

## Performance Concerns
- Concern 1: ...

## Security Risks
- Risk 1: ...

## Code Quality Issues
- Issue 1: ...

## Recommendations
- Specific changes to make
```

#### 3.7 `/parallel-branches` Command
**Purpose**: llm-council pattern - spawn parallel Claude instances on different branches

**Workflow**:
1. Stash current work if needed
2. Create all branches at once: `git branch feat/1 && git branch feat/2`
3. Spawn ALL agents in ONE message using Task tool:

```
Task 1: Checkout feat/feature-1, implement feature A, commit, push, PR
Task 2: Checkout feat/feature-2, implement feature B, commit, push, PR
Task 3: Checkout fix/bug-1, fix bug, commit, push, PR

TodoWrite: Track all parallel work items
```

4. Each agent:
   - Works only on assigned branch
   - Writes progress to `.claude/session-<branch>.json`
   - Creates PR when complete
   - Doesn't touch other branches

**Coordination**: Progress tracking via TodoWrite and session files

#### 2.3 `/verify-app` Command
**Purpose**: E2E testing with verification loops

**Multi-Platform Strategy**:

**Web (Next.js/React)**:
- Use MCP browser automation tools
- Navigate through critical flows
- Take screenshots at each step
- Check console for errors
- Verify auth, main user journey, edge cases

**Mobile (React Native)**:
- Build and run: `npx expo run:ios` or `npx expo run:android`
- Provide clear manual testing checklist
- Screenshot critical screens
- Document testing steps

**API (FastAPI/Node)**:
- Start server: `uvicorn main:app` or `npm run dev`
- Test endpoints with curl
- Validate status codes and response schemas
- Test error handling and edge cases

**Output**: Comprehensive markdown report with:
- Screenshots
- Errors found
- Performance observations
- Recommendations

#### 3.8 `/superpowers` Command
**Purpose**: Multi-repo orchestration for parallel work across related repositories

**Pre-Computation**:
```bash
PARENT_DIR=$(dirname $(git rev-parse --show-toplevel))
REPOS=$(find "$PARENT_DIR" -maxdepth 2 -name ".git" -type d -exec dirname {} \;)

for repo in $REPOS; do
  cd "$repo"
  echo "Repo: $(basename $repo)"
  echo "Branch: $(git branch --show-current)"
  echo "Status: $(git status --porcelain | wc -l) changes"
  echo "---"
done
```

**Workflow**:
1. Spawn ALL repo agents in parallel (single message, multiple Task calls):
   - Frontend repo agent: Update UI, API client, tests
   - Backend repo agent: Add endpoints, generate types, tests
   - Shared repo agent: Update shared types, utilities

2. Each agent:
   - Works only in assigned repo directory
   - Writes progress to `.claude/multi-repo-<repo>.json`
   - Creates PR when complete
   - Tags PRs with `multi-repo` label for linking

3. Dependency flow coordination: Backend → Shared → Frontend

**Success Criteria**: All PRs created, linked via labels, tests passing

#### 3.9 `/research` Command (CRITICAL - Use BEFORE coding!)
**Purpose**: Research docs, boilerplates, and verify up-to-date patterns BEFORE writing any code

**User's critical requirement**: "NO code written without consulting docs to avoid hallucination, and look for boilerplates/repos first before starting from scratch. Must be up-to-date!"

**Process**:
1. **Search official docs** (via WebSearch or Rube MCP)
   - Latest version/release notes
   - Official examples
   - Breaking changes
   - Best practices

2. **Find existing boilerplates/repos**
   - Search GitHub for: "[technology] boilerplate 2025"
   - Search GitHub for: "[technology] starter template"
   - Look for official examples from maintainers
   - Check stars, recent commits, last updated date

3. **Verify everything is up-to-date**
   - Check package.json / requirements.txt versions
   - Compare with latest releases
   - Look for deprecation warnings
   - Check if patterns are current (2025+)

4. **Document findings**
   - Create `.claude/research/[topic].md`
   - Official docs links
   - Boilerplate repo links
   - Current versions
   - Patterns to use/avoid
   - Code examples from docs

**Example usage**:
```bash
# Before implementing Supabase auth
claude /research "Supabase authentication with React Native"

# Creates .claude/research/supabase-auth.md with:
# - Official Supabase docs (v2.latest)
# - Supabase RN auth boilerplate repo
# - Current best practices
# - Code examples from official docs
```

**Output template**:
```markdown
# Research: [Topic]

## Official Documentation
- Link: [URL]
- Current Version: [version]
- Last Updated: [date]

## Boilerplates/Examples Found
1. [Repo Name] - [GitHub URL]
   - Stars: [count]
   - Last Updated: [date]
   - Status: ✓ Active / ⚠ Outdated

## Current Best Practices (2025)
- Pattern 1: [description + code example from docs]
- Pattern 2: ...

## Deprecated Patterns (DO NOT USE)
- Old pattern 1: [why it's deprecated]
- Old pattern 2: ...

## Dependencies & Versions
- Package 1: v[version] (latest)
- Package 2: v[version] (latest)

## Code Examples (From Official Docs)
[Paste relevant examples with attribution]

## Ready to Use
- [ ] Official docs reviewed
- [ ] Boilerplate found (or decided to start fresh with good reason)
- [ ] Versions verified as current
- [ ] No deprecated patterns
```

**Rube MCP Integration**:
Use Rube MCP to search across connected services:
```bash
# Search Supabase docs
RUBE_SEARCH_TOOLS: "Supabase auth documentation"

# Search GitHub via Rube
RUBE_SEARCH_TOOLS: "React Native Supabase starter"
```

#### 3.10 `/ui-design` Command (CRITICAL - UI First!)

**User's requirement**: "We need importance on getting the UI right BEFORE the code is written."

**Purpose**: Generate UI designs and mockups BEFORE implementing, using Stitch or Google AI Studio

**Process**:
1. **Research UI patterns first** (via research subagent)
   - Search YouTube for UI implementations
   - Search GitHub for similar UI components
   - Search Reddit/X for user feedback on similar UIs
   - Find Figma/Stitch templates

2. **Create UI mockup** (via Stitch/Google AI Studio)
   - Generate visual mockup based on research
   - Show to user for approval
   - Iterate until UI is approved

3. **Only then write code** to implement the approved design

**Integration with Stitch**:
```bash
# Use Stitch API to generate UI preview
curl -X POST "https://api.stitch.tech/v1/generate" \
  -H "Authorization: Bearer $STITCH_API_KEY" \
  -d '{
    "prompt": "Design a mobile habit tracker card component with...",
    "framework": "react-native",
    "style": "modern, minimalist"
  }'
# Returns image URL + component code
```

**Integration with Google AI Studio**:
```bash
# Use Gemini 2.0 Flash with vision
# Describe UI → Gemini generates mockup → Approve → Implement
```

**Workflow**:
```bash
# 1. User describes UI
claude "I need a habit tracker card"

# 2. Research phase (automatic via subagent)
# Searches YouTube, GitHub, Reddit for best practices

# 3. Generate mockup (Stitch/AI Studio)
# Shows visual preview

# 4. User approves
# "Looks good!" or "Change X to Y"

# 5. Only then: write implementation code
```

**Example UI-Design Skill** (based on community best practices):
```markdown
---
name: ui-design
description: Design UI components before implementation
context: fork
skills: [research-ui-patterns]
hooks:
  Stop:
    hooks:
      - type: command
        command: "~/.claude/scripts/speak.sh 'UI design ready for review'"
---

# UI Design Skill

Before implementing ANY UI component:

1. **Research Phase** (via research-ui-patterns skill)
   - Find 3-5 examples on GitHub
   - Find 2-3 YouTube tutorials
   - Check Reddit/X for user feedback
   - Document findings in .claude/research/ui-[component].md

2. **Design Phase** (via Stitch/Google AI Studio)
   - Generate mockup based on research
   - Show to user
   - Iterate based on feedback

3. **Only implement after approval**

## UI Design Principles (Project-Specific)
[Update this section for your project's style]

- Color palette: [colors]
- Typography: [fonts]
- Spacing: [8px grid, etc.]
- Animation: [preferences]
- Accessibility: [WCAG AA minimum]

## Component Library Patterns
[Your project's component patterns]

- Buttons: [style guide]
- Cards: [style guide]
- Forms: [style guide]
- Modals: [style guide]

## Research Sources Priority
1. Official framework docs (React Native, etc.)
2. Dribbble/Behance for visual inspiration
3. GitHub repos with high stars + recent updates
4. YouTube tutorials with good engagement
5. Reddit/X for user experience feedback
```

#### 3.11 `/guide` Command (Interactive Build Guide)
**Purpose**: Guide you through the complete development workflow step-by-step

**User's request**: "I want Claude and its subagents to guide me through the builds, like Cole's YouTube transcript on agentic engineering"

**Interactive Workflow**:

```bash
# Start the guided build
claude /guide
```

**Step-by-step guidance**:

**Phase 1: Project Initialization**
```
🎯 Welcome to your AI-guided build!

Current Status: No PRD found

📋 STEP 1: Create Your PRD
- What are you building?
- Who is it for?
- What problem does it solve?

Let's have a conversation about your project...
[After discussion]
✓ PRD created at PRD.md

Next: /guide (to continue)
```

**Phase 2: Research Phase**
```
📚 STEP 2: Research & Discovery

Before we write ANY code, let's research:
1. What are we building this iteration?
   → [User answers: "Supabase authentication"]

2. Running /research "Supabase authentication with React Native"...
   ✓ Official docs found (Supabase v2.latest)
   ✓ Boilerplate repo found (supabase/auth-helpers)
   ✓ Versions verified as current (2025)

3. Review research at .claude/research/supabase-auth.md

Ready to proceed? (y/n)

Next: /guide (to continue)
```

**Phase 3: Planning Phase**
```
📝 STEP 3: Plan the Feature

Current: We're implementing Supabase authentication

1. Running /prime to load context...
   ✓ PRD loaded
   ✓ Research loaded
   ✓ Codebase explored

2. Based on the PRD and research, here's what we should build:
   - User registration flow
   - Login/logout
   - Session management
   - Protected routes

3. Creating structured plan...
   Running: /plan supabase-auth

   ✓ Plan created at .claude/plans/supabase-auth.md

Review the plan. Does it look good? (y/n)

Next: /guide (to continue)
```

**Phase 4: Context Reset & Execution**
```
💻 STEP 4: Execute the Plan

⚠️  IMPORTANT: We're about to do a CONTEXT RESET

This means:
- Close this conversation
- Start a NEW Claude Code session
- We'll execute with ONLY the plan as context

Ready to execute? I'll prepare the command for you:

RUN THIS IN A NEW SESSION:
claude /execute .claude/plans/supabase-auth.md

After execution completes, return here and run /guide
```

**Phase 5: Verification**
```
✅ STEP 5: Verify the Implementation

Let's verify everything works:

1. Running /code-review...
   ⚠ Found 3 issues (see below)
   - Fix these before proceeding

2. Running /verify-app...
   ✓ Auth flow works
   ✓ Session persistence works
   ⚠ Logout doesn't clear all state

3. Fix the issues found

Fixed all issues? (y/n)

Next: /guide (to continue)
```

**Phase 6: Commit & PR**
```
🚀 STEP 6: Commit & Create PR

Everything verified and working!

Running /commit-push-pr...
✓ Commit created
✓ Pushed to origin
✓ PR #42 created

PR URL: https://github.com/user/repo/pull/42

Next: /guide (to continue)
```

**Phase 7: System Evolution**
```
🎓 STEP 7: Learn & Improve

Did we encounter any bugs or issues during this build?

[User: "Yes, forgot to handle token expiration"]

Running /system-evolve...

Proposed system improvements:
1. Add to .claude/reference/api-development.md:
   Section: "Auth Token Handling"
   - [ ] Handle token expiration
   - [ ] Implement refresh logic
   - [ ] Test expired token scenarios

2. Update /plan command template:
   Add: "Auth considerations" section

Apply these changes? (y/n)

✓ System updated

🎉 Build cycle complete!

Next feature:
- Run /guide to start the next feature
- Or run /guide stats to see your progress
```

**Progress Tracking**:
```bash
claude /guide stats

📊 Your Progress:
✓ 3 features completed
✓ 12 commits made
✓ 3 PRs merged
✓ 8 system improvements

Current streak: 5 days
```

**Key Features**:
- **Step-by-step**: Never overwhelming, one phase at a time
- **Interactive**: Waits for confirmation before proceeding
- **Educational**: Explains WHY we're doing each step
- **Enforces best practices**: Won't let you skip research or verification
- **Adaptive**: Adjusts based on project type (greenfield/brownfield)
- **Progress tracking**: Shows your development journey

#### 3.11 `/system-evolve` Command
**Purpose**: System evolution - improve rules/commands/process after encountering bugs

**When to use**: After completing a feature and finding issues during validation

**Process**:
1. Describe the bug/issue you encountered
2. What fix you had to make manually
3. Command analyzes:
   - What commands were used in the workflow
   - What rules were (or should have been) in place
   - What reference docs are relevant
4. Self-reflection questions:
   - Why did the agent miss this?
   - What rule could prevent this?
   - What process step was missing?
   - What reference doc needs updating?
5. Propose changes to:
   - CLAUDE.md (new rule or update)
   - Relevant .claude/reference/ docs
   - Command workflows (add validation step?)
   - Agent definitions (add hook?)

**Output**: Specific diffs to apply to system files

**Philosophy**: Don't just fix the bug - fix the system that allowed the bug

**Example flow**:
```
User: "I just found a bug - the API returns 500 when the user_id is null. I had to add null checking."

Agent: "Let me analyze the workflow and rules...
- We used /execute which ran .claude/reference/api-development.md
- Current rule: 'Validate all inputs'
- Gap: Not specific enough

Proposed changes:
1. Update .claude/reference/api-development.md:
   Add section: 'Input Validation Checklist'
   - [ ] Check for null/undefined
   - [ ] Validate types match schema
   - [ ] Check string lengths
   - [ ] Validate enums

2. Update /execute command:
   Add step: 'Review API input validation checklist before testing'

3. Add to CLAUDE.md institutional knowledge:
   'FastAPI: Null user_id caused 500 - always validate nullable fields explicitly'
"
```

**Result**: System gets stronger, bug doesn't happen again

### Step 4: Create Subagents Directory
**Location**: `~/.claude/agents/`

All subagents support:
- **Context forking**: Add `context: fork` to run in isolated context
- **Model selection**: Add `model: haiku` for faster execution
- **Hooks**: PreToolUse, PostToolUse, Stop hooks for automation
- **Skill access**: Add `skills: [skill-name]` to allow agent to use specific skills

#### 4.1 `code-simplifier.md`
**Mission**: Simplify code after implementation without changing functionality

**Frontmatter**:
```markdown
---
name: code-simplifier
description: Simplify code after implementation
context: fork
model: sonnet
hooks:
  PostToolUse:
    matcher: "Write|Edit"
    hooks:
      - type: command
        command: "npm test 2>&1 | grep -q 'PASS' && echo '✓ Tests still pass' || echo '✗ Tests broken'"
---
```

**Process**:
1. Read changed files: `git diff --name-only main...HEAD`
2. For each file:
   - Analyze complexity
   - Identify simplification opportunities
   - Apply refactorings
3. Verify tests still pass (via PostToolUse hook)
4. Report: files simplified, lines removed, complexity reduction

**Patterns**:
- Remove duplication
- Reduce complexity (early returns, break large functions)
- Improve readability
- Optimize imports

#### 4.2 `verify-app.md` (detailed agent)
**Purpose**: Comprehensive E2E verification with detailed checklists

**Frontmatter**:
```markdown
---
name: verify-app
description: Comprehensive E2E verification
context: fork
model: sonnet
skills: [verify-app]  # Can use verify-app command
hooks:
  Stop:
    hooks:
      - type: command
        command: "echo '📊 Verification complete. Check report in .claude/verification-report.md'"
---
```

**Checklists for**:
- **Web apps**: Navigation, forms, auth, API calls, accessibility, responsive design
- **Mobile apps**: Launch, navigation, persistence, performance, platform differences
- **APIs**: All endpoints, status codes, schemas, authentication, error handling

**Output**: Detailed report with:
- Severity levels (critical, high, medium, low)
- Reproduction steps
- Screenshots
- Recommended fixes

#### 4.3 `react-native-expert.md`
**Frontmatter**:
```markdown
---
name: react-native-expert
description: React Native specialized expertise
model: sonnet
---
```

**Expertise Areas**:
- Performance optimization (FlashList, memoization, profiling)
- Platform differences (iOS vs Android patterns)
- Common pitfalls (images, keyboard, navigation, linking)

**Quick Fixes**: Code snippets for common issues

#### 4.4 `research-ui-patterns.md` (CRITICAL Subagent!)
**Purpose**: Deep research for UI implementations across YouTube, GitHub, Reddit, X

**Frontmatter**:
```markdown
---
name: research-ui-patterns
description: Research UI patterns from multiple sources
context: fork
model: sonnet  # Needs good analysis
hooks:
  Stop:
    hooks:
      - type: command
        command: "~/.claude/scripts/speak.sh 'UI research complete. Found patterns from YouTube, GitHub, and community feedback.'"
---
```

**Research Process**:
1. **YouTube Search** (via WebSearch or Rube)
   - Search: "[component] React Native tutorial 2025"
   - Filter: Recent uploads, good engagement
   - Extract: Implementation approaches, user feedback in comments

2. **GitHub Search**
   - Search: "[component] react-native stars:>100"
   - Filter: Updated in last 6 months
   - Extract: Code patterns, component structure, prop APIs

3. **Reddit/X Search**
   - r/reactnative, r/expo for discussions
   - X hashtags: #ReactNative #ExpoSDK
   - Extract: User pain points, what works/doesn't work

4. **Dribbble/Behance**
   - Visual inspiration
   - Current design trends
   - Interaction patterns

**Output Template**:
```markdown
# UI Research: [Component Name]

## YouTube Findings
1. [Video Title] - [Channel] - [View count]
   - Approach: [description]
   - Pros/Cons: [analysis]
   - Code pattern: [key takeaway]

## GitHub Repos
1. [Repo Name] - ⭐ [stars] - Updated: [date]
   - Implementation: [approach]
   - Props API: [interface]
   - Notable features: [list]

## Community Feedback (Reddit/X)
- Positive: [what users love]
- Pain points: [what users complain about]
- Recommendations: [what the community suggests]

## Design Inspiration (Dribbble/Behance)
- Trending patterns: [visual patterns]
- Color schemes: [popular combinations]
- Animations: [micro-interactions]

## Recommendation
Based on research, recommend: [specific approach]
Reasoning: [why this is best for our use case]
```

#### 4.5 `frontend-subagent.md` (With UI-Design Skill)
**Purpose**: Handle all UI implementation with design-first approach

**Frontmatter**:
```markdown
---
name: frontend
description: Frontend/UI development with design-first approach
context: fork
model: sonnet
skills: [ui-design, research-ui-patterns]  # Can invoke skills!
hooks:
  PreToolUse:
    matcher: "Write|Edit"
    hooks:
      - type: prompt
        prompt: "Before writing UI code: Has the UI design been approved? If not, invoke ui-design skill first."
  Stop:
    hooks:
      - type: command
        command: "~/.claude/scripts/speak.sh 'Frontend implementation complete'"
---
```

**Process**:
1. User requests UI feature
2. **FIRST**: Invoke `research-ui-patterns` skill
3. **SECOND**: Invoke `ui-design` skill (generate mockup)
4. **THIRD**: Get user approval
5. **ONLY THEN**: Write implementation code

#### 4.6 `orchestrator.md` (Code Quality Check Coordinator)
**Purpose**: Triggered by Stop-Hook, decides what quality checks to run based on code changes

**User's workflow**: "Stop-Hook that calls orchestrator subagent, that decides based on changes what checks to run"

**Frontmatter**:
```markdown
---
name: orchestrator
description: Coordinate quality checks based on code changes
context: fork
model: haiku  # Fast decision-making
hooks:
  Stop:
    hooks:
      - type: command
        command: "~/.claude/scripts/speak.sh 'All quality checks passed'"
---
```

**Process**:
1. **Analyze changes** (git diff)
   - UI files changed? (.tsx, .jsx with JSX)
   - API files changed? (endpoints, routes)
   - Database files changed? (migrations, schemas)
   - Tests changed/added?

2. **Invoke appropriate subagents**:
   ```javascript
   if (hasUIChanges) {
     Task(@frontend "Review UI changes with ui-design skill")
   }
   if (hasAPIChanges) {
     Task(@api-expert "Review API endpoint changes")
   }
   if (hasDBChanges) {
     Task(@database-expert "Review schema changes, check RLS")
   }
   ```

3. **Collect feedback** from all subagents

4. **Report** to main session:
   - All checks passed ✓
   - OR Issues found → fix before committing

**Example orchestrator logic**:
```markdown
# Orchestrator Decision Tree

## Check 1: What changed?
Run: `git diff --name-only HEAD~1`

## Check 2: Categorize changes
- UI: *.tsx, *.jsx with JSX
- API: **/api/**, **/routes/**, **/endpoints/**
- DB: **/migrations/**, schema.sql, supabase/
- Tests: *.test.*, *.spec.*
- Config: package.json, *.config.*, .env

## Check 3: Invoke quality agents
| Change Type | Agent to Invoke | What They Check |
|-------------|-----------------|-----------------|
| UI | @frontend + ui-design skill | Design consistency, accessibility, responsive |
| API | @api-expert | Input validation, error handling, security |
| DB | @database-expert | RLS policies, migrations, indexes |
| Tests | @test-expert | Coverage, assertions, edge cases |

## Check 4: Collect & Report
- Each agent returns: PASS or FAIL + feedback
- Orchestrator aggregates
- If any FAIL: block commit, show fixes needed
- If all PASS: allow commit

## Voice notification
Speak: "Quality checks complete. [X] passed, [Y] need fixes."
```

#### 4.7 `bash-runner.md`
**Purpose**: Long-running bash workflows in isolated context

**Frontmatter**:
```markdown
---
name: bash-runner
description: Execute long-running bash workflows
context: fork
agent: bash  # Uses specialized bash subagent
model: haiku  # Faster for bash operations
hooks:
  PreToolUse:
    matcher: "Bash"
    hooks:
      - type: command
        command: "echo '🔄 Running bash command...'"
        once: true
  Stop:
    hooks:
      - type: command
        command: "osascript -e 'display notification \"Bash workflow complete\"'"
---
```

**Use cases**:
- npm install / pip install (long dependency installs)
- npm run build (long builds)
- Database migrations
- Test suites
- Docker operations

**Benefits**:
- Doesn't consume main session context
- Runs in background (Ctrl+B)
- Notifications when complete
- Uses faster Haiku model

### Step 4: Update settings.local.json
**Location**: `~/.claude/settings.local.json`

**Current content** (minimal):
```json
{
  "permissions": {
    "allow": ["WebSearch", "Bash(git clone:*)", "Bash(cat:*)"]
  },
  "enableAllProjectMcpServers": true
}
```

**Enhanced content**:
```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch(domain:raw.githubusercontent.com)",
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(cat:*)",
      "Bash(ls:*)",
      "Bash(pwd)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(node:*)",
      "Bash(yarn:*)",
      "Bash(python:*)",
      "Bash(pip:*)",
      "Bash(pytest:*)",
      "Bash(black:*)",
      "Bash(ruff:*)",
      "Bash(supabase:*)",
      "Bash(expo:*)",
      "Bash(xcrun:*)",
      "Bash(curl:*)",
      "Bash(jq:*)",
      "Write",
      "Edit",
      "MultiEdit",
      "Read",
      "Glob",
      "Grep"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(sudo:*)",
      "Bash(chmod 777:*)"
    ]
  },
  "hooks": {
    "PostToolUse": {
      "matcher": "Write|Edit|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "sh -c 'FILE=$(echo \"$TOOL_INPUT\" | jq -r \".file_path\"); case \"$FILE\" in *.ts|*.tsx|*.js|*.jsx) npx prettier --write \"$FILE\" 2>/dev/null || true;; *.py) black \"$FILE\" 2>/dev/null || true;; esac'"
        }
      ]
    },
    "Stop": {
      "hooks": [
        {
          "type": "command",
          "command": "echo '\n⚠️  VERIFICATION CHECKLIST:\n- Tests run and passing?\n- TypeScript/Python checked?\n- Manual testing done?\n- Ready to commit?\n'"
        }
      ]
    }
  },
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["slack"],
  "includeCoAuthoredBy": true
}
```

**Key Changes**:
- Pre-allow common safe bash commands (git, npm, python, etc.)
- Add PostToolUse hook for auto-formatting
- Add Stop hook for verification reminder
- **Add self-learning prompts** (see below)
- Enable Co-Authored-By in commits
- Deny dangerous commands

### Step 4.1: Voice Notifications with ElevenLabs (Critical!)

**User's requirement**: "I had hooks that alerted me when agents need input or are finished. I want it to just read out to me right away (not saved to computer)."

**Your ElevenLabs API Key**: `sk_d227dd8dd7701a491431a052f560bfaa6e5078005b22f003`

**Implementation**:

```bash
# Install ElevenLabs CLI
npm install -g elevenlabs-cli

# Set API key
export ELEVENLABS_API_KEY="sk_d227dd8dd7701a491431a052f560bfaa6e5078005b22f003"
```

**Voice Notification Function** (add to hooks):
```bash
#!/bin/bash
# ~/.claude/scripts/speak.sh

speak() {
    local message="$1"
    # Use ElevenLabs TTS to speak immediately (no file saved)
    curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM" \
      -H "xi-api-key: sk_d227dd8dd7701a491431a052f560bfaa6e5078005b22f003" \
      -H "Content-Type: application/json" \
      -d "{\"text\": \"$message\", \"model_id\": \"eleven_monolingual_v1\"}" \
      --output - | afplay -  # macOS audio playback (use 'play' on Linux)
}

speak "$@"
```

**Hooks Configuration** (settings.local.json):

```json
{
  "hooks": {
    "PreToolUse": {
      "matcher": "Task",
      "hooks": [
        {
          "type": "command",
          "comment": "Announce agent starting",
          "command": "~/.claude/scripts/speak.sh 'Starting new agent task'"
        }
      ]
    },
    "PostToolUse": {
      "matcher": "Task",
      "hooks": [
        {
          "type": "command",
          "comment": "Announce agent complete",
          "command": "~/.claude/scripts/speak.sh 'Agent task completed'"
        }
      ]
    },
    "Stop": {
      "hooks": [
        {
          "type": "command",
          "comment": "Announce session ending",
          "command": "~/.claude/scripts/speak.sh 'Claude Code session complete. Ready for your review.'"
        },
        {
          "type": "prompt",
          "comment": "Self-learning checkpoint",
          "prompt": "..."
        }
      ]
    }
  }
}
```

**Voice Notifications for Different Events**:

**Agent needs input**:
```bash
# In agent hooks
hooks:
  PreToolUse:
    matcher: "AskUserQuestion"
    hooks:
      - type: command
        command: "~/.claude/scripts/speak.sh 'Agent needs your input. Please check the terminal.'"
```

**Agent finished**:
```bash
# Task completion
hooks:
  PostToolUse:
    matcher: "Task"
    hooks:
      - type: command
        command: "~/.claude/scripts/speak.sh 'Agent finished. Results ready for review.'"
```

**Multiple agents status**:
```bash
# Custom script for parallel agents
speak_agent_status() {
    local total=$1
    local completed=$2
    ~/.claude/scripts/speak.sh "$completed of $total agents completed"
}
```

**ElevenLabs Voice Selection**:
- Voice ID `21m00Tcm4TlvDq8ikWAM` = Rachel (default)
- Other options: `EXAVITQu4vr4xnSDxMaL` (Bella), `ErXwobaYiN019PkySvjV` (Antoni)
- Change in speak.sh script

**Cost Management**:
- ~1000 characters = $0.30 (standard voice)
- Keep messages short (<50 chars)
- Example: "Agent done" vs "The agent has completed its task successfully"

**CRITICAL Alert**: When User Input Needed
```bash
# When Claude needs your answer (you might be away from desk!)
hooks:
  PreToolUse:
    matcher: "AskUserQuestion"
    hooks:
      - type: command
        command: "~/.claude/scripts/speak.sh 'ATTENTION: Claude needs your input. Please return to your computer.'"
```

### Step 4.1.1: YOLO Mode (User Request: "--dangerously-skip-permissions for most operations")

**Goal**: Automatic execution without permission prompts, but VOICE ALERT when user input truly needed

**settings.local.json YOLO Configuration**:
```json
{
  "permissionMode": "yolo",  // YOLO mode enabled!
  "dangerouslySkipPermissions": true,
  "permissions": {
    "allow": ["*"],  // Allow everything
    "deny": [
      "Bash(rm -rf /)",
      "Bash(sudo:*)",
      "Bash(chmod 777:*)"
    ]
  },
  "hooks": {
    "PreToolUse": {
      "matcher": "AskUserQuestion",
      "hooks": [
        {
          "type": "command",
          "comment": "LOUD ALERT when user input needed",
          "command": "~/.claude/scripts/speak.sh 'ATTENTION. Claude needs your input NOW. Please check terminal.'"
        }
      ]
    }
  }
}
```

**CLI Usage**:
```bash
# YOLO mode for autonomous sessions
claude --dangerously-skip-permissions "Work on feature X"

# YOLO + Ralph Wiggum for multi-hour autonomous work
claude --dangerously-skip-permissions --plugin=ralph-wiggum --max-iterations=50 "Implement all features from PRD"
```

**When Voice Alerts Trigger**:
- User input needed (AskUserQuestion)
- Critical decision point
- Error that requires human intervention
- Quality check failures

**Safety**: Even in YOLO mode, destructive commands (rm -rf, sudo) are denied

### Step 4.2: Self-Learning Mechanism (User Request: "Prompt agents to remember fixes")

**Goal**: When something couldn't be fixed initially but IS fixed later, automatically capture the solution for future reference

**Implementation via Hooks**:

```json
{
  "hooks": {
    "PostToolUse": {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "comment": "Auto-format code",
          "command": "..."
        },
        {
          "type": "prompt",
          "comment": "Self-learning: Capture fixes",
          "once": false,
          "prompt": "After making this change, consider: Was this fixing a bug or issue that Claude struggled with earlier? If YES, briefly note: (1) What was the problem, (2) What was the solution, (3) Why it matters. This will be added to institutional knowledge."
        }
      ]
    },
    "Stop": {
      "hooks": [
        {
          "type": "prompt",
          "comment": "Self-learning checkpoint",
          "prompt": "Before ending this session:\n\n🎓 LEARNING CHECKPOINT\n\nDid we encounter any issues that required manual fixes or multiple attempts?\n\nIf YES, run: /system-evolve [describe issue]\nThis will update our rules/commands so this issue doesn't happen again.\n\nIf NO, we're good! ✓"
        },
        {
          "type": "command",
          "command": "echo '\n⚠️  VERIFICATION CHECKLIST:\n- Tests run and passing?\n- TypeScript/Python checked?\n- Manual testing done?\n- Ready to commit?\n- Learning captured? (run /system-evolve if needed)\n'"
        }
      ]
    }
  }
}
```

**Self-Learning Flow**:

1. **During Development** (PostToolUse hook):
   - After every code change, subtle prompt: "Was this fixing a struggle?"
   - If yes, agent briefly notes the issue + solution
   - Stored in memory for end-of-session review

2. **End of Session** (Stop hook):
   - Review all struggles encountered
   - Prompt: "Run /system-evolve to capture learnings"
   - Updates CLAUDE.md institutional knowledge section

3. **Automatic in /guide workflow**:
   - Phase 7 explicitly asks: "What did we learn?"
   - Runs /system-evolve automatically
   - System gets smarter with every feature

**Example Institutional Knowledge Growth**:

```markdown
## Institutional Knowledge

### React Native
- **FlashList import error** (2025-01-07): Must use `@shopify/flash-list` not `react-native-flash-list`. Old package deprecated.
- **Keyboard avoidance** (2025-01-08): `KeyboardAvoidingView` alone not enough on Android. Must also use `android:windowSoftInputMode="adjustResize"` in AndroidManifest.xml.

### Supabase
- **RLS policies not applying** (2025-01-07): Policies must be ENABLED in addition to being defined. Check `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`.
- **Null user_id in API** (2025-01-08): FastAPI endpoints must explicitly validate nullable fields. Pydantic Optional[str] allows None - add manual check.

### API Development
- **CORS errors in dev** (2025-01-09): Expo dev client uses different origin than web. Must add `http://192.168.*` to allowed origins, not just `localhost`.
```

**Self-Learning Triggers**:
- Manual fixes after Claude's attempt
- Test failures that required debugging
- "I can't fix this" → later fixed successfully
- Patterns that emerged after trial and error
- Boilerplate discoveries during /research

**Benefits**:
- System continuously improves
- New team members benefit from past learnings
- Reduces repeated mistakes
- Creates living documentation
- Compound knowledge over time

### Step 5: MCP Configuration (Critical!)
**Location**: `~/.mcp.json`

**Current**: Slack MCP is enabled

**Required Additions**:

#### 5.1 Rube MCP Server
Connects to 500+ apps: Supabase, Vercel, Google Workspace, GitHub, and more

```json
{
  "mcpServers": {
    "slack": {
      // existing Slack config
    },
    "rube": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@composiohq/mcp-server-composio"],
      "env": {
        "COMPOSIO_API_KEY": "${COMPOSIO_API_KEY}"
      }
    },
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Rube capabilities**:
- Supabase: Database operations, auth, storage
- Vercel: Deployments, environment variables
- Google: Gmail, Drive, Sheets, Calendar
- And 500+ more integrations

#### 5.2 LLM Council (OpenRouter Integration)
**Your OpenRouter API Key**: `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`

**Multi-Model Access** via OpenRouter:
- Google: Gemini 2.0 Flash, Gemini Pro
- OpenAI: GPT-4o, o1, o3-mini
- Anthropic: Claude Opus 4.5, Sonnet 4.5
- xAI: Grok 2, Grok Vision

**Configuration in commands/agents**:
```markdown
---
model: openrouter/google/gemini-2.0-flash-exp  # Fast, cheap
# OR
model: openrouter/anthropic/claude-opus-4.5    # Most capable
# OR
model: openrouter/openai/gpt-4o                # Balance
# OR
model: openrouter/x-ai/grok-2-vision-1212      # Vision tasks
---
```

**Environment variable**:
```bash
export OPENROUTER_API_KEY="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"
```

**When to use which model**:
- **Gemini Flash**: Fast iterations, bash operations, simple refactoring
- **Claude Opus 4.5**: Complex planning, architecture, critical features
- **GPT-4o**: General development, good balance
- **Grok Vision**: Screenshot analysis, UI review

#### 5.3 LLM Council Pattern for Parallel Execution
Use `/parallel-branches` or `/superpowers` to run different models simultaneously:

```bash
# Example: 3 models working on 3 features in parallel
Task 1 (Gemini Flash): "Simple UI component - fast iteration"
Task 2 (Claude Opus): "Complex state management - needs deep thinking"
Task 3 (GPT-4o): "API integration - balanced approach"
```

## Critical Files Priority

Implement in this order:

1. **CLAUDE.md** - Foundation for everything else
2. **settings.local.json** - Enables smooth workflows with permissions/hooks
3. **commands/commit-push-pr.md** - Most frequently used workflow
4. **commands/verify-app.md** - Critical for quality
5. **agents/code-simplifier.md** - Post-implementation cleanup

Then add parallel-branches, superpowers, and remaining agents as needed.

## Verification Steps

After implementation:

### Test 1: CLAUDE.md Recognition
```bash
claude "What are my tech stack conventions for React Native?"
# Expected: Claude should cite conventions from CLAUDE.md
```

### Test 2: Slash Command Execution
```bash
# Make a small change to a file
echo "# Test" >> README.md

# Run the command
claude /commit-push-pr
# Expected: Commit created, pushed, PR created (if not on main)
```

### Test 3: Hooks Working
```bash
# Edit a TypeScript file
claude "Add a console.log to src/App.tsx"
# Expected: File auto-formatted with Prettier after edit
```

### Test 4: Permissions Working
```bash
claude "Run npm install"
# Expected: No permission prompt (pre-allowed)
```

### Test 5: Subagent Invocation
```bash
claude "Use the code-simplifier agent to clean up this file"
# Expected: Agent runs, simplifies code, reports changes
```

### Test 6: Parallel Branches
```bash
claude /parallel-branches "Create feat/ui-update and feat/api-update branches, work on both in parallel"
# Expected: Two Task agents spawned, working simultaneously
```

### Test 7: Verification Loop
```bash
claude /verify-app
# Expected: E2E testing performed, report generated with screenshots
```

## Success Metrics

- **Time saved per commit**: 50%+ reduction (no manual PR creation, commit message writing)
- **Bugs caught before PR**: 80%+ (verification loops catch issues early)
- **Context switching**: Support 5+ parallel Claude instances
- **Team adoption**: Shareable via git, entire team can use same config

## Ralph Wiggum Plugin - Autonomous Long-Running Loops

**What it is**: A Claude Code plugin that enables autonomous work for hours/days by intercepting stop attempts and re-injecting the prompt.

**How it works**: "Ralph is a Bash loop" - uses exit code 2 to block Claude from stopping and re-prompt with the original task.

**Named after**: Ralph Wiggum from The Simpsons - persistent iteration despite setbacks.

### Installation

```bash
# Install the plugin
cd ~/.claude/plugins
git clone https://github.com/anthropics/claude-code.git
cd claude-code/plugins/ralph-wiggum

# Enable in settings.local.json
{
  "plugins": {
    "ralph-wiggum": {
      "enabled": true,
      "max_iterations": 50  // CRITICAL: Set limit to avoid token burn!
    }
  }
}
```

### Configuration

**Plugin Structure**:
```bash
~/.claude/plugins/ralph-wiggum/
├── README.md
├── hook.sh              # Stop hook that re-injects prompt
└── config.json          # Max iterations, exit conditions
```

**Stop Hook** (prevents Claude from stopping):
```bash
#!/bin/bash
# Checks if task is complete
# If not: exit 2 (blocks stop, re-prompts)
# If yes: exit 0 (allows stop)
```

### Use Cases (Best For)

**Large Refactors**:
- Framework migrations (React 17 → 18 across 200 files)
- Dependency upgrades (updating all packages + fixing breaking changes)
- API version bumps across hundreds of endpoints

**Batch Operations**:
- Support ticket triage (100+ GitHub issues)
- Documentation generation (docstrings for entire codebase)
- Code standardization (apply ESLint fixes to 500 files)

**Test Coverage**:
- Write tests for all untested functions
- Achieve 80%+ coverage across project
- Fix all failing tests

**Example: Multi-Month Loop**:
```bash
# Geoffrey Huntley's famous example (ran 3 months!):
# "Make me a programming language like Golang but with Gen Z slang keywords"
# Result: Full compiler, LLVM compilation, standard library, editor support
```

### Safety Guidelines

⚠️ **CRITICAL WARNINGS**:

1. **Token Costs**: 50-iteration loop on large codebase = $50-100+ in API credits
   - Always set `max_iterations`
   - Start with 10-20 iterations for testing
   - Monitor costs in Claude dashboard

2. **Task Clarity**: Must have clear completion criteria
   - ✅ GOOD: "Add tests until coverage is 80%"
   - ✅ GOOD: "Migrate all class components to functional components"
   - ❌ BAD: "Make the app better" (no clear end state)

3. **Progress Tracking**: Ralph writes progress to `.claude/ralph-progress.json`
   - Monitor to see if stuck in loop
   - Can intervene and adjust prompt

### Example Usage

**Scenario**: Migrate 200 files from JavaScript to TypeScript

```bash
# Create prompt file
cat > migrate-to-ts-prompt.txt << 'EOF'
Task: Migrate all JavaScript files to TypeScript

Completion Criteria:
- All .js files converted to .tsx
- All type errors resolved
- All tests passing
- Max 50 iterations

Process:
1. List all .js files (find . -name "*.js")
2. Convert files one by one:
   - Add TypeScript types
   - Fix type errors
   - Run tests
   - Commit if tests pass
3. When no .js files remain, task is complete

Progress Tracking:
- Log each file converted to .claude/ralph-progress.json
- Report: X/200 files complete
EOF

# Run with Ralph Wiggum
claude --plugin=ralph-wiggum --prompt migrate-to-ts-prompt.txt
```

**What happens**:
1. Claude converts first file, tests, commits
2. Ralph loop re-prompts with same task
3. Claude sees progress, continues with next file
4. Repeats until all 200 files done
5. Task completes when criteria met

### Integration with Your System

**Combine with Commands**:
```bash
# Ralph loop for parallel-branches
claude --plugin=ralph-wiggum "
Use /parallel-branches to work on these features until all PRs are merged:
- feat/user-settings
- feat/dark-mode
- feat/profile-pictures

Max iterations: 30
"
```

**Combine with /guide**:
```bash
# Autonomous guided builds
claude --plugin=ralph-wiggum "
Run /guide repeatedly until 5 features from PRD are complete.
Max iterations: 100
"
```

**When NOT to use Ralph**:
- Short tasks (<30 min)
- Tasks requiring human decisions
- Exploratory work without clear goals
- Initial prototyping

**When TO use Ralph**:
- Mechanical, repetitive work
- Clear completion criteria
- Hours/days of work
- Batch operations

## Future Enhancements

After core system working:

1. **Add tech stack expert agents**: python-expert, nextjs-expert, supabase-expert
2. **Create more specialized commands**: /debug-prod, /migration, /refactor
3. **Enhance CLAUDE.md**: Add team learnings, common mistakes, known issues as they arise
4. **Add more hooks**: Pre-commit validation, test coverage checks
5. **MCP integrations**: Supabase, Linear, Figma as they become available
6. **Ralph Wiggum integration**: For autonomous multi-day refactors and batch operations

## Migration from Old Setup

**From your November 2025 backup**:
- 29 skills → 4 slash commands + 3 subagents (streamlined)
- 22 plugins → Focused on core workflows
- Distributed config → Single source of truth (CLAUDE.md)

**Philosophy shift**:
- Old: Many specialized skills for specific tasks
- New: Core automation + institutional knowledge + parallel execution

This follows Boris's "vanilla" approach: the system works because it's simple, focused, and team-shareable.

## Notes

- All configuration files should be committed to git for team sharing
- CLAUDE.md should be updated whenever Claude makes a mistake (institutional learning)
- Start with Opus 4.5 for best 1-shot execution results
- Plan mode first, then auto-accept edits mode for complex changes
- Verification is non-negotiable - never skip the loops

---

## Guided Multi-Terminal Workflow (Your Primary Workflow!)

**User's request**: "I want to be guided like: work on this feature, send it to agents in multiple terminals. Make sure it works, then continue."

**Setup**: 5 terminal tabs numbered 1-5 (like Boris)

### Terminal 1: Main Orchestration
This is your primary terminal where you interact with Claude

### Terminals 2-5: Parallel Agent Execution
These run agents autonomously while you continue planning in Terminal 1

---

## Step-by-Step: Feature Implementation

**You say**: "I want to build user authentication"

**Claude responds with guided workflow**:

```bash
🎯 FEATURE: User Authentication

I'll guide you through this. Here's the plan:

📋 Phase 1: Research & Design (Terminal 1 - you're here)
   INVOKE: /research "authentication React Native Supabase"
   INVOKE: /ui-design "login screen, registration screen"
   → Wait for approval

📝 Phase 2: Planning (Terminal 1)
   INVOKE: /prime
   INVOKE: /plan user-authentication
   → Creates .claude/plans/user-authentication.md

💻 Phase 3: Parallel Execution (Terminals 2-5)

   Terminal 2:
   INVOKE: @frontend "Implement login UI from approved design"
   (with ui-design skill enforcing approved mockup)

   Terminal 3:
   INVOKE: @backend "Implement auth endpoints with Supabase"

   Terminal 4:
   INVOKE: @testing "Write tests for auth flow"

   Terminal 5:
   INVOKE: @bash "npm install @supabase/supabase-js && build"

   → Press Ctrl+B in each to run in background
   → Voice notifications tell you when each completes

✅ Phase 4: Quality Checks (Automatic via orchestrator)
   TRIGGERED: Stop-Hook calls @orchestrator
   @orchestrator analyzes changes, invokes:
   - @frontend (UI changes detected)
   - @api-expert (API changes detected)
   - @verify-app (E2E testing)

   → Voice: "Quality checks complete. 3 passed, 0 need fixes"

🚀 Phase 5: Commit & Continue (Terminal 1)
   INVOKE: /commit-push-pr
   → Voice: "Committed and PR created"

NEXT FEATURE?
   Run: /guide (to start next feature cycle)
```

**Voice Notifications Throughout**:
- "Starting frontend agent" (Terminal 2)
- "Starting backend agent" (Terminal 3)
- "Frontend agent complete. Results ready" (Terminal 2)
- "All agents complete. Running quality checks..."
- "Quality checks passed. Ready to commit"

---

## When to Invoke What (Automatic Guidance)

The `/guide` command tells you exactly when to invoke each command:

| Situation | Command to Run | Terminal |
|-----------|---------------|----------|
| Starting new feature | `/guide` | 1 |
| Need to research tech/patterns | `/research "[topic]"` | 1 |
| Need UI mockup | `/ui-design "[component]"` | 1 |
| Planning implementation | `/prime` then `/plan` | 1 |
| Executing plan | `/execute [plan-file]` | 1 (new session!) |
| Parallel feature work | `/parallel-branches` | 1 (spawns to 2-5) |
| Multi-repo work | `/superpowers` | 1 (spawns to 2-5) |
| UI implementation | `@frontend` | 2 |
| API implementation | `@backend` | 3 |
| Long builds | `@bash` | 5 |
| Code review | `/code-review` | 1 |
| Verification | `/verify-app` | 1 |
| Commit | `/commit-push-pr` | 1 |
| Learn from bugs | `/system-evolve` | 1 |

**Hooks automatically invoke**:
- Orchestrator (Stop-Hook after every session)
- UI-design check (before writing UI code)
- Self-learning prompts (after fixes)
- Voice notifications (all agent events)

---

## Maximum Hooks Configuration

**Your requirement**: "I want as many hooks as possible"

**settings.local.json with ALL hooks**:

```json
{
  "hooks": {
    "PreToolUse": {
      "matcher": ".*",
      "hooks": [
        {
          "type": "prompt",
          "comment": "Universal pre-check",
          "prompt": "Before using this tool, confirm: (1) Is this following our workflow? (2) Have prerequisites been met?"
        }
      ]
    },
    "PreToolUse": {
      "matcher": "Task",
      "hooks": [
        {
          "type": "command",
          "comment": "Voice: Agent starting",
          "command": "~/.claude/scripts/speak.sh 'Starting agent task'"
        }
      ]
    },
    "PreToolUse": {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "prompt",
          "comment": "UI code check",
          "prompt": "If this is UI code: Has the design been approved via /ui-design? If not, STOP and run /ui-design first."
        }
      ]
    },
    "PostToolUse": {
      "matcher": "Write|Edit|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "comment": "Auto-format",
          "command": "[format command from earlier]"
        },
        {
          "type": "prompt",
          "comment": "Self-learning",
          "prompt": "Was this fixing a previous struggle? Note it for institutional knowledge."
        }
      ]
    },
    "PostToolUse": {
      "matcher": "Task",
      "hooks": [
        {
          "type": "command",
          "comment": "Voice: Agent complete",
          "command": "~/.claude/scripts/speak.sh 'Agent task completed'"
        }
      ]
    },
    "PostToolUse": {
      "matcher": "Bash(npm test|pytest)",
      "hooks": [
        {
          "type": "prompt",
          "comment": "Test result analysis",
          "prompt": "Did tests pass? If not, what failed and why?"
        }
      ]
    },
    "Stop": {
      "hooks": [
        {
          "type": "command",
          "comment": "Invoke orchestrator for quality checks",
          "command": "claude @orchestrator 'Analyze changes and run quality checks'"
        },
        {
          "type": "prompt",
          "comment": "Self-learning checkpoint",
          "prompt": "[learning checkpoint from earlier]"
        },
        {
          "type": "command",
          "comment": "Voice: Session complete",
          "command": "~/.claude/scripts/speak.sh 'Session complete. Quality checks done. Ready for review.'"
        }
      ]
    }
  }
}
```

**Agent-specific hooks** (in each agent frontmatter):
- frontend.md: PreToolUse check for approved design
- orchestrator.md: Analyzes git diff, invokes quality agents
- research-ui-patterns.md: Voice notification when research complete
- bash-runner.md: Notifications for long-running tasks

---

## Complete Workflow Examples

### Example 1: Green Field Development (New Project)

**Session 1: PRD Creation**
```bash
# Have conversation about project
claude "I want to build a habit tracker app with React Native..."

# When aligned on vision
claude /create-prd PRD.md
```

**Session 2: First Feature Planning**
```bash
# Prime the session
claude /prime

# Ask for next feature
claude "Based on the PRD, what should we build first?"
# Discussion happens...

# Create structured plan
claude /plan user-authentication
# → Creates .claude/plans/user-authentication.md
```

**Session 3: First Feature Execution** (FRESH SESSION - context reset!)
```bash
# Execute the plan (only context needed)
claude /execute .claude/plans/user-authentication.md

# When done, commit
claude /commit-push-pr

# Verify implementation
claude /verify-app
```

**Session 4: System Evolution**
```bash
# Found some issues during verification
claude /system-evolve "The auth flow doesn't handle expired tokens properly..."

# Apply proposed changes to system files
```

### Example 2: Brownfield Development (Existing Project)

**Session 1: Create PRD for New Features**
```bash
# Prime to understand existing codebase
claude /prime

# Discuss what exists and what's next
claude "Document current state and plan the notification feature..."

# Create PRD documenting current + next
claude /create-prd PRD.md
```

**Session 2: Code Review Before New Work**
```bash
# Review recent changes
claude /code-review

# Address issues found, then commit fixes
claude /commit-push-pr
```

**Session 3: Multi-Repo Feature**
```bash
# Planning session
claude /prime
claude "Based on PRD, plan the cross-platform notification feature"
claude /plan notifications

# Execution session (FRESH)
claude /superpowers "Implement notifications across backend, frontend, mobile repos"
```

### Example 3: Parallel Development

**Session 1: Planning Multiple Features**
```bash
claude /prime
claude "Plan features: user-settings, dark-mode, profile-pictures"
claude /plan user-settings
claude /plan dark-mode
claude /plan profile-pictures
```

**Sessions 2-4: Parallel Execution** (3 separate Claude instances)
```bash
# Terminal Tab 1
claude /parallel-branches "feat/user-settings feat/dark-mode feat/profile-pictures"

# Spawns 3 agents working simultaneously
# Each agent creates branch, implements, tests, commits, PRs
```

**Session 5: Integration**
```bash
# After all PRs merged
claude /verify-app
claude /code-review
```

### Example 4: Long-Running Build

**Using Bash Subagent**
```bash
# Start long build in background
claude "@bash npm run build:production"

# Press Ctrl+B to move to background
# Continue other work in main session

# Get notification when build completes (via Stop hook)
```

## Implementation Checklist

### Core Setup
- [ ] Create `~/.claude/CLAUDE.md` (lightweight, <200 lines)
- [ ] Create `~/.claude/reference/` directory
- [ ] Create task-specific reference docs:
  - [ ] api-development.md
  - [ ] frontend-components.md
  - [ ] mobile-patterns.md
  - [ ] database-schema.md
  - [ ] testing-strategy.md
  - [ ] deployment.md
- [ ] Create `~/.claude/scripts/` directory
- [ ] Create `~/.claude/scripts/speak.sh` (ElevenLabs voice notifications)
- [ ] Set environment variable: `ELEVENLABS_API_KEY="sk_d227dd8dd7701a491431a052f560bfaa6e5078005b22f003"`
- [ ] **Enable YOLO mode**: Add to settings.local.json or use CLI flag
- [ ] Update `~/.claude/settings.local.json` with:
  - [ ] Wildcard permissions
  - [ ] PostToolUse hook for formatting
  - [ ] Stop hook for verification reminder
  - [ ] **Voice notification hooks** (PreToolUse, PostToolUse, Stop)
  - [ ] Self-learning prompt hooks
  - [ ] Language parameter (if needed)
  - [ ] includeCoAuthoredBy: true

### Commands
- [ ] Create `~/.claude/commands/` directory
- [ ] Create `/create-prd` command
- [ ] Create `/prime` command
- [ ] Create `/plan` command
- [ ] Create `/execute` command
- [ ] Create `/commit-push-pr` command
- [ ] Create `/code-review` command (user's critical need!)
- [ ] Create `/verify-app` command
- [ ] Create `/parallel-branches` command
- [ ] Create `/superpowers` command
- [ ] Create `/research` command (consult docs, find boilerplates!)
- [ ] Create `/guide` command (step-by-step build guidance)
- [ ] Create `/system-evolve` command

### Skills
- [ ] Create `~/.claude/skills/` directory
- [ ] Create `ui-design.md` (CRITICAL - design before code!)
- [ ] Install/customize community ui-design skill for your project

### Subagents
- [ ] Create `~/.claude/agents/` directory
- [ ] Create `code-simplifier.md` (with context: fork, hooks)
- [ ] Create `verify-app.md` (with skills reference)
- [ ] Create `react-native-expert.md`
- [ ] Create `research-ui-patterns.md` (CRITICAL - deep research!)
- [ ] Create `frontend.md` (with ui-design + research-ui-patterns skills)
- [ ] Create `orchestrator.md` (CRITICAL - quality check coordinator!)
- [ ] Create `bash-runner.md` (with agent: bash, notifications)

### Testing & Validation
- [ ] Test PRD creation workflow
- [ ] Test prime → plan → context reset → execute cycle
- [ ] Test /commit-push-pr with inline bash
- [ ] Test /code-review (user's specific request!)
- [ ] Test context forking (verify main session context preserved)
- [ ] Test subagent hooks (formatting, notifications)
- [ ] Test @bash subagent
- [ ] Test parallel execution (/parallel-branches)
- [ ] Test /system-evolve (propose and apply system changes)
- [ ] Test Ctrl+B background mode

### Advanced Features
- [ ] Test wildcard permissions (no prompts for common commands)
- [ ] Test skills as slash commands (just type /skill-name)
- [ ] Test /plan command (toggle plan mode)
- [ ] Verify hook "once: true" behavior
- [ ] Test permission denied handling (subagents try alternatives)
- [ ] Configure Ralph Wiggum plugin for autonomous loops (see below)

### Team Rollout
- [ ] Commit all config to git
- [ ] Create team onboarding guide
- [ ] Document PRD-first workflow
- [ ] Share reference docs structure
- [ ] Train team on context reset technique
- [ ] Establish system evolution practice

Ready to execute!