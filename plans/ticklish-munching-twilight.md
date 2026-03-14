# Fix Proposal Send Flow - Email, Cocktails, Shopping List

## Context
The proposal email flow now works end-to-end (3 bugs fixed this session: RLS, html field, share-url). But the email the client receives is bare-bones plain text with a raw URL, the cocktail selection limit is wrong for bar service, and the shopping list doesn't auto-send when the client supplies alcohol. These fixes must not break the portal link or email delivery that was just fixed.

## Issues to Fix (4 items)

### 1. Email Template - Raw URL + Plain Text
**Problem**: The email body is plain text with `\n` → `<br>` replacement. The portal URL shows as a raw 150+ character URL with query params. Subject line shows raw ISO datetime.
**File**: `hooks/useProposalActions.ts` lines 413-422

Current code:
```ts
const emailContent =
  args.customMessage || quote.data?.customMessage ||
  `Hi ${name},\n\n...Here's your personalized proposal:\n\n${quoteUrl}\n\n...`;
await sendEmail({ ..., html: emailContent.replace(/\n/g, '<br>') });
```

**Fix**:
- Create a proper HTML email template function in a new file `services/proposalEmailTemplate.ts`
- Include: styled header, greeting, CTA button (not raw URL), footer with branding
- The CTA button links to the portal URL but displays as "View Your Proposal"
- Format subject line: `Your MTL Craft Cocktails Proposal - March 12, 2026` (human-readable date)

### 2. Cocktail Selection Limit for Bar Service
**Problem**: User says bar service stopped at 3 cocktails. Config in `config/event-configs.ts` already says 4 for bar service, 3 for workshop. The `CocktailSelectorModal` reads `limit` prop correctly.
**Root cause investigation needed**: The limit is passed correctly from config → Proposal.tsx → CocktailSelectorModal. The issue may be:
- (a) The quote's `eventType` maps to wrong config key (e.g., 'private' without service type → defaults wrong)
- (b) The portal (separate project) has its own hardcoded limit
- (c) The quote data doesn't include `cocktailLimit` so the portal can't enforce it

**Fix**: Ensure `cocktailLimit` and `serviceType` are included in the quote data sent to `/api/quotes` so the portal can read the correct limit. In `api/quotes/index.js` `enrichQuoteData`, add cocktailLimit based on event type.

**Files**:
- `api/quotes/index.js` - add `cocktailLimit` to enriched quote data
- `config/event-configs.ts` - already correct (4 bar, 3 workshop)
- `hooks/useProposalActions.ts` - pass `serviceType` in quote data

### 3. Auto-Send Shopping List When Client Supplies Alcohol
**Problem**: When the client supplies their own alcohol, they need to know what to buy. Currently `sendClientShoppingListEmail()` exists in `services/emailService.ts` but is only triggered manually. It should auto-send alongside the proposal email when `clientSuppliesAlcohol` is true.
**Files**:
- `hooks/useProposalActions.ts` - `handleSendProposal` (line 365-444)
- `services/emailService.ts` - `sendClientShoppingListEmail` (line 213-283)
- `services/calculationService.ts` - `calculateClientAlcoholList` (line 1362-1456)

**Fix**: After the proposal email sends successfully in `handleSendProposal`:
1. Check if `quote.data?.clientSuppliesAlcohol === true` (or event's `clientSuppliesAlcohol`)
2. If yes, look up the linked event from `events` state using `quote.data?.eventId`
3. Get recipes from event data
4. Call `sendClientShoppingListEmail(event, recipes)`
5. Log the action

Note: The event's `clientSuppliesAlcohol` flag may not be on the quote yet. Need to check if it's in `quote.data` or needs to be added to the quote creation flow.

### 4. Subject Line Format
**Problem**: Subject shows `Your MTL Craft Cocktails Proposal - 2026-03-12T16:30:00` (raw ISO)
**File**: `hooks/useProposalActions.ts` line 421
**Fix**: Format the date using `new Date(eventDate).toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })` → "Thursday, March 12, 2026"

## Execution Order

### Step 1: Email template + subject line (items 1 & 4)
- Create `services/proposalEmailTemplate.ts` with `generateProposalEmailHTML(params)` function
- Update `handleSendProposal` to use the template instead of plain text
- Format subject line date

### Step 2: Cocktail limit in quote data (item 2)
- Add `cocktailLimit` and `serviceType` fields to quote enrichment in `api/quotes/index.js`
- Map event type to correct limit: workshop → 3, all others → 4

### Step 3: Auto-send shopping list (item 3)
- Add `clientSuppliesAlcohol` to `ProposalBuilderData` interface and quote data
- After proposal email sends, check flag and auto-send shopping list
- Add the shopping list trigger in `handleSendProposal`

### Step 4: Tests + verification
- Update `tests/services/emailService.test.ts` if needed
- Add test for new email template function
- Run `npm run ci` (typecheck + lint + test + build)
- Browser test: create proposal, send, check Gmail for styled email with button

## Files to Modify
| File | Change |
|------|--------|
| `services/proposalEmailTemplate.ts` | **NEW** - HTML email template for proposals |
| `hooks/useProposalActions.ts` | Use template, format subject, auto-send shopping list |
| `api/quotes/index.js` | Add cocktailLimit + serviceType to enriched data |
| `components/ProposalBuilder.tsx` | Add clientSuppliesAlcohol field |
| `components/ProposalBuilder.tsx` (interface) | Add clientSuppliesAlcohol to ProposalBuilderData |

## What NOT to Change
- `services/emailService.ts` - sendEmail and sendClientShoppingListEmail work correctly now
- `api/quotes/[id]/share-url.js` - portal URL generation works
- The in-memory quote pattern in handleSendProposal - just fixed, don't break it
- `config/event-configs.ts` - limits already correct (4 bar, 3 workshop)

## Verification
1. `npm run ci` passes
2. Browser: Create proposal for Catherine Williams → Proposal Preview shows
3. Click "Send to Client" → Check Gmail for styled HTML email with "View Your Proposal" button
4. Click button → Opens portal correctly
5. Portal shows correct cocktail limit (4 for bar service)
6. If clientSuppliesAlcohol → second email with shopping list also arrives
