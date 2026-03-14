# Plan: Auto-Draft Emails in Inbox Watcher

## Context

Ashley wants Max to proactively draft email replies when new client emails arrive, not wait to be asked. Currently inbox-watcher sends Telegram alerts (summary only), and email drafting is on-demand via Telegram. The goal: one Telegram message with email summary + draft reply + approve/edit/skip, automatically.

## Approach: Extend inbox-watcher with Ollama drafting

Modify `inbox-watcher.sh` to also draft replies for client emails using `call_ollama()` (free, local) and pipe through existing `post-draft.sh`. No new files needed. No gateway agent turns consumed.

### Why this approach
- **Zero cost**: Ollama local = free. No agent turns consumed.
- **Reuses existing code**: `post-draft.sh` already creates Gmail draft + Telegram notification with summary + draft + send/change/skip
- **No new services/crons**: inbox-watcher already runs every 5min via launchd
- **Keeps it simple**: One script does detect + draft + notify

### What changes

#### 1. Modify `skills/inbox-watcher/scripts/inbox-watcher.sh`

When a client email is detected (line ~147, `category == "client"`):

**Before:** Send alert-only Telegram message
**After:**
1. Fetch thread context via `GMAIL_FETCH_MESSAGE_BY_THREAD_ID` (if thread_id exists)
2. Fetch correction rules via `get_correction_rules()` from `corrections.sh`
3. Build drafting prompt with business context (embedded in prompt, not reading files)
4. Call `call_ollama()` to draft a reply (~2048 tokens)
5. If Ollama returns a good draft (non-empty, not error), pipe it to `post-draft.sh`
6. `post-draft.sh` handles: Gmail draft creation, email_queue storage, labeling, contact resolution, Telegram notification (summary + draft + send/change/skip)
7. If drafting fails, fall back to alert-only (current behavior)

**New function `draft_and_notify()` in inbox-watcher.sh:**
```bash
draft_and_notify() {
    local msg_id="$1" from_addr="$2" subject="$3" snippet="$4" thread_id="$5" preview="$6"

    # Fetch thread context
    local thread_context=""
    if [[ -n "$thread_id" ]]; then
        thread_context=$(rube_execute "GMAIL_FETCH_MESSAGE_BY_THREAD_ID" "{\"thread_id\":\"$thread_id\"}" "Fetch thread" 2>/dev/null) || true
        thread_context=$(echo "$thread_context" | python3 -c "..." 2>/dev/null) # extract text, truncate to 3000 chars
    fi

    # Get correction rules
    local rules=""
    if [[ "$CORRECTIONS_AVAILABLE" == "true" ]]; then
        rules=$(get_correction_rules "$from_addr" "$subject" 2>/dev/null) || true
    fi

    # Extract reply-to email
    local email_only="$from_addr"
    [[ "$from_addr" =~ \<([^>]+)\> ]] && email_only="${BASH_REMATCH[1]}"

    # Build prompt + draft via Ollama
    local system_prompt="You are Max, assistant to Ashley Tower at MTL Craft Cocktails (mobile bartending, Montreal). [embedded business context: pricing, tone, bilingual rules]. Draft a reply. If no reply needed, output exactly NO_REPLY_NEEDED."
    local user_prompt="From: $from_addr\nSubject: $subject\nBody: $snippet\nThread: $thread_context\nCorrection rules: $rules"

    local draft
    draft=$(call_ollama "$system_prompt" "$user_prompt" 2048) || {
        # Fallback to alert-only
        send_telegram_message "$alert_msg"
        return
    }

    # Skip if no reply needed
    if [[ "$draft" == *"NO_REPLY_NEEDED"* ]]; then
        log "No reply needed for $msg_id"
        # Still send a summary-only alert
        send_telegram_message "$alert_msg (No reply needed)"
        return
    fi

    # Pipe draft to post-draft.sh
    echo "$draft" | post-draft.sh --msg-id "$msg_id" --recipient "$email_only" --recipient-name "$sender_name" --subject "$subject" --thread-id "$thread_id" --category "conversation" --label-drafted-id "$LABEL_DRAFTED_ID" --body-summary "$preview"
}
```

**Key detail:** The `post-draft.sh` notification already produces the exact Telegram format Ashley wants:
```
EMAIL from Sender Name
Subject line

Preview of original email...

DRAFT REPLY:
[draft text in pre block]

Reply: send | change [feedback] | skip
View in Gmail
```

#### 2. Source corrections.sh in inbox-watcher

Add at top of inbox-watcher.sh (after sourcing common.sh):
```bash
CORRECTIONS_AVAILABLE=false
if [[ -f "$SHARED_LIB/corrections.sh" ]]; then
    source "$SHARED_LIB/corrections.sh"
    CORRECTIONS_AVAILABLE=true
fi
```

#### 3. Add label resolution to inbox-watcher

Reuse the `resolve_label_ids()` pattern from classify-inbox.sh to get `LABEL_DRAFTED_ID` at startup. Or pass empty string and let post-draft.sh skip labeling.

Simpler: resolve once at startup, cache in a variable.

#### 4. Business context in prompt

Embed a condensed version of the business context directly in the system prompt (pricing tiers, services, tone rules). This avoids file reads from inbox-watcher. ~500 chars of core context is sufficient for Ollama drafting quality.

Load from `workspace/MEMORY.md` key facts: services (mobile bartending, workshops), pricing range ($350-$2500+), bilingual EN/FR, Montreal area. The system prompt template lives in the script itself.

#### 5. NO_REPLY_NEEDED handling

When Ollama determines no reply is needed (confirmations, FYI emails, auto-responses), inbox-watcher sends a summary-only alert (current behavior) without drafting.

### Files to modify

| File | Change |
|------|--------|
| `skills/inbox-watcher/scripts/inbox-watcher.sh` | Add `draft_and_notify()`, source corrections.sh, add label resolution, modify `check_gmail()` to call draft flow for client emails |
| `skills/inbox-watcher/SKILL.md` | Update description to reflect auto-drafting |

### Files reused (no changes)

| File | What we use |
|------|-------------|
| `skills/email-master/email-master/scripts/post-draft.sh` | Gmail draft creation + Telegram notification |
| `skills/shared/lib/common.sh` | `call_ollama()`, `send_telegram_message()`, `rube_execute()`, `escape_html_telegram()` |
| `skills/shared/lib/corrections.sh` | `get_correction_rules()` |
| `skills/shared/lib/email-patterns.sh` | `categorize_email_simple()`, `extract_field()` |

### What stays the same

- inbox-watcher launchd plist (no env var changes needed - common.sh auto-loads from `~/.openclaw/.env`)
- Instagram DM alerts (unchanged - still alert-only, no drafting)
- email-master skill (unchanged - still available for on-demand use via Telegram)
- Approval flow (unchanged - send/change/skip handled by gateway agent reading SKILL.md)
- Correction learning (unchanged - check-corrections 8am cron)
- 5-minute run interval (unchanged)

### Edge cases

1. **Ollama not running**: `call_ollama()` falls back to `call_claude_cli()` then `call_claude_api()`. All handled.
2. **Draft too long**: `send_telegram_draft_notification()` already truncates at 2500 chars.
3. **No thread context**: Draft without it (first message in thread).
4. **post-draft.sh fails**: Log error, fall back to alert-only.
5. **Rate limiting on Rube MCP**: Already handled by inbox-watcher's 1-second throttle between emails.
6. **Multiple client emails in one run**: Process each sequentially. Max 10 emails per run (existing limit).
7. **Duplicate drafts**: inbox-watcher's seen-ids.txt prevents re-processing. email_queue dedup by gmail_message_id.

### Verification

1. Run `inbox-watcher.sh` manually with a test unread email in Gmail
2. Verify Telegram message shows: summary + draft + send/change/skip
3. Verify Gmail draft was created in the correct thread
4. Verify email_queue row in Supabase with status=pending
5. Reply "send" on Telegram → verify Max sends it
6. Reply "change: make it shorter" → verify Max re-drafts
7. Reply "skip" → verify draft marked rejected
8. Send a transactional email → verify NO draft is created (alert-only or silent)
9. Check Ollama handles drafting (no Anthropic API calls for normal flow)
