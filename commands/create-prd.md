# Create PRD Command

**Purpose**: Create a Product Requirements Document (PRD) that becomes the north star for all feature development.

## Usage

```bash
claude /create-prd [output-file]
# Example: claude /create-prd PRD.md
```

## Process

### Phase 1: Clarification Questions (PROMPT IMPROVER)

Before writing ANY PRD, ask 3-5 targeted questions to eliminate ambiguity:

**Key Areas to Clarify:**
- **Purpose & Context**: What problem is this solving? Who are the users?
- **Scope & Features**: What specific capabilities are needed? What's explicitly out?
- **Technical Requirements**: What technologies, patterns, or constraints apply?
- **Data & Content**: What data needs to be displayed/processed? What's the source?
- **Interactions & UX**: How should users interact? What are key workflows?
- **Design & Styling**: Existing design system? Brand requirements?

**Question Format:**
```
I need to clarify a few things before creating the PRD:

1. [Most critical ambiguity]
2. [Second most critical]
3. [Third priority]
4. [Optional: Fourth if needed]
5. [Optional: Fifth if needed]
```

**Rules:**
- DO NOT start writing the PRD until questions are answered
- DO NOT make assumptions - ASK
- Questions should be specific and actionable (answers directly inform the PRD)

### Phase 2: PRD Generation

After receiving answers, synthesize everything into the PRD structure below.

## Template Structure

Create a comprehensive PRD with these sections:

### 1. Project Name & Tagline
Concise name and one-sentence description

### 2. Target Users
Who is this for? Be specific about the audience.

### 3. Mission Statement
What problem does this solve? Why does it matter?

### 4. In Scope (This Iteration)
What we're building RIGHT NOW in this iteration. Be specific and realistic.

### 5. Out of Scope
What we're explicitly NOT building (prevents scope creep)

### 6. Architecture Overview
- Tech stack (specific versions!)
- Key components
- Data flow
- Third-party integrations

### 7. Features Breakdown
Detailed list of features to build, organized by priority:

**Phase 1 (MVP)**:
- Feature 1: Description
- Feature 2: Description

**Phase 2 (Enhancement)**:
- Feature 3: Description

**Phase 3 (Polish)**:
- Feature 4: Description

### 8. Success Criteria
How do we know we're done?
- Measurable outcomes
- User experience goals
- Technical milestones

### 9. Technical Decisions
Document key technical choices made:
- Why this framework?
- Why this architecture?
- Trade-offs considered

### 10. Known Constraints
- Budget constraints
- Time constraints
- Technical limitations
- Platform requirements

## Output

Save the PRD to the specified file (usually `PRD.md` in project root).

## Next Steps

After creating PRD:
1. Commit to git: `git add PRD.md && git commit -m "docs: add project PRD"`
2. Start first feature: `claude /guide` or `claude "Based on the PRD, what should we build first?"`

## Example PRD Output

```markdown
# Wandr - Voice-First AI Travel Companion

*Your AI travel buddy that speaks your language*

## Target Users
Solo travelers and small groups who want seamless travel experiences without language barriers

## Mission
Make international travel accessible by providing real-time voice translation, AI-powered booking assistance, and intelligent itinerary management - all controlled by voice.

## In Scope (MVP)
- Real-time voice translation (40+ languages)
- AI agent restaurant booking via phone
- Voice-controlled itinerary ("Add coffee shop on the way")
- Budget tracking
- Basic TikTok place discovery

## Out of Scope
- Group trip planning (future)
- Flight booking (future)
- Advanced analytics (future)

## Architecture
- **Mobile**: React Native + Expo SDK 52
- **Voice**: Gemini Live API + Twilio
- **Backend**: Supabase (Auth, Database, Storage)
- **AI**: PydanticAI for agent workflows
- **Social**: TikTok API for place discovery

## Features (MVP - Phase 1)

### F1: Voice Translation
Real-time translation using Gemini Live

### F2: AI Restaurant Booking
Agent calls restaurants, makes reservations

### F3: Voice Itinerary Control
"Add coffee on the way" updates itinerary

### F4: Budget Tracking
Track expenses, convert currencies

### F5: TikTok Discovery
Find trending places from TikTok

## Success Criteria
- Users can have basic conversation in foreign language
- AI successfully books 80%+ of restaurant calls
- Voice commands work with 90%+ accuracy
- Budget tracking within 5% accuracy

## Technical Decisions
- Gemini Live: Best real-time voice AI (vs OpenAI Realtime)
- Twilio: Reliable voice calling infrastructure
- Supabase: Fast development, good RLS support
- Expo: Cross-platform with good SDK support

## Known Constraints
- Gemini Live in beta (may have rate limits)
- TikTok API requires approval
- Voice calling costs ~$0.01/min (budget consideration)
```

## Notes

- Keep PRD focused and realistic
- Update as project evolves
- Reference in all planning sessions
- Foundation for all `/plan` commands
