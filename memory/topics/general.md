# General Learnings

## Notes

### 2026-02-06 - Agent teams enabled
[decision] Enabled CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS in settings.json. tmux auto-launches via .zshrc for split-pane mode. Teammates are ephemeral -- they don't persist between sessions. All memory must go through files.

### 2026-02-06 - Webflow lead capture (TODO)
[decision] Ashley wants to replace Dubsado (current CRM) with a Webflow-native lead capture form on the main website. Flow: Webflow form submission -> email webhook -> auto-creates Google Calendar event -> auto-logs as new event tile in MTL app. Webflow integration via Composio or Rube MCP. This is a future task after Track A production readiness is done.

### 2026-02-06 - Vitest CalendarWidget test failures
[gotcha] CalendarWidget tests have pre-existing failures related to time format display (expects "2:00 PM" but component shows "2:00 p.m." with lowercase). These are NOT related to Phase 1 changes. 3/1441 tests fail. 17/114 test files fail (mostly CalendarWidget formatting issues).

### 2026-02-06 - Module-level GoogleGenAI instantiation breaks tests
[gotcha] `proposalService.ts` and `memoryIngestion.ts` both create `GoogleGenAI` at module top-level, which throws "API key must be set" during test import. Any test file whose import chain reaches these modules needs to mock them. Key chains: `salesAgent -> proposalService -> GoogleGenAI`, `quoteService -> leadNurturingService -> draftService -> memoryIngestion -> GoogleGenAI`, `claudeVoicePipeline -> behaviorInjectionService -> supabaseClient`. Always mock the nearest module in the chain to break the dependency.

### 2026-02-06 - WorkflowCoordinator async methods
[gotcha] `listActiveWorkflows()` and `getPendingApprovals()` on WorkflowCoordinator are async (return Promise). Tests must use `await`. Easy to miss because the methods look like simple array filters but they call `ensureInitialized()` internally.

### 2026-02-07 - Sidebar was non-functional dead weight
[decision] Removed Sidebar.tsx entirely in Phase 6. All 7 sidebar links (Dashboard, Events, Emails, Inventory, Recipes, Staff, Settings) only set local `activeLink` state that connected to nothing. No routing, no view switching. The bento grid IS the app. PremiumLayout now renders CRMBentoGrid directly.

### 2026-02-07 - Email lead_stage defaults cause false URGENT tags
[gotcha] All inbound emails in Supabase default to `lead_stage='new_inquiry'` and `status='new'`. The old tagging logic checked these fields directly, causing every email (including bank notifications, receipts) to show "NEW LEAD" + "URGENT". Fix: created `emailTagUtils.ts` that runs `classifyEmail()` from emailAutonomyService on each email, plus checks sender patterns (noreply@, notifications@) to detect system notifications. Tags are now workflow-based, not field-based.

### 2026-02-07 - Floating button overlap with sidebar
[gotcha] The floating settings button at `fixed bottom-20 left-4` overlapped the sidebar's user avatar. After sidebar removal, repositioned to `fixed bottom-6 left-4`. Watch for z-index conflicts between fixed-position floating buttons.

### 2026-02-08 - Business context audit: 10 bugs + 94 placeholders fixed
[decision] Full audit of business context across 5 data stores (workspace files, Mem0, Supabase, hardcoded defaults, moltbot.json). Fixed 10 bugs: tasks schema (status enum, missing columns), Mem0 user_id mismatch, stale DB references, memory-sync overwrite, seed data, scheduled_jobs gap. Replaced all 94 [ASK ASHLEY] placeholders with confirmed data from interview. Key business facts: 4 service tiers (Tailored $15-25/pp, Ultimate $30-60/pp, Mocktail $25/pp, Consumption $12.50/drink), 25% deposit, 1 bartender per 40 guests, $500K 2026 target. Files changed: 13.

### 2026-02-08 - Loaded business context into live Mem0 + Supabase
[decision] After fixing files on disk, loaded confirmed business context into live data stores. Supabase memory table: 20 records (importance 7-10) covering pricing, policies, operations, vendors, goals, contacts. Mem0 (user_id=ashley): added 13 new memories with 4 service tiers, deposit policy, staffing ratios, suppliers, revenue target, lead questions. Deleted 5 stale/wrong memories ($45 open bar, quote-based duplicates, hourly rate reference). Restored $40/hr mixologist rate (it IS correct). Total Mem0 count: 115 (was 99). Local Rube MCP token was expired; used cloud Rube for Supabase and local mem0.sh CLI for Mem0.

### 2026-02-08 - Live testing feedback: payment, quoting rules, draft behavior
[gotcha] Payment is credit card via payment link ONLY. Not e-transfer, not PayPal. $40/hr per mixologist IS correct (includes setup/teardown). Corporate events: always quote WITH alcohol (Ultimate tier), never suggest Tailored. Private events: ask about both options. Lead handling: proactively draft reply to Gmail drafts (not workspace files), show details in one message, don't ask "Want me to draft?". Response style: no filler ("Great question!"), confirm what's known, only ask what's missing. Turnkey service includes: fresh juice, fresh syrups, signature menu of 4 + classics, printed menu, mixers, sparkling water, water station.

### 2026-02-08 - ROOT CAUSE: SMS/email prompts were generic, workspace files never read at runtime
[gotcha] The SMS service (skills/twilio-sms/) runs on Railway as a standalone Express app. It has ZERO access to workspace/*.md files. The LLM prompt was built in `claude.js:buildSystemPrompt()` -- a generic 15-line prompt that said "keep under 160 chars" with no qualifying questions, no business rules, no tone guidance. Similarly, email-drafter.sh had a generic prompt. Updating MEMORY.md/IDENTITY.md had zero effect on Max's responses because those files are never read by the deployed service. Fix: rewrote both prompts with the full qualifying questions template, first-message vs follow-up detection, corporate/private rules, tone rules, contact capture, and an example response template directly embedded in the prompt. Also increased max_tokens from 300->600 for longer qualifying responses.

### 2026-02-08 - Railway deploy: twilio-sms is standalone, NOT OpenClaw gateway
[gotcha] The Railway project "open-claw" has TWO services: "OpenClaw" (gateway wrapper, root Dockerfile, port 8080, with volume at /data) and "twilio-sms" (standalone Express SMS app, skills/twilio-sms/Dockerfile, port 5000). They are SEPARATE. The twilio-sms service uses the simple node:20-slim Dockerfile (5 steps), NOT the root Dockerfile (11 steps with openclaw/mcporter). Deploying the root Dockerfile to twilio-sms will break it ("configured: false" because no OpenClaw config).

### 2026-02-08 - Railway deploy: `railway up` picks up wrong Dockerfile from project root
[gotcha] `railway up` from project root finds the ROOT Dockerfile, ignoring `RAILWAY_ROOT_DIRECTORY` and `railway.json` in subdirectories. Must use `railway up --path-as-root /path/to/skills/twilio-sms` to deploy the standalone SMS app with its own Dockerfile. The `railway.json` must use `"dockerfilePath": "Dockerfile"` (relative to root dir), NOT `"skills/twilio-sms/Dockerfile"` (relative to repo root). Also `watchPatterns` must be `["**"]` not `["skills/twilio-sms/**"]` because paths are relative to RAILWAY_ROOT_DIRECTORY.

### 2026-02-08 - Railway deploy: GitHub auto-deploy was disconnected on Feb 7
[gotcha] Original deploys came from separate repo `ashleytower/twilio-sms-webhook`. On Feb 7, switched to CLI deploys (`railway up`). Pushes to `ashleytower/max-ai-employee` main do NOT trigger Railway rebuilds. Must manually deploy via `cd skills/twilio-sms && railway up --path-as-root .` or reconnect GitHub integration to the monorepo with `RAILWAY_ROOT_DIRECTORY=skills/twilio-sms`.

### 2026-02-11 - NEVER recommend architecture changes without checking Hard Dependencies
[gotcha] Recommended separate macOS user for Max without checking that nightly builder needs Ashley's Claude Max plan OAuth (lives in user profile) and fb-group-monitor needs Ashley's Chrome sessions. Both break under a different user. CLAUDE.md now has a "Hard Dependencies" table. ALWAYS check it before proposing infra/security/deployment changes. The rule: verify every dependency still works before recommending. If unsure, say "this might conflict with X" instead of presenting it as clean.

### 2026-02-11 - OpenClaw sandbox config exists but was never enabled
[config] OpenClaw v2026.2.9 supports tool-level sandboxing via agents.defaults.sandbox in openclaw.json. Ashley's install has no sandbox block. This is the #1 security gap. Jan 2026: 21,639 exposed OpenClaw instances found (CVE-2026-25253). Add sandbox config, tighten exec-approvals, keep same user account.

### 2026-02-12 - RUBE_TOKEN must be ak_ format, NOT JWT
[gotcha] Rube dashboard has TWO auth methods: "Get API Key" (gives `ak_` prefix token) and "Auth Headers" (gives JWT). The `ak_` format gives direct access to all 500+ tools (GMAIL_FETCH_EMAILS, SUPABASE_BETA_RUN_SQL_QUERY, etc.). The JWT from Auth Headers only exposes RUBE_SEARCH_TOOLS as a meta-tool -- all bash scripts calling tools by name break. Always use "Get API Key" for RUBE_TOKEN.

### 2026-02-12 - railway run runs LOCALLY, not on Railway container
[gotcha] `railway run openclaw config set channels.telegram.botToken` modified the LOCAL Mac ~/.openclaw/openclaw.json, NOT the Railway /data volume. This injected a `channels.telegram` block into the Mac node's config (which is a node host, not a gateway). The extra config confused the node. Fix: use `railway ssh -- openclaw config set` to run commands on the actual container. Always `railway ssh` for remote config changes, never `railway run`.

### 2026-02-12 - Secret rotation: where each key lives
[gotcha] Railway env vars alone are NOT enough for key rotation. Keys live in MULTIPLE places:
- ANTHROPIC_API_KEY: Railway env vars + Mac launchd plist
- TELEGRAM_BOT_TOKEN: Railway env vars + Mac launchd plist + OpenClaw config on /data volume (channels.telegram.botToken via `railway ssh`)
- RUBE_TOKEN: Railway env vars (RUBE_TOKEN + RUBE_API_KEY) + Mac launchd plist
- Gateway restarts needed: `railway redeploy -y` for Railway, `launchctl kickstart -k gui/$(id -u)/ai.openclaw.node` for Mac

### 2026-02-08 - Railway deploy: SUPABASE_SERVICE_KEY env var missing
[gotcha] The twilio-sms code uses `process.env.SUPABASE_SERVICE_KEY` but Railway had the env var as `SUPABASE_SERVICE_ROLE_KEY`. Added `SUPABASE_SERVICE_KEY` as a separate var with the same value. Without this, the app crashes on startup with "supabaseKey is required."

### 2026-02-13 - Remotion bundle cannot use node:fs
[gotcha] Remotion bundles with Webpack, which cannot handle `node:` URI imports (node:fs, node:path, etc.). Any code imported from Root.tsx → registry → loader that uses filesystem APIs will crash the build. Solution: use static JSON imports (`import config from './config/file.json'`) for anything loaded at bundle time. Keep the node:fs loader for CLI scripts only.

### 2026-02-13 - Zod 3.22.3 discriminatedUnion + intersection fragility
[gotcha] z.intersection() + z.discriminatedUnion() works in Zod 3.22.3 but is fragile. Adding .refine() to the intersection may break. Tested and passing but document the constraint. Consider flat union variants if Zod is upgraded.

### 2026-02-14 - Telegram Draft Approval Flow
[pattern] Added `send_telegram_draft_notification()` to common.sh for rich per-email/DM/SMS notifications in Telegram. Format: channel label + sender + subject + summary + draft in `<pre>` block + "send / change / skip" instructions. HTML-escaped, truncated at 2500 chars for Telegram 4096 limit.
[pattern] Rube Gmail tools confirmed: `GMAIL_SEND_DRAFT` (draft_id), `GMAIL_SEND_EMAIL` (recipient_email, subject, body), `GMAIL_DELETE_DRAFT` (draft_id). Gmail connection is active for info@mtlcraftcocktails.com.
[decision] Draft approval happens via natural Telegram messages (no inline buttons needed). Max LLM on gateway receives Ashley's replies and handles send/change/skip commands. Instructions in AGENTS.md + TOOLS.md.
[gotcha] `send_telegram_message()` uses jq `-Rs` for escaping. The new notification function must HTML-escape `<`, `>`, `&` in user content before passing to it, or Telegram HTML parse mode breaks on email content containing angle brackets.

### 2026-02-21 - Mac deployment learnings (Phase B-D cutover)
[gotcha] `sudo -u max` does NOT change HOME on macOS. All `sudo -u max git config --global` commands write to the calling user's .gitconfig. Always use `sudo -u max HOME=/Users/max <command>`.
[gotcha] `cp -a` of large .git directories can hang under sudo due to macOS TCC (Transparency, Consent, and Control). Use `rsync -a --info=progress2` as alternative to see progress.
[gotcha] Git 2.45+ on macOS changed `git config` subcommand syntax. `git config --global --add` now shows usage help. Use `git config set --global` for newer versions, or both work if you just push through.
[gotcha] OpenClaw `openclaw onboard --auth-choice openai-codex` OAuth token expires fast. Complete browser sign-in within 30 seconds or get 401 "token_expired". Second attempt worked.
[gotcha] OpenClaw `openclaw gateway install` fails under `sudo -u max -i` with "Domain does not support specified action" because it tries LaunchAgent (user-level). Harmless -- we use LaunchDaemon (system-level) plists at /Library/LaunchDaemons/ai.max.*.plist.
[pattern] Cloudflare Worker deploy via `npx wrangler deploy` from config/ dir with minimal wrangler.toml. No global install needed. Worker URL: max-sms-fallback.ash-cocktails.workers.dev.
[config] Max AI Employee model switched from anthropic/claude-haiku-4-5 to openai-codex/gpt-5.3-codex on 2026-02-21. Uses Ashley's ChatGPT Plus ($20/mo). Rollback: `openclaw models set anthropic/claude-haiku-4-5` + restart gateway.

### 2026-02-17 - exec-approvals.json main agent empty allowlist
[gotcha] The `main` agent in `~/.openclaw/exec-approvals.json` had `"allowlist": []` which overrode the `*` wildcard allowlist. This caused ALL cron jobs using agent `main` (email-check-business, email-check-9am, email-check-evening) to exec-deny on approval timeout. Email processing was down for ~1 week (Feb 9-17) before discovery. Fix: removed the empty allowlist so `main` inherits from `*`. The `cron` agent has its own allowlist with `ask: "never"` and works fine. Email cron jobs use agent `main`, while heartbeat/others use `default`.

### 2026-02-25 - Gemini to Claude Migration
[decision] Migrated 7 services from @google/genai to callClaudeProxy. All use ANTHROPIC_MODEL_HAIKU from modelRouter.ts (claude-haiku-4-5-20251001). Embeddings moved to OpenAI text-embedding-3-small via /api/embeddings.js proxy. @google/genai kept ONLY for Gemini Live API voice (geminiService.ts, skills/types.ts, skills/toolRegistry.ts, api/voice/session-token.js). The api/utils/omiClassifier.js uses @anthropic-ai/sdk directly (server-side).
