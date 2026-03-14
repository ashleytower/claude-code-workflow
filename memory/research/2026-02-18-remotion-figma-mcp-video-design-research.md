# Remotion + Figma MCP Video Design Research

## Source
Reddit post by u/propololo (Daumantas Banys, @daumantasbanys on X)
- r/ClaudeCode: https://www.reddit.com/r/ClaudeCode/comments/1r748to/
- r/vibecoding cross-post
- r/MotionDesign cross-post
- X thread: https://x.com/daumantasbanys/status/2022309419317436892
- Posted: 2026-02-13 (based on X oEmbed date)

## Product Being Demonstrated
**Slicer.dev** - Chrome extension to copy interactive web components from websites.
- Exports to React, Figma, Framer, AI prompts
- Branding: vibrant pink/magenta (#ff0066) accent, dark icons, clean modern aesthetic

## The Video
- 1920x1080, 30fps, 51 seconds, h264
- Product demo/marketing video for Slicer.dev

## Visual Design Analysis (from extracted frames)

### Color Palette
- **Background**: Very light blue-gray (#E8EDF2 or similar) -- used consistently across ALL frames
- **Primary text**: Dark charcoal/near-black for body copy
- **Accent color**: Hot pink/magenta (#FF0066) for emphasis words in headlines
- **Secondary text**: Light gray for de-emphasized/fading words
- **Cards/UI elements**: White with subtle rounded corners and soft shadows
- **Blue accent**: Bright blue (#0099FF) for the "Copying" status pill

### Typography
- Large, bold sans-serif for headlines (likely Inter or similar geometric sans)
- Two-color text pattern: key words in pink, rest in dark charcoal or light gray
- Text appears to animate word-by-word with some words highlighted
- Very large type sizes -- headlines fill roughly 40-60% of frame width

### Layout Patterns
1. **Centered single-line text on blank bg**: "design and development utility tool" with "utility" in pink
2. **Text + UI mockup combo**: Headline at top, card/list UI below (like the "AI design tools" list)
3. **Product showcase cards**: White cards with app icon, description, tags, upvote/comment counts
4. **Action demonstration**: Dimmed background with selection highlight + floating "Copying" badge
5. **Logo + text lockup**: Icon beside product name for closing branding
6. **Confetti celebration**: Multicolor confetti particles for milestone moments

### Scene Types Identified
- 0-2s: Logo intro (Slicer.dev icon centered on light blue bg)
- 5s: Kinetic text -- "design and development utility tool"
- 8s: Kinetic text -- "changes how we build websites"
- 10s: Transition -- pink shape wipe from corner
- 15s: UI mockup -- "Hover any component or section" + list of tools
- 20s: Action demo -- "click to copy" + cursor + "Copying" badge overlay
- 25s: Feature showcase -- "Figma, Framer" text + "Copy slice" button + app icons
- 30s: Competitive context -- other tool icons shown
- 35s: Celebration -- confetti + Slicer.dev card
- 40s: Interactive state -- Slicer.dev card with upvote highlighted in red
- 45s: Final product card -- clean isolated view
- 48s: Closing -- logo + "slicer.dev" text lockup

### Animation Techniques
- Word-by-word text reveals with color emphasis
- Cursor movement (pointer icon) for click demonstrations
- Fade/slide transitions between scenes
- Color wipe transition (pink arc from corner)
- Confetti particle animation
- Scale/zoom on individual UI elements
- Card highlight/selection states
- Subtle shadow depth changes

## How Figma Was Used

### Key Insight: Figma Was for FRAME DESIGN, Not Storyboarding
The author explicitly stated:
- "Design scenes in Figma (no magic wand here, did this manually to ensure the quality)"
- "I'm a product designer" (from r/vibecoding post)
- "It took +/-2 full days still, most of the time in Figma to be fair"

### What Was Designed in Figma
Each SCENE was designed as individual Figma frames. These included:
1. **UI mockup cards** (the product listing cards with icons, descriptions, stats)
2. **Typography layouts** (the headline text compositions with color highlighting)
3. **Product screenshots/recreations** (the tool interface mockups)
4. **Icon arrangements** (app icon rows, feature icons)
5. **Button/CTA designs** (the "Copy slice" button)
6. **Logo lockups** (the Slicer.dev branding)

### The Figma-to-Remotion Pipeline
1. Design individual scene compositions as Figma frames
2. Each frame has named layers that Remotion can address
3. Via Figma MCP, Claude reads the frame structure (layers, positions, colors, typography)
4. Claude generates Remotion code that recreates the layout and adds animation
5. Author described animations verbally to Claude ("describe what you want to achieve")

## Workflow Summary
1. **Script**: AI-generated (used manus.im for best results)
2. **Scene Design**: Manual Figma work (bulk of the 2-day effort)
3. **Tech Setup**: Claude Code + Remotion skill + remotion-best-practices + Figma MCP
4. **Animation**: Paste script + guidelines + Figma frame URLs one by one, describe desired animation

## Professional Reception

### r/ClaudeCode (57 upvotes, 90% upvote ratio)
- Generally positive about the workflow innovation
- Q about time: "2 full days, most in Figma"
- Discussion about marketing bottleneck for vibe-coded apps
- One commenter noted it was "quite painful to set up"
- Author acknowledged "not top-notch quality" vs pro motion designers

### r/MotionDesign (harsh professional feedback)
- "I think my career is still safe"
- "You dare post 'No motion designer needed' to this subreddit?"
- "Honestly, we feel it. Either it's made by a very bad motion designer, or by an AI."
- Specific critiques: "No speed curves, one text style animation, scale errors"
- "It's full of sloppy, careless errors"
- Professional consensus: not client-acceptable quality

## What Made It Look Better Than Generic AI Slop
1. **Consistent color palette** throughout (not random AI colors)
2. **Real UI mockups** designed by a product designer (not placeholder boxes)
3. **Branded** -- actual product branding with consistent use of the pink accent
4. **Typography hierarchy** -- large bold headlines with strategic color emphasis
5. **Clean backgrounds** -- single light color, not busy gradients
6. **Realistic product cards** -- actual UI patterns that look like a real app

## What Professionals Said Was Missing
1. **Speed curves/easing** -- animations were linear, not natural
2. **Variety in text animations** -- only one style used repeatedly
3. **Scale precision** -- sizing errors in animated elements
4. **Timing/rhythm** -- not synced to beats or natural pacing
5. **Polish details** -- the small refinements that separate amateur from professional

## Key Takeaway for Our Pipeline
The Figma step is what elevated this above pure AI-generated video. Without it, you get generic layouts. With it, you get your actual brand, your actual UI, your actual design system. The limitation was in the ANIMATION quality, not the design quality. A professional product designer's Figma frames + AI animation = decent product demo, but still recognizably AI-animated to trained eyes.
