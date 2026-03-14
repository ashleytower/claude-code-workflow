# OpenClaw Full Architecture Audit

**Date:** 2026-02-07
**Reviewers:** 7 parallel agents
**Version:** OpenClaw 2026.2.6-3, Model: Kimi K2.5 via OpenRouter

## Critical Findings

### 1. Kimi K2.5 Tool-Use is BROKEN
[gotcha] GitHub issue #9413: tool events not delivered for kimi-k2.5 on non-TUI clients (Telegram gateway). PR #8432 broke capability-based routing. Max cannot execute tools, create cron jobs, or run skills via Telegram. SWITCH BACK TO CLAUDE.

### 2. 6 Scheduled Skills NOT REGISTERED in OpenClaw Cron
[gotcha] moltbot.json is a design doc, NOT read by OpenClaw. Jobs must be registered via `openclaw cron add`. Missing: fb-group-monitor, reddit-engage, lead-pipeline (x4). These skills have NEVER run.

### 3. 3 New Skills NOT DEPLOYED (no symlinks)
[gotcha] lead-pipeline, fb-group-monitor, reddit-engage exist in repo but have no symlinks in ~/.openclaw/skills/. They were added on feat/reddit-engage branch; watcher syncs from main only.

### 4. Gateway WebSocket Flapping
[debug] Hundreds of `gateway closed (1006)` in node.err.log. Railway gateway connection drops and reconnects constantly. May cause dropped skill executions.

### 5. All Secrets Exposed in Git History
[gotcha] railway-vars-backup.json was committed (79116e7) then removed (82bc610). All production secrets (Anthropic, Telegram, Railway, Rube, Composio, etc.) remain in git history. Need rotation + history purge.

### 6. Morning-Brief Last Ran Feb 1
[debug] 7-day gap in cron execution. All cron jobs may be silently failing.

## Schedule Mismatches (moltbot.json vs actual OpenClaw cron)
- morning-brief: 8am -> actually 8:30am
- email-drafter: 2am -> actually 10am
- afternoon-report: daily -> actually Monday only
- morning-reviewer: crontab 6am but no env vars loaded -> FAILS

## Missing Capabilities
- No reminder/alarm skill (OpenClaw supports `openclaw cron add --at` one-shots)
- No real-time email (Gmail Pub/Sub supported but not configured)
- Instagram DMs only checked every 30min heartbeat (no push)
- Facebook Messenger DMs not monitored at all
- No WhatsApp integration

## OpenClaw Features NOT Being Used
- Gmail Pub/Sub hooks (real-time email)
- Context pruning (adaptive mode saves tokens)
- Message debouncing (2s batches rapid messages)
- Identity links (cross-channel session continuity)
- TTS auto-generation for Telegram voice notes
- Webhook integration with n8n/Make for unsupported channels

## Architecture Notes
- Railway gateway: handles Telegram polling, LLM calls, cron scheduling
- Mac node: executes shell commands, runs skills, browser automation
- WebSocket connects the two, authenticated by gateway token
- Env vars come from Railway (gateway side) for cron jobs
- Exec-approvals.json controls what commands node can run
- Cron agent missing git/gh in allowlist (nightly-builder needs them)
