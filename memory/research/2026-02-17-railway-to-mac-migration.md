# Railway to Mac Migration Research

### 2026-02-17 - Research findings from 4 parallel agents

## Docker on Mac - DO NOT USE
[gotcha] Docker Desktop on Apple Silicon does NOT pass GPU to containers. Ollama runs 5-6x slower (CPU only). Docker VM consumes 4-8GB RAM overhead. Unworkable on 16GB machine.

## Dedicated macOS User Account - RECOMMENDED
[pattern] Create standard (non-admin) "max" user for isolation. Gets own home dir, Keychain, TCC permissions. Cannot access Ashley's .ssh, .aws, browser data. Zero memory overhead. SandVault (brew install sandvault) adds sandbox-exec hardening on top.

## Cloudflare Tunnel - RECOMMENDED for webhooks
[pattern] Free tier: unlimited tunnels/bandwidth, custom domain, path-based ingress (regex), auto HTTPS, DDoS, WAF (5 rules), rate limiting, Zero Trust Access (50 users). Install: `brew install cloudflared && sudo cloudflared service install`. Creates launchd daemon at /Library/LaunchDaemons/com.cloudflare.cloudflared.plist.
[gotcha] cloudflared may not auto-reconnect after Mac sleep/wake (GitHub #724). Need watchdog launchd job.

## LLM Routing
[pattern] Three tiers: Ollama (free, local) -> claude -p via Max plan (flat rate) -> Sonnet/Opus (rate-limited). Replace call_claude_api() fallback with call_claude_cli() that unsets ANTHROPIC_API_KEY to force Max plan OAuth.
[gotcha] claude -p has 2-5s startup overhead per call. Not suitable for batch scoring. Keep Ollama for that.
[gotcha] Claude Code refuses to run inside another Claude Code session. Workaround: `env -u CLAUDECODE claude -p ...`

## Twilio Webhook Fragility
[gotcha] Twilio retries SMS webhooks only ONCE (15s after failure). If tunnel is down, inbound SMS is lost. Configure Twilio fallback URL to a Cloudflare Worker with static "we'll get back to you" response.

## Mac Sleep
[gotcha] MacBook Pro sleeps when lid is closed regardless of pmset settings unless external display connected (clamshell mode). Need Amphetamine app or keep lid open.

## Port 5000 Conflict
[gotcha] macOS AirPlay Receiver (ControlCenter) uses port 5000. Change twilio-sms to port 5050.

## Railway Data to Migrate
[gotcha] Telegram channel config only exists on Railway /data volume, not in local ~/.openclaw/openclaw.json. Must re-configure locally. 226 sessions in sessions.json need migration for conversation continuity.
[gotcha] `railway run` executes commands LOCALLY, not on remote container. Need `railway shell` to access /data.

## Rollback
[pattern] Keep Railway running for 2 weeks during soak. Telegram bot token can only be used by one gateway at a time (409 Conflict if both poll). Switch back by updating node plist host and Twilio webhook URL.
