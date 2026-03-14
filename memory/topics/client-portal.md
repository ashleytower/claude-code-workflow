# Client Portal Learnings

## Notes

### 2026-02-10 - Stripe metadata key mismatch between portal and main app webhook
[gotcha] Portal payment route (`app/api/payment/route.ts`) was sending `quoteId` (camelCase) in Stripe checkout session metadata, but the main app webhook (`api/webhook/stripe.js`) expects `quote_id` (snake_case). Payment goes through on Stripe but webhook can't find the quote to update. Fix: portal must use snake_case keys matching the webhook: `quote_id`, `client_email`, `client_name`, `payment_type`.

### 2026-02-10 - Portal success page missing after Stripe payment
[gotcha] After Stripe checkout completes, user is redirected to `/{quoteId}?payment=success` but the portal page didn't handle the `payment=success` query param. Fixed: added success confirmation view with green checkmark, "You're Booked!" headline, bilingual EN/FR text. Commit `e9470fb`.

### 2026-02-10 - Stripe checkout needs itemized line items (not lump sum)
[pattern] Portal TotalCard builds a `paymentLineItems` array with breakdown (package, staffing, add-ons) and sends it to `/api/payment`. The API must map these to separate Stripe `line_items` so the auto-receipt email shows the breakdown. Apply deposit ratio proportionally: `depositRatio = depositAmount / fullTotal`, then each line item's `unit_amount = item.total * depositRatio * 100`. Commit `12d3758`.

### 2026-02-10 - Stripe auto-sends receipts for Checkout sessions
[pattern] Stripe automatically emails itemized receipts when `customer_email` is set on the checkout session. No need for Resend or custom email. Verify "Successful payments" is toggled on in Stripe Dashboard > Settings > Emails.

### 2026-02-10 - Full portal payment loop
[pattern] Complete hands-free flow: Portal → Stripe Checkout (itemized) → "You're Booked!" success page → Stripe auto-receipt email → webhook updates quote to accepted + creates event in main app. Zero manual intervention needed.
