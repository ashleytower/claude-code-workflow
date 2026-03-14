# Heartbeat System

### 2026-02-10 - Max was faking heartbeat checks
[gotcha] HEARTBEAT.md allowed Max to report "HEARTBEAT_OK" without actually calling any APIs. The heartbeat is triggered by the gateway every 30 min via openclaw.json config (not a cron job). Fixed by: (1) removing the "Stay silent (HEARTBEAT_OK)" option, (2) adding mandatory API calls section requiring INSTAGRAM_LIST_ALL_CONVERSATIONS, GMAIL_FETCH_EMAILS, and Supabase pending count query, (3) requiring structured reporting format with actual counts. Max must now report what it actually checked.

### 2026-02-10 - Two AGENTS.md / HEARTBEAT.md locations
[gotcha] Identity files exist in two places: the GitHub repo (`/Users/ashleytower/Documents/GitHub/max-ai-employee/workspace/`) and a separate copy (`/Users/ashleytower/max-ai-employee/workspace/`). The symlinks at `~/.openclaw/identity/` point to DIFFERENT locations for different files (HEARTBEAT.md -> GitHub repo, AGENTS.md -> non-GitHub copy). When editing identity files, always update BOTH locations. Check `ls -la ~/.openclaw/identity/` to see which location each symlink targets.
