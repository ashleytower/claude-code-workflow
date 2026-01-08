# Prime Command

**Purpose**: Load all necessary context at the start of a planning session. Prepares Claude to answer: "Based on the PRD, what should we build next?"

## Usage

```bash
claude /prime
# Loads PRD, CLAUDE.md, explores codebase, ready for planning
```

## Bash Pre-Computation (Gather Project Context)

```bash
echo "╔════════════════════════════════════════╗"
echo "║       PRIMING CONTEXT...               ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Git info
echo "📊 Git Status:"
git log --oneline -10 2>/dev/null || echo "  No commits yet"
echo ""
git status --porcelain | head -20
echo ""

# Project structure
echo "📁 Project Structure:"
ls -la | grep "^d"
echo ""

# Find key files
echo "📄 Key Files:"
find . -maxdepth 2 -type f -name "*.md" | head -20
find . -maxdepth 1 -type f -name "package.json" -o -name "requirements.txt" -o -name "pyproject.toml" 2>/dev/null
echo ""

# Check for PRD
if [ -f "PRD.md" ]; then
  echo "✓ PRD found: PRD.md"
else
  echo "⚠ No PRD found - consider running /create-prd"
fi
echo ""

# Source directories
echo "💻 Source Directories:"
ls -la src/ 2>/dev/null || ls -la app/ 2>/dev/null || echo "  Standard structure"
echo ""
```

## Process

### 1. Read PRD
- Load PRD.md from project root
- Understand project scope
- Identify completed vs pending features

### 2. Read Global + Project CLAUDE.md
- Load ~/.claude/CLAUDE.md (universal rules)
- Load ./CLAUDE.md (project-specific rules)
- Load relevant ~/.claude/reference/ docs

### 3. Explore Codebase Structure
- Identify main directories (src/, app/, etc.)
- Find key configuration files
- Understand project organization
- Note any patterns

### 4. Load Recent Context
- Recent commits (understand what's been done)
- Current branch
- Open PRs
- Pending changes

### 5. Identify Relevant Reference Docs
Based on project type, load:
- API project? Load api-development.md
- UI work? Load frontend-components.md, mobile-patterns.md
- Database changes? Load database-schema.md

## Output

```
✅ PRIMING COMPLETE

Loaded context:
├─ PRD: [Project Name]
│  └─ 10 features defined, 3 completed, 7 pending
├─ Rules: Global + Project CLAUDE.md
├─ Reference: api-development.md, frontend-components.md
├─ Codebase:
│  ├─ Structure: src/components, src/api, src/utils
│  ├─ Tech: React Native + Expo + Supabase
│  └─ Recent work: [last 3 commits]
└─ Status: Ready for planning

🎯 I'm now ready to answer: "Based on the PRD, what should we build next?"

Or ask me:
- "Plan the [feature name] feature"
- "What are the dependencies for [feature]?"
- "What's the best approach for [feature]?"
```

## Integration with Workflow

**Start of every planning session**:
```bash
# Terminal 1
claude /prime

# Then discuss
claude "Based on the PRD, what should we build next?"

# Then plan
claude /plan [feature-name]
```

**In /guide workflow**:
Phase 4 (Planning) automatically runs /prime

## What Makes This Effective

**Boris's principle**: Pre-compute all context in bash
- Faster than asking Claude to explore
- All info gathered in one shot
- No back-and-forth

**Context Protection**:
- Loads ONLY what's needed for planning
- References point to detailed docs (load on demand)
- Keeps conversation focused

## Example Session

```bash
$ claude /prime

[Bash pre-computation runs...]

✅ PRIMING COMPLETE

Loaded context:
├─ PRD: Wandr - Voice-First AI Travel Companion
│  └─ MVP: 5 features defined, 2 completed, 3 pending
├─ Rules: Global + Project CLAUDE.md
│  └─ Tech: React Native, Supabase, PydanticAI
├─ Reference: mobile-patterns.md, api-development.md
├─ Codebase:
│  ├─ src/components (12 components)
│  ├─ src/screens (8 screens)
│  ├─ src/api (Supabase client)
│  └─ Recent: "feat(voice): add Gemini Live integration"
└─ Status: Ready for planning

🎯 Ready! What would you like to plan?

$ claude "Based on the PRD, what should we build next?"

Based on the PRD and current progress, I recommend building the AI Restaurant Booking feature next because:

1. Core MVP feature (high priority in PRD)
2. Builds on completed voice integration
3. Showcases AI agent capabilities
4. High user value

Would you like me to create a plan for this feature?
```

## Notes

- Always run at start of planning sessions
- Fast execution (bash pre-computation)
- Essential for informed planning
- Part of Plan → Context Reset → Execute cycle
