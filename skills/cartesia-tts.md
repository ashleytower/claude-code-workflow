---
name: cartesia-tts
category: integrations
frameworks: [nextjs, react, vite]
last_updated: 2026-01-30
version: sonic-3
---

# Cartesia TTS Integration

Ultra-low latency text-to-speech (~90ms) using Cartesia's Sonic 3 model.

## Quick Start

```bash
# No package needed - uses fetch API directly
```

## Environment Variables

```env
VITE_CARTESIA_API_KEY=sk_car_xxxxxxxxxxxxx
VITE_CARTESIA_VOICE_ID=694f9389-aac1-45b6-b726-9d9369183238  # Optional, defaults to Barbershop Man
```

## API Reference

- **Endpoint**: `https://api.cartesia.ai/tts/bytes`
- **Docs**: https://docs.cartesia.ai/api-reference/tts/bytes
- **Model**: `sonic-3` (ultra-low latency)

## Voice IDs

Voice IDs are UUIDs (36 characters with hyphens):
- `694f9389-aac1-45b6-b726-9d9369183238` - Barbershop Man (male)
- Browse voices at: https://play.cartesia.ai/

## Setup Code

### Vite/React Service

```typescript
// services/textToSpeechService.ts

const CARTESIA_API_URL = 'https://api.cartesia.ai/tts/bytes';
const CARTESIA_API_VERSION = '2025-04-16';
const CARTESIA_MODEL = 'sonic-3';
const DEFAULT_VOICE_ID = '694f9389-aac1-45b6-b726-9d9369183238'; // Barbershop Man

interface TTSResult {
  success: boolean;
  audioBlob?: Blob;
  error?: string;
}

export function getDefaultVoiceId(): string {
  const envVoiceId = import.meta.env.VITE_CARTESIA_VOICE_ID || '';
  // Cartesia voice IDs are UUIDs (36 characters with hyphens)
  if (envVoiceId && envVoiceId.length >= 30) {
    return envVoiceId;
  }
  return DEFAULT_VOICE_ID;
}

export function isTTSEnabled(): boolean {
  return !!import.meta.env.VITE_CARTESIA_API_KEY;
}

export async function convertTextToSpeech(
  text: string,
  voiceId?: string
): Promise<TTSResult> {
  if (!text || text.trim().length === 0) {
    return { success: false, error: 'Text cannot be empty' };
  }

  const apiKey = import.meta.env.VITE_CARTESIA_API_KEY || '';
  if (!apiKey) {
    return { success: false, error: 'Cartesia API key not configured' };
  }

  const targetVoiceId = voiceId || getDefaultVoiceId();

  const response = await fetch(CARTESIA_API_URL, {
    method: 'POST',
    headers: {
      'Cartesia-Version': CARTESIA_API_VERSION,
      'X-API-Key': apiKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model_id: CARTESIA_MODEL,
      transcript: text,
      voice: {
        mode: 'id',
        id: targetVoiceId,
      },
      language: 'en',
      output_format: {
        container: 'raw',
        encoding: 'pcm_s16le',
        sample_rate: 24000,
      },
      generation_config: {
        speed: 1.0, // 1.0 = normal speed
      },
    }),
  });

  if (!response.ok) {
    const errorText = await response.text().catch(() => '');
    return { success: false, error: `Cartesia API error: ${response.status} - ${errorText}` };
  }

  const audioBlob = await response.blob();
  return { success: true, audioBlob };
}
```

### Browser Audio Playback (Web Audio API)

Cartesia returns raw PCM data (16-bit signed little-endian at 24kHz). Use Web Audio API to play it:

```typescript
export async function speakText(text: string, voiceId?: string): Promise<void> {
  const result = await convertTextToSpeech(text, voiceId);

  if (!result.success || !result.audioBlob) {
    console.error('[TTS] Failed:', result.error);
    return;
  }

  // Create AudioContext at 24kHz to match Cartesia output
  const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)({
    sampleRate: 24000
  });

  // Convert raw PCM (16-bit signed LE) to Float32
  const arrayBuffer = await result.audioBlob.arrayBuffer();
  const int16 = new Int16Array(arrayBuffer);
  const float32 = new Float32Array(int16.length);
  for (let i = 0; i < int16.length; i++) {
    float32[i] = int16[i] / 32768.0;
  }

  // Create audio buffer and play
  const audioBuffer = audioContext.createBuffer(1, float32.length, 24000);
  audioBuffer.copyToChannel(float32, 0);

  const source = audioContext.createBufferSource();
  source.buffer = audioBuffer;
  source.connect(audioContext.destination);
  source.start();

  // Cleanup when done
  source.onended = () => audioContext.close();
}
```

### Voice Pipeline Integration (Base64)

When integrating with a voice pipeline that passes audio as base64:

```typescript
const playAudioChunk = async (base64String: string) => {
  // CRITICAL: Create audio context on demand (defensive)
  if (!outputContextRef.current) {
    outputContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)({
      sampleRate: 24000
    });
  }

  const ctx = outputContextRef.current;

  // Resume if suspended (browser autoplay policy)
  if (ctx.state === 'suspended') {
    await ctx.resume();
  }

  // Decode base64 to PCM
  const binaryString = atob(base64String);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }

  // Convert 16-bit PCM to Float32
  const int16 = new Int16Array(bytes.buffer);
  const float32 = new Float32Array(int16.length);
  for (let i = 0; i < int16.length; i++) {
    float32[i] = int16[i] / 32768.0;
  }

  // Create buffer and play
  const buffer = ctx.createBuffer(1, float32.length, 24000);
  buffer.copyToChannel(float32, 0);

  const source = ctx.createBufferSource();
  source.buffer = buffer;
  source.connect(ctx.destination);
  source.start();
};
```

## Gotchas

1. **Voice ID validation**: Cartesia voice IDs are UUIDs (36 chars). Validate before use:
   ```typescript
   if (voiceId.length < 30) {
     console.warn('Invalid voice ID, using fallback');
     voiceId = DEFAULT_VOICE_ID;
   }
   ```

2. **AudioContext must be created on demand**: Browser security policies may prevent early creation. Always create in response to user interaction or when audio arrives:
   ```typescript
   if (!outputContextRef.current) {
     outputContextRef.current = new AudioContext({ sampleRate: 24000 });
   }
   ```

3. **Sample rate must match**: Cartesia outputs 24kHz. Your AudioContext must also be 24kHz or audio will play at wrong speed.

4. **Browser autoplay policy**: AudioContext may be suspended. Always resume before playing:
   ```typescript
   if (ctx.state === 'suspended') {
     await ctx.resume();
   }
   ```

5. **PCM format**: Output is raw PCM, 16-bit signed little-endian. Must convert to Float32 for Web Audio API (divide by 32768).

6. **API version header**: Required header `Cartesia-Version: 2025-04-16`. Without it, requests may fail.

## Comparison to ElevenLabs

| Feature | Cartesia | ElevenLabs |
|---------|----------|------------|
| Latency | ~90ms | ~200ms |
| Output format | Raw PCM | MP3 or PCM |
| Voice IDs | UUID format | Alphanumeric (20+ chars) |
| Custom voices | Supported | Limited (quota) |
| Pricing | Per character | Credits-based |

## Testing

```typescript
// Quick test
const result = await convertTextToSpeech('Hello, this is a test.');
console.log('Audio blob size:', result.audioBlob?.size);
// Expected: ~50KB for short phrase
```

## Updates

- 2026-01-30: Initial skill created after switching from ElevenLabs (out of credits)
- Key fix: AudioContext must be created on demand, not at component mount
