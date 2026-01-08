# Learn Command

**Purpose**: Captures successful implementations as reusable skills. Turns every integration into institutional knowledge.

**Philosophy**: Build it once, use it everywhere. Second time = copy-paste.

## Usage

```bash
# After successful implementation
claude /learn 'stripe-payments'

# Specify what to extract
claude /learn 'resend-emails' --focus "API setup, environment variables, common patterns"

# Save from specific files
claude /learn 'uploadthing' --files "lib/uploadthing.ts,app/api/uploadthing/route.ts"
```

## What Gets Saved

The command extracts and saves to `~/.claude/skills/[name].md`:

1. **API Setup Code**
   - Installation commands
   - Environment variables
   - Configuration files
   - Initialization code

2. **Integration Patterns**
   - Common use cases
   - Code snippets for typical operations
   - Error handling patterns

3. **Gotchas & Learnings**
   - Issues encountered during implementation
   - Solutions that worked
   - Things to avoid
   - Performance considerations

4. **Framework-Specific Adaptations**
   - Next.js vs React Native differences
   - Backend vs frontend patterns
   - Type definitions

5. **Testing Patterns**
   - How to test the integration
   - Mock/stub examples
   - Common test cases

## Skill Template

```markdown
---
name: [service-name]
category: [integration|auth|payments|email|storage|monitoring]
frameworks: [nextjs, react-native, fastapi]
last_updated: [date]
version: [service version]
---

# [Service Name] Integration

## Quick Start

[Framework detection and auto-pick code]

## Installation

\`\`\`bash
# Next.js
npm install [package]

# React Native
npx expo install [package]

# Python
pip install [package]
\`\`\`

## Environment Variables

\`\`\`.env
[SERVICE]_API_KEY=
[SERVICE]_SECRET=
\`\`\`

## Setup Code

### Next.js
\`\`\`typescript
// Copy-paste code here
\`\`\`

### React Native
\`\`\`typescript
// Copy-paste code here
\`\`\`

### FastAPI
\`\`\`python
# Copy-paste code here
\`\`\`

## Common Use Cases

### [Use Case 1]
\`\`\`typescript
// Code snippet
\`\`\`

### [Use Case 2]
\`\`\`typescript
// Code snippet
\`\`\`

## Gotchas

- [Issue 1]: [Solution]
- [Issue 2]: [Solution]

## Testing

\`\`\`typescript
// Test examples
\`\`\`

## Updates

- [Date]: [What changed]
\`\`\`

## Invocation

```bash
# Manual
/learn 'stripe-payments'

# Auto-suggested after successful /verify-app
✓ All tests passed
✓ Implementation verified

💡 Save this as a reusable skill?
   Run: /learn 'stripe-payments'
```

## Integration with Workflow

### After /verify-app Success

```bash
# verify-app completes successfully
claude /verify-app

✓ All tests passed
✓ Build successful
✓ No linting errors

💡 Capture this implementation?
   What did you build? (e.g., 'stripe-payments', 'resend-emails')

[User: "stripe-payments"]

INVOKE: /learn 'stripe-payments'
```

### Auto-Detection

The learn command analyzes:
- Files changed in git diff
- Package.json dependencies added
- Environment variables referenced
- API integrations detected

Suggests skill name automatically:
```bash
claude /learn

Detected integrations:
1. Stripe (stripe package, STRIPE_SECRET_KEY env var)
2. Resend (resend package, RESEND_API_KEY env var)

Which one to save? (or 'both')
```

## Script: learn.sh

Located at: `~/.claude/scripts/learn.sh`

```bash
#!/bin/bash
# Extract implementation into reusable skill

SKILL_NAME=$1
SKILL_DIR="$HOME/.claude/skills"
SKILL_FILE="$SKILL_DIR/$SKILL_NAME.md"

# Detect framework
detect_framework() {
  if [ -f "package.json" ]; then
    if grep -q "next" package.json; then
      echo "nextjs"
    elif grep -q "expo" package.json; then
      echo "react-native"
    fi
  elif [ -f "requirements.txt" ]; then
    echo "fastapi"
  fi
}

# Extract relevant files
extract_files() {
  # Get recently changed files
  git diff --name-only HEAD~1 HEAD
}

# Extract environment variables
extract_env_vars() {
  # Search for env variables in code
  grep -r "process.env" --include="*.ts" --include="*.tsx" --include="*.js" | \
    grep -oE "process\.env\.[A-Z_]+" | sort -u
}

# Extract dependencies
extract_dependencies() {
  # Get recently added dependencies
  git diff HEAD~1 HEAD package.json | grep "+" | grep -v "+++"
}

# Invoke Claude to generate skill from context
claude <<EOF
Create a reusable skill for: $SKILL_NAME

Extract from recent implementation:

Framework: $(detect_framework)

Files changed:
$(extract_files)

Environment variables used:
$(extract_env_vars)

Dependencies added:
$(extract_dependencies)

Generate a comprehensive skill following the template in /learn command.

Focus on:
1. Copy-paste code snippets
2. Framework-specific variations
3. Common use cases
4. Gotchas encountered
5. Testing patterns

Save to: $SKILL_FILE
EOF
```

## Examples

### Stripe Payments

```bash
# After implementing Stripe checkout
claude /verify-app
# All tests pass

claude /learn 'stripe-payments'

# Creates ~/.claude/skills/stripe-payments.md with:
# - Installation for Next.js/React Native
# - Webhook handling code
# - Payment intent creation
# - Customer management
# - Subscription handling
# - Testing with Stripe CLI
# - Gotcha: Webhook signature verification
```

**Next project:**
```bash
claude "Add Stripe"
# → Detects stripe-payments.md skill exists
# → Uses saved code patterns
# → 10 minutes instead of 2 hours
```

### Resend Email

```bash
claude /learn 'resend-emails'

# Creates ~/.claude/skills/resend-emails.md with:
# - API setup
# - Send transactional email
# - Email templates
# - React Email components
# - Error handling
# - Rate limiting
```

**Next project:**
```bash
claude "Add email notifications"
# → Detects resend-emails.md skill
# → Copy-pastes working code
# → Instant implementation
```

### Telegram Bot

```bash
claude /learn 'telegram-bot'

# Creates ~/.claude/skills/telegram-bot.md with:
# - Bot token setup
# - Webhook vs polling
# - Command handlers
# - Inline keyboards
# - File uploads
# - Message formatting
```

## Skill Auto-Discovery

When implementing anything, Claude checks:
```bash
# Before writing code
ls ~/.claude/skills/*.md

# If skill exists:
✓ Found skill: stripe-payments.md
  Using saved patterns for Stripe integration

# If skill missing:
⚠ No skill found for this integration
  Building from scratch
  (Run /learn after to save for next time)
```

## Categories

Skills organized by category:

```
~/.claude/skills/
├── integrations/
│   ├── stripe-payments.md
│   ├── resend-emails.md
│   ├── uploadthing.md
│   └── telegram-bot.md
├── auth/
│   ├── auth.md (already exists)
│   └── clerk.md
├── database/
│   ├── supabase-rls.md
│   └── prisma-schema.md
├── monitoring/
│   ├── sentry.md
│   └── posthog.md
└── ui/
    ├── shadcn.md
    └── tailwind-config.md
```

## Voice Notifications

```bash
# After /learn completes
"Skill saved. [service-name] ready for reuse."
```

## Integration with Other Commands

### /guide Phase 9
```bash
# After system-evolve
INVOKE: /system-evolve

✓ System improvements saved

💡 Save implementation as reusable skill?
   INVOKE: /learn 'feature-name'
```

### /verify-app
```bash
# After successful verification
✓ All tests passed

Next steps:
1. /commit-push-pr (create PR)
2. /learn '[name]' (save as skill)
```

## Notes

- Skills saved in markdown for easy editing
- Framework detection automatic
- Extracts code from git diff
- Voice notification on save
- Auto-suggested after successful builds
- Skills reusable across all projects
- Updates independently (like auth skill)

---

**Philosophy**: Every implementation teaches the system. Build once, reuse everywhere.
