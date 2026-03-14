# Cocktail Voice UI Redesign Research
### 2026-02-22

## Available Design Tools
- **Stitch MCP**: Generate screens from text prompts (Gemini 3 Pro/Flash), edit existing screens, mobile/desktop/tablet targets
- **MagicUI**: 150+ animated components (shadcn/ui companion) - buttons (rainbow, shimmer, shiny, pulsating, ripple), special effects (animated-beam, border-beam, shine-border, magic-card, meteors, neon-gradient-card, confetti, particles), backgrounds (warp, flickering-grid, animated-grid-pattern, retro-grid, ripple), text animations (word-rotate, flip-text, hyper-text, morphing-text, spinning-text, sparkles-text), device mocks (safari, iphone-15-pro, android)
- **Recraft**: AI image generation (logos, illustrations, vectors), image-to-image, background replacement, vectorization, custom style creation

## Voice UI Best Practices (2025-2026)
[pattern] Visual menus must work alongside voice commands. Clear labels, logical content structures, instant feedback.
[pattern] Sub-300ms feedback latency perceived as instantaneous.
[pattern] Animation durations: 200-500ms for interactions, easing: cubic-bezier(0.4, 0, 0.2, 1)
[pattern] State-based gradients: Idle=gray, Listening=emerald/teal, Processing=blue/cyan, Speaking=purple/pink, Error=red/orange, Success=green/emerald

## Premium Dark Mode Palettes
[research] Background hierarchy: Primary #0F0F0F-#1A1A1A (not pure black), Secondary #2D2D2D-#3A3A3A, Tertiary #404040-#4D4D4D
[research] WCAG AA: #ffffff on #0f0f0f = 20.5:1 ratio, #d1d5db on #0f0f0f = 9.2:1

## Glassmorphism (Trending 2025-2026)
[pattern] background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.2)
[pattern] Apple "Liquid Glass" design language announced WWDC 2025

## Audio-Reactive Orb Pattern
[pattern] Web Audio API AnalyserNode extracts frequency data. Real-time amplitude drives blob deformation. Color maps to frequency bands.
[pattern] States: Idle=4000ms breathing pulse, Listening=mic reactive, Thinking=color shift loop, Speaking=TTS reactive

## Micro-Interaction Specs
[pattern] Recording pulse ring: @keyframes pulseRing { 0%{scale(1);opacity:0.6} 100%{scale(1.4);opacity:0} } 1.5s infinite
[pattern] Message appearance: user slide-in-right 250ms, assistant fade-in 300ms, typing dots staggered 150ms/dot
[pattern] Voice button: hover scale(1.05), press scale(0.95), recording pulsing ring + dots

## Typography for Premium Voice Apps
[research] Modular scale: Major Third 1.25x ratio. Base 16px -> xs:12, sm:14, base:16, lg:20, xl:25, 2xl:31
[research] Line-height: body 1.6, headers 1.2-1.3, small text 1.4
[research] 8pt grid spacing system: 4/8/16/24/32/48/64px

## Component Recommendations
[research] ElevenLabs UI: Live Waveform, Voice Picker, Orb, Message Thread, Audio Controls (shadcn compatible)
[research] shadcn/ui: Assistant UI template, Speech Input Button, Message Thread, Dialog/Alert

## ARIA for Voice UIs
[pattern] aria-live="polite" for message updates, aria-live="assertive" for errors
[pattern] aria-pressed for toggle buttons, aria-busy for processing state
[pattern] All interactive elements must be Tab-reachable for voice navigation software compatibility

## Sources
- magicui.design/docs/components
- ui.elevenlabs.io
- digipixel.sg/dark-mode-voice-ui-and-microinteractions
- ui-deploy.com/blog/voice-user-interface-design-patterns
- designstudiouiux.com - Glassmorphism UI Trend 2026
- bubbleiodeveloper.com - Voice & Conversational UI Design Trends 2025
