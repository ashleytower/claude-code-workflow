# Unified Audit & Gap Analysis
## MTL Craft Cocktails AI + Max AI Employee
### February 6, 2026

---

## CORRECTIONS FROM EARLIER RESEARCH

Before the gap analysis, three facts the team audit corrected:

1. **No mtlApi.js bridge exists.** The earlier GitHub-based research said Max's twilio-sms skill calls MTL app endpoints via `mtlApi.js`. This is FALSE. The twilio-sms microservice is self-contained. The only shared layer is Supabase.

2. **TTS is Cartesia, not ElevenLabs.** The MTL app's CLAUDE.md and env vars reference ElevenLabs, but the actual `textToSpeechService.ts` uses **Cartesia Sonic 3** (`api.cartesia.ai`). ElevenLabs SDK is a dead dependency in package.json. Max DOES use ElevenLabs.

3. **The `-1` repo is the NEWER code.** `mtl-craft-cocktails-ai` is on a stale feature branch. `mtl-craft-cocktails-ai-1` has the latest `main` with a major App.tsx refactor (6,215 -> 1,535 lines, 43 hooks extracted) plus SMS endpoints and multi-agent validation.

---

## 1. WHAT WORKS END-TO-END RIGHT NOW

### MTL App (mtl-craft-cocktails-ai-1 = latest code)
- Lead intake from email webhooks or voice command -> event created in Supabase + Google Calendar
- Quote creation with full pricing engine (per-person rates, staffing, bar rental, travel, rush, discounts)
- AI proposal generation (via Gemini 2.0 Flash, bilingual EN/FR)
- Client-facing quote portal (bilingual, interactive addon selection, cocktail browser)
- Stripe 25% deposit checkout with price tampering protection
- Stripe webhook -> quote status updated to "accepted" -> event status to "Booked"
- Simple payment links for syrups/kits with branded bilingual email
- Email inbound via Resend/Svix webhooks with auto-classification
- Email outbound via Resend with threading support
- AI email draft generation with learning from corrections
- Stale quote alerts (daily 9am cron)
- Pending response alerts (daily 10am cron)
- Email sync polling (every 15 min backup)
- Text chat via Claude Sonnet 4.5 with 13 meta-tools and 80+ tool handlers
- Domain memory (client preferences, behavioral learning, episode summaries)
- Google Calendar integration (create, update, delete events)
- Staff management, recipe lookup, packing list calculator
- Menu builder with PDF export
- CRM bento grid dashboard
- Error tracking via Sentry

### Max (max-ai-employee)
- Telegram command/response loop via OpenClaw gateway on Railway
- SMS pipeline: client texts -> Twilio webhook -> Claude Haiku draft -> Telegram approval -> send
- Voice mode toggle (Vapi AI answering vs forward to Ashley's cell)
- Voice notes via Deepgram + ElevenLabs
- Morning brief (8am): weather, calendar, emails, Notion todos, YouTube
- Afternoon report (2pm): research topic + web research + Telegram delivery
- Nightly builder (11pm): fetches tasks -> spawns Claude Code CLI agents -> creates PRs
- Email scanner (2am): Gmail scan -> categorize -> draft responses -> email_queue table
- Mem0 semantic memory (1,292+ facts, WAL protocol)
- Task management (Supabase + Notion sync)
- Safety system (approval flows, audit logging, rate limiting, injection detection)
- Browser automation via Playwright
- GitHub integration (PRs, issues)
- Skill security (blocklist/allowlist for ClawHub skills)

---

## 2. WHAT'S BROKEN AND NEEDS FIXING

### Critical (Blocks core functionality)

| Issue | Location | Impact | Fix |
|-------|----------|--------|-----|
| Voice pipeline doesn't activate in production | MTL app: `VITE_USE_CLAUDE_VOICE` env var | Voice-first is the #1 requirement and it's broken in prod | Set env var to string `'true'` in Vercel, verify comparison logic |
| Anthropic API key exposed in browser | MTL app: `claudeService.ts` `dangerouslyAllowBrowser: true` | Anyone can steal the API key from browser devtools | Proxy Claude calls through a Vercel API route |
| Post-payment confirmation email fails | MTL app: Stripe webhook calls `/api/drafts/trigger` which doesn't exist | Clients pay deposit but get no confirmation email | Create the endpoint or inline the email send in the webhook handler |
| Primary repo is stale | `mtl-craft-cocktails-ai` is on merged branch, 3 commits behind | Working on old code | `git fetch && git checkout main && git pull` |
| Deepgram using nova-2 not nova-3 | MTL app: `speechToTextService.ts` defaults to `nova-2` | 54% worse word error rate, missing multilingual code-switching for FR/EN | Change default to `nova-3` |

### High (Degrades experience significantly)

| Issue | Location | Impact | Fix |
|-------|----------|--------|-----|
| CLAUDE.md says ElevenLabs, code uses Cartesia | MTL app: docs vs `textToSpeechService.ts` | Confuses any developer/agent working on the project | Update CLAUDE.md and env var names |
| Stripe SDK 3 major versions behind (v17 vs v20) | MTL app: `package.json` | Missing security patches, features, potential deprecations | `npm install stripe@latest` |
| Max's Anthropic SDK v0.20 (53 versions behind) | Max: `skills/twilio-sms/package.json` | Likely using deprecated API patterns | Update to latest |
| No Twilio webhook signature validation in MTL app | MTL app: `api/send-sms.js` | Anyone can forge inbound SMS webhooks | Add `validateRequest()` |
| Canada Post skill has payment card details in SKILL.md | Max: `skills/canada-post/SKILL.md` | Credit card info in source code (even if gitignored locally) | Move to encrypted credentials in Supabase |
| Cron job queries may not match schema | MTL app: `check-pending-responses.js` queries flat fields but data is in JSONB `data` column | Cron silently returns no results | Fix queries to use `data->>'clientEmail'` etc |

---

## 3. WHAT'S STUBBED AND NEEDS BUILDING

### Proactive Agents (MTL app -- designed but never called)

7 agent files with full cognitive architectures, ~100K+ of code, ZERO callers:

| Agent | Purpose | Code Status | What's Needed |
|-------|---------|-------------|---------------|
| `directorAgent.ts` | Routes to sub-agents, multi-step reasoning | ~500 lines, complete | Wire to a trigger (cron, webhook, or voice command) |
| `salesAgent.ts` | Lead qualification, proposal strategy | ~600 lines, complete | Wire to email/SMS intake events |
| `emailAgent.ts` | Email response generation | ~300 lines, complete | Wire to inbound email webhook |
| `operationsAgent.ts` | Staffing, logistics | ~500 lines, complete | Wire to event status changes |
| `workflowCoordinator.ts` | Multi-agent workflow orchestration | Complete | Wire as the entry point that dispatches to other agents |
| `validatorAgent.ts` | Validates AI outputs before sending | Complete | Call before any auto-send |
| `multiAgentValidation.ts` | Generator-critic pattern | Complete (in -1 repo) | Wire to quote/email generation |

### Lead Nurturing (MTL app -- infrastructure exists, not automated)

- `leadNurturingService.ts` has follow-up rules defined (3/7/14 day sequences)
- `processFollowUps()` function exists but NO cron job calls it
- Notification queue stores alerts but nothing consumes them
- **Need:** A cron job that calls `processFollowUps()` and either auto-sends or queues for approval

### SMS in MTL App (stub)

- `smsService.ts` and `api/send-sms.js` exist but are minimal
- The `-1` repo has new SMS endpoints (`api/sms/inbound.js`, `api/sms/menu-update.js`, `api/sms/search.js`)
- Max's twilio-sms microservice is the working SMS handler
- **Decision needed:** Should SMS live in Max (current) or be pulled into the MTL app?

### Instagram DM Monitoring (not in MTL app)

- Max can check Instagram DMs via Rube/Composio
- MTL app has no Instagram integration
- **Need:** Either Max monitors DMs and creates leads in Supabase (which MTL app reads), or MTL app gets its own Instagram integration

### Event Completeness Checker (doesn't exist anywhere)

- The pattern Ashley described: for each upcoming event, check all channels for missing info (address, guest count, dietary restrictions, menu confirmation, deposit)
- **Need:** New cron job or agent that iterates events, checks for gaps, searches SMS/email/DM history, and either fills gaps or queues outreach

---

## 4. THE BRIDGE: HOW MAX AND MTL APP CONNECT

### Current State: Shared Supabase Only

Both apps use the same Supabase project (`clnxmkbqdwtyywmgtnjj`). That's the only connection. There is no API bridge, no shared message bus, no webhook between them.

**What Max writes that MTL app could read:**
- `sms_conversations` + `sms_messages` (full SMS history with clients)
- `memory` table (business facts, client preferences)
- `tasks` table (Max's task queue)
- `audit_log` (everything Max does)
- `email_queue` (drafted email responses)

**What MTL app writes that Max could read:**
- `events` table (all event data)
- `quotes` table (all quotes with status)
- `emails` table (inbound/outbound email history)
- `domain_memory` (client preferences, patterns)
- `action_log` (all user actions)
- `scheduled_follow_ups` (follow-up queue)

### What the Bridge Should Look Like

```
Client contacts Ashley (SMS/Instagram/Email/Phone/Voice)
        |
        v
Max intercepts (OpenClaw gateway)
  - SMS: Twilio -> Railway -> Claude draft -> Telegram approval
  - Instagram: Rube polls DMs -> classifies -> Telegram alert
  - Email: Gmail scan at 2am -> draft -> email_queue
  - Phone: Vapi AI answers or forwards
        |
        v
Max creates/updates in Supabase:
  - New lead? -> INSERT into events table (status: "Inquiry")
  - Existing client? -> UPDATE event with new info
  - Address found in SMS? -> UPDATE event data->address
        |
        v
MTL App reads from same Supabase:
  - Dashboard shows new leads
  - Voice: "Any new leads?" -> queries events where status = "Inquiry"
  - Voice: "Did Sarah send her address?" -> queries sms_messages + emails + events
        |
        v
MTL App takes action:
  - Voice: "Send proposal to Sarah" -> createQuote -> email with link
  - Voice: "Create payment link for 2 syrups" -> Stripe payment link
  - Client pays deposit -> webhook -> event status = "Booked"
        |
        v
Max monitors outcomes:
  - Morning brief includes: "Sarah's quote was viewed but not paid"
  - Heartbeat checks: "3 quotes pending >5 days"
  - Can proactively draft follow-ups
```

### Bridge Requirements (What Needs Building)

1. **Max needs to write leads to the `events` table** in MTL app's expected format (JSONB `data` column with clientName, clientEmail, phone, headcount, date, eventType, status)

2. **MTL app's voice tools need to query `sms_messages`** -- currently they can't. The "Did Sarah send her address?" use case requires a new tool that searches SMS + email + event data.

3. **A unified contact resolution layer** -- when Ashley says "Sarah," both systems need to resolve that to the same client across SMS, email, Instagram, and events. MTL app has `identityResolutionService.ts` and `contactResolutionService.ts` but they don't know about SMS or Instagram channels. Max has Mem0 with client facts.

4. **Event completeness checker** -- new cron job (in Max or MTL app) that iterates upcoming events, checks for missing fields, searches all channels, and queues actions.

5. **Notification routing** -- MTL app's notification queue needs to deliver to both the dashboard AND Telegram (via Max). Currently notifications just sit in the queue.

---

## 5. PRIORITY-ORDERED PUNCH LIST

### Week 1: Make the core pipeline work

1. **Sync the primary repo** -- `git fetch && git checkout main && git pull` in `mtl-craft-cocktails-ai` (or just work from `-1`)
2. **Fix voice pipeline production bug** -- Set `VITE_USE_CLAUDE_VOICE=true` in Vercel env vars, verify the string comparison
3. **Fix Deepgram model** -- Change default from `nova-2` to `nova-3` in speechToTextService.ts
4. **Fix CLAUDE.md** -- Update TTS references from ElevenLabs to Cartesia
5. **Fix post-payment confirmation** -- Either create `/api/drafts/trigger` endpoint or inline confirmation email in Stripe webhook handler
6. **Fix Anthropic browser exposure** -- Create `/api/claude` proxy route, remove `dangerouslyAllowBrowser: true`
7. **Test full pipeline** -- Lead -> Quote -> Send email -> Client views -> Selects cocktails -> Pays deposit -> Confirmed

### Week 2: Build the bridge

8. **Add "search all channels" voice tool** -- Queries sms_messages + emails + events for a client name, returns what was found
9. **Max writes leads to events table** -- When SMS/Instagram inquiry comes in, Max creates an event in Supabase in MTL app format
10. **Add follow-up cron** -- New Vercel cron that calls `processFollowUps()` from leadNurturingService.ts
11. **Wire notification delivery** -- Notification queue items push to both dashboard and Telegram
12. **Update outdated deps** -- Stripe v17->v20, Max's Anthropic SDK, Max's Supabase SDK

### Week 3: Activate proactive agents

13. **Wire workflowCoordinator** -- Connect to email webhook and SMS events as triggers
14. **Wire salesAgent** -- Triggered on new inquiries, auto-qualifies leads
15. **Wire validatorAgent** -- Called before any auto-send (email, SMS, quote)
16. **Build event completeness checker** -- Cron that iterates upcoming events, finds missing info across channels, queues outreach
17. **Add Twilio webhook validation** -- In MTL app's SMS endpoints

### Week 4: Polish and unify

18. **Unified voice identity** -- Same Deepgram config + same TTS voice across both systems
19. **Mem0 integration in MTL app** -- Voice tools query Max's Mem0 for business context
20. **Instagram -> Lead pipeline** -- Max monitors DMs, creates leads in Supabase, MTL app shows them
21. **Post-event follow-up chain** -- Thank you -> feedback -> review -> rebooking -> referral

---

## 6. HOW VOICE-FIRST COMMANDS FLOW

### Current Flow (Text Chat Only Working)
```
Ashley speaks -> Deepgram STT -> Claude Sonnet 4.5 -> meta-tool selection
  -> skill bundle loaded -> tool handler in App.tsx -> Supabase CRUD
  -> Claude response -> Cartesia TTS -> Ashley hears answer
```

### Target Flow (Voice-First with Bridge)
```
Ashley speaks: "Did Sarah send her address yet?"
  -> Deepgram Nova-3 STT (with cocktail keyterms, FR/EN code-switching)
  -> Claude processes intent: "cross-channel search for client Sarah, field: address"
  -> Tool: searchAllChannels("Sarah", "address")
    -> Query 1: sms_messages WHERE phone matches Sarah's number
    -> Query 2: emails WHERE sender matches Sarah's email
    -> Query 3: events WHERE data->clientName ILIKE 'sarah%'
  -> Results compiled
  -> IF FOUND: "Yes, Sarah sent her address in a text on February 3rd: 456 Rue Saint-Laurent. Want me to update her event?"
    -> IF YES: UPDATE events SET data->address = '456 Rue Saint-Laurent'
  -> IF NOT FOUND: "No, I don't see an address from Sarah anywhere. Want me to email her asking for it?"
    -> IF YES: draftService generates email -> approval -> Resend sends
  -> Cartesia TTS -> Ashley hears the answer
```

### Target Flow (Proactive via Max)
```
Max scheduled job (every 6 hours):
  -> Query events WHERE date > NOW() AND date < NOW() + 7 days
  -> For each event, check completeness:
    - address? guest count? menu confirmed? deposit paid?
  -> For missing fields, search channels (SMS, email, Instagram)
  -> IF found: update event, send Telegram: "Updated Sarah's address from her Feb 3 text"
  -> IF not found: send Telegram: "Sarah's event is Saturday but we're missing her address. Draft an email?"
    -> Ashley approves on Telegram
    -> Max calls MTL app's Resend endpoint (or sends directly)
```

---

## DEPENDENCY VERSIONS REQUIRING UPDATE

| Package | Current | Latest | Location | Priority |
|---------|---------|--------|----------|----------|
| `stripe` | ^17.5.0 | 20.3.1 | MTL app | HIGH |
| `@anthropic-ai/sdk` | ^0.20.0 | 0.73.0 | Max twilio-sms | HIGH |
| `@supabase/supabase-js` | ^2.39.3 | 2.93.x | Max agency-dashboard | MEDIUM |
| `twilio` | ^5.0.0 | 5.11.2 | Max twilio-sms | MEDIUM |
| `@deepgram/sdk` | ^4.11.3 | 4.11.3 | MTL app | UP TO DATE |

---

## SECURITY ISSUES REQUIRING ATTENTION

1. **Anthropic API key in browser** -- MTL app, CRITICAL
2. **No Twilio webhook validation** -- MTL app SMS endpoints
3. **Canada Post credit card in SKILL.md** -- Max, move to encrypted store
4. **No RLS policies visible** -- Both apps use service key, bypasses RLS
5. **Stripe SDK outdated** -- Potential security patches missing
