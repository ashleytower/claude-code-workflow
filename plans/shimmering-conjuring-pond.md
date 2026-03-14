# Plan: Activate Max as a Real Employee

## Context

Ashley wants to start actually using Max day-to-day. The infrastructure is 90% built -- email drafting, brain dump, task tracker, correction learning -- but key pieces are either unverified or missing the interactive layer. The biggest gap: Ashley can't tell Max "reply to that email saying X" via Telegram. The system is reactive (cron drafts, then approve/edit/skip) but not interactive.

This plan activates what exists, fills the interactive email gap, and processes Ashley's goals through the brain dump system.

---

## Step 1: Commit Technical Fixes (already done by agent)

**Files modified (uncommitted):**
- `.gitignore` -- added `*.skill` pattern to prevent binary bundles from being tracked
- `skills/email-master/email-master/scripts/process-emails.sh` -- added Ollama fallback Telegram alert (once per run)

**Action:** Commit and push both changes.

---

## Step 2: Verify Existing Systems Are Live

Before building anything new, confirm the 3 core systems are actually running.

### 2a. Brain-dump skill
- Check symlink: `ls -la ~/.openclaw/skills/brain-dump`
- If missing: `ln -s /path/to/skills/brain-dump ~/.openclaw/skills/brain-dump`
- Check cron: `openclaw cron list | grep weekly-goal-review`
- If missing: register via `openclaw cron add`

### 2b. Task manager skill
- Check symlink: `ls -la ~/.openclaw/skills/task-manager`
- If missing: create symlink
- Verify Supabase tables exist: run `SELECT count(*) FROM tasks` via Rube

### 2c. Email-master skill
- Verify symlink: `ls -la ~/.openclaw/skills/email-master`
- Check cron jobs are registered: `openclaw cron list | grep email`
- Confirm inbox-watcher is running: `openclaw cron list | grep inbox-watcher`
- Test: check Telegram for recent email alerts

---

## Step 3: Enable Interactive Email (THE BIG FEATURE)

**Problem:** Ashley can tell Max "send" / "change: make it more formal" / "skip" for existing drafts. But she can't say "reply to the email from Venue XYZ saying we're available Saturday at $2500."

**Solution: Update identity files with interactive email instructions.**

This does NOT require new bash scripts. OpenClaw's LLM gateway already has access to all Gmail tools via Rube MCP. What's missing is clear instructions telling the LLM HOW to handle interactive email commands.

### 3a. Update `skills/email-master/email-master/SKILL.md`

Add a new section: **Interactive Email Commands**

When Ashley sends a message like:
- "Reply to [sender/subject] saying [content]"
- "Tell them [content]" (uses most recent email context)
- "Draft an email to [address] about [topic]"
- "Forward that to [address]"

The LLM should:
1. Identify the target thread (search Gmail by sender name, subject, or use most recent if "them/that")
2. Fetch thread context via `GMAIL_FETCH_MESSAGE_BY_THREAD_ID`
3. Draft reply using Ashley's specified content + business context + correction rules
4. Create Gmail draft via `GMAIL_CREATE_EMAIL_DRAFT`
5. Store in `email_queue` table (status=pending)
6. Send Telegram notification with draft preview + "send | change | skip" buttons
7. **ALWAYS** wait for approval before sending (never auto-send, per Ashley's preference)

### 3b. Update `workspace/AGENTS.md`

Add interactive email patterns to the operating instructions:
- "Reply to X saying Y" → email-master interactive mode
- "Tell them Y" → reply to last-discussed email thread
- "Email [name] about [topic]" → compose new email
- Always show draft for approval before sending (never auto-send)

### 3c. Update `workspace/TOOLS.md`

Add patterns for:
- How to search Gmail for a specific thread by sender name
- How to create a draft reply in an existing thread
- How to compose a new outbound email

### Key files to modify:
- `skills/email-master/email-master/SKILL.md`
- `workspace/AGENTS.md`
- `workspace/TOOLS.md`

---

## Step 4: Verify End-to-End (Deferred: Brain Dump)

Brain dump / goal tracking deferred -- Ashley wants to focus on email + tasks first.

**Smoke test the full loop:**
1. Check Ollama is running: `ollama list`
2. Check recent inbox-watcher alerts in Telegram
3. Verify email-master cron is processing (check logs or email_queue table)
4. Test task creation: confirm `task.sh add` works

---

## Step 5: Commit Everything

Commit all changes:
- Technical fixes (Step 1)
- Any symlink/cron setup scripts if created
- SKILL.md + AGENTS.md + TOOLS.md updates (Step 3)

---

## What We're NOT Building

Per CLAUDE.md's "ASK BEFORE BUILDING" rule:
- No new Railway services
- No new cron jobs (existing ones handle everything)
- No new bash scripts for interactive email (LLM instructions handle this)
- No Notion integration (Supabase tasks table is the source of truth)
- No Telegram inline buttons (text commands are sufficient for now)

The most impactful change is **instructions, not code.** Updating SKILL.md, AGENTS.md, and TOOLS.md teaches the existing LLM gateway how to handle interactive email commands -- no new services needed.

---

## Verification

1. **Ollama alert**: Stop Ollama, trigger email-master, confirm Telegram alert arrives
2. **Interactive email**: Send Max a Telegram message "reply to [recent sender] saying thanks for reaching out, we'd love to chat", confirm draft created and approval prompt appears
3. **Brain dump**: Tell Max "brain dump: [goals]", confirm goals/tasks created in Supabase
4. **Task tracker**: Tell Max "add to task list: update website pricing page", confirm task created
5. **Correction loop**: Edit a draft Max created, verify correction extracted next morning at 8am

---

## Estimated Effort

| Step | Effort | Type |
|------|--------|------|
| 1. Commit fixes | 2 min | Git |
| 2. Verify systems | 10 min | Bash checks |
| 3. Interactive email instructions | 30 min | Identity file updates |
| 4. Smoke test | 10 min | Verification |
| 5. Commit + push | 2 min | Git |
| **Total** | **~55 min** | |
