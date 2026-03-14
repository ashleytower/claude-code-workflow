# Plan: Two Vapi Assistants with Tool Calling

## Context

Max on the phone is "dumb" -- no access to real data. Ashley wants two separate Vapi assistants:

1. **Personal Max** -- for Ashley. Full access to emails, calendar, tasks, memory. Casual tone. Lives on the dedicated number (+1 438 544 7557).
2. **Client Max** -- for clients. Simple voicemail bot. "We're away, leave a message." Takes the message and sends it to Ashley on Telegram. Lives on the business Vapi number (clients reach it when voice mode = "ai" and the call forwards from Twilio).

When voice mode = "forward", client calls still go directly to Ashley's cell. Client Max only answers when mode = "ai" (Ashley doesn't want to take calls).

**Current state:**
- 1 Vapi assistant: `1427681a-7f23-46f9-9714-2f82c4b8c9fb`
- Business number (Twilio): +1 438 255 7557 -> voice.js, mode "ai" dials `VAPI_PHONE_NUMBER`
- Dedicated number (Vapi): +1 438 544 7557, ID `8da70eaa-17e4-4e9d-ad53-d070833edd8b`
- Railway URL: `https://twilio-sms-production-b6b8.up.railway.app`

## Architecture

```
CLIENT CALLS (business number, mode = "ai")
    |
    Twilio voice.js --> dials VAPI_PHONE_NUMBER
    |
    v
Client Max (NEW Vapi assistant)
    |  "We're away right now. Leave a message and we'll get back to you."
    |  Tool: take_message -> Telegram notify
    v
/vapi/tools webhook


ASHLEY CALLS (dedicated number +1 438 544 7557)
    |
    Ashley dials directly, or Max calls her (reminders)
    |
    v
Personal Max (EXISTING Vapi assistant, enhanced)
    |  Tools: lookup_emails, check_calendar, list_tasks, search_memory
    v
/vapi/tools webhook (same endpoint)
```

## Tools

### Client Max (1 tool)

| Tool | Purpose | Action |
|------|---------|--------|
| `take_message` | Capture client name, phone, message | Store + Telegram notify Ashley |

### Personal Max (4 tools)

| Tool | Purpose | Data Source |
|------|---------|-----------|
| `lookup_emails` | Recent unread emails | Rube Gmail API |
| `check_calendar` | Events for a given day | Rube Google Calendar |
| `list_tasks` | Pending tasks | Supabase tasks table |
| `search_memory` | Business knowledge | pgvector semantic search |

Total: 5 tools, 1 webhook endpoint.

## Steps

### 1. New route: `src/routes/vapiTools.js`

Single POST endpoint `/vapi/tools` handling all 5 tool functions.

**Auth:** `VAPI_SERVER_SECRET` env var. Vapi sends it via the server `secret` field (appears as `x-vapi-secret` header). Timing-safe comparison.

**Tool handlers:**

**`take_message`** (client tool)
- Params: `name` (string), `phone` (string, optional), `message` (string)
- Logic: Send Telegram message to Ashley: "New voicemail from [name] ([phone]): [message]"
- Also upsert into `contacts` table via `resolve_contact` if phone provided
- Returns: "Got it, I'll make sure Ashley gets your message right away"

**`lookup_emails`** (personal tool)
- Params: `max_results` (1-10, default 5), `query` (Gmail search, default "is:unread")
- Logic: Rube `GMAIL_FETCH_EMAILS` -> for each, get snippet
- Returns: "You have N unread emails. From X about Y, from Z about W..."

**`check_calendar`** (personal tool)
- Params: `date` ("today", "tomorrow", or ISO date; default "today")
- Logic: Parse date, call Rube `GOOGLECALENDAR_LIST_EVENTS`, format events
- Reuses pattern from `services/calendar.js:99-135`
- Returns: "Today you have N events: Booking X at 3pm..."

**`list_tasks`** (personal tool)
- Params: `status` (default "assigned_to_max"), `limit` (1-10, default 5)
- Logic: Supabase query on `tasks` table
- Returns: "You have N tasks. First is [title], then [title]..."

**`search_memory`** (personal tool)
- Params: `query` (required)
- Logic: `searchMemoriesPgvector(query, 0.6, 5)` from `services/pgvector.js`
- Returns: "Here's what I know: [concise bullets]"

All handlers return voice-friendly text (natural language, concise, under 100 words). No JSON dumps.

### 2. Wire into `index.js`

```javascript
import vapiToolsRouter from './routes/vapiTools.js';
app.use('/vapi', express.json());
app.use('/vapi', vapiToolsRouter);
```

### 3. Create 5 Vapi tools via MCP

Use `mcp__vapi__create_tool` for each. All share the same server URL:
```
https://twilio-sms-production-b6b8.up.railway.app/vapi/tools
```

### 4. Create Client Max assistant via MCP

Use `mcp__vapi__create_assistant`:
- **Name:** "Max - MTL Craft Cocktails"
- **Model:** Anthropic Claude (claude-3-7-sonnet-20250219)
- **Voice:** Same ElevenLabs voice as personal Max (copy voice config from existing assistant)
- **First message:** "Hey, thanks for calling MTL Craft Cocktails! We're currently away from the phone, but if you leave your name and what you're calling about, we'll get back to you as soon as possible."
- **System prompt:** "You are Max, the assistant at MTL Craft Cocktails, a mobile bartending company in Montreal. Ashley is currently unavailable. Your job is to take a message. Ask for the caller's name and what they need. If they mention their phone number, note it. Once you have enough info, use the take_message tool to record it. Be friendly, brief, and professional. Bilingual English/French -- match the caller's language."
- **Tool IDs:** [take_message tool ID]

### 5. Update Personal Max assistant via MCP

Use `mcp__vapi__update_assistant` on `1427681a-7f23-46f9-9714-2f82c4b8c9fb`:
- **Tool IDs:** [lookup_emails, check_calendar, list_tasks, search_memory tool IDs]
- **System prompt addition:** "You have access to tools. When Ashley asks about emails, calendar, tasks, or business info, use the appropriate tool to look it up rather than guessing."

### 6. Assign Client Max to business Vapi phone number

Update the Vapi phone number that `VAPI_PHONE_NUMBER` points to -- change its `assistantId` from the personal assistant to the new client assistant.

The dedicated number (+1 438 544 7557) stays connected to the personal assistant.

### 7. Railway env vars

- Generate and set `VAPI_SERVER_SECRET` (32-char random string)
- Set `VAPI_CLIENT_ASSISTANT_ID` (for reference after creation)

### 8. Deploy

`railway up skills/twilio-sms --path-as-root -s twilio-sms`

## Files

| File | Change |
|------|--------|
| `skills/twilio-sms/src/routes/vapiTools.js` | NEW -- webhook handler for all 5 tools |
| `skills/twilio-sms/src/index.js` | Mount `/vapi` route |
| `skills/twilio-sms/.env.example` | Add VAPI_SERVER_SECRET |

## Reused Code

| What | From |
|------|------|
| `searchMemoriesPgvector()` | `services/pgvector.js:79` |
| Rube API fetch pattern | `services/calendar.js:113-127` |
| Calendar date range logic | `services/calendar.js:99-135` |
| Supabase client | `services/supabase.js` or create new client |
| `sendMessage()` | `services/telegram.js` (for take_message notifications) |
| `createLogger()` | `utils/logger.js` |

## Not Included (v1)

- Email drafting or SMS sending via voice (read-only first)
- Client pricing/availability lookup (keep client Max simple as voicemail)
- Post-call Telegram summaries
- Automatic follow-up scheduling from client messages

## Verification

### Personal Max
1. Schedule a reminder call or dial dedicated number
2. "Do I have any emails?" -> lookup_emails fires, reads back summary
3. "What's on my calendar today?" -> check_calendar fires
4. "What are my tasks?" -> list_tasks fires
5. "What's our open bar pricing?" -> search_memory fires

### Client Max
6. Set voice mode to "ai": `POST /voice/mode { "mode": "ai" }`
7. Call business number from a non-Ashley phone
8. Hear greeting: "We're currently away..."
9. Leave name and message
10. Verify take_message tool fires -> Telegram notification arrives

### Both
11. Railway logs show tool calls with function names and response times
12. Bad VAPI_SERVER_SECRET returns 401
13. Responses are voice-friendly (natural, concise)
