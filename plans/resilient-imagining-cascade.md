# Phase 2: Migrate OpenClaw Gateway from Railway to Local Mac

## Context

The OpenClaw Gateway currently runs on Railway (cloud), connecting to the Mac-local OpenClaw Node via WebSocket. This hybrid setup causes recurring failures at the Railway/Mac boundary -- connection hiccups, config drift, split debugging. Phase 1 created the "max" macOS user with directories, symlinks, and LaunchDaemons. Phase 2 moves the gateway itself to run locally under max, eliminating Railway entirely for real-time operations.

**Critical constraint:** macOS TCC blocks LaunchDaemons running as `max` from reading files under `/Users/ashleytower/Documents/` (EPERM). Phase 1 symlinks point there. Fix: clone repo to `/Users/max/max-ai-employee/` and repoint all symlinks.

**Critical constraint:** Telegram bot token can only be polled by ONE gateway (409 Conflict). Must stop Railway before starting local.

## Architecture Change

```
BEFORE: Railway Gateway -(WebSocket/TLS)-> Mac Node -> tools
AFTER:  Mac Gateway (localhost:18789) -> Mac Node (localhost) -> tools
        No Railway dependency. No network boundary.
```

## Scripts (TDD: tests first, then implementation)

### Tests (`scripts/phase2/tests/`)

| File | Tests | What |
|------|-------|------|
| `01-repo-clone.bats` | 5 | Repo at `/Users/max/max-ai-employee/`, max owns it, workspace + skills exist |
| `02-symlinks.bats` | 10 | All 7 identity + skills symlinks point to max's clone (NOT Ashley's repo) |
| `03-gateway-config.bats` | 8 | openclaw.json: mode=local, bind=loopback, port=18789, auth token, Telegram, no mcpServers |
| `04-startup-wrapper.bats` | 5 | `/Users/max/.openclaw/bin/gateway-start.sh` exists, executable, has ensureDefaultModel + exec |
| `05-plists.bats` | 10 | Gateway plist calls wrapper, has RUBE_TOKEN, node plist connects 127.0.0.1:18789 (no --tls) |
| `06-cron.bats` | 4 | `cron/jobs.json` has 18+ jobs, correct timezone |
| `07-secrets.bats` | 5 | No REPLACE_ME in installed plists, tokens non-empty |
| `08-services.bats` | 6 | Gateway health on :18789, Ollama reachable, tunnel healthy, twilio :5050 |
| `run-tests.sh` | -- | Runner: collects .bats files, TAP output, reports pass/fail |

### Implementation (`scripts/phase2/`)

| Script | Purpose | Depends On |
|--------|---------|------------|
| `01-clone-repo.sh` | `git clone` repo to `/Users/max/max-ai-employee/`, install twilio-sms deps | max user |
| `02-repoint-symlinks.sh` | Update all identity + skill symlinks to max's clone | 01 |
| `03-configure-gateway.sh` | Create openclaw.json (local mode), generate auth token, set default model | 01 |
| `04-create-startup-wrapper.sh` | Create `/Users/max/.openclaw/bin/gateway-start.sh` (replaces server.js) | 03 |
| `05-update-plists.sh` | Fix gateway plist (call wrapper, add RUBE_TOKEN), create ai.max.node plist | 04 |
| `06-migrate-cron.sh` | Register 18 cron jobs via `openclaw cron add` | 03 |
| `07-fill-secrets.sh` | Read secrets from Ashley's `ai.openclaw.node.plist`, fill REPLACE_ME | 05 |
| `08-verify-all.sh` | 37+ colored pass/fail checks | all above |
| `cutover.sh` | Stop Railway -> start local gateway + node -> verify Telegram | all verified |
| `rollback.sh` | Emergency: stop local, restart Railway | -- |
| `sync-repo.sh` | Cron-able `git pull` to keep max's clone in sync | 01 |
| `setup-phase2.sh` | Master orchestrator (runs 01-08 in order) | -- |

All scripts get `--dry-run` and `--verify` flags.

## Known Issues to Fix

### 1. Gateway plist missing `--token` flag
server.js passes `--token $TOKEN` (line 228) but `ai.max.gateway.plist` only has `--auth token`. Fix: startup wrapper reads token and passes `--token`.

### 2. RUBE_TOKEN missing from gateway plist
mcporter.json uses `${RUBE_TOKEN}`. Plist has `COMPOSIO_API_KEY`. Fix: add `RUBE_TOKEN` to plist env vars.

### 3. TCC breaks Phase 1 symlinks
All symlinks point to `/Users/ashleytower/Documents/...` which max LaunchDaemons cannot read. Fix: clone repo to max's home, repoint symlinks.

### 4. No node plist for local connection
Current `ai.openclaw.node.plist` connects to Railway (`openclaw-production-efd7.up.railway.app:443 --tls`). Need new `ai.max.node.plist` connecting to `127.0.0.1:18789` (no --tls).

### 5. Ollama model mismatch (non-blocking)
common.sh defaults to `mistral-nemo:12b`, CLAUDE.md says `qwen2.5:7b`. Verify with `ollama list` and reconcile.

## Startup Wrapper (`gateway-start.sh`)

Replaces server.js functions for launchd. Key logic:
1. `ensureDefaultModel` -- runs `openclaw models set anthropic/claude-haiku-4-5` + patches sessions.json
2. `cleanupConfig` -- removes invalid mcpServers from openclaw.json
3. `resolveGatewayToken` -- reads from env or `~/.openclaw/gateway.token`, generates if missing
4. `exec` gateway -- replaces process so launchd manages the real gateway PID

Source reference: `src/server.js` lines 22-258 (resolveGatewayToken, ensureDefaultModel, cleanupConfig, startGateway).

## Secret Sources

Read from Ashley's existing `ai.openclaw.node.plist` (`/Users/ashleytower/Library/LaunchAgents/`):
- RUBE_TOKEN
- SUPABASE_URL, SUPABASE_SERVICE_KEY
- ANTHROPIC_API_KEY
- TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID

Generated:
- OPENCLAW_GATEWAY_TOKEN (via `openssl rand -hex 24`)

## Agent Team Plan

**Stream A (TDD first):** `@backend` -- Write all 8 bats test files + run-tests.sh

**Stream B (parallel, after tests):**
- `@backend` agent 1: `01-clone-repo.sh`, `02-repoint-symlinks.sh`
- `@backend` agent 2: `03-configure-gateway.sh`, `04-create-startup-wrapper.sh`

**Stream C (after B):**
- `@backend` agent 1: `05-update-plists.sh`, `07-fill-secrets.sh`
- `@backend` agent 2: `06-migrate-cron.sh`

**Stream D (after C):** `@backend` -- `08-verify-all.sh`, `cutover.sh`, `rollback.sh`, `setup-phase2.sh`, `sync-repo.sh`

**Stream E:** `@code-reviewer` reviews all scripts, `@code-simplifier` cleanup pass, `@verify-app` final validation

## Cutover Sequence

1. Run `08-verify-all.sh` -- all checks pass (except gateway health)
2. Pick low-traffic time (suggest 7am ET, before 8am crons)
3. Stop Railway gateway: `railway service stop`
4. Wait 3 seconds (Telegram polling release)
5. Bootstrap gateway: `sudo launchctl bootstrap system /Library/LaunchDaemons/ai.max.gateway.plist`
6. Wait for health: `curl --retry 20 --retry-delay 3 localhost:18789/health`
7. Bootstrap node: `sudo launchctl bootstrap system /Library/LaunchDaemons/ai.max.node.plist`
8. Test Telegram: send message, verify response
9. Verify crons, SMS, tunnel

**Estimated downtime:** 30-40 seconds. Telegram queues messages 24h.

**Rollback:** `rollback.sh` -- stop local, restart Railway. Keep Railway alive (stopped) for 2 weeks.

## Post-Cutover Monitoring (48h)

- Telegram responsiveness (every 2h)
- Gateway health (every 15min via `curl localhost:18789/health`)
- First heartbeat fires (30min after cutover if within 8am-11pm)
- Morning brief at 8:30am
- Nightly builder at 11pm
- Memory pressure (peak ~10-11GB of 16GB)

## Critical Files

| File | Role |
|------|------|
| `config/launchd/ai.max.gateway.plist` | Gateway LaunchDaemon (update: call wrapper, add RUBE_TOKEN) |
| `src/server.js:22-258` | Logic to replicate in startup wrapper |
| `skills/shared/lib/common.sh` | Shared functions (call_claude_cli, call_ollama, rube_execute) |
| `/Users/ashleytower/Library/LaunchAgents/ai.openclaw.node.plist` | Secret source for fill-secrets.sh |
| `scripts/phase1/07-verify-all.sh` | Pattern to follow for 08-verify-all.sh |
| `scripts/phase1/fix-tcc.sh` | TCC workaround pattern (copy to max's home) |

## Verification Checklist

- [ ] All bats tests pass
- [ ] 08-verify-all.sh reports all checks green
- [ ] Gateway responds on localhost:18789
- [ ] `openclaw cron list` shows 18+ jobs
- [ ] Telegram message sent and response received
- [ ] SMS webhook works (curl letsaskmax.com/health)
- [ ] No REPLACE_ME in installed plists
- [ ] Gateway bound to loopback only (not 0.0.0.0)
- [ ] gateway.token is max:staff 600
- [ ] Plists are root:wheel 644
- [ ] 48h monitoring clean
