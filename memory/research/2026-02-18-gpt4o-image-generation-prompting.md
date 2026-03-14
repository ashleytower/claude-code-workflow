### 2026-02-18 - GPT-4o / GPT Image 1 Prompting Research

[research] Comprehensive research on GPT-4o image generation (also called GPT Image 1 / gpt-image-1) best practices, gathered from OpenAI docs, community forums, prompt engineering guides, and comparison articles.

---

## Model Overview

GPT-4o image generation is autoregressive, using the same architecture as the GPT-4o LLM. It generates images the same way the LLM generates text. This is fundamentally different from diffusion-based models like Midjourney, Flux, and Stable Diffusion.

Key model names:
- ChatGPT interface: "4o image generation" or "native image generation"
- API: `gpt-image-1` (original), `gpt-image-1.5` (improved version)
- Max resolution: up to 4096x4096 pixels

## Core Prompting Formula

**[What you want] + [Style] + [Important details] + [Technical specs]**

Or structured as: **background/scene -> subject -> key details -> constraints**

For complex requests, use short labeled segments or line breaks instead of one long paragraph.

## What Works Well

1. **Natural language paragraphs** over keyword-stuffed prompts (unlike Midjourney)
2. **Conversational iteration** - start simple, refine with follow-up messages
3. **Specific visual descriptors**: lighting type, color hex codes, camera angle, texture
4. **Text rendering** - ~85% accuracy, best with sans-serif fonts. Put literal text in QUOTES or ALL CAPS in the prompt. Spell uncommon words letter-by-letter.
5. **Photography language** (lens type, aperture feel, lighting direction) for photorealism
6. **Context about purpose** helps the model tailor output
7. **Hex color codes** (#1B365D) rather than color names for consistency
8. **Aspect ratio in first sentence** - specify 1:1, 3:2, 2:3, 16:9, 9:16
9. **"Transparent background" or "transparent PNG"** for sticker-style outputs
10. **50-100 word prompts** outperform longer ones for most tasks

## What Works Poorly / Common Mistakes

1. **Vague prompts** ("draw something cool") produce generic results
2. **Overloaded mega-prompts** - start simple and iterate instead
3. **Not specifying resolution** leads to blurry/poorly scaled output
4. **Missing style keywords** ("photorealistic", "3D-style", etc.)
5. **Hands/fingers** (~70% success rate)
6. **5+ people** in a scene
7. **Perfectly symmetrical designs** are unreliable
8. **Very specific poses or angles** often fail
9. **Small text on complex backgrounds** is hard
10. **Non-Latin text** rendering is weak
11. **Images tend dark** - may need to explicitly prompt for bright/well-lit scenes or use gamma 1.5 correction
12. **Flat compositions** - need extensive detail prompting for depth
13. **Copyrighted style requests** get blocked (especially vague ones that might accidentally mimic)

## Known Technical Issues

- Final processing phase adds artifacts, especially around eyes/faces
- Consistent underexposure (dark images)
- Digital camera artifacts from training data (grain, edge sharpening)
- Images can be cropped too tightly, especially at bottom of tall images
- Dimension/color tone inconsistencies in editing workflows

## GPT-4o vs Midjourney vs Flux

| Feature | GPT-4o | Midjourney | Flux |
|---------|--------|------------|------|
| Prompting style | Natural language paragraphs | Keyword-heavy, parameter flags | Structured prompts |
| Text rendering | Excellent (~85%) | Poor | Poor-Moderate |
| Artistic quality | Good, improving | Best for artistic/cinematic | Best for commercial realism |
| Complex instructions | Excellent (LLM reasoning) | Limited | Limited |
| Speed | 90-120 sec | Fast | 4.5 sec (fastest) |
| Conversational editing | Yes (huge advantage) | No | No |
| Objects per scene | 10-20 | 5-8 | 5-8 |
| Photorealism | Good | Excellent (cinematic) | Excellent (commercial) |
| Fantasy/Creative | Weaker than DALL-E 3 | Strongest | Good |
| Identity preservation | Good with explicit locking | N/A | Good (Kontext) |

## Best Use Cases for GPT-4o

- Text-heavy images (menus, posters, infographics, labels)
- Marketing assets with specific copy
- UI/UX mockups (describe as if product already exists)
- Product packaging design
- Action figure / toy packaging (viral trend)
- Style transfer (Ghibli, Pixar, cyberpunk, noir)
- Photo editing and transformation
- Iterative design workflows
- Educational content with annotations
- Logo design with text

## Worst Use Cases for GPT-4o

- Photorealistic portraits requiring perfection (artifact issues)
- Highly symmetrical designs
- Large groups of people
- Fantasy/imagination-heavy artwork (Midjourney better)
- Speed-critical applications (Flux much faster)
- Fine art with extreme detail (Midjourney better)
- Non-Latin script rendering

## 10 High-Quality Example Prompts

### 1. Photorealistic Product Shot
"Create a professional product photograph of [product] on pure white background (#FFFFFF). Studio lighting with soft, even illumination. DSLR quality, highly detailed textures, natural lighting."

### 2. Studio Ghibli Style Transfer
"Remix this photo into a Studio Ghibli-style illustration - soft watercolor palette, delicate linework, cozy atmosphere, and fantasy elements like floating lights or magical effects."

### 3. Action Figure Packaging
"Create a classic toy action figure of the person in this photo. In traditional packaging with cardboard backer and plastic blister. The blister pack should have a header with the text '[NAME]' in large letters and a subheading of '[TITLE]' below it. Each accessory in its own plastic bubble."

### 4. Pixar 3D Cartoon
"Convert this image into a 3D Pixar-style cartoon - clean lines, soft lighting, expressive features, and polished cinematic render."

### 5. Infographic
"Create an infographic explaining [TOPIC] in great detail. The background should be pure white, and include neatly rendered text labels with step-by-step annotations. Each step should be numbered and connected with subtle gradient arrows."

### 6. Wine List / Menu Design
"Design a wine list for a Mediterranean tapas bar named Olive & Vine in Barcelona. The style should be contemporary yet romantic. Incorporate watercolor illustrations for wine regions, with all text rendered in elegant calligraphy on aged parchment."

### 7. Cyberpunk Transformation
"Transform this image into a cyberpunk aesthetic - neon lights, dark city backdrop, glowing signs, misty rain, and futuristic accessories."

### 8. Film Noir
"Transform into classic noir - high-contrast black and white, sharp shadows, foggy ambiance, and vintage film grain."

### 9. Abstract Cosmic Composition
"Create a circular image containing a spiral arrangement of 12 objects on a deep space background. Include: a crystalline hourglass, a mechanical butterfly, a floating quantum computer, a DNA helix made of stars, a Klein bottle filled with rainbow liquid, a Mobius strip of sheet music, a fractal tree growing circuit boards, a time-worn pocket watch showing impossible hours..."

### 10. LinkedIn Professional Graphic
"Design a square social media graphic for LinkedIn, 1:1 ratio. Background: smooth gradient from navy blue (#1B365D) at top to lighter blue at bottom. Add the title 'Q1 2026 Performance Review' in bold white sans-serif font. Include plenty of white space. Clean, professional layout."

## Advanced Techniques (from OpenAI Cookbook)

- **Identity preservation**: "Explicitly lock the person (face, body shape, pose, hair, expression)" and "change only X, keep everything else the same"
- **Style transfer**: Describe "what must stay consistent (style cues) and what must change (new content)"
- **Product extraction**: Demand "transparent background (RGBA PNG), crisp silhouette, no halos/fringing"
- **Lighting changes**: Modify "only environmental conditions" while "preserving identity, geometry, camera angle"
- **UI Mockups**: Describe the product as if it already exists. Focus on layout, hierarchy, spacing. Avoid concept art language.
- **New chat per unrelated image** to avoid style/element carryover
- **Ask model to output its generated prompt** if iterations are drifting

## Sources

- OpenAI Cookbook: https://developers.openai.com/cookbook/examples/multimodal/image-gen-1.5-prompting_guide
- Prompt Engineering Guide: https://www.promptingguide.ai/guides/4o-image-generation
- OpenAI Community Forum: https://community.openai.com/t/collection-of-gpt-4o-images-prompting-tips-issues-and-bugs/1201440
- LearnPrompting: https://learnprompting.org/blog/guide-openai-4o-image-generation
- Analytics Vidhya: https://www.analyticsvidhya.com/blog/2025/03/gpt-4o-image-generation-prompts/
- God of Prompt: https://www.godofprompt.ai/blog/chatgpt-prompts-for-image-generation
- PXZ AI: https://pxz.ai/blog/chatgpt-4o-image-prompts-2026
- Model Comparisons: https://medium.com/@inchristiely/ai-image-model-comparison-2025-midjourney-vs-chatgpt-vs-flux-vs-imagen-vs-nano-banana-9db41af5ef7a
