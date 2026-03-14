# Plan: Integrate Remotion Template Techniques into Mirror Pipeline

## Goal
Add TikTok-style captions, audio waveform visualization, and smooth scene transitions using `@remotion/captions`, `@remotion/media-utils`, and `@remotion/transitions` (already installed but unused).

## Task Dependency Graph

```
Task 0: Install packages
   ├── Task 1: TikTok-style captions component
   ├── Task 2: Audio waveform visualizer component
   ├── Task 3: Scene transitions (TransitionSeries)
   └── Task 5: Voiceover duration from MP3
        └── Task 4: Wire everything into DesignSystemPreview
```

Tasks 1, 2, 3, 5 can run in parallel after Task 0. Task 4 depends on all others.

---

## Task 0: Install Dependencies

Install `@remotion/captions` and `@remotion/media-utils` (match existing Remotion version 4.0.421). `@remotion/transitions` is already installed.

```bash
npm install @remotion/captions@4.0.421 @remotion/media-utils@4.0.421
```

---

## Task 1: TikTok-Style Captions Component

**File**: `src/components/text/TikTokCaptions.tsx`
**Test**: `tests/components/text/TikTokCaptions.test.tsx`

Use `@remotion/captions` API:
- Accept a `captions` prop (array of `{ text, startMs, endMs, timestampMs, confidence }`)
- Use `createTikTokStyleCaptions()` with `combineTokensWithinMilliseconds` for word grouping
- Render word-by-word highlighting synced to current frame
- Style: white text with black outline/shadow, bottom-center position inside safe zone
- Spring animation for word pop-in
- Props: `captions`, `fontSize`, `linesPerPage`, `combineMs`

---

## Task 2: Audio Waveform Visualizer

**File**: `src/components/audio/WaveformVisualizer.tsx`
**Test**: `tests/components/audio/WaveformVisualizer.test.tsx`

Use `@remotion/media-utils`:
- `useWindowedAudioData()` to get frequency data for current frame window
- `visualizeAudio()` to convert to bar heights (frequency spectrum)
- Render as vertical bars with gradient coloring from design tokens
- Props: `src` (audio file), `barCount`, `barWidth`, `color`, `style`
- Positioned as subtle background element (low opacity, behind text layer)

---

## Task 3: Scene Transitions

**File**: `src/components/transitions/SceneTransitions.ts`
**Test**: `tests/components/transitions/SceneTransitions.test.tsx`

Use `@remotion/transitions`:
- Export preset transition configs using `fade()`, `slide()`, `wipe()` from `@remotion/transitions/presets`
- Map to scene psychology: hook→demo = `slide({ direction: 'from-left' })`, demo→result = `fade()`, result→CTA = `wipe({ direction: 'from-bottom' })`
- Export a `SCENE_TRANSITIONS` constant mapping scene pairs to their transition + duration
- Each transition gets 15 frames (0.5s at 30fps) overlap

---

## Task 4: Wire Into DesignSystemPreview (depends on Tasks 1-3, 5)

**File**: `src/compositions/DesignSystemPreview/DesignSystemPreview.tsx`
**File**: `src/compositions/DesignSystemPreview/registry.tsx`

Changes:
1. Replace `<Sequence>` blocks with `<TransitionSeries>` + `<TransitionSeries.Sequence>` + `<TransitionSeries.Transition>`
2. Add `<TikTokCaptions>` as an overlay layer (z-index above text, below CTA)
3. Add `<WaveformVisualizer>` as subtle background in demo scene
4. Adjust total duration to account for transition overlaps (3 transitions x 15 frames = 45 frames shorter)
5. Update registry with new duration

---

## Task 5: Voiceover Duration from MP3

**File**: `src/lib/voice/text-to-speech.ts`
**Test**: `tests/lib/voice/text-to-speech.test.ts` (update existing)

Add duration calculation to `generateVoiceover()` return value:
- After writing MP3 file, read file size
- Calculate duration from CBR: `duration = (fileSize * 8) / (128000)` (128kbps)
- Return `{ filePath, cached, duration }` where duration is in seconds
- This enables future frame-accurate caption sync

---

## Implementation Approach

- TDD: Write failing tests first for each component
- Agent team: 3-4 parallel implementers after Task 0
- Code review after all tasks complete
- Re-render DesignSystemPreview MP4 to verify
- Run full CI before commit

## Risks

- `@remotion/captions` requires actual caption data (timestamps per word). For now, generate synthetic captions from narration text with estimated timing since Cartesia doesn't return word-level timestamps.
- `useWindowedAudioData()` requires the composition to have audio - already have voiceover wired in.
- TransitionSeries changes scene timing math - need to recalculate carefully.
