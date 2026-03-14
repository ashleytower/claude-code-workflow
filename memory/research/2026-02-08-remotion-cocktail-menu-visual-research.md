# Remotion + Premium Cocktail Menu Visual Design Research

### 2026-02-08 - Remotion capabilities, cocktail visualization trends, and actionable recommendations for MTL Craft Cocktails client portal

[research] Deep dive into Remotion framework capabilities for video/animation, premium digital cocktail menu trends, and visual style options for craft cocktail catering proposals.

---

## Remotion Capabilities Summary

### Core Animation APIs
- `interpolate()` - maps input ranges to output ranges (frame-based)
- `spring()` - physics-based animation with stiffness/damping/mass
- `Easing` module - bezier, bounce, elastic, back, etc.
- `<Sequence>` - time-shift children for staggered reveals
- `<Series>` - display content sequentially
- `<Loop>` - repeat content
- `interpolateColors()` - animate between colors
- `measureSpring()` - calculate spring duration for precise timing

### 3D Integration (@remotion/three)
- `<ThreeCanvas>` wrapper syncs React Three Fiber with Remotion's useCurrentFrame()
- Import from Spline (3D web editor) directly as R3F code
- GLTF/GLB model support via useGLTF
- Video as 3D texture via @remotion/media
- Full React Three Fiber ecosystem available (drei, postprocessing, etc.)
- MeshTransmissionMaterial for glass effects
- Custom liquid shaders possible (r3f-cheers example)

### Video/Transparency
- WebM with alpha channel (VP8/VP9 + yuva420p)
- ProRes with alpha for video editing
- OffthreadVideo for embedding video content
- mixBlendMode: "screen" for compositing
- Greenscreen removal via pixel manipulation

### AI Integration (2026)
- Remotion Skills - formalized actions for AI agents
- MCP server for documentation indexing
- Claude Code can generate Remotion compositions via natural language
- remotion-media-mcp for generating images, video, music, SFX, speech, subtitles

### Player Component
- `<Player>` embeds Remotion compositions in any React app (no video file needed)
- Real-time rendering in browser
- Scrubbing, play/pause controls
- Can be used for interactive previews in web apps

## Cocktail Visual Style Comparison

| Style | Premium Feel | Performance | Difficulty | Best For |
|-------|-------------|-------------|------------|----------|
| AI-generated photography | 9/10 | High (static) | Low | Menu cards, hero images |
| Watercolor illustrations | 8/10 | High (static) | Medium (need artist) | Elegant menus, print |
| Animated SVG/Lottie | 7/10 | Excellent | Medium | Interactive micro-animations |
| Video loops (bartender) | 9/10 | Heavy (video) | Low (stock) | Hero backgrounds, atmosphere |
| 3D rendered cocktails | 10/10 | Heavy (WebGL) | High | Showcase, wow factor |
| 3D + Remotion video | 10/10 | Rendered to MP4 | High | Marketing, social media |

## 2026 Premium Bar Trends
- Technical essentialism: precision you can taste, not theatrics
- Minimalist serves at high-end bars
- Hyper-personalization (QR-coded edible films, AI menus)
- Multi-sensory cocktail tasting menus
- Experience-forward: cocktail as story, not just drink
- Dark, moody, intimate aesthetic dominates luxury bar design

## Recommendation for MTL Client Portal

### Immediate (Low Effort, High Impact)
1. AI-generated cocktail photography for menu cards (Midjourney/DALL-E)
2. Subtle CSS animations on cards (hover parallax, reveal effects)
3. Dark mode with gold/amber accents for premium feel

### Medium Term (Remotion Integration)
1. Remotion `<Player>` for animated cocktail reveal sequences on menu page
2. Spring-animated text reveals for cocktail names/descriptions
3. Animated hero banner using Remotion composition

### Ambitious (3D + Video)
1. React Three Fiber glass cocktail models with liquid shaders
2. Remotion-rendered video clips for each signature cocktail
3. Full 3D cocktail configurator with Spline models
