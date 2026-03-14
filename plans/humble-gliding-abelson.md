# Voice Inventory: Red Wine Rush -- Veo 3 Video + TikTok Text

## Context

User wants to test Voice Inventory with a specific scenario: bartender in Friday night rush, needs red wine from stock room, wastes 10 minutes. Current AI photos look artificial. Fix: Veo 3.1 video clips as scene backgrounds + TikTok-style rounded captions.

**Root problem:** The 414-line PROMPTING_GUIDE.md has thorough research, but the actual video prompts in `video-prompts.ts` are hardcoded ~50 word blobs that don't apply it. The `leadContext` field on `ImagePrompt` is marked "reserved for future" and ignored. Every inventory lead gets the same generic "bartender counts bottles with clipboard" regardless of their actual pain.

**Proven approach:** The cocktail card prompts (`cocktail_card_prompts.md`) demonstrate the right architecture: structured templates with `{VARIABLE}` placeholders, model-specific variants, data tables for substitution, and practical notes about what works. Apply this same pattern to video prompts.

## Step 1: Restructure video prompts as templates

**Modify: `src/lib/imagery/video-prompts.ts`**

Replace hardcoded text blobs with structured templates containing `{VARIABLES}` that `buildVideoPrompt()` populates from `leadContext`. This is the same pattern as the cocktail card prompts.

**Template variables available from `ImagePrompt.leadContext`:**
- `{CURRENT_TOOL}` -- what they currently use (e.g., "spreadsheet", "clipboard")
- `{PAIN_SNIPPET}` -- first 80 chars of their pain quote
- `{SEGMENT}` -- the business segment (inventory, bookkeeping, crm)

**Veo 3.1 inventory templates (upgraded to ~150 words with best practices):**

```
hook_background:
"Medium shot inside a busy craft bar on a Friday night. A bartender in their 30s
wearing a black apron stands behind the bar, scanning the nearly-empty wine shelf
with visible frustration. {PAIN_SNIPPET}. They glance down at a {CURRENT_TOOL},
then look back at the shelf and slowly shake their head. Other staff move behind
them in the background. Warm amber Edison bulb key light from above, cool blue fill
from a neon beer sign stage left. Condensation on nearby pint glasses, slightly
cluttered bar top with garnish trays and speed pourers. The camera slowly pushes in
over 6 seconds from medium to medium close-up. Shot on Arri Alexa Mini, 35mm
Zeiss Supreme Prime, natural film grain, shallow depth of field. No plastic skin,
no oversaturation, no text overlays."
```

Same upgrade for `demo_screenshot`, `result_background`, `cta_background`.

**`buildVideoPrompt()` changes:** Instead of returning raw text, replace `{CURRENT_TOOL}`, `{PAIN_SNIPPET}`, `{SEGMENT}` with values from `prompt.leadContext`. This activates the "reserved" field.

**Also upgrade Kling 2.1 and Wan 2.5 inventory templates** following same pattern with their model-specific structures (4-part formula for Kling, sequential steps for Wan).

### Step 2: Wire BackgroundMedia into InventoryDemo scenes

**Modify 5 files.** The `BackgroundMedia` component (`src/components/overlays/BackgroundMedia.tsx`) already handles video + Ken Burns + dark overlay. The `LeadPropsSchema` already defines all 4 background URL optional props. The scene components accept them but don't render them.

| File | Change |
|------|--------|
| `InventoryDemo/index.tsx` | Pass `hookBackgroundUrl`, `demoScreenshotUrl`, `resultBackgroundUrl`, `ctaBackgroundUrl` through to child scenes |
| `InventoryDemo/HookScene.tsx` | Destructure `hookBackgroundUrl`, render `<BackgroundMedia>` when present |
| `InventoryDemo/DemoScene.tsx` | Destructure `demoScreenshotUrl`, render `<BackgroundMedia>` when present |
| `InventoryDemo/ResultScene.tsx` | Destructure `resultBackgroundUrl`, render `<BackgroundMedia>` when present |
| `InventoryDemo/CtaScene.tsx` | Destructure `ctaBackgroundUrl`, render `<BackgroundMedia>` when present |

Pattern per scene:
```tsx
{hookBackgroundUrl && <BackgroundMedia src={hookBackgroundUrl} darkenOpacity={0.6} />}
```

### Step 3: Create RoundedCaption component

**New: `src/components/text/RoundedCaption.tsx`**

Uses `@remotion/rounded-text-box` (4.0.421) + `@remotion/layout-utils`.

Semi-transparent black rounded box behind text (TikTok style). Spring entrance animation. Used for pain quote (HookScene) and voice commands (DemoScene).

### Step 4: Generate Veo 3 clips + create lead + render

1. Create `leads/input/red-wine-rush.json` with the Marco red wine rush scenario
2. Generate 4 Veo 3.1 clips (6s, 9:16) via `generateVideo()`
3. Save to `public/videos/leads/inventory-rush/`
4. Run pipeline: `npx tsx scripts/orchestrate.ts --input leads/input/red-wine-rush.json --outputs bundle,voiceover,video`

## Files

| Action | File | Purpose |
|--------|------|---------|
| Modify | `src/lib/imagery/video-prompts.ts` | Template-based prompts with `{VARIABLES}` + 150 word upgrades |
| Modify | `InventoryDemo/index.tsx` | Pass background URLs to scenes |
| Modify | `InventoryDemo/HookScene.tsx` | Add BackgroundMedia + RoundedCaption |
| Modify | `InventoryDemo/DemoScene.tsx` | Add BackgroundMedia + RoundedCaption |
| Modify | `InventoryDemo/ResultScene.tsx` | Add BackgroundMedia |
| Modify | `InventoryDemo/CtaScene.tsx` | Add BackgroundMedia |
| Create | `src/components/text/RoundedCaption.tsx` | TikTok-style text overlay |
| Create | `leads/input/red-wine-rush.json` | Lead input |

## Existing Code to Reuse

- `src/components/overlays/BackgroundMedia.tsx` -- video bg with Ken Burns + dark overlay
- `src/lib/imagery/video-generator.ts` -- `generateVideo()` for Kie.ai
- `src/lib/imagery/types.ts` -- `ImagePrompt.leadContext` (activate it)
- `src/schemas/lead.ts` -- all 4 background URL props already defined
- `@remotion/rounded-text-box` -- `createRoundedTextBox()` for SVG paths
- `@remotion/layout-utils` -- text measurement

## Verification

1. `npm run typecheck` -- no new errors
2. `npm test` -- all tests pass
3. `npm run dev` -- Remotion Studio shows video backgrounds + rounded captions
4. Veo 3 clips look realistic (film grain, motivated lighting, no AI look)
5. Full pipeline renders video with VO synced to scenes
