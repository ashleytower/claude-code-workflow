# Plan: Rebuild Another Round Video Ads

## Context
The first batch of Another Round video ads used AI-generated images as backgrounds (SyrupsDemo composition) and Cartesia TTS at "slow" speed. User feedback:
1. Voiceover still too fast even on "slow"
2. AI images aren't good enough -- drop them entirely
3. Use pure Remotion motion graphics with personalized text calling out bartenders by name

User choices:
- **Both** personalized ("Hey Alex") and generic ("Hey bartender") versions
- **Gradient + motion** style (dark gradients, smooth animated text reveals, polished)
- **Test both** Cartesia with pauses AND ElevenLabs at 0.7x speed

---

## Part 1: New TextForwardAd Composition

### New files (all in `src/pipelines/ashley/compositions/TextForwardAd/`)

**Schema** (`schema.ts`):
- `bartenderName` (string, default "bartender")
- `painLine`, `bridgeLine`, `solutionLine` (required strings)
- `painDetail`, `solutionDetail` (optional strings)
- `ctaLine` (default "Link in bio"), `ctaUrl`
- `accentColor` (default "#d97706")
- `voiceoverUrl` (optional)

**GradientBackground.tsx** -- Replaces BackgroundMedia:
- Animated radial gradient using useCurrentFrame() + interpolate()
- Slow "breathing" effect via sin(frame * 0.02)
- Accent color as dim glow point (opacity 0.06-0.12)
- 4 variants: radial-center, radial-top, radial-bottom, linear-diagonal
- Base dark: #0a0f1a, accent: #d97706

**5 Scene Components** (each gets its own file):

| Scene | Frames | Animation | Content |
|-------|--------|-----------|---------|
| HookScene | 0-120 (0-4s) | Name slam (damping 12, stiffness 200) | "Hey {name}" + amber accent bar |
| PainScene | 90-240 (3-8s) | TypewriterText (speed 1.5) | Pain mirror quote |
| BridgeScene | 210-330 (7-11s) | FadeInText + subtle scale 0.95→1.0 | "What if..." |
| SolutionScene | 300-480 (10-16s) | Bouncy scale + HighlightText underline | Product benefit |
| CtaScene | 450-600 (15-20s) | Slide-up + pulsing amber button | CTA + URL |

Scenes overlap by ~1s for momentum (matches existing pattern).

**index.tsx** -- Main composition:
- Wire 5 scenes with Sequence layout + premountFor={fps}
- Audio via `<Audio>` from @remotion/media when voiceoverUrl provided
- AbsoluteFill with #0a0f1a base

### Modifications to existing files

1. **TypewriterText.tsx** -- Add optional `cursorColor` prop (default #a78bfa for backward compat). Passes through to cursor span color + textShadow.

2. **registry.tsx** -- Register `TextForwardAd-Vertical` (1080x1920, 30fps, 600 frames) with TextForwardAdPropsSchema and default props.

### Ad script data

New file `src/pipelines/ashley/data/another-round-scripts.ts` with all 9 ad scripts parsed into the 5-beat structure (hookLine, painLine, bridgeLine, solutionLine, ctaLine).

---

## Part 2: Voiceover Pacing Fix

### Cartesia improvement
- Current code passes `speed: 'slow'` as string. Cartesia ModelSpeed type also accepts `'slowest'`.
- Update VoiceoverSpeed type to include `'slowest'` and `'fastest'`.
- Add SSML-style pauses by inserting `...` and sentence breaks in the script text before sending to API.
- New helper: `addTextPauses(script: string)` -- inserts natural pauses at sentence boundaries.

### ElevenLabs integration
- Package already installed: `@elevenlabs/elevenlabs-js` v2.35.0
- New file: `src/lib/voice/elevenlabs-tts.ts`
  - Same interface as Cartesia: `generateVoiceover(text, options) → VoiceoverResult`
  - Speed: numeric 0.7 (30% slower than default)
  - Model: `eleven_multilingual_v2`
  - Voice: George (`JBFqnCBsd6RMkjVDRZzb`) or similar narrative voice
  - Output: MP3 44100/128kbps (matches Cartesia output)
  - Requires `ELEVENLABS_API_KEY` env var
- Update `VoiceoverOptions` with optional `provider: 'cartesia' | 'elevenlabs'`

### Generation script
- New: `scripts/gen-another-round-vo2.ts` -- generates all 9 scripts with both TTS engines for A/B comparison.
- Outputs to `public/audio/another-round/cartesia/` and `public/audio/another-round/elevenlabs/`

---

## Part 3: Render All Versions

### Batch render script
- New: `scripts/render-another-round-text-ads.ts`
- For each of 9 ad scripts × 2 versions (personalized + generic) = 18 renders
- Uses winning TTS after comparison (or renders both for user review)
- Output: `leads/renders/another-round-v2/`

---

## Tests (TDD -- written first)

1. `tests/pipelines/ashley/schemas/text-forward-ad.test.ts` -- Schema validation (defaults, required fields, URL validation)
2. `tests/pipelines/ashley/compositions/TextForwardAd.test.ts` -- Render tests (default props, name personalization, optional fields)
3. `tests/lib/voice/elevenlabs-tts.test.ts` -- ElevenLabs TTS (mocked API, speed mapping, caching)
4. `tests/lib/voice/text-pauses.test.ts` -- Pause insertion helper
5. Update registry test for new composition count

---

## Team Structure

| Agent | Role | Tasks |
|-------|------|-------|
| composition-builder | frontend | Schema + GradientBackground + 5 scenes + main composition + registry |
| tts-builder | backend | ElevenLabs module + pause helper + VoiceoverSpeed update + gen script |
| reviewer | code-reviewer | Review all changes |
| validator | verify-app | CI: typecheck + test + lint + build |

composition-builder and tts-builder work in parallel (no shared files).

---

## Verification

1. `npm run ci` passes (typecheck, test, lint, build)
2. Preview in Remotion Studio: `npm run dev` → open TextForwardAd-Vertical
3. Render one test video: `npx remotion render TextForwardAd-Vertical --props='...'`
4. Generate both Cartesia (slowest + pauses) and ElevenLabs (0.7x) voiceovers for ad 1
5. Play both for user to pick winner
6. Batch render all 18 versions with winning TTS
