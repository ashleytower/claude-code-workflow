# Plan: Inbox Watcher (Real-Time Alerts)

## Context
Ashley wants near-instant Telegram alerts when a new client email or Instagram DM arrives, instead of waiting for the 15-min/30-min processing cycles. SMS is already real-time via Twilio webhook. The watcher must be zero-LLM-cost -- pure API checks + pattern matching.

## What It Does
- Runs every 3 minutes via OpenClaw cron
- Checks Gmail for new unread client emails (filters out transactional/newsletters using existing rule-based patterns)
- Checks Instagram for new DMs (timestamp-based, last 5 min window)
- Sends Telegram alert with sender + subject/preview
- Tracks already-alerted IDs in a local state file to avoid duplicate alerts
- Does NOT draft replies -- that stays on the existing schedule

## Files to Create

### 1. `skills/inbox-watcher/SKILL.md`
Minimal frontmatter for OpenClaw skill registration.

### 2. `skills/inbox-watcher/scripts/inbox-watcher.sh`
Single script, ~150 lines. Structure:

```
source shared/lib/common.sh
cron_lock "inbox-watcher"

STATE_FILE="${SKILL_DIR}/data/seen-ids.txt"

# --- Gmail ---
Fetch unread IDs (GMAIL_FETCH_EMAILS, ids_only, max 10)
For each ID not in STATE_FILE:
  Fetch details (GMAIL_FETCH_MESSAGE_BY_MESSAGE_ID)
  Extract from, subject via extract_field() pattern (Python, from process-emails.sh)
  Categorize using TRANSACTIONAL_PATTERNS + SERVICE_DOMAINS + NEWSLETTER_INDICATORS
  If "conversation" or "action_required":
    Send Telegram: "New email from <sender>: <subject>"
    Append ID to STATE_FILE

# --- Instagram ---
Fetch conversations (INSTAGRAM_LIST_ALL_CONVERSATIONS)
Parse with Python: find messages newer than 5 min
For each new message where sender not in STATE_FILE (keyed by conv_id+msg_timestamp):
  Send Telegram: "New IG DM from @<username>: <preview>"
  Append key to STATE_FILE

# --- Cleanup ---
Prune STATE_FILE entries older than 24h (keep file from growing)
```

### Key Design Decisions

1. **State file over Supabase** -- A local flat file (`seen-ids.txt`) is faster and avoids a network round-trip every 3 minutes. One ID per line. Pruned daily.

2. **Reuse email classification patterns** -- Copy the `TRANSACTIONAL_PATTERNS`, `SERVICE_DOMAINS`, `NEWSLETTER_INDICATORS`, and `TRANSACTIONAL_SUBJECTS` arrays from `process-emails.sh`. Same categorize logic, just inline (don't source process-emails.sh since it has side effects).

3. **Reuse extract_field() Python** -- Same Python snippet from process-emails.sh for parsing Gmail API response formats.

4. **5-min window for IG** -- Check messages created in last 5 minutes (slightly wider than the 3-min cron interval to avoid gaps).

5. **No symlink needed** -- This runs via `openclaw cron add` pointing to the script path. Symlink to `~/.openclaw/skills/` is optional (Max doesn't need to invoke this conversationally).

## Files to Modify

### 3. `CLAUDE.md`
- Add inbox-watcher to Skill Inventory
- Add cron entry to Cron Schedule table
- Update Data Flows section with alert flow

## Cron Registration
```bash
openclaw cron add --name inbox-watcher \
  --schedule "*/3 8-23 * * *" \
  --timezone "America/New_York" \
  --command "bash /Users/ashleytower/Documents/GitHub/max-ai-employee/skills/inbox-watcher/scripts/inbox-watcher.sh"
```
Only during active hours (8am-11pm) -- no 3am alerts.

## Dependencies (already available)
- `rube_execute()` from `skills/shared/lib/common.sh`
- `send_telegram_message()` from `skills/shared/lib/common.sh`
- `cron_lock()` from `skills/shared/lib/common.sh`
- `RUBE_TOKEN`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` env vars (already set for other cron jobs)

## Verification
1. Run script manually with `DRY_RUN=false` and verify Telegram alert arrives
2. Run again immediately -- should NOT re-alert (dedup via state file)
3. Send a test email to Ashley's inbox, wait 3 min, confirm alert
4. Check state file has the message ID recorded
5. Verify cron is registered: `openclaw cron list | grep inbox-watcher`
