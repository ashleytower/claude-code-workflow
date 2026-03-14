# Event Tiles Fix & Enhancement Plan

## Context
Webflow webhook-created events crash when clicked (`TypeError: Cannot read properties of undefined (reading 'toLowerCase')`) because fields like `eventFormat` are undefined on webhook leads. Additionally, event tiles on the "All Events" view look cut off, the hover overlay isn't used everywhere, and there's no manual event/client creation UI (only voice commands exist).

## Tasks

### Task 1: Fix TypeError on event tile click
**Bug:** `EventDetailView.tsx:1138` calls `event.eventFormat.toLowerCase()` without null check. Webhook-created events don't have `eventFormat`.

**Files:**
- `components/EventDetailView.tsx:1138` - Add optional chaining: `event.eventFormat?.toLowerCase()`
- `components/crm-bento-grid.tsx:862-863` - Guard `event.clientName?.toLowerCase()`
- `App.tsx:516,782,785` - Guard `event.clientName?.toLowerCase()` in voice search handlers

### Task 2: Fix event tile cut-off on All Events view
The cocktail pills section has `h-14 overflow-hidden` that truncates content. Location text uses `truncate` class cutting off addresses.

**Files:**
- `components/EventCard.tsx:161` - Remove fixed `h-14` height, use `max-h-20` with scroll or show all
- `components/EventCardHover.tsx:172` - Same fix
- `components/EventCard.tsx:152` - Add `title` attr for full location on hover, keep `truncate` for layout

### Task 3: Use EventCardHover on All Events page
`AllEventsPage.tsx` already uses `EventCardHover` which has the Aceternity-style hover overlay with full details. `AllEventsView.tsx` uses plain `EventCard` without hover overlay. Switch `AllEventsView` to use `EventCardHover` so the hover info overlay appears everywhere.

**Files:**
- `components/AllEventsView.tsx` - Import and use `EventCardHover` instead of `EventCard`

### Task 4: Glassmorphic hover overlay styling
The hover overlay in `EventCardHover.tsx:189` currently uses `bg-white/95 backdrop-blur-md`. Update to glassmorphic style with subtle gradient, frosted glass effect, and better visual contrast.

**Files:**
- `components/EventCardHover.tsx:189` - Update overlay classes to glassmorphic: `bg-white/80 backdrop-blur-xl border border-white/20 shadow-xl`

### Task 5: Add manual event creation (voice already exists, add "+ New Event" button)
`handleCreateEvent` and `handleCreateLead` already exist in `useEventOpsHandlers`. Voice commands "add a new event for [name]" already work. Add a visible "+ New Event" button on the dashboard/events views that opens a minimal form (name required, everything else optional for progressive entry).

**Files:**
- `components/EventsWidget.tsx` - Add "+ New Event" button in header
- `components/AllEventsView.tsx` - Add "+ New Event" button
- `components/NewEventForm.tsx` (NEW) - Simple modal form: name (required), email, phone, event date, event type, headcount, location, notes
- `App.tsx` - Wire the form submit to the existing Supabase insert logic

## Verification
1. `npm run typecheck` - no type errors
2. `npm test` - all tests pass
3. `npm run build` - build succeeds
4. Manual test: Click webhook-created event tile - no crash
5. Manual test: Hover over event card on All Events - see glassmorphic overlay with full details
6. Manual test: Click "+ New Event" button - form opens, submit creates event
7. Voice test: "Add a new event for John Smith" still works
