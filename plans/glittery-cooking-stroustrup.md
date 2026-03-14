# Plan: Wire Voice-to-Portal Proposal Flow

## Context

The owner wants one seamless flow: say "create a workshop for Sarah Jones, 12 people, next Sunday, 123 Main Street, send her the proposal" and the client gets an email with a link to **portal.mtlcraftcocktails.com** (the external Next.js portal with 3 tabs: Proposal, Menu, Confirmation).

**Current state:** The flow is 90% wired. Voice -> createQuote -> Supabase works. The external portal can already read quotes from Supabase (same instance). But two things are broken:

1. **Portal URLs point to the wrong place.** `api/quotes/[id]/share-url.js` generates `https://{host}/quote/{id}` (the in-app portal), not `https://portal.mtlcraftcocktails.com/{id}` (the external portal).
2. **The proposal email is a bare text link.** When `sendToClient=true`, `handleCreateQuote` sends a raw `<a href>` email instead of the branded template the payment-link endpoint uses.

Both repos share the same Supabase instance. The external portal already handles view tracking, client edits, contract signing, and Stripe payments. No portal code changes needed.

## Changes (Main App Only)

### 1. Fix portal URL generation in `api/quotes/[id]/share-url.js`

**File:** `api/quotes/[id]/share-url.js`

Change `getPortalBase()` to return the external portal URL:
- Add env var `CLIENT_PORTAL_URL` (default: `https://portal.mtlcraftcocktails.com`)
- URL format: `https://portal.mtlcraftcocktails.com/{quoteId}` (no `/quote/` prefix -- the external portal uses `/{token}` routes)
- Hash fragments still work: `#menu`, `#contract`
- Remove the `ensureQuotePath()` logic that appends `/quote`

### 2. Fix portal URL in quote creation API response

**File:** `api/quotes/index.js` (line 397-399)

Currently: `const url = \`${baseUrl}/quote/${quote.id}?${buildPortalAccessQuery(access)}\``
This uses `resolveBaseUrl(req)` which returns the main app URL.

Change to use `CLIENT_PORTAL_URL` env var:
```js
const portalBase = (process.env.CLIENT_PORTAL_URL || 'https://portal.mtlcraftcocktails.com').replace(/\/+$/, '');
const url = `${portalBase}/${quote.id}`;
```
No `/quote/` prefix -- the external portal uses `/{token}` routes directly.
No portal access query params needed -- the external portal uses Supabase anon key to read quotes by UUID.

### 3. Upgrade the proposal email template

**File:** `hooks/useProposalActions.ts` (lines 482-498)

Replace the inline HTML string with a branded bilingual email template matching the style of `api/payment-link.js` (lines 36-170). The template should include:
- MTL Craft Cocktails header with brand gradient
- Bilingual greeting (EN/FR)
- Event summary card (date, headcount, event type, location)
- Total amount and deposit info
- "View Your Proposal / Voir votre proposition" CTA button linking to external portal
- Trust footer with tax numbers
- Same styling as payment-link email (consistent brand experience)

### 4. Fix `handleSendProposal` portal URL

**File:** `hooks/useProposalActions.ts` (lines 775-852)

`handleSendProposal` calls `/api/quotes/{id}/share-url` to get the URL, then emails it. Once step 1 is done, this will automatically return the correct external portal URL. But the email template here is also bare text (line 821). Upgrade it to use the same branded template from step 3.

Extract the branded email template into a shared helper function so both `handleCreateQuote` (sendToClient path) and `handleSendProposal` use the same template.

### 5. Update `.env.example`

**File:** `.env.example`

Add `CLIENT_PORTAL_URL=https://portal.mtlcraftcocktails.com` with a comment explaining it.

### 6. Write regression tests

**New file:** `tests/api/quotes-share-url-portal.test.ts`

Test that:
- `share-url` returns external portal URL (not in-app)
- URL format is `https://portal.mtlcraftcocktails.com/{id}` (no `/quote/` prefix)
- Hash fragments work (#menu, #contract)
- Fallback works when `CLIENT_PORTAL_URL` is not set

**New file:** `tests/hooks/useProposalActions-email.test.ts`

Test that:
- `handleCreateQuote` with `sendToClient=true` sends branded email with portal link
- `handleSendProposal` sends branded email with portal link
- Email contains both EN and FR text
- Email contains event details (date, headcount, type)

## Files to Modify

| File | Change |
|------|--------|
| `api/quotes/[id]/share-url.js` | Return external portal URL |
| `hooks/useProposalActions.ts` | Branded email template + shared helper |
| `.env.example` | Add `CLIENT_PORTAL_URL` |
| `tests/api/quotes-share-url-portal.test.ts` | New: portal URL tests |
| `tests/hooks/useProposalActions-email.test.ts` | New: email template tests |

| `api/quotes/index.js` | Fix `url` in POST response (line 399) to use external portal |
| `api/lib/autoProposal.js` | Ensure auto-send uses external portal URL |
| `api/quotes/[id]/portal-links.js` | Ensure portal links point externally |

## What Does NOT Change

- External portal (`client-portal-proposal` repo) -- no changes needed
- Supabase schema -- no changes needed
- Voice pipeline / skill bundles / tool executor -- already working
- Quote creation logic -- already working
- View tracking -- external portal already handles this

## Verification

1. `npm run typecheck` -- passes
2. `npm test` -- passes (including new tests)
3. `npm run lint` -- passes
4. `npm run build` -- passes
5. Manual test: create quote via voice, verify email arrives with branded template and `portal.mtlcraftcocktails.com/{id}` link
6. Manual test: click portal link, verify it opens on external portal with correct data
7. Manual test: send proposal via voice, verify same branded email
8. Check: quote status updates to 'viewed' when client opens portal link
