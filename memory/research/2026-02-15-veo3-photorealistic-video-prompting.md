# Veo 3 / Veo 3.1 Photorealistic Video Prompting Research

### 2026-02-15 - Comprehensive prompting guide for commercial-grade AI video

[research] Deep research into Google Veo 3/3.1 best practices for photorealistic, non-AI-looking video output.

## Core Prompt Formula (5-7 Layers)

**7-Layer**: [Camera & Lens] + [Subject] + [Action & Physics] + [Environment] + [Lighting] + [Style & Texture] + [Audio]
**5-Layer**: [Shot Composition] + [Subject Details] + [Action] + [Setting/Environment] + [Aesthetics/Mood]

## Optimal Prompt Length

- Under 50 words: too vague
- 50-100 words: minimum effective
- **100-200 words: optimal sweet spot**
- 200-300 words: diminishing returns
- Over 300 words: conflicting instructions, messy output

## Key Anti-AI Keywords

- "Slightly grainy, looks very film-like" - pushes away from too-clean AI look
- "shot on 35mm film with natural grain"
- "16mm documentary style"
- "Super 8 home movie aesthetic"
- "film grain 400 ISO; halation; anamorphic flares; light bloom"
- "shallow depth of field with creamy bokeh"
- "handheld camera" or "slight handheld movement"

## Negative Cues (Artifact Avoidance)

- "avoid extra limbs"
- "avoid glitch morphs"
- "no object warping"
- "no jump cuts within clips"
- "avoid text overlays"
- "no oversaturation"
- "no plastic skin"
- "no over-sharpening"
- "no soap opera effect"
- "no subtitles" (when using dialogue)

## Camera Movement Terms (Tested & Working)

- "slow dolly forward" / "gentle dolly-in"
- "slow pan left/right"
- "smooth tracking shot following subject"
- "crane shot descending"
- "handheld tracking" (documentary feel)
- "static camera" / "locked-off"
- "slow push-in over 6-8 seconds"
- Keep to ONE camera move per shot
- Pan speeds: 10-20% feel natural; above 40% causes edge smearing
- Write camera movement as standalone sentence, not embedded in subject description

## Lighting Keywords

- "soft daylight from north-facing window"
- "golden-hour backlight"
- "overcast, diffused key"
- "warm golden hour sunlight"
- "soft key from window left; 3:1 key-to-fill; weak rim from streetlight"
- "volumetric fog rays"
- "dappled forest light"
- "harsh overhead fluorescents"
- "practical lights" (visible lamps, neon, candles)
- "rim lighting"

## Material/Texture Keywords for Subject Anchoring

Specifying fabric/material gives Veo a light-reflection profile that stabilizes the subject:
- "charcoal canvas" / "cotton" / "silk" / "linen" / "worn leather"
- "sweat-glistening faces"
- "visible plumes of breath"
- "dust kicking up slightly"

## Resolution & Settings

- Veo 3: up to 1080p, 8-second clips
- Veo 3.1: up to 4K (3840x2160), 4-8 second clips, extendable to 60 seconds
- Aspect ratios: 16:9 (YouTube/web), 9:16 (Shorts/Reels/TikTok)
- Duration: 4s (simple), 6s (narrative/dialogue), 8s (complex sequences)
- Use 720p for drafts/iteration, 1080p or 4K for final

## Photorealism Comparison

- **Veo 3/3.1**: Best overall photorealism, especially lighting/textures. Best fire, water, fireworks. Minimal camera drift.
- **Kling 2.1**: Excellent photorealism, works best with short simple prompts, precise rendering
- **Wan 2.5**: More obvious "AI look" on characters, but excels at dynamic motion and audio sync

## Commercial/Marketing Tips

- Cost reduction up to 70% vs traditional production
- First fully AI-generated TV commercial: Coign credit card, under 12 hours, <1% of traditional cost
- Platform-specific optimization: vertical/quick for social, narrative/high-res for YouTube
- Post-production polish (color correction, audio mastering) elevates to agency quality
- Test prompts as static images first before committing to video generation
- Use for quick social ads, campaign tests, content variations; keep traditional for hero content

## Dialogue Tips

- Use colon format: `Character says: 'dialogue'` (prevents subtitles)
- Keep dialogue under 8 seconds
- Specify "no subtitles" when dialogue shouldn't display text
- Specify character identifiers (clothing, positioning) for multi-character scenes

## Example Prompt Structure (Restaurant Scene)

"Interior cafe, late afternoon. Two friends in a medium two-shot at a window table. One line of dialogue from Person A: 'This is it--are you ready?' Person B smiles silently. Camera: gentle dolly-in. Natural ambience: clinking cups, soft chatter. Keep lips aligned to dialogue."
