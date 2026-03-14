# Auto-Proposal Workflow + Workflow Status Tags

## Context

Lead capture already works: Webflow form -> event created -> calendar added -> tile appears. But after that, nothing happens automatically. The owner must manually generate the proposal, copy the portal link, and email it. For workshops (which have standard per-person pricing), this should be fully automatic.

Two changes:
1. **Auto-proposal**: After event creation, if enough info exists (especially workshops), auto-generate quote, send portal link, schedule follow-ups
2. **Workflow tags on tiles**: Show "Proposal Sent", "Waiting for Email", "Follow-up Scheduled" as small tags on each event tile

---

## Phase 1: Workflow Status Tags (on `fix/event-tiles-enhancement` branch)

### 1a. Create `utils/workflowStatusTags.ts`

Pure function — derives tags from existing EventData fields:

```
lead_status === 'quote_sent'        -> "Proposal Sent" (amber)
draft_status === 'sent' + no reply 48h -> "Awaiting Reply" (orange)
next_reminder_at in future          -> "Follow-up Scheduled" (blue)
quote_sent + future reminder        -> "Workflow Active" (purple)
lead_status === 'deposit_paid'      -> "Deposit Received" (green)
```

Returns array of `{ label, colorClass }` sorted by priority.

### 1b. Add tags to `components/crm-bento-grid.tsx`

After the "Headcount + staff" line (~line 1086), render workflow tags as a row of small pills:

```tsx
{workflowTags.length > 0 && (
  <div className="flex flex-wrap gap-1 pt-0.5">
    {tags.slice(0, 2).map(tag => (
      <span className={cn("rounded px-1.5 py-0.5 text-[8px] font-semibold", tag.colorClass)}>
        {tag.label}
      </span>
    ))}
  </div>
)}
```

Same visual style as the PAID/Bar Rental/Glass Rental badges above.

### 1c. Tests

- `tests/utils/workflowStatusTags.test.ts` — 10 test cases for tag derivation logic

**Files modified:**
- NEW: `utils/workflowStatusTags.ts`
- NEW: `tests/utils/workflowStatusTags.test.ts`
- EDIT: `components/crm-bento-grid.tsx` (import + render tags)

---

## Phase 2: Auto-Proposal Server Module (new branch `feat/auto-proposal-workflow`)

### 2a. Create `api/lib/autoProposal.js`

Shared module with two functions:

**`checkEligibility(eventData)`** — returns `{ eligible, autoSend, reason, missingFields }`
- Workshop: auto-send if `clientEmail + headcount + eventDate` present
- Bar Service: eligible (draft only, no auto-send) if `clientEmail + headcount` present
- Wedding: never auto-send (needs personal touch)

**`executeAutoProposal(supabase, eventData, options)`** — full orchestration:
1. Check eligibility
2. Create quote in `quotes` table (same insert as `api/quotes/index.js`)
3. Generate portal URL via `createPortalAccessForQuote()` from `api/utils/portalAccess.js`
4. Portal URL: `${PORTAL_URL || 'https://portal.mtlcraftcocktails.com'}/${quoteId}?exp=...&sig=...`
5. If autoSend: send email via Resend (pattern from `useProposalActions.ts:handleSendProposal`)
6. If autoSend: update quote status to `'sent'`, set `sent_at`
7. Update event: `status: 'Proposal Sent'`, `lead_status: 'quote_sent'`, `source_quote_id`, `next_reminder_at` (3 days)
8. If NOT autoSend: keep quote as `'draft'`, update event `draft_status: 'draft_ready'`
9. Return `{ success, quoteId, portalUrl, emailSent, action: 'sent' | 'drafted' }`

### 2b. Create `api/auto-proposal.js`

Thin API endpoint for client-side callers (voice/manual lead creation):
- POST with `{ eventId, language? }`
- Auth: supabase session
- Calls `executeAutoProposal()` from `api/lib/autoProposal.js`

### 2c. Wire into `api/leads.js` (Webflow webhook path)

After line 129 (event created), before calendar sync:
```js
// Auto-proposal check (non-blocking)
try {
  const autoResult = await executeAutoProposal(supabase, eventData);
  // Include in response: autoResult.action, autoResult.emailSent
} catch (e) {
  console.warn('[Leads] Auto-proposal failed:', e);
}
```

Direct import — no HTTP self-call. Both use the same service-key Supabase client.

### 2d. Wire into `services/leadService.ts` (voice path)

After event creation, call `POST /api/auto-proposal` via `apiFetch`. Non-blocking — failures don't break lead creation.

### 2e. Wire into `services/leadCaptureService.ts` (email path)

After `captureNewLead()`, call `POST /api/auto-proposal`. This path already creates quotes but doesn't send — now it will.

### 2f. Tests

- `tests/api/lib/autoProposal.test.ts` — eligibility + execution (mock Supabase, Resend)
- `tests/api/auto-proposal.test.ts` — endpoint auth + validation

**Files modified:**
- NEW: `api/lib/autoProposal.js`
- NEW: `api/auto-proposal.js`
- NEW: `tests/api/lib/autoProposal.test.ts`
- NEW: `tests/api/auto-proposal.test.ts`
- EDIT: `api/leads.js` (~5 lines after event insert)
- EDIT: `services/leadService.ts` (~5 lines after createLead)
- EDIT: `services/leadCaptureService.ts` (~5 lines after captureNewLead)

---

## Phase 3: Voice Command (same branch as Phase 2)

Add voice tool `checkAutoProposal` to a skill bundle so the owner can say "Check if Sarah's quote can auto-send" or "Send Sarah's proposal automatically".

- Tool definition in `services/skills/bundles/` (proposals bundle)
- Handler in `VoiceToolContext.tsx` + `App.tsx`

---

## Verification

1. `npm run ci` (typecheck + lint + test + build) passes
2. Create test Webflow-style lead with workshop + email + headcount + date -> verify quote created + email sent + event status updated
3. Create test bar service lead -> verify quote drafted only, no email sent
4. Check event tiles show workflow tags matching the status
5. Voice: "New workshop lead Sarah, 20 people, March 15, sarah@test.com" -> auto-proposal fires

---

## Key Existing Code to Reuse

| What | Where | How |
|------|-------|-----|
| Portal URL generation | `api/utils/portalAccess.js` | `createPortalAccessForQuote()`, `buildPortalAccessQuery()` |
| Quote creation pattern | `api/quotes/index.js` | Supabase insert with same schema |
| Email sending | `services/emailService.ts` | `sendEmail({ to, toName, subject, html })` |
| Email template | `useProposalActions.ts:156-171` | Existing proposal email HTML |
| Event status fields | `types.ts:115-141` | `lead_status`, `draft_status`, `next_reminder_at` already in schema |
| Supabase service client | `api/leads.js:22-25` | Same pattern for server-side writes |
