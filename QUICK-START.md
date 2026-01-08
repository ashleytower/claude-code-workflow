# Quick Start Guide

**Copy-paste these commands for common scenarios**

---

## Scenario 1: Starting a Brand New Project

```bash
# Navigate to project directory
mkdir ~/projects/my-new-app
cd ~/projects/my-new-app

# Start guided workflow
claude "/guide 'Build [describe your app]'"

# Example:
claude "/guide 'Build a task management app with real-time collaboration'"

# Guide will:
# → Ask clarifying questions
# → Create comprehensive PRD
# → Prompt you to exit

# Exit for fresh context
exit

# Execute from PRD
claude "Read PRD and implement: ~/.claude/plans/[project-name]-prd.md"
```

---

## Scenario 2: Adding Feature to Existing Project

```bash
# Navigate to your project
cd ~/projects/my-app

# Start guided workflow for feature
claude "/guide 'Add [feature name]'"

# Examples:
claude "/guide 'Add Stripe subscription payments'"
claude "/guide 'Add email notifications with Resend'"
claude "/guide 'Add file uploads with Uploadthing'"
claude "/guide 'Add Telegram bot integration'"

# Guide will:
# → Check for existing skills (instant if saved)
# → Research docs (if building from scratch)
# → Design UI (if applicable)
# → Create plan
# → Prompt for context reset
# → Execute in fresh context
```

---

## Scenario 3: Quick Integration (When Skill Exists)

```bash
# Just describe what you want
claude "Add Stripe payments"
claude "Add Resend emails"
claude "Add authentication"

# Auto-detects:
# → Checks ~/.claude/skills/[integration].md
# → Uses saved code if exists
# → 10 minutes instead of 2 hours
```

---

## Scenario 4: After Successful Implementation

```bash
# Verify everything works
claude "/verify-app"

# If tests pass and new integration added:
claude "/learn 'stripe-payments'"
# or
claude "/learn 'resend-emails'"
# or
claude "/learn 'uploadthing'"

# Saves for next project
# Next time = instant
```

---

## Scenario 5: Multiple Features in Parallel

```bash
# Open 5 terminal tabs

# Terminal 1 (Main)
cd ~/projects/my-app
claude "Coordinate: Backend team add Stripe API, Frontend team add checkout UI, Testing team verify"

# Terminal 2 (Backend)
claude "@backend 'Implement Stripe API endpoints'"

# Terminal 3 (Frontend)
claude "@frontend 'Implement checkout UI'"

# Terminal 4 (Testing)
claude "@verify-app 'Verify Stripe integration'"

# Terminal 5 (Bash)
claude "@bash 'Run Stripe webhook listener'"

# Voice alerts when each completes
```

---

## Scenario 6: Resuming Previous Work

```bash
cd ~/projects/my-app

# Just run guide without arguments
claude "/guide"

# Auto-detects:
# → Reads .claude/guide-state.json
# → Shows last phase
# → Offers to resume
```

---

## Scenario 7: Check Progress

```bash
claude "/guide stats"

# Shows:
# - Features completed
# - PRs created
# - Skills saved
# - Current streak
```

---

## Scenario 8: Research Before Coding

```bash
# Always research first (hook enforces this)
claude "/research 'Stripe subscriptions with Next.js'"

# Checks:
# - Official docs (latest)
# - GitHub boilerplates
# - Existing skills
# - Saves research
```

---

## Scenario 9: Save Time on Auth

```bash
# Framework auto-detected from package.json
claude "Add authentication"

# Next.js → Recommends Clerk or Supabase
# React Native → Uses Supabase
# FastAPI → Uses Supabase

# Copy-paste code provided
# 1 day instead of 1 week
```

---

## Scenario 10: Learn from Bugs

```bash
# Encountered a bug during implementation?
claude "/system-evolve 'Stripe webhook signature verification failed'"

# Updates:
# - CLAUDE.md knowledge
# - Reference docs
# - Plan templates
# - Never make same mistake again
```

---

## Common Integration Commands

```bash
# Payments
claude "Add Stripe payments"
claude "Add PayPal checkout"

# Email
claude "Add Resend transactional emails"
claude "Add SendGrid bulk emails"

# Storage
claude "Add Uploadthing file uploads"
claude "Add S3 storage"

# Messaging
claude "Add Telegram bot"
claude "Add Slack notifications"

# Monitoring
claude "Add Sentry error tracking"
claude "Add PostHog analytics"

# Auth (already has skill)
claude "Add authentication"
```

---

## Pro Tips

### Build Once, Reuse Forever

```bash
# First project (2 hours)
claude "/guide 'Add Stripe subscriptions'"
# ... implementation ...
claude "/verify-app"
claude "/learn 'stripe-subscriptions'"

# Second project (10 minutes)
claude "Add Stripe subscriptions"
# Uses saved skill → instant
```

### Context at 70%?

```bash
# Voice alert: "Context at 70 percent"

# Option 1: Summarize and restart
claude "Summarize to /tmp/state.md"
exit
claude "Read /tmp/state.md and continue"

# Option 2: Fork to agent
claude "@backend 'Continue implementation'"

# Option 3: New terminal
# Open new terminal tab
claude "Continue from current state"
```

### Update Everything

```bash
# Update Claude Code
claude "/self-update"

# Update LLM models
claude "/update-council"

# Update auth docs (auto-weekly)
~/.claude/scripts/update-auth-docs.sh
```

---

## Workflow Shortcuts

```bash
# Full guided workflow
/guide → /research → /ui-design → /plan → /execute → /verify-app → /learn → /commit-push-pr

# Quick feature (existing project)
/guide 'feature' → uses saved skill → /verify-app → /commit-push-pr

# Autonomous overnight
/ralph-loop 'migrate all components to TypeScript'
```

---

## Your First Project

```bash
# Step 1: Create project
mkdir ~/projects/test-app
cd ~/projects/test-app

# Step 2: Start guide
claude "/guide 'Build a simple todo app'"

# Step 3: Follow prompts
# Answer questions about your app

# Step 4: Exit when prompted
exit

# Step 5: Execute
claude "Read PRD and implement: ~/.claude/plans/todo-app-prd.md"

# Step 6: Verify
claude "/verify-app"

# Step 7: No integrations to save (basic app)
# But if you added Supabase:
# claude "/learn 'supabase-crud'"

# Step 8: Commit
claude "/commit-push-pr"

# Done! First project complete.
```

---

## Next Steps

1. Try the workflow on a real project
2. Save your first skill with `/learn`
3. Reuse that skill on your next project
4. Watch your skills library grow
5. Build faster every time

**Philosophy**: Every project makes the next one faster.
