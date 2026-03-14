# HeyGen & ElevenLabs API Research
**Date**: 2026-02-12
**Research**: Programmatic video/audio generation APIs for avatar videos and text-to-speech

## HeyGen API

### Core Endpoints
- **Video Generation**: `POST https://api.heygen.com/v2/video/generate`
- **Status Check**: Poll for video completion status
- **Avatar List**: `GET /v2/avatars` - fetch available avatars
- **Voice List**: `GET /v2/voices` - fetch available voices

### Pricing (API-specific, not web subscription)
- **Free Trial**: Included with all HeyGen App users
- **Pro Plan**: $99/month for 100 credits (~$0.99/credit)
- **Scale Plan**: $330/month (~$0.50/credit)
- **Enterprise**: Custom pricing, unlimited/custom credits
- **Credit Measurement**: 30-second increments
  - 0-29 seconds = 0.5 credits
  - 30-59 seconds = 1.0 credit
  - 60-89 seconds = 1.5 credits
- **Example**: 15-second video = 0.5 credits ($0.50 on Pro, $0.25 on Scale)
- **Expiration**: Credits expire every 30 days

### Generation Time
- **Avatar Studio videos**: ~10 minutes per 1 minute of video (often faster)
- **15-second video**: Expect 2-3 minutes processing time
- **Priority Processing**:
  - Creator/Pro/Business: First 100 videos/month priority, then 2-36 hours
  - Enterprise: All videos get priority processing
- **Real-time option**: Streaming API available for instant generation

### Output Format
- **Format**: MP4
- **Resolution**: 720p (free API), up to 4K (paid plans)
- **Aspect Ratio**: Configurable (e.g., "16:9")
- **Dimension**: Set via `dimension` parameter

### Rate Limits
- **Pro Plan**: 3 requests per 10 seconds (18 requests/minute)
- Higher tiers: Not specified in search results

### Avatars & Customization
- **Types**: Avatar III, Avatar IV (most advanced/photorealistic)
- **Photo Avatars**: Create custom avatars from uploaded photos
- **Instant Avatars**: Available in list endpoint
- **Talking Photos**: Supported via Avatar IV

### Node.js SDK
- **Package**: `@heygen/streaming-avatar`
- **Install**: `npm i @heygen/streaming-avatar`
- **Use Case**: Real-time interactive avatars via WebRTC
- **Features**: Text-to-speech integration, event-driven architecture, session management
- **Latest Version**: 2.1.0
- **Demo**: HeyGen provides Interactive Avatar Next.js Demo on GitHub

### Code Example (Express.js)
```javascript
const express = require('express');
const fetch = require('node-fetch');
const app = express();

app.get('/api/get-access-token', async (req, res) => {
  try {
    const apiKey = process.env.HEYGEN_API_KEY;
    const response = await fetch('https://api.heygen.com/v1/streaming.create_token', {
      method: 'POST',
      headers: { 'x-api-key': apiKey },
    });
    const { data } = await response.json();
    res.json({ token: data.token });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch access token' });
  }
});

app.listen(3000);
```

### Gotchas
- [gotcha] API plans are SEPARATE from web subscriptions. You can have API access on a free web plan.
- [gotcha] Credits are measured in 30-second increments, so a 31-second video costs 1.0 credit, not 0.5.
- [gotcha] Free API plan limited to 720p exports.
- [gotcha] Streaming SDK (`@heygen/streaming-avatar`) is for real-time interactive avatars, NOT batch video generation.

---

## ElevenLabs API

### Core Endpoints
- **Text-to-Speech**: `POST /v1/text-to-speech/{voice_id}`
- **Streaming**: `POST /v1/text-to-speech/{voice_id}/stream`
- **WebSocket**: `wss://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream-input`
- **Voice List**: `GET /v1/voices`

### Pricing (Character-based)
- **Model-specific costs**:
  - Flash v2.5 / Turbo v2.5: **0.5 credits per character** (50% discount)
  - Eleven v3 / Multilingual v2: **1.0 credit per character**
  - V1 English / V1 Multilingual: **1.0 credit per character**
- **Free Plan**: Included, but no commercial usage rights
- **Paid Plans**: Commercial usage rights included
- **No API surcharge**: API is included in all plans at same character cost
- **Failed requests**: Do NOT consume credits

### Best Voices for Casual/UGC Narration
- **Aaron**: Most popular for AI/tech content, middle-aged American male, conversational tone
- **Cassidy**: Engaging and energetic, great for podcasts
- **Eryn**: Friendly and relatable, ideal for casual interactions
- **Mark**: Relaxed and laid back, suitable for non-chalant chats
- **Angela**: Raw and relatable, down to earth
- **Voice Library**: 40+ default voices + 10,000+ community voices
- **Filtering**: By category, gender, age, accent, use case

### Latency
- **Flash TTS**: 135ms time-to-first-byte (TTFB), 75ms model time
- **Turbo**: ~300ms latency
- **Older models**: Previously 2-3 seconds
- **Streaming TTS**: <500ms typical response time
- **Optimization Levels**: 0-4 (0=default, 4=max optimization, ~75% improvement)

### Output Format
- **Formats**: MP3, WAV, and others
- **Format Notation**: `codec_sample_rate_bitrate` (e.g., `mp3_22050_32` = MP3 @ 22.05kHz @ 32kbps)
- **Streaming**: Supported for all TTS, Voice Changer, and Audio Isolation APIs

### Character Limits
- **Eleven v3**: 5,000 characters per request
- **Turbo v2.5 / Flash v2.5**: 40,000 characters per request
- **Website**: 5,000 chars/generation (paid), 2,500 chars (free)

### Rate Limits
- **Concurrency**: Plan-dependent (not publicly specified)
- **Error**: 429 Too Many Requests when rate limit hit
- **Enterprise**: Higher limits available

### Node.js SDK
- **Official Package**: `@elevenlabs/elevenlabs-js` (RECOMMENDED)
- **Alternative**: `elevenlabs` or `elevenlabs-node` (community)
- **Install**: `npm install @elevenlabs/elevenlabs-js`
- **Features**: TypeScript support, streaming, full API access

### Code Example (Official SDK)
```javascript
import { ElevenLabsClient, play } from "@elevenlabs/elevenlabs-js";

const elevenlabs = new ElevenLabsClient({
  apiKey: "YOUR_API_KEY",
});

// Generate audio
const audio = await elevenlabs.textToSpeech.convert("Xb7hH8MSUJpSbSDYk0k2", {
  text: "Hello world!",
});

// Streaming
const audioStream = await elevenlabs.textToSpeech.stream("JBFqnCBsd6RMkjVDRZzb", {
  text: "This is a... streaming voice",
  modelId: "eleven_multilingual_v2",
});
```

### Models
- **Flash v2.5**: Fastest, lowest latency (135ms TTFB), 0.5 credits/char
- **Turbo v2.5**: Low latency (~300ms), 0.5 credits/char, 40k char limit
- **Eleven v3**: Most emotionally rich/expressive, 1.0 credit/char, 70+ languages, 5k char limit

### Gotchas
- [gotcha] WebSocket connections auto-close after 20 seconds of inactivity.
- [gotcha] Commercial usage rights ONLY available on paid plans. Free plan cannot monetize outputs.
- [gotcha] Latency optimization levels (0-4) must be explicitly set. Default is 0 (no optimization).
- [gotcha] Voice selection affects latency: Default voices > Synthetic > Instant Voice Clones.
- [gotcha] Conversational voice speed: 0.9-1.1x for natural feel.
- [gotcha] Flash v2.5 and Turbo v2.5 are 50% cheaper (0.5 credits/char vs 1.0).

---

## Combined Use Case: Avatar Video with Custom Narration

### Workflow
1. **Generate narration** with ElevenLabs (use Flash v2.5 for speed + cost)
2. **Upload audio** to storage (S3, Cloudinary, etc.)
3. **Create HeyGen video** with custom audio URL via `/v2/video/generate`
4. **Poll for completion** (2-3 min for 15-20 sec video)
5. **Download final MP4** from HeyGen response

### Cost Estimate (15-second video + narration)
- **ElevenLabs**: ~150 characters @ 0.5 credits/char = 75 credits (~$0.XX depending on plan)
- **HeyGen**: 15-second video = 0.5 credits = $0.50 (Pro) or $0.25 (Scale)
- **Total per video**: ~$0.50-$0.75 (excluding storage/hosting)

---

## Sources
- [HeyGen API Documentation](https://docs.heygen.com/)
- [HeyGen API Pricing](https://www.heygen.com/api-pricing)
- [HeyGen API Limits](https://docs.heygen.com/reference/limits)
- [Create Avatar Video V2](https://docs.heygen.com/reference/create-an-avatar-video-v2)
- [HeyGen Streaming Avatar SDK](https://www.npmjs.com/package/@heygen/streaming-avatar)
- [ElevenLabs Text to Speech Docs](https://elevenlabs.io/docs/overview/capabilities/text-to-speech)
- [ElevenLabs API Pricing](https://elevenlabs.io/pricing/api)
- [ElevenLabs Latency Optimization](https://elevenlabs.io/docs/developers/best-practices/latency-optimization)
- [ElevenLabs Models](https://elevenlabs.io/docs/overview/models)
- [ElevenLabs Voice Library](https://elevenlabs.io/voice-library)
- [ElevenLabs Node.js SDK](https://github.com/elevenlabs/elevenlabs-js)
