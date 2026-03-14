
### 2026-03-12 - VAPI real-time transcript + AI hold architecture
[pattern] VAPI GET /call/{id} does NOT return transcript during active calls — only after call ends. Must use serverUrl webhook for real-time transcript events.
[pattern] Edge Runtime route files in Next.js cannot export anything except HTTP method handlers (GET/POST etc). Shared state (Maps) must live in a separate lib module, not the route file itself.
[pattern] check_with_user sync tool: VAPI holds the LLM response until the webhook POST returns. Use a polling loop (500ms interval, 120s timeout) inside the webhook handler to wait for a client decision.
[gotcha] VAPI tool-calls event shape: body.message.toolCallList[].function.name — not body.toolCallList directly.
[pattern] Two-poll architecture: poll VAPI /call/{id} every 3s for status (ended/error detection), poll our own /api/vapi/transcript every 1.5s for live transcript from webhook.
