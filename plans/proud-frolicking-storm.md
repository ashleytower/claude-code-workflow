# Parallel Ralph Loop Workstreams

Two independent features to build on separate branches using Ralph loops.

---

## Branch 1: `feature/claude-meta-tools`

### Problem
1. Gemini Chat API hallucinates tool execution (says "done" without calling tools)
2. ~110 tools exposed to AI (way too many for reliable selection)
3. Skills are organizational bundles but AI still sees individual tools

### Solution
Switch text chat to Claude with true meta-tool pattern:
- AI sees **13 skill tools**, not 110 individual tools
- Each skill tool has an `action` parameter to specify what to do
- Claude orchestrates agents and executes tools via skill routing

### Architecture

```
Current (broken):
  Message → Gemini → 110 tools exposed → Hallucinated execution

New (meta-tools):
  Message → Claude → 13 skill tools → Router → Actual tool execution
```

### Skill Meta-Tools (13 total)

| Meta-Tool | Actions | Example |
|-----------|---------|---------|
| `event_management` | create, update, archive, get_packing_list, add_cocktail, etc. | `{skill: "event_management", action: "updateHeadcount", params: {count: 50}}` |
| `calendar_management` | check_availability, add_event, get_schedule | `{skill: "calendar_management", action: "getSchedule", params: {date: "tomorrow"}}` |
| `staff_management` | assign, lookup, send_brief | ... |
| `quote_management` | create, send, create_payment_link | ... |
| `email_sending` | send_brief, send_proposal, send_shopping_list | ... |
| `email_inbox` | get_new, get_details, generate_draft, send_draft, archive | ... |
| `todo_management` | add, list, complete, delete, set_reminder | ... |
| `memory_assistant` | check_status, get_history, verify_action | ... |
| `event_drafts` | generate, review, approve | ... |
| `sms_management` | send_text | ... |
| `location_reminders` | add, check_proximity | ... |
| `sales_management` | qualify_lead, score, suggest_response | ... |
| `workflow_management` | start_workflow, check_status | ... |

### Implementation Steps

#### Step 1: Create Claude Service
- **File**: `services/claudeService.ts`
- Install `@anthropic-ai/sdk`
- Create `sendChatMessage(message, context)` function
- **Model**: `claude-sonnet-4-5-20241022` (Sonnet 4.5)

#### Step 2: Define Meta-Tool Schema
- **File**: `services/skills/metaToolSchema.ts`
- Single tool definition with `skill`, `action`, `params`
- Action enum per skill (from existing tool names)

#### Step 3: Create Skill Router
- **File**: `services/skills/skillRouter.ts`
- Route `{skill, action, params}` → actual tool execution
- Reuse existing `executeToolHandler()` from `toolExecutor.ts`

#### Step 4: Inject Skill Descriptions
- System prompt includes skill descriptions + available actions
- Claude reads descriptions, picks skill + action
- No 110 tool definitions in context

#### Step 5: Wire Up Text Chat
- **File**: `services/geminiService.ts` → update `sendChatMessage`
- Route text input to Claude instead of Gemini
- Keep Gemini Live for voice (unchanged)

#### Step 6: Test & Verify
- Text: "Send payment link to Sally for $50" → Claude → `{skill: "quote_management", action: "create_payment_link", params: {...}}`
- Voice: Same command → Gemini Live → Direct tool execution (unchanged)

### Files to Modify

| File | Change |
|------|--------|
| `package.json` | Add `@anthropic-ai/sdk` |
| `services/claudeService.ts` | NEW - Claude API integration |
| `services/skills/metaToolSchema.ts` | NEW - Meta-tool definitions |
| `services/skills/skillRouter.ts` | NEW - Skill → tool routing |
| `services/geminiService.ts` | Route text chat to Claude |
| `.env` | Add `ANTHROPIC_API_KEY` |

### Verification
1. Text chat executes tools (no hallucination)
2. Voice still works via Gemini Live
3. All 60+ tools accessible via 13 meta-tools
4. Response quality improved (Claude reasoning)

---

## Branch 2: `feature/progressive-voice-entry`

### Problem
Creating events requires saying everything at once. User wants:
- "Sally, 10pm January 31st, 8 people, mixology workshop" → Create event
- Later: "Enter Sally's email" → Update event
- Later: "Add Sally's address as 1234 Main Street" → Update event

### Current State (Already Built)
- `createLead` tool accepts only `clientName` as required
- `missing_info` field tracks what's needed
- `lead_status` and `draft_status` workflow exists
- Database schema ready

### What's Missing
1. Multi-turn context (remember which lead we're working on)
2. Progressive update tool (modify one field at a time)
3. Natural language field updates ("enter Sally's email")
4. Dashboard indicators for incomplete leads

### Implementation Steps

#### Step 1: Add Session State
- **File**: `App.tsx`
- Track `activeLeadId` in state
- Persist across voice turns until user switches context

#### Step 2: Create `updateLeadField` Tool
- **File**: `services/skills/bundles/eventManagement.ts`
- Tool: `updateLeadField(field, value)` - uses session's activeLeadId
- Fields: email, phone, headcount, date, location, notes

#### Step 3: Add Lead Context Detection
- **File**: `services/skills/toolRegistry.ts`
- Detect "Sally's email" → find lead by name → set as active
- Fuzzy match client names across events

#### Step 4: Wire Handler
- **File**: `App.tsx`
- `handleUpdateLeadField` updates Supabase
- Returns confirmation + next missing field prompt

#### Step 5: Dashboard Indicators
- **File**: `components/Dashboard.tsx`
- Show draft status badge (red/yellow/green)
- Display missing fields on event tiles
- "Incomplete: email, location" text

#### Step 6: Conversational Prompts
- After each update, Gemini suggests next field
- "Got it, added Sally's email. What's the event location?"

### Voice Command Examples

| User Says | Tool Called | Result |
|-----------|-------------|--------|
| "Sally, Jan 31, 8 people, workshop" | `createLead` | Creates event, sets activeLeadId |
| "Enter Sally's email as sally@email.com" | `updateLeadField` | Updates email on active lead |
| "Add the address 1234 Main St" | `updateLeadField` | Updates location |
| "Actually it's 10 people" | `updateLeadField` | Updates headcount |

### Files to Modify

| File | Change |
|------|--------|
| `App.tsx` | Add `activeLeadId` state, `handleUpdateLeadField` |
| `services/skills/bundles/eventManagement.ts` | Add `updateLeadField` tool |
| `services/leadService.ts` | Add `updateLeadField` function |
| `components/Dashboard.tsx` | Add draft status indicators |
| `VoiceToolContext.tsx` | Expose activeLeadId to voice handlers |

### Verification
1. Create minimal event by voice (name only)
2. Add email by voice ("enter Sally's email")
3. Add location by voice ("add address 1234 Main")
4. Dashboard shows incomplete status
5. All fields persist to Supabase

---

## Ralph Loop Commands

```bash
# Terminal 1: Claude Meta-Tools
git checkout -b feature/claude-meta-tools
/ralph-loop "Implement Claude + meta-tool architecture.
1. Create claudeService.ts with Anthropic SDK
2. Define meta-tool schema (13 skills as tools)
3. Create skill router to map actions to tools
4. Wire text chat to Claude
5. Test: 'send payment link to Sally' executes correctly
Output <promise>TEXT_CHAT_WORKS</promise> when tools execute without hallucination." --max-iterations 30

# Terminal 2: Progressive Voice Entry
git checkout -b feature/progressive-voice-entry
/ralph-loop "Implement progressive voice event creation.
1. Add activeLeadId state to App.tsx
2. Create updateLeadField tool in eventManagement.ts
3. Add handler for field updates
4. Add dashboard indicators for incomplete leads
5. Test: Create lead 'Sally', then 'add Sally email' updates it
Output <promise>PROGRESSIVE_ENTRY_WORKS</promise> when multi-turn updates work." --max-iterations 25
```

---

## Dependencies

- **Branch 1** requires: `ANTHROPIC_API_KEY` env var
- **Branch 2** requires: Nothing new (uses existing infrastructure)
- **No conflicts**: Branches modify different files

## Merge Order

1. Either branch can merge first (no dependencies)
2. Both can run in parallel on separate terminals
3. Final: Merge both to main, test together
