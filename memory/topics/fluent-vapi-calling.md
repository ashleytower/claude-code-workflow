# Fluent - VAPI Calling Feature

### 2026-03-11 - VAPI AI calling integrated into Fluent

[decision] Using VAPI over Twilio DIY for voice calling. VAPI handles full pipeline (STT+LLM+TTS), already had account with 2 phone numbers and MCP tools connected. Hours vs months to implement.

[pattern] VAPI assistant: "Fluent - Travel Concierge v2" (ID: 216a0861-8e05-45a1-aac3-035c7f28770d). Uses Claude 3.5 Haiku + Deepgram Nova 3 + ElevenLabs turbo v2.5. Phone number: Twilio +14387937557 imported into VAPI (ID: b50da400-2ad4-4bde-9a3d-db5d67e46d38). Supports international calls.

[gotcha] Free VAPI numbers do NOT support international calls. Must import a Twilio number with international calling enabled. Import via POST https://api.vapi.ai/phone-number with provider:"twilio", twilioAccountSid, twilioAuthToken.

[pattern] Architecture: Next.js API route (`app/api/call/route.ts`) proxies VAPI calls server-side (keeps VAPI_API_KEY off client). Hook (`useVapiCall`) polls VAPI every 2s for status/transcript. UI is a bottom Sheet (`CallSheet`) over the chat view.

[gotcha] VAPI MCP cannot persist assistant instructions or firstMessage. Use direct PATCH to https://api.vapi.ai/assistant/{id} with model.messages[{role:"system",content:"..."}] instead.

[gotcha] ElevenLabs eleven_turbo_v2_5 is English-only with terrible accents in other languages. Use eleven_multilingual_v2 for proper multilingual support.

[gotcha] VAPI ends calls via POST /call/{id}/hang (not DELETE). The MCP tool schema requires objects not JSON strings for transcriber/voice params.

[gotcha] E.164 phone validation: strip formatting chars but require `+` prefix with country code. Don't strip `+` then re-add it (dead code path).

[gotcha] Must validate callId as UUID before interpolating into VAPI API URLs (SSRF prevention).

[gotcha] Need `resetCall()` function in hook to prevent duplicate summary messages when user reopens call sheet after completed call.

### Files Created/Modified
- `app/api/call/route.ts` - POST/GET/DELETE proxy to VAPI
- `hooks/useVapiCall.ts` - call state management hook
- `components/call/CallSheet.tsx` - call UI (form, transcript, result)
- `components/chat/InputArea.tsx` - added Phone button
- `app/page.tsx` - wired up CallSheet + useVapiCall
- `types.ts` - CallRequest, CallTranscript, CallStatus, CallResult
- `next.config.js` - added api.vapi.ai to CSP
- `.env.example` - VAPI_API_KEY, VAPI_PHONE_NUMBER_ID, VAPI_ASSISTANT_ID

### Env Vars on Vercel (all set, server-side only)
- VAPI_API_KEY = 8813514e-2d55-40a8-a772-6aec5d5d237d (sensitive)
- VAPI_PHONE_NUMBER_ID = b50da400-2ad4-4bde-9a3d-db5d67e46d38 (Twilio +14387937557)
- VAPI_ASSISTANT_ID = 216a0861-8e05-45a1-aac3-035c7f28770d

### 2026-03-13 - Transient assistant + model upgrade

[debug] assistantId + assistantOverrides has a known VAPI bug where model overrides break conversation turn-taking. AI speaks first but never processes responses. Fix: use transient `assistant` object inline instead.

[debug] Claude 3.5 Haiku couldn't understand it was on a phone call — responded like a chatbot ("I'm ready to help"), narrated its actions. Switched to Haiku 4.5.

[gotcha] Voice override in assistantOverrides is silently ignored. Must either update the saved assistant directly (VAPI API) or include voice in transient assistant config.

[gotcha] `firstMessageMode: 'assistant-waits-for-user'` causes the AI to go completely silent on outbound calls. Use `assistant-speaks-first-with-model-generated-message` instead.

[decision] Switched from saved assistant + overrides to full transient assistant for per-call configs. VAPI docs recommend this when system prompt changes per call.

[decision] Voice changed from Adam → Antoni → Sarah (EXAVITQu4vr4xnSDxMaL) on eleven_multilingual_v2. Sarah is the #1 rated ElevenLabs voice for multilingual phone agents.

[decision] Name removed from system prompt unless userName is provided. Don't introduce yourself unless it's a reservation.

### 2026-03-13 - Conversation loop fixed + UX improvements

[gotcha] **ROOT CAUSE of AI not processing turns**: Deepgram transcriber defaulted to English-only without `language` param. French speech transcribed as English gibberish ("We We oh, no. D d a." instead of "Oui, on a des billets"). Fix: `language: 'multi'` on Deepgram nova-3 transcriber. Supports 10 languages including FR, ES, JA, ZH.

[gotcha] **check_with_user tool (async: false) freezes conversation**: When LLM calls the tool, VAPI sends tool-calls event to webhook which holds for 20s waiting for user decision. During this time the entire conversation is frozen. The call sheet auto-minimized so user couldn't even see the decision prompt. Removed tool temporarily; will re-add with async: true or better UX.

[gotcha] **Edge Runtime in-memory Maps unreliable across isolates**: Webhook stores transcript in Map, but polling endpoint may hit a different Edge isolate with empty Map. Fix: added VAPI call object messages as fallback transcript source in useVapiCall hook.

[gotcha] **Don't auto-minimize call sheet during active calls**. User needs to see live transcript and type instructions to the AI in real time. The call sheet has message input + end call button.

[decision] Model: GPT-4o. Tested Claude 3.5 Haiku (broke character), Haiku 4.5 (not supported by VAPI), Sonnet 3.7, GPT-4o. GPT-4o is VAPI's best-tested model and handles phone conversations well.

[pattern] System prompt must: (1) combine greeting + question in first message, (2) stick to the stated task only, (3) not buy/book/commit unless task explicitly says to, (4) gather details like price/time/availability, (5) never speak English or narrate actions.

### Onboarding TODO (not yet built)
Collect during onboarding/settings:
- **Full name** — for reservations, voicemail messages
- **Phone number** — callback number for voicemail, reservations
- **Home language** — user's native language (sets "from" language)
- **Destination country/countries** — determines "to" language(s)
- Any other relevant travel context

This data auto-populates every call so the AI already knows who you are. Chat should show "Calling as [Name] ([Number])" before each call for confirmation.

### Not Yet Done
- Onboarding flow (name, phone, languages, destinations)
- Rate limiting on API route (anyone can trigger calls)
- WebSocket monitoring (using polling instead of VAPI listenUrl)
- Tests for hook and component
- ESLint not configured in this project
- User profile storage (localStorage or Supabase)
