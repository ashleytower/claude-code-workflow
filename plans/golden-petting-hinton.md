# Mirror Pipeline — Phase 2.5: Kie.ai Image/Video Generation + Marketing Creative Integration

## Context

Phase 1 (Remotion compositions) and Phase 2 (enrichment + scripts) are complete and rendering videos. The current compositions use placeholder visuals (colored boxes, animated text). This phase replaces placeholders with AI-generated images and video clips via **Kie.ai** — an API aggregator that provides access to Flux, Nano Banana, GPT-4o Image, Veo 3.1, and more through a single API.

The goal: generate marketing-quality product demo images, background visuals, and optionally short video clips that make the rendered videos look professional and authentic (not "AI-looking").

## Research Summary

### Kie.ai Platform
- **URL**: https://kie.ai/ | **Docs**: https://docs.kie.ai/
- **API**: REST, unified format across all models — swap models by changing one parameter
- **Auth**: API key in request headers
- **MCP Server**: `@felores/kie-ai-mcp-server` (npm, v2.0.10)

### Available Models (via Kie.ai)
| Model | Type | Best For |
|-------|------|----------|
| **Flux.1 Kontext** | Image | Text-heavy ads, product shots, editing |
| **GPT-4o Image** | Image | Complex scenes, perfect text rendering |
| **Nano Banana** | Image | Character consistency, iterative editing |
| **Grok Imagine** | Image+Video | Flexible formats, detailed scenes |
| **Veo 3.1** | Video | Marketing video clips with audio sync |
| **Wan 2.5** | Video | Cinematic clips with audio |
| **Kling 2.1** | Video | Realistic motion, 1080p |

### What Works in Marketing (Research Findings)
- UGC-style ads get 7x more clicks than polished brand content
- AI ads that don't look like AI significantly outperform both human-made and obviously-AI ads
- Flux is the best model for text-heavy marketing images (clean text rendering)
- GPT-4o handles complex multi-object scenes best
- Key: authenticity > polish. Keep it real, not corporate.

### Skills to Install
| Skill | Source | Purpose |
|-------|--------|---------|
| `skill-zero/s@prompt-engineering` | GitHub | AI image/video prompt patterns |
| `cdeistopened/opened-vault@meta-ads-creative` | GitHub | Meta ad creative specs |
| `dennisonbertram/claude-media-skills@realistic-ugc-video` | GitHub | UGC-style video creation |

### Existing Skills (Already Installed, Relevant)
- `paid-ads` — Creative testing hierarchy, video ad structure (Hook 0-3s, Problem 3-8s, Solution 8-20s, CTA 20-30s)
- `social-content` — Platform-specific content guidance, hook formulas
- `marketing-psychology` — 70+ mental models for ad design decisions

---

## Implementation Plan

### Step 1: Install Kie.ai MCP Server + Skills

- Install MCP: `npm i @felores/kie-ai-mcp-server` (or configure as MCP server in Claude Code settings)
- Install skills:
  - `npx skills add skill-zero/s@prompt-engineering --yes --ide claude`
  - `npx skills add cdeistopened/opened-vault@meta-ads-creative --yes --ide claude`
  - `npx skills add dennisonbertram/claude-media-skills@realistic-ugc-video --yes --ide claude`
- Add `KIE_API_KEY` to `.env`
- Update `CLAUDE.md` with Kie.ai integration notes

### Step 2: Image Generation Module (TDD)

**Files:**
- `src/lib/imagery/types.ts` — ImageAsset, ImagePrompt, GenerationConfig types
- `src/lib/imagery/prompts.ts` — Per-segment prompt templates for product demo images
- `src/lib/imagery/generator.ts` — Kie.ai API wrapper: generateImage()
- `src/lib/imagery/models.ts` — Model selection logic (Flux for text, GPT-4o for scenes)
- `tests/lib/imagery.test.ts` — Tests with mocked Kie.ai API

**ImagePrompt type:**
```ts
type ImagePrompt = {
  segment: 'bookkeeping' | 'inventory' | 'crm';
  scene: 'hook_background' | 'demo_screenshot' | 'result_background' | 'cta_background';
  leadContext: {
    currentTool: string;
    painQuote: string;
  };
  style: 'ugc' | 'minimal' | 'product_shot';
  aspectRatio: '9:16' | '16:9' | '1:1';
};
```

**Per-segment prompts (examples):**
- Bookkeeping demo_screenshot: "Overhead photo of a messy desk with scattered paper receipts, a phone showing a camera app, and a laptop with a Google Sheet. Natural lighting, slightly cluttered, authentic home office feel. No text overlays."
- Inventory demo_screenshot: "Close-up of a bartender's hand near a phone, bar shelf with bottles visible in background, warm amber lighting, slightly blurred depth of field. Casual, authentic feel."
- CRM demo_screenshot: "Split screen style: phone showing a voice waveform on left, email being sent on right. Clean modern UI, warm neutral tones."

**Model selection logic:**
- Text in image needed → Flux.1 Kontext
- Complex multi-object scene → GPT-4o Image
- Character/person consistency → Nano Banana
- Quick iteration/editing → Nano Banana
- Default → Flux.1 Kontext (best overall for marketing)

### Step 3: Prompt Engineering System

**File:** `src/lib/imagery/prompt-builder.ts`

A prompt builder that encodes best practices from research:
- Lead with image type and subject (AI prioritizes first words)
- Include: subject, style, mood, lighting, constraints
- Add negative prompts: "No text overlays, no watermarks, no AI artifacts"
- Specify aspect ratio for target platform
- Style modifiers based on `style` param:
  - `ugc`: "shot on iPhone, natural lighting, slightly imperfect, authentic feel"
  - `minimal`: "clean white background, studio lighting, professional product photography"
  - `product_shot`: "soft diffused daylight, shallow depth of field, warm tones"

### Step 4: Integrate Generated Images into Compositions

**Modify existing compositions:**
- Update `LeadPropsSchema` to accept optional image URLs:
  ```ts
  hookBackgroundUrl: z.string().optional(),
  demoScreenshotUrl: z.string().optional(),
  resultBackgroundUrl: z.string().optional(),
  ```
- Update DemoScene components to render actual images (via `<Img>` from Remotion) when URL provided, fall back to current placeholder when not
- Update HookScene to optionally use a background image
- Images loaded via `staticFile()` (downloaded to `public/` first) or remote URL

### Step 5: Terminal-Driven Workflow (Claude Code on Max Plan)

Image generation runs through Claude Code in this terminal — same pattern as enrichment. No API calls in the codebase. The workflow:

1. You give me a lead (or I read from `leads/input/`)
2. I enrich the lead (extract pain quote, segment, etc.)
3. I craft image prompts using the prompt builder patterns
4. I call Kie.ai via MCP tools (`@felores/kie-ai-mcp-server`) from this terminal
5. You review each generated image — approve or request changes
6. I download approved images to `public/images/leads/{lead-slug}/`
7. I update the props JSON with local image paths
8. `npm run pipeline` renders the video with real images

**No code changes to `scripts/render-lead.ts`** — it already reads image URLs from props. We just populate those fields before rendering.

**New convenience script: `scripts/download-image.ts`:**
- Takes a URL and lead slug, downloads to correct public/ path
- Returns the `staticFile()` path for props JSON

### Step 6: Marketing Creative Documentation

**File:** `src/lib/imagery/PROMPTING_GUIDE.md`

Document what works and what doesn't, updated as we iterate:
- Model comparison results for each scene type
- Prompt patterns that produced best results
- Common failures and fixes
- Performance notes (generation time, cost per image)

This becomes the team's living reference for AI image generation.

---

## Agent Team Structure

1. **Backend Agent** (`@backend`): Prompt builder module + image types + download utility + tests
2. **Frontend Agent** (`@frontend`): Composition updates to accept/render images + schema updates
3. Run in parallel
4. After both: `@code-reviewer` → `@code-simplifier` → `/verify-app`
5. Then: **Manual test** — I generate images for Sarah via Kie.ai MCP, render video with real images

## TDD Approach

For each module:
1. Write failing test (mock Kie.ai API responses)
2. Implement minimum to pass
3. `npm run ci`
4. Loop until green

## Verification Checklist

1. `npm run ci` passes (typecheck + test + lint + build)
2. Image generation module returns valid image URLs from mocked Kie.ai
3. Prompt builder generates correct prompts for each segment + scene combination
4. Model selection picks Flux for text-heavy, GPT-4o for complex scenes
5. Compositions render with placeholder images (no regression)
6. Compositions render with provided image URLs
7. `scripts/download-image.ts` downloads and saves to correct path
8. Props with image URLs render correctly (images visible in video)
9. Updated LeadPropsSchema validates with and without image URLs
10. End-to-end: generate Sarah's images via Kie.ai MCP → download → render → watch video

## Commit Strategy

- Commit 1: "Add Kie.ai image generation module with prompt builder and tests"
- Commit 2: "Update compositions to render AI-generated images with fallback"
- Commit 3: "Add image generation CLI and pipeline integration"

## Critical Files to Modify

- `/Users/ashleytower/Documents/GitHub/mirror-pipeline/src/schemas/lead.ts` — add image URL fields
- `/Users/ashleytower/Documents/GitHub/mirror-pipeline/src/compositions/BookkeepingDemo/DemoScene.tsx` — render images
- `/Users/ashleytower/Documents/GitHub/mirror-pipeline/src/compositions/InventoryDemo/DemoScene.tsx` — render images
- `/Users/ashleytower/Documents/GitHub/mirror-pipeline/src/compositions/BookkeepingDemo/HookScene.tsx` (via shared) — optional background
- `/Users/ashleytower/Documents/GitHub/mirror-pipeline/scripts/render-lead.ts` — add --generate-images flag
- `/Users/ashleytower/Documents/GitHub/mirror-pipeline/.env` — add KIE_API_KEY
- `/Users/ashleytower/Documents/GitHub/mirror-pipeline/CLAUDE.md` — add Kie.ai rules
