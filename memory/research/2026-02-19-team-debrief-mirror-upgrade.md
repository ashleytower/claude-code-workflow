# Team Debrief: mirror-upgrade (Design System Upgrade)
### 2026-02-19

## What went smoothly
- Design tokens foundation completed quickly, unblocked 4 parallel agents
- All 4 agents (layer-stack, kinetic-text, prompt-upgrade, broll) completed independently with zero conflicts
- TDD approach: 217 new tests, all passing
- Code simplifier caught 3 duplicated utilities (hexToRgba, adjustBrightness, FILL constant) across 5 files

## What was hard
- Session froze mid-implementation in the first attempt, losing all agent context
- Recovery required reading 8 research files + session state to reconstruct progress
- Handoff file kept getting overwritten by session hooks pointing to wrong project (max-ai-employee)
- Pre-existing registry.test.tsx failures (useCurrentFrame outside composition) caused confusion about whether new code introduced regressions

## Key learnings
[gotcha] GradientScrim: using raw hex color in CSS gradient middle stops creates a fully opaque band. Must convert to rgba with opacity applied via hexToRgba utility.
[gotcha] Pexels API rate limit: throwing on X-Ratelimit-Remaining=0 discards valid data. The response was successful - the header warns about the NEXT request. Use console.warn instead.
[pattern] Path traversal guard: always validate external API IDs before using in file paths, even when typed as number. Cast without runtime validation leaves the door open.
[pattern] Duplicate utilities emerge naturally when multiple agents work in parallel. Plan for a simplification pass.
[pattern] jsdom converts hex to rgb in gradient strings, and strips "to bottom" as default direction. Test assertions must account for this.

## Unresolved
- 5 pre-existing failures in tests/pipelines/ashley/registry.test.tsx (Remotion useCurrentFrame outside composition context)
- ImageSegment type is a wide string, not a union of known segment names - typos won't be caught at compile time
