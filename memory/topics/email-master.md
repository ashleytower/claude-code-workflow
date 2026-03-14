# Email Master

### 2026-02-10 - Thread context truncation caused bad drafts
[gotcha] `build_thread_context()` in process-emails.sh was truncating each thread message to 500 chars. This caused Claude to miss critical context (e.g., client declining). Fixed to 2000 chars. Also bumped max output tokens from 1024 to 2048 -- the 1024 limit left almost no room for reasoning after the system prompt consumed ~800 tokens.

### 2026-02-10 - Added thread comprehension step to drafting prompt
[pattern] The drafting prompt had no comprehension step. Claude would jump straight to classification and response. Added a mandatory THREAD COMPREHENSION section with explicit decline signal detection (budget constraints, buying own supplies, "on va passer", etc.). This goes BEFORE the classification step.

### 2026-02-10 - Rube MCP appends RETURNING * to INSERT queries
[gotcha] When using SUPABASE_BETA_RUN_SQL_QUERY via Rube MCP, do NOT include `RETURNING` in your INSERT statement. Rube automatically appends `RETURNING *`, so including your own causes a syntax error (`RETURNING id RETURNING *`). Just end the INSERT with a semicolon.

### 2026-02-10 - draft_corrections table has NOT NULL constraint on original_draft
[gotcha] The `draft_corrections` table requires `original_draft` to be non-null. When inserting correction rules manually (not from an actual draft), provide a placeholder string describing the scenario.

### 2026-02-27 - Email-master hybrid architecture split
[pattern] Split process-emails.sh (1389 lines) into hybrid bash/agent architecture:
- classify-inbox.sh: deterministic fetch, classify, gather context -> JSON to stdout
- post-draft.sh: takes draft via stdin + metadata args -> Gmail draft + email_queue + label + Telegram
- Agent drafts replies using its full loaded context (IDENTITY + MEMORY + SOUL + 662 lines of reference files)
- process-emails.sh kept as manual/emergency fallback
- Same cron_lock "process-emails" prevents concurrent runs between new and legacy scripts
- ANTHROPIC_API_KEY no longer required (agent uses its own model, bash scripts don't call LLM for drafting)
- Bug fix: removed dead code in extract_lead_fields() that referenced undefined `patterns` variable

### 2026-02-27 - Rate limit spam root cause
[debug] Max sending repeated "API rate limit reached" Telegram messages. Root cause: OpenAI Codex (ChatGPT subscription) rate limit, NOT Gmail API. Every cron job fires an LLM call through the gateway. inbox-watcher (every 15 min) and heartbeat-check (every 60 min) are the main offenders (19 of 21 cron-attributed errors). Fix options: (1) increase intervals, (2) move inbox-watcher/heartbeat to standalone launchd jobs (they don't need LLM), (3) add circuit breaker in gateway cron runner. Also found: stale /root/ path in LLM system prompt causing skill read failures, Telegram polling 409 conflicts, BOT_COMMANDS_TOO_MUCH errors.
