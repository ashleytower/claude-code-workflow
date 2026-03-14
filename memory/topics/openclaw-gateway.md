# OpenClaw Gateway

### 2026-02-16 - Telegram Max not responding (gateway down)
[debug] Gateway was returning 502. Two issues:
1. Container had been stopped (SIGTERM at 2026-02-15 20:50 ET) and never restarted. `railway redeploy` failed because it reused a stale/wrong image that ran twilio-sms code instead of the gateway.
2. Fix: `railway link -s openclaw -e production` then `railway up` (fresh build from repo root using root Dockerfile). `railway redeploy` alone was not enough.
3. After gateway came up, Telegram still broken: a webhook was set on the bot pointing to `twilio-sms-production-b6b8.up.railway.app/approval`. This blocked the gateway's `getUpdates` polling. Fix: `curl "https://api.telegram.org/bot<TOKEN>/deleteWebhook"`.

[gotcha] The Telegram bot can only use ONE method: either webhook OR polling. OpenClaw gateway uses polling (`getUpdates`). If anything sets a webhook (even manually), polling breaks with 409 Conflict. Always check `getWebhookInfo` if Telegram stops working.

[gotcha] `railway redeploy` reuses the existing image. If the image is broken, use `railway up` for a fresh build. Also verify the Railway CLI is linked to the correct service (`railway status`).

[gotcha] The Railway CLI in this repo defaults to `twilio-sms` service. To work with the gateway, must explicitly link: `railway link -p 77e97a0b-961a-4ce7-8005-feff63e30b5a -s openclaw -e production`. Always re-link back to twilio-sms when done.

### 2026-02-19 - OpenClaw Gateway Local Mode Research (context7 MCP)
[research] Full documentation review for Phase 2 migration. Key findings:

**Gateway local mode setup:**
- `gateway.mode` must be `"local"` in `~/.openclaw/openclaw.json` -- gateway refuses to start otherwise
- `gateway.bind` options: `auto`, `loopback` (default, localhost only), `lan` (0.0.0.0), `tailnet`, or custom IP
- Non-loopback bind requires auth (token or password) -- gateway refuses with "refusing to bind gateway ... without auth"
- Port 18789 is the default. Precedence: CLI flag > env var > config file.
- `EADDRINUSE` means another gateway or process is on that port.

**LaunchAgent/LaunchDaemon:**
- `openclaw gateway install` creates a LaunchAgent plist automatically. Label: `bot.molt.gateway` (or `bot.molt.<profile>` for named profiles).
- Legacy labels `com.openclaw.*` may still exist on older installs.
- Plist location: `~/Library/LaunchAgents/bot.molt.gateway.plist` (LaunchAgent) or `/Library/LaunchDaemons/` (our custom approach with UserName=max).
- Manage with: `launchctl kickstart -k gui/$UID/bot.molt.gateway` (restart), `launchctl bootout gui/$UID/bot.molt.gateway` (stop).
- For our headless setup, we use custom LaunchDaemon plists (`ai.max.gateway`) with `/bin/bash gateway-start.sh` wrapper.
- `openclaw doctor` audits and repairs service config drift. `--fix`, `--yes`, `--repair`, `--repair --force` options.
- `openclaw gateway install --force` forces full plist rewrite if config mismatch.

[gotcha] `openclaw gateway install` creates its OWN LaunchAgent with label `bot.molt.gateway`. This could CONFLICT with our custom `ai.max.gateway` LaunchDaemon. Do NOT run `openclaw gateway install` after deploying our custom plists -- it will create a second service. Use `openclaw doctor` carefully or skip it.

[gotcha] Gateway config mismatch: if `openclaw gateway status` shows different configs for CLI vs service, use `openclaw gateway install --force` to align them. But this will overwrite our custom plist, so only use for troubleshooting.

**Token auth:**
- Config: `gateway.auth.mode = "token"`, `gateway.auth.token = "<token>"`
- Token can also come from env var `OPENCLAW_GATEWAY_TOKEN`
- Rate limiting available: `auth.rateLimit.maxAttempts`, `windowMs`, `lockoutMs`, `exemptLoopback`
- Other auth modes: `password` (OPENCLAW_GATEWAY_PASSWORD), `trusted-proxy` (x-forwarded-user header)

**Telegram channel:**
- Config: `channels.telegram.enabled = true`, `channels.telegram.botToken = "123:abc"`
- `dmPolicy`: `pairing` (recommended), `allowlist`, `open`, `disabled`
- `allowFrom`: list of allowed users e.g. `["tg:123456789"]`
- `streamMode`: `off`, `partial` (recommended), `block`
- CLI add: `openclaw channels add --channel telegram --token $BOT_TOKEN`
- Bot token can ONLY be used by one gateway -- 409 Conflict if both Railway and local poll simultaneously

**Cron/Scheduler:**
- Cron jobs persist at `~/.openclaw/cron/jobs.json` -- gateway reads on startup, hot-reload supported
- CLI: `openclaw cron add --name <n> --cron "<expr>" --tz "America/New_York" --session isolated --message "<msg>" --channel telegram`
- Jobs.json format: array of objects with `name`, `cron`, `timezone`, `session`, `message`, `channel` keys
- Also supports `--at <time>` (one-shot), `--every <duration>` (interval), `--system-event <event>`
- Can pre-write jobs.json before gateway starts (our approach in 06-migrate-cron.sh)

**Node host (tool executor):**
- `openclaw node install --host <gateway-host> --port 18789 --display-name "Build Node"`
- For local: `--host 127.0.0.1 --port 18789` (no --tls needed for loopback)
- `openclaw node run --host <gateway-host> --port 18789` for foreground
- `openclaw node status` to check

**Migration from cloud to local:**
- Copy `$OPENCLAW_STATE_DIR` (default `~/.openclaw`) from old machine
- Copy workspace directory
- Run `openclaw doctor` after migration
- State dir contains secrets (API keys, OAuth tokens) -- treat as production secrets
- Profile/state-dir mismatch = empty session history
- Persistence: openclaw.json, model auth profiles, skill configs, workspace, WhatsApp session, Gmail keyring all under ~/.openclaw/

**Known issues / gotchas:**
- "Gateway start blocked: set gateway.mode=local" -- must explicitly set mode in config
- 0.0.0.0 binding vulnerability: 135K+ instances found exposed. Always use loopback + tunnel.
- Config mismatch between CLI and service is common after manual edits
- Bun is NOT recommended as gateway runtime -- use Node.js
- Node.js 22+ required

### 2026-02-20 - Phase 2 Cutover Complete (Railway -> Local Mac)
[decision] Gateway successfully migrated from Railway to local Mac. All services verified:
- Gateway: localhost:18789 (launchd: ai.max.gateway)
- Node: localhost (launchd: ai.max.node, connects to 127.0.0.1:18789)
- twilio-sms: localhost:5050 (launchd: ai.max.twilio-sms)
- Cloudflare tunnel: letsaskmax.com
- Telegram: test message sent successfully

[gotcha] `agents.defaults.model` in openclaw.json must be an OBJECT `{"primary": "anthropic/claude-haiku-4-5"}`, NOT a string. The context7 docs are misleading. Always reference Ashley's working config at `~/.openclaw/openclaw.json` for the correct schema.

[gotcha] `git clone` hangs when cloning from ashleytower-owned repo as root/max due to safe.directory + TCC restrictions. Use `cp -a` instead, then `chown -R max:staff`.

[gotcha] `sudo rm -rf /path/*` with zsh fails silently when the current user can't read the directory (700 perms, owned by another user). Glob expands BEFORE sudo runs. Fix: use `find /path -mindepth 1 -maxdepth 1 -exec rm -rf {} +` under sudo instead.

[gotcha] `ln -sf target linkname` on an existing DIRECTORY creates the symlink INSIDE the directory instead of replacing it. Must `rm -rf` the existing dir first, then `ln -s`.

[gotcha] `grep -c` on binary plist files (after PlistBuddy edits) produces multi-line output that breaks `[[ ]]` arithmetic. Use `grep -q` instead.

[pattern] For migration scripts requiring sudo, write self-contained .sh files rather than giving users long commands to paste. Terminal line-wrapping breaks multi-argument commands.

### 2026-02-20 - Phase 5 TODO: Switch to ChatGPT Codex (eliminate API costs)
[research] OpenClaw can use ChatGPT Codex model via subscription auth (no per-token API costs).
- Reference: https://travis.media/blog/switch-openclaw-claude-to-chatgpt/
- Command: `openclaw onboard --auth-choice openai-codex` (select "Use existing values" to keep config)
- Then: `openclaw models set openai-codex/gpt-5.3-codex`
- Verify: `openclaw models status --plain`
- This would eliminate the Anthropic API key dependency for the gateway entirely.
- Could also stay on Claude with API key (console.anthropic.com) instead of OAuth.
- DO AFTER Phase 2 is stable. Not urgent.

### 2026-02-21 - Phase 3/4/5 implementation learnings

[gotcha] Anthropic blocked Max plan OAuth tokens for third-party tools (Jan 9, 2026). The nightly-builder `unset ANTHROPIC_API_KEY && claude -p` approach may already be broken server-side. Codex migration is more urgent than expected.

[pattern] Parallel ralph-loop agents work well when file partitioning is clean: Phase 3 (common.sh, migrations, nightly-builder), Phase 4 (archive, workspace, config), Phase 5 (docs, research). All 10/10 stories passed first try. Key: each agent does `git pull --rebase` before each story.

[gotcha] match_memories_hybrid() SQL RPC must include user_id filter AND LIMIT on vector_results CTE. Without LIMIT, pgvector does full table scan on every query (degrades at 10K+ rows). Without user_id, SECURITY DEFINER bypasses RLS.

[gotcha] `echo "$text" | grep -qE` is unsafe when $text starts with hyphen. Use `grep -qE 'pattern' <<< "$text"` (here-string) instead. Also eliminates a subshell per check.

[gotcha] Python string interpolation in bash `python3 -c "...('${var}')"` is shell injection. Use env var: `QUERY="$var" python3 -c "import os; print(os.environ['QUERY'])"`.

[pattern] check_for_leaked_secrets() scans outbound messages for API key patterns. Key: REDACT the message (replace with placeholder) rather than dropping it silently. Never lose the signal that a message was attempted.

[decision] pf anchor: removed `pass in all flags S/SA keep state` rule that was overly permissive. Block-quick on ports 11434/8080/18789/5050 + loopback pass + ICMP pass is sufficient.

[decision] package.json renamed from `openclaw-railway-template` to `max-ai-employee`. Scripts now point to bats tests + shellcheck instead of archived server.js.

### 2026-02-22 - Gateway Watchdog Deployed (fixes recurring timeout/hang issue)

[decision] Built custom gateway watchdog instead of using third-party tools (Ramsbaby/openclaw-self-healing, clawdbrunner/sentinel, etc.). All community tools are <3 weeks old, low star count, unaudited -- too risky to run as root on the Mac. Our watchdog is 20 lines of logic, zero dependencies beyond common.sh.

[pattern] Gateway watchdog (`ai.max.watchdog`):
- Curls `localhost:18789` every 3 min via launchd StartInterval
- 2 consecutive failures -> `sudo launchctl kickstart -k system/ai.max.gateway`
- Anti-flap: 5 min cooldown between restarts
- Telegram alerts on restart AND recovery
- Runs as root (no UserName key) because `launchctl kickstart` requires root
- State files: `/Users/max/.openclaw/watchdog/{fail_count,last_restart}`
- 16 bats tests, all passing

[gotcha] `KeepAlive: true` in launchd only restarts CRASHED processes. A hung gateway (stuck LLM call, stuck Telegram poll) stays alive but unresponsive -- launchd sees it running and does nothing. External health check watchdog is required.

[gotcha] `caffeinate -s` only prevents system sleep, NOT idle sleep. macOS can still throttle network on idle. Add `-i` flag: `caffeinate -s -i`.

[gotcha] Without `ThrottleInterval` in launchd plists, repeated crashes cause exponential backoff up to hours of silent downtime. Added `ThrottleInterval: 5` to all service plists (caps restart delay to 5 seconds).

[gotcha] `LOG_FILE` must be set BEFORE sourcing common.sh. The `log()` function does `tee -a "$LOG_FILE"` and with `set -e`, an unset LOG_FILE crashes the script immediately. Tests mask this because they export LOG_FILE in setup.

[gotcha] For deploy scripts requiring sudo, write self-contained .sh files (`scripts/deploy-watchdog.sh`). Terminal copy-paste breaks multi-argument commands -- spaces between source and destination get eaten, causing `cp` to fail with "usage" errors.

[pattern] `rotate_openclaw_logs()` in common.sh now uses `*.log` glob (was hardcoded to node.log only). Gateway, cloudflared, twilio-sms, and watchdog logs all get rotated automatically.

[research] Full watchdog research saved to `~/.claude/memory/research/2026-02-22-openclaw-gateway-watchdog-research.md`. Covers 6 community projects, 8 known gateway bugs, official OpenClaw health commands, ClawHub skill registry.
