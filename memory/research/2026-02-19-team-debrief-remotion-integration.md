### 2026-02-19 - Team Debrief: Remotion Integration (Captions, Waveform, Transitions)

## What went smoothly
- All 4 parallel agents completed independently without conflicts
- TDD approach worked well - tests first, implementation second
- No merge conflicts between agent outputs (independent file creation)
- TypeScript typecheck passed first try after wiring

## What was hard
- [gotcha] CaptionPage timing bug: The captions agent implemented `currentAbsoluteMs >= pageStartMs + token.fromMs` which only works when pageStartMs=0. Correct formula per @remotion/captions docs: `absoluteTimeMs = pageStartMs + (frame/fps)*1000`, then `token.fromMs <= absoluteTimeMs && token.toMs > absoluteTimeMs`. Token timestamps are ABSOLUTE, not page-relative.
- [gotcha] Voiceover agent updated elevenlabs-tts.ts to use `fs.statSync` but didn't update the ELEVENLABS test file's fs mock. Had to add `statSync: vi.fn()` to the mock and `vi.mocked(fs.statSync).mockReturnValue({ size: 16000 } as fs.Stats)` to beforeEach.
- [gotcha] Ashley registry test was pre-existing broken - compositions use `<Audio>` from `@remotion/media` but test only mocked `remotion`, not `@remotion/media`. Added mock for `@remotion/media` and `@remotion/media-utils`.

## Key learnings
- [pattern] TransitionSeries replaces Sequence for scene layouts. No `from` prop needed - scenes lay out sequentially. Transitions subtract from total duration: `totalFrames = sum(scenes) - numTransitions * transitionFrames`.
- [pattern] Audio should stay OUTSIDE TransitionSeries (in a sibling AbsoluteFill) for full-duration playback.
- [pattern] Captions overlay placed after TransitionSeries in render tree = renders on top of all scenes.
- [decision] Used procedural waveform instead of live audio (`useWindowedAudioData`) for testability. Sine waves at 3 frequencies create organic-looking movement.
- [pattern] @remotion/captions `createTikTokStyleCaptions()` groups captions into pages with `combineTokensWithinMilliseconds`. Pages have `startMs` and `tokens[]` with absolute `fromMs`/`toMs`.

## Unresolved
- Synthetic captions use estimated word timing. When Cartesia adds word-level timestamp support, replace with real timestamps.
- `linesPerPage` prop accepted but unused in TikTokCaptions component.
- npm install only added @remotion/captions (1 package). @remotion/media-utils was already a transitive dep.
