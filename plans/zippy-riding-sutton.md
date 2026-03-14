# Plan: Get Max Fully Operational + Switch to ChatGPT

## Context

Max AI Employee (Railway-to-Mac migration) has Phases 0-5 code-complete and committed, but nothing has been deployed to the actual Mac yet. The running system still has stale code. Additionally, Anthropic blocked Max plan OAuth (Jan 2026), making the ChatGPT switch urgent to eliminate API costs. User has ChatGPT Plus ($20/mo).

## What This Plan Does

1. Fix bugs found in code review (wrong paths, wrong defaults)
2. Sync all code to the `max` user on Mac
3. Apply Supabase migration (hybrid memory search)
4. Activate firewall + run security audit
5. Switch gateway to ChatGPT (Phase 5 cutover)
6. Disable nightly-builder temporarily
7. Deploy Cloudflare Worker SMS fallback

## Phase A: Code Fixes (agent team, no sudo needed)

These are repo edits that agents can do in parallel:

### A1. Fix `ai.max.node.plist` - wrong path
- **File:** `config/launchd/ai.max.node.plist:21`
- **Bug:** `/Users/ashleytower/.npm-global/lib/node_modules/openclaw/dist/index.js`
- **Fix:** `/Users/max/.npm-global/lib/node_modules/openclaw/dist/index.js`

### A2. Fix `common.sh` - wrong Ollama model default
- **File:** `skills/shared/lib/common.sh:228`
- **Bug:** `OLLAMA_MODEL="${OLLAMA_MODEL:-mistral-nemo:12b}"`
- **Fix:** `OLLAMA_MODEL="${OLLAMA_MODEL:-qwen2.5:7b}"`

### A3. Fix `common.sh` - wrong log rotation path
- **File:** `skills/shared/lib/common.sh:39`
- **Bug:** `local log_dir="/Users/ashleytower/.openclaw/logs"`
- **Fix:** `local log_dir="/Users/max/.openclaw/logs"`

### A4. Fill Cloudflare Worker phone number
- **File:** `config/cloudflare-worker-fallback.js:31`
- **Current:** `text her at [leave blank for now]`
- **Fix:** `text her at 514-664-7557`

### A5. Commit `scripts/fix-max-git.sh`
- Currently untracked, useful utility for broken git in max's copy

### A6. Remove stale plist if present
- **File:** `config/launchd/com.max.twilio-sms.plist` (ashleytower-user legacy)
- Check if it exists; delete from repo if so

## Phase B: Deploy to Mac (user runs in terminal)

After code fixes are committed and pushed, user runs these commands. I will provide the exact sequence.

### B1. Fix max's git + sync repo
```bash
sudo bash scripts/fix-max-git.sh
sudo bash scripts/phase2/sync-repo.sh
```

### B2. Reinstall node plist (if path was wrong in installed copy)
```bash
# Check the installed plist for the ashleytower path bug
sudo grep -c "ashleytower" /Library/LaunchDaemons/ai.max.node.plist
# If it shows 1+, reinstall from repo source:
sudo cp config/launchd/ai.max.node.plist /Library/LaunchDaemons/ai.max.node.plist
sudo bash scripts/phase2/07-fill-secrets.sh  # repopulate REPLACE_ME values
sudo launchctl kickstart -k system/ai.max.node
```

### B3. Apply Supabase migration
```bash
# Run via Supabase dashboard SQL editor or Rube MCP
# File: supabase/migrations/20260221000001_hybrid_memory_search.sql
```

### B4. Install pf firewall
```bash
sudo bash scripts/phase3/install-pf-rules.sh
sudo pfctl -s rules | grep -E '18789|11434|5050'
```

### B5. Run security audit
```bash
sudo bash scripts/phase4/security-audit.sh
```

### B6. Verify services are healthy
```bash
curl -sf http://localhost:18789 && echo "Gateway OK"
curl -sf http://localhost:5050/health && echo "Twilio-SMS OK"
launchctl print system/ai.max.gateway | grep "state ="
launchctl print system/ai.max.node | grep "state ="
```

## Phase C: Switch to ChatGPT (user runs in terminal)

### C1. Pre-cutover checks
```bash
sudo -u max HOME=/Users/max OPENCLAW_STATE_DIR=/Users/max/.openclaw openclaw --version
# Must be 2026.2.6+

sudo cp -a /Users/max/.openclaw /Users/max/.openclaw.backup-phase5-$(date +%Y%m%d)
```

### C2. Disable nightly-builder cron
Temporarily remove/disable nightly-builder entry in `/Users/max/.openclaw/cron/jobs.json`.

### C3. Run Codex onboard
```bash
sudo -u max HOME=/Users/max OPENCLAW_STATE_DIR=/Users/max/.openclaw openclaw onboard --auth-choice openai-codex
# CRITICAL: Select "Quickstart" -> "Use existing values" (NOT Reset)
# Browser opens -> sign in with ChatGPT account
# After browser auth completes, close the terminal prompt (don't continue wizard)
```

### C4. Set model + persist
```bash
sudo -u max HOME=/Users/max OPENCLAW_STATE_DIR=/Users/max/.openclaw openclaw models set openai-codex/gpt-5.3-codex
sudo -u max HOME=/Users/max OPENCLAW_STATE_DIR=/Users/max/.openclaw openclaw models status --plain
```

Then update openclaw.json:
```json
"agents": { "defaults": { "model": { "primary": "openai-codex/gpt-5.3-codex" } } }
```

### C5. Restart gateway + test
```bash
sudo launchctl kickstart -k system/ai.max.gateway
curl -sf http://localhost:18789 && echo "OK"
# Send test message on Telegram
```

## Phase D: Cloudflare Worker Deploy (manual, workers.cloudflare.com)

1. Go to workers.cloudflare.com
2. Create new Worker
3. Paste contents of `config/cloudflare-worker-fallback.js`
4. Deploy
5. In Twilio Console: set Worker URL as SMS/Voice fallback webhook

## Phase E: Verification

- [ ] Gateway responds on localhost:18789
- [ ] Node connected (check node logs)
- [ ] Twilio-SMS responds on localhost:5050/health
- [ ] Telegram bot responds to test message (using ChatGPT, not Claude)
- [ ] `pfctl -s rules` shows blocked ports
- [ ] Security audit passes
- [ ] Supabase `match_memories_hybrid()` function exists
- [ ] Nightly-builder cron disabled
- [ ] Cloudflare Worker responds at /health

## Rollback

If ChatGPT switch causes issues:
```bash
# Edit openclaw.json, change model back to "anthropic/claude-haiku-4-5"
sudo launchctl kickstart -k system/ai.max.gateway
```
30-second rollback.

## Agent Team Assignment

- **Agent 1 (general-purpose):** Phase A fixes (A1-A6) - edit files, commit
- **Agent 2 (general-purpose):** Apply Supabase migration via Rube MCP
- **Code Reviewer:** Review Phase A changes
- **User (Ashley):** Phases B, C, D terminal commands (I provide exact copy-paste sequence)
