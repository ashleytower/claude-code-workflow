# Team Debrief: Content Generation Platform

## Date: 2026-02-14

## Team
- Lead (Opus 4.6): Phase 0, Phase 6, Phase 7, coordination, critical fixes
- pipeline-agent (@backend): Phase 2 router + adapters, then ai-video + heygen-ugc handlers
- heygen-agent (@backend): Phase 3 HeyGen integration
- video-gen-agent (@backend): Phase 4 AI video generation
- cli-brief-agent (@frontend): Phase 1 CLI creative brief
- theme-agent (@frontend): Phase 5 theme system in mirror-landing
- docs-agent (@backend): CLAUDE.md + .env.example updates
- reviewer-agent (@code-reviewer): Two review passes

## What Went Smoothly
- Parallel agent execution: 4 agents ran simultaneously on Phases 1-4 with zero merge conflicts
- TDD approach: every agent wrote tests first, caught issues early
- Phase 0 foundation types enabled clean parallel work — all agents imported from the same types
- Total test count grew from ~350 to 477 across two sessions

## What Was Hard
- **generateScript Voss mirroring**: Non-lead content types (event-promo, clip-compilation, batch-landing) crashed because generateScript enforced Voss validation by default. Required adding skipVossValidation option.
- **buildVideoPrompt segment-locked**: The video prompt templates only had entries for bookkeeping/inventory/crm segments. ai-video pipeline would crash for any other productId. Fixed by using scene description directly.
- **avatarStyle vs avatarId**: CLI collected "avatar style preference" (e.g., "casual") but passed it as HeyGen `avatar_id` parameter which expects a literal ID like "Angela-inTshirt-20220820". Semantic mismatch caught in review.
- **Dynamic imports in create-brief.ts**: Agent used `await import('child_process')` unnecessarily inside functions where static imports were available at module scope.
- **Duplicate ContentTypeSchema**: Defined identically in both creative-brief.ts and content-bundle.ts Zod schemas. Fixed by exporting from creative-brief and importing in content-bundle.

## Key Learnings
- [pattern] For non-lead content types, always pass `{ systemPrompt: PROMO_SCRIPT_SYSTEM_PROMPT, skipVossValidation: true }` to generateScript
- [pattern] Use `registerAllPipelines()` from `src/lib/pipelines/register-all.ts` instead of duplicating registration in each script
- [gotcha] buildVideoPrompt in video-prompts.ts only works for segments with pre-defined templates (bookkeeping, inventory, crm). For user-provided scenes, use the description directly as the prompt.
- [gotcha] HeyGen avatarStyle is a UX concept, not an API parameter. Always use DEFAULT_AVATAR_ID unless user provides an actual avatar ID.
- [pattern] API keys should always be trimmed: `process.env.FOO?.trim()` — prevents auth failures from copy-paste whitespace.

## Unresolved
- Type drift between mirror-pipeline ContentBundle and mirror-landing ContentBundle (mirror-landing is missing several optional fields)
- No concurrency control on batch-landing pipeline — large persona x theme x variant combos could generate hundreds of sequential API calls
- intent-classifier keyword "scene" may misclassify event descriptions as ai-video
