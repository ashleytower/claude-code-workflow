# AI Video Prompting Research: Veo 3.1, Kling 2.1/2.6, Wan 2.5/2.6

### 2026-02-18 - Comprehensive prompting techniques for AI video generation models

[research] Deep research across Google Cloud docs, Reddit, Medium, Skywork, and multiple guides.

## Key Findings

### Universal Prompt Formula
[Subject] + [Action] + [Camera/Shot] + [Environment] + [Style/Lighting] + [Duration/Aspect]
- 100-150 words optimal (3-6 sentences)
- Front-load the most important elements in first 20-30 words
- Max 4-5 distinct nouns per prompt to avoid confusion

### Model Selection Guide
- **Veo 3.1**: Best for dialogue, lip sync, natural performance, cinematic polish. 8s max, 1080p, 24fps.
- **Kling 2.6**: Best for motion control, action, dance, visual fidelity. Up to 3min with extend, 1080p, 48fps.
- **Wan 2.6**: Best for open-source/developer use, multi-shot narrative, budget work. 15s max, 1080p.

### Camera Movement Terms That Work
dolly in/out, slow pan L/R, tracking shot, crane up/down, orbit, push-in, whip-pan, tilt up/down, aerial reveal, handheld drift

### Common Mistakes
1. Conflicting instructions (fast + slow)
2. Too many elements (keep under 5 nouns)
3. Vague descriptors ("nice" instead of specific)
4. No motion cues = static/lifeless output
5. Ignoring timing vs duration mismatch
6. Skipping negative prompts
7. Not specifying light SOURCE (just saying "cinematic lighting")

### Top Prompt Patterns (from story321.com 76-prompt library)
- "A lone hiker crests a ridge at sunrise, sea of clouds below, photoreal, slow dolly-out, 35mm lens, golden rim light, 16:9, 8s."
- "Neon-lit alley in light rain, protagonist adjusts motorcycle helmet, anamorphic flares, handheld, shallow DOF, 16:9, 10s."
- "Matte black wireless earbuds on wet slate, macro droplets, soft rim, slow hero orbit, photoreal, 16:9, 8s."

### 7 Prompt Types (from aifire.co)
1. Cinematic (camera + emotion)
2. Timestamp (second-by-second segments)
3. Cutscene ("cut to" transitions)
4. GPT-assisted (AI writes structure, you simplify)
5. Anchor (character detail locks)
6. Image (image-to-video with minimal text)
7. Negative (remove unwanted elements)

## Sources
- Google Cloud Veo 3.1 Official Guide
- story321.com 60+ prompt library
- skywork.ai prompt patterns
- dreamega.ai model comparison
- aifire.co 7 prompt types
- wan2-5.com prompt guide
- invideo.io Kling hidden secrets
