### 2026-02-07 - Portal Schema Mapping: Quote -> ProposalData

[research] Maps main app's `Quote` type to portal rough copy's `ProposalData` interface.

## Source: `types/quote.ts` -> Target: `lib/proposal-types.ts`

### Field Mapping

| Quote (Supabase) | ProposalData (Portal) | Transform |
|---|---|---|
| `quote.data.clientName` (string) | `clientName: { value, source: "backend" }` | Wrap in ProposalField |
| `quote.data.clientEmail` (string) | `clientEmail: { value, source: "backend" }` | Wrap in ProposalField |
| `quote.data.clientPhone` (string) | `clientPhone: { value, source: "backend" }` | Wrap in ProposalField |
| `quote.data.eventDate` (string) | `eventDate: { value, source: "backend" }` | Wrap in ProposalField |
| `quote.data.eventTime` (string) | `startTime: { value, source: "backend" }` | Wrap in ProposalField |
| `quote.data.endTime` (string) | `endTime: { value, source: "backend" }` | Wrap in ProposalField |
| `quote.data.headcount` (number) | `guests: { value, source: "backend" }` | Wrap in ProposalField |
| `quote.data.location` (string) | `location: { value, source: "backend" }` | Wrap in ProposalField |
| N/A | `address: { value: null, source: null }` | No equivalent in Quote |
| `quote.data.templateType` + config | `packageName` (string) | Lookup from EVENT_CONFIGS |
| Config-driven | `packageDescription` (string) | From EVENT_CONFIGS |
| Config-driven | `pricePerPerson` (number) | From pricing.ts ($45/pp bar, varies) |
| Config-driven | `inclusions` (string[]) | From EVENT_CONFIGS.whyLoveThis |
| Hardcoded 25 | `depositPercent` (number) | Always 25% |
| "Ashley" | `contactName` (string) | Hardcoded |
| "438-255-7557" | `companyPhone` (string) | Hardcoded |
| 7 | `validDays` (number) | Hardcoded |
| `quote.data.selectedAddons` | `addOns: AddOnData[]` | Lookup from addons table |
| Calculated | `staffing` object | From staffing.ts rules |

### Key Differences
- Portal ProposalField wraps values with `{ value, source }` for edit tracking
- Quote stores flat strings; portal needs wrapping function
- Quote's `lineItems[]` needs splitting into package + staffing + addons
- Quote template_type maps to EVENT_CONFIGS key for display copy

### Portal Chat API
- Currently uses `openai/gpt-4o-mini` -- switch to `@anthropic-ai/sdk` with Claude
- Uses Vercel AI SDK `@ai-sdk/react` v3 + `ai` v6

### Portal Tech Stack
- Next.js 16.1.6 (App Router)
- React 19, SWR 2.4, Tailwind 3.4, shadcn/ui
- Inter + Playfair Display fonts
- next-themes for dark mode
