# Context Management - Never Hit the Wall

**Max tokens**: 200,000
**Warning threshold**: 70% (140,000 tokens)
**Critical threshold**: 90% (180,000 tokens)

---

## The Problem

Context window fills → Quality degrades → Work becomes inefficient

## The Solution

**Monitor → Summarize → Fork → Continue**

---

## 1. Monitor Context Usage

### Check Current Usage
```bash
# Claude Code shows token usage after each response
# Look for: "Token usage: X/200000"
# Or check in status bar
```

### When to Act

| Usage | Action |
|-------|--------|
| 0-50% | Normal operation |
| 50-70% | Start planning handoff |
| 70-90% | **Summarize & fork NOW** |
| 90%+ | **Emergency - fork immediately** |

**Voice alert at 70%**: *"Context at 70 percent. Consider forking."*

---

## 2. PRD Pattern (Your Strategy)

### How PRD Works
```bash
# 1. Planning phase (uses tokens)
/create-prd "Build user management"

# 2. PRD written to file
~/.claude/plans/user-management-prd.md

# 3. CLEAR CONTEXT (exit session)
exit

# 4. Execution phase (fresh context)
claude --resume
# OR
claude "Read PRD and implement: ~/.claude/plans/user-management-prd.md"
```

**Why this works**:
- Planning uses tokens (research, decisions)
- PRD captures everything
- Fresh context for execution
- No token waste on planning context

---

## 3. Context Handoff Pattern

### Same Pattern for Any Long Task

**Step 1: Work Phase**
```bash
# Work until 70% context
# Write summary document
```

**Step 2: Summarize**
```markdown
# Current State Summary
Location: ~/.claude/summaries/feature-xyz-$(date +%Y%m%d).md

## What We Built
- File1: Purpose, key functions
- File2: Purpose, key functions

## Decisions Made
- Chose Clerk over Supabase (reason)
- Used shadcn/ui (reason)

## Next Steps
1. Implement auth flow
2. Add protected routes
3. Test E2E

## Context Needed
- User model: app/models/user.ts
- Auth config: lib/auth.ts
- Key dependencies: Clerk, Zod

## Issues/Gotchas
- Clerk middleware must match all routes
- Need to add Apple sign-in if Google used
```

**Step 3: Clear & Resume**
```bash
# Exit session
exit

# Start fresh with summary
claude "Read summary and continue: ~/.claude/summaries/feature-xyz-20260108.md"
```

---

## 4. Fork to Agents (Different Context Windows)

### All Agents Have `context: fork`

Check:
```bash
grep "context: fork" ~/.claude/agents/*.md
```

Should show:
```
backend.md:context: fork
bash.md:context: fork
code-simplifier.md:context: fork
frontend.md:context: fork
orchestrator.md:context: fork
react-native-expert.md:context: fork
research-ui-patterns.md:context: fork
verify-app.md:context: fork
```

### What `context: fork` Means

**WITHOUT fork** (default):
```bash
claude "@agent 'task'"
# → Uses SAME context window as main session
# → Main session context grows
```

**WITH fork** (`context: fork`):
```bash
claude "@agent 'task'"
# → Creates NEW isolated context window
# → Agent has own 200K token budget
# → Main session context unchanged
# → Agent returns summary only
```

### Example: Main Context Getting Full

```bash
# Main session at 65% context
# Don't add more to this context!

# Fork to agent (fresh context)
claude "@backend 'Implement user CRUD API'"

# What happens:
# 1. Backend agent starts with 0% context
# 2. Reads only what it needs
# 3. Implements feature
# 4. Returns summary to main
# 5. Main session only adds summary (small)

# Main session now at 66% (not 90%)
```

---

## 5. Different Terminals (Parallel Contexts)

### Terminal Strategy

**Terminal 1 (Main - Coordination)**:
```bash
# Use for: Planning, coordination, monitoring
# Keep this clean - just coordination
/plan "Feature requirements"
# Monitor other terminals
```

**Terminal 2-5 (Work - Agents)**:
```bash
# Terminal 2
claude "@backend 'API implementation'"

# Terminal 3
claude "@frontend 'UI implementation'"

# Terminal 4
claude "@verify-app 'Run tests'"

# Terminal 5
claude "/ralph-loop 'Migrate database'"
```

**Each terminal**:
- Own context window (200K tokens)
- Independent progress
- Voice notifications when done
- Can run overnight

### Benefit: 5 Terminals = 1 Million Tokens

```
Terminal 1: 200K (coordination)
Terminal 2: 200K (@backend)
Terminal 3: 200K (@frontend)
Terminal 4: 200K (@verify-app)
Terminal 5: 200K (ralph-loop)
─────────────────────────
Total:      1M tokens available
```

---

## 6. Web Handoff (claude.ai/code)

### Use `&` Operator to Background

```bash
# Local terminal getting full?
# Hand off to web

# Background local session
claude "Implement auth" &
# → Opens web session
# → Task continues on web
# → Local terminal freed

# Or start directly on web
# Open claude.ai/code
# Start task there
# Local terminals available for other work
```

### When to Use Web

**Use web for**:
- Long-running tasks (overnight)
- When all 5 terminals busy
- Mobile (start on phone, continue on desktop)
- Collaborative work (share web session)

**Keep local for**:
- Quick edits
- Planning
- Code review
- Coordination

### Web + Local Strategy

```bash
# Morning (on phone via Claude iOS app)
# Start task on web
"Implement user authentication"

# Commute
# Task running on web

# Arrive at desk
# Check web progress
# Continue locally if needed
claude --teleport web-session-id

# Or keep on web
# Use local for other features
```

---

## 7. Context Warning Workflow

### At 70% Usage

**Voice alert**: *"Context at 70 percent. Consider forking."*

**Decision Tree**:
```
Context at 70%?
├─ Simple task left? → Finish it, then summarize
├─ Complex task left? → Summarize NOW, fork to agent
├─ Planning phase? → Write to PRD, clear context
└─ Implementation? → Fork to agent or new terminal
```

### Summarize Before Forking

**Always write summary first**:
```bash
# Before context gets too full
claude "Summarize our work so far to ~/.claude/summaries/current-work.md"

# Then fork
claude "@agent 'Continue work from summary: ~/.claude/summaries/current-work.md'"
```

---

## 8. Plan Mode Pattern (Best for Context)

### Why Plan Mode Saves Context

**Without Plan Mode**:
```bash
# Main session
claude "Build user management"
# → Research (20K tokens)
# → Design (15K tokens)
# → Planning (25K tokens)
# → Implementation (40K tokens)
# → Testing (10K tokens)
# Total: 110K tokens in one session
```

**With Plan Mode**:
```bash
# Plan session (separate)
Plan mode: Research + Design + Planning
# → Write to plan file
# → 60K tokens used

# Exit, clear context

# Execute session (fresh)
claude "Implement plan: ~/.claude/plans/user-mgmt.md"
# → Implementation (40K tokens)
# → Testing (10K tokens)
# Total: 50K tokens (not 110K)
```

**Context saved**: 60K tokens

---

## 9. Emergency: Context at 95%

### Immediate Actions

```bash
# 1. Stop current work
# Don't add more tokens!

# 2. Summarize FAST
claude "Quick summary of current state to /tmp/emergency-summary.md"

# 3. Exit immediately
exit

# 4. Resume with summary
claude "Read /tmp/emergency-summary.md and continue implementation"
```

### Prevent This

- Monitor usage after each response
- Set up 70% warnings
- Use Plan mode for large features
- Fork agents early
- Use terminals in parallel

---

## 10. Automation: Context Monitoring

### Manual Check
```bash
# After each Claude response, check status bar
# Shows: "X / 200000 tokens used"

# Calculate percentage
# If > 140000 (70%), act
```

### Automatic Workflow

**In your workflow**:
```bash
# 1. Plan (Plan mode)
shift+tab shift+tab
# → Write plan
# → Exit

# 2. Execute (Fresh context)
claude "Implement plan"
# → Fork agents when needed
# → Monitor context

# 3. At 70%
# → Summarize
# → Fork or restart

# 4. Verify (Fresh context)
/verify-app

# 5. Commit (Fresh context)
/commit-push-pr
```

---

## 11. Context Budget Strategy

### Allocate Tokens by Phase

| Phase | Tokens | Strategy |
|-------|--------|----------|
| Planning | 50K | Plan mode → Write PRD → Clear |
| Research | 30K | /research → Save docs → Clear |
| Implementation | 80K | Fork agents, use terminals |
| Testing | 20K | /verify-app in fresh context |
| Review | 10K | /code-review in fresh context |
| Commit | 10K | /commit-push-pr in fresh context |

**Total**: 200K tokens, but split across multiple sessions

---

## 12. Best Practices

### DO
- ✅ Write summaries at 70%
- ✅ Use Plan mode for large features
- ✅ Fork agents (`context: fork`)
- ✅ Use 5 terminals in parallel
- ✅ Hand off to web with `&`
- ✅ Clear context between planning and execution
- ✅ Monitor token usage constantly

### DON'T
- ❌ Let context hit 90%+
- ❌ Keep adding to full context
- ❌ Skip summarization
- ❌ Use single terminal for everything
- ❌ Ignore context warnings

---

## 13. Quick Reference

### Context Full? Quick Fixes

```bash
# Option 1: Summarize & Restart
claude "Summarize to /tmp/state.md"
exit
claude "Read /tmp/state.md and continue"

# Option 2: Fork to Agent
claude "@agent 'Continue implementation'"

# Option 3: New Terminal
# Open new terminal
claude "Continue work from current state"

# Option 4: Web Handoff
claude "Continue on web" &
```

---

## Files

```
~/.claude/summaries/           # Context handoff summaries
~/.claude/plans/               # PRDs for fresh execution
~/.claude/scripts/check-context.sh  # Context monitor
```

---

**Your strategy is correct**: Write document, clear context, continue with document. Use for everything, not just PRD.

**Remember**: 5 terminals × 200K = 1M tokens available. Use them.
