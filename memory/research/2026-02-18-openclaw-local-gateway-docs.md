# OpenClaw Local Gateway Documentation Research

### 2026-02-18 - Comprehensive docs research for Railway -> local migration

## 1. Gateway Modes (local vs remote)

[pattern] `gateway.mode` in `~/.openclaw/openclaw.json` controls behavior:
- `"local"` -- Gateway server runs on your machine (port 18789 default)
- `"remote"` -- Client connects to external Gateway (current setup: Railway)

When `mode: "remote"`, local server settings (port, bind) are ignored. Session files live on the remote host. Checking local Mac files will NOT reflect actual gateway state.

## 2. Switching from Remote to Local

[pattern] Change `gateway.mode` from `"remote"` to `"local"` in `~/.openclaw/openclaw.json`. Then:
```bash
openclaw gateway install   # Creates LaunchAgent plist
openclaw gateway restart   # Starts local gateway
```

LaunchAgent label: `bot.molt.gateway` (or `bot.molt.<profile>`)
Plist location: `~/Library/LaunchAgents/bot.molt.gateway.plist`
Log location: `/tmp/openclaw/openclaw-gateway.log`

## 3. Session/State Migration

[gotcha] The Gateway host is the source of truth for sessions. Remote sessions live on Railway /data/.openclaw/. Steps:
1. Stop remote gateway: `openclaw gateway stop` (on Railway)
2. Export: `tar -czf openclaw-state.tgz .openclaw` (on Railway /data/)
3. Transfer tar to Mac
4. Extract into `~/.openclaw/` (merge carefully, don't overwrite local config)
5. Run `openclaw doctor` to repair/validate
6. `openclaw gateway restart`

[gotcha] `railway run` executes LOCALLY. Need `railway shell` to access /data volume.
[gotcha] Copying as root or changing users breaks credential reads. Ensure ~/.openclaw/ owned by running user.
[gotcha] $OPENCLAW_STATE_DIR contains secrets (API keys, OAuth tokens). Treat backups as production secrets.

## 4. Telegram Channel Configuration

[pattern] Add Telegram channel locally:
```bash
openclaw channels add --channel telegram --token "<BOT_TOKEN>"
```

[gotcha] Telegram channel config only exists on Railway /data volume, not in local ~/.openclaw/openclaw.json. Must re-configure locally OR migrate the full state dir.
[gotcha] Bot token can only be used by one gateway (409 Conflict if both poll). Stop Railway gateway BEFORE starting local.

## 5. Cron Jobs

[pattern] Cron runs INSIDE the Gateway process (not inside the model). Jobs persist at `~/.openclaw/cron/jobs.json`. Run history at `~/.openclaw/cron/runs/<jobId>.jsonl`.

[gotcha] Currently no local cron dir exists (Railway handles all cron). Migration options:
- Copy `cron/` directory from Railway /data/.openclaw/cron/ to local ~/.openclaw/cron/
- OR re-register all 18 jobs via `openclaw cron add` commands
- Manual edits to jobs.json only safe when gateway is stopped

[pattern] Cron survives gateway restarts. If timezone omitted, uses gateway host's local timezone.
[pattern] Top-of-hour jobs get automatic 0-5 minute stagger to reduce load spikes.
[pattern] Hot-reload: cron config changes are "safe" (hot-applied without restart).

Disable cron: `cron.enabled: false` or `OPENCLAW_SKIP_CRON=1` env var.

## 6. Gateway Install Command

```bash
openclaw gateway install    # Creates LaunchAgent, enables daemon
openclaw gateway status     # Check if running
openclaw gateway restart    # Restart service
openclaw gateway stop       # Stop service
openclaw doctor             # Repair services, apply config migrations
openclaw security audit --deep --fix  # Auto-fix permissions
```

LaunchAgent management:
```bash
launchctl kickstart -k gui/$UID/bot.molt.gateway   # Force restart
launchctl bootout gui/$UID/bot.molt.gateway         # Stop
```

Quitting the macOS app does NOT stop the gateway -- launchd maintains it independently.

## 7. Local vs Remote Gotchas

[gotcha] When migrating between modes, the host running the gateway owns the session store + workspace. Migrating local machine does NOT transfer remote gateway state.
[gotcha] Profile/state-dir mismatch between old/new = empty session history symptom.
[gotcha] Copying only openclaw.json is INSUFFICIENT. Need full state dir.
[gotcha] Config hot-reload is "hybrid" by default. Safe changes (channels, cron, tools, skills) hot-apply. Restart-required: port, bind, auth, TLS, plugins.

## 8. Dedicated macOS User

[decision] Recommended approach: standard (non-admin) macOS user account for isolation.
- Cannot access Ashley's .ssh, .aws, browser data
- Zero memory overhead vs Docker
- Gets own Keychain, TCC permissions

[gotcha] Official support for `_clawdbot` system user (LaunchDaemon at /Library/LaunchDaemons/) was proposed in GitHub #2341 but closed without implementation. Current workaround: standard user + LaunchAgent.

## 9. Security Configuration

Hardened local config:
```json5
{
  gateway: {
    mode: "local",
    bind: "loopback",      // localhost only
    auth: { mode: "token", token: "long-random-token" }
  }
}
```

File permissions: 600 for config files, 700 for directories.
Exec approvals: `~/.openclaw/exec-approvals.json` with default deny + allowlist.
Env filtering: blocks DYLD_*, LD_*, NODE_OPTIONS automatically.

## 10. Binding Options

- `loopback` (default, most secure) -- 127.0.0.1 only
- `lan` -- primary LAN IPv4
- `auto` -- auto-detect
- `custom` -- user-specified via `gateway.customBindHost`
- `tailnet` -- Tailscale IP
