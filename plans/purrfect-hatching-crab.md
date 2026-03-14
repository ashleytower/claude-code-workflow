# Plan: Multi-Output Content Engine

## Context

The dual-mode mirror pipeline is complete (Ashley + Generic, 158 tests, shipped). Currently the pipeline has one output: MP4 video. Ashley wants the same enriched lead data to produce multiple output formats — video, landing pages, YouTube Shorts, TikToks, clip compilations, DMs, ad creatives. The AI enrichment (Claude Haiku + Sonnet, ~$0.04/lead) is the expensive step. Rendering to any format is cheap and mechanical. Do the AI work once, render many.

**User's vision**: "I can say build the UGC or the DM version, or something to post as an ad. We can build a whole quick landing page catered to somebody. And Remotion gets played in there too."

## Architecture

### Core Concept: ContentBundle

A single JSON file per lead that captures ALL enrichment outputs. Every output renderer reads from this bundle.

```typescript
// src/types/content-bundle.ts
type ContentBundle = {
  version: 1;
  generatedAt: string;
  leadSlug: string;
  pipeline: 'ashley' | 'generic';
  segment: string;

  // AI outputs (expensive step, run once)
  rawInput: RawLeadInput;
  enrichedLead: EnrichedLead;
  script: Script;
  productConfig?: ProductConfig;   // generic pipeline only

  // Generated assets (populated incrementally)
  assets: {
    voiceoverUrl?: string;
    images: Partial<Record<ImageScene, ImageAsset>>;
    videoVertical?: string;        // path to rendered MP4
    videoHorizontal?: string;
  };

  // Output tracking
  outputs: {
    video?: { vertical?: string; horizontal?: string };
    landing?: { slug: string; url?: string };
    shortForm?: Record<string, string>;  // duration → path
    clipCompilation?: string;
    dmCaption?: { hook: string; full: string };
  };
};
```

### Data Flow

```
RawLeadInput
  │
  ▼ enrichment.ts (Claude Haiku)
EnrichedLead + Script (Claude Sonnet) + ImageAssets (Kie.ai)
  │
  ▼ writes to disk
ContentBundle JSON  ──────────────────────────────────────┐
  │                                                        │
  ├─→ [video]           Remotion render → MP4              │
  ├─→ [short-form]      Remotion ShortForm → MP4 (15/30s) │
  ├─→ [clip-comp]       Remotion ClipComp → MP4            │
  ├─→ [landing]         Next.js static page → HTML/Vercel  │
  ├─→ [dm-caption]      Text extraction → .txt             │
  └─→ [ad]              Future: static image or video crop  │
```

### Two Projects, Shared Data

Keep the Remotion project and the Next.js landing page project **separate**. No monorepo needed. They share data via ContentBundle JSON files on disk.

```
~/mirror-pipeline/           # Remotion project (existing)
  leads/bundles/             # ContentBundle JSON files (shared data)
  leads/renders/             # Rendered MP4s

~/mirror-landing/            # Next.js project (new)
  reads from ~/mirror-pipeline/leads/bundles/
  embeds pre-rendered video as <video> tag (not @remotion/player)
  deploys to Vercel as static site
```

**Why separate, not monorepo**: Remotion uses Webpack internally. Next.js uses its own bundler. Mixing them in a monorepo creates dependency conflicts (React version, Tailwind version, build tooling). Two projects with a JSON contract is simpler for a solo operator. The orchestrator script in mirror-pipeline shells out to both.

**Why `<video>` tag, not `@remotion/player`**: The Player requires importing all Remotion composition code into the Next.js bundle (200KB+ JS, React version alignment, Webpack compatibility). A pre-rendered MP4 embedded as `<video autoplay muted loop playsinline>` is zero-JS, loads fast, works everywhere. The orchestrator renders the video first, then generates the landing page.

## Phase 1: ContentBundle + Orchestrator

**Goal**: Single CLI entry point that enriches once, writes a bundle, and dispatches to output renderers.

### Create

**`src/types/content-bundle.ts`** — ContentBundle type definition
**`src/schemas/content-bundle.ts`** — Zod schema for validation
**`scripts/orchestrate.ts`** — Unified pipeline entry point

```bash
# Enrich + render video
npx tsx scripts/orchestrate.ts --input leads/input/sarah.json --outputs video

# Enrich + multiple outputs
npx tsx scripts/orchestrate.ts --input leads/input/sarah.json --outputs video,landing,short-form

# From existing bundle (skip enrichment)
npx tsx scripts/orchestrate.ts --bundle leads/bundles/sarah-bookkeeping.json --outputs landing

# Generic pipeline
npx tsx scripts/orchestrate.ts --input leads/input/sarah.json --config src/pipelines/generic/config/example-saas.json --outputs video,landing

# Batch
npx tsx scripts/orchestrate.ts --input-dir leads/input/ --outputs video
```

Orchestrator flow:
1. Parse CLI args (input, outputs, optional product config)
2. If no bundle: run `enrichLead()` → `generateScript()` → optionally `generateImage()` / TTS → write bundle
3. For each output: dispatch to renderer function
4. Update bundle with output paths, write back

**`tests/orchestrate.test.ts`** — Unit tests with mocked AI calls

### Modify

**`scripts/render-lead.ts`** — Add `--from-bundle` flag that reads ContentBundle instead of raw props
**`scripts/render-generic.ts`** — Same `--from-bundle` flag
**`leads/bundles/`** — New directory for bundle JSON files

## Phase 2: Landing Page Project

**Goal**: Personalized landing page per lead using adapted Aceternity template, deployed to Vercel.

### New project: `~/mirror-landing/`

Initialize from the Aceternity template at `~/mcc-landing-page/aceternity-ui/`, then adapt components to be data-driven from ContentBundle.

**Tech stack**: Next.js 15 (latest), React 19, Tailwind CSS 4, Framer Motion 11+, TypeScript 5.x. Upgrade from Aceternity's React 18 / Tailwind 3 / Framer Motion 10.

### Component mapping (video scene to page section)

| Video Scene | Page Section | Aceternity Base | ContentBundle Source |
|---|---|---|---|
| HookScene | Hero | `Hero.tsx` | `script.hookText`, `enrichedLead.painQuote` |
| Mirror text | Mirror section | New | `script.mirrorText` (Voss mirror) |
| Bridge | Transition | New | `script.bridgeText` |
| DemoScene | Features/Demo | `SubHero.tsx` | `productConfig.demoContent` or segment features |
| ResultScene | Results | `Testimonials.tsx` adapted | `script.resultText`, `productConfig.resultHeadline` |
| Video embed | Video section | New | `<video>` with pre-rendered MP4 |
| CtaScene | CTA | `CTA.tsx` | `script.ctaText`, `bundle.outputs.ctaUrl` |

### File structure

```
mirror-landing/
  package.json
  next.config.ts              # output: 'export' for static HTML
  tailwind.config.ts          # accent color from bundle, vulcan palette
  app/
    layout.tsx                # minimal: meta tags, fonts
    page.tsx                  # redirect or index
    [slug]/
      page.tsx                # SSG: reads ContentBundle, renders PersonalizedPage
  components/
    PersonalizedPage.tsx      # composes all sections from bundle data
    HeroSection.tsx           # adapted Hero.tsx — headline from script.hookText
    MirrorSection.tsx         # new — Voss mirror text with emotional styling
    DemoSection.tsx           # adapted SubHero.tsx — features from product config
    ResultsSection.tsx        # adapted Testimonials.tsx — result statements
    VideoSection.tsx          # new — <video> embed with autoplay on scroll
    CtaSection.tsx            # adapted CTA.tsx — dynamic text + link
    ui/                       # Button, Container, GridPattern, BlurImage
  lib/
    load-bundle.ts            # reads ContentBundle JSON from disk path
    types.ts                  # ContentBundle type (duplicated from mirror-pipeline, small)
  public/
    videos/                   # copied MP4s for static export
```

### Key decisions

- **Static generation**: `generateStaticParams()` reads all bundles from a configured directory. Each lead gets `yourdomain.com/{slug}`.
- **Video embedding**: Pre-rendered MP4 copied to `public/videos/{slug}.mp4`. Embedded as `<video autoplay muted loop playsinline>`. No JS player needed.
- **Accent color**: Each page reads `productConfig.accentColor` (or a default per Ashley segment) and applies it via CSS custom properties or Tailwind's `style` prop.
- **Personalization without being creepy**: For individual leads, use first name + pain quote. For group pages, use segment pain points without names. The bundle's `enrichedLead.name` controls this — set to "there" for anonymous.
- **Deployment**: `next build` produces static HTML. Deploy via `vercel deploy --prod` or Vercel Git integration.

### Orchestrator integration

Add `generateLandingPage(bundle)` to orchestrator that:
1. Copies bundle JSON to mirror-landing's data directory
2. Copies rendered video MP4 to mirror-landing's `public/videos/`
3. Runs `cd ~/mirror-landing && npm run build` (or `next build`)
4. Optionally runs `vercel deploy`

## Phase 3: Short-Form Video Compositions

**Goal**: 15-second and 30-second vertical videos optimized for YouTube Shorts, TikTok, Reels.

All work stays in the existing `~/mirror-pipeline/` Remotion project.

### Create

**`src/compositions/ShortForm/ShortFormComposition.tsx`** — Wrapper that uses existing scene components with compressed timing:

- **15s**: Hook (0-2s) + Demo highlight (2-8s) + Result (8-12s) + CTA (12-15s)
- **30s**: Hook (0-3s) + Mirror (2-5s) + Demo (4-15s) + Result (14-25s) + CTA (24-30s)

Uses the same `HookScene`, `DemoScene`, `ResultScene`, `CtaScene` from Ashley/Generic pipelines but with tighter frame counts.

**`src/compositions/ShortForm/ShortFormSchema.ts`** — Extends LeadPropsSchema with `duration: z.enum(['15', '30'])`

**`scripts/render-short-form.ts`** — Renders short-form variants from ContentBundle

**`tests/compositions/ShortForm.test.tsx`** — Render tests for both durations

### Modify

**`src/Root.tsx`** — Register ShortForm compositions (15s + 30s, vertical only)

### Orchestrator integration

Add `renderShortForm(bundle)` to orchestrator. Renders 15s and 30s variants. Writes paths to `bundle.outputs.shortForm`.

## Phase 4: Clip Compilation

**Goal**: Stitch together curated clips with text overlays, branding, and optional voiceover. For YouTube Shorts, TikToks, social content.

### Create

**`public/clips/library.json`** — Manifest of available clips:
```json
{
  "clips": [
    { "id": "demo-1", "file": "raw/demo-walkthrough.mp4", "duration": 8.5, "tags": ["demo", "product"] },
    { "id": "broll-bar", "file": "raw/cocktail-pour.mp4", "duration": 4.2, "tags": ["broll", "bar-service"] }
  ]
}
```

**`public/clips/raw/`** — Directory for raw clip files (MP4)

**`src/compositions/ClipCompilation/ClipCompilationComposition.tsx`** — Main composition:
- Uses Remotion `<Video>` from `@remotion/media` to embed clips
- `<Sequence>` stitches clips sequentially
- Text overlay components layer branding, captions, CTAs on top
- Optional voiceover via `<Audio>`

**`src/compositions/ClipCompilation/ClipSegment.tsx`** — Single clip with text overlay
**`src/compositions/ClipCompilation/BrandTransition.tsx`** — Branded transition between clips

Props:
```typescript
type ClipCompilationProps = {
  clips: Array<{
    src: string;
    trimStart?: number;  // frames
    trimEnd?: number;
    overlayText?: string;
    overlayPosition?: 'top' | 'center' | 'bottom';
  }>;
  brandColor: string;
  voiceoverUrl?: string;
  ctaText?: string;
  ctaUrl?: string;
  musicUrl?: string;     // background music
};
```

**`scripts/render-clip-compilation.ts`** — CLI to render from a clip list JSON
**`scripts/add-clip.ts`** — Adds a new clip to library.json with duration detection

### Modify

**`src/Root.tsx`** — Register ClipCompilation composition

## Phase 5: DM/Caption Text Output (quick win)

**Goal**: Extract text outputs from the Script for direct messages and social captions.

### Create

**`scripts/generate-text.ts`** — Reads ContentBundle, outputs formatted text:

```bash
npx tsx scripts/generate-text.ts --bundle leads/bundles/sarah.json --format dm
# Output: "Hey Sarah. You said you're 'drowning in receipts.' That's exhausting. What if it took ten seconds? ..."

npx tsx scripts/generate-text.ts --bundle leads/bundles/sarah.json --format caption
# Output: Instagram-optimized caption with line breaks, hashtags derived from segment
```

This is pure text extraction from `script.*` fields — no AI calls, no rendering. Already have all the data.

### Orchestrator integration

Add `generateTextOutput(bundle, format)`. Writes to `leads/outputs/{slug}-dm.txt` and `leads/outputs/{slug}-caption.txt`.

## Implementation Order

| Phase | Scope | Parallel? | Estimated files |
|---|---|---|---|
| 1 | ContentBundle + Orchestrator | Foundation, do first | ~6 new, ~2 modified |
| 2 | Landing page project | Independent after Phase 1 | ~15 new (separate project) |
| 3 | Short-form compositions | Independent after Phase 1 | ~5 new, 1 modified |
| 4 | Clip compilation | Independent after Phase 1 | ~7 new, 1 modified |
| 5 | DM/Caption text | Independent after Phase 1 | ~2 new |

Phase 1 is the foundation. Phases 2-5 are all independent and can be built in parallel after Phase 1 is done.

**Recommended build order**: Phase 1 → Phase 2 + Phase 3 in parallel (highest value) → Phase 5 (quick win) → Phase 4 (clip compilation needs clip library populated first).

## Verification

### Phase 1
- `npm run ci` — All 158 existing tests still pass
- New orchestrate tests pass
- `npx tsx scripts/orchestrate.ts --input leads/input/example.json --outputs bundle` produces valid JSON
- `npx tsx scripts/orchestrate.ts --bundle leads/bundles/example.json --outputs video` renders MP4

### Phase 2
- `cd ~/mirror-landing && npm run build` — Static export succeeds
- `npm run dev` — Dev server shows personalized page at localhost:3000/{slug}
- Video autoplay works on the page
- All sections populated from bundle data (no hardcoded Foxtrot text)
- `vercel deploy` succeeds

### Phase 3
- `npm run ci` in mirror-pipeline — all tests pass
- Remotion Studio shows ShortForm-15s and ShortForm-30s compositions
- `npx tsx scripts/render-short-form.ts` produces 15s and 30s MP4s

### Phase 4
- Clip library manifest validates
- Remotion Studio shows ClipCompilation composition
- Render produces stitched MP4 with overlays

### Phase 5
- Text output matches script content
- DM format is concise, caption format has line breaks

## Notes

- Aceternity template needs React 18→19, Tailwind 3→4, Framer Motion 10→11 upgrades. These are breaking changes that require component adjustments.
- The landing page `<video>` approach means the video must be rendered BEFORE the landing page is built. The orchestrator handles this ordering.
- Clip compilation requires manually curating clips first. The `add-clip.ts` script handles library management but clip selection is human.
- ContentBundle is the single source of truth. All output renderers are pure functions of the bundle.
- Zod 3.22.3 constraint only applies to the Remotion project. The landing page project can use any Zod version (or none).
