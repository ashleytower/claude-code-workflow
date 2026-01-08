---
name: guide
description: Step-by-step feature development workflow
category: workflow
---

# Guide Skill

**Purpose**: Provide structured, step-by-step guidance through complete feature development workflow.

## When to Use

Use this skill when:
- User asks "how do I add [feature]?"
- User wants guidance on workflow
- User is new to the project
- User wants systematic feature development

## Quick Reference

```bash
# New project
/guide "Build fitness tracking app"
→ Auto-creates PRD → Guides through implementation

# Existing project, new feature
/guide "Add Stripe payments"
→ Skips PRD → Guides through feature implementation

# Resume previous work
/guide
→ Detects guide-state.json → Resumes from last phase
```

## Workflow Phases

1. **Project Detection** - Auto-detects new vs existing project
2. **Research** - Mandatory docs check, find boilerplates
3. **UI Design** - Mockups before code (if UI involved)
4. **Planning** - Structured execution plan
5. **Context Reset** - Clear for fresh execution
6. **Execution** - Multi-terminal parallel work
7. **Verification** - Tests, type-check, lint, build
8. **Quality Checks** - Orchestrator review
9. **Commit** - Automated git workflow
10. **Learning** - System evolution + skill extraction

## Auto-Detection Logic

```javascript
// Check project state
const hasPackageJson = fileExists('package.json')
const hasCLAUDEmd = fileExists('CLAUDE.md')
const hasGuideState = fileExists('.claude/guide-state.json')

if (!hasPackageJson && !hasCLAUDEmd) {
  return 'new-project' // Create PRD
} else if (hasCLAUDEmd && !hasGuideState) {
  return 'new-feature' // Skip to research
} else if (hasGuideState) {
  return 'resume' // Continue from last phase
}
```

## Integration Detection

Before implementing any feature, check for existing skills:

```bash
# Check if skill exists
ls ~/.claude/skills/stripe-payments.md
ls ~/.claude/skills/resend-emails.md
ls ~/.claude/skills/auth.md

# If exists: Use saved patterns
# If missing: Build from scratch, suggest /learn after
```

## Voice Notifications

Throughout workflow:
- "PRD created"
- "Research complete"
- "UI design approved"
- "Planning complete"
- "Ready for execution"
- "Verification complete"
- "Quality checks passed"
- "Pull request created"
- "Skill saved. [name] ready for reuse."

## State Management

Saves progress to `.claude/guide-state.json`:

```json
{
  "currentPhase": "verification",
  "currentFeature": "stripe-payments",
  "featuresCompleted": ["auth", "profile"],
  "prsCreated": [42, 43],
  "skillsSaved": ["stripe-payments"],
  "stats": {
    "features": 3,
    "prs": 3,
    "commits": 18,
    "tests": 42
  }
}
```

## Multi-Terminal Coordination

At execution phase, instructs:

```
Terminal 1: Main coordination
Terminal 2: @frontend agent
Terminal 3: @backend agent
Terminal 4: @verify-app agent
Terminal 5: @bash agent (if needed)
```

Voice alerts when each completes.

## Learning Integration

After successful verification, auto-suggests:

```
💡 Save implementation as reusable skill?

Detected:
├─ Stripe (stripe package, STRIPE_SECRET_KEY)
└─ Resend (resend package, RESEND_API_KEY)

Save for future projects:
  /learn 'stripe-payments'
  /learn 'resend-emails'
```

## Progress Tracking

```bash
/guide stats

📊 YOUR PROGRESS

Features Completed: 3/10
PRs Created: 3
Skills Saved: 2
Current Streak: 7 days
```

## Notes

- Auto-detects project type
- Enforces research before code
- Saves institutional knowledge
- Multi-terminal parallel execution
- Voice keeps you informed
- Resumes from any phase
