# Stripe Connect + Vercel Connection Research

### 2026-02-10 - Stripe Connect managed accounts and Vercel StripeConnectionError

## Question 1: "Sampark Inc helps manage this account" banner
[research] The Stripe dashboard shows "[Platform name] helps manage this account" when your Stripe account is a **Standard connected account** under a Stripe Connect platform. "Sampark Inc" is the platform. Your account has its own dashboard and API keys, but the platform has some control over it. Stripe recommends creating a fresh standalone account if you want to build your own integration without platform dependencies.

## Question 2: StripeConnectionError on Vercel serverless
[debug] Root cause: serverless cold starts and frozen TCP connections. Lambda/Vercel freeze processes between invocations, killing keep-alive connections. On thaw, SDK tries to reuse dead connections -> ECONNRESET/EPIPE -> StripeConnectionError.
- Fix 1: Use `Stripe.createFetchHttpClient()` instead of default Node http agent (already done in client portal)
- Fix 2: Set `maxNetworkRetries: 3` (already done in client portal)
- Fix 3: Verify env vars are correctly set in Vercel dashboard (common gotcha: trailing whitespace/newlines in secret keys)
- The main app webhook handler (`api/webhook/stripe.js`) does NOT use fetchHttpClient or maxNetworkRetries - potential issue

## Question 3: Vercel pdx1 region issues
[research] No Stripe-specific pdx1 issue found. But there ARE documented Vercel egress network issues across all regions (iad1, sfo1, cle1). One unresolved community thread reports TCP handshake timeouts for all outbound connections. Vercel has intermittently moved pdx1 builds to iad1 during incidents. Not a Stripe-specific problem - it's Vercel infrastructure.

## Question 4: Connected account API keys for Checkout Sessions
[research] YES, Standard connected accounts have their own API keys and CAN use them directly. A Standard account "has a relationship with Stripe, is able to log in to the Dashboard, and can process charges on their own." However, if you want platform fee collection, you must use the platform's keys + Stripe-Account header. For independent Checkout Sessions (no platform fees), the account's own sk_live_ key works fine.
