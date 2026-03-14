### 2026-02-12 - Anthropic SDK + Remotion Zod peer dependency conflict
[gotcha] @anthropic-ai/sdk 0.74.0 requires zod >=3.x but Remotion 4.x pins zod to exactly 3.22.3.
Install with `--legacy-peer-deps` to avoid ERESOLVE error. The SDK works fine with 3.22.3 since
we don't use Zod schemas from the SDK directly.

### 2026-02-12 - Vitest mock pattern for Anthropic SDK
[pattern] Use a class-based mock for the Anthropic default export. The `vi.fn().mockImplementation`
pattern fails because Vitest hoists vi.mock and the mock factory arrow function is not a valid
constructor. Working pattern:
```ts
const createMock = vi.fn();
vi.mock('@anthropic-ai/sdk', () => ({
  default: class MockAnthropic {
    messages = { create: createMock };
  },
}));
```

### 2026-02-12 - ESLint 10 flat config needs typescript-eslint for .ts files
[gotcha] The default ESLint flat config with only `files: ['**/*.{ts,tsx}']` cannot parse TypeScript.
Must install `typescript-eslint` and spread `tseslint.configs.recommended` into the config array.

### 2026-02-12 - @testing-library/react requires @testing-library/dom
[gotcha] `@testing-library/react@16` does not auto-install `@testing-library/dom` as a dependency.
Must explicitly install `@testing-library/dom` as devDep or tests fail with "Cannot find module '@testing-library/dom'".

### 2026-02-12 - Remotion Tailwind v4 setup
[pattern] For Remotion 4.x + Tailwind v4: install `@remotion/tailwind-v4` + `tailwindcss` + `@tailwindcss/postcss`.
Config: `remotion.config.ts` uses `enableTailwind()` from `@remotion/tailwind-v4`.
Need `postcss.config.mjs` with `@tailwindcss/postcss` plugin. CSS file: `@import 'tailwindcss';`.
Add `"sideEffects": ["*.css"]` to package.json.

### 2026-02-12 - Vitest globals need tsconfig types entry
[gotcha] With `globals: true` in vitest config, TypeScript still needs `"types": ["vitest/globals"]`
in tsconfig.json to recognize `vi`, `describe`, `it`, `expect` etc. without explicit imports.

### 2026-02-12 - Session Progress
[decision] All 3 segment compositions complete: BookkeepingDemo, InventoryDemo, CrmDemo. Each has 4 scenes (Hook, Demo, Result, CTA) with optional background image URLs.

[pattern] CrmDemo uses purple (#a78bfa) accent color. BookkeepingDemo uses green (#22c55e). InventoryDemo uses amber (#f59e0b).

[decision] Sarah (bookkeeping lead) is the first complete end-to-end test case. 4 images generated via Nano Banana Pro and saved to public/images/leads/sarah/.

[gotcha] When adding new compositions, must register both Vertical and Horizontal variants in Root.tsx within a Folder component. Default props must match LeadPropsSchema.

### 2026-02-14 - Content Platform Architecture Complete
[decision] Content Generation Platform implemented with 6 content types: lead-response, event-promo, clip-compilation, ai-video, heygen-ugc, batch-landing. Entry point is CreativeBrief (CLI or JSON). Content Router dispatches to pipeline handlers via registry pattern.

### 2026-02-14 - generateScript needs skipVossValidation for non-lead content
[gotcha] The `generateScript()` function validates Voss mirroring by default (checks mirrorText contains exact painQuote). For non-lead content types (event-promo, clip-compilation, batch-landing), the "painQuote" is a synthesized description, not a real lead quote. Must pass `{ skipVossValidation: true, systemPrompt: PROMO_SCRIPT_SYSTEM_PROMPT }` as third argument to avoid runtime failures.

### 2026-02-14 - Parallel agent team worked cleanly
[pattern] 4 agents (CLI, Router, HeyGen, Video) ran in parallel on independent phases with zero merge conflicts. Key: each agent had a distinct set of files. Total: 462 tests across 45 files. Team pattern: create team, create tasks, spawn agents with team_name, agents self-report completion.

### 2026-02-15 - Enrichment segment mismatch with script templates
[gotcha] The enrichment module (`src/lib/enrichment/enrichment.ts`) accepts segments like `bar-service`, `syrups`, `workshops`, `activities` that have NO corresponding script templates in `src/lib/scripts/templates.ts` (only `bookkeeping`, `inventory`, `crm`). Fix: pass `Object.keys(SEGMENT_TEMPLATES)` as `validSegments` to `enrichLead()` in `createBundle()` so the LLM is constrained to segments with templates. Without this, a bartender post gets classified as `bar-service` instead of `inventory` and the pipeline crashes with "Unknown segment".

### 2026-02-15 - ContentBundleSchema strips social proof fields on re-load
[gotcha] The Zod schema `ContentBundleSchema` in `src/schemas/content-bundle.ts` did not include `socialProof`, `faq`, or `benefits` fields. When loading a bundle via `--bundle` flag, `safeParse()` silently strips unrecognized fields. This means if you create a bundle with social proof, then re-load it for another step (voiceover, landing), the social proof data is lost. Fix: added `SocialProofSchema`, `FaqItemSchema`, and `BenefitsSchema` as optional fields in the Zod schema.

### 2026-02-15 - Landing loadBundle path mismatch
[gotcha] `processLandingOutput` writes bundle JSON to `{landingDir}/data/{slug}.json`. The landing app's `loadBundle` was reading from `~/mirror-pipeline/leads/bundles/` by default. Fix: changed default `BUNDLES_DIR` in `mirror-landing/lib/load-bundle.ts` to `path.join(process.cwd(), "data")` so it reads from the local `data/` directory where `processLandingOutput` writes.

### 2026-02-15 - Run full pipeline in single command to preserve bundle fields
[pattern] Running `--outputs bundle,dm-caption,voiceover,video,landing` in a single command works best because the bundle object stays in memory with all fields intact. Running step-by-step with `--bundle` flag between steps causes the bundle to be re-loaded from disk through the Zod schema, which strips any fields not in the schema. If you must run step-by-step, make sure the schema includes all fields first.

### 2026-02-21 - HeyGen avatar retired + audio URL requirement
[gotcha] HeyGen default avatar `Angela-inTshirt-20220820` is RETIRED (404). Use `Brandon_Kitchen_Standing_Front_public` instead. Also, HeyGen audio_url must be a public HTTP URL — local file paths like `public/audio/foo.mp3` return 400. Upload to tmpfiles.org or use a CDN URL.

### 2026-02-21 - Stitch MCP stale project reference (FIXED)
[gotcha] Stitch MCP was returning "Project 'projects/5224881548932927504' not found or deleted" for all calls. Fixed by creating new project `16038115970111393225` ("Mirror Pipeline") and updating `STITCH_PROJECT_ID` in `~/.claude.json`. Requires Claude Code restart to take effect.

### 2026-02-21 - ElevenLabs vs Cartesia voice quality
[decision] User found all Cartesia voices "too fake" for UGC ads. ElevenLabs voices sound more natural. Preferred: Charlie (Australian male, ElevenLabs). Cartesia Liam (guy next door, slow speed) used as placeholder. ElevenLabs quota was 0 at time of testing.

### 2026-02-21 - UGC composition design iteration lessons
[pattern] For UGC ad compositions: (1) Use the full design system component library, not custom inline components. (2) Visual text must match voiceover exactly — mismatched items confuse viewers. (3) TikTok captions redundant when visual text already on screen. (4) Scrolling lists are distracting. (5) Keep it clean: color-graded backgrounds + text animations + waveform is enough.
