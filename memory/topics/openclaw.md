# OpenClaw

### 2026-02-08 - Critical Config Gotchas
[gotcha] moltbot.json scheduling section is a DESIGN DOC ONLY. OpenClaw does NOT read it. Jobs must be registered via `openclaw cron add`. If a job isn't in `openclaw cron list`, it has never run.

[gotcha] Skills must be symlinked to `~/.openclaw/skills/` to be discoverable. The `openclaw-watcher` syncs from main branch only. Skills on feature branches need manual symlinks.

[gotcha] Kimi K2.5 tool-use is broken on non-TUI clients (GitHub #9413, v2026.2.3+). Tool events not delivered via Telegram gateway. Stick with Claude Sonnet 4.5 for now.

[gotcha] Cron agent has separate allowlist in `exec-approvals.json`. If a skill needs `gh`, `git`, `node`, or `python3`, those must be explicitly added to the cron agent's allowlist (not just the `*` agent).

[pattern] Cron job pattern: `openclaw cron add --name X --cron "expr" --tz "America/New_York" --session isolated --message "natural language instruction" --thinking medium --timeout-seconds N`

[config] Key files: `~/.openclaw/openclaw.json` (model, gateway, heartbeat), `~/.openclaw/exec-approvals.json` (command allowlist), `~/.openclaw/node.json` (node config)

### 2026-02-08 - Schedule Reference
All 13 cron jobs registered:
- morning-brief: 8:30am ET daily
- email-check-9am: 9am ET daily
- email-check-business: every 15min 9-5 ET
- email-drafter: 10am ET daily
- fb-group-monitor: 10am ET daily
- reddit-engage: 11am ET daily
- afternoon-report: 2pm ET Mondays
- email-check-evening: 6pm/8pm/10pm ET daily
- nightly-builder: 11pm ET daily
- lead-pipeline-bars: 3am ET Mon/Thu
- lead-pipeline-crm: 3am ET Tue/Fri
- lead-pipeline-events: 3am ET Wed/Sat
- venue-discovery-refresh: 4am ET 1st of month

### 2026-02-09 - Skill Building Learnings (email-master)
[pattern] Skill packaging: `python3 ~/.claude/plugins/marketplaces/anthropic-agent-skills/skills/skill-creator/scripts/package_skill.py <skill-dir>`. Requires `pip3 install pyyaml`.

[pattern] Skill progressive disclosure: SKILL.md body <500 lines, reference files loaded on-demand, scripts executed without loading into context. `{baseDir}` placeholder resolves to skill's absolute directory.

[gotcha] GMAIL_FETCH_EMAILS does NOT support `thread_id` as a parameter. To search within a thread, embed it in the query string: `"in:sent thread:$thread_id"`.

[gotcha] Claude's NO_REPLY_NEEDED output may include trailing whitespace/newlines. Always trim with `xargs` before exact string comparison.

[gotcha] Checking draft existence by listing all drafts with `max_results: 50` will miss drafts when >50 exist. Better: fetch the specific draft by message ID and check for DRAFT label.

[pattern] Skill frontmatter description is the ONLY trigger mechanism. Must be comprehensive with explicit "Use when:" scenarios. Body is only loaded after triggering.

### 2026-02-09 - ig-responder Build Learnings
[gotcha] draft_corrections schema: columns are `incoming_context`, `incoming_from`, `original_draft`, `corrected_text`, `correction_rule`, `promoted_to_mem0`, `source_record_id`, `source_table`. Builder agents generated wrong column names (correction_text, promoted, category) -- always verify against the migration file.

[pattern] Cross-channel correction rules: query ALL channels from draft_corrections (not just the current channel). A correction learned from email applies to IG DMs too.

[pattern] Instagram Rube MCP tool slugs: `INSTAGRAM_LIST_ALL_CONVERSATIONS`, `INSTAGRAM_LIST_ALL_MESSAGES`, `INSTAGRAM_SEND_TEXT_MESSAGE`. Requires `recipient_id` from message `from.id` field.

[pattern] Node.js Railway service pattern for polling: Express server + setInterval polling loop. Health check at /health. Telegram webhook for approval callbacks. Matches twilio-sms architecture.

[decision] ig-responder was scrapped -- heartbeat system already handles IG DMs at zero additional cost. Added "ASK BEFORE BUILDING" rule to CLAUDE.md.

### 2026-02-10 - Schedule Update
[config] check-corrections cron added: 8am daily ET. All email cron jobs updated to reference email-master skill explicitly. gmail-responder Railway deployment removed (code preserved). 14 cron jobs total now.

### 2026-02-10 - Ashley Brain Dump (Sales Knowledge)
[pattern] Contact capture: ALWAYS get both phone AND email. DM/text leads need email for the proposal portal. Email leads need phone.

[pattern] Price objection #1: "If we pay the bartender hourly, what's the per-person for?" Answer: it's like a caterer. Per-person covers everything (juice, syrups, menu, glassware, setup, teardown), not just labor. Don't over-explain.

[pattern] Competition: They compare us to "just a bartender" (hourly, speed rail, basic drinks, no equipment). We're turnkey craft cocktails. Paint the picture, don't trash the competition.

[pattern] The cocktail bar effect: Beer/wine crowds default to wine. But a cocktail bar = kid in a candy store. Even "I don't drink cocktails" people do when they see a real craft bar. This is the differentiator.

[pattern] Tastings: Free for weddings. At Loft Beauty. Mention casually in back-and-forth, not as a hard pitch.

[pattern] Email length: No hard word limit. Match complexity of the question. Corrections loop will refine over time.

[decision] Future task: study best funnels and landing pages for MTL Craft Cocktails. Task added to Supabase (cbaeaf94) as research type, assigned_to_max.

### 2026-02-10 - LLM Cost Optimization Research
[research] Claude Sonnet 4.5 ($3/$15 per M tokens) is current default. Cheapest viable alternatives with good tool calling: GPT-4.1 nano ($0.10/$0.40), Gemini 2.5 Flash Lite ($0.10/$0.40), GPT-4o-mini ($0.15/$0.60), GPT-4.1 mini ($0.40/$1.60), Claude Haiku 4.5 ($1.00/$5.00).

[gotcha] DeepSeek V3 tool calling is unreliable -- tool_choice:auto silently fails, model loops on repeated calls. Avoid for unattended automation.

[gotcha] Gemini 2.5 Flash tool calling degrades in long conversations -- stops calling tools and outputs markdown code instead. Fine for single-turn, risky for multi-step pipelines.

[research] Kimi K2.5 ($0.60/$2.50, auto-caching $0.15) handles 200-300 sequential tool calls without drift. Already configured in openclaw.json as alias "kimi". However, OpenClaw note from 2026-02-08 says tool-use is broken on non-TUI clients (GitHub #9413).

[decision] Safest cost reduction: switch OpenClaw default from Sonnet 4.5 to Haiku 4.5 for routine operations (~70% savings, zero code changes, same Anthropic API). Keep Sonnet for drafting/coding.

[research] Anthropic Batch API is 50% cheaper than standard API and explicitly designed for scheduled/automated workloads like Max's cron jobs.

### 2026-02-10 - Claude Code Max Plan vs API for Max
[research] Claude Code Max plan ($100-200/mo) gives 140-480 hrs/week of Sonnet. Usage shared across Claude web + Claude Code. Anthropic ToS prohibits automated/non-human access on consumer subscriptions EXCEPT via API key or official Claude Code client.

[gotcha] Anthropic cracked down Jan 2026 on third-party harnesses (OpenCode etc.) spoofing Claude Code headers. Official Claude Code CLI (`claude -p`) itself is allowed -- their docs show it with cron jobs. BUT running 24/7 automated agents on Max subscription is exactly what triggered the crackdown (some users consumed tens of thousands $/mo).

[decision] Safe hybrid approach: nightly-builder can use claude -p under Max subscription (limited hours, official CLI, scheduled). OpenClaw Gateway daytime operations (email every 15min, heartbeat every 30min) must stay on API key -- high-frequency automated loop pattern is what Anthropic flagged.

[gotcha] If ANTHROPIC_API_KEY env var is set, Claude Code uses API billing instead of subscription. Must be unset for Max subscription usage. Be careful with env inheritance in cron/launchd.

### 2026-02-10 - OpenClaw Model Switching (Hard-Won Knowledge)
[gotcha] THREE separate places store model config, and NONE of them are the Railway env vars: (1) `~/.openclaw/openclaw.json` on Mac (agents.defaults.model.primary), (2) Gateway session default at `/data/.openclaw/agents/main/sessions/sessions.json` on Railway container, (3) Per-session model override via Telegram. Priority: per-session > gateway session default > openclaw.json.

[gotcha] Railway env vars (AGENT_MODEL, ANTHROPIC_MODEL, CLAWDBOT_MODEL, OPENCLAW_MODEL) are NOT read by the gateway for model selection. Changing them does nothing. Redeploying does not change the model -- /data volume persists across deploys.

[gotcha] `railway run` executes commands LOCALLY with Railway env vars injected, NOT on the remote container. Cannot use it to modify gateway state.

[pattern] PERMANENT model change: Set `OPENCLAW_DEFAULT_MODEL` Railway env var (e.g. `anthropic/claude-haiku-4-5`). server.js `ensureDefaultModel()` runs `openclaw models set` CLI before gateway starts. Direct sessions.json patching alone does NOT work -- must use CLI. Commit f5d083e.

[pattern] Per-session model change: tell Max "switch to haiku" (or sonnet/opus) on Telegram. Uses aliases from openclaw.json models section. Does NOT persist across new sessions.

[pattern] Check gateway model: `openclaw gateway call status --json` → `sessions.defaults.model` shows the persistent default. Individual sessions show their own model in the `recent` array.

[gotcha] "New session" / "/new" in Telegram creates a fresh context but INHERITS the gateway's session default model. Does not pick up openclaw.json changes.

### 2026-02-10 - System Audit Findings
[gotcha] HEARTBEAT.md at ~/.openclaw/identity/ was an ACTUAL FILE (not symlink), outdated. Missing correction capture rules, clickable Gmail/IG links, wrong Mem0 user_id. Fixed: replaced with symlink to workspace/HEARTBEAT.md. Always verify identity files are symlinks with `ls -la ~/.openclaw/identity/`.

[gotcha] Direct patching of sessions.json `defaults.model` does NOT change the gateway's reported model. Must use `openclaw models set` CLI command. The `ensureDefaultModel()` function in server.js now does this correctly (commit f5d083e).

[pattern] `openclaw models set` is the correct CLI command to change the gateway default model. Used by setup wizard and now by ensureDefaultModel() on startup.

### 2026-02-08 - Security Alert
[gotcha] railway-vars-backup.json was committed then removed. ALL production secrets remain in git history (commit 79116e7). Need: rotate all keys, purge git history with `git filter-repo` or BFG.

### 2026-02-10 - Firecrawl + Research Tool Decision
[config] Firecrawl now available in Rube MCP. Ashley added it. Can be used for deep page scraping via rube_execute().

[decision] Research tool stack for Max: Claude's built-in web search + Firecrawl via Rube is sufficient. No need for Tavily or Perplexity API. Claude Code agents already have web search, and Firecrawl gives deep page scraping when needed. Brave API key exists in Railway (`BSA3ms7L7aj0aV6PONXCF5_4JHBZktD`) but unused -- could be wired later if needed.

[config] Lead pipeline env vars added to Mac node launchd plist (`~/Library/LaunchAgents/ai.openclaw.node.plist`): SUPABASE_URL, SUPABASE_SERVICE_KEY, ANTHROPIC_API_KEY, TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID. These are required by lead-pipeline, reddit-engage, and fb-group-monitor bash scripts which run via openclaw cron.

### 2026-02-15 - Identity symlinks pointed to wrong repo
[gotcha] ~/.openclaw/identity/ symlinks were pointing to ~/max-ai-employee/ (an OLD copy of the repo) instead of ~/Documents/GitHub/max-ai-employee/ (the active development repo). Only HEARTBEAT.md had been fixed previously. All 6 other symlinks (AGENTS.md, IDENTITY.md, MEMORY.md, SESSION-STATE.md, SOUL.md, TOOLS.md) were reading stale files. Fixed with `ln -sf` to point all to ~/Documents/GitHub/max-ai-employee/workspace/. This means Max was operating with outdated identity, tools, and agent instructions for weeks.
[debug] Two copies of the repo exist: ~/max-ai-employee/ (old, created Jan 29) and ~/Documents/GitHub/max-ai-employee/ (current, active development). The old one should probably be deleted eventually to prevent confusion.

### 2026-02-15 - Version Management Setup
[config] OpenClaw v2026.2.14 installed (latest as of Feb 15, 2026).
- Dockerfile pinned to specific version (was @latest -- risky on redeploy)
- Weekly update check script at skills/shared/scripts/check-openclaw-update.sh
- Mac CLI installed at ~/.npm-global/bin/openclaw
- Date-based versioning: YYYY.M.D format, releases daily/multiple per day
- Known issue: Gateway token leaked in URL redirect (server.js line 1007) -- OpenClaw upstream pattern, cannot fix without forking

### 2026-02-15 - Update Policy
[decision] Pin Dockerfile to specific version. Weekly Telegram alert if new version available. Review changelog before updating. Test locally before redeploying Railway.

### 2026-02-24 - LESSON: Fresh Install > Debugging Corrupted State
[decision] When OpenClaw gateway/node pairing breaks (device token mismatch), a fresh install is almost always faster than debugging file by file. All persistent data lives in Supabase (memory, tasks, goals, leads, contacts, corrections) and the git repo (skills, identity files, workspace docs). A fresh `curl -fsSL https://openclaw.ai/install.sh | bash` takes 5 minutes. Debugging device registries took 4+ hours and still didn't work.

[pattern] OpenClaw device approval state is stored in `~/.openclaw/devices/paired.json` (NOT in identity/device-auth.json or agents/main/agent/auth-profiles.json). Must clear ALL three to fully reset pairing.

[gotcha] Running `openclaw onboard` as a different user (sudo without -u max, or as root) corrupts the device identity. The onboard registers a new device that doesn't match the node's identity. Recovery requires clearing `devices/paired.json`, `identity/device-auth.json`, AND `agents/main/agent/auth-profiles.json` -- or just reinstalling.

[gotcha] `openclaw doctor --fix` can revert model settings and write config keys from a newer version format. If ashley's openclaw is a different version than max's, running ANY openclaw command cross-user introduces version-incompatible config keys.

[decision] For Ashley's setup: install OpenClaw under Ashley's user (LaunchAgents, no sudo) instead of a dedicated max user (LaunchDaemons, constant sudo). Simpler, less error-prone. The max user isolation was over-engineered for a single-owner setup.

### 2026-02-22 - Codex Migration: Config Validation Breaks Everything
[gotcha] openclaw.json with unrecognized keys (`commands.ownerDisplay`, `channels.telegram.streaming`) causes the ENTIRE config to fail validation. Gateway silently falls back to Haiku even when `agents.defaults.model.primary` is set to `openai-codex/gpt-5.3-codex`. The error only shows when running `openclaw models status --plain`. Fix: remove the bad keys with python/jq, not `openclaw doctor --fix` (doctor may revert other settings).

[gotcha] `openclaw doctor --fix` can REVERT model settings back to defaults. After running doctor, always re-check `agents.defaults.model.primary` in openclaw.json. Never rely on doctor to preserve custom model config.

[gotcha] OAuth credentials for openai-codex are stored at `/Users/max/.openclaw/agents/main/agent/auth.json`, NOT in the `credentials/` directory. The credentials dir only holds telegram pairing. Always check auth.json before re-running `openclaw onboard`.

[gotcha] `openclaw onboard --auth-choice openai-codex` with `sudo -u max` fails because the max user has no desktop session to open a browser. Use `sudo OPENCLAW_STATE_DIR=/Users/max/.openclaw openclaw onboard --auth-choice openai-codex` (runs as current user's desktop but saves to max's dir). However, auth tokens may save to current user OR max depending on internal logic -- check both locations.

[gotcha] `openclaw cron` fails with `TypeError: Cannot read properties of undefined (reading 'kind')` when the model in openclaw.json is not recognized or config is invalid. This is a symptom of bad config, not a cron-specific bug.

[pattern] Correct Codex migration sequence: (1) verify auth.json has openai-codex token, (2) remove invalid config keys from openclaw.json, (3) set model to openai-codex/gpt-5.3-codex, (4) restart gateway + node. Do NOT re-run onboard if auth.json already has credentials.

[debug] When Max reports wrong model on Telegram, check in order: (1) openclaw.json validity (run `openclaw models status --plain`), (2) `agents.defaults.model.primary` value, (3) auth.json credentials exist, (4) gateway logs for fallback errors. The model displayed by Max reflects what the gateway actually loaded, not what's in the config file.

### 2026-02-25 - OpenClaw Node Exec Fix (Phase 5)
[gotcha] Node exec (system.run) requires THREE layers of config:
1. `exec-approvals.json` - controls allowlist/blocklist per agent. For headless: `security: "open"`, `ask: "never"`. Node push rejects `note` and `blocklist` fields.
2. `openclaw.json` → `tools.exec.host: "node"` + `tools.exec.node: "<display name>"` - routes exec to the node.
3. `openclaw.json` → `tools.exec.security: "full"` + `tools.exec.ask: "off"` - THIS IS THE CRITICAL ONE. Without this, even open exec-approvals are overridden. Valid values: security = "deny"|"allowlist"|"full", ask = "off"|"on-miss"|"always". Note: exec-approvals uses "open"/"never" but openclaw.json uses "full"/"off".
[gotcha] Shell wrappers (bash -c) are ALWAYS blocked under allowlist security, even with ask=never. The code explicitly checks: `if (security === "allowlist" && parsed.shellCommand && !policy.approvedByAsk)` → denied. Must use "full" security.
[gotcha] The exec-approvals socket file doesn't exist on fresh install. Doesn't matter with ask=off.
[debug] Error progression: "exec host not allowed" → add tools.exec.host. "requires node id" → add tools.exec.node. "approval timed out" → push approvals to node (not just local). "SYSTEM_RUN_DENIED: approval required" → add tools.exec.security="full" + tools.exec.ask="off" to openclaw.json.
