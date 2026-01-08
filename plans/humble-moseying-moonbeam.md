# Wandr Voice-First AI Travel App - Implementation Plan

## Overview
Build a voice-first travel companion app by combining two existing boilerplates with our Supabase infrastructure. The app enables real-time voice translation and AI-powered phone calls to book restaurants internationally.

## Source Repositories

### Repo 1: Frontend Base
**[Gemini Live React Native](https://github.com/pathakmukul/Gemini-LIVE-API-Bidirectional-Audio-in-React-Native)**
- React Native (Expo)
- Bidirectional audio streaming
- WebSocket to Gemini Live API
- Real-time voice translation

### Repo 2: Backend Base
**[Gemini + Twilio Telephony](https://github.com/sa-kanean/gemini-live-voice-ai-agent-with-telephony)**
- Python/Pipecat server
- Twilio phone calling
- Gemini Live for conversations
- Function calling support

### Existing Travel-App Assets to Salvage
From `/Users/ashleytower/Travel-App/`:
- ✅ Supabase schema (trips, activities, travelers, scheduled_activities, etc.)
- ✅ Supabase client setup and auth flow
- ✅ Budget table definitions (for future use)
- ✅ Database types (`types/database.ts`)
- ❌ Skip: Old UI components, Zustand store, offline sync (too complex)

---

## New Repository Structure

```
wandr-ai/                          # New root directory
├── app/                           # React Native frontend (from Repo 1)
│   ├── src/
│   │   ├── screens/
│   │   │   ├── TodayScreen.tsx
│   │   │   ├── TranslateScreen.tsx
│   │   │   ├── CallScreen.tsx
│   │   ├── components/
│   │   ├── hooks/
│   │   └── lib/
│   ├── package.json
│   └── app.json
│
├── server/                        # Backend (from Repo 2)
│   ├── main.py                    # FastAPI/Pipecat server
│   ├── twilio_handler.py
│   ├── gemini_client.py
│   └── requirements.txt
│
└── supabase/                      # Database (from existing Travel-App)
    ├── migrations/
    ├── schema.sql
    └── seed.sql
```

---

## PHASE 1: Foundation Setup (PARALLELIZABLE - 3 branches)

### Branch 1: `feature/frontend-base`
**Agent Task:** Set up React Native frontend
**Time:** 2-3 hours

**Steps:**
1. Create new directory `wandr-ai/`
2. Clone Repo 1 into `wandr-ai/app/`
3. Install dependencies: `cd app && npm install`
4. Test baseline: Run `npm start` and verify Expo works
5. Remove unnecessary features from boilerplate
6. Configure environment variables:
   ```env
   EXPO_PUBLIC_GEMINI_API_KEY=
   EXPO_PUBLIC_SUPABASE_URL=
   EXPO_PUBLIC_SUPABASE_ANON_KEY=
   ```

**Deliverable:** Working Expo app with Gemini Live voice translation

**Critical Files:**
- `wandr-ai/app/src/screens/VoiceScreen.tsx` (main voice interface)
- `wandr-ai/app/src/lib/gemini-live.ts` (WebSocket client)
- `wandr-ai/app/.env`

---

### Branch 2: `feature/backend-server`
**Agent Task:** Set up Python backend with Twilio + Gemini
**Time:** 2-3 hours

**Steps:**
1. Clone Repo 2 into `wandr-ai/server/`
2. Install dependencies: `pip install -r requirements.txt`
3. Configure Twilio credentials:
   ```env
   TWILIO_ACCOUNT_SID=
   TWILIO_AUTH_TOKEN=
   TWILIO_PHONE_NUMBER=
   GEMINI_API_KEY=
   ```
4. Test baseline: Start server, verify Twilio webhook endpoints respond
5. Customize function calling for restaurant reservations:
   - `book_reservation(restaurant_name, date, time, party_size)`
   - `check_availability(restaurant_name, date, time)`
   - `cancel_reservation(confirmation_code)`
6. Deploy to Railway or Render

**Deliverable:** Python server that can make outbound calls via Twilio

**Critical Files:**
- `wandr-ai/server/main.py` (FastAPI server entry)
- `wandr-ai/server/twilio_handler.py` (call logic)
- `wandr-ai/server/reservation_tools.py` (function calling definitions)

---

### Branch 3: `feature/supabase-setup`
**Agent Task:** Migrate Supabase schema and auth
**Time:** 1-2 hours

**Steps:**
1. Create `wandr-ai/supabase/` directory
2. Copy from existing Travel-App:
   - `types/database.ts` → `wandr-ai/app/src/types/database.ts`
   - Supabase client setup from `lib/supabase.ts`
   - Schema definitions (trips, activities, travelers, scheduled_activities)
3. Create new Supabase project: `wandr-ai-prod`
4. Run migrations:
   ```sql
   -- Core tables
   CREATE TABLE trips (...);
   CREATE TABLE activities (...);
   CREATE TABLE scheduled_activities (...);
   CREATE TABLE travelers (...);

   -- Budget tables (for later)
   CREATE TABLE budget_categories (...);
   CREATE TABLE expenses (...);
   ```
5. Enable RLS policies
6. Test: Create dummy trip via Supabase dashboard

**Deliverable:** Working Supabase project with all tables and auth

**Critical Files:**
- `wandr-ai/supabase/schema.sql` (consolidated schema)
- `wandr-ai/app/src/lib/supabase.ts` (client config)
- `wandr-ai/app/src/types/database.ts` (TypeScript types)

---

## PHASE 2: Integration (SEQUENTIAL - after Phase 1)

### Task: Wire Frontend → Backend → Supabase
**Time:** 3-4 hours

**Steps:**
1. **Frontend → Backend:**
   - Add API calls from React Native to Python server
   - Create `callRestaurant(activityId)` function in app
   - WebSocket for real-time call transcripts

2. **Backend → Supabase:**
   - Add Supabase client to Python server
   - Save reservation results to `scheduled_activities` table
   - Update activity status after successful booking

3. **Frontend → Supabase:**
   - Implement auth flow (sign in with email)
   - Fetch trips and activities
   - Display schedule in simple list view

**Critical Files:**
- `wandr-ai/app/src/api/backend.ts` (API client)
- `wandr-ai/server/supabase_client.py` (Python Supabase SDK)
- `wandr-ai/app/src/screens/TodayScreen.tsx` (display schedule)

**Testing Checklist:**
- [ ] User can sign in with email/password
- [ ] App fetches trip data from Supabase
- [ ] Tapping "Book" triggers Python server call
- [ ] Server calls Twilio → Gemini speaks
- [ ] Transcript streams back to app in real-time
- [ ] Reservation saved to Supabase on success

---

## PHASE 3: Voice Features (PARALLELIZABLE - 2 branches)

### Branch 4: `feature/voice-commands`
**Agent Task:** Implement voice command parsing for itinerary management
**Time:** 4-5 hours

**Voice Commands to Support:**
- "Add coffee on the way" → Search Google Places API, insert into schedule
- "Skip dinner reservation" → Mark activity as skipped
- "Move lunch to 2pm" → Update scheduled_activities.start_time
- "Running 15 minutes late" → Recalculate all downstream times
- "Book this place for tonight" → Trigger AI calling flow

**Implementation:**
1. Add Google Maps API integration:
   - Places API: `https://maps.googleapis.com/maps/api/place/nearbysearch/json`
   - Directions API: Check if place is on route
   - Distance Matrix API: Calculate time impact
2. Create `parseVoiceCommand()` function using Gemini:
   ```typescript
   const result = await gemini.parseIntent(transcript);
   // { intent: "add_activity", type: "coffee", location: "along_route" }
   ```
3. Implement command handlers:
   - `handleAddActivity()` → Search Places, add to Supabase
   - `handleSkipActivity()` → Update status
   - `handleMoveActivity()` → Update start_time, recalculate downstream
   - `handleRunningLate()` → Cascade time adjustments

**Deliverable:** Voice commands modify itinerary in real-time

**Critical Files:**
- `wandr-ai/app/src/lib/voice-commands.ts` (command parser)
- `wandr-ai/app/src/lib/google-maps.ts` (Places API integration)
- `wandr-ai/app/src/hooks/useVoiceCommands.ts` (React hook)

**Environment Variables:**
```env
EXPO_PUBLIC_GOOGLE_MAPS_API_KEY=
```

---

### Branch 5: `feature/translation-ui`
**Agent Task:** Build clean translation interface
**Time:** 2-3 hours

**UI Requirements:**
- Full-screen translation modal
- Large "Tap to Speak" button
- Real-time transcription display
- Toggle source/target language
- Save to phrasebook

**Implementation:**
1. Create `TranslateScreen.tsx`:
   - Microphone button (hold to record)
   - Live transcription from Gemini Live
   - Translation display (large text)
   - Save button → stores to Supabase `saved_translations` table
2. Use existing Gemini Live WebSocket from Repo 1
3. Add language selector (Gemini Live supports 40+ languages):
   - **Asian:** Japanese, Korean, Mandarin, Cantonese, Thai, Vietnamese, Hindi, Bengali, Tamil, Telugu
   - **European:** Spanish, French, Italian, German, Portuguese, Russian, Polish, Dutch, Swedish, Norwegian
   - **Middle Eastern:** Arabic, Hebrew, Turkish, Farsi
   - **Others:** Swahili, Indonesian, Malay, Filipino + 20 more

**Deliverable:** Working translation screen with phrase saving

**Critical Files:**
- `wandr-ai/app/src/screens/TranslateScreen.tsx`
- `wandr-ai/app/src/components/LanguageSelector.tsx`
- `wandr-ai/app/src/hooks/useTranslation.ts`

---

## PHASE 4: UI Polish (Optional - after core features work)

### Clean Design System
- Use shadcn-inspired colors (zinc-950 dark mode)
- Simple tab navigation: Today | Translate | Call
- Activity cards with swipe actions
- Voice button (floating action button, violet-500)

**Reference Design:**
- Generous whitespace
- Rounded corners (xl: 1rem)
- Subtle shadows
- No visual clutter

**Files to Create:**
- `wandr-ai/app/src/constants/Design.ts` (colors, typography)
- `wandr-ai/app/src/components/ui/Card.tsx`
- `wandr-ai/app/src/components/ui/Button.tsx`

---

## Critical API Keys Required

| Service | Key Name | Where to Get | Cost |
|---------|----------|--------------|------|
| Gemini | GEMINI_API_KEY | Google AI Studio | Free tier: 60 req/min |
| Twilio | TWILIO_ACCOUNT_SID | Twilio Console | ~$0.05/call |
| Twilio | TWILIO_AUTH_TOKEN | Twilio Console | - |
| Twilio | TWILIO_PHONE_NUMBER | Twilio Console | $1/month |
| Google Maps | GOOGLE_MAPS_API_KEY | Google Cloud Console | $200 free credit |
| Supabase | SUPABASE_URL | Supabase Dashboard | Free tier |
| Supabase | SUPABASE_ANON_KEY | Supabase Dashboard | - |

---

## Testing Checklist (End-to-End)

### Voice Translation
- [ ] Open app → Tap Translate tab
- [ ] Hold mic button, speak English phrase
- [ ] See real-time transcription
- [ ] See Japanese translation
- [ ] Tap Save → phrase saved to Supabase

### AI Restaurant Calling
- [ ] Create test activity "Sushi Dai" in schedule
- [ ] Tap "Book via AI"
- [ ] Backend server calls test number via Twilio
- [ ] Gemini speaks: "Hello, I'd like to make a reservation"
- [ ] See live transcript in app
- [ ] Call completes, reservation saved to Supabase

### Voice Commands (Itinerary)
- [ ] Say "Add coffee on the way"
- [ ] See Google Places results
- [ ] Select coffee shop
- [ ] Activity added to schedule between current and next stop
- [ ] Transit times recalculated

### Data Persistence
- [ ] Close app
- [ ] Reopen app
- [ ] User still signed in (Supabase auth persists)
- [ ] Trip data loads from Supabase
- [ ] Saved translations appear in phrasebook

---

## Parallel Execution Strategy

**Simultaneous Branches (3 agents):**
1. Agent A → Branch 1 (`feature/frontend-base`)
2. Agent B → Branch 2 (`feature/backend-server`)
3. Agent C → Branch 3 (`feature/supabase-setup`)

**After merge to main:**
4. Integration (single agent, sequential)

**Then parallel again (2 agents):**
5. Agent D → Branch 4 (`feature/voice-commands`)
6. Agent E → Branch 5 (`feature/translation-ui`)

**Total time estimate:** 12-16 hours (with parallelization: 6-8 hours wall time)

---

## Success Criteria

✅ App runs on Expo Go (iOS/Android)
✅ Voice translation works in 9 languages
✅ AI can make phone calls via Twilio
✅ Voice commands modify itinerary ("add coffee on the way")
✅ Data persists in Supabase
✅ Clean, minimal UI (shadcn-inspired)

---

## Next Steps After Plan Approval

1. Create new directory: `wandr-ai/`
2. Initialize git: `git init && git branch -M main`
3. Create 5 feature branches
4. Spawn parallel agents to execute Phases 1 & 3
5. Merge branches after testing
6. Deploy backend to Railway
7. Test end-to-end with real phone calls
