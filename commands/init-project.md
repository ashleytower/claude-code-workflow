---
name: init-project
description: Generate project CLAUDE.md by exploring codebase
---

# Init Project

Explore the codebase and generate a project-specific CLAUDE.md.

## Process

### Step 1: Detect Project Type

Check for project markers:
- `package.json` → Node.js / React / Next.js
- `requirements.txt` or `pyproject.toml` → Python
- `Cargo.toml` → Rust
- `go.mod` → Go
- `pubspec.yaml` → Flutter/Dart

### Step 2: Read Dependencies

From package.json or equivalent, identify:
- Framework (Next.js, React Native, FastAPI, etc.)
- Database (Supabase, Prisma, Drizzle, etc.)
- Auth (Clerk, Supabase Auth, NextAuth, etc.)
- UI library (Tailwind, shadcn, etc.)
- Key integrations (Stripe, Resend, etc.)

### Step 3: Explore Structure

Find key directories:
```bash
# Common patterns
ls -la src/ app/ lib/ components/ pages/ api/ server/ 2>/dev/null
```

### Step 4: Check Existing Docs

Look for:
- Existing CLAUDE.md
- README.md
- PRD.md
- .env.example (for required env vars)

### Step 5: Generate CLAUDE.md

Create project CLAUDE.md with discovered info:

```markdown
# [Project Name from package.json]

## Tech Stack
- **Framework**: [detected]
- **Database**: [detected]
- **Auth**: [detected]
- **UI**: [detected]

## Structure
```
[discovered directory structure]
```

## Key Files
- [important files discovered]

## Environment Variables
- [from .env.example]

## Patterns
- [leave empty for user to fill]

## Known Issues
- [leave empty - add when Claude makes mistakes]
```

### Step 6: Confirm with User

Show generated CLAUDE.md and ask:
- Is this accurate?
- Anything to add?
- Any specific patterns to document?

## Output

Creates `./CLAUDE.md` in the project root.

## Usage

```bash
/init-project
# Explores codebase and generates CLAUDE.md

/init-project --force
# Overwrites existing CLAUDE.md
```
