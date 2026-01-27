---
name: gemini-live-api
category: integrations
frameworks: [nextjs, react]
last_updated: 2025-01-19
version: "@google/genai ^1.37.0"
---

# Gemini Live API Integration

Real-time bidirectional audio/video streaming with Google's Gemini 2.0 Flash model.

## Quick Start

Use the official `@google/genai` SDK, NOT third-party packages like `gemini-live-react`.

## Installation

```bash
npm install @google/genai
```

## Environment Variables

```env
# Get your key at: https://aistudio.google.com/app/apikey
NEXT_PUBLIC_GOOGLE_API_KEY=your-api-key-here
```

**CRITICAL**: For Vercel deployment, set the env var in Vercel Dashboard > Settings > Environment Variables.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  AudioRecorder  │────▶│  GeminiLiveClient │────▶│   AudioPlayer   │
│  (mic capture)  │     │  (WebSocket)      │     │  (playback)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                       │                        │
         └───────────────────────┼────────────────────────┘
                                 │
                      ┌──────────────────┐
                      │  useGeminiLive   │
                      │  (React Hook)    │
                      └──────────────────┘
```

## Core Files

### 1. Gemini Live Client (`lib/gemini-live-client.ts`)

```typescript
/**
 * Gemini Live API Client
 * Based on google-gemini/live-api-web-console
 */

import { GoogleGenAI, LiveServerMessage, Modality } from '@google/genai';

export interface LiveClientConfig {
  systemInstruction?: string;
  responseModalities?: Modality[];
  speechConfig?: {
    voiceConfig?: {
      prebuiltVoiceConfig?: {
        voiceName: string;
      };
    };
  };
}

export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected' | 'error';

export class GeminiLiveClient {
  private client: GoogleGenAI;
  private session: Awaited<ReturnType<GoogleGenAI['live']['connect']>> | null = null;
  private _status: ConnectionStatus = 'disconnected';
  private listeners: Map<string, Set<(...args: unknown[]) => void>> = new Map();

  constructor(apiKey: string) {
    this.client = new GoogleGenAI({ apiKey });
  }

  get status(): ConnectionStatus {
    return this._status;
  }

  on(event: string, callback: (...args: unknown[]) => void): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);
  }

  off(event: string, callback: (...args: unknown[]) => void): void {
    this.listeners.get(event)?.delete(callback);
  }

  private emit(event: string, ...args: unknown[]): void {
    this.listeners.get(event)?.forEach((cb) => cb(...args));
  }

  async connect(model: string, config: LiveClientConfig): Promise<boolean> {
    if (this._status === 'connected') {
      await this.disconnect();
    }

    this._status = 'connecting';
    this.emit('statuschange', this._status);

    try {
      this.session = await this.client.live.connect({
        model,
        config: {
          systemInstruction: config.systemInstruction,
          responseModalities: config.responseModalities || [Modality.AUDIO],
          speechConfig: config.speechConfig,
        },
        callbacks: {
          onopen: () => {
            this._status = 'connected';
            this.emit('statuschange', this._status);
            this.emit('open');
          },
          onmessage: (message: LiveServerMessage) => {
            this.handleMessage(message);
          },
          // GOTCHA: onerror receives ErrorEvent, not Error
          onerror: (event: ErrorEvent) => {
            this._status = 'error';
            this.emit('statuschange', this._status);
            this.emit('error', new Error(event.message || 'Connection error'));
          },
          onclose: () => {
            this._status = 'disconnected';
            this.emit('statuschange', this._status);
            this.emit('close');
          },
        },
      });

      return true;
    } catch (error) {
      this._status = 'error';
      this.emit('statuschange', this._status);
      this.emit('error', error);
      return false;
    }
  }

  async disconnect(): Promise<void> {
    if (this.session) {
      this.session.close();
      this.session = null;
    }
    this._status = 'disconnected';
    this.emit('statuschange', this._status);
  }

  private handleMessage(message: LiveServerMessage): void {
    // Handle audio data
    if (message.serverContent?.modelTurn?.parts) {
      for (const part of message.serverContent.modelTurn.parts) {
        if (part.inlineData?.mimeType?.startsWith('audio/')) {
          const audioData = part.inlineData.data;
          if (audioData) {
            this.emit('audio', audioData);
          }
        }
        if (part.text) {
          this.emit('text', part.text);
        }
      }
    }

    // Handle turn complete
    if (message.serverContent?.turnComplete) {
      this.emit('turncomplete');
    }

    // Handle tool calls
    if (message.toolCall) {
      this.emit('toolcall', message.toolCall);
    }

    // Handle interruption
    if (message.serverContent?.interrupted) {
      this.emit('interrupted');
    }
  }

  sendAudio(base64Audio: string): void {
    if (!this.session) return;
    this.session.sendRealtimeInput({
      media: {
        mimeType: 'audio/pcm;rate=16000',
        data: base64Audio,
      },
    });
  }

  sendImage(base64Image: string, mimeType: string = 'image/jpeg'): void {
    if (!this.session) return;
    this.session.sendRealtimeInput({
      media: {
        mimeType,
        data: base64Image,
      },
    });
  }

  sendText(text: string): void {
    if (!this.session) return;
    this.session.sendClientContent({
      turns: [{ role: 'user', parts: [{ text }] }],
      turnComplete: true,
    });
  }

  sendToolResponse(functionResponses: Array<{ id: string; response: Record<string, unknown> }>): void {
    if (!this.session) return;
    this.session.sendToolResponse({ functionResponses });
  }
}
```

### 2. Audio Recorder (`lib/audio-recorder.ts`)

```typescript
/**
 * Audio Recorder for capturing microphone input
 * Converts to 16kHz mono PCM for Gemini
 */

type AudioRecorderCallback = (base64Audio: string) => void;
type VolumeCallback = (volume: number) => void;

export class AudioRecorder {
  private stream: MediaStream | null = null;
  private audioContext: AudioContext | null = null;
  private source: MediaStreamAudioSourceNode | null = null;
  private processor: ScriptProcessorNode | null = null;
  private onDataCallback: AudioRecorderCallback | null = null;
  private onVolumeCallback: VolumeCallback | null = null;
  private recording = false;
  private sampleRate = 16000;

  constructor(sampleRate = 16000) {
    this.sampleRate = sampleRate;
  }

  onData(callback: AudioRecorderCallback): void {
    this.onDataCallback = callback;
  }

  onVolume(callback: VolumeCallback): void {
    this.onVolumeCallback = callback;
  }

  async start(): Promise<void> {
    try {
      // GOTCHA: This triggers browser permission dialog - blocks until user responds
      this.stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          sampleRate: this.sampleRate,
          channelCount: 1,
          echoCancellation: true,
          noiseSuppression: true,
        },
      });

      this.audioContext = new AudioContext({ sampleRate: this.sampleRate });
      this.source = this.audioContext.createMediaStreamSource(this.stream);

      const bufferSize = 4096;
      this.processor = this.audioContext.createScriptProcessor(bufferSize, 1, 1);

      this.processor.onaudioprocess = (event) => {
        if (!this.recording) return;

        const inputData = event.inputBuffer.getChannelData(0);

        // Calculate volume for UI feedback
        let sum = 0;
        for (let i = 0; i < inputData.length; i++) {
          sum += inputData[i] * inputData[i];
        }
        const rms = Math.sqrt(sum / inputData.length);
        const volume = Math.min(1, rms * 10);
        this.onVolumeCallback?.(volume);

        // Convert to 16-bit PCM
        const pcmData = new Int16Array(inputData.length);
        for (let i = 0; i < inputData.length; i++) {
          const s = Math.max(-1, Math.min(1, inputData[i]));
          pcmData[i] = s < 0 ? s * 0x8000 : s * 0x7fff;
        }

        // Convert to base64
        const base64 = this.arrayBufferToBase64(pcmData.buffer);
        this.onDataCallback?.(base64);
      };

      this.source.connect(this.processor);
      this.processor.connect(this.audioContext.destination);
      this.recording = true;
    } catch (error) {
      console.error('Failed to start audio recording:', error);
      throw error;
    }
  }

  stop(): void {
    this.recording = false;
    this.processor?.disconnect();
    this.source?.disconnect();
    this.stream?.getTracks().forEach((track) => track.stop());
    this.audioContext?.close();
    this.processor = null;
    this.source = null;
    this.stream = null;
    this.audioContext = null;
  }

  private arrayBufferToBase64(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
  }
}
```

### 3. Audio Player (`lib/audio-player.ts`)

```typescript
/**
 * Audio Player for Gemini response playback
 * Handles 24kHz PCM audio from Gemini
 */

export class AudioPlayer {
  private audioContext: AudioContext | null = null;
  private scheduledTime = 0;
  private isPlaying = false;
  private onPlayingChangeCallback: ((playing: boolean) => void) | null = null;
  private sampleRate = 24000; // Gemini outputs 24kHz

  onPlayingChange(callback: (playing: boolean) => void): void {
    this.onPlayingChangeCallback = callback;
  }

  async init(): Promise<void> {
    this.audioContext = new AudioContext({ sampleRate: this.sampleRate });
    this.scheduledTime = this.audioContext.currentTime;
  }

  addAudio(base64Audio: string): void {
    if (!this.audioContext) return;

    const pcmData = this.base64ToInt16Array(base64Audio);
    const floatData = new Float32Array(pcmData.length);
    for (let i = 0; i < pcmData.length; i++) {
      floatData[i] = pcmData[i] / 32768;
    }

    const buffer = this.audioContext.createBuffer(1, floatData.length, this.sampleRate);
    buffer.getChannelData(0).set(floatData);

    const source = this.audioContext.createBufferSource();
    source.buffer = buffer;
    source.connect(this.audioContext.destination);

    const currentTime = this.audioContext.currentTime;
    if (this.scheduledTime < currentTime) {
      this.scheduledTime = currentTime;
    }

    source.start(this.scheduledTime);
    this.scheduledTime += buffer.duration;

    if (!this.isPlaying) {
      this.isPlaying = true;
      this.onPlayingChangeCallback?.(true);
    }

    source.onended = () => {
      if (this.audioContext && this.audioContext.currentTime >= this.scheduledTime - 0.1) {
        this.isPlaying = false;
        this.onPlayingChangeCallback?.(false);
      }
    };
  }

  clear(): void {
    if (this.audioContext) {
      this.scheduledTime = this.audioContext.currentTime;
    }
    this.isPlaying = false;
    this.onPlayingChangeCallback?.(false);
  }

  stop(): void {
    this.clear();
  }

  close(): void {
    this.audioContext?.close();
    this.audioContext = null;
  }

  private base64ToInt16Array(base64: string): Int16Array {
    const binaryString = atob(base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    return new Int16Array(bytes.buffer);
  }
}
```

### 4. React Hook (`hooks/useGeminiLive.ts`)

```typescript
'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { GeminiLiveClient, ConnectionStatus, LiveClientConfig } from '@/lib/gemini-live-client';
import { AudioRecorder } from '@/lib/audio-recorder';
import { AudioPlayer } from '@/lib/audio-player';
import { Modality } from '@google/genai';

export interface Transcript {
  id: string;
  role: 'user' | 'model';
  text: string;
  timestamp: number;
}

export interface UseGeminiLiveOptions {
  apiKey: string;
  model?: string;
  systemInstruction?: string;
  voiceName?: string;
}

export interface UseGeminiLiveReturn {
  status: ConnectionStatus;
  isConnected: boolean;
  isConnecting: boolean;
  error: string | null;
  isSpeaking: boolean;
  isListening: boolean;
  micVolume: number;
  transcripts: Transcript[];
  streamingText: string;
  connect: () => Promise<void>;
  disconnect: () => void;
  sendText: (text: string) => void;
  sendImage: (base64Image: string, mimeType?: string) => void;
  clearTranscripts: () => void;
}

export function useGeminiLive(options: UseGeminiLiveOptions): UseGeminiLiveReturn {
  const {
    apiKey,
    model = 'models/gemini-2.0-flash-exp',
    systemInstruction = 'You are a helpful assistant.',
    voiceName = 'Aoede',
  } = options;

  const [status, setStatus] = useState<ConnectionStatus>('disconnected');
  const [error, setError] = useState<string | null>(null);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [isListening, setIsListening] = useState(false);
  const [micVolume, setMicVolume] = useState(0);
  const [transcripts, setTranscripts] = useState<Transcript[]>([]);
  const [streamingText, setStreamingText] = useState('');

  const clientRef = useRef<GeminiLiveClient | null>(null);
  const recorderRef = useRef<AudioRecorder | null>(null);
  const playerRef = useRef<AudioPlayer | null>(null);

  useEffect(() => {
    if (!apiKey) {
      setError('API key is required');
      return;
    }

    clientRef.current = new GeminiLiveClient(apiKey);
    playerRef.current = new AudioPlayer();
    recorderRef.current = new AudioRecorder();

    recorderRef.current.onData((base64Audio) => {
      clientRef.current?.sendAudio(base64Audio);
    });

    recorderRef.current.onVolume((volume) => {
      setMicVolume(volume);
      setIsListening(volume > 0.01);
    });

    playerRef.current.onPlayingChange((playing) => {
      setIsSpeaking(playing);
    });

    const client = clientRef.current;

    // GOTCHA: Event listener callbacks receive unknown[] args - cast inside
    client.on('statuschange', (newStatus) => {
      setStatus(newStatus as ConnectionStatus);
    });

    client.on('error', (err) => {
      setError((err as Error).message);
    });

    client.on('audio', (base64Audio) => {
      playerRef.current?.addAudio(base64Audio as string);
    });

    client.on('text', (text) => {
      setStreamingText((prev) => prev + (text as string));
    });

    client.on('turncomplete', () => {
      setStreamingText((text) => {
        if (text) {
          const transcript: Transcript = {
            id: Date.now().toString(),
            role: 'model',
            text,
            timestamp: Date.now(),
          };
          setTranscripts((prev) => [...prev, transcript]);
        }
        return '';
      });
    });

    client.on('interrupted', () => {
      playerRef.current?.clear();
    });

    return () => {
      recorderRef.current?.stop();
      playerRef.current?.close();
      clientRef.current?.disconnect();
    };
  }, [apiKey]);

  const connect = useCallback(async () => {
    if (!clientRef.current) return;
    setError(null);

    const config: LiveClientConfig = {
      systemInstruction,
      responseModalities: [Modality.AUDIO],
      speechConfig: {
        voiceConfig: {
          prebuiltVoiceConfig: { voiceName },
        },
      },
    };

    try {
      const success = await clientRef.current.connect(model, config);
      if (success) {
        await recorderRef.current?.start();
        await playerRef.current?.init();
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Connection failed');
    }
  }, [model, systemInstruction, voiceName]);

  const disconnect = useCallback(() => {
    recorderRef.current?.stop();
    playerRef.current?.stop();
    clientRef.current?.disconnect();
    setMicVolume(0);
    setIsListening(false);
    setIsSpeaking(false);
    setStreamingText('');
  }, []);

  const sendText = useCallback((text: string) => {
    if (!clientRef.current) return;
    const transcript: Transcript = {
      id: Date.now().toString(),
      role: 'user',
      text,
      timestamp: Date.now(),
    };
    setTranscripts((prev) => [...prev, transcript]);
    clientRef.current.sendText(text);
  }, []);

  const sendImage = useCallback((base64Image: string, mimeType = 'image/jpeg') => {
    clientRef.current?.sendImage(base64Image, mimeType);
  }, []);

  const clearTranscripts = useCallback(() => {
    setTranscripts([]);
    setStreamingText('');
  }, []);

  return {
    status,
    isConnected: status === 'connected',
    isConnecting: status === 'connecting',
    error,
    isSpeaking,
    isListening,
    micVolume,
    transcripts,
    streamingText,
    connect,
    disconnect,
    sendText,
    sendImage,
    clearTranscripts,
  };
}
```

## Usage in Page Component

```typescript
'use client';

import { useState } from 'react';
import { useGeminiLive } from '@/hooks/useGeminiLive';

export default function VoicePage() {
  const [isStarting, setIsStarting] = useState(false); // CRITICAL: Local loading state

  const apiKey = process.env.NEXT_PUBLIC_GOOGLE_API_KEY || '';

  const {
    status,
    isConnected,
    isConnecting,
    isSpeaking,
    isListening,
    error,
    transcripts,
    streamingText,
    connect,
    disconnect,
  } = useGeminiLive({
    apiKey,
    model: 'models/gemini-2.0-flash-exp',
    systemInstruction: 'You are a helpful voice assistant.',
    voiceName: 'Aoede', // Options: Aoede, Charon, Fenrir, Kore, Puck
  });

  const handleConnect = async () => {
    if (isConnected) {
      setIsStarting(false);
      disconnect();
      return;
    }

    // CRITICAL: Set loading state IMMEDIATELY for visual feedback
    setIsStarting(true);

    try {
      // Camera/mic permission dialogs will block here
      await connect();
      setIsStarting(false);
    } catch (err) {
      console.error('Connection failed:', err);
      setIsStarting(false);
    }
  };

  // Compute visual state
  const getButtonState = () => {
    if (isStarting || isConnecting) return 'connecting';
    if (isConnected && isListening) return 'listening';
    if (isConnected && isSpeaking) return 'speaking';
    if (isConnected) return 'listening';
    return 'idle';
  };

  return (
    <div>
      <button
        onClick={handleConnect}
        disabled={isStarting || isConnecting}
      >
        {getButtonState()}
      </button>

      <p>
        {isStarting && !isConnecting && 'Starting...'}
        {isConnecting && 'Connecting...'}
        {isConnected && isListening && 'Listening...'}
        {isConnected && isSpeaking && 'Speaking...'}
        {!isConnected && !isConnecting && !isStarting && 'Tap to start'}
      </p>

      {error && <p className="error">{error}</p>}

      {transcripts.map((t) => (
        <div key={t.id}>{t.role}: {t.text}</div>
      ))}

      {streamingText && <div>AI: {streamingText}</div>}
    </div>
  );
}
```

## Gotchas

### 1. No Visual Feedback on Click
**Problem**: Button click appears to do nothing while waiting for camera permission.
**Solution**: Add local `isStarting` state that's set IMMEDIATELY before async operations.

```typescript
const [isStarting, setIsStarting] = useState(false);

const handleConnect = async () => {
  setIsStarting(true); // BEFORE any await
  try {
    await connect();
  } finally {
    setIsStarting(false);
  }
};
```

### 2. TypeScript Event Callback Types
**Problem**: Event callbacks receive `(...args: unknown[])` but you need specific types.
**Solution**: Cast inside the callback, not in the signature.

```typescript
// WRONG - causes type errors
client.on('statuschange', (newStatus: ConnectionStatus) => { ... });

// RIGHT - cast inside
client.on('statuschange', (newStatus) => {
  setStatus(newStatus as ConnectionStatus);
});
```

### 3. onerror Receives ErrorEvent, Not Error
**Problem**: `onerror` callback receives `ErrorEvent`, not `Error`.
**Solution**: Create Error from event.message.

```typescript
onerror: (event: ErrorEvent) => {
  this.emit('error', new Error(event.message || 'Connection error'));
}
```

### 4. Environment Variable Not Available
**Problem**: `NEXT_PUBLIC_*` env var works locally but not in production.
**Solution**: Set it in Vercel Dashboard > Settings > Environment Variables.

### 5. Camera Permission Blocks UI
**Problem**: `getUserMedia()` blocks until user responds to permission dialog.
**Solution**: Show loading state BEFORE calling getUserMedia, not after.

### 6. Audio Sample Rates
**Input**: Gemini expects 16kHz mono PCM
**Output**: Gemini returns 24kHz mono PCM

```typescript
// Recording
const audioContext = new AudioContext({ sampleRate: 16000 });

// Playback
const audioContext = new AudioContext({ sampleRate: 24000 });
```

### 7. Third-Party Packages Are Outdated
**Problem**: Packages like `gemini-live-react` may be outdated or broken.
**Solution**: Use official `@google/genai` SDK directly.

## Available Voices

- `Aoede` (default)
- `Charon`
- `Fenrir`
- `Kore`
- `Puck`

## Available Models

- `models/gemini-2.0-flash-exp` (recommended for live)

## Testing

Browser automation (Playwright, Puppeteer) CANNOT grant camera/microphone permissions. Test manually or mock the mediaDevices API.

```typescript
// Mock for testing
Object.defineProperty(navigator, 'mediaDevices', {
  value: {
    getUserMedia: jest.fn().mockResolvedValue({
      getTracks: () => [{ stop: jest.fn() }],
    }),
  },
});
```

## Debugging

Add console.log at each step:

```typescript
console.log('[DEBUG] handleConnect called');
console.log('[DEBUG] apiKey present:', !!apiKey, 'length:', apiKey?.length);
console.log('[DEBUG] Starting camera...');
console.log('[DEBUG] Camera started, connecting to Gemini...');
console.log('[DEBUG] Gemini connection complete');
```

## Updates

- 2025-01-19: Initial skill created from Voice Translator debugging session
  - Fixed "nothing happens" bug with isStarting state
  - Documented TypeScript callback typing gotchas
  - Added proper error handling for onerror callback
