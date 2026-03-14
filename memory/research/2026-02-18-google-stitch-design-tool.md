# Google Stitch Design Tool - Research Findings
### 2026-02-18 - Comprehensive research on stitch.withgoogle.com

## What Stitch Is
[research] Google Labs experimental AI design tool. Powered by Gemini 2.5 (Flash for Standard, Pro for Experimental mode). Generates UI screens from text prompts or uploaded images/wireframes. Free via Google Labs with Google account.

## Prompt Engineering

### Zoom-Out-Zoom-In Framework
[pattern] Best prompt structure:
1. Context: what the product is, who uses it
2. Specific screen: goal, layout hierarchy, design constraints
3. Expectations: what the generated screen should achieve

### What Works in Prompts
[pattern] Use UI/UX keywords: "navigation bar", "call-to-action", "card layout", "grid", "stacked", "scrollable"
[pattern] Include tone/mood adjectives: "vibrant", "minimalist", "warm, inviting"
[pattern] Five-part prompt: purpose, core components, layout, style, data context
[pattern] Example: "Design a mobile dashboard for a crypto app with cards showing prices, dark theme with rounded cards, scrollable layout"

### What Breaks
[gotcha] Long prompts (5000+ chars) cause Stitch to omit components. Keep prompts focused.
[gotcha] Compound requests cause full layout recreation, breaking everything. One or two changes per prompt.
[gotcha] Stitch does NOT remember previous design unless you are extremely precise and incremental.
[gotcha] Save screenshots after successful iterations -- unexpected resets happen.

## Color / Typography / Layout Control

### Colors
[research] Stitch accepts color names ("forest green") and mood descriptions ("warm color palette").
[research] The design-md skill shows Stitch internally tracks hex codes with semantic names (e.g., "Deep Muted Teal-Navy (#294056)").
[gotcha] Color accuracy can be imprecise -- reviewer noted "faintest purple tint, almost imperceptible" when requesting specific colors.

### Typography
[research] Limited to a handful of Google Fonts selectable in the sidebar.
[research] Prompts accept descriptive language: "playful sans-serif font", "serif font for headings".
[gotcha] No custom font upload. Only Google Fonts available in the sidebar picker.

### Layout
[research] AI-determined layout. No pixel-perfect control.
[research] Sidebar controls: color palette, fonts, border radius (rounded-full, rounded-lg, rounded-none), dark/light mode toggle.
[gotcha] Editing interface is "very basic" -- limited colors, limited fonts, simple corner radius.

## Output Formats
[research] HTML + Tailwind CSS code (clean, production-usable for static UI)
[research] Figma export with Auto Layout and nested layers preserved (Standard Mode only, NOT available in Experimental Mode)
[research] Screenshots / visual previews
[research] No interactive prototypes (static screens only, no animations or micro-interactions)

## Mobile / Web Support
[research] Toggle between Mobile and Web layout modes in the UI before generation.
[research] Stitch works best for mobile app design, less effective for web.
[gotcha] No explicit 9:16 aspect ratio control found. You set "Mobile" layout mode. Exact dimensions not documented publicly.

## Iterative Design Workflow
[pattern] Generate -> Review -> Adjust prompt -> Regenerate (one screen at a time)
[pattern] Multi-select (Shift+click) to apply theme changes across multiple screens at once
[pattern] "Big Picture" command generates complete multi-screen app flows simultaneously
[pattern] Can edit individual elements: "Change primary CTA button on login screen to larger, brand primary blue"

## Modes
- Standard Mode: Gemini 2.5 Flash, fast, 350 gens/month, Figma export available
- Experimental Mode: Gemini 2.5 Pro, slower, 50 gens/month, accepts image uploads, NO Figma export

## MCP Integration
[research] Official MCP support exists at stitch.withgoogle.com/docs/mcp/setup
[research] Third-party stitch-mcp by davideast: `npx @_davideast/stitch-mcp init`
[research] MCP tools: build_site, get_screen_code, get_screen_image
[research] Auth: API key (STITCH_API_KEY), gcloud OAuth, or access token
[research] Works with Claude Code, Cursor, VS Code, Gemini CLI

## Design System (DESIGN.md via stitch-skills)
[research] The design-md skill can analyze a Stitch project and generate a DESIGN.md with:
- Visual Theme & Atmosphere
- Color Palette & Roles (name + hex + function)
- Typography Rules (family, weight, spacing)
- Component Stylings (buttons, cards, inputs)
- Layout Principles (whitespace, margins, grid)

## Limitations
[gotcha] Cannot import custom design systems or brand guidelines directly
[gotcha] No real-time collaboration features
[gotcha] No version control
[gotcha] Charts/graphs not actually generated despite prompts requesting them
[gotcha] Alignment and grouping problems common
[gotcha] Generic output without highly specific prompts
[gotcha] Privacy: disable Google model training on conversations before starting (Settings)
