# Rube MCP (Composio)

### 2026-02-07 - Rube has NO REST API, only MCP
[gotcha] The URLs `api.rube.sh` and `api.rubeapp.com` do NOT EXIST. They were hallucinated. The only endpoint is `https://rube.app/mcp` which speaks MCP JSON-RPC over HTTP/SSE. All tool calls must go through `RUBE_MULTI_EXECUTE_TOOL` via the MCP protocol.

### 2026-02-07 - Token management
[pattern] Token is a JWT stored in `RUBE_TOKEN` env var and in `~/.mcporter/mcporter.json`. The mcporter.json token goes stale — always sync from env var. Token has `iat` claim but no explicit `exp` — Rube rotates server-side.

### 2026-02-07 - MCP call pattern (bash)
[pattern] Built `rube_execute()` in `skills/shared/lib/common.sh`. Flow:
1. Build JSON-RPC payload wrapping tool_slug + arguments in RUBE_MULTI_EXECUTE_TOOL
2. POST to `https://rube.app/mcp` with Bearer token
3. Response is SSE: `event: message\ndata: {jsonrpc response}`
4. Inner text is double-JSON: outer MCP content[0].text contains stringified JSON with `.data.data.results[0].response`
5. Python3 parsing required — Reddit content has unescaped control chars that break jq

### 2026-02-07 - Reddit search via Rube
[pattern] Tool slug: `REDDIT_SEARCH_ACROSS_SUBREDDITS`. Key param is `search_query` (NOT `query`). Response shape: `{posts: [{author, title, selftext, subreddit, permalink, score, num_comments, id, ...}]}`. Permalink may or may not have `https://www.reddit.com` prefix — always check.

### 2026-02-07 - RUBE_SEARCH_TOOLS requires `queries` array
[gotcha] Not a simple string query. Requires: `{"queries": [{"use_case": "description"}], "session": {"generate_id": true}}`. Returns session_id to reuse. But session_id is optional for MULTI_EXECUTE_TOOL.

### 2026-02-07 - Code review: rube_execute bugs
[gotcha] `2>&1` on python3 call merges stderr into stdout, corrupting JSON output. Fix: use `2>/dev/null` or capture stderr separately. Also: curl `--max-time 60` is too short for Apify actors (need 120-180s). Changed to 300s.

### 2026-02-07 - Apify tool slugs UNVERIFIED
[gotcha] Tool slugs `APIFY_RUN_ACTOR_SYNC_GET_DATASET_ITEMS` and `GOOGLESHEETS_BATCH_UPDATE` were guessed during migration, never tested. Parameter schema (`actor_id`, `run_input`, `timeout_secs`) may be wrong — Composio typically uses camelCase (`actorId`, `input`, `timeout`). MUST run `RUBE_SEARCH_TOOLS` with query "apify" to verify before first real run.

### 2026-02-07 - SSE parsing only reads first data line
[gotcha] Python parser in rube_execute breaks on first `data:` line. If Rube sends heartbeat/keepalive before real payload, wrong data is parsed. Also no try/except on KeyError for JSON-RPC error responses (`.error` instead of `.result`).

### 2026-02-07 - Available meta tools
[pattern] `RUBE_FIND_RECIPE`, `RUBE_MANAGE_RECIPE_SCHEDULE`, `RUBE_MANAGE_CONNECTIONS`, `RUBE_MULTI_EXECUTE_TOOL`, `RUBE_REMOTE_BASH_TOOL`, `RUBE_REMOTE_WORKBENCH`, `RUBE_SEARCH_TOOLS`, `RUBE_GET_TOOL_SCHEMAS`, `RUBE_CREATE_UPDATE_RECIPE`, `RUBE_EXECUTE_RECIPE`, `RUBE_GET_RECIPE_DETAILS`. App tools (REDDIT_*, APIFY_*, GOOGLESHEETS_*) are called through MULTI_EXECUTE_TOOL.

### 2026-02-09 - Gmail tool slugs (VERIFIED)
[gotcha] Gmail tool slugs via Rube/Composio are NOT what you'd guess:
- `GMAIL_FETCH_EMAILS` - Search/list emails. Supports `query`, `max_results`, `ids_only` params.
- `GMAIL_FETCH_MESSAGE_BY_MESSAGE_ID` - Get single email by ID. NOT `GMAIL_GET_MESSAGE`.
- `GMAIL_FETCH_MESSAGE_BY_THREAD_ID` - Get all messages in a thread. NOT `GMAIL_FETCH_EMAILS` with `thread:` query.
- `GMAIL_CREATE_EMAIL_DRAFT` - Create draft. NOT `GMAIL_CREATE_DRAFT`. Params: `recipient_email` (NOT `to`), `body`, `subject` (omit for thread replies to stay in-thread), `thread_id`, `is_html`. Returns `data.id` as draft_id.
- `GMAIL_ADD_LABEL_TO_EMAIL` - Add/remove labels. NOT `GMAIL_ADD_LABELS_TO_EMAIL` (plural). Params: `message_id`, `add_label_ids`, `remove_label_ids`. REQUIRES label IDs (e.g., `Label_3`), NOT label names.
- `GMAIL_BATCH_MODIFY_MESSAGES` - Bulk label changes (up to 1000 messages). Params: `messageIds`, `addLabelIds`, `removeLabelIds`.
- `GMAIL_LIST_LABELS` - List all labels with IDs. Custom labels have format `Label_<number>`. System labels use name as ID (INBOX, UNREAD, etc.).
- `GMAIL_CREATE_LABEL` - Create a label. Returns `{id, name, ...}`. Cache the `id` for use with label tools.
- Mark as read: Use `GMAIL_ADD_LABEL_TO_EMAIL` with `remove_label_ids: ['UNREAD']`. No dedicated GMAIL_MARK_EMAIL_AS_READ tool verified.
Always use `RUBE_SEARCH_TOOLS` to verify slugs before coding.

### 2026-02-09 - Gmail data_preview vs full payload format
[gotcha] `GMAIL_FETCH_MESSAGE_BY_MESSAGE_ID` returns `data_preview` (not `data`) for most messages. `data_preview` has flat fields: `messageText`, `messageId`, `threadId`, `labelIds`, `sender`, `recipient`, `subject`, `snippet`, `internalDate`. It does NOT have `payload.headers` or `payload.parts`. Code must handle both: check `data.payload` first (full format), fall back to direct `data.messageText`/`data.sender`/etc.

### 2026-02-09 - Rube MCP data_preview vs data
[gotcha] Large Rube MCP responses use `data_preview` instead of `data` in the response path `inner.data.data.results[0].response`. `data_preview` contains truncated results. Always check both: `resp?.data || resp?.data_preview`. For Gmail search, use `ids_only: true` to get compact ID stubs that won't be truncated.

### 2026-02-09 - Rube MCP messageId field names
[gotcha] Rube/Composio returns Gmail message IDs as `messageId` (camelCase), not `id`. Thread IDs are `threadId`. Always check all variants: `msg.id || msg.messageId || msg.message_id`.

### 2026-02-09 - Railway monorepo subdirectory deploys
[gotcha] `railway up <path>` from a monorepo root picks up the ROOT Dockerfile, not the subdirectory's. Must use `railway up <path> --path-as-root` to use the subdirectory's Dockerfile. Also use `--ci` for non-interactive deploys.

### 2026-02-08 - Token expiry research (CRITICAL)
[research] The `@jlowin/rube-mcp` npm package is GONE (404 on npm). Must migrate to `@composio/rube-mcp` or use HTTP transport to `https://rube.app/mcp`. Three layers of auth to understand:
1. **Rube JWT token** (RUBE_TOKEN): Your identity token for the Rube MCP endpoint. JWT has `iat` but NO `exp` claim. However, Rube rotates/invalidates server-side. Current token issued 2026-02-01. No public docs on how long it stays valid.
2. **Composio API key** (COMPOSIO_API_KEY): Long-lived API key from `platform.composio.dev/settings`. Does NOT expire like OAuth tokens. Use this as a more stable alternative.
3. **Individual app OAuth tokens**: Per-app tokens (Google, Slack, GitHub, etc.) managed by Composio. These expire per OAuth spec (typically 1hr) but Composio auto-refreshes them using refresh tokens. Only marked EXPIRED after multiple refresh failures.

[gotcha] The "token expired" you see between sessions is likely one of:
- The Rube JWT being rotated server-side (no client notification)
- Individual app OAuth tokens expiring while Composio refresh failed
- The npm package `@jlowin/rube-mcp` being removed, causing 404 errors that look like auth failures

[decision] Fix options ranked:
1. **Best**: Switch to HTTP transport with COMPOSIO_API_KEY header instead of npx stdio: `claude mcp add --transport http rube -s user "https://rube.app/mcp" --header "X-API-Key:YOUR_COMPOSIO_API_KEY"`
2. **Good**: Update Claude Desktop config to use `@composio/mcp@latest` with setup command: `{"command":"npx","args":["@composio/mcp@latest","setup","https://rube.app/mcp","rube","--client","claude"]}`
3. **Fallback**: Generate a new token from rube.app dashboard, update RUBE_TOKEN in .zshenv, and use `@composio/rube-mcp` instead of `@jlowin/rube-mcp`

### 2026-02-14 - mcporter config priority and RUBE_TOKEN mismatch
[gotcha] mcporter reads Rube config from the PROJECT-LEVEL `config/mcporter.json` (in max-ai-employee repo), NOT from `~/.mcporter/mcporter.json`. The project config uses `"Authorization": "Bearer ${RUBE_TOKEN}"` env var substitution. BUT the RUBE_TOKEN in the openclaw-node launchd plist is an `ak_` API key (23 chars), NOT a JWT. The Rube MCP SSE endpoint at `rube.app/mcp` requires a JWT. Fix: set RUBE_TOKEN to the JWT when running process-emails.sh manually. The JWT has no expiry (`iat` only, no `exp`). Check with `mcporter config get rube` to see which config file is being used.

### 2026-02-14 - rube_execute() rewritten to mcporter CLI
[pattern] `rube_execute()` in common.sh now calls mcporter CLI instead of direct curl. This fixes OAuth refresh permanently. The tool param name changed from `params` to `arguments` in RUBE_MULTI_EXECUTE_TOOL. Old: `{tool_slug, params}`. New: `{tool_slug, arguments}`.

### 2026-02-14 - Gmail mark as unread
[pattern] Use `GMAIL_ADD_LABEL_TO_EMAIL` with `add_label_ids: ["UNREAD"]`. There is no dedicated GMAIL_MARK_AS_UNREAD tool. Similarly, mark as read = `remove_label_ids: ["UNREAD"]`.
