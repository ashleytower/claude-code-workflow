# 2026-02-22 - OpenClaw Gateway Watchdog & Self-Healing Research

[research] Comprehensive search for existing watchdog/self-healing solutions for OpenClaw gateway stability.

## Top Solutions Found

### 1. Ramsbaby/openclaw-self-healing (BEST FIT for macOS)
- GitHub: https://github.com/Ramsbaby/openclaw-self-healing
- 18 stars, MIT license, v3.1.0 (Feb 21, 2026 - actively maintained)
- 4-tier recovery: L0 KeepAlive (0-30s), L1 Watchdog+doctor (3-5min), L2 Claude AI diagnosis (5-30min), L3 Human alert (Discord/Telegram)
- macOS LaunchAgent + Linux systemd support
- Crash loop guard: stops escalating after 5 consecutive failures
- Real-world: 9 of 14 incidents resolved autonomously
- Install: `curl -fsSL https://raw.githubusercontent.com/ramsbaby/openclaw-self-healing/main/install.sh | bash`
- Prereqs: macOS 12+, OpenClaw Gateway, Claude CLI, tmux, jq

### 2. clawdbrunner/openclaw-sentinel (macOS, AI-powered)
- GitHub: https://github.com/clawdbrunner/openclaw-sentinel
- 29 stars, 6 forks
- Health check every 5min, runs `openclaw doctor`, invokes Claude Code for repair
- Cost-controlled: $2 budget per repair, max 20 turns, typical $0.15-$0.70
- Includes backup system (3-tier) and upgrade management
- macOS only (launchd)
- Install: `git clone` then `./install.sh`

### 3. amanaiproduct/openclaw-setup (macOS hardened setup)
- GitHub: https://github.com/amanaiproduct/openclaw-setup
- Includes watchdog LaunchAgent template + watchdog.sh health check script
- Checks gateway health endpoint every 2 minutes, force-restarts if unresponsive
- Part of a broader hardened macOS setup

### 4. Yash-Kavaiya/openclaw-watchdog (Windows only)
- GitHub: https://github.com/Yash-Kavaiya/openclaw-watchdog
- Windows only, PowerShell-based, checks every 5 seconds
- NOT useful for macOS

### 5. rodbland2021 Session Monitor Gist (corruption-focused)
- Gist: https://gist.github.com/rodbland2021/ee54e28fab443730068202249c6ca5bc
- repair-session.py + session-monitor.sh
- Fixes corrupted session transcripts (orphan tool_result)
- Cron-based: runs every 5 minutes
- Detects error loops, context overflow, corrupted sessions
- Telegram alerts

### 6. zach-highley/openclaw-starter-kit (minimal approach)
- GitHub: https://github.com/zach-highley/openclaw-starter-kit
- Warns AGAINST custom watchdog scripts as anti-patterns
- Recommends: launchd KeepAlive + daily 5am `openclaw doctor --fix`

## Known Gateway Bugs (macOS specific)

1. **Unhandled fetch rejection crash loop** (#14649, #4248, #7553, #4425): TypeError: fetch failed kills gateway, launchd throttles after ~50 restarts, gateway stays dead silently for hours. Closed as duplicate, NOT fixed in gateway itself.
2. **SIGUSR1 restart destabilizes launchd** (#14161): config changes trigger SIGUSR1, launchd interprets as crash loop, unloads service. Fix: `openclaw gateway install && restart`.
3. **EPIPE crash on LaunchAgent restart** (#4632): stdout/stderr EPIPE crashes gateway, exponential throttle.
4. **mDNS/Bonjour crash loop** (#3821): sleep/wake network changes trigger unhandled rejection.
5. **Stuck agent loop** (#16808): Agent calls same tool 1500+ times, $150 cost. FIXED in #17118 (merged Feb 16, 2026).

## Official OpenClaw Recommendations

- `openclaw doctor --fix` for automated health checks
- `openclaw status --deep` for per-channel connectivity probe
- `openclaw health --json` for full health snapshot
- `openclaw gateway install --force` to re-register with launchd
- ThrottleInterval in plist to cap restart delay (prevents hours of downtime)
- No official built-in watchdog beyond KeepAlive

## ClawHub (Official Skill Registry)
- URL: https://clawhub.ai
- CLI: `clawhub search "watchdog"` or `clawhub search "gateway monitor"`
- Install: `clawhub install <slug>`
- 3000+ community skills, vector search

## Key Decision
[decision] For this setup (macOS LaunchDaemon, local gateway), **Ramsbaby/openclaw-self-healing** is the best fit:
- macOS native (LaunchAgent)
- 4-tier escalation matches our launchd-based setup
- Actively maintained (v3.1.0, Feb 21, 2026)
- Crash loop guard prevents infinite restart storms
- Can be adapted from LaunchAgent to LaunchDaemon for the "max" user
