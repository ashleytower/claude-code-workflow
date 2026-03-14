# Team Debrief: Mirror Pipeline Phase 1 + Phase 2
**Date**: 2026-02-12
**Team**: mirror-pipeline (4 agents: phase1-frontend, phase2-backend, code-reviewer, code-simplifier, verify-app)

## What Went Smoothly
- Parallel execution of Phase 1 (Remotion) and Phase 2 (Claude API) worked perfectly — no merge conflicts
- TDD approach caught no regressions — all 46 tests passed from first CI run after both phases merged
- Code reviewer only found 2 minor issues (type tightening, frame number convention)
- Code simplifier cleanly extracted shared HookScene and CtaScene components
- All 13 verification checks passed on first run

## What Was Hard
- **Zod version conflict**: Remotion pins zod@3.22.3, Anthropic SDK wants >=3.25. Required `.npmrc` with `legacy-peer-deps=true`. No functional issue but unexpected.
- **ESLint TypeScript parsing**: Remotion scaffold's default ESLint config had no TypeScript parser. Had to add `typescript-eslint` as dev dep.
- **@testing-library/dom missing**: @testing-library/react@16 doesn't auto-install @testing-library/dom. Needed explicit devDep.
- **Vitest globals typing**: Required `"types": ["vitest/globals"]` in tsconfig.json for `describe`/`it`/`expect` to be recognized.
- **Anthropic SDK mocking**: vi.mock needs class-based mock pattern for the SDK (constructor, not function).

## Key Learnings
- [pattern] Remotion + Anthropic SDK coexist fine with legacy-peer-deps despite Zod version mismatch
- [pattern] Shared scenes (HookScene, CtaScene) are identical across compositions — extract early
- [pattern] For Remotion TDD: mock useCurrentFrame/useVideoConfig/spring from 'remotion' module
- [gotcha] Remotion spring() returns 0-1 range — no need to manually clamp
- [gotcha] Remotion rule #4 (timing in seconds * fps) is easy to miss — code reviewer caught hardcoded frame numbers

## Unresolved
- ProductDemo component exists but is unused until Phase 5 (render pipeline)
- `scaleIn` and `slideUp` animation helpers exist but are unused in current compositions (kept for future use)
- Remotion Studio visual verification not automated (would need screenshots/Playwright)

## Stats
- **Files created**: ~35 source files + 12 test files
- **Tests**: 46 passing across 11 suites
- **CI time**: ~5 seconds total (typecheck + test + lint + build)
- **Agent time**: ~8 minutes wall clock for full pipeline
