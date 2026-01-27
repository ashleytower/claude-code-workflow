---
name: voice-first-stack
category: integration
frameworks: [python, fastapi, nextjs, livekit, railway, vercel]
last_updated: 2026-01-26
version: LiveKit Agents 1.3+ | Deepgram Nova-3 | Cartesia Sonic 3
---

# Voice-First Application Stack

Complete stack for building voice-controlled applications with real-time bidirectional audio.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        WEB CLIENT (Vercel)                       │
│  Next.js + LiveKit React SDK                                    │
│  - Fetches room token from backend                              │
│  - Connects to LiveKit room                                     │
│  - Bidirectional audio (user speaks ↔ agent responds)           │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ WebSocket/WebRTC
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LIVEKIT CLOUD                                 │
│  - Room management                                              │
│  - Audio routing                                                │
│  - WebRTC infrastructure                                        │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ LiveKit Agents Protocol
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│               VOICE AGENT SERVICE (Railway)                      │
│  Python + LiveKit Agents Framework                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ Deepgram    │  │ Claude LLM  │  │ Cartesia    │             │
│  │ STT (Nova-3)│→ │ (Sonnet 4)  │→ │ TTS (Sonic) │             │
│  │ $0.004/min  │  │ $0.01-02/m  │  │ $0.005/min  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                          │                                      │
│                          ▼                                      │
│                   Function Tools                                │
│                   (query_inventory, etc.)                       │
└─────────────────────────────────────────────────────────────────┘
                                │
                                │ REST/MCP
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  API SERVICE (Railway)                           │
│  FastAPI + MCP Server                                           │
│  - Token generation endpoint                                    │
│  - REST API endpoints                                           │
│  - VAPI webhook compatibility                                   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                   DATA LAYER                                     │
│  Google Sheets (primary) | Supabase (optional auth/sync)        │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. LiveKit Cloud Setup

```bash
# 1. Create account at https://cloud.livekit.io
# 2. Create a new project
# 3. Get credentials from Settings → API Keys
```

Environment variables:
```env
LIVEKIT_URL=wss://your-project.livekit.cloud
LIVEKIT_API_KEY=APIxxxxxxxx
LIVEKIT_API_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 2. STT/TTS Provider Setup

**Deepgram** (STT - Speech to Text):
```bash
# 1. Create account at https://console.deepgram.com
# 2. Create API key
```

**Cartesia** (TTS - Text to Speech):
```bash
# 1. Create account at https://play.cartesia.ai
# 2. Get API key from dashboard
```

```env
DEEPGRAM_API_KEY=xxxxxxxxxxxxxxx
CARTESIA_API_KEY=xxxxxxxxxxxxxxx
CARTESIA_VOICE_ID=694f9389-aac1-45b6-b726-9d9369183238  # Default voice
ANTHROPIC_API_KEY=sk-ant-xxxxxxx  # For Claude LLM
```

### 3. Backend Voice Agent (Python)

```bash
# Install dependencies
pip install "livekit-agents[anthropic,deepgram,cartesia,silero]~=1.3"
```

**Basic Agent Structure:**
```python
# livekit_agent.py
import os
from dataclasses import dataclass
from livekit.agents import (
    Agent, AgentServer, AgentSession, JobContext,
    RunContext, cli, function_tool, ToolError
)
from livekit.plugins import anthropic, deepgram, cartesia, silero

@dataclass
class ConversationState:
    """Track conversation state across tool calls"""
    last_item_discussed: str = ""
    business_name: str = "My Business"

class MyVoiceAgent(Agent):
    """Voice agent with function tools"""

    def __init__(self):
        super().__init__(instructions=self._get_system_prompt())
        # Initialize your business logic here

    def _get_system_prompt(self) -> str:
        return """You are a voice assistant. Keep responses brief and conversational.

VOICE OUTPUT RULES:
- Maximum 2-3 sentences per response
- Use natural speech (say "five" not "5")
- Confirm actions immediately ("Done. Added to list")
- If listing items, max 5 then "and X more"
"""

    @function_tool()
    async def my_tool(
        self,
        context: RunContext[ConversationState],
        parameter: str
    ) -> str:
        """
        Tool description for the LLM.

        Args:
            parameter: What this parameter does
        """
        try:
            result = do_something(parameter)
            context.userdata.last_item_discussed = parameter
            return f"Done. {result}"
        except Exception as e:
            raise ToolError(f"Failed: {e}")

def create_agent_session(ctx: JobContext) -> AgentSession:
    """Factory for creating agent sessions"""
    return AgentSession(
        agent=MyVoiceAgent(),
        stt=deepgram.STT(model="nova-3"),
        llm=anthropic.LLM(model="claude-sonnet-4-20250514"),
        tts=cartesia.TTS(
            model="sonic-3",
            voice=os.getenv("CARTESIA_VOICE_ID", "694f9389-aac1-45b6-b726-9d9369183238")
        ),
        vad=silero.VAD.load(),
        userdata_type=ConversationState,
    )

if __name__ == "__main__":
    server = AgentServer(create_agent_session)
    cli.run_app(server)
```

### 4. Token Endpoint (FastAPI)

```python
# simple_api.py
from fastapi import FastAPI, HTTPException
from livekit import api
import os
import time

app = FastAPI()

@app.get("/api/livekit/token")
async def get_livekit_token():
    """Generate a LiveKit room token for voice agent connection."""
    api_key = os.getenv("LIVEKIT_API_KEY")
    api_secret = os.getenv("LIVEKIT_API_SECRET")
    livekit_url = os.getenv("LIVEKIT_URL")

    if not all([api_key, api_secret, livekit_url]):
        raise HTTPException(500, "LiveKit credentials not configured")

    timestamp = int(time.time())
    room_name = f"voice-{timestamp}"
    participant_name = f"user-{timestamp}"

    token = (
        api.AccessToken(api_key, api_secret)
        .with_identity(participant_name)
        .with_name("User")
        .with_grants(api.VideoGrants(
            room_join=True,
            room=room_name,
            can_publish=True,
            can_subscribe=True,
            can_publish_data=True,
        ))
    )

    return {
        "success": True,
        "serverUrl": livekit_url,
        "token": token.to_jwt(),
        "roomName": room_name,
        "participantName": participant_name
    }
```

### 5. Web Client (Next.js)

```bash
# Install LiveKit React SDK
cd web-client
npm install @livekit/components-react livekit-client
```

**Voice Component:**
```tsx
// components/voice/livekit-voice.tsx
"use client";

import { useState, useCallback } from "react";
import {
  LiveKitRoom,
  RoomAudioRenderer,
  useVoiceAssistant,
  BarVisualizer,
} from "@livekit/components-react";
import "@livekit/components-styles";

interface VoiceAgentProps {
  onClose: () => void;
}

function VoiceAgent({ onClose }: VoiceAgentProps) {
  const { state, audioTrack } = useVoiceAssistant();

  return (
    <div className="voice-agent">
      <div className="status">{state}</div>
      <BarVisualizer trackRef={audioTrack} />
      <RoomAudioRenderer />
      <button onClick={onClose}>End Call</button>
    </div>
  );
}

export function LiveKitVoice() {
  const [token, setToken] = useState<string | null>(null);
  const [serverUrl, setServerUrl] = useState<string | null>(null);
  const [isConnecting, setIsConnecting] = useState(false);

  const connect = useCallback(async () => {
    setIsConnecting(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/livekit/token`);
      const data = await res.json();
      if (data.success) {
        setToken(data.token);
        setServerUrl(data.serverUrl);
      }
    } catch (error) {
      console.error("Failed to get token:", error);
    }
    setIsConnecting(false);
  }, []);

  const disconnect = useCallback(() => {
    setToken(null);
    setServerUrl(null);
  }, []);

  if (!token || !serverUrl) {
    return (
      <button onClick={connect} disabled={isConnecting}>
        {isConnecting ? "Connecting..." : "Start Voice"}
      </button>
    );
  }

  return (
    <LiveKitRoom
      serverUrl={serverUrl}
      token={token}
      connect={true}
      audio={true}
      video={false}
    >
      <VoiceAgent onClose={disconnect} />
    </LiveKitRoom>
  );
}
```

## Railway Deployment

### Two Services Pattern (Recommended)

**Service 1: API Server**
- Entry: `python main.py` or `uvicorn simple_api:app`
- Handles: Token generation, REST API, webhooks
- Resources: 512MB RAM, 0.5 CPU

**Service 2: Voice Agent**
- Entry: `python livekit_agent.py`
- Handles: Voice pipeline (STT → LLM → TTS)
- Resources: 1GB RAM, 1 CPU

### Shared Environment Variables

Both services need these vars. In Railway:
1. Go to project → Shared Variables
2. Add variable
3. Click "ADD" on EACH service to enable

**CRITICAL GOTCHA**: Adding to "Shared" does NOT automatically add to services. You MUST click the "ADD" button on each service.

```env
# LiveKit
LIVEKIT_URL=wss://xxx.livekit.cloud
LIVEKIT_API_KEY=xxx
LIVEKIT_API_SECRET=xxx

# Voice Providers
DEEPGRAM_API_KEY=xxx
CARTESIA_API_KEY=xxx
ANTHROPIC_API_KEY=xxx

# Data
GOOGLE_SHEETS_ID=xxx
GOOGLE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
```

### Railway Files

```toml
# nixpacks.toml - Force Python build
providers = ["python"]
```

```json
// railway.json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {"builder": "NIXPACKS"},
  "deploy": {
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

## Vercel Deployment (Frontend)

```json
// vercel.json
{
  "framework": "nextjs",
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {"key": "X-Content-Type-Options", "value": "nosniff"},
        {"key": "X-Frame-Options", "value": "DENY"}
      ]
    }
  ]
}
```

```env
# .env.local
NEXT_PUBLIC_API_URL=https://your-api.railway.app
NEXT_PUBLIC_LIVEKIT_URL=wss://your-project.livekit.cloud
```

## Cost Breakdown

| Provider | Rate | Typical Usage |
|----------|------|---------------|
| Deepgram Nova-3 | $0.0043/min | STT |
| Cartesia Sonic 3 | $0.005/min | TTS |
| Claude Sonnet 4 | ~$0.01-0.02/min | LLM |
| LiveKit Cloud | Free 50hr/mo, then $0.02/min | Infrastructure |
| **Total** | **~$0.03-0.05/min** | |

Compare to VAPI: $0.05-0.10/min (40-50% savings)

## Voice Response Best Practices

### DO
- Keep responses under 3 sentences
- Use natural speech ("eight bottles" not "8")
- Confirm actions immediately ("Done. Added.")
- Truncate lists ("Vodka, Gin, Rum, and 3 more")

### DON'T
- Use markdown, JSON, or formatting
- Say numbers as digits
- Give long explanations
- List more than 5 items

### Number Conversion Helper

```python
def number_to_words(n: int) -> str:
    """Convert numbers 0-20 to words for natural speech"""
    words = [
        "zero", "one", "two", "three", "four", "five",
        "six", "seven", "eight", "nine", "ten", "eleven",
        "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
        "seventeen", "eighteen", "nineteen", "twenty"
    ]
    return words[n] if 0 <= n <= 20 else str(n)
```

## Debugging Checklist

### Agent Can't Hear User
1. [ ] Check DEEPGRAM_API_KEY is set in Railway
2. [ ] Verify LiveKit room created (check LiveKit dashboard)
3. [ ] Check browser microphone permissions
4. [ ] Verify token endpoint returns valid JWT

### Agent Responds But No Audio
1. [ ] Check CARTESIA_API_KEY is set
2. [ ] Verify CARTESIA_VOICE_ID is valid
3. [ ] Check browser audio permissions
4. [ ] Add `<RoomAudioRenderer />` to React component

### Token Endpoint Returns 404
1. [ ] Verify which server Railway is running (main.py vs simple_api.py)
2. [ ] Check endpoint is defined in the correct server file
3. [ ] Redeploy after adding endpoint

### Agent Returns Wrong Data
1. [ ] Check GOOGLE_SHEETS_ID shows "ADDED" (not "ADD") in Railway
2. [ ] Verify GOOGLE_SERVICE_ACCOUNT_JSON is set
3. [ ] Check Railway logs for "Google Sheets authenticated"
4. [ ] Verify latest commit SHA matches deployment

## Migration from VAPI

If migrating from VAPI:

1. **Keep VAPI webhook endpoint** for backwards compatibility
2. **Add LiveKit endpoints** alongside existing API
3. **Update web client** to use LiveKit instead of VAPI web embed
4. **Test both paths** before removing VAPI

```python
# Keep legacy VAPI endpoint working
@app.post("/vapi-functions")
async def handle_vapi_function(request: Request):
    # Legacy VAPI handler
    ...

# Add new LiveKit endpoints
@app.get("/api/livekit/token")
async def get_livekit_token():
    # New LiveKit token endpoint
    ...
```

## Dependencies

### Backend (requirements.txt)
```txt
livekit-agents[anthropic,deepgram,cartesia,silero]>=1.3.0
fastapi>=0.109.0
uvicorn>=0.27.0
python-dotenv>=1.0.0
livekit-api>=0.6.0
```

### Frontend (package.json)
```json
{
  "dependencies": {
    "@livekit/components-react": "^2.0.0",
    "livekit-client": "^2.0.0"
  }
}
```

## Monitoring

### LiveKit Dashboard
- Room analytics (join rates, durations)
- Audio quality metrics
- Error rates

### Recommended Logging
```python
import logging
logger = logging.getLogger(__name__)

# Log tool calls
@function_tool()
async def my_tool(self, context, param):
    logger.info(f"Tool called: my_tool({param})")
    result = do_work(param)
    logger.info(f"Tool result: {result}")
    return result
```

---

*Updated 2026-01-26: Created from cocktail-inventory-mcp project learnings*
