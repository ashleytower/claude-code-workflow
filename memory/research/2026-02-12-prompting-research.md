# Prompting Research - Image & Video Generation
## 2026-02-12

### Key Findings

[research] 4 parallel research agents scoured Reddit, X, YouTube, GitHub, and official docs for best practices across Flux Kontext, Nano Banana, GPT-4o Image, Grok Imagine, Veo 3.1, Kling 2.1, and Wan 2.5.

### Image Models

[decision] Nano Banana Pro is best overall image generator in 2025/2026 -- 5/5 text rendering, 9.5/10 photorealism, $0.09-0.12/image via Kie.ai. Flux Kontext best open-source for text. GPT-4o best for iterative refinement and multi-turn editing.

[pattern] Physics-first prompting: Replace adjectives ("ultra-realistic") with camera specs ("Canon 5D Mark IV, 85mm f/1.4, Kodak Portra 400"). This is the single most impactful technique across all models.

[pattern] UGC degradation: Flux defaults to polished. Must explicitly degrade: "shot on iPhone", "compressed", "visible pores", "natural peach fuzz", "candid composition not perfectly centered".

[gotcha] Flux has NO negative prompt support. Use positive reframing: "sharp focus throughout" not "no blur".

[gotcha] Flux prompt weight syntax `(concept:1.5)` does NOT work. Use natural language emphasis.

### Video Models

[decision] Veo 3.1 for dialogue/talking head (best lip sync). Kling 2.1 for product/motion (best texture realism). Wan 2.5 for budget/open-source.

[pattern] One camera move per shot. Multiple simultaneous motions cause artifact spikes across all models.

[gotcha] Wan 2.5 face drift: reduces ~60% by including specific identifying characteristics in prompts.

### UGC Ad Creative

[research] AI-generated UGC: +47% CTR, -29% CPA. Creative fatigue: 37% drop after 7 days -- refresh weekly. Target 30-40% 3-second hook rate.

[pattern] Hook→Problem→Solution→CTA structure. Before/after split imagery converts highest for service businesses.

### Output

Full prompting guide written to `src/lib/imagery/PROMPTING_GUIDE.md`. Prompt-builder.ts updated with research-backed improvements.
