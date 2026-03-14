# Chat View Redesign Plan

## Context

The current chat view is a broken skeleton — mostly empty black screen, tiny 96px grey orb, stuck on "Initializing..." when LiveKit fails (which happens on Vercel), and the text input is disabled/useless without LiveKit. It doesn't match the Version B preview the user approved.

**Goal**: Rebuild chat-view.tsx so it looks polished and works well regardless of LiveKit connection, using existing REST API endpoints as text-input fallback.

## Approach

**Decouple from LiveKit dependency**. The chat view renders immediately with full UI. LiveKit connects in the background. If it fails, text input still works by dispatching to existing REST API endpoints (queryInventory, checkLowStock, viewPickupList, etc.) via a keyword-based command parser.

## Files to Create/Modify

| File | Action |
|------|--------|
| `lib/text-command-parser.ts` | **NEW** — Parse text input, dispatch to REST APIs |
| `components/chat/chat-view.tsx` | **REWRITE** — Full redesign |
| `app/globals.css` | **MODIFY** — Add orb keyframes, data card styles |

## Implementation Steps

### Step 1: Text Command Parser (new file)

Create `lib/text-command-parser.ts` with:

- `parseCommand(text)` — keyword matching to determine intent:
  - "check {item}" / "how much {item}" → `queryInventory(item)`
  - "low stock" / "running low" → `checkLowStock()`
  - "all inventory" / "show everything" → `getFullInventory()`
  - "pickup list" / "shopping list" → `viewPickupList()`
  - "add {item} to pickup" → `addToPickupList(item)`
  - "used {N} {item}" → `recordUsage(item, N)`
  - Unknown → return help text with example commands

- `executeCommand(cmd)` — calls the real API functions from `lib/api.ts`, returns human-readable text + optional DataCard info

### Step 2: CSS Additions (globals.css)

Add orb keyframe animations (from preview-version-b.html):
- `@keyframes orb-breathe` — idle state breathing
- `@keyframes orb-listening` — green pulse
- `@keyframes orb-speaking` — purple wave
- `@keyframes msg-appear` — message slide-up entrance
- `.data-card` styles — structured result cards

### Step 3: Chat View Rewrite (chat-view.tsx)

Complete rewrite with these sub-components:

**ChatView (root)** — Attempts LiveKit in background, renders full UI immediately regardless of connection state. If connected, wraps in `<LiveKitRoom>`. If not, everything still works.

**ChatHeader** — "Stockly" title (Instrument Serif), green/gray status dot, Sheets link button.

**VoiceOrbSection** — 120px orb (up from 96px) matching preview-version-b. Three concentric rings with CSS keyframe animations. Mic icon inside core. State-driven colors. When LiveKit connected, reads `useVoiceAssistant()` state. When disconnected, idle breathing animation.

**MessageThread** — Scrollable message area. Empty state shows tappable quick-action chips ("What's running low?", "Check vodka", "Show pickup list") instead of just placeholder text.

**ChatMessage** — User bubbles right-aligned, assistant bubbles left-aligned, with DataCard attachment support.

**DataCard** — Renders structured API results inline (item name, quantity, status badge). Matches preview-version-b styling (#1E1E1E bg, 16px radius, green/red badges).

**TextInput** — ALWAYS ENABLED. Glass morphism styling. When LiveKit connected, sends via `useChat()`. When disconnected, sends via `parseCommand()` + `executeCommand()`.

### Step 4: Verify

1. `npm run typecheck`
2. `npm test`
3. `npm run build`
4. Visual check — page should look good even without LiveKit
5. Text input should return real inventory data via REST APIs
6. Push to Vercel and verify deployment

## Key Design Decisions

- **Text input always works** — never disabled, dispatches to REST when offline
- **LiveKit is enhancement, not requirement** — UI renders immediately, voice connects in background
- **Quick-action chips** — empty state is useful, not blank
- **120px orb with mic icon** — prominent visual centerpiece matching approved preview
- **CSS keyframes for orb** — smoother than JS-driven Framer Motion for always-visible animations
- **DataCards for results** — inventory queries show structured cards, not just text
