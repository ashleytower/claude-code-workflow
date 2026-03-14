# Stripe SDK Notes

### 2026-02-06 - Upgraded stripe-node from v17.5.0 to v20.3.1
[version/compat] Upgraded in mtl-craft-cocktails-ai project.
- v17->v18: API 2025-03-31.basil. Removed subscription usage records, upcoming invoice methods. No changes to constructor, webhooks.constructEvent, checkout.sessions.create, products.create, prices.create, paymentLinks.create.
- v18->v19: API 2025-09-30.clover. parseThinEvent renamed to parseEventNotification. Dropped Node < 16. No changes to core payment APIs.
- v19->v20: Array param serialization change for v2 endpoints only. No changes to v1 payment APIs.
- Bottom line: For typical payment usage (checkout sessions, payment links, webhooks), v17->v20 is a drop-in upgrade. No code changes needed.

### 2026-02-10 - CRITICAL: Stripe on Vercel requires fetchHttpClient
[gotcha] Default Node.js https client breaks on Vercel serverless cold starts. Frozen TCP keep-alive connections cause StripeConnectionError after thaw.
- ALWAYS use: `new Stripe(key, { httpClient: Stripe.createFetchHttpClient(), maxNetworkRetries: 3 })`
- ALWAYS set: `export const maxDuration = 30` on payment routes (Vercel Hobby default is 10s)
- Applies to ALL Stripe routes: checkout sessions, payment links, webhooks
- Full skill: `~/.claude/skills/stripe-payments.md`

### 2026-02-10 - API key types: sk_live_ vs rk_live_
[gotcha] Restricted keys (`rk_live_`) can EXPIRE causing `StripeAuthenticationError: api-key-expired`. Standard keys (`sk_live_`) do not expire. Always use `sk_live_` for production.

### 2026-02-10 - Stripe Connect managed accounts
[research] If dashboard shows "[Platform] helps manage this account", it's a Standard connected account. Own `sk_live_` keys work for independent Checkout Sessions. Platform has transaction visibility. Stripe recommends creating standalone account for custom integrations.
