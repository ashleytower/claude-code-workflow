
### 2026-02-08 - Balance reminder cron job for MTL Craft Cocktails
[pattern] Created automated balance reminder system for events:
- Cron runs daily at 10 AM EST (14:00 UTC) via Vercel Cron
- Queries quotes with status='accepted' and event_date = today + 3 days
- Filters for paymentStatus != 'paid_in_full' and !balanceReminderSent
- Creates Stripe Payment Link for balance amount (total - deposit)
- Sends branded bilingual email (EN/FR) with payment link
- Marks quote as balanceReminderSent to avoid duplicates
- Pattern matches existing cron jobs: check-stale-quotes.js, process-follow-ups.js
- Email template matches MTL brand style from payment-link.js
- Security: Uses CRON_SECRET authorization header (Vercel standard)
