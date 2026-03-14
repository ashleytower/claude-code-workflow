# Plan: Split email-master into hybrid bash/agent architecture

## Context

`process-emails.sh` (1389 lines) does everything monolithically: fetch, classify, draft, post. The draft happens via `call_claude_cli` on line 858 with a stripped-down ~200-line bash prompt. But when a cron job fires, the OpenClaw gateway creates an agent turn where the agent already has IDENTITY.md, MEMORY.md, SOUL.md, USER.md loaded. The bash script's LLM call duplicates the agent's work with LESS context -- no access to the 662 lines of reference files (business-context.md, sales-playbook.md, persuasion-framework.md) that the agent can read natively.

**Fix:** Split bash into classify-only + post-draft helpers. Let the agent draft replies itself using its full loaded context.

## Files

| Action | File | Purpose |
|--------|------|---------|
| CREATE | `skills/email-master/email-master/scripts/classify-inbox.sh` | Deterministic: fetch, classify, gather context, output JSON |
| CREATE | `skills/email-master/email-master/scripts/post-draft.sh` | Post-draft: Gmail draft, email_queue, label, Telegram notify |
| MODIFY | `skills/email-master/email-master/SKILL.md` | Rewrite cron workflow to 5-step agent-orchestrated pipeline |
| KEEP | `skills/email-master/email-master/scripts/process-emails.sh` | Untouched, manual/emergency fallback |

No cron job changes needed -- existing cron fires agent turns that read SKILL.md.

## Step 1: Create `classify-inbox.sh`

Extract all deterministic functions from `process-emails.sh`. All logs to stderr, only JSON to stdout.

**Functions to copy from process-emails.sh:**
- Classification patterns (lines 47-91)
- `is_lead_form()`, `extract_lead_email()`, `extract_lead_name()`, `extract_lead_fields()` (96-249)
- `ollama_prefilter()` (255-289)
- `categorize_email()` (406-518)
- `already_processed()` (523-533)
- `fetch_unread_emails()`, `fetch_email_details()`, `fetch_thread()` (357-399)
- `build_thread_context()` (619-653)
- `get_sender_context()` (601-614)
- `resolve_label_ids()`, `label_and_mark_read()` (312-352, 918-937)

**NOT copied (agent handles these):**
- `generate_draft()` -- agent drafts natively
- `get_business_context()` -- agent reads reference files directly
- `create_gmail_draft()`, `store_in_email_queue()`, `resolve_email_contact()` -- moved to post-draft.sh

**Output JSON schema:**
```json
{
  "emails": [{
    "msg_id": "...", "from": "...", "reply_to": "...", "reply_to_name": "...",
    "subject": "...", "body": "...(truncated to 4000 chars)...",
    "thread_id": "...", "category": "conversation|lead_form|action_required",
    "is_first_message": true, "thread_context": "...(truncated to 3000 chars)...",
    "sender_context": "...", "correction_rules": "...", "lead_fields": "..."
  }],
  "stats": { "scanned": N, "conversations": N, "transactional_skipped": N, ... },
  "action_items": ["sender: subject", ...],
  "labels": { "drafted_id": "Label_X", "skipped_id": "Label_Y" }
}
```

Uses same `cron_lock "process-emails"` to prevent concurrent runs with legacy script. Truncates `body` to 4000 chars and `thread_context` to 3000 chars to keep JSON manageable.

## Step 2: Create `post-draft.sh`

Small helper that takes draft text via stdin + metadata via args, then:
1. Creates Gmail draft via `rube_execute("GMAIL_CREATE_EMAIL_DRAFT")`
2. Stores in `email_queue` (Supabase)
3. Labels email (Max/Drafted) + marks read
4. Resolves contact (fire-and-forget)
5. Sends Telegram notification with draft preview

**Interface:**
```bash
cat /tmp/draft.txt | ./post-draft.sh \
  --msg-id MSG_ID \
  --recipient EMAIL \
  --recipient-name NAME \
  --subject SUBJECT \
  --thread-id THREAD_ID \
  --category CATEGORY \
  --label-drafted-id LABEL_ID \
  [--is-lead-form]
```

**Output:** `{"success": true, "draft_id": "...", "gmail_link": "..."}`

Functions extracted from process-emails.sh: `create_gmail_draft()` (871-916), `store_in_email_queue()` (942-974), `label_and_mark_read()` (918-937), `resolve_email_contact()` (976-1000).

## Step 3: Update SKILL.md

Rewrite the cron workflow section. Keep all existing sections (interactive commands, classification reference, response rules, business context pointers, learning system, safety).

**New cron workflow (replaces "Quick Start"):**

1. **Read reference files** -- business-context.md, sales-playbook.md, persuasion-framework.md
2. **Exec classify-inbox.sh** -- parse JSON output
3. **For each email:** Draft the reply yourself using full context (IDENTITY + MEMORY + SOUL + reference files + thread_context + correction_rules from JSON)
4. **For each draft:** Write to temp file, pipe to post-draft.sh
5. **Send summary** to Telegram with stats + draft list

Key changes:
- Remove `ANTHROPIC_API_KEY` from required env vars (agent uses its own model, bash scripts don't call LLM)
- Document the JSON schema inline
- Instruct agent to write drafts to temp files to avoid shell escaping issues
- Keep all existing Response Rules / Classification / Interactive sections as agent reference

## Step 4: Test

1. Run `classify-inbox.sh` manually, verify valid JSON output
2. Pipe test draft to `post-draft.sh`, verify Gmail draft + email_queue + Telegram notification
3. Trigger cron manually ("Run email-master"), verify full pipeline
4. Run `check-corrections.sh` against new drafts -- verify correction learning still works
5. Test edge cases: 0 unread emails, all transactional, lead form emails

## Step 5: Investigate rate limit spam

Max is sending repeated "API rate limit reached" messages. Likely cause: inbox-watcher (every 3 min) or overlapping email cron jobs hitting Rube MCP limits. Check gateway logs, identify the offending cron job, and add backoff/rate limiting.

## What Improves

- **Draft quality**: Agent has 662 lines of business refs + IDENTITY/MEMORY/SOUL vs 200-line bash prompt
- **Cost**: No extra LLM call -- agent was already running for the cron turn (gpt-5.3-codex, free)
- **Maintainability**: Drafting rules in SKILL.md markdown, not embedded in bash strings
- **Correction rules**: Injected alongside full business knowledge instead of crammed bash prompt
- **Classification stays fast**: Rule-based bash + free Ollama prefilter, no change
