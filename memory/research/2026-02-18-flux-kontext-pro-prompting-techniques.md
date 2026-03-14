# Flux Kontext & Flux Pro Prompting Techniques Research
### 2026-02-18 - Comprehensive prompting research for Flux models

[research] Compiled from official BFL docs, community guides, Civitai, Reddit aggregators, and blog posts.

## Key Findings

### 1. Prompt Structure: Natural Language Wins
- Flux uses dual-encoder (CLIP + T5). T5 understands natural language like an LLM.
- Write conversational sentences, NOT comma-separated keywords.
- Short prompts (10-30 words) for quick concepts; Medium (30-80 words) for most work; Long (80+) for complex scenes.
- Keep under 512 tokens max. Optimal T5 length ~256 tokens.
- Long prompts get compressed to ~100 tokens internally. Short prompts get auto-expanded.

### 2. Best Style Keywords
- Camera references: "Shot on Sony A7IV", "Canon 5D Mark IV, 24-70mm at 35mm"
- Film stocks: "Kodak Portra 400", "Fujifilm Superia"
- Era styles: "80s vintage photo", "2000s digicam style", "early digital camera"
- Art styles: "impressionist painting", "watercolor sketch", "oil painting with visible brushstrokes"
- Photography terms: "shallow depth of field", "golden hour", "cinematic harsh flash lighting"
- Mood/atmosphere: "editorial raw portrait", "documentary style"

### 3. What to AVOID
- NO prompt weights syntax (text)++ - not supported
- NO negative prompts natively - use positive phrasing instead ("sharp focus" not "no blur")
- NO "white background" in dev variant - causes blur
- NO sequential actions ("man sitting then standing") - pick one state
- NO keyword dumping - structure narratively
- NO conflicting styles ("cyberpunk and medieval")
- NO vague pronouns ("her", "it") - use descriptors ("the woman with short black hair")
- NO vague instructions ("make it better", "clean up")

### 4. Flux vs Midjourney vs DALL-E
- Flux: Natural language, no special syntax, best for photorealism, no --style flags
- Midjourney: Uses --style, --stylize parameters, distinctive aesthetic, better for artistic work
- DALL-E: Best at understanding complex instructions, conversational refinements
- Flux excels at text rendering in images, photorealistic humans, and technical precision

### 5. Best Settings
- Steps: 24-32 for dev, 2-4 for schnell
- Guidance: 2.5-3.8 for dev, 4.5 default for Flux 2
- Resolution: 1024x1024 or larger, avoid 512x512
- Aspect ratios: 1:1, 16:9, 9:16, 4:3, 21:9 all supported
- Stay under 2MP to avoid white halos
- Dimensions must be multiples of 32 (Flux 1) or 16 (Flux 2)

### 6. Kontext-Specific Tips
- Three-Layer Framework: Action Layer + Context Layer + Preservation Layer
- Always specify what to KEEP, not just what to change
- Use original unaltered photo as input for each new edit (don't chain edited versions)
- Text editing: use quotes - Replace '[original]' with '[new text]'
- Character consistency: "maintain the exact same character and facial features"
- Style transfer: name exact styles, not vague terms

### 7. Top Example Prompts (Proven Results)

**Photorealistic Portrait:**
"A young woman with long, wavy brunette hair rests her head on her clasped hands, looking at the camera. She is dressed in a black top and wears a delicate bracelet on her left wrist. Her expression is gentle and thoughtful, enhanced by natural makeup and a hint of pink lipstick. The background is dark and blurred, drawing attention to her face and hands."

**Product Shot:**
"Black cat hiding behind a watermelon slice, professional studio shot, bright red and turquoise background with summer mystery vibe"

**Cinematic Animal:**
"Dog wrapped in white towel after bath, photographed with direct flash and high exposure, fur wet details sharply visible, editorial raw portrait, cinematic harsh flash lighting, intimate humorous documentary style"

**Vintage Style:**
"A group of baby penguins in a trampoline park, having the time of their lives, 80s vintage photo"

**Landscape:**
"Wide-angle snow-capped peaks at dawn, mist swirling, vibrant orange-pink sky, lone wolf foreground gazing at horizon"

**Magazine Cover:**
"Women's Health magazine cover, April 2025 issue, 'Spring forward' headline, woman in green outfit sitting on orange blocks, white sneakers, 'Covid: five years on' feature text, '15 skincare habits' callout, professional editorial photography, magazine layout with multiple text elements"

**Layered Composition:**
"In the foreground, a vintage car with a 'CLASSIC' plate is parked on a cobblestone street. Behind it, a bustling market scene with colorful awnings. In the background, the silhouette of an old castle on a hill, shrouded in mist"

**Food Photography:**
"A rustic wooden table set with a traditional Galician ceramic plate holds steaming Pulpo a la Gallega—tender octopus slices, glistening with golden olive oil and sprinkled with vibrant red paprika and coarse sea salt. Soft, diffused natural light highlights the dish's textures. Shot in a close-up, slightly overhead angle with a shallow depth of field."

## Sources
- BFL Official Kontext Guide: https://docs.bfl.ai/guides/prompting_guide_kontext_i2i
- BFL Official Flux 2 Guide: https://docs.bfl.ml/guides/prompting_guide_flux2
- getimg.ai Guide: https://getimg.ai/blog/flux-1-prompt-guide-pro-tips-and-common-mistakes-to-avoid
- Civitai Analysis: https://civitai.com/articles/7309/starting-to-understand-how-flux-reads-your-prompts
- Ambience AI Guide: https://www.ambienceai.com/tutorials/flux-prompting-guide
- Segmind Guide: https://blog.segmind.com/flux-prompting-guide-image-creation/
