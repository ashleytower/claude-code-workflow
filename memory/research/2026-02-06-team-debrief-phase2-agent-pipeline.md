### 2026-02-06 - Phase 2: Agent Pipeline Team Debrief

## What Went Smoothly
- All 4 Batch 1 tasks ran fully in parallel with no file conflicts
- Voice teaching enhancement (Task 2) finished first, clean 24/24 tests
- Validation loop (Task 1) wired correctly with non-blocking fallthrough
- Bundle splitting (Task 3) created 7 bundles all within 15-tool limit
- DB migration (Task 5) trivial, done by lead while waiting

## What Was Hard
- [gotcha] backend-tests found that `verifyAction` in actionLogService has a regex bug: `/send|sent|email|quote|invoice|proposal|calendar|schedule|draft|to|the|a|for|about/gi` strips all "a" characters from client names (e.g., "Sarah" -> "Srh"). Tests worked around it but the bug should be fixed separately.
- [gotcha] Test suite has 18 files that fail at file level due to missing Supabase env vars -- pre-existing, not from phase 2.
- [gotcha] 3 CalendarWidget tests fail due to locale-sensitive time formatting ("2:00 p.m." vs "2:00 PM") -- pre-existing.

## Key Learnings
- [pattern] `vi.hoisted()` required in Vitest 4 for mock variables used in `vi.mock` factories
- [pattern] For non-blocking validation, catch at the wrapper level and fall through -- don't let validator errors break the main draft flow
- [pattern] When splitting bundles, keep old files marked @deprecated rather than deleting -- avoids breaking any direct imports elsewhere
- [decision] Voice teaching uses dynamic import for identityResolutionService to avoid circular dependency

## Unresolved
- verifyAction regex bug (strips "a" from names) -- needs separate fix
- Pre-existing test failures (CalendarWidget locale, env-dependent files)
- Migration 028 needs to be applied to production Supabase
