# Remotion Personalized Video Outreach Pipeline - Research Findings

**Date:** 2026-02-12  
**Task:** Research Remotion boilerplates and existing repos for personalized video outreach pipeline  
**Status:** Completed

## Executive Summary

Found multiple production-ready Remotion templates and pipelines that can accelerate our personalized video outreach system. The most valuable discoveries:

1. **Official Remotion Templates** provide battle-tested foundations
2. **GitHub Unwrapped** demonstrates large-scale personalized video generation (10,000+ users)
3. **ElevenLabs + Remotion integration** exists and is functional
4. **AI-driven video pipelines** combining multiple services are emerging
5. **Open-source avatar alternatives** to HeyGen exist (SadTalker with 13.5k stars)

## Top Boilerplate Candidates

### 1. Remotion template-prompt-to-video ⭐ BEST FOR AI PIPELINE
**URL:** https://github.com/remotion-dev/template-prompt-to-video  
**Stars:** 56  
**What it does:**
- Generates videos from text prompts end-to-end
- Uses OpenAI for script generation
- Uses ElevenLabs for TTS voiceovers
- Creates timeline.json with synchronized elements, text, and audio
- Already integrates the exact services we need

**Reusable components:**
- CLI for video generation
- Timeline architecture (elements, text, audio with timestamps)
- OpenAI + ElevenLabs integration patterns
- Slide backgrounds with transitions

**Fork strategy:** This is our best starting point. Fork and adapt for personalization props.

---

### 2. Remotion github-unwrapped-2022 ⭐ BEST FOR PERSONALIZATION ARCHITECTURE
**URL:** https://github.com/remotion-dev/github-unwrapped-2022  
**Stars:** 1,320  
**What it does:**
- Generated personalized "year in review" videos for 10,000+ GitHub users
- Fetches user data via GraphQL API
- Uses MongoDB for caching and deduplication locks
- Distributes rendering across multiple AWS Lambda regions
- Next.js frontend + Remotion backend

**Reusable architecture:**
- Data pipeline: API → MongoDB → Remotion props
- Lock mechanism to prevent duplicate renders
- Multi-region Lambda distribution for scale
- Caching layer for popular requests
- Props-based personalization pattern

**Key insight:** Separates data collection from rendering, enabling independent scaling.

---

### 3. Remotion template-next-app-dir ⭐ BEST FOR SAAS FOUNDATION
**URL:** https://github.com/remotion-dev/template-next-app-dir  
**Stars:** 119  
**What it does:**
- Next.js App Router + Remotion integration
- Includes `@remotion/player` and `@remotion/lambda`
- AWS Lambda deployment scripts included
- Configuration for programmatic rendering

**Reusable components:**
- Next.js + Remotion project structure
- Lambda deployment automation (`deploy.mjs`)
- Environment configuration patterns
- Development + production rendering workflows

---

### 4. Remotion template-tiktok ⭐ BEST FOR TEXT ANIMATIONS
**URL:** https://github.com/remotion-dev/template-tiktok  
**Stars:** 216  
**What it does:**
- Generates TikTok-style animated captions
- Uses Whisper.cpp for speech-to-text
- Batch processes videos in `public/` folder
- Supports multilingual transcription

**Reusable components:**
- Whisper.cpp integration for captions
- Caption timing synchronization
- Batch video processing script (`sub.mjs`)
- Animated text overlays

---

### 5. Remotion template-audiogram ⭐ BEST FOR DATA-DRIVEN PROPS
**URL:** https://github.com/remotion-dev/template-audiogram  
**Stars:** 243  
**What it does:**
- Creates podcast video clips with waveforms
- Props-based configuration via Studio sidebar
- Auto-generates captions from audio
- Optimized waveform rendering for long audio

**Reusable patterns:**
- Props system (`src/Root.tsx`)
- Caption/transcript handling (JSON, SRT formats)
- Asset management in `public/` folder
- Performance optimization with `useWindowedAudioData()`

---

### 6. remotion-sst ⭐ BEST FOR AWS DEPLOYMENT
**URL:** https://github.com/karelnagel/remotion-sst  
**Stars:** 25  
**What it does:**
- Deploys Remotion Lambda to AWS via SST/Pulumi
- Auto-creates Lambda functions, S3 buckets, and resources
- Type-safe resource linking
- Frontend integration with Astro (adaptable to Next.js)

**Reusable components:**
- Infrastructure-as-code for Remotion Lambda
- Resource linking pattern for frontend apps
- Deployment automation

---

### 7. elevenlabs-remotion-skill
**URL:** https://github.com/Maartenlouis/elevenlabs-remotion-skill  
**Stars:** 2  
**What it does:**
- Scene-based voiceover generation with ElevenLabs
- Character voice presets
- Timing validation for audio-video sync
- Pronunciation dictionaries

**Reusable components:**
- ElevenLabs API integration patterns
- Scene-based audio generation
- Voice preset management
- Pronunciation handling

---

## AI + Remotion Integration Findings

### ElevenLabs Integration
- **Confirmed working**: Multiple repos integrate ElevenLabs TTS with Remotion
- **Best example**: `template-prompt-to-video` uses ElevenLabs for voiceovers
- **2026 capabilities**: Eleven v3 model supports emotional direction ([whisper], [shout])
- **Video integration**: ElevenLabs offers audio-video workspace with Sora, Veo, Kling integration

### HeyGen Integration
- **No direct Remotion integration found**
- **HeyGen API examples**: 9 repos with basic API usage
- **Best example**: `Avatrix` - Next.js app with HeyGen API for avatar videos
- **Open-source alternative**: **SadTalker** (13,592 stars) - generates talking head videos from image + audio

### SadTalker as HeyGen Alternative ⭐ IMPORTANT
**URL:** https://github.com/OpenTalker/SadTalker  
**Stars:** 13,592  
**What it does:**
- Creates realistic talking head videos from single image + audio
- Open-source, self-hostable
- Production-ready API server available (`faster-SadTalker-API` - 145 stars)
- 3D motion coefficients for realistic facial animation

**Integration opportunity:**
- Replace HeyGen with SadTalker for avatar generation
- Run on our own infrastructure (no per-video API costs)
- Combine with Remotion for full video composition

---

## Remotion Official Templates Overview

**Template catalog:** https://www.remotion.dev/templates/

Key templates:
1. **template-next-app-dir** - Next.js SaaS foundation
2. **template-next-app-dir-tailwind** - Next.js + Tailwind CSS
3. **template-react-router** - React Router 7 + Lambda
4. **template-prompt-to-motion-graphics-saas** - AI-powered motion graphics
5. **template-code-hike** - Beautiful code snippet animations
6. **template-three** - React Three Fiber for 3D
7. **template-skia** - React Native Skia integration
8. **template-still** - Static image generation

---

## Data-Driven Personalization Patterns

### Input Props System
- Define props as **Zod schema** for type safety
- Edit props visually in Remotion Studio sidebar
- Pass data via `renderMedia({ inputProps: data })`
- Support for complex nested objects

### Batch Rendering from Dataset
**Documentation:** https://www.remotion.dev/docs/dataset-render

Process:
```javascript
dataset.forEach(entry => {
  renderMedia({
    composition: "MyTemplate",
    inputProps: entry,  // Pass personalization data
    outputLocation: `output/${entry.id}.mp4`
  });
});
```

### Parameterized Rendering
**Documentation:** https://www.remotion.dev/docs/parameterized-rendering

- CLI: `npx remotion render --props='{"name":"John"}'`
- Programmatic: Pass props object to rendering functions
- Metadata influence: Props can change duration, dimensions, framerate

---

## Deployment & Scaling Patterns

### Remotion Lambda Architecture
- Deploy to AWS Lambda for serverless rendering
- Multiple regions for global distribution
- S3 for asset storage and output
- Rate limiting via token rotation

### GitHub Unwrapped Scale Tactics
1. **MongoDB lock mechanism** - prevents duplicate renders
2. **Token rotation** - cycles through multiple AWS keys/regions
3. **Video caching** - stores rendered videos for repeat requests
4. **Environment variable rotation** - `AWS_KEY_1`, `AWS_KEY_2`, etc.

### SST/Pulumi Deployment
- Infrastructure-as-code for reproducibility
- Type-safe resource references
- One-command deployment
- Automatic S3 + Lambda + IAM setup

---

## Text Animation & Effects

### Community Templates
**URL:** https://github.com/reactvideoeditor/remotion-templates  
**Stars:** 69  
**Description:** Free Remotion effects & animations collection

### Typewriter Effect
**URL:** https://github.com/remotion-dev/typewriter  
**Stars:** 34  
**Description:** Basic typewriter text animation

### Code Animations
**URL:** https://github.com/remotion-dev/template-code-hike  
**Stars:** 201  
**Description:** Beautiful animated code snippets

---

## Programmatic Video Automation Pipelines

### AutoResolve
**URL:** https://github.com/HawzhinBlanca/AutoResolve  
**Stars:** 2  
**Description:** Production-ready video automation with DaVinci Resolve
- B-roll semantic indexing
- Automated cuts detection
- Multi-format rendering

### AutoWare
**URL:** https://github.com/rs0125/AutoWare  
**Stars:** 0  
**Description:** Video automation pipeline built with React Remotion

### ai-avatar-video-generation-system
**URL:** https://github.com/Awaisali36/ai-avatar-video-generation-system  
**Stars:** 6  
**Description:** n8n workflow for automated AI avatar news videos
- RSS feed → Google Gemini → HeyGen avatars
- Fully automated pipeline

---

## Key Learnings & Gotchas

### [pattern] Remotion + AI Services Integration
The `template-prompt-to-video` shows the winning pattern:
1. Generate script with LLM (OpenAI)
2. Generate voiceover with TTS (ElevenLabs)
3. Create timeline.json with synchronized elements
4. Render with Remotion

**Why this works:** Separates content generation (AI) from video composition (Remotion).

### [gotcha] HeyGen API Limitations
- No official Remotion integration examples found
- Most examples are basic API calls, not full pipelines
- Consider SadTalker (open-source) for cost savings and control

### [decision] Best Starting Point
**Fork `template-prompt-to-video`** because:
- Already integrates OpenAI + ElevenLabs
- Timeline architecture matches our needs
- CLI + programmatic rendering ready
- Just needs personalization props layer

### [research] SadTalker vs HeyGen Trade-offs
**SadTalker advantages:**
- Open-source, self-hosted (no API costs)
- 13.5k stars, production-ready
- Faster API server available
- Full control over infrastructure

**HeyGen advantages:**
- Simpler API (no infrastructure management)
- Higher quality avatars (subjective)
- Built-in CRM integrations

**Recommendation:** Start with HeyGen API for MVP, evaluate SadTalker if costs scale.

---

## Recommended Tech Stack

Based on research findings:

### Core Framework
- **Remotion 4.0** - Video rendering
- **Next.js 14+ (App Router)** - Web framework
- **TypeScript** - Type safety

### AI Services
- **OpenAI GPT-4** - Script generation
- **ElevenLabs** - Text-to-speech voiceovers
- **HeyGen API** (MVP) or **SadTalker** (scale) - Avatar videos
- **Whisper** (optional) - Speech-to-text for captions

### Infrastructure
- **Remotion Lambda** - Serverless rendering
- **AWS S3** - Asset storage and output
- **MongoDB** - Caching and deduplication
- **SST/Pulumi** - Infrastructure-as-code

### Data Pipeline
- **Zod** - Schema validation for input props
- **Supabase/PostgreSQL** - User data and render jobs
- **BullMQ/Inngest** - Job queue for batch rendering

---

## Next Steps

1. **Fork template-prompt-to-video** as foundation
2. **Add personalization layer** with Zod schemas for props
3. **Integrate HeyGen API** for avatar videos (or set up SadTalker)
4. **Set up Remotion Lambda** with SST for deployment
5. **Build data pipeline** for batch rendering from CRM data
6. **Implement caching** (MongoDB) to avoid duplicate renders
7. **Add job queue** for async rendering
8. **Test with 10-100 personalized videos** before scaling

---

## References

### Official Remotion Docs
- Templates: https://www.remotion.dev/templates/
- Parameterized rendering: https://www.remotion.dev/docs/parameterized-rendering
- Dataset render: https://www.remotion.dev/docs/dataset-render
- Input props: https://www.remotion.dev/docs/terminology/input-props

### Key Repositories
- template-prompt-to-video: https://github.com/remotion-dev/template-prompt-to-video
- github-unwrapped-2022: https://github.com/remotion-dev/github-unwrapped-2022
- remotion-sst: https://github.com/karelnagel/remotion-sst
- SadTalker: https://github.com/OpenTalker/SadTalker

### Community Resources
- Remotion Discord: https://remotion.dev/discord
- Awesome Personalized Video Creation: https://github.com/inFaaa/Awesome-Personalized-Video-Creation
