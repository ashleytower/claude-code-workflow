### 2026-02-06 - Phase 3 Learning System Integration Debrief

## What went smoothly
- Voice pipeline behavior injection (Task 1): Clean implementation, 10 tests written and passed
- Migration creation (Task 2): Straightforward ALTER TABLE
- Draft client context (Task 3): Gap identified quickly, small fix in draftService.ts
- Confidence promotion (Task 4): reinforce/decay methods implemented cleanly with floating point safety

## What was hard
- [gotcha] Migration numbered 032 when last was 029 -- fixed to 030
- [gotcha] `getBehaviorsForClient` did NOT filter out deactivated behaviors (active: false in JSONB). Fixed post-review by adding `.filter(d => d.value?.active !== false)`. Without this fix, `decayBehavior` would mark things inactive but they'd still appear in prompts.
- [decision] reinforcement_count stored in JSONB `value` field, not in the top-level column added by migration. Minor inconsistency but functional.

## Key learnings
- [pattern] Voice pipeline uses bracket delimiters `[LEARNED BEHAVIORS]...[USER MESSAGE]` for behavior injection, while claudeService uses `=== LEARNED BEHAVIORS ===` in system prompt. Different injection points, different formats.
- [pattern] `draftService.ts` regeneration path was missing client context params that `useEmailActions.ts` already had. Two call sites for same function = easy to miss one.
- [pattern] TDD worked well with 2 parallel agents. 22 total new tests, all passing.

## Unresolved
- `reinforceBehavior`/`decayBehavior` are implemented and tested but NOT wired into `draftLearningService.ts` correction flow. Need follow-up to: (1) call `reinforceBehavior` when correction matches existing behavior, (2) call `decayBehavior` when user overrides a learned behavior.
- Migration top-level `reinforcement_count` column unused -- code stores count in JSONB instead.

## Files changed
- `services/claudeVoicePipeline.ts` - behavior injection before Claude calls
- `services/behaviorInjectionService.ts` - reinforce/decay methods + deactivation filter
- `services/draftService.ts` - client context in regeneration path
- `supabase_migrations/030_confidence_history.sql` - reinforcement_count column
- `tests/services/claudeVoicePipelineBehaviors.test.ts` (new, 10 tests)
- `tests/services/draftLearningClientContext.test.ts` (new, 4 tests)
- `tests/services/confidencePromotion.test.ts` (new, 8 tests)
- `tests/services/claudeVoicePipeline.test.ts` (updated)
