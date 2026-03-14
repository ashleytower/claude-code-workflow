# Portal Rough Copy Research -- 2026-02-07

## Tech Stack

| Item | Value |
|------|-------|
| Next.js | 16.1.6 (App Router) |
| UI | Tailwind 3.4.17 + shadcn/ui (default style, neutral base) |
| Icons | Lucide React |
| Data fetching | SWR 2.4.0 (revalidateOnFocus: false, optimistic mutations) |
| AI Chat | ai 6.0.73 + @ai-sdk/react 3.0.75 (useChat + DefaultChatTransport) |
| Supabase | NONE -- all mock data in-memory |
| Origin | v0.dev generated |
| Fonts | Inter (sans) + Playfair Display (serif) |
| Theme | next-themes, dark default, warm gold primary hsl(36, 72%, 48%) |

## Pages (3 tabs)

1. **Proposal** (`app/page.tsx`) -- Hero, stat cards, package, staffing, add-ons, total, trust footer, mixologist chat
2. **Menu** (`app/menu/page.tsx`) -- Cocktail grid, filter pills, category sections (signature/classic/syrups), max 4 selections, chat drawer
3. **Contract** (`app/contract/page.tsx`) -- 21 collapsible legal sections, bilingual, e-signature, PDF via window.print()

## API Routes (ALL MOCK -- need rebuild)

- `GET/PATCH /api/proposal` -- in-memory ProposalData
- `POST /api/chat` -- streamText with "openai/gpt-4o-mini" string
- `GET/POST /api/menu` -- in-memory cocktail categories + selections
- `POST /api/menu/chat` -- menu-specific AI chat

## Schema Mapping: ProposalData vs Quote

### ProposalField pattern
```ts
{ value: string | number | null, source: "backend" | "user" | null }
```

### Field mapping
| ProposalData | Quote equivalent | Gap? |
|-------------|-----------------|------|
| clientName (ProposalField) | Quote.data.clientName (string) | Wrap needed |
| clientEmail (ProposalField) | Quote.client_email | Wrap needed |
| clientPhone (ProposalField) | Quote.data.clientPhone | Wrap needed |
| eventDate (ProposalField) | Quote.event_date | Wrap needed |
| startTime (ProposalField) | Quote.data.eventTime | NAME MISMATCH |
| endTime (ProposalField) | Quote.data.endTime | Direct |
| guests (ProposalField) | Quote.data.headcount | NAME MISMATCH |
| location (ProposalField) | Quote.data.location | Direct |
| address (ProposalField) | -- | MISSING |
| packageName (string) | EventTypeConfig.packageName | Config-driven |
| pricePerPerson (number) | subtotal / headcount | Calculated |
| inclusions (string[]) | Quote.data.lineItems | Different shape |
| staffing (object) | -- | MISSING |
| addOns (AddOnData[]) | Quote.data.selectedAddons + addons table | Different shape |
| depositPercent | Hardcoded 25% | Parameterize |

### Required Quote.data JSONB additions
- `address: string`
- `staffing: { ratePerHour, mixologistsRequired, serviceHours, setupHours, teardownHours }`
- `clientEdits: Record<string, { value, editedAt }>` (for ProposalField source tracking)
- `contractSigned, contractSignedBy, contractSignedAt`

## Keep vs Rebuild

### KEEP (production-quality UI)
- All 17 proposal components (hero, stats, package, staffing, addons, total, etc.)
- EditableField (crown jewel -- inline edit with save/cancel/unknown)
- CocktailCard design
- 500+ line bilingual translations (EN/FR including full contract text)
- Print/PDF CSS styles in globals.css
- Warm gold/amber color palette
- Tab navigation pattern
- Language/theme providers

### REBUILD
- All 4 API routes (mock -> Supabase)
- ProposalProvider data layer (SWR fetch -> Supabase with token auth)
- Chat transport (AI SDK -> Claude server proxy)
- Menu data (hardcoded -> Supabase cocktails table)
- Auth (none -> quote token-based access)

### DROP (unused deps)
- react-hook-form, zod, recharts, 30+ Radix primitives, embla-carousel, react-resizable-panels, vaul, sonner, cmdk, input-otp
- Only `tabs` from shadcn/ui is actually used

## Architecture Decision

[decision] Deploy as separate Next.js app on Vercel (`portal.mtlcraftcocktails.com/[quote-token]`).
Reasons: different audience than CRM, SSR/SEO, API routes for Supabase proxy, independent deploys.
Main app's ProposalTab.tsx and QuotePage.tsx can be deprecated after portal launch.

## Existing Supabase Schema

- `quotes` table: id, client_email, event_date, status, amount, template_type, language, data (JSONB), event_id, email_id, expires_at, timestamps
- `quote_templates` table: template_type + language + version, content JSONB
- `addons` table: name, category, price, price_type, description/description_fr
- `quote_views` table: quote_id, viewed_at, ip_address, user_agent, time_on_page, configurator_used
- `payments` table: type, client_email, amount, Stripe refs, event_id

## Event Type Configs (7 types in main app)

Bar service: private_bar, corporate_bar, wedding_bar, wedding_morning
Workshop: corporate_workshop, bachelorette_workshop, private_workshop
Each has: headline, subhead, packageName, image, whyLoveThis (all bilingual), cocktailLimit, CTA
