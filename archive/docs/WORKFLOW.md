# Complete Workflow Guide

**Last Updated**: 2026-01-08

---

## Starting a Project

### New Project (No Code Yet)

```bash
cd ~/projects/my-app
claude "/guide 'Build fitness tracking app for runners'"

# Guide auto-detects: New project
# → Creates PRD
# → Prompts: "Exit and run fresh execution"

exit
claude "Read PRD and implement: ~/.claude/plans/fitness-app-prd.md"
```

### Existing Project, New Feature

```bash
cd ~/projects/my-app
claude "/guide 'Add Stripe payments'"

# Guide auto-detects: Existing project
# → Skips PRD
# → Goes straight to research phase
# → Checks for stripe-payments.md skill
# → If exists: Uses saved code
# → If missing: Builds from scratch
```

---

## The 10 Phases

### 1. Project Detection (Auto)

```
Checks:
- package.json exists?
- CLAUDE.md exists?
- guide-state.json exists?

Decides:
- New project → Create PRD
- Existing project → Skip to research
- Resume work → Continue from last phase
```

### 2. Research (Mandatory)

```bash
# Auto-invoked by guide
/research "Stripe payments with Next.js"

# Checks:
- Official Stripe docs (latest version)
- GitHub boilerplates (stars, recency)
- Existing ~/.claude/skills/stripe-payments.md

# Saves to:
.claude/research/stripe-payments.md
```

**Hook enforces**: NO Write/Edit until docs checked.

### 3. UI Design (If Applicable)

```bash
# If feature has UI
/ui-design "Checkout flow with card input"

# Generates mockup
# Shows for approval
# Saves to: .claude/designs/checkout-flow.md
```

### 4. Planning

```bash
# Creates structured plan
/prime  # Load context
/plan stripe-payments

# Saves to:
.claude/plans/stripe-payments.md
```

### 5. Context Reset

```
⚠️  Exit session now

Why: Keep context light for execution

Next:
  exit
  claude "/execute .claude/plans/stripe-payments.md"
```

### 6. Execution (Fresh Context)

```
Opens 5 terminals:

Terminal 1: Main coordination
Terminal 2: @frontend (if needed)
Terminal 3: @backend (API implementation)
Terminal 4: @verify-app (tests)
Terminal 5: @bash (commands)

Voice alerts: "Task done" when each completes
```

### 7. Verification

```bash
/verify-app

# Runs:
- Unit tests
- Integration tests
- Type checking
- Linting
- Build
- Performance checks
- Security scans

# Outputs:
✅ VERIFICATION REPORT
💡 Save as skill? /learn 'stripe-payments'
```

### 8. Quality Checks (Auto)

```bash
# Orchestrator auto-invoked by Stop hook
@orchestrator reviews:
- Code quality
- Test coverage
- Performance
- Security
```

### 9. Commit & PR

```bash
/commit-push-pr

# Auto-generates:
- Commit message (from changes)
- Branch name
- PR description
- Creates PR
```

### 10. Learning (Two Types)

#### A. Bug/Issue Learning

```bash
# If you encountered bugs
/system-evolve "Stripe webhook signature verification issue"

# Updates:
- CLAUDE.md institutional knowledge
- Reference docs
- Plan templates
```

#### B. Success Learning (NEW!)

```bash
# Save implementation as reusable skill
/learn 'stripe-payments'

# Extracts:
- Installation commands
- Environment variables
- Setup code (framework-specific)
- Common use cases
- Gotchas encountered
- Testing patterns

# Saves to:
~/.claude/skills/stripe-payments.md

# Next project:
claude "Add Stripe"
→ Uses saved skill
→ 10 minutes instead of 2 hours
```

---

## Skill System

### What Gets Saved

Every successful integration can become a skill:

- **Payments**: Stripe, PayPal
- **Email**: Resend, SendGrid, Mailgun
- **Storage**: Uploadthing, S3, Cloudinary
- **Messaging**: Telegram, Slack, Discord
- **Monitoring**: Sentry, PostHog, LogRocket
- **Auth**: Clerk, Supabase (auth.md already exists)

### When to Use /learn

After `/verify-app` succeeds:

```
✅ All tests passed

💡 Save implementation as reusable skill?

Detected integrations:
├─ Stripe (stripe package, STRIPE_SECRET_KEY)
└─ Resend (resend package, RESEND_API_KEY)

/learn 'stripe-payments'
/learn 'resend-emails'
```

### Skill Template

```markdown
---
name: stripe-payments
category: payments
frameworks: [nextjs, react-native]
last_updated: 2026-01-08
version: stripe@14.0.0
---

# Stripe Payments Integration

## Installation

npm install stripe

## Environment Variables

STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

## Setup Code

### Next.js
[Copy-paste code]

### React Native
[Copy-paste code]

## Common Use Cases

### Create Payment Intent
[Code snippet]

### Handle Webhook
[Code snippet]

## Gotchas

- Webhook signature verification must use raw body
- Test mode vs live mode keys
- Currency must be lowercase

## Testing

[Test examples with Stripe CLI]
```

### Using Saved Skills

```bash
# Next project
claude "Add Stripe payments"

# Checks: ~/.claude/skills/stripe-payments.md exists?
# → YES: Uses saved code
# → NO: Builds from scratch, suggests /learn after
```

---

## Context Management

### 70% Warning

```bash
# Voice alert at 140K tokens
"Context at 70 percent. Consider forking."

# Options:
1. Summarize and exit
2. Fork to agent
3. New terminal
4. Web handoff
```

### PRD Pattern

```
1. Planning phase uses context
2. Write PRD to file
3. Exit (clear context)
4. Execute with PRD (fresh context)
```

### Agent Forking

All agents have `context: fork`:

```bash
claude "@backend 'Implement Stripe API'"

# Backend agent:
- Starts with 0% context (isolated)
- Returns summary only
- Main session stays at same %
```

### 5 Terminals = 1M Tokens

```
Terminal 1: 200K (coordination)
Terminal 2: 200K (@frontend)
Terminal 3: 200K (@backend)
Terminal 4: 200K (@verify-app)
Terminal 5: 200K (@bash)
─────────────────────────
Total:      1M tokens
```

---

## Real Example: Stripe Integration

### First Time (2 hours)

```bash
# Terminal 1
cd ~/projects/ecommerce-app
claude "/guide 'Add Stripe checkout'"

# Phase 1: Detects existing project
# Phase 2: Research Stripe docs
# Phase 3: Design checkout UI
# Phase 4: Plan implementation
# Phase 5: Exit for fresh context

exit

# Fresh context
claude "/execute .claude/plans/stripe-checkout.md"

# Implementation runs...
# Voice: "Task done"

claude "/verify-app"
# All tests pass

# Save for next time
claude "/learn 'stripe-payments'"
# Skill saved to ~/.claude/skills/stripe-payments.md

claude "/commit-push-pr"
# PR created
```

**Time**: 2 hours (research + implementation + testing)

### Second Time (10 minutes)

```bash
# Different project
cd ~/projects/saas-app
claude "Add Stripe subscription billing"

# Auto-detects: stripe-payments.md skill exists
# Uses saved code patterns
# Adapts to subscription model
# Done in 10 minutes

claude "/verify-app"
# Tests pass

claude "/commit-push-pr"
# PR created
```

**Time**: 10 minutes (just adaptation, no research)

---

## Skills Library

Your growing library:

```
~/.claude/skills/
├── auth.md                    # Already exists (auto-updates weekly)
├── stripe-payments.md         # After first Stripe implementation
├── resend-emails.md          # After first Resend implementation
├── uploadthing.md            # After first file upload
├── telegram-bot.md           # After first bot
├── sentry-monitoring.md      # After first Sentry setup
├── supabase-realtime.md      # After first realtime feature
└── ... (grows over time)
```

Each skill = 1-2 hours saved on future projects.

10 skills = 10-20 hours saved.

---

## Workflow Summary

```
New Project:
1. /guide → Create PRD
2. Exit
3. Implement from PRD
4. /verify-app
5. /learn (save skills)
6. /commit-push-pr

Existing Project, New Feature:
1. /guide → Auto-detects existing project
2. Research → Check for saved skills
3. If skill exists: Use it (10 min)
4. If skill missing: Build (2 hr) → /learn to save
5. /verify-app
6. /commit-push-pr

Every Build:
- Research docs (mandatory)
- Use saved skills when available
- Save new integrations as skills
- Next time = instant
```

---

## Voice Notifications

Throughout workflow:
- "PRD created"
- "Research complete"
- "UI design approved"
- "Planning complete"
- "Task done"
- "Verification complete"
- "Skill saved. [name] ready for reuse."
- "Pull request created"

---

## Key Philosophy

1. **Build once, reuse everywhere** - Every integration becomes institutional knowledge
2. **Mandatory research** - No guessing, always check docs first
3. **Context optimization** - PRD pattern + agent forking + 5 terminals
4. **Continuous learning** - Bugs → /system-evolve, Success → /learn
5. **Automation** - Voice alerts, auto-updates, parallel execution

---

**Next**: Try the workflow on your next project and start building your skills library.
