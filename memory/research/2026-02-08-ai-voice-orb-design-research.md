# AI Voice Assistant Orb Design Research
### 2026-02-08

## Summary
Research into modern AI chat orb designs, floating action button patterns, voice assistant animations, and premium AI assistant UIs for the MTL Craft Cocktails voice button redesign.

---

## 1. ChatGPT Voice Mode Orb

**Visual Style:**
- Full-screen breathing black/blue orb (original separate mode)
- Now integrated inline within chat (default since late 2025)
- Separate Mode still available in Settings > Voice > Separate Mode
- Orb pulsed and morphed during speech

**States:**
- Idle (null) - resting state
- Listening - audio input active
- Thinking - processing
- Talking - audio output

**Animation:** 3D WebGL orb with audio reactivity, built on Three.js

---

## 2. Google Gemini

**Visual Style:**
- Multi-color gradient system (Google's red, yellow, green, blue palette)
- Sharp nearly-opaque leading edges that diffuse at the tail
- Circle as foundational shape - conveys simplicity, harmony, comfort
- Four-color glow overlay on Android

**States:**
- Morphing fluid shapes for thinking/processing
- Rippling radial gradient for voice waves
- Pulsing gradient bars for feature icons
- Each animation has defined start and end points

**Design Philosophy:**
- "Amorphous, adaptable" - not static
- Motion is "essential guiding element"
- Gradients act as directional pointers
- Inspired by Material 3 Expressive shapes
- Circles contain and sculpt signature color gradients

**Animation Techniques:**
- CSS shape() function with keyframe morphing
- clip-path animations across 5 shape states
- Linear gradient at 135deg: blue (#217bfe, #078efb), purple (#ac87eb)
- 400% background-size with translating gradient

---

## 3. Apple Siri

**Visual Style:**
- iOS 18+: Glowing edge border around entire screen
- Classic: Waveform visualization
- New: Bubble/blob animation replacing classic waveform

**Animation Techniques:**
- SiriWave JS library (5 sin-waves with different parameters)
- Conic-gradient with custom CSS properties and blur
- CSS @property for animatable --angle property
- Rotation keyframes from 0deg to 360deg

**React Libraries:**
- react-siriwave (npm package)
- VapiBlocks Siri component (react-siriwave + Framer Motion)
  - Config: ratio:1, speed:0.2, amplitude:1, frequency:6, color:#fff
  - Width:300, height:100
  - Volume scales amplitude (x7.5 when > 0.01)
  - Speed increases when volume > 0.5 (x10)

---

## 4. Anthropic Claude Voice

**Visual Style:**
- Sound-wave icon in chat input bar
- Text key points displayed while speaking
- Five voice options: Buttery, Airy, Mellow, Glassy, Rounded
- Uses ElevenLabs for TTS
- Minimal, text-focused design (no prominent orb)

---

## 5. Pi by Inflection

**Visual Style:**
- Clean ecru background with black undulating responsive lines
- Pi's signature green color floods the interface
- Green gradient rectangles as portal metaphor
- Warm, gentle, compassionate tone reflected in design

**Voice:**
- Six voice options including British English accents
- Rich text UI with voice call animation

---

## 6. Rabbit R1

**Visual Style:**
- Hyper-minimal, clean, uncluttered
- Card-based design (RabbitOS 2) - colorful Rolodex-style
- Push-to-talk physical button
- Scroll wheel navigation

**Design Philosophy:**
- Intentional simplicity
- Voice-first with minimal visual interface
- AI-generated customizable themes (Magic Interface)

---

## 7. Perplexity

**Visual Style:**
- Dot pattern interactions for voice input
- Hold-mic tooltip with pulse animation
- Loader morphing animations
- Floating mic panel for desktop (streams queries in real-time)

**Voice Features:**
- "Hey Perplexity" wake phrase
- Streaming-first voice processing
- First spoken response within ~1 second

---

## Ready-to-Use Component Libraries

### ElevenLabs UI Orb (Best for production)
- **Tech:** Three.js + React Three Fiber + WebGL shaders
- **States:** null (idle), "listening", "thinking", "talking"
- **Props:** colors (pair), seed, agentState, volumeMode, manualInput/Output
- **Default colors:** ["#CADCFC", "#A0B9D1"]
- **Install:** `pnpm dlx @elevenlabs/cli@latest components add orb`
- **Deps:** @react-three/drei, @react-three/fiber, three

### react-ai-orb (Lightweight CSS option)
- **Tech:** Pure CSS with layered blob animations
- **Presets:** oceanDepths, galaxy, caribean, cherryBlossom, emerald, multiColor, goldenGlow
- **Props:** palette, size, animationSpeedBase, animationSpeedHue, hueRotation, blobOpacities
- **Install:** `npm i react-ai-orb`
- **Weekly downloads:** ~341

### SmoothUI Siri Orb (TailwindCSS + Motion)
- **Tech:** CSS @property for --angle, conic-gradients, backdrop-filter
- **Features:** Animated waves, glow effects, audio-reactive, prefers-reduced-motion support
- **CSS vars:** --c1, --c2, --c3, --bg, --shadow-spread, --blur-amount, --animation-duration
- **Install:** `npx smoothui-cli add siri-orb`
- **Sizes:** 64px, 128px, 192px, 256px, 320px

### VapiBlocks 3D Orb (Three.js + audio reactive)
- **Tech:** IcosahedronGeometry (radius 10, 8 subdivisions), MeshLambertMaterial, wireframe
- **Audio:** Simplex noise morphing with 4x volume amplification
- **States:** Idle (steady rotation), Active (vertex deformation), Reset

### ReactBits Orb Background
- **Tech:** Animated gradient mesh with orbiting color blobs
- **Features:** Mouse-following gradient, psychedelic mesh gradients

---

## CSS Technique Cheatsheet

### Pulse Effect
```css
@keyframes pulse {
  0% { transform: scale(1); box-shadow: 0 0 0 0 rgba(color, 0.7); }
  70% { transform: scale(1.05); box-shadow: 0 0 0 10px rgba(color, 0); }
  100% { transform: scale(1); box-shadow: 0 0 0 0 rgba(color, 0); }
}
```

### Spinning Conic Gradient
```css
@property --angle {
  syntax: "<angle>";
  inherits: false;
  initial-value: 0deg;
}
@keyframes rotate { to { --angle: 360deg; } }
.orb::before {
  background: conic-gradient(from var(--angle), #c1, #c2, #c3, #c1);
  animation: rotate 3s linear infinite;
}
```

### Breathing/Float Effect
```css
@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}
.orb { animation: float 6s ease-in-out infinite; }
```

### Glassmorphism Base
```css
.orb {
  backdrop-filter: blur(10px);
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 50%;
}
```

---

## FAB Best Practices (Material Design)

- **Size:** Default 56dp, Mini 40dp
- **Position:** 16dp from edge on mobile, 24dp on tablet/desktop
- **Placement:** Bottom-right (standard) or bottom-center (inclusive)
- **Rule:** Max 1 FAB per screen
- **Action:** Should represent THE most important action
- **Transitions:** Stay on screen if action persists, translate to new position if needed
- **Lists:** Add padding beneath so content isn't blocked

---

## Recommendation for MTL Craft Cocktails

[decision] For a voice-first bartending app, recommend:
1. **Size:** 64-72px orb, bottom-center or bottom-right
2. **Style:** Conic gradient with glassmorphism (CSS-only, no Three.js overhead)
3. **Colors:** Brand-aligned gradient pair (warm cocktail tones or cool premium blue)
4. **States:** Idle (gentle breathing + slow gradient rotation), Listening (faster pulse + brighter glow), Thinking (morphing gradient), Speaking (waveform or rapid pulse)
5. **Implementation:** SmoothUI Siri Orb pattern or custom CSS @property approach
6. **Accessibility:** Respect prefers-reduced-motion
