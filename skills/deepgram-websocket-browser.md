---
name: deepgram-websocket-browser
category: integration
frameworks: [react, nextjs, vite]
last_updated: 2026-01-30
version: Deepgram API v1
---

# Deepgram WebSocket (Browser) Integration

Real-time speech-to-text using Deepgram's streaming API from browser JavaScript.

## Critical Gotchas

### 1. Browser WebSocket Authentication

**Problem:** Browser WebSocket APIs cannot set custom `Authorization` headers. The Deepgram SDK uses `Authorization: Token YOUR_KEY` which fails in browsers.

**Solution:** Use `Sec-WebSocket-Protocol` header instead:

```typescript
// WRONG - SDK approach (fails in browsers)
import { createClient } from '@deepgram/sdk';
const client = createClient(apiKey);
const connection = client.listen.live({...}); // Uses Authorization header

// CORRECT - Native WebSocket with Sec-WebSocket-Protocol
const ws = new WebSocket(url, ['token', apiKey]);
```

Per Deepgram docs: https://developers.deepgram.com/docs/using-the-sec-websocket-protocol

### 2. utterance_end_ms Minimum Value

**Problem:** `utterance_end_ms` must be >= 1000ms. Values below 1000 cause HTTP 400 Bad Request.

```typescript
// WRONG - causes 400 error
const params = new URLSearchParams({
  utterance_end_ms: '800',  // Below minimum!
});

// CORRECT
const params = new URLSearchParams({
  utterance_end_ms: '1000',  // Minimum 1000ms
});
```

Per Deepgram docs: "You should set the value of utterance_end_ms to be 1000 ms or higher. Deepgram's Interim Results are sent every 1 second, so using a value of less than 1 second will not offer any benefits."

### 3. React Event Handling with Browser Automation

**Problem:** Playwright/Puppeteer `.click()` may not trigger React's synthetic event system properly.

**Solution:** Call React's onClick handler directly:

```typescript
// Find React props on DOM element
const propsKey = Object.keys(button).find(k => k.startsWith('__reactProps'));
if (propsKey && button[propsKey].onClick) {
  button[propsKey].onClick();  // Directly invoke React handler
}
```

## Installation

```bash
# No SDK needed for browser - use native WebSocket
# Optionally install for Node.js server-side:
npm install @deepgram/sdk
```

## Environment Variables

```env
VITE_DEEPGRAM_API_KEY=your_40_char_hex_key
```

## Setup Code

### Browser (React/Vite/Next.js Client)

```typescript
export interface TranscriptResult {
  text: string;
  isFinal: boolean;
  confidence?: number;
  timestamp?: number;
}

export interface DeepgramConfig {
  onTranscript: (result: TranscriptResult) => void;
  onError: (error: Error) => void;
  model?: string;
  language?: string;
  punctuate?: boolean;
  interimResults?: boolean;
}

export class DeepgramTranscriber {
  private apiKey: string;
  private socket: WebSocket | null = null;
  private connected: boolean = false;

  constructor(apiKey: string) {
    if (!apiKey) throw new Error('Deepgram API key is required');
    this.apiKey = apiKey;
  }

  async connect(config: DeepgramConfig): Promise<void> {
    const params = new URLSearchParams({
      model: config.model || 'nova-2',
      language: config.language || 'en-US',
      punctuate: String(config.punctuate !== false),
      interim_results: String(config.interimResults !== false),
      smart_format: 'true',
      encoding: 'linear16',
      sample_rate: '16000',
      endpointing: '500',
      utterance_end_ms: '1000', // MUST be >= 1000
    });

    const url = `wss://api.deepgram.com/v1/listen?${params.toString()}`;

    // Browser auth via Sec-WebSocket-Protocol
    this.socket = new WebSocket(url, ['token', this.apiKey]);

    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error('Connection timeout')), 10000);

      this.socket!.onopen = () => {
        clearTimeout(timeout);
        this.connected = true;
        resolve();
      };

      this.socket!.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.type === 'Results') {
          const transcript = data.channel?.alternatives?.[0];
          if (transcript?.transcript) {
            config.onTranscript({
              text: transcript.transcript,
              isFinal: data.is_final || false,
              confidence: transcript.confidence,
              timestamp: Date.now(),
            });
          }
        }
      };

      this.socket!.onerror = () => {
        clearTimeout(timeout);
        reject(new Error('WebSocket connection failed'));
      };

      this.socket!.onclose = (event) => {
        this.connected = false;
        if (event.code === 1008) {
          config.onError(new Error('Authentication failed. Check API key.'));
        }
      };
    });
  }

  sendAudio(audioData: ArrayBuffer): void {
    if (!this.connected || this.socket?.readyState !== WebSocket.OPEN) {
      throw new Error('Not connected');
    }
    this.socket.send(audioData);
  }

  isConnected(): boolean {
    return this.connected && this.socket?.readyState === WebSocket.OPEN;
  }

  disconnect(): void {
    if (this.socket?.readyState === WebSocket.OPEN) {
      this.socket.send(JSON.stringify({ type: 'CloseStream' }));
    }
    this.socket?.close();
    this.socket = null;
    this.connected = false;
  }
}
```

### Audio Capture from Microphone

```typescript
// Get microphone stream
const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
const audioContext = new AudioContext({ sampleRate: 16000 });
const source = audioContext.createMediaStreamSource(stream);
const processor = audioContext.createScriptProcessor(4096, 1, 1);

source.connect(processor);
processor.connect(audioContext.destination);

// Send audio to Deepgram
processor.onaudioprocess = (e) => {
  const inputData = e.inputBuffer.getChannelData(0);
  const pcmData = new Int16Array(inputData.length);
  for (let i = 0; i < inputData.length; i++) {
    pcmData[i] = inputData[i] * 32768;
  }
  transcriber.sendAudio(pcmData.buffer);
};
```

## Common Parameters

| Parameter | Type | Default | Notes |
|-----------|------|---------|-------|
| model | string | nova-2 | nova-2 recommended for accuracy |
| language | string | en-US | BCP-47 language tag |
| punctuate | boolean | false | Add punctuation |
| interim_results | boolean | false | Get partial transcripts |
| smart_format | boolean | false | Formatting improvements |
| encoding | string | - | linear16 for PCM |
| sample_rate | integer | - | 16000 for 16kHz |
| endpointing | integer | - | ms of silence to finalize |
| utterance_end_ms | integer | - | **Min 1000ms** for UtteranceEnd events |

## Error Codes

| WebSocket Code | Meaning |
|----------------|---------|
| 1006 | Abnormal close (network issue or invalid request) |
| 1008 | Authentication failed (invalid API key) |
| 400 | Bad Request (invalid parameters) |

## Testing

```typescript
// Test WebSocket connection directly in browser console
const key = 'your_api_key';
const ws = new WebSocket(
  'wss://api.deepgram.com/v1/listen?model=nova-2&encoding=linear16&sample_rate=16000',
  ['token', key]
);
ws.onopen = () => console.log('Connected!');
ws.onerror = () => console.log('Failed!');
```

## Debugging

Add console logs to track connection:

```typescript
console.log('[Deepgram] WebSocket URL:', url);
console.log('[Deepgram] API key length:', apiKey.length);

this.socket.onopen = () => console.log('[Deepgram] Connected');
this.socket.onerror = (e) => console.error('[Deepgram] Error:', e);
this.socket.onclose = (e) => console.log('[Deepgram] Closed:', e.code, e.reason);
```

## Updates

- 2026-01-30: Initial skill created after fixing utterance_end_ms 400 error
