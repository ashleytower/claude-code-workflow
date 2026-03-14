# Team Debrief: Red Wine Rush (2026-02-15)

## What went smoothly
- All 4 parallel tasks completed independently with zero conflicts
- BackgroundMedia wiring was straightforward -- props already existed in types
- Video prompt template upgrade went cleanly, all 15 existing tests still pass
- Lead JSON creation was trivial (matched existing format)

## What was hard
- `@remotion/rounded-text-box` API differs from docs/guesses: actual export is `createRoundedTextBox` (not `makeRoundedRect`), takes `textMeasurements: Dimensions[]` array, returns `{ d, boundingBox }` with viewBox property
- `@remotion/layout-utils` was already installed as transitive dep but not in package.json -- code reviewer caught this

## Key learnings
- [pattern] `createRoundedTextBox({ textMeasurements: [{ width, height }], textAlign, horizontalPadding, borderRadius })` returns `{ d: string, boundingBox: { viewBox, width, height } }`
- [gotcha] Always add transitive deps as explicit deps in package.json if importing directly
- [pattern] Template variable substitution in video prompts: use `{VAR}` placeholders, replace in `buildVideoPrompt()` with fallback defaults

## Unresolved
- RoundedCaption component is created but not yet wired into HookScene/DemoScene (plan Step 3 was create-only)
- Veo 3.1 video clip generation (plan Step 4) requires running `generateVideo()` with KIE_API_KEY -- not done in this session
- 3 pre-existing typecheck errors in heygen scripts, 4 pre-existing test failures (HeyGen, CrmDemo, CallToAction)
