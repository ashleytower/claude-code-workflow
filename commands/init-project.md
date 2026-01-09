---
name: init-project
description: Generate project CLAUDE.md by exploring codebase
---

# Init Project

Explore the codebase and generate a project-specific CLAUDE.md.

Works for both **new projects** and **existing codebases**.

## Usage

```bash
/init-project           # Explore and generate CLAUDE.md
/init-project --force   # Overwrite existing CLAUDE.md
```

## Process

### Step 1: Check What Exists

**New project (empty/minimal)?**
- Ask what you're building
- Ask about planned tech stack
- Generate starter CLAUDE.md

**Existing project (has code)?**
- Explore the codebase first
- Read package.json, requirements.txt, etc.
- Detect what's actually there

### Step 2: Explore (Existing Projects)

Read these files to understand the project:

```bash
# Package manager files
cat package.json
cat requirements.txt
cat pyproject.toml

# Existing docs
cat README.md
cat .env.example

# Directory structure
ls -la src/ app/ lib/ components/ pages/ api/ server/
```

### Step 3: Detect Tech Stack

From dependencies, identify:
- **Framework**: Next.js, React Native, FastAPI, etc.
- **Database**: Supabase, Prisma, Drizzle, etc.
- **Auth**: Clerk, Supabase Auth, NextAuth, etc.
- **UI**: Tailwind, shadcn, etc.
- **Integrations**: Stripe, Resend, etc.

### Step 4: Generate CLAUDE.md

```markdown
# [Project Name]

## Tech Stack
- **Framework**: [detected or planned]
- **Database**: [detected or planned]
- **Auth**: [detected or planned]
- **UI**: [detected or planned]

## Structure
```
[actual directory structure]
```

## Key Files
- `src/app/` - [description]
- `src/lib/` - [description]

## Environment Variables
[from .env.example or ask user]

## Patterns
[ask user or leave for them to fill]

## Known Issues
[empty - add when Claude makes mistakes]
```

### Step 5: Confirm

Show the generated CLAUDE.md and ask:
- Is this accurate?
- Anything to add or change?
- Any patterns I should know about?

## Examples

**New Next.js project:**
```
User: /init-project
Claude: I see this is a new/empty project. What are you building?
User: A SaaS app with Supabase and Stripe
Claude: [Generates CLAUDE.md with Next.js + Supabase + Stripe]
```

**Existing React Native app:**
```
User: /init-project
Claude: [Reads package.json, explores src/]
Claude: I found:
- React Native with Expo SDK 52
- Supabase for auth and database
- React Navigation
- [Shows generated CLAUDE.md]
Is this accurate?
```

## Output

Creates `./CLAUDE.md` in the project root.

After this, run `/guide` to start building.
