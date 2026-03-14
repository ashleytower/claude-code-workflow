# OpenClaw Setup Notes

### 2026-02-25 - Fresh Install Lessons (2 sessions of debugging)

[gotcha] Token mismatch between gateway and node persisted across 2 sessions despite all visible configs matching. Never debug this -- wipe and reinstall. The official installer handles token alignment internally.

[gotcha] `openclaw node install --force` strips all custom env vars from the node plist. Must re-add RUBE_TOKEN, SUPABASE, ANTHROPIC, TELEGRAM, OLLAMA vars manually every time.

[gotcha] `openclaw gateway install --force --token <token>` may set an internal token that doesn't match what you think. Let the installer handle token setup.

[gotcha] auth-profiles.json at `~/.openclaw/agents/main/agent/auth-profiles.json` must have API keys. Fresh install creates it empty. Gateway reads keys from here, NOT from plist env vars or shell env.

[gotcha] dmPolicy "open" requires `allowFrom: ["*"]` in openclaw.json. Without it, config validation fails silently and pairing is still required.

[gotcha] Node shows "unpaired - connected" for local loopback connections. This is cosmetic -- commands still reach the node.

[pattern] ALWAYS follow the Phase 5 plan at `docs/plans/2026-02-21-phase5-codex-migration.md`. Use `openclaw onboard --auth-choice openai-codex` for Codex setup.

[pattern] ALWAYS use agent teams with a monitor agent for OpenClaw setup tasks. Solo debugging leads to circles.

[decision] 2026-02-25: Migrated from dedicated `max` user (LaunchDaemons, sudo required) to `ashleytower` user (LaunchAgents, no sudo). Clean slate approach chosen after 2 sessions of token debugging.

[decision] 2026-02-25: Phase 5 Codex migration chosen over continuing with Anthropic Haiku. Eliminates gateway API costs.

[debug] exec-approvals.json needs shell tools (bash, sh, zsh, cat, ls, grep, etc.) in the allowlist. Default only has curl/jq/git/node/python3. Without shell tools, node commands fail with "not in allowlist" errors.
