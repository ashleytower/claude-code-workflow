# AI-Generated Visuals for Short-Form Marketing Videos — Deep Research

**Date:** 2026-02-18
**Context:** Research for mirror-pipeline personalized outreach videos (27-second, 4-scene structure)

## Summary

Static AI images are fine but AI video backgrounds are the 2026 move. The biggest anti-pattern is the "stock photo look" — overly polished, plastic skin, uniform lighting. The fix is imperfection: film grain, weathered textures, specific camera/lens references, and candid compositions. For the 4-scene video structure (hook/demo/result/CTA), each scene needs a distinct color temperature and energy level.

---

## 1. Flux Kontext Prompting (Best Practices)

### Official Docs: docs.bfl.ai/guides/prompting_guide_kontext_i2i

**Core rules:**
- 512 token max per prompt
- Focus on what to CHANGE, not what to keep
- Use exact descriptors, not vague terms
- Start simple, build up complexity
- Name subjects directly (not "her" — say "the woman with short black hair")
- Use quotation marks for text changes

**Best structure:** Subject + Action + Style + Context

**For background scenes specifically:**
- "Change the background to [specific setting] while keeping the person in the exact same position, scale, and pose"
- State emotional tone: "serene, contemplative" or "tense, dramatic"
- Name the exact style: "impressionist painting" not "make it artistic"

**[gotcha] Flux Kontext does NOT support negative prompts.** Describe what you want positively.

---

## 2. FLUX.2 Prompting (Text-to-Image)

### Official Docs: docs.bfl.ml/guides/prompting_guide_flux2

**Formula:** Main subject -> Key action -> Critical style -> Essential context -> Secondary details

**Prompt length sweet spot:** 30-80 words (medium)

**JSON structured prompting for complex scenes:**
```json
{
  "scene": "dimly lit bar after closing time",
  "subjects": [{"description": "exhausted bar owner", "position": "center", "action": "counting inventory"}],
  "style": "cinematic, documentary feel",
  "lighting": "single overhead pendant lamp, warm tungsten",
  "mood": "overwhelmed, isolated",
  "camera": {"angle": "slightly above eye level", "lens": "35mm", "depth_of_field": "shallow"}
}
```

**Supports hex color codes:** "The background is hex #1a1a2e" for brand consistency

**Key style references that work:**
- Modern Digital: "shot on Sony A7IV, clean sharp, high dynamic range"
- Analog Film: "shot on Kodak Portra 400, natural grain, organic colors"
- 80s Vintage: "film grain, warm color cast, soft focus"
- 2000s Digicam: "early digital camera, slight noise, flash photography"

---

## 3. GPT-4o Image Generation (via Kie.ai)

**Formula:** Style + Subject + Details + Mood

**Camera terms that elevate results:**
- "Close-up shot, soft focus, studio lighting"
- "Wide-angle shot, cinematic style, natural light"
- "Over-the-shoulder, dramatic contrast"

**Color palette specification:** "warm amber tones" / "cool technology blues" / "muted earth palette"

**Style anchoring:** Reference real-world aesthetics:
- "Make it look like a vintage magazine advertisement"
- "Documentary photography style, candid"
- "Editorial portrait, Vanity Fair aesthetic"

---

## 4. AI Video vs Static Images for Backgrounds

### Verdict: Use AI video backgrounds for hook and result scenes. Static is acceptable for demo/CTA.

**Why video backgrounds win:**
- 95% message retention with video vs 10% with text
- 25-30% reply rates for personalized video (6x higher than text)
- 300% higher click-through rates vs standard emails
- 3x higher engagement in email/LinkedIn outreach

**What works for background video:**
- Subtle motion: gentle pans, slight parallax, minor rotations
- Seamless loops (Kling supports "loop" keyword in prompt)
- 5-second clips that loop for each scene
- DO NOT over-animate — subtle beats aggressive

**Best tools via Kie.ai:**
- **Veo 3.1:** Best for coherent long-form, 1080p, integrated audio
- **Kling 2.1:** Best for motion realism, background coherence, atmospheric sequences
- **Wan 2.5:** Best for image-to-video with native audio sync

### Image-to-Video Workflow (Recommended)
1. Generate high-quality still with Flux/GPT-4o
2. Use Kling or Wan to add subtle motion (5-second loop)
3. Prompt the video model for MOTION ONLY: "gentle ambient movement, slight camera drift, atmospheric particles floating"

---

## 5. Veo 3.1 Prompting (Video)

### Master Template:
"[Camera move + lens]: [Subject] [Action & physics], in [Setting + atmosphere], lit by [Light source]. Style: [Texture/finish]. Audio: [Dialogue/SFX/ambience]."

**Key rules:**
- Specify camera: 16mm (expansive), 35mm (neutral), 85mm (intimate)
- Use force-based verbs: push, pull, sway, ripple, spiral
- One dominant motion per clip
- Avoid exact numbers: "a small group" not "five people"
- Keep dialogue under 8 seconds per clip
- Use "Negative:" at end to block unwanted elements

**Example for marketing background:**
"Camera locked at eye level. Slow forward push on a 35mm lens. A busy restaurant kitchen during peak hours, steam rising from multiple stations, warm tungsten overhead lights with cool blue from the walk-in cooler door. Style: documentary, fine texture, no gloss. Audio: ambient kitchen sounds, distant plate clatter, muffled conversation."

---

## 6. Wan 2.5 Prompting (Image-to-Video)

**Formula:** [Scene Description] + [Subject Action] + [Camera Movement] + [Audio/Dialogue]

**Key for backgrounds:**
- The source image establishes subject, scene, style
- Prompt focuses on DESIRED MOTION and CAMERA MOVEMENT
- "Camera push", "camera left shift", "fixed camera"
- Keep dialogue concise within 5-second clips
- Sound descriptions influence visual generation
- Use high-res, centered subject, minimal text as input

---

## 7. What Makes AI Visuals Look BAD (Anti-Patterns)

### The "Stock Photo" Tells:
1. **Plastic skin** — overly smooth, poreless, airbrushed
2. **Perfect symmetry** — faces, compositions that are too balanced
3. **Uniform lighting** — flat, even illumination everywhere
4. **Over-saturation** — colors too vivid, too punchy
5. **Generic composition** — centered subject, blurred background, no story
6. **Text artifacts** — misspelled or garbled text
7. **Physics violations** — shadows pointing wrong, objects floating
8. **The sheen** — everything looks slightly glossy/wet

### Specific Keywords That Make Images WORSE:
- "beautiful" (triggers generic beauty)
- "perfect" (triggers uncanny symmetry)
- "professional photo" alone (too vague, defaults to stock)
- "high quality" alone (same problem)
- "4K" or "8K" alone without other descriptors

---

## 8. What Makes AI Visuals Look GREAT (The Fix)

### The 7 Realism Keywords (from Promptaa):

1. **Photographic style:** "shot on Nikon Z9 with 50mm f/1.4, studio lighting, subtle rim-light"
2. **Natural imperfections:** "weathered face, slight asymmetry, natural skin texture, candid expression"
3. **Environmental context:** "afternoon light streaming through dusty windows, music sheets scattered, lived-in atmosphere"
4. **Material specificity:** "full-grain brown leather with visible grain texture, cracked seams"
5. **Candid moments:** "genuine laughter, leaves mid-air, natural gesture, shallow depth of field"
6. **Film references:** "35mm film, shot on Leica M6, Ilford HP5, high grain, raw and atmospheric"
7. **Quality anchors:** "trending on 500px, incredibly detailed, sharp focus"

### The Transformation Formula:
**BAD:** "Close-up portrait of a man, 8K"
**GOOD:** "A hyper-realistic close-up portrait of a man in his late 30s, shot with an 85mm f/1.8 lens. Soft, natural window light from the side creates subtle shadows revealing hyper-detailed skin texture with visible pores and slight imperfections. A few stray hairs fall across his forehead. He wears a dark cotton shirt with faint creases and visible fabric texture. Softly blurred background. Subtle film grain. 8K quality."

### Micro-Details That Sell Realism:
- Dust particles in light beams
- Fingerprints on reflective surfaces
- Uneven stitching on fabric
- Chipped paint, worn wood
- Stray hairs, slight under-eye circles
- Steam, condensation, breath in cold air

---

## 9. Color Psychology for Scene Design

### Hook Scene (Pain Point): Warm stress colors
- **Colors:** Amber, warm red, harsh tungsten yellow
- **Effect:** Creates urgency, discomfort, tension
- **Lighting:** Harsh overhead, single source, dramatic shadows
- Example: "Warm tungsten overhead light casting harsh shadows, amber and brown palette"

### Demo Scene (Solution): Cool trust colors
- **Colors:** Blue, teal, white
- **Effect:** Trust, clarity, professionalism
- **Lighting:** Clean, balanced, modern
- Example: "Cool blue-white lighting, clean modern aesthetic, technology blue palette"

### Result Scene (Success): Green/gold prosperity
- **Colors:** Green, gold, warm sunshine
- **Effect:** Growth, success, relief
- **Lighting:** Golden hour, warm and inviting
- Example: "Golden hour natural light streaming in, warm and inviting, success and relief"

### CTA Scene (Action): High-contrast action colors
- **Colors:** Orange, bright green, high contrast
- **Effect:** Drives immediate action
- **Lighting:** Clean and bold
- Note: Orange/red CTAs boost conversions 21% over green (HubSpot)

---

## 10. Specific Prompts for Our 4-Scene Video Structure

### Scene 1: Hook (Bar Owner Pain Point)
**Static image prompt (Flux):**
"Documentary-style photograph, exhausted bar owner in his 40s alone behind the bar counter at 2am, manually counting liquor bottles with a clipboard, harsh single overhead pendant lamp casting dramatic shadows, amber tungsten light, bottles in soft focus background, worn wooden bar surface with scratches and water rings, tired expression with visible under-eye circles, shot on 35mm f/2.0, shallow depth of field, muted warm palette, candid moment, photojournalistic feel"

**Video motion prompt (Kling/Wan):**
"Slow subtle push-in, fixed camera with slight drift, ambient bar atmosphere, gentle flickering of pendant light, steam rising from coffee cup on counter, distant street sounds through window"

### Scene 2: Demo (Product Showcase)
**Static image prompt (Flux):**
"Clean modern UI dashboard mockup on a tablet screen, inventory management interface with clear data visualization, placed on a clean light wood desk, soft balanced side lighting, technology blue and white color palette, professional product photography style, shot on Sony A7IV with 50mm lens, clean but not sterile, subtle desk texture visible, hex #0066CC accent color"

### Scene 3: Result (Success/Relief)
**Static image prompt (Flux):**
"Candid documentary photograph, confident bar owner in his 40s smiling while reviewing inventory on a tablet, bustling successful bar in background with happy customers in soft bokeh, golden hour warm light streaming through windows, the same person from scene 1 but now relaxed and confident, warm gold and green color palette suggesting prosperity, shot on Kodak Portra 400, natural film grain, 85mm f/1.8 lens creating beautiful background separation"

**Video motion prompt (Kling/Wan):**
"Gentle camera drift to the right, subtle parallax with background movement, warm ambient sounds of a busy successful bar, natural movement of background customers"

### Scene 4: CTA (Call to Action)
**Static image prompt (Flux):**
"Bold clean marketing graphic, dark gradient background hex #1a1a2e to hex #0d0d1a, centered text area for overlay, subtle abstract geometric shapes in brand color, professional minimalist design, high contrast, clean and intentional with space for text overlay, premium technology feel"

---

## 11. Key Decisions & Recommendations

1. **Use image-to-video pipeline** (not pure text-to-video) for backgrounds — more controllable
2. **Hook and Result scenes** benefit most from video motion (emotional scenes)
3. **Demo and CTA scenes** can stay static (informational scenes)
4. **Always specify a real camera/lens** in prompts to avoid stock-photo look
5. **Use film stock references** (Kodak Portra 400, Fuji Pro 400H) for warmth
6. **Add imperfection keywords** to every prompt: weathered, worn, slight asymmetry, natural texture
7. **Color-code scenes** using psychology: warm stress -> cool trust -> gold success -> high-contrast action
8. **9:16 vertical format** for all backgrounds (mobile-first, short-form video)
9. **Loop video backgrounds** at 5 seconds each for the 27-second video
10. **Test both Flux and GPT-4o** for each scene — they have different strengths
