# Guide Command

Interactive workflow guidance based on Boris's approach.

## Usage

```bash
/guide              # Start or continue workflow
/guide "feature"    # Start with specific feature
```

## Boris's Workflow (What This Follows)

1. **Plan mode first** (shift+tab twice) - Get the plan right
2. **Auto-accept mode** - Let Claude 1-shot it
3. **Verify the work** - Give Claude feedback loop
4. **Commit** - /commit-push-pr

## The Steps

### Step 0: Project Setup (First Time Only)

```
If no CLAUDE.md exists in this project:

/init-project

This explores the codebase and generates a project CLAUDE.md
with tech stack, structure, and key files.
```

### Step 1: Plan Mode

```
Start in Plan mode (shift+tab twice in Claude Code).

Go back and forth until the plan looks right.
A good plan = Claude can usually 1-shot implementation.

Questions to answer:
- What exactly are we building?
- What files will change?
- What's the approach?
- What could go wrong?
```

### Step 2: Research (Mandatory for New Code)

```
Before writing code:

Skill(research) "topic"
# or
/research "topic"

This checks official docs and finds boilerplates.
NO CODE WITHOUT DOCS.
```

### Step 3: Execute

```
Once plan is good:
1. Switch to auto-accept mode (cmd+shift+a or setting)
2. Let Claude implement the plan
3. Claude should verify its work as it goes
```

### Step 4: Verify

```
Give Claude a way to verify:
- Run tests: npm test
- Type check: npx tsc --noEmit
- Build: npm run build
- Manual test if needed

This 2-3x's the quality.
```

### Step 5: Commit

```
/commit-push-pr

Creates commit, pushes, opens PR.
```

### Step 6: Learn (Optional)

```
If you built a new integration (Stripe, auth, etc):

/learn "stripe-payments"

Saves it for next time.
```

## Parallel Work (Boris runs 5 Claudes)

For bigger features:
- Terminal 1: Main planning/coordination
- Terminal 2-5: Parallel agents or web sessions

Use system notifications to know when Claude needs input.

## Key Points from Boris

1. **Opus 4.5 with thinking** - Best model, less steering needed
2. **Shared CLAUDE.md** - Team updates when Claude does something wrong
3. **Slash commands for inner loops** - /commit-push-pr dozens of times daily
4. **Subagents for common workflows** - code-simplifier, verify-app, etc.
5. **Give Claude verification** - Most important for quality
6. **Pre-allow safe commands** - Use /permissions, not --dangerously-skip-permissions

## When to Use This

- Starting a new project → runs /init-project first
- Starting a new feature
- Not sure what to do next
- Want step-by-step guidance
- Learning the workflow
