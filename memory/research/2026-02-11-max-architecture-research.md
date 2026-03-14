# Max AI Employee Architecture Research - Feb 11, 2026

## Sources
7 research agents covering: Alex Finn YouTube, Medium/Reddit/DO articles, OpenClaw docs, framework comparison, mtl-craft-cocktails-ai repo, client-portal-proposal repo, voice agent platforms.

## Key Decisions

### 1. Keep OpenClaw (hardened)
Nothing else has native multi-channel + identity system. Migration cost too high. Security audit needed (CVE-2026-25253, 341 malicious skills on ClawHub).

### 2. Move gateway to Mac (eliminate Railway)
[decision] Telegram long-polling works without webhook/public URL. Direct tool execution when gateway+tools on same machine. Eliminates WebSocket hop, exec host issues, skill path errors, Railway cost.

### 3. Three-tier model routing
[pattern] Budget (Gemini Flash-Lite $0.50/M): heartbeats, classification. Mid-tier (Haiku/DeepSeek R1 $1-2.74/M): daily work. Frontier (Sonnet/Opus $3-75/M): drafting, coding. Per-cron --model overrides work for isolated jobs.

### 4. Heartbeat model override is broken
[gotcha] Issue #9556. Config exists but doesn't work. PRs #9721 and #12704 pending. Workaround: cheap primary model + per-cron upgrades.

### 5. Stay with Vapi for voice
Already integrated, lowest latency (<500ms), new SMS capability. Retell AI is cheaper ($0.07/min flat) if volume grows. Keep as OpenClaw skill for cross-channel correction learning.

### 6. Node 22+ has Telegram long-polling bugs
[gotcha] Issues #7519 and #1639. AbortErrors and polling stalls. Use latest OpenClaw build or Node 20.

### 7. Two separate Supabase projects
[gotcha] mtl-craft-cocktails-ai uses `ctyxnhcljruyciebkwef`. Max uses `clnxmkbqdwtyywmgtnjj`. Client-portal-proposal shares Max's DB. Need bridge for dashboard<->Max integration.

### 8. client-portal-proposal is the revenue bridge
[pattern] Max scrapes leads -> creates quotes in Supabase -> portal sends branded proposal -> client pays deposit via Stripe. Direct lead-to-revenue pipeline.

### 9. Security hardening required
[decision] Run `openclaw security audit --deep`. Pin version. Audit skills (no ClawHub). Gateway bind 127.0.0.1. Per-agent tool deny lists. Container isolation.

### 10. Alex Finn pattern worth adopting
[pattern] Brain dump everything, context-first design, slash commands + sub-agents, reverse prompting technique.
