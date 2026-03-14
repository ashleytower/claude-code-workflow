# Team Debrief: Multi-Output Content Engine

## Date: 2026-02-13
## Team: content-engine (team-lead + landing-builder + shortform-builder + clip-builder + text-builder)

## What went smoothly
- All 4 parallel agents completed with zero file conflicts -- clear file boundaries prevented all merge issues
- Phase 1 (ContentBundle + Orchestrator) was quick to implement as team-lead, unblocking all agents
- Landing page agent bootstrapped a full Next.js 16 project from scratch in one pass
- Text output (Phase 5) was the quickest win -- pure extraction, no AI calls
- Final count: 224 tests across 30 files, all passing

## What was hard
- **`<Video>` from `@remotion/media` doesn't support `startFrom`/`endAt`**: Clip-builder initially used these props, causing a typecheck error. The `<Video>` component from `@remotion/media` differs from core Remotion's `<OffthreadVideo>`. Trim must be done via `<Sequence>` wrapping, not on the `<Video>` tag itself.
- **Next.js 16 breaking changes**: `params` in page components are now Promises and must be awaited. `create-next-app` now prompts for React Compiler (needs stdin workaround).
- **Tailwind 4 in Next.js**: Uses `@theme inline` blocks in CSS instead of `tailwind.config.ts`. Different from Remotion's `@remotion/tailwind-v4` approach.
- **Command injection risk**: Code reviewer caught that `execSync` with string interpolation passes unsanitized `productConfig.id` to shell. Fixed with `execFileSync` (no shell invocation) + strict regex validation.

## Key learnings
- [gotcha] `<Video>` from `@remotion/media` has no `startFrom`/`endAt` props. Use `<Sequence from={} durationInFrames={}>` to wrap for trimming.
- [pattern] Use `execFileSync` instead of `execSync` when arguments come from user data. `execFileSync` does not invoke a shell, preventing injection.
- [pattern] Validate user-controlled strings that flow into file paths with strict regex: `/^[a-z0-9][a-z0-9-]*$/`
- [gotcha] Next.js 16 page params are async: `const { slug } = await params;`
- [pattern] Two projects sharing data via JSON contract (ContentBundle) works well. No monorepo complexity, no dependency conflicts.
- [decision] `<video autoplay muted loop playsinline>` is better than `@remotion/player` for landing pages -- zero JS, loads fast, works everywhere.

## Unresolved
- Orchestrator `landing` output is informational-only (tells user to run build manually). Full automation would require shelling out to the mirror-landing project.
- `clip-comp` output requires a separate clips config JSON; cannot auto-generate from ContentBundle.
- Landing page `DemoSection` uses hardcoded segment features rather than reading `demoContent` from the bundle's productConfig. Future enhancement.
- ContentBundle type is duplicated (simplified) in mirror-landing. A shared types package would reduce drift risk.
