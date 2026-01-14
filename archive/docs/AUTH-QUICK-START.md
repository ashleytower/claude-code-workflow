# Auth - Stop Wasting Time

**Last updated**: 2026-01-08
**Auto-updates**: Weekly (Sunday 3 AM)

---

## The Problem

You spend hours on auth every project. No more.

## The Solution

Smart auth skill that:
1. Detects your framework
2. Picks best auth solution
3. Gives copy-paste code
4. Auto-updates weekly

---

## Usage

```bash
# Just ask for auth
claude "Add authentication"

# Or use skill directly
claude "Invoke auth skill for Next.js"

# Agent auto-detects framework and recommends solution
```

---

## What You Get

### Framework Detection
Checks your project:
- package.json → Next.js/React Native
- requirements.txt → FastAPI/Python
- Recommends best auth solution

### Copy-Paste Implementation
Exact code for your framework:
- Installation commands
- Environment variables
- Code snippets
- Middleware/routing setup
- Protected routes

### Decision Matrix
| Framework | Best Choice | Time | Free Tier |
|-----------|-------------|------|-----------|
| Next.js (fast) | Clerk | 1 day | 10K MAU |
| Next.js (cheap) | Supabase | 2 days | 50K MAU |
| React Native | Supabase | 2 days | 50K MAU |
| FastAPI | Supabase | 1 day | 50K MAU |

---

## Quick Examples

### Next.js + Clerk (Fastest)
```bash
npm install @clerk/nextjs
# → Gives you exact code for:
# - app/layout.tsx
# - middleware.ts
# - sign-in/page.tsx
# - Protected routes
```

**Result**: Working auth in 1 day

### React Native + Supabase
```bash
npx expo install @supabase/supabase-js
# → Gives you exact code for:
# - lib/supabase.ts
# - app/login.tsx
# - OAuth (Google/Apple)
# - Session management
```

**Result**: Working auth in 2 days

---

## Auto-Updates

### Weekly Check (Sunday 3 AM)
```bash
# Runs automatically
~/.claude/scripts/update-auth-docs.sh

# Checks:
- Latest Clerk version
- Latest Supabase version
- Breaking changes
- New features
- Security patches
```

### Voice Alert
If breaking changes detected:
*"Auth breaking changes detected"*

Check logs:
```bash
cat ~/.claude/logs/auth-updates.log
```

---

## Setup Auto-Updates

```bash
# Run once
chmod +x ~/.claude/cron-setup.sh
~/.claude/cron-setup.sh

# Confirms:
"Auth docs will update every Sunday at 3 AM"
```

---

## What's Included

### All Frameworks Covered
- Next.js (App Router)
- React Native/Expo
- FastAPI/Python
- Any framework (NextAuth.js)

### All Auth Methods
- Email/password
- OAuth (Google, GitHub, Apple)
- Magic links
- MFA/2FA
- Passwordless

### All Platforms
- Web (Next.js)
- Mobile (React Native/Expo)
- API (FastAPI)

---

## Current Recommendations (2026)

### Next.js
**Fast shipping**: Clerk
- Pre-built UI components
- 1-day implementation
- $0.02/MAU after 10K free

**Cost optimization**: Supabase
- 50,000 MAU free (5x more)
- Database integration + RLS
- 2-day implementation

### React Native/Expo
**Only choice**: Supabase
- Best mobile support
- Official Expo docs
- Works with Expo SDK

**WARNING**: Clerk + Supabase integration deprecated (April 2025)

### FastAPI/Python
**Best choice**: Supabase
- Python SDK
- Database integration
- JWT tokens

---

## Files

```
~/.claude/skills/auth.md              # Auth skill (auto-used by agents)
~/.claude/scripts/update-auth-docs.sh # Weekly update script
~/.claude/logs/auth-updates.log       # Update history
~/.claude/backups/auth-*.md           # Backups (daily)
```

---

## Test It

```bash
# Create test Next.js project
npx create-next-app@latest test-auth
cd test-auth

# Ask Claude to add auth
claude "Add authentication with Clerk"

# Watch it:
# 1. Detect Next.js
# 2. Recommend Clerk
# 3. Give installation commands
# 4. Provide exact code
# 5. Set up middleware
# 6. Add protected routes

# Result: Working auth in 1 day
```

---

## Sources (Auto-Updated)

- [Clerk Next.js Guide](https://clerk.com/docs/quickstarts/nextjs)
- [Supabase Next.js Guide](https://supabase.com/docs/guides/auth/quickstarts/nextjs)
- [Supabase React Native](https://supabase.com/docs/guides/auth/quickstarts/react-native)
- [Expo Auth Docs](https://docs.expo.dev/develop/authentication/)
- [Clerk vs Supabase Comparison](https://medium.com/better-dev-nextjs-react/clerk-vs-supabase-auth-vs-nextauth-js-the-production-reality-nobody-tells-you-a4b8f0993e1b)
- [Authentication Comparison](https://blog.hyperknot.com/p/comparing-auth-providers)

---

**Status**: Production ready. Stop wasting time on auth. Build features.
