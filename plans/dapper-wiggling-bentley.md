# Voice Pipeline & Calendar Query Issues

## Problem Summary

User tested voice on production and found:
1. **Claude voice pipeline not activating** - Falls back to Gemini despite being configured
2. **Calendar events not found** - "Dry ice order" on 1/20/2026 in Google Calendar wasn't found by AI

---

## Issue 1: Claude Voice Pipeline Falls Back to Gemini

### Root Cause: Vercel Missing Environment Variables
The production build on Vercel likely doesn't have these env vars configured:
- `VITE_USE_CLAUDE_VOICE`
- `VITE_DEEPGRAM_API_KEY`
- `VITE_ELEVENLABS_API_KEY`

These are in `.env.local` but need to be added to Vercel's Environment Variables settings.

### Fix Required
Add to Vercel Environment Variables:
```
VITE_USE_CLAUDE_VOICE=true
VITE_DEEPGRAM_API_KEY=d07df256bc8b83a2f445f2ac311c5f6dae88c85c
VITE_ELEVENLABS_API_KEY=sk_d227dd8dd7701a491431a052f560bfaa6e5078005b22f003
```

Then redeploy to pick up the new env vars.

---

## Issue 2: Calendar Events Not Found

### Root Cause (CONFIRMED)
**`searchEvents` searches LOCAL events database, NOT Google Calendar.**

- "Dry ice order" is a Google Calendar event only
- `searchEvents` only searches the `events` state array (client bookings)
- There's no tool that searches Google Calendar by arbitrary date

### Architecture Gap
| Tool | Searches | Works For |
|------|----------|-----------|
| `queryCalendar` | Google Calendar | Pre-defined ranges (today, tomorrow, this_week) + specific date |
| `searchEvents` | Local events DB | Client bookings by date/client/status |

**Missing capability:** Search Google Calendar by arbitrary date string or event name.

### Why Claude Failed
When Claude tried `searchEvents` for "1/20/2026":
1. Claude called QUERY_TOOLS with `action: "searchEvents"`
2. Claude passed `{ value: "1/20/2026" }` but NOT `searchType`
3. SkillRouter requires `searchType` (enum: date, month, status, bartender)
4. Validation failed: `Missing required params: searchType`
5. Even if it passed, it would search wrong database (local events, not Google Calendar)

---

## Implementation Plan

### Issue 1 Fix: Add Vercel Environment Variables

**Step 1:** Use Rube MCP to add env vars to Vercel:
- `VITE_USE_CLAUDE_VOICE=true`
- `VITE_DEEPGRAM_API_KEY` (from .env.local)
- `VITE_ELEVENLABS_API_KEY` (from .env.local)

**Step 2:** Trigger redeploy to pick up new env vars

---

### Issue 2 Fix: Enhance Calendar Query (Both Parts)

**Part A: Enhance queryCalendar for arbitrary dates**

1. `services/skills/metaToolSchema.ts` - Update QUERY_TOOLS:
   - Add `specificDate` as optional param for queryCalendar
   - Allow dateRange to accept "specific" value

2. `App.tsx` - Update `handleQueryCalendar`:
   - Parse natural date strings ("1/20/2026", "January 20th")
   - Query Google Calendar for that specific date

**Part B: Fix searchEvents parameter bug**

1. `services/skills/skillRouter.ts`:
   - Auto-default `searchType` to "date" when a date-like value is provided
   - Or make searchType optional with smart inference

2. `services/skills/metaToolSchema.ts`:
   - Update searchEvents to have better parameter descriptions
   - Consider making searchType optional

---

## Files to Modify

| File | Change |
|------|--------|
| Vercel Environment Variables | Add 3 VITE_* vars for Claude pipeline |
| `services/skills/metaToolSchema.ts` | Enhance queryCalendar + fix searchEvents params |
| `services/skills/skillRouter.ts` | Add parameter defaulting logic |
| `App.tsx` | Update handleQueryCalendar for arbitrary dates |

---

## Verification Plan

1. **Issue 1:** After adding Vercel env vars and redeploying:
   - Click mic button
   - Console should show `[VoiceAssistant] Using Claude voice pipeline` (not Gemini fallback)
   - Should hear ElevenLabs voice (different from Gemini)

2. **Issue 2:** After code changes:
   - Voice: "What's on my calendar for January 20th?"
   - Should find and read "dry ice order" from Google Calendar
   - Voice: "Do I have any events on 1/20?"
   - Should work without "Missing required params" error
