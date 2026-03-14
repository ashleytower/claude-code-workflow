# Plan: Fix Max -- Broken DMs, Infrastructure, Then Enhancements

## Context

Max is broken in critical ways. Client inquiries are going unanswered for 9-13+ hours. The IG DM approval handler was never implemented -- drafts get created and sent to Telegram for approval, but when Ashley taps "send", nothing happens. Check-corrections is failing on the Mac node. Heartbeat doesn't flag overdue inquiries. These must be fixed before any enhancements.

## Ashley's Issues (Feb 17, 2026)

1. **2 client inquiries overdue** -- Kristen Huber (13+ hrs), Gila Vanounou (9+ hrs) -- no response sent
2. **8 approval drafts from Feb 12** aging 4+ days
3. **check-corrections failing** -- Mac node script can't reach Rube MCP
4. **Max doesn't send IG DMs** -- approval handler never implemented
5. **No proactive Instagram engagement** -- only reactive DM response exists
6. **Elestio credits critical** -- 24 hours to suspension
7. **Jessica Boisvert event** 10 days away, needs supplies/bartender coordination

## Investigation Findings

### Finding 1: IG DM Send Handler MISSING (root cause of overdue inquiries)

`INSTAGRAM_SEND_TEXT_MESSAGE` appears in docs/design only. Zero instances in actual code.

**The chain:**
- Heartbeat detects DM -> `draft-dm-replies.sh` drafts reply -> stored in `dm_queue` (status=pending) -> Telegram notification sent -> **Ashley approves -> NOTHING HAPPENS** -> draft stays pending forever

**Where it should be:** `skills/twilio-sms/src/routes/approval.js` has `sendApprovedSms()` for SMS but NO equivalent for Instagram DMs. The `dm_queue` table has no approval route.

### Finding 2: Heartbeat Doesn't Check Overdue Age

`workspace/HEARTBEAT.md` says: "Any inquiry older than 4 hours = alert Ashley immediately"

But `heartbeat-check.sh` only checks for NEW messages in the last 30 minutes. It never queries `dm_queue` for stale pending items.

### Finding 3: check-corrections Depends on Rube MCP via mcporter

`check-corrections.sh` calls `rube_execute()` for `GMAIL_FETCH_EMAILS` and `GMAIL_FETCH_MESSAGE_BY_MESSAGE_ID`. This requires mcporter to bridge to Rube MCP. Mac node WebSocket connection is unstable (1006 errors in `node.err.log`).

### Finding 4: No Proactive Instagram Engagement Code

Only reactive DM response exists. FB group monitor and Reddit engage have the comment-draft-approve pattern. Instagram post engagement would follow the same pattern but doesn't exist yet.

---

## Phase 1: Fix IG DM Sending (CRITICAL -- clients waiting)

**Goal:** When Ashley approves an IG DM draft, actually send it via Instagram.

**File: `skills/twilio-sms/src/routes/approval.js`**

Add an IG DM approval handler alongside the existing SMS handler:

| Change | Details |
|--------|---------|
| Add `sendApprovedInstagramDM()` function | Fetch draft from `dm_queue` by ID, call Rube MCP `INSTAGRAM_SEND_TEXT_MESSAGE` with `{recipient_id, message}`, update `dm_queue` status to 'sent' |
| Wire into approval route | When approval comes in for a `dm_queue` record, route to IG handler instead of SMS handler |
| Store correction on edit | If Ashley edited before sending, store in `draft_corrections` (channel='instagram_dm') |
| Telegram confirmation | Update Telegram message: "Sent to @username" or "Failed: error" |

**How Rube is called from Node.js:** Check how the existing SMS/voice routes call external APIs. The twilio-sms service runs on Railway -- it may use a different pattern than bash's `rube_execute()`. Need to check if there's a Node.js Rube/mcporter client or if it calls the Rube REST API directly.

**Existing reference files:**
- `skills/twilio-sms/src/routes/approval.js` -- existing SMS approval handler
- `skills/twilio-sms/src/services/` -- check for existing Rube/Instagram service
- `skills/twilio-sms/src/routes/messages.js` -- may have draft retrieval patterns
- `workspace/TOOLS.md` -- documents `INSTAGRAM_SEND_TEXT_MESSAGE` tool slug

**Verification:**
1. Create test draft in `dm_queue` with known `sender_id` and `draft_text`
2. Trigger approval flow
3. Confirm DM actually arrives on Instagram
4. Confirm `dm_queue` status updated to 'sent'
5. Confirm Telegram shows "Sent to @username"

## Phase 2: Fix Heartbeat Overdue Detection

**Goal:** Alert Ashley when DM inquiries or email drafts sit unresponded >4 hours.

**File: `skills/heartbeat/scripts/heartbeat-check.sh`**

| Change | Details |
|--------|---------|
| Add overdue DM check | Query `dm_queue?status=eq.pending&created_at=lt.<4h_ago>` -- if count > 0, send urgent Telegram alert with sender usernames and age |
| Add overdue email check | Query `email_queue?status=eq.pending&created_at=lt.<4h_ago>` -- same pattern |
| Format alert | "OVERDUE: 2 IG DMs pending >4h: @kristen_h (13h), @gila_v (9h)" |

**Verification:**
1. Manually insert a `dm_queue` record with `created_at` 5 hours ago
2. Run `heartbeat-check.sh`
3. Confirm Telegram alert fires with correct age calculation

## Phase 3: Fix check-corrections (Mac Node Stability)

**Goal:** Make correction extraction work reliably despite Mac node instability.

**Investigation needed first:** Read the actual error logs to understand if the issue is:
- mcporter not installed/not in PATH
- Rube token expired
- WebSocket disconnection during execution
- Gateway not forwarding tool calls properly

**File: `skills/email-master/email-master/scripts/check-corrections.sh`**

| Change | Details |
|--------|---------|
| Add error handling around `rube_execute()` calls | If mcporter fails, log the error and skip that correction (don't crash the whole script) |
| Add retry logic | If Rube call fails, retry once after 5s delay |
| Add connectivity check at script start | `mcporter call rube.RUBE_MANAGE_CONNECTIONS` -- if it fails, log "Rube MCP unavailable, skipping corrections check" and exit gracefully |

**Verification:**
1. Run `check-corrections.sh` manually
2. Confirm it processes recent email drafts
3. Confirm it detects edits and extracts correction rules
4. Confirm it doesn't crash when mcporter is unavailable

## Phase 4: Proactive Instagram Engagement

**Goal:** Max proactively comments on relevant Instagram posts to build visibility and pull in leads.

**Pattern:** Follow `skills/fb-group-monitor/` and `skills/reddit-engage/` exactly.

**Strategy decisions from Ashley's conversation with Max:**
- **Targets:** Wedding planners, event organizers, Montreal venues, engaged couples
- **Hashtags:** #MTLweddings #MontrealEvents #bartender + Montreal location tags
- **Approval:** Draft comments in batches for daily Telegram approval
- **Tone:** Needs confirmation (professional/casual/funny)
- **Volume:** Needs confirmation (suggest 5-10 per day)
- **Account:** @mtl_craftcocktails

**New files:**

| File | Purpose |
|------|---------|
| `skills/ig-engage/SKILL.md` | Skill definition |
| `skills/ig-engage/scripts/ig-engage.sh` | Main script (~300 lines) |
| `skills/ig-engage/data/` | State files (seen posts, etc.) |

**Script flow (mirrors reddit-engage.sh):**
1. Search target hashtags/accounts via Rube Instagram tools (check available slugs first)
2. Score posts for buyer intent using Ollama (free)
3. Draft helpful, non-promotional comments using Haiku (or CLIProxyAPI if Phase 5 done)
4. Send batch to Telegram for approval
5. On approval: post comment via claude-in-chrome browser automation (Instagram API may not support commenting)
6. Log to `audit_log` table

**Check first:** Run `RUBE_SEARCH_TOOLS` with "instagram" to see if post searching/commenting tools exist. If not, this phase uses claude-in-chrome browser automation only.

**Cron:** 12pm daily (after FB 10am and Reddit 11am).

**Verification:**
1. Run `ig-engage.sh` manually
2. Confirm it finds relevant posts
3. Confirm draft comments appear in Telegram
4. Confirm approval -> comment posted (or browser automation initiated)

## Phase 5: CLIProxyAPI (free LLM calls)

**Goal:** Insert CLIProxyAPI into the LLM cascade so paid Haiku calls route through Max subscription.

**Setup (one-time, manual):**
```bash
brew install cliproxyapi
cliproxyapi --claude-login
```

**File: `skills/shared/lib/common.sh`**

| Change | Details |
|--------|---------|
| Add `CLIPROXY_URL` env var | Default: `http://localhost:8317` |
| Add `ensure_cliproxy_checked()` | Same pattern as `ensure_ollama_checked()`. Probe `/v1/models` with 2s timeout |
| Add `call_cliproxy()` | OpenAI-compatible POST to `${CLIPROXY_URL}/v1/chat/completions`. Parse `choices[0].message.content`. Falls back to `call_claude_api()` |
| Modify `call_ollama()` fallback | Change `call_claude_api` -> `call_cliproxy` (which itself falls back to `call_claude_api`) |

**New cascade:** Ollama -> CLIProxyAPI -> Anthropic API

**Verification:**
1. `curl -s http://localhost:8317/v1/models` returns model list
2. Stop Ollama, run `call_ollama "test" "Say hello"` -- routes through CLIProxyAPI
3. Stop both, confirm fallback to Anthropic API

## Phase 6: Notion Mission Control via Rube MCP

**Goal:** Convert broken direct Notion API calls to working Rube MCP. Wire brain-dump to sync.

**New file: `skills/shared/lib/notion.sh`** (~60 lines, Rube MCP wrappers)

**Files to modify:**
- `scripts/sync-notion-tasks.sh` -- replace curl with Rube calls
- `scripts/verify-notion.sh` -- replace curl with Rube calls
- `skills/nightly-builder/scripts/nightly-builder.sh:49-149` -- replace Notion functions
- `skills/morning-brief/scripts/morning-brief.sh:164-227` -- replace Notion todo section
- `skills/brain-dump/scripts/brain-dump.sh` -- add Notion sync after task insert

**First:** Run `mcporter call rube.RUBE_SEARCH_TOOLS query="notion" limit=20` to confirm exact tool slugs.

## Phase 7: Daily Digest (9pm ET)

**Goal:** Nightly Telegram summary of what Max did. Zero LLM cost.

**New files:**
- `skills/daily-digest/SKILL.md`
- `skills/daily-digest/scripts/daily-digest.sh` (~200 lines)

**Sections:** Emails, Tasks, Goals, Corrections, Leads, Tonight's Queue, Needs Attention

**Cron:** `openclaw cron add --name "daily-digest" --cron "0 21 * * *" --tz "America/New_York"`

## Agent Team

| Agent | Phases | Priority |
|-------|--------|----------|
| Backend 1 | Phase 1 (IG DM sending) + Phase 2 (heartbeat overdue) | CRITICAL -- do first |
| Backend 2 | Phase 3 (check-corrections) + Phase 4 (IG engagement) | HIGH |
| Backend 3 | Phase 5 (CLIProxyAPI) + Phase 6 (Notion) + Phase 7 (Digest) | MEDIUM |
| Code Reviewer | All phases | After each phase |

Phases 1-2 are urgent. Everything else follows.

## CLAUDE.md Updates (after all phases)

- Add IG DM approval flow to Data Flows section
- Add heartbeat overdue detection to heartbeat description
- Add ig-engage to skill inventory and cron schedule
- Add CLIProxyAPI to cost tiers
- Add daily-digest to cron schedule
- Document Notion via Rube MCP
- Update cron count
