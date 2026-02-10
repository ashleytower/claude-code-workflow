---
name: claude-optimised
description: Guide for optimizing CLAUDE.md files. Use when creating, reviewing, or auditing CLAUDE.md files.
---

# CLAUDE.md Optimization Guide

## Core Principle
Long CLAUDE.md = Claude ignores half of it. Target under 50 lines.

**For each line ask:** "Would removing this cause Claude to make mistakes?"
- If no → delete it
- If Claude already does it → delete it

## What to Include

| Section | Example |
|---------|---------|
| Project context | "Next.js e-commerce with Stripe" (1 line) |
| Build/test commands | `npm test`, `npm run build` |
| Critical gotchas | "Never modify auth.ts directly" |
| Non-obvious conventions | "Use `vi` for state, not `useState`" |

## Do NOT Include
- Things Claude already knows (general coding practices)
- Obvious patterns (detectable from existing code)
- Lengthy explanations (be terse)
- Aspirational rules (only real problems you've hit)

## File Placement

| Location | Scope |
|----------|-------|
| `~/.claude/CLAUDE.md` | All sessions (universal rules) |
| `./CLAUDE.md` | Project-specific only |

**Key:** No duplication between global and project files.

## Optimization Checklist
- [ ] Under 50 lines?
- [ ] Every line solves a real problem?
- [ ] No redundancy with global CLAUDE.md?
- [ ] No instructions Claude follows by default?

## Anti-Patterns
- 200+ line files (gets ignored)
- Duplicate rules across files
- "Write clean code" (Claude knows this)
- Long prose (use bullet points)
