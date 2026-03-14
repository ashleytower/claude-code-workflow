# Team Debrief: Phase 1 Core - MTL Craft Cocktails AI

**Date:** 2026-02-06
**Team:** phase1-core (7 agents, 4 batches)
**Duration:** ~15 minutes total

## What Went Smoothly
- Tasks 1-3 parallelized cleanly (no shared files)
- Tasks 5-6 parallelized cleanly after Task 4
- Stripe SDK update (v17 -> v20.3.1) had no breaking changes
- All new endpoints created: /api/drafts/trigger, /api/claude, /api/cron/process-follow-ups
- Documentation cleanup complete -- no ElevenLabs refs remain in docs/env
- Notification voice tool wired end-to-end (bundle + executor + consumer)
- Build succeeds after all changes

## What Was Hard
- Claude proxy (Task 4) was the longest-running task -- service refactoring is always more complex
- VITE_ANTHROPIC_API_KEY exists in 6+ services beyond claudeService.ts -- plan only scoped one file

## Key Learnings
- [pattern] The project has many services that directly instantiate the Anthropic client with dangerouslyAllowBrowser. A single proxy endpoint doesn't fix all of them -- need a systematic migration.
- [gotcha] CalendarWidget tests have pre-existing locale-dependent failures ("PM" vs "p.m."). Not related to our changes.
- [pattern] Vercel cron pattern is consistent across all api/cron/ files -- CRON_SECRET auth header check.

## Unresolved
- 6 additional services still use VITE_ANTHROPIC_API_KEY directly in browser (security debt)
- dangerouslyAllowBrowser: true still in episodeSummaryService.ts
- 3 pre-existing CalendarWidget test failures (locale issue)
- VoiceToolContext.tsx and App.tsx handler wiring for checkNotifications should be manually verified

## Test Results
- 1428/1431 tests pass (97/114 files)
- 3 failures pre-existing in CalendarWidget.test.tsx
