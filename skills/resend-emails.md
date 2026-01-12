---
name: resend-emails
category: integration
frameworks: [nextjs, vercel]
last_updated: 2026-01-12
version: resend 4.x
---

# Resend Email Integration

## Quick Start

```bash
npm install resend svix
```

## Environment Variables

```env
RESEND_API_KEY=re_xxxxx
RESEND_WEBHOOK_SECRET=whsec_xxxxx  # From Resend dashboard > Webhooks
```

## Outbound Email (Simple)

```typescript
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

const { data, error } = await resend.emails.send({
  from: 'Name <name@yourdomain.com>',
  to: recipient,
  subject: 'Subject',
  text: 'Plain text body',
  html: '<p>HTML body</p>'  // optional
});
```

## Inbound Email Webhook

### Setup in Resend Dashboard

1. Go to Resend Dashboard > Receiving > Add Domain
2. Add DNS records (MX + TXT for verification)
3. Create webhook at Resend Dashboard > Webhooks
4. Select `email.received` event
5. Copy signing secret to `RESEND_WEBHOOK_SECRET`

### Webhook Handler (Vercel)

```javascript
// api/webhook/email.js
import { Webhook } from 'svix';

export const config = {
  api: { bodyParser: false }  // Required for Svix signature
};

export default async function handler(req, res) {
  // 1. Get raw body
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const rawBody = Buffer.concat(chunks).toString();

  // 2. Verify Svix signature
  const webhook = new Webhook(process.env.RESEND_WEBHOOK_SECRET);
  const headers = {
    'svix-id': req.headers['svix-id'],
    'svix-timestamp': req.headers['svix-timestamp'],
    'svix-signature': req.headers['svix-signature'],
  };

  let event;
  try {
    event = webhook.verify(rawBody, headers);
  } catch (err) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  // 3. Handle email.received event
  if (event.type === 'email.received') {
    const { email_id, from, to, subject } = event.data;

    // Fetch full email body (webhook only has metadata)
    const response = await fetch(
      `https://api.resend.com/emails/receiving/${email_id}`,
      { headers: { 'Authorization': `Bearer ${process.env.RESEND_API_KEY}` }}
    );
    const fullEmail = await response.json();
    // fullEmail.text, fullEmail.html, fullEmail.attachments
  }

  return res.status(200).json({ success: true });
}
```

## CRITICAL: Polling Backup for Webhooks

**Issue**: Resend webhooks sometimes don't fire for new inbound emails.

**Solution**: Implement polling backup that runs on cron.

### Polling Endpoint

```javascript
// api/email/sync.js
export default async function handler(req, res) {
  // Fetch all received emails
  const response = await fetch('https://api.resend.com/emails/receiving', {
    headers: { 'Authorization': `Bearer ${process.env.RESEND_API_KEY}` }
  });
  const { data: emails } = await response.json();

  // Get existing IDs from your database
  const existingIds = new Set(/* query your DB */);

  // Process only new emails
  for (const email of emails) {
    if (!existingIds.has(email.id)) {
      // Fetch full content and save
      const full = await fetch(`https://api.resend.com/emails/receiving/${email.id}`, ...);
      // Save to database
    }
  }

  return res.status(200).json({ success: true, processed: newCount });
}
```

### Vercel Cron Job

```json
// vercel.json
{
  "crons": [
    {
      "path": "/api/email/sync",
      "schedule": "*/15 * * * *"
    }
  ]
}
```

## Email Filtering (Spam Prevention)

```javascript
const BLOCKED_DOMAINS = [
  'github.com', 'vercel.com', 'resend.com',
  'notifications.github.com', 'noreply.github.com',
  'facebookmail.com', 'linkedin.com', 'twitter.com',
  'mailchimp.com', 'sendgrid.net', 'amazonses.com'
];

// Allowed noreply senders (leads + payments)
const ALLOWED_NOREPLY = [
  'dubsado.com',      // Lead notifications (ONLY "New Lead:" emails)
  'stripe.com',       // Payment notifications
  'square.com',       // Payment notifications
  'interac.ca',       // E-transfers
];

// CRITICAL: Dubsado sends many admin emails (reminders, approvals, etc.)
// Only process emails with "New Lead:" in subject
if (domain.includes('dubsado.com')) {
  if (!subjectLower.includes('new lead:')) {
    return { process: false, reason: 'dubsado_not_new_lead' };
  }
}

function shouldProcessEmail(fromEmail, subject, bodyText) {
  const domain = fromEmail.match(/@([a-z0-9.-]+)/i)?.[1] || '';

  // Block known system domains
  if (BLOCKED_DOMAINS.some(b => domain.includes(b))) {
    return { process: false, reason: 'blocked_domain' };
  }

  // Check noreply
  if (fromEmail.includes('noreply@') || fromEmail.includes('no-reply@')) {
    if (!ALLOWED_NOREPLY.some(a => domain.includes(a))) {
      return { process: false, reason: 'blocked_noreply' };
    }
  }

  // Check newsletter indicators
  const newsletterKeywords = ['unsubscribe', 'email preferences', 'opt out'];
  if (newsletterKeywords.some(k => bodyText.toLowerCase().includes(k))) {
    return { process: false, reason: 'newsletter' };
  }

  return { process: true };
}
```

## Gotchas

### 1. parseEmailAddress Must Handle Arrays

The `reply-to` header can come as an array, not a string:

```javascript
function parseEmailAddress(str) {
  // Handle array (take first element)
  if (Array.isArray(str) && str.length > 0) {
    str = str[0];
  }

  // Ensure str is a string
  if (!str || typeof str !== 'string') {
    return null;
  }

  // Parse "Name <email>" format
  const match = str.match(/^(?:"?([^"<]+)"?\s*)?<?([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})>?$/);
  if (match) {
    return { name: match[1]?.trim() || null, email: match[2] };
  }
  return null;
}
```

### 2. Extract Original Sender from Forwarded Emails

When emails are forwarded (e.g., Gmail > Google Workspace > Resend), extract original sender:

```javascript
function extractOriginalSender(fullEmail, bodyText) {
  const headers = fullEmail?.headers || {};

  // Check forwarding headers
  const headerKeys = ['x-original-from', 'reply-to', 'x-forwarded-from'];
  for (const key of headerKeys) {
    const value = headers[key] || headers[key.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join('-')];
    if (value) {
      const parsed = parseEmailAddress(value);
      if (parsed) return parsed;
    }
  }

  // Parse from body: "From: Name <email@example.com>"
  const fromMatch = bodyText?.match(/From:\s*([^<\n]+)?<?([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})>?/i);
  if (fromMatch) {
    return { name: fromMatch[1]?.trim() || null, email: fromMatch[2] };
  }

  return null;
}
```

### 3. Webhook Body Parsing Disabled

Must disable body parsing for Svix signature verification:

```javascript
export const config = {
  api: { bodyParser: false }
};
```

### 4. Fetch Full Email Content

Webhook payload only contains metadata. Must fetch full content:

```javascript
// Webhook gives you: email_id, from, to, subject
// Must fetch for: text, html, attachments, headers
const response = await fetch(`https://api.resend.com/emails/receiving/${email_id}`, {
  headers: { 'Authorization': `Bearer ${process.env.RESEND_API_KEY}` }
});
```

### 5. Add Your Own Domain to Allowed Noreply

If forwarding through your own domain, add it to allowed list:

```javascript
const ALLOWED_NOREPLY = [
  // ... other allowed
  'mail.yourdomain.com',  // Your inbound domain
  'yourdomain.com',
];
```

## Database Schema

```sql
CREATE TABLE emails (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resend_id TEXT UNIQUE,  -- For deduplication
  direction TEXT CHECK (direction IN ('inbound', 'outbound')),
  from_email TEXT NOT NULL,
  from_name TEXT,
  to_email TEXT NOT NULL,
  subject TEXT,
  body_text TEXT,
  body_html TEXT,
  status TEXT DEFAULT 'new',
  ai_category TEXT,
  ai_summary TEXT,
  attachments JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Upsert to handle duplicate webhooks
INSERT INTO emails (resend_id, ...)
VALUES ($1, ...)
ON CONFLICT (resend_id) DO UPDATE SET updated_at = NOW();
```

## Testing

```bash
# Test webhook endpoint
curl -X GET https://your-app.vercel.app/api/webhook/email

# Manual sync trigger
curl https://your-app.vercel.app/api/email/sync
```

## Updates

- 2026-01-12: Initial skill created
- 2026-01-12: Added polling backup for webhook reliability issues
- 2026-01-12: Added email filtering (spam, newsletters, system notifications)
- 2026-01-12: Added array handling for reply-to header
- 2026-01-12: Added original sender extraction for forwarded emails
- 2026-01-12: Dubsado filtering - ONLY allow "New Lead:" emails, block admin/reminder emails
