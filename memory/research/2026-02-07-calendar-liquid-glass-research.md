# Calendar + Liquid Glass UI Research

### 2026-02-07 - CRM Dashboard Calendar Redesign Libraries

## macos-calendar (npm: macos-calendar)
[research] **VERDICT: DO NOT USE**
- GitHub: github.com/macos-components/macos-calendar
- 5 stars, 0 forks, last published 6 years ago (v1.0.5)
- No explicit React version support - likely class components
- Will NOT work with React 19
- Minimal community, no maintenance

## liquid-glass-react (npm: liquid-glass-react)
[research] **VERDICT: VIABLE - Good option for glass effects**
- GitHub: github.com/rdev/liquid-glass-react (4.4k stars, 290 forks)
- Peer dependency: React >=19.0.0 and react-dom >=19.0.0
- TypeScript (95.5%), ESM + CJS output, esbuild bundler
- MIT license
- Four refraction modes: standard, polar, prominent, shader
- Props: displacementScale, blurAmount, saturation, aberrationIntensity, elasticity, cornerRadius, padding, className, overLight, onClick, mouseContainer, mode, globalMousePos
- [gotcha] Safari/Firefox: displacement NOT visible (SVG filter limitation). Chrome-only for full effect.
- [gotcha] "shader" mode is less stable
- Demo app uses Next.js 15.3.3 + Tailwind v4 (similar to our stack)
- Should work with Vite 6 (standard ESM package)

## @liquidglass/react (alternative)
[research] Another option on npm - backdrop filters + SVG displacement mapping. Less popular.

## Aceternity UI Pro
[research] **No glass-specific components**. No calendar components either.
- Project already uses "Aceternity-style" hover overlays (EventCardHover.tsx) implemented with Tailwind backdrop-blur
- Pro has: Hero Sections, Logo Clouds, Bento Grids, Feature Sections, Shaders, Backgrounds, Pricing, Navbars, Cards, CTA, Testimonials
- Glass effects are implemented via Tailwind, not Aceternity-specific components

## CSS/Tailwind Glassmorphism (existing in project)
[pattern] The crm-bento-grid.tsx already uses glassmorphism extensively:
- `backdrop-blur-md` + `bg-white/70` on the calendar month grid
- `backdrop-blur-sm` + `bg-white/80` on day cards
- `backdrop-blur-xl` + `bg-white/80` + `border-white/20` on QuickAdd modal
- `backdrop-blur-sm` on tooltips
- This is the established pattern in the codebase

## Recommendation
1. **Calendar**: Build custom with Tailwind + Framer Motion (no viable Apple Calendar library exists for React 19)
2. **Glass effects**: liquid-glass-react for hero/accent elements, CSS backdrop-filter for general glassmorphism (matches existing patterns)
3. **Fallback**: Pure Tailwind backdrop-blur (already proven in codebase) if liquid-glass-react adds too much complexity
