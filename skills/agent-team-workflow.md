---
name: agent-team-workflow
description: Activate the full agent team workflow for non-trivial implementation tasks. Use when starting any feature, bug fix, or refactor that involves more than a single file change. Runs: Plan -> TDD -> Implement (with team) -> @code-reviewer -> @code-simplifier -> /verify-app -> /commit-push-pr.
---

# Agent Team Workflow

Every non-trivial task uses an agent team. No solo implementation.

## When to Use

- Any feature, bug fix, or refactor touching 2+ files
- Any change with user-facing behavior
- Any database or API change
- Skip only for: config tweaks, docs, single-line fixes

## Pipeline

```
Plan -> Document -> TDD -> Implement -> @code-reviewer -> @code-simplifier -> /verify-app -> /commit-push-pr
```

## Required Roles

| Role | Agent | Responsibility |
|------|-------|---------------|
| Implementer | `@frontend` / `@backend` / general | Build the feature |
| Reviewer | `@code-reviewer` | Review every changeset |
| Build Validator | `@verify-app` | Run full CI |
| Simplifier | `@code-simplifier` | Post-implementation cleanup |

## TDD Rules

- New features: write failing test FIRST, then implement
- Bug fixes: write regression test that reproduces the bug BEFORE fixing
- Refactoring: run full CI after every step

## Verification Checklist

Before marking ANY task complete:

1. Type check passes (`npm run typecheck`)
2. Tests pass (`npm test`)
3. Lint passes (`npm run lint`)
4. Build passes (`npm run build`)
5. UI manually verified (if UI changed)
6. Security reviewed (no XSS, injection, credentials)
7. Voice-first check (new features have voice commands)
8. Documentation updated

Quick CI: `npm run ci` (runs all four automated checks)

## Parallel Agents

For independent tasks, use the `dispatching-parallel-agents` skill instead of serializing work.

## Feedback Loop

If verification fails: fix -> re-verify -> loop until green. Never mark complete while CI is failing.

## Integration

- `Skill(tdd)` — test-first workflow detail
- `Skill(nexus-sprint)` — for 2-6 week feature builds
- `Skill(nexus-micro)` — for 1-5 day bug fixes and small tasks
- `Skill(nexus-code-review)` — full multi-agent review pipeline
- `Skill(verify-app)` — CI verification
- `Skill(commit-push-pr)` — commit and PR creation

## Eval

**Trigger**: "Build the trip details screen with Supabase integration"

**Expected behavior**: Agent activates @frontend implementer, writes failing tests first, implements, hands off to @code-reviewer, runs @code-simplifier, then runs /verify-app before /commit-push-pr. Does not mark complete until all 8 checklist items pass.
