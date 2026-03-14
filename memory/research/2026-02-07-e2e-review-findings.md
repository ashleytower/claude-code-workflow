# E2E Review Findings - feat/reddit-engage Branch

**Date:** 2026-02-07
**Reviewers:** 5 parallel agents (reddit-tester, facebook-tester, google-tester, shared-lib-reviewer, code-reviewer)
**Branch:** feat/reddit-engage (commits 5298d27, d205664)

## Systemic Issues (affect all pipelines)

1. **`set -e` kills error recovery** -- every `|| true` guard, fail-open check, and fallback parser is dead code. Fix: remove `set -e`, keep explicit error handling.
2. **Telegram Markdown escaping** -- user content with `_*[]` breaks message delivery. Fix: remove parse_mode, send plain text.
3. **rube_execute() stderr corruption** -- `2>&1` merges python warnings into JSON. Fix: `2>/dev/null`.
4. **execute_browser_comments marks all as posted** -- no per-comment success tracking. Documented limitation.
5. **Telegram offset=0 consumes cross-skill messages** -- fix: poll with offset=-1 first.

## Reddit Pipeline

- Dry-run still calls Claude API and Telegram getUpdates
- `limit` sent as string not number (--arg vs --argjson)
- No cross-run daily comment cap
- Keywords in config are comma-separated strings instead of JSON arrays

## Facebook Pipeline

- Google Sheets write promised in docs but never implemented
- Keyword intent overwrite (warm->medium) due to loop not breaking
- Empty post_url fingerprint causes all URL-less posts to dedup to same hash
- Universal patterns with literal "..." never match real posts
- `--phase engage` documented but not implemented
- CAPTCHA detection file never created by any code
- Comment limit bumped 5->20 risks spam detection (reverted to 8)

## Lead Pipeline (MOST CRITICAL)

- Apify tool slugs + parameter schemas UNVERIFIED (migrated but never tested)
- curl 60s timeout kills Apify calls that need 120-180s
- Word-splitting breaks every multi-word Google Maps search query
- `--refresh-venues` flag is a complete no-op
- `--campaign all` hardcodes list instead of reading config
- `warm` count always 0 in summary (field missing from result JSON)
- Dry-run still writes to Supabase (bypasses supabase_query)
- Stdout pollution from curl in subshell corrupts result JSON

## Shared Library (common.sh)

- No python3 availability check before rube_execute
- No JSON-RPC error handling (checks .result but not .error)
- call_claude_api 30s timeout may be too short for long prompts
- No rate limit (429) handling for Anthropic API
- check_env_vars default list missing TELEGRAM_CHAT_ID
- generate_fingerprint MD5 output format varies by platform (handled with fallbacks)
- Hardcoded model `claude-3-5-haiku-20251022` will break on deprecation

## Fixes Applied By Code Simplifier + Final Reviewer

All 12 fixes applied and verified (11 PASS, 1 CONCERN fixed post-review):
1. Removed `set -e` from 3 orchestrators (kept -uo pipefail)
2. rube_execute() stderr: `2>&1` -> `2>/dev/null`
3. Telegram: removed parse_mode Markdown, plain text only
4. execute_browser_comments: documented "marks all as posted" limitation
5. FB comment limit: 20->8/day, delay 90->120s
6. Telegram offset: poll from latest update_id+1 (not 0)
7. Word-splitting: `for in` -> `while IFS= read -r`
8. curl timeout: 60s -> 300s for Apify actors
9. Reddit limit: --arg -> --argjson (string -> number)
10. FB fingerprint: composite key when post_url empty
11. Dry-run: added guard before raw Supabase curl
12. Keywords: removed "..." from universal patterns
