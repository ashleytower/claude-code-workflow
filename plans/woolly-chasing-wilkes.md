# Plan: Enhanced CRM + Wire Email Approval Flow

## Context

Ashley needs two things:

1. **Enhanced CRM**: The `contacts` table exists with `resolve_contact()` (auto-creates contacts from email/SMS/IG), but it's passive. No one looks at it. Ashley wants Max to proactively use it -- pre-event client briefings, follow-up detection, automatic enrichment from Gmail/Calendar scanning.

2. **Email approval flow must work**: When Max sends a draft notification on Telegram ("DRAFT REPLY: ..."), Ashley needs to be able to reply with "send", "change: make it shorter", or "skip" and have Max actually act on it. The instructions exist in AGENTS.md and TOOLS.md but Max may not reliably follow them because: (a) the instructions are spread across 3 files, (b) the email_queue column names don't match what the instructions reference (`from_address` not `to_address` in some instructions), and (c) there's no reinforcement in the email-master SKILL.md about handling approvals.

**The user also confirmed**: phone calls to the business line go to their cell (Vapi handles this), and they need email + Instagram approval to work.

## Approach

Two changes, both low-effort because infrastructure already exists:

### Part A: CRM Skill (new skill)

A lightweight OpenClaw skill that:
1. **Daily contact enrichment** (bash cron, zero LLM): Scans recent Gmail sent items and calendar events to auto-discover contacts via `resolve_contact()`
2. **Client briefing on-demand** (LLM, via Telegram): "Tell me about [client name]" returns everything Max knows -- contact info, all emails, DMs, quotes, corrections, memory entries
3. **Follow-up detection** (bash, part of enrichment cron): Flags contacts where last_contacted_at > 3 days ago and there's a pending quote

### Part B: Wire Email Approval Flow into SKILL.md

Add a clear "Handling Approval Commands" section to email-master SKILL.md so Max knows exactly what to do when Ashley says "send", "change", or "skip" after receiving a draft. Also add to AGENTS.md a cross-reference. The tool calls are already documented in TOOLS.md -- just needs explicit wiring.

---

## Step 1: Create CRM skill structure

**New files:**
```
skills/crm/
  SKILL.md              # Skill definition + Telegram commands
  scripts/
    enrich-contacts.sh  # Daily cron: scan Gmail sent + calendar -> resolve_contact()
```

### SKILL.md content

Frontmatter: name `crm`, description covers client lookup, briefings, follow-up detection.

**Telegram commands the skill teaches Max to handle:**
- "Who is [name]?" / "Tell me about [name]" → `search_contacts()` + query email_queue + dm_queue + memory for that contact
- "Who needs follow-up?" → query contacts where last_contacted_at < NOW() - 3 days AND there's a pending/sent email
- "Client brief for [name]" → full briefing: contact info, all interactions, quotes given, upcoming events

**The skill does NOT draft emails** -- it just surfaces info. email-master handles drafting.

### enrich-contacts.sh content

Pure bash script (zero LLM), designed to run as a launchd job or cron:

1. **Gmail sent scan**: Fetch recent sent emails (last 24h) via `GMAIL_FETCH_EMAILS` with query `in:sent newer_than:1d`. For each, extract recipient email + name, call `resolve_contact()` RPC. This ensures anyone Ashley emails gets added to contacts.

2. **Calendar scan**: Fetch upcoming 7 days of events via `GOOGLECALENDAR_LIST_EVENTS`. Extract attendee emails/names, call `resolve_contact()` for each. This captures meeting/tasting contacts.

3. **Follow-up flag**: Query contacts joined with email_queue:
   ```sql
   SELECT c.display_name, c.email_address, eq.subject, eq.created_at
   FROM contacts c
   JOIN email_queue eq ON eq.from_address = c.email_address
   WHERE eq.status = 'sent'
     AND eq.created_at < NOW() - INTERVAL '3 days'
     AND NOT EXISTS (
       SELECT 1 FROM email_queue eq2
       WHERE eq2.from_address = c.email_address
       AND eq2.created_at > eq.created_at
     )
   ```
   If any stale follow-ups found, send a Telegram summary.

**Reuses from shared/lib/common.sh:**
- `rube_execute()` for Gmail/Calendar API calls
- `supabase_query()` for contact queries
- `send_telegram_message()` for alerts
- `check_dependencies`, `check_env_vars`, `log()`, `error()`

**Lock file:** `/tmp/max-cron-locks/crm-enrich.lock` (same pattern as other scripts)

## Step 2: Symlink and register CRM skill

```bash
ln -sf /Users/ashleytower/Documents/GitHub/max-ai-employee/skills/crm \
       /Users/ashleytower/.openclaw/skills/crm
```

No cron job initially -- run enrichment manually or via launchd later. The Telegram commands work immediately via the gateway LLM reading SKILL.md.

## Step 3: Wire email approval flow into email-master SKILL.md

**File:** `skills/email-master/email-master/SKILL.md`

Add a new section after "Step 5: Send summary" called "## Handling Draft Approvals (Telegram)".

Content covers:

### When Ashley says "send" or "approve"
1. Query email_queue for most recent pending draft:
   ```sql
   SELECT id, from_address, subject, draft_response, gmail_draft_id
   FROM email_queue WHERE status = 'pending'
   ORDER BY created_at DESC LIMIT 1
   ```
2. Send via Rube MCP: `GMAIL_SEND_DRAFT` with `{draft_id: "<gmail_draft_id>"}`
3. Update queue: `UPDATE email_queue SET status = 'sent' WHERE id = '<id>'`
4. Confirm in Telegram: "Sent to [from_address]"

### When Ashley says "change: [feedback]" or "change [feedback]"
1. Query email_queue for most recent pending draft (same query)
2. Store correction in draft_corrections:
   ```sql
   INSERT INTO draft_corrections (user_id, channel, action, incoming_context, incoming_from, original_draft, source_record_id, source_table)
   VALUES ('3ed111ff-...', 'email', 'edit', 'Subject: <subject>', '<from_address>', '<draft_response>', '<id>', 'email_queue')
   ```
3. Delete old Gmail draft: `GMAIL_DELETE_DRAFT` with `{draft_id: "<old_gmail_draft_id>"}`
4. Re-draft the reply incorporating Ashley's feedback + original thread context
5. Create new Gmail draft: `GMAIL_CREATE_EMAIL_DRAFT`
6. Update email_queue with new draft_response and gmail_draft_id
7. Show new draft in Telegram

### When Ashley says "skip" or "ignore"
1. Query email_queue for most recent pending draft
2. Store rejection correction (same INSERT but action='reject')
3. Update queue: `UPDATE email_queue SET status = 'rejected' WHERE id = '<id>'`
4. Confirm: "Skipped. Won't reply to [from_address]."

### When Ashley says "tell them [content]" or "reply saying [content]"
1. Query email_queue for most recent pending/sent draft to find the thread
2. Search Gmail for the thread: `GMAIL_FETCH_MESSAGE_BY_THREAD_ID`
3. Draft reply using Ashley's content + business context + correction rules
4. Follow Step 4 (post-draft.sh) flow

**Key detail**: Use `from_address` consistently (that's the column name in email_queue), not `to_address` which doesn't exist.

## Step 4: Add contact_id to email_queue lookups

When Max drafts an email, also store the contact_id in email_queue (the FK column already exists from the unified_contacts migration). Update post-draft.sh to capture the contact_id from `resolve_contact()` response and include it in the email_queue INSERT.

This lets CRM queries join email_queue to contacts efficiently.

**File:** `skills/email-master/email-master/scripts/post-draft.sh`

Change: The `resolve_contact` call currently runs fire-and-forget in a background subshell. Move it to foreground, capture the returned UUID, and include `contact_id` in the email_queue INSERT.

## Step 5: Add IG DM approval to SKILL.md (same pattern)

The dm_queue table exists with the same status flow. Add a section or cross-reference so Max knows:
- "send" on an IG DM draft → `INSTAGRAM_SEND_TEXT_MESSAGE` with `recipient_id`
- "change" → store correction, re-draft, show new version
- "skip" → mark rejected

This uses the same pattern as email, just different API calls.

---

## Files to Modify

| File | Change |
|------|--------|
| `skills/crm/SKILL.md` | **NEW** -- CRM skill definition, Telegram commands |
| `skills/crm/scripts/enrich-contacts.sh` | **NEW** -- Daily contact enrichment (Gmail sent + calendar + follow-up detection) |
| `skills/email-master/email-master/SKILL.md` | Add "Handling Draft Approvals" section with send/change/skip flows |
| `skills/email-master/email-master/scripts/post-draft.sh` | Capture contact_id from resolve_contact, include in email_queue INSERT |
| `~/.openclaw/skills/crm` | Symlink to repo |

## What NOT to change

- contacts table schema (already has everything needed)
- resolve_contact() function (already handles find-or-create + merging)
- search_contacts() function (already does ILIKE across all fields)
- AGENTS.md approval section (already correct, SKILL.md will reinforce it)
- HEARTBEAT.md (already has follow-up logic, CRM enrichment complements it)
- inbox-watcher (already sends rich alerts, no changes needed)
- common.sh (already has all needed functions)

## Verification

1. **CRM skill**: Symlink, then tell Max on Telegram "Who is [recent client name]?" -- should return contact info + recent emails
2. **Contact enrichment**: Run `enrich-contacts.sh` manually, check contacts table grew
3. **Email send**: Have Max draft an email, reply "send" on Telegram, verify email sent in Gmail
4. **Email change**: Have Max draft, reply "change: make it shorter", verify new draft appears
5. **Email skip**: Reply "skip", verify email_queue status = rejected and correction stored
6. **Contact_id wiring**: After post-draft.sh runs, check email_queue row has non-null contact_id
