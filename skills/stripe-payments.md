---
name: stripe-payments
category: payments
frameworks: [nextjs, vite-react]
last_updated: 2026-02-10
version: stripe-node v20.3.1
---

# Stripe Payments Integration

## Quick Start

```bash
npm install stripe
```

## Environment Variables

```env
STRIPE_SECRET_KEY=sk_live_...    # Server-side only, NEVER expose to client
STRIPE_PUBLISHABLE_KEY=pk_live_... # Client-side (optional, for Stripe.js)
STRIPE_WEBHOOK_SECRET=whsec_...  # For webhook signature verification
```

## CRITICAL: Vercel Serverless Compatibility

**Stripe SDK on Vercel MUST use the fetch HTTP client.** The default Node.js `https` client uses keep-alive connections that break on serverless cold starts.

### The Problem

Vercel freezes serverless function processes between invocations. The default Stripe Node.js HTTP client (using Node's `https` module with keep-alive) tries to reuse stale TCP connections after thaw, causing:

```
StripeConnectionError: An error occurred with our connection to Stripe.
Request was retried 2 times.
```

This error is **network-level** (not authentication). The key is valid but the TCP connection is dead.

### The Fix (MANDATORY for Vercel)

```typescript
import Stripe from 'stripe'

// CORRECT: fetch-based client for serverless
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  httpClient: Stripe.createFetchHttpClient(),
  maxNetworkRetries: 3,
})
```

```typescript
// WRONG: default Node.js https client breaks on cold starts
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)
```

### Additional Vercel Requirements

```typescript
// Set maxDuration to prevent 10s default timeout (Hobby plan)
export const maxDuration = 30
```

### Applies to ALL Stripe routes:
- Checkout Sessions
- Payment Links
- Webhook handlers
- Customer management
- Any route that calls `stripe.*`

## API Key Types

| Key Type | Prefix | Usage |
|----------|--------|-------|
| Standard Secret | `sk_live_` / `sk_test_` | Full API access, server-side only |
| Restricted | `rk_live_` / `rk_test_` | Limited permissions, CAN EXPIRE |
| Publishable | `pk_live_` / `pk_test_` | Client-side safe, limited scope |

**Use `sk_live_` (standard) for production.** Restricted keys (`rk_live_`) can expire and cause `StripeAuthenticationError: api-key-expired`.

## Stripe Connect (Managed Accounts)

If the Stripe Dashboard shows "[Platform Name] helps manage this account":

- Your account is a **Standard connected account** under a Stripe Connect platform
- Your own `sk_live_` keys DO work for creating Checkout Sessions independently
- The platform has visibility into your transactions
- Stripe recommends creating a fresh standalone account for independent integrations
- For platform-mediated charges, use platform keys + `Stripe-Account` header

## Checkout Sessions (Next.js App Router)

```typescript
// app/api/payment/route.ts
import { NextRequest, NextResponse } from 'next/server'
import Stripe from 'stripe'

export const maxDuration = 30

export async function POST(request: NextRequest) {
  try {
    const key = process.env.STRIPE_SECRET_KEY
    if (!key) {
      return NextResponse.json(
        { error: 'Payment service not configured' },
        { status: 503 }
      )
    }

    const body = await request.json()
    const { clientEmail, clientName, amount, description, quoteId } = body

    // Validate inputs
    if (!clientEmail || !amount || !description) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    // CRITICAL: Use fetchHttpClient for Vercel serverless
    const stripe = new Stripe(key, {
      httpClient: Stripe.createFetchHttpClient(),
      maxNetworkRetries: 3,
    })

    const origin = request.headers.get('origin') || 'https://your-domain.com'

    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      customer_email: clientEmail,
      line_items: [
        {
          price_data: {
            currency: 'cad',
            product_data: {
              name: description,
              ...(clientName ? { description: `Client: ${clientName}` } : {}),
            },
            unit_amount: Math.round(amount * 100), // Stripe uses cents
          },
          quantity: 1,
        },
      ],
      metadata: {
        quoteId: quoteId || '',
        clientName: clientName || '',
        clientEmail,
      },
      success_url: `${origin}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${origin}/cancel`,
    })

    return NextResponse.json({ paymentLink: session.url })
  } catch (err: unknown) {
    const stripeErr = err as { type?: string; code?: string; message?: string }
    console.error('[api/payment] Error:', JSON.stringify({
      type: stripeErr.type,
      code: stripeErr.code,
      msg: stripeErr.message,
    }))
    const message = err instanceof Error ? err.message : 'Internal server error'
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
```

## Payment Links (Vite + Express)

```javascript
// api/payment-link.js (Vite backend)
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  httpClient: Stripe.createFetchHttpClient(),
  maxNetworkRetries: 3,
})

export async function createPaymentLink({ amount, description, metadata }) {
  const product = await stripe.products.create({ name: description })
  const price = await stripe.prices.create({
    product: product.id,
    unit_amount: Math.round(amount * 100),
    currency: 'cad',
  })
  const link = await stripe.paymentLinks.create({
    line_items: [{ price: price.id, quantity: 1 }],
    metadata,
  })
  return link.url
}
```

## Webhook Handling

```javascript
// api/webhook/stripe.js
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  httpClient: Stripe.createFetchHttpClient(),
  maxNetworkRetries: 3,
})

export default async function handler(req, res) {
  const sig = req.headers['stripe-signature']
  let event

  try {
    // IMPORTANT: Use raw body for signature verification
    event = stripe.webhooks.constructEvent(
      req.rawBody || req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    )
  } catch (err) {
    console.error('Webhook signature failed:', err.message)
    return res.status(400).send(`Webhook Error: ${err.message}`)
  }

  switch (event.type) {
    case 'checkout.session.completed':
      const session = event.data.object
      // Handle successful payment
      break
    case 'payment_intent.succeeded':
      // Handle payment intent success
      break
  }

  res.json({ received: true })
}
```

## Gotchas

### 1. StripeConnectionError on Vercel (CRITICAL)
**Problem**: `StripeConnectionError: An error occurred with our connection to Stripe. Request was retried 2 times.`
**Cause**: Serverless cold starts freeze TCP keep-alive connections
**Fix**: `httpClient: Stripe.createFetchHttpClient()` + `maxNetworkRetries: 3`
**Sources**: [stripe-node #1040](https://github.com/stripe/stripe-node/issues/1040), [Vercel Community](https://community.vercel.com/t/critical-stripe-live-api-connectivity-issue-connection/23103)

### 2. API Version Mismatch
**Problem**: Errors about unknown fields or changed behavior
**Fix**: Let the SDK use its default API version (don't hardcode `apiVersion`). SDK v20.3.1 defaults to `2026-01-28.clover`.

### 3. Expired Restricted Keys
**Problem**: `StripeAuthenticationError: api-key-expired` with `rk_live_` keys
**Fix**: Use `sk_live_` (standard secret key) instead. Standard keys don't expire.

### 4. Vercel Env Var Not Taking Effect
**Problem**: Updated STRIPE_SECRET_KEY on Vercel but old key still used
**Fix**: Env var changes require a redeployment. Trigger with `vercel --prod --force --yes` or push a commit.
**Gotcha**: Check for trailing whitespace/newlines in env var values.

### 5. Vercel Function Timeout
**Problem**: Payment route times out on Hobby plan (10s default)
**Fix**: Add `export const maxDuration = 30` to the route file.

### 6. Stripe Amounts Are in Cents
**Problem**: Charging $1 instead of $100
**Fix**: Always `Math.round(amount * 100)` when passing to Stripe.

### 7. Module-Scope vs Handler-Scope Initialization
**Problem**: `new Stripe(process.env.KEY!)` at module scope may read undefined
**Best practice**: Initialize inside the handler where env vars are guaranteed available:
```typescript
export async function POST(req) {
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
    httpClient: Stripe.createFetchHttpClient(),
    maxNetworkRetries: 3,
  })
  // ...
}
```

## SDK Version History (v17 -> v20)

- **v17->v18**: API `2025-03-31.basil`. No changes to core payment APIs.
- **v18->v19**: API `2025-09-30.clover`. `parseThinEvent` renamed to `parseEventNotification`. Dropped Node < 16.
- **v19->v20**: Array param serialization for v2 endpoints only. No v1 changes.
- **Bottom line**: For checkout sessions, payment links, and webhooks, v17->v20 is drop-in.

## Testing

```bash
# Test key validity directly
curl -s -o /dev/null -w "%{http_code}" https://api.stripe.com/v1/balance \
  -H "Authorization: Bearer sk_live_..."
# Expected: 200

# Test checkout session creation locally
node -e "
const Stripe = require('stripe');
const stripe = new Stripe('sk_test_...');
stripe.checkout.sessions.create({
  mode: 'payment',
  line_items: [{ price_data: { currency: 'cad', product_data: { name: 'Test' }, unit_amount: 100 }, quantity: 1 }],
  success_url: 'https://example.com/success',
  cancel_url: 'https://example.com/cancel',
}).then(s => console.log('OK:', s.url)).catch(e => console.error('FAIL:', e.type, e.message));
"

# Test Vercel endpoint
curl -s -X POST https://your-domain.com/api/payment \
  -H "Content-Type: application/json" \
  -d '{"clientEmail":"test@example.com","amount":1,"description":"Test"}'
```

## Debugging Checklist

1. Key valid? `curl https://api.stripe.com/v1/balance -H "Authorization: Bearer $KEY"` -> 200
2. Key type? `sk_live_` (standard, doesn't expire) vs `rk_live_` (restricted, can expire)
3. Using fetchHttpClient? `Stripe.createFetchHttpClient()` (mandatory on Vercel)
4. maxDuration set? `export const maxDuration = 30` (prevents 10s timeout)
5. Env var deployed? `vercel env ls production` then redeploy if changed
6. Trailing whitespace? Check env var value in Vercel dashboard
7. Connect account? Check if "helps manage this account" banner exists

## Related

- Memory: `~/.claude/memory/topics/stripe.md`
- Memory: `~/.claude/memory/topics/stripe-payments.md`
- Research: `~/.claude/memory/research/2026-02-10-stripe-connect-vercel-connection-research.md`
- Vercel deployment: `~/.claude/skills/vercel-express-deployment.md`

## Updates

- 2026-02-10: Created skill from client portal Stripe Checkout implementation
  - StripeConnectionError fix: fetchHttpClient for Vercel serverless
  - Stripe Connect / managed account documentation
  - API key types and expiration behavior
  - Vercel-specific gotchas (timeout, env vars, cold starts)
  - SDK version migration notes (v17->v20)
