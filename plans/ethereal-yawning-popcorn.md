# Test Plan: Full Webflow-to-Proposal Flow

## Context

The lead-to-proposal pipeline receives Webflow form submissions, creates events + quotes in Supabase, and either auto-sends an email or saves a draft. Last session built a bilingual email template, but the auto-send path in `autoProposal.js` (lines 488-496) still uses old plain-text HTML and wrong `from` address. We need to fix that, then test the full flow end-to-end.

## Step 1: Fix auto-send email in autoProposal.js

**File:** `api/lib/autoProposal.js` lines 488-496

**Problem:** Auto-send path uses inline HTML instead of the bilingual template. Also uses `ashley@mtlcraftcocktails.com` instead of `events@mail.mtlcraftcocktails.com`.

**Fix:**
- Import `generateProposalEmailHTML` and `formatEventDate` from the template (JS import from TS -- use the built path or dynamic import)
- Replace inline HTML with template call
- Fix `from` address to match `send-email.js`
- Keep using Resend directly (already does)

**Critical files:**
- `api/lib/autoProposal.js` -- the fix
- `services/proposalEmailTemplate.ts` -- the template to import
- `api/send-email.js` -- reference for correct `from` address

**Note:** Since `autoProposal.js` is a server-side JS file importing a TS module, check how other API files handle this (Vite/Vercel should handle `.ts` imports in API routes).

## Step 2: Check env vars on Vercel

Before testing, verify these are set on Vercel production:
- `ENABLE_WORKSHOP_AUTO_SEND` -- currently NOT in `.env.local` (auto-send disabled)
- `LEADS_WEBHOOK_SECRET` -- currently NOT in `.env.local` (webhook auth disabled)
- `RESEND_API_KEY` -- confirmed set
- `API_SECRET` -- confirmed set

## Step 3: Test scenarios via curl against production API

Use `x-app-source: {API_SECRET}` header for auth (internal service mode, simplest).

### Test A: Bar service, complete data (expect: draft, no email)
```
POST /api/leads
{
  "name": "Test Client",
  "email": "ash.cocktails@gmail.com",
  "eventType": "Bar Service",
  "headcount": 40,
  "eventDate": "2026-04-15",
  "eventTime": "6:00 PM",
  "endTime": "11:00 PM",
  "location": "456 Rue Notre-Dame, Montreal"
}
```
**Expected:** Event created, quote created as draft, draft email saved in `events.draft_content`, NO email sent.

### Test B: Bar service, missing info (expect: draft with questions)
```
POST /api/leads
{
  "name": "Incomplete Lead",
  "email": "ash.cocktails@gmail.com",
  "eventType": "Bar Service",
  "headcount": 25
}
```
**Expected:** Event created, quote created, draft email with "Quick Questions" asking for eventDate, eventTime, endTime, location.

### Test C: Workshop, complete data (expect: auto-send if flag on)
```
POST /api/leads
{
  "name": "Workshop Test",
  "email": "ash.cocktails@gmail.com",
  "eventType": "Workshop",
  "headcount": 10,
  "eventDate": "2026-04-20",
  "eventTime": "2:00 PM",
  "endTime": "5:00 PM",
  "location": "789 Rue Saint-Laurent, Montreal"
}
```
**Expected:** If `ENABLE_WORKSHOP_AUTO_SEND=true` on Vercel -> email sent with bilingual template. If not set -> draft only.

### Test D: Wedding (expect: draft only, never auto-send)
```
POST /api/leads
{
  "name": "Wedding Couple",
  "email": "ash.cocktails@gmail.com",
  "eventType": "Wedding",
  "headcount": 100,
  "eventDate": "2026-08-15",
  "eventTime": "5:00 PM",
  "endTime": "11:00 PM",
  "location": "Chateau Frontenac"
}
```
**Expected:** Event created, quote created as draft, draft saved. Never auto-sent.

## Step 4: Verify in Supabase

After each test, check:
- `events` table: event created with correct `lead_status`, `draft_status`, `missing_info`, `draft_content`
- `quotes` table: quote created with correct `status`, `amount`, `template_type`, `data`
- If email sent: quote status = `sent`, `sent_at` populated

## Step 5: Verify email received

For any test that triggers an email (Test C with flag on), check ash.cocktails@gmail.com for:
- Bilingual template (not old plain text)
- Correct `from` address
- Working portal link
- "Cheers," sign-off

## Verification checklist
- [ ] autoProposal.js uses bilingual template
- [ ] autoProposal.js uses correct `from` address
- [ ] Typecheck passes
- [ ] Tests pass
- [ ] Test A: bar service creates draft (no email)
- [ ] Test B: missing info creates draft with questions
- [ ] Test C: workshop behavior matches env flag
- [ ] Test D: wedding never auto-sends
- [ ] Events table populated correctly
- [ ] Quotes table populated correctly
- [ ] Portal link works from email
