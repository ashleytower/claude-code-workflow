# Vapi Voice Tools

### 2026-02-16 - Vapi tool muting fix
[gotcha] Vapi tools MUST have `async: false` set or the LLM will not speak after receiving tool results. Also remove any empty `request-complete` messages. The combination of these two issues causes the AI to go silent after tool calls complete.

### 2026-02-16 - Vapi tool response format
[gotcha] Vapi server-side tool responses MUST include `name` (function name), `toolCallId`, and `result` in each result object. Missing `name` field may cause tool results to not be fed back to the LLM.

### 2026-02-16 - Composio REST API replaces Rube
[pattern] Rube HTTP endpoint (`rube.app/mcp/execute`) is dead. Use Composio REST API directly: `POST https://backend.composio.dev/api/v2/actions/{ACTION_NAME}/execute` with `X-API-Key` header and body `{connectedAccountId, input}`. Action names differ from MCP (e.g. `GOOGLECALENDAR_EVENTS_LIST` not `GOOGLECALENDAR_EVENTS_LIST_ALL_CALENDARS`). Connected account IDs are UUIDs, not `ca_xxx` format.

### 2026-02-16 - Railway timezone handling
[gotcha] Railway runs in UTC. When parsing user times like "2:30pm", must build ISO strings with EST offset (e.g. `2026-02-16T14:30:00-05:00`). Using `new Date().setHours(14,30)` sets 2:30 PM UTC which is wrong. Use `getEstOffsetStr()` helper to get current EST/EDT offset.

### 2026-02-16 - Ashley's phone numbers
[pattern] Ashley's cell (for outbound calls): +15146647557. The number +14388689878 goes to voicemail. Railway env `ASHLEY_PHONE_NUMBER=+15146647557` is correct. Max's dedicated number: +14385447557. Business number: +14382557557.

### 2026-02-16 - Supabase tasks table schema
[gotcha] Tasks `priority` is TEXT enum (`low`, `medium`, `high`, `urgent`), not a number. Tasks require `user_id` column (DEFAULT_USER_ID = `3ed111ff-c28f-4cda-b987-1afa4f7eb081`).

### 2026-03-12 - VAPI outbound calling (Fluent voice-translator)
[pattern] Full outbound calling architecture built in voice-translator repo. Key gotchas:
- `assistantOverrides.model` replaces the ENTIRE model config (provider, model, messages, tools). Must include tools inline.
- VAPI template variables (`{{var}}`) do NOT interpolate in overrides. Build system prompt with actual values server-side.
- `firstMessageMode: "assistant-speaks-first-with-model-generated-message"` ignores `firstMessage`, LLM generates from system prompt.
- Vercel serverless functions don't share memory across route files. Consolidated webhook/transcript/decision into single Edge catch-all at `/api/vapi/[...action]/route.ts` with `runtime = 'edge'` and `preferredRegion = 'iad1'`.
- Edge Runtime shares V8 isolate memory for concurrent requests in same function -- in-memory Maps work for cross-request state.
- `export const maxDuration = 30` needed on call creation route to avoid 504 on Vercel Hobby plan.
- `backgroundSound: "off"` + `backgroundDenoisingEnabled: true` removes call-center ambiance.
- Webhook must always return HTTP 200. For tool-calls, return `{ results: [{ toolCallId, result }] }`.
- Human-in-the-loop via sync `check_with_user` tool: webhook holds response up to 20s polling for user decision.

### 2026-02-16 - Composio available actions
[research] Verified working Composio V2 REST actions: `GOOGLECALENDAR_EVENTS_LIST`, `GOOGLECALENDAR_UPDATE_EVENT`, `GOOGLECALENDAR_CREATE_EVENT`, `GOOGLECALENDAR_DELETE_EVENT`, `GOOGLECALENDAR_PATCH_EVENT`, `GOOGLECALENDAR_EVENTS_MOVE`, `GMAIL_FETCH_EMAILS`, `GMAIL_SEND_EMAIL`, `GMAIL_CREATE_EMAIL_DRAFT`, `GMAIL_FETCH_MESSAGE_BY_MESSAGE_ID`, `GMAIL_FETCH_MESSAGE_BY_THREAD_ID`. Calendar account: `0116783f-113b-4e4c-9c68-bf7f557c2e1f`. Gmail account: `b2813f94-4d85-4bf1-b858-2c002a7cf70c`.
