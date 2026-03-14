### 2026-03-11 - VAPI vs Twilio vs Alternatives for Travel Voice Agent

[research] Comprehensive comparison for building AI voice agent that calls restaurants/hotels in local languages on behalf of English-speaking travelers.

## Context
Travel-App already has a Twilio + Gemini bridge server (`server/bridge-server.ts`) on Railway. It supports 9 languages (ja, ko, zh, th, vi, es, fr, it, de) but has TODO stubs where Gemini Live API audio streaming should go. The existing implementation uses Twilio Media Streams + WebSocket but audio processing is not wired up.

VAPI MCP is connected with 2 assistants, 2 phone numbers, and 10 tools already configured.

## VAPI (vapi.ai)
- **What**: Full-stack voice AI platform. Handles STT + LLM + TTS + telephony in one API.
- **Pricing**: $0.05/min platform fee + vendor costs. True all-in cost ~$0.14-0.33/min depending on providers.
  - Deepgram STT: ~$0.0043/min
  - ElevenLabs TTS: ~$0.024/min
  - LLM (Claude/GPT-4): ~$0.045-0.10/min
  - Telephony: ~$0.013/min (uses Twilio under the hood)
- **Multilingual**: Depends on STT/TTS provider choice.
  - Deepgram Nova 2/3 with "multi" setting: auto-detects 100+ languages
  - Google STT with "multilingual": 125+ languages
  - Azure TTS: 400+ voices in 140+ languages (best for Asian languages)
  - ElevenLabs: 30+ languages
- **Latency**: ~465ms achievable with optimization, default can be 1.5s+
- **Live monitoring**: YES - listenUrl provides WebSocket audio stream, controlUrl allows injecting messages
- **Outbound calls**: YES - /call endpoint, can specify assistant + destination number
- **Key advantage**: Already connected via MCP. Could create assistant + make call in minutes.
- **Key risk**: Free numbers can't make international calls. Need imported number for Asian destinations.

## Twilio (DIY approach)
- **What**: Telephony API. You wire up STT + LLM + TTS yourself.
- **Current state**: Bridge server exists but audio processing TODOs not implemented.
- **ConversationRelay**: New product (beta since Nov 2024) that handles STT/TTS pipeline over WebSocket. You provide the LLM.
- **Pricing (telephony only)**:
  - US calls: $0.013-0.014/min
  - Japan landline: $0.0746/min, Japan mobile: $0.185/min
  - International numbers: $4.50-25/month
  - Plus STT/TTS/LLM costs on top
- **Total estimated**: ~$0.14/min (similar to VAPI when you add all pieces)
- **Key advantage**: Already have account, phone number, and Railway server.
- **Key disadvantage**: Months of work to finish. Need to implement ConversationRelay or Gemini Live API integration, handle interruptions, latency optimization, error handling.

## Retell.ai
- **Pricing**: $0.07/min all-inclusive (cheapest)
- **Languages**: 31+ including Japanese, Korean
- **Latency**: Sub-500ms
- **Key advantage**: Simplest pricing, good multilingual, batch calling
- **Key disadvantage**: No MCP integration, would need to set up from scratch

## Bland.ai
- **Pricing**: $0.09/min base
- **Languages**: English only by default, multilingual only for enterprise
- **Verdict**: Not suitable for this use case

## Recommendation
VAPI is the fastest path: MCP already connected, can create multilingual assistant and make outbound calls within hours. Twilio path would take weeks/months to finish the bridge server properly.
