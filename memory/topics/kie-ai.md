# Kie.ai Image Generation

### 2026-02-12 - Phase 2.5 Integration Complete
[pattern] Kie.ai API wrapper at `src/lib/imagery/generator.ts`. REST API at `https://api.kie.ai/v1/generate`. Auth: Bearer token via `KIE_API_KEY` env var. Response contains `image_url` field.

### 2026-02-12 - Model Selection
[decision] Flux Kontext for text-heavy and demo screenshots (best text rendering). GPT-4o Image for complex multi-object scenes (bookkeeping hook backgrounds). Default to Flux. See `src/lib/imagery/models.ts`.

### 2026-02-12 - Prompt Engineering Patterns
[pattern] Lead with image type + subject. Include style/mood/lighting. Always append negative prompt: "No text overlays, no watermarks, no AI artifacts, no distorted hands, no blurry faces". Style modifiers: ugc="shot on iPhone", minimal="studio lighting", product_shot="shallow depth of field".

### 2026-02-12 - Response Validation Required
[gotcha] Must validate `data.image_url` exists and is a string after API response. Kie.ai may return success without `image_url` on schema changes.

### 2026-02-12 - API Key Whitespace
[gotcha] Trim KIE_API_KEY with `.trim()` — whitespace-only keys pass falsy check but fail auth.

### 2026-02-13 - Kie.ai API v2 (async task-based)
[gotcha] The old endpoint `https://api.kie.ai/v1/generate` returns 404. The current API is async/task-based:
- Submit: `POST https://api.kie.ai/api/v1/flux/kontext/generate` → returns `{ data: { taskId } }`
- Poll: `GET https://api.kie.ai/api/v1/flux/kontext/record-info?taskId=xxx` → `successFlag: 0=processing, 1=done, 2/3=failed`
- Result field: `data.response.resultImageUrl` (14-day expiry) or `originImageUrl` (10-min expiry)
- GPT-4o images use `/api/v1/gpt4o-image/generate` and `/api/v1/gpt4o-image/record-info` (path changed from `/4o-image/` around Feb 2026)
- Typical generation: 15-25 seconds per image (6-8 poll attempts at 3s intervals)
- Images returned as JPEG even for Flux Kontext — save with .jpg extension, NOT .png

### 2026-02-13 - Remotion staticFile() required for local assets
[gotcha] Remotion's `<Img>` component cannot load files from `public/` using bare paths like `images/foo.jpg`. 
Must wrap with `staticFile()`: `<Img src={staticFile('images/foo.jpg')} />`. Without this, files 404 during `remotion render`.
Pattern: check if src starts with 'http', if not, wrap with `staticFile()`.

### 2026-02-15 - Veo 3.1 Video API requires model slug in body
[gotcha] Kie.ai video endpoints require a `model` field in the POST body. The slug format drops hyphens and dots:
- `veo-3.1` → `"model": "veo3"`
- Kling and Wan endpoints (`/api/v1/kling/`, `/api/v1/wan/`) return 404 as of Feb 2025 — may be deprecated.
- Generation takes ~100s per 6s video (33+ poll attempts at 3s intervals).

### 2026-02-15 - Veo response uses resultUrls array
[gotcha] Veo record-info returns `data.response.resultUrls` (string array) NOT `resultVideoUrl`. Must extract `resultUrls[0]`. Also includes `hasAudioList` array and `seeds` array. Updated `extractVideoUrl()` in video-generator.ts to handle both formats.

### 2026-02-18 - GPT-4o Image API breaking changes
[gotcha] Three changes from the old `/4o-image/` endpoint:
1. Path: `/api/v1/4o-image/` → `/api/v1/gpt4o-image/` (both generate and record-info)
2. Param: GPT-4o uses `size` (values: `1:1`, `3:2`, `2:3`) instead of `aspectRatio` (`9:16`, `16:9`)
3. Response: `data.response.resultUrls` (string array) instead of `resultImageUrl` (string). Use `resultUrls[0]`.

### 2026-02-18 - FAILURE: Prompt quality never researched, only API mechanics
[gotcha] Built the entire image generation pipeline — prompt-builder, prompt-enhancer, model selection, generator — without ever researching what prompts actually produce good images. All effort went into:
- API integration (endpoints, polling, auth)
- Personalization (Claude Haiku rewrites prompts for lead context)
- Model routing (Flux vs GPT-4o per scene type)

What was NEVER done:
- Research what prompt styles work for Flux Kontext vs GPT-4o Image
- Study what visual styles convert in short-form marketing video
- Look at what creators are actually doing on Reddit/X/YouTube
- Test and iterate on prompt quality before shipping

Result: "stock photo slop" — hyper-detailed photography descriptions ("Canon 5D Mark IV, 35mm f/1.4, tungsten lighting") that produce flat, depressing, uncanny valley images.

**Root cause**: Confused "building the plumbing" with "solving the problem." The plumbing works perfectly. The water tastes terrible.

**Fix pattern**: Any time a creative/generative feature is built, the FIRST step must be researching what good output looks like — not building the API integration. Research prompting best practices BEFORE writing prompt-builder code. Test 10+ prompts manually before automating.

**Also missed**: Should have considered AI video clips (Veo 3.1, Kling) as backgrounds instead of static images. Video backgrounds in a video product is obvious in hindsight.

### 2026-02-13 - Orchestrator props file naming affects output path
[gotcha] render-generic.ts uses `path.basename(propsFile, '.json')` as the output directory slug.
If the props file is named `.tmp-orchestrate-props-mike-crm.json`, the output goes to `leads/renders/.tmp-orchestrate-props-mike-crm/`.
Fix: write props to `leads/props/{leadSlug}.json` so the basename matches the desired output slug.
