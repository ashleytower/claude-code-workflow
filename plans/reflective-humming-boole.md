# Plan: Telegram-Native Draft Approval Flow

## Context

Currently, when Max processes emails/DMs/SMS, the Telegram notification is a batch summary with Gmail links. Ashley has to leave Telegram, open Gmail, review the draft, edit/send/delete it, then wait until the 8am cron for correction learning. This is slow and fragmented.

**Goal:** Ashley sees a summary + draft text right in Telegram, replies "send", "change [feedback]", or "skip", and Max handles everything -- including immediate correction learning.

## Architecture Decision

No inline keyboard buttons needed. Max (LLM on the gateway) already receives Ashley's Telegram replies as regular messages. We just need:
1. Richer per-email Telegram notifications (summary + draft + instructions)
2. Identity file instructions telling Max how to handle approve/change/skip
3. A Gmail send capability (search Rube for GMAIL_SEND_DRAFT or GMAIL_SEND_EMAIL)
4. Immediate correction learning (don't wait for 8am cron)

## Files to Modify

| File | Change |
|------|--------|
| `skills/shared/lib/common.sh` | Add `send_telegram_draft_notification()` function |
| `skills/email-master/email-master/scripts/process-emails.sh` | Call new notification per-email (not just batch summary) |
| `workspace/AGENTS.md` | Add draft approval command handling instructions |
| `workspace/TOOLS.md` | Document Gmail send tool slug + approval flow |
| `workspace/HEARTBEAT.md` | Update DM notification format to include draft + approval instructions |
| `skills/email-master/email-master/SKILL.md` | Update "Never auto-send" rule to allow Telegram-based approval |

## Implementation

### Step 1: Add `send_telegram_draft_notification()` to common.sh

New function in `skills/shared/lib/common.sh` (after existing `send_telegram_message`):

```bash
send_telegram_draft_notification() {
    local channel="$1"       # "email", "instagram_dm", "sms"
    local from="$2"          # sender name/handle
    local subject="$3"       # email subject or DM preview
    local summary="$4"       # 1-line gist of the incoming message
    local draft_text="$5"    # the full draft reply
    local queue_id="$6"      # email_queue or dm_queue row ID
    local extra_link="${7:-}" # optional Gmail/IG link

    local channel_emoji=""
    case "$channel" in
        email) channel_emoji="EMAIL" ;;
        instagram_dm) channel_emoji="IG DM" ;;
        sms) channel_emoji="SMS" ;;
    esac

    local message="<b>${channel_emoji} from ${from}</b>"
    [[ -n "$subject" ]] && message+="
<i>${subject}</i>"
    message+="

${summary}

<b>DRAFT REPLY:</b>
<pre>${draft_text}</pre>

Reply: <b>send</b> | <b>change</b> [feedback] | <b>skip</b>"

    [[ -n "$extra_link" ]] && message+="
${extra_link}"

    # Use existing send_telegram_message (reuse its escaping/error handling)
    send_telegram_message "$message"
}
```

### Step 2: Update process-emails.sh to send per-email notifications

In the main loop (around line 1098-1108), after creating the Gmail draft and storing in email_queue, add a per-email notification call:

```bash
# After store_in_email_queue and label_and_mark_read:

# Generate 1-line summary of the incoming email
local email_summary
email_summary=$(echo "$body" | head -c 200 | tr '\n' ' ')

# Send per-email Telegram notification with draft
local queue_row_id
queue_row_id=$(supabase_query "email_queue?gmail_message_id=eq.${msg_id}&select=id&limit=1" "GET" \
    | jq -r '.[0].id // empty' 2>/dev/null)

send_telegram_draft_notification \
    "email" \
    "$sender_name" \
    "$subject" \
    "$email_summary" \
    "$draft_text" \
    "${queue_row_id:-}" \
    "${gmail_link:-}"
```

Keep the existing batch summary at the end for stats, but the per-email notification is the primary one.

### Step 3: Search Rube for Gmail send capability

Before implementation, run:
```
RUBE_SEARCH_TOOLS: queries=[{"use_case": "send Gmail draft"}, {"use_case": "send email Gmail"}]
```

Expected: `GMAIL_SEND_DRAFT` or `GMAIL_SEND_EMAIL` tool slug.

If found: document in TOOLS.md and use in the approval flow.
If not found: Use `GMAIL_CREATE_EMAIL_DRAFT` to update the draft, then tell Ashley "Draft updated, tap send in Gmail." (Fallback -- still better than current flow.)

### Step 4: Update AGENTS.md with approval command handling

Add a new section to `workspace/AGENTS.md`:

```markdown
## Draft Approval Commands (Telegram)

When Ashley replies to a draft notification:

### "send" or "approve"
1. Look up the most recent pending draft in email_queue/dm_queue
2. For email: Send the draft via GMAIL_SEND_DRAFT (or GMAIL_SEND_EMAIL)
3. For IG DM: Send via INSTAGRAM_SEND_TEXT_MESSAGE
4. For SMS: Forward to Twilio send endpoint
5. Update queue status to "sent"
6. Confirm: "Sent to [recipient]"

### "change [feedback]" or "change: [feedback]"
1. Look up the most recent pending draft
2. Store correction immediately:
   - Call store_correction() equivalent via Supabase INSERT
   - Channel: email/instagram_dm/sms, Action: "edit"
3. Re-draft with the feedback applied (use the same Claude prompt but add the feedback as a correction)
4. Delete old Gmail draft, create new one
5. Send new draft notification to Telegram
6. Confirm: "Redrafted. Here's the updated version."

### "skip" or "ignore"
1. Look up the most recent pending draft
2. Store correction (action: "reject") via Supabase INSERT
3. Delete the Gmail draft
4. Update queue status to "rejected"
5. Confirm: "Skipped. Won't reply to [sender]."

### Multiple pending drafts
If Ashley says "send" and there are multiple pending drafts:
1. List them: "I have 3 pending drafts: 1) [sender/subject] 2) [sender/subject] 3) [sender/subject]"
2. Ask: "Which one? (number, 'all', or 'newest')"

### Lookup query
```sql
SELECT id, to_address, subject, body, gmail_draft_id, thread_id
FROM email_queue
WHERE status IN ('pending', 'drafted')
ORDER BY created_at DESC
LIMIT 5
```
```

### Step 5: Update TOOLS.md with send tool documentation

Add to the Communication Tools section:

```markdown
### Draft Approval (Telegram-based)

When Ashley approves a draft via Telegram:

**Send an email draft:**
```
GMAIL_SEND_DRAFT: {draft_id: "<draft_id>"}
```
(Or if not available: GMAIL_SEND_EMAIL with recipient, subject, body, thread_id)

**Send an IG DM:**
```
INSTAGRAM_SEND_TEXT_MESSAGE: {recipient_id: "<id>", message: "<draft_text>"}
```

**Store immediate correction (on "change"):**
```sql
INSERT INTO draft_corrections (user_id, channel, action, incoming_context, incoming_from, original_draft, corrected_text, source_record_id, source_table)
VALUES ('3ed111ff-...', 'email', 'edit', '<context>', '<from>', '<original>', '<new_draft>', '<queue_id>', 'email_queue')
```
```

### Step 6: Update HEARTBEAT.md for DM notifications

Change the IG DM notification format to include draft text and approval instructions (same pattern as email).

### Step 7: Update SKILL.md safety rule

Change `skills/email-master/email-master/SKILL.md` line 146:
```
- **Never auto-send** -- all drafts require Ashley's review in Gmail
```
To:
```
- **Never auto-send** -- all drafts require Ashley's approval (via Telegram reply or Gmail review)
```

## What This Does NOT Change

- The 8am correction cron (`check-corrections.sh`) still runs as a safety net for drafts approved/edited in Gmail directly
- The batch summary at the end of process-emails.sh still sends (useful for stats)
- The existing Gmail-based workflow still works if Ashley prefers to review there
- SMS approval continues through its existing Twilio web UI (Telegram approval is additive)

## Verification

1. Run `bash -n` on all modified scripts (syntax check)
2. Manually test: Run `process-emails.sh` with `DRY_RUN=true` to verify notification format
3. Check Telegram notification renders correctly (HTML formatting, pre block for draft)
4. Verify identity file symlinks are still valid: `ls -la ~/.openclaw/identity/`
5. Send a test email, verify per-email notification appears in Telegram
6. Reply "send" in Telegram, verify Max handles it correctly
7. Reply "change: shorter" in Telegram, verify Max re-drafts and stores correction
8. Reply "skip" in Telegram, verify Max marks as rejected

## Risks

- **Telegram message length limit**: 4096 chars. Long drafts will need truncation with "... (full draft in Gmail)" link
- **Gmail send tool**: If Rube doesn't have GMAIL_SEND_DRAFT, we fall back to draft-in-Gmail + "tap send" instruction
- **Multiple drafts**: If several emails come in at once, Ashley needs to specify which one. The numbered list approach handles this.
- **HTML escaping**: Draft text in `<pre>` tags needs `<` and `>` escaped to avoid breaking Telegram HTML parsing
