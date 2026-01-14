# MTL Craft Cocktails AI - Complete Voice-First Business Management System

## Product Requirements Document

**Version**: 2.0
**Created**: January 9, 2026
**Timeline**: 4-5 weeks (Q1 2026)
**Status**: Ready for Approval

---

## Executive Summary

Evolution of the existing MTL Craft Cocktails AI platform into a complete voice-first business management system with autonomous AI agents, approval workflows, and SMS integration. Built on the existing React/Gemini/Supabase stack, adding multi-agent coordination with human-in-the-loop approval gates.

---

## Vision

**One sentence**: An AI operations manager that runs your bartending business hands-free, preparing actions for your approval while you're bartending or driving.

**Core philosophy**:
- Voice-first (hands-free operation)
- AI prepares, human approves
- Autonomous within boundaries
- Learn from every interaction

---

## Current State

### What Works
- 40+ voice tools across 9 skill bundles
- Full event lifecycle (inquiry → complete)
- Email inbox with AI draft generation
- Google Calendar integration
- Stripe payments and quotes
- Domain memory (client preferences)
- Packing list calculations

**Lead Capture (AutoWin Flow) - ALREADY WORKING:**
- `createLead` voice tool: "New lead from Sarah, wedding, June 15th"
- Auto-creates event in Supabase (status: Inquiry)
- Auto-adds to Google Calendar (if date is valid)
- Auto-updates domain memory for returning clients
- Urgency calculation (red/yellow/green based on date proximity)
- Sources: Email webhook, voice commands, (future: Webflow forms)

**Quote/Invoice System - ALREADY WORKING:**
- `createQuote` voice tool: "Send Sarah a quote for $2,400"
- `generateProposal` tool: Creates proposal from email inquiry
- Stripe Checkout for 25% deposits
- Quote status tracking (sent → viewed → accepted)
- Payment link creation for add-ons/syrups

### What's Broken
- Text chat tool execution (Gemini hallucination) - **ACCEPT FOR NOW**
- Agent-swarm branch not merged - **NEEDS AUDIT**

### What's Missing
- **Email Agent** (autonomous email workflow)
- SMS/WhatsApp messaging
- Approval workflow UI
- Push notifications
- Multi-agent coordination
- Configurable automation rules
- **Action audit trail** (for "did I do X?" queries)

---

## Target Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INTERFACE                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ Voice Input │  │ Approval    │  │ Push Notifications  │ │
│  │ (Gemini)    │  │ Queue UI    │  │ (Mobile/Desktop)    │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    AGENT LAYER                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              DIRECTOR AGENT                          │   │
│  │  (Orchestrates all operations, prepares actions)     │   │
│  └─────────────────────────────────────────────────────┘   │
│           │              │              │                   │
│  ┌────────▼───┐  ┌──────▼──────┐  ┌────▼────────┐         │
│  │ Comms      │  │ Operations  │  │ Finance     │         │
│  │ Director   │  │ Director    │  │ Director    │         │
│  │            │  │             │  │             │         │
│  │ - Email    │  │ - Events    │  │ - Quotes    │         │
│  │ - SMS      │  │ - Staff     │  │ - Payments  │         │
│  │ - Calendar │  │ - Inventory │  │ - Invoices  │         │
│  └────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                  APPROVAL LAYER                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Action Queue: Pending actions awaiting approval     │   │
│  │  - Voice: "Ready to send. Say confirm or cancel"     │   │
│  │  - Push: Notification with approve/reject            │   │
│  │  - UI: Queue panel to review details                 │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                    DATA LAYER                               │
│  Supabase: Events, Emails, Quotes, Memory, Actions Queue   │
├─────────────────────────────────────────────────────────────┤
│                  INTEGRATIONS                               │
│  Gemini │ Twilio │ Resend │ Stripe │ Google Calendar       │
└─────────────────────────────────────────────────────────────┘
```

---

## Phases

### Phase 1: Stabilization (Week 1)
**Goal**: Clean foundation before adding features

1. **Audit agent-swarm branch**
   - Review Director Agent implementation
   - Review SMS service code
   - Check for breaking changes vs main
   - Document what to keep/discard

2. **Code cleanup**
   - Remove unused files/code
   - Fix any build warnings
   - Update dependencies
   - Ensure all tests pass

3. **Merge safe parts**
   - Cherry-pick stable features from agent-swarm
   - Keep main branch deployable at all times

**Deliverable**: Clean main branch with audited agent-swarm features identified

---

### Phase 2: Email Agent + Action Memory (Week 2) **[HIGH PRIORITY]**
**Goal**: Autonomous email workflow + complete action audit trail

1. **Email Agent (Communications Director)**
   - **Categorization**: Auto-categorize incoming emails (inquiry, follow-up, confirmation, spam)
   - **Draft generation**: AI drafts responses using domain memory + business knowledge
   - **Lead nurturing**: Auto-follow-up on:
     - Quotes not responded to (3 days, 7 days)
     - Deposits not paid (reminder at 5 days)
     - Missing information requests
   - **Proposal email integration**: Connect with existing proposal service

2. **Full Email Workflow**
   ```
   New Email → Categorize → Enrich with client history
       ↓
   Generate Draft → Queue for Approval
       ↓
   User: Approve/Edit/Reject
       ↓
   Send → Log to Action Memory → Schedule follow-up if needed
   ```

3. **Action Memory (Audit Trail)**
   - `action_log` table: Every action taken by system or user
   - Fields: action_type, actor (ai/user), target (client/event), payload, timestamp
   - Enables: "Did I send John an email about his address?"
   - Query by: client name, action type, date range, content search

4. **Voice queries for action memory**
   - "Did I send Sarah the quote?"
   - "What did we discuss with John last week?"
   - "Have I followed up with Amanda about the deposit?"
   - "Show me everything I did with the Chen wedding"

**Deliverable**: Autonomous email workflow + queryable action history

---

### Phase 3: Approval System (Week 3)
**Goal**: Human-in-the-loop approval workflow

1. **Database schema**
   - `pending_actions` table (action_type, payload, status, created_at)
   - Action types: email, sms, quote, payment, calendar

2. **Approval Queue UI**
   - New panel showing pending actions
   - Preview of what will be sent/done
   - Approve/Reject/Edit buttons
   - Batch approve option

3. **Voice approval flow**
   - AI announces: "Ready to send quote to Sarah for $2,400. Confirm or cancel?"
   - User says "confirm" → execute
   - User says "cancel" → discard
   - User says "edit" → open for modification

4. **Configurable rules** (per-action type)
   - Email to client: Approval required
   - Email to staff: Auto-send
   - Quote > $1000: Approval required
   - Quote < $1000: Auto-send
   - Calendar event: Auto-create
   - Payment link: Approval required

**Deliverable**: Working approval queue with voice + UI approval

---

### Phase 4: SMS Integration (Week 4)
**Goal**: Twilio SMS for quick client communication

1. **Twilio setup**
   - Account configuration
   - Phone number provisioning
   - Webhook for inbound SMS

2. **SMS service**
   - Send SMS function
   - Receive SMS webhook
   - Thread tracking (conversation history)

3. **Voice commands**
   - "Text Sarah that we're running 10 minutes late"
   - "Send Amanda the deposit link via text"
   - "Read me my texts"

4. **Approval integration**
   - SMS to client: Goes to approval queue
   - Review message before sending
   - Edit if needed

**Deliverable**: Working SMS send/receive with approval workflow

---

### Phase 5: Agent Integration + Notifications (Week 5 - stretch)
**Goal**: Merge Director Agent with approval system

1. **Director Agent activation**
   - Merge from agent-swarm branch (after audit)
   - Connect to approval queue
   - Test autonomous workflows

2. **Multi-step operations**
   - Agent plans: "New inquiry from Sarah → Generate quote → Queue for approval → Send when approved"
   - Agent chains actions with approval gates

3. **Learning from approvals**
   - Track approval/rejection patterns
   - Adjust confidence thresholds
   - Suggest auto-approve for repeated patterns

4. **Push notifications**
   - Web push for pending approvals
   - Mobile notifications (PWA)
   - Sound alerts for urgent items

**Deliverable**: Autonomous agent with approval gates and notifications

*Note: Phase 5 is stretch goal - SMS may push to Week 5 if Email Agent takes longer*

---

## Feature Details

### Email Agent (Communications Director)

**Core Responsibilities**:
1. Process all inbound emails automatically
2. Categorize and prioritize
3. Generate context-aware draft responses
4. Track lead pipeline stages
5. Auto-follow-up on stale items

**Email Categories**:
| Category | Example | Auto-Action |
|----------|---------|-------------|
| New Inquiry | "Hi, interested in bartending for our wedding" | Create lead, draft response |
| Quote Follow-up | "Can you adjust the price?" | Link to quote, draft response |
| Confirmation | "Sounds good, let's book it" | Update status, draft confirmation |
| Missing Info | "What's included in the package?" | Draft detailed response |
| Spam/Promo | Marketing emails | Auto-archive |

**Lead Nurturing Automation**:
```
Quote Sent → 3 days no response → Draft follow-up (queue for approval)
          → 7 days no response → Draft "just checking in" (queue)
          → 14 days no response → Mark as cold, archive

Deposit Request → 5 days unpaid → Draft reminder (queue)
              → 10 days unpaid → Draft urgent reminder (queue)
              → 14 days unpaid → Alert owner, suggest call
```

**Voice Commands**:
- "Do I have new emails?" → Lists unread with AI summary
- "What's urgent in my inbox?" → Filters by urgency
- "Generate a response to Sarah's email" → Creates draft
- "Send the draft to Amanda" → Queues for approval (or auto-sends if configured)

---

### Action Memory (Audit Trail)

**Purpose**: Never wonder "did I do that?" again.

**What Gets Logged**:
- Every email sent (to whom, subject, when)
- Every quote created/sent
- Every SMS sent
- Every calendar event created
- Every status change
- Every voice command executed
- Every client interaction

**Schema**:
```sql
action_log (
  id uuid,
  action_type text,        -- 'email_sent', 'quote_created', 'sms_sent', etc.
  actor text,              -- 'ai', 'user', 'system'
  target_type text,        -- 'client', 'event', 'staff'
  target_id text,          -- client email, event id, etc.
  target_name text,        -- "Sarah Chen", "Johnson Wedding"
  summary text,            -- "Sent quote for $2,400"
  payload jsonb,           -- Full details
  created_at timestamptz
)
```

**Voice Queries**:
- "Did I send John an email about his address?"
  → Searches action_log for emails to John containing "address"
- "What did I do with the Martinez event last week?"
  → Lists all actions for Martinez event in last 7 days
- "Have I followed up with Amanda?"
  → Shows last communication with Amanda + days since

---

### Approval Queue

**Action Types & Default Rules**:
| Action | Default | Configurable |
|--------|---------|--------------|
| Email to client | Approve | Yes |
| Email to staff | Auto | Yes |
| SMS to client | Approve | Yes |
| Quote any amount | Approve | Yes (threshold) |
| Payment link | Approve | Yes |
| Calendar create | Auto | Yes |
| Calendar delete | Approve | Yes |
| Staff assignment | Auto | Yes |
| Packing list | Auto | No |

**UI Elements**:
- Badge count on nav showing pending items
- Queue panel (slide-in from right)
- Each item shows: Type, recipient, preview, timestamp
- Actions: Approve, Reject, Edit, Approve All

**Voice Flow**:
```
AI: "I've prepared a quote for Sarah Chen's wedding.
     150 guests, 4 cocktails, bar rental included.
     Total is $3,750 with a $937 deposit.
     Say confirm to send, cancel to discard, or details to hear more."

User: "Confirm"

AI: "Quote sent to Sarah Chen. I'll let you know when she views it."
```

**In-App Voice Notifications** (via Gemini Live API):
- Gemini speaks results naturally during voice sessions
- "I've prepared a quote for Sarah" (spoken by AI)
- "Quote sent successfully" (confirmation spoken)

**In-App Visual Notifications**:
- Badge count on approval queue
- Toast notifications for actions
- Color-coded urgency indicators

**Development Notifications** (Claude Code - separate):
- ElevenLabs: `~/.claude/scripts/speak.sh` - notifies developer when agents need input
- macOS alerts: `~/.claude/scripts/notify.sh` - visual dev notifications

**App Notification Triggers**:
| Event | In-App Voice (Gemini) | In-App Visual |
|-------|----------------------|----------------|
| New email needs attention | "You have a new inquiry from Sarah" | Badge + inbox highlight |
| Draft ready for approval | "Draft ready for Amanda. Review when ready" | Queue count badge |
| Quote viewed by client | "Sarah just opened her quote" | Toast notification |
| Deposit paid | "Deposit received from Chen wedding!" | Success banner |
| Urgent follow-up due | "Amanda hasn't responded in 7 days" | Red urgency badge |
| Action approved/sent | "Quote sent to Sarah" | Confirmation toast |

---

### SMS Integration

**Voice Commands**:
- `text [client] [message]` - Send SMS
- `read texts` - Read recent SMS
- `text [client] the deposit link` - Send payment link via SMS
- `reply [message]` - Reply to last SMS

**Inbound Handling**:
- New SMS creates notification
- AI can summarize: "Sarah texted asking about glassware options"
- Suggest response (goes to approval queue)

---

### Agent Autonomy Levels

**Level 0 - Suggestions Only**:
AI suggests actions, user must initiate

**Level 1 - Prepare & Approve** (Default):
AI prepares actions, queues for approval

**Level 2 - Auto with Exceptions**:
AI executes routine actions, queues exceptions

**Level 3 - Full Autonomous**:
AI executes everything, notifies of actions taken

*User can set per-action-type autonomy levels*

---

## Success Criteria

### Week 1 (Stabilization)
- [ ] Agent-swarm branch fully audited (document keep/discard)
- [ ] Safe features merged to main
- [ ] All tests passing
- [ ] No build warnings
- [ ] Uncommitted work (email processing queue) resolved

### Week 2 (Email Agent + Action Memory)
- [ ] Email auto-categorization working
- [ ] AI draft generation with client context
- [ ] Lead nurturing automation (follow-up scheduling)
- [ ] `action_log` table created and populated
- [ ] "Did I do X?" voice queries working
- [ ] Email → Approval queue flow complete

### Week 3 (Approval System)
- [ ] `pending_actions` table created
- [ ] Approval queue UI functional
- [ ] Voice approval flow working
- [ ] Configurable rules per action type
- [ ] Email drafts flow through approval

### Week 4 (SMS)
- [ ] Twilio account configured
- [ ] Send SMS working
- [ ] Receive SMS webhook working
- [ ] Voice commands for SMS
- [ ] SMS in approval queue
- [ ] SMS logged to action_log

### Week 5 (Stretch - Agent Integration)
- [ ] Director Agent merged
- [ ] Multi-step workflows working
- [ ] Push notifications working
- [ ] Learning from approvals
- [ ] Full E2E test passing

---

## Out of Scope (Future)

- WhatsApp Business API (requires business verification)
- Inventory tracking system
- Financial dashboard
- Client portal
- Mobile native app
- Multi-business/white-label
- Text chat bug fix (voice-only for now)

---

## Voice-First Design Requirements

**From project CLAUDE.md - CRITICAL**:

This is a voice-first app. The owner operates it hands-free while bartending or driving. Every feature MUST be voice-accessible.

### When Building ANY Feature:
1. **Add voice commands** - If it can be done in the UI, it MUST also work via voice
2. **Use readable indicators** - No tiny dots or icons-only. Use text labels like "Draft Ready"
3. **Speak results** - Voice responses should be natural and complete
4. **Fuzzy match names** - Users say "Amanda's event" not event IDs

### Voice Command Checklist (for every new feature):
- [ ] Added function declaration to skill bundle in `services/skills/bundles/`
- [ ] Added case handler in BOTH switch statements (Live API + Chat API)
- [ ] Added handler type to `VoiceToolContext.tsx`
- [ ] Added handler implementation in `App.tsx`
- [ ] Wired handler to both `sendChatMessage` and context provider

### Skills-with-Tools Architecture (DO NOT VIOLATE):
- New voice tools go in skill bundles, NOT directly in geminiService.ts
- Max 15 tools per skill bundle (Gemini best practice)
- Use `getToolsForChatMessage(message)` for text chat
- Use `getToolsForLive('voice')` for voice

---

## Technical Decisions

| Decision | Choice | Reasoning |
|----------|--------|-----------|
| Platform | Web (React) | Keep current, works well |
| Voice AI | Gemini 2.5 Flash | Already integrated, works |
| SMS | Twilio | Industry standard, reliable |
| Database | Supabase | Already integrated |
| Notifications | Web Push API | No app store needed |
| Agent arch | Director pattern | From agent-swarm branch |

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Agent-swarm branch too diverged | High | Careful audit, cherry-pick only |
| Twilio costs | Medium | Monitor usage, set alerts |
| Approval fatigue | Medium | Smart defaults, auto-approve learning |
| Voice-only limitation | Medium | Design for voice-first anyway |

---

## Next Steps

1. **Approve this PRD** - Confirm direction
2. **Start Phase 1** - Audit agent-swarm branch
3. **Create detailed plans** - Per-phase implementation plans
4. **Execute** - Weekly sprints with demos

---

*This PRD serves as the north star for development. Update as we learn.*
