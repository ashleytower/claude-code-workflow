# Team Debrief: Phase 1 max-user Setup Scripts

**Date:** 2026-02-18
**Project:** max-ai-employee (Railway-to-Mac migration)
**Team:** phase1-max-user (6 agents: backend, impl-1 through impl-4, code-reviewer, code-simplifier, verifier)
**Duration:** ~20 minutes wall clock

## What Went Smoothly

- 10 stories implemented in parallel waves (4 agents at a time)
- All scripts passed shellcheck on first write (agents followed the shellcheck-before-report pattern)
- Plist files validated by plutil on first write
- Dry-run mode worked end-to-end on the master orchestrator immediately
- Code review caught 4 real bugs that would have broken production setup

## What Was Hard

- **Agent message delivery confusion**: impl-1/2/3 received new task assignments but thought they were being asked about their already-completed previous tasks. Required explicit "IMPORTANT: This is a NEW task" prefix to break the pattern. [gotcha] Always prefix re-dispatched agents with "NEW TASK" to avoid confusion with previous assignments.
- **No-args behavior mismatch**: 02-setup-dirs.sh exited with usage when called with no args, but the orchestrator called it with no args. Code review caught this. [gotcha] When writing scripts that will be called by an orchestrator, default to "run mode" with no args.

## Key Learnings

- [gotcha] macOS `chmod +a` DOES add duplicate ACL entries. The comment claiming idempotency was wrong. Fix: remove before add (`chmod -a ... || true` then `chmod +a`).
- [gotcha] `caffeinate -s` creates IOPMAssertion which requires root. LaunchDaemon with `UserName=max` drops privileges BEFORE running the command, so caffeinate may silently fail. Fix: no UserName key for caffeinate (runs as root).
- [pattern] LaunchDaemons that need system-level access (sleep prevention, network binding) should NOT use UserName. Only use UserName for app-level services.
- [gotcha] `launchctl load` is deprecated since macOS 10.11. Use `launchctl bootstrap system <path>` and `launchctl bootout system/<label>`.
- [pattern] Homebrew `/opt/homebrew/bin/` is 755 (world-executable). Non-admin users CAN execute binaries there without being in admin group. nvm is for interactive use; LaunchDaemons need stable absolute paths.
- [decision] Node path in plists: Use `/opt/homebrew/bin/node` (stable, world-executable) rather than nvm path (version-dependent, requires shell sourcing).
- [gotcha] `sudo -u max bash` does NOT reset HOME. The Claude Code installer writes to $HOME/.claude/downloads which resolves to Ashley's home. Fix: use `sudo -H -u max bash` (-H flag resets HOME to target user).
- [gotcha] Claude Code installer v2.1+ installs to `~/.local/bin/claude`, NOT `~/.claude/local/claude`. Check both paths in verification scripts.
- [gotcha] nvm installer warns "Profile not found" for new users with no .zshrc/.bashrc. It still installs, just can't auto-add PATH entries. Source nvm.sh explicitly in scripts.
- [gotcha] `set -euo pipefail` in install scripts means if Claude Code install fails, the script exits before removing max from admin group. Either use a trap for cleanup or run admin removal in a separate step.
- [gotcha] macOS TCC (Transparency, Consent, and Control) blocks cross-user access to ~/Documents/ even with correct ACLs. `sudo -u max cat /Users/ashleytower/Documents/...` works (sudo has TCC bypass), but LaunchDaemons running as max get EPERM. ACLs are NOT sufficient for cross-user ~/Documents/ access. Files must live outside TCC-protected paths or inside max's own home.
- [gotcha] Node binary at `/usr/local/bin/node` on this system, NOT `/opt/homebrew/bin/node` (Apple Silicon Homebrew default). Always check `which node` rather than assuming Homebrew paths.

## Unresolved

- **Review finding #20**: Gateway plist references `openclaw` npm package at `/Users/max/.npm-global/lib/node_modules/openclaw/dist/entry.js` but install script doesn't install it. Needs manual `npm install -g openclaw` as max user, or add to install script in Phase 2.
- **Review finding #13**: `USER.md` exists in workspace/ but is not symlinked. Check if OpenClaw uses it.
- **Review finding #14**: No log rotation for LaunchDaemon stdout/stderr logs. Add to Phase 2 or Phase 4 cleanup.
- **Review finding #8**: sysadminctl password visible in `ps aux` during execution. Documented limitation.

## Deliverables (17 files)

### Scripts (8)
- scripts/phase1/01-create-user.sh (133 lines)
- scripts/phase1/02-setup-dirs.sh (133 lines)
- scripts/phase1/03-setup-acls.sh (163 lines)
- scripts/phase1/04-setup-symlinks.sh (186 lines)
- scripts/phase1/05-setup-launchdaemons.sh (168 lines)
- scripts/phase1/06-install-tools.sh (247 lines)
- scripts/phase1/07-verify-all.sh (319 lines)
- scripts/phase1/setup-max-user.sh (218 lines)

### LaunchDaemon Plists (4)
- config/launchd/ai.max.gateway.plist
- config/launchd/ai.max.twilio-sms.plist
- config/launchd/ai.max.cloudflared.plist
- config/launchd/ai.max.caffeinate.plist

### Tests (8)
- scripts/phase1/tests/run-tests.sh + 7 bats files (59 tests)

### Config
- scripts/phase1/prd.json
