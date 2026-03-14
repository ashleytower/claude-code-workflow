# Team Debrief: email-master skill build
Date: 2026-02-09

## Team Composition
- 3 reference writers (ref-business, ref-sales, ref-tools)
- 2 script writers (script-process, script-corrections)
- 1 code reviewer
- 3 research agents (Chris Do, Hormozi, email frameworks)
- 1 voice/tone explorer
- Lead (me)

## What Went Smoothly
- All 3 reference files written correctly in first pass
- Both scripts passed syntax checks on first write
- Skill packaging validation passed immediately
- Progressive disclosure pattern worked well (SKILL.md 149 lines)
- Team agents worked fully in parallel, no blocking

## What Was Hard
- Code reviewer found 4 major bugs in check-corrections.sh:
  - GMAIL_FETCH_EMAILS doesn't support thread_id as a param (must embed in query string)
  - Fallback logic using message_id as thread_id was wrong
  - NO_REPLY_NEEDED exact match missed whitespace
  - Draft existence check capped at 50 drafts caused false "deleted"
- Had to fix all 4 before shipping

## Key Learnings
[gotcha] GMAIL_FETCH_EMAILS only takes query/max_results/ids_only. Thread filtering goes in the query string: "in:sent thread:$id"
[gotcha] Claude may return NO_REPLY_NEEDED with whitespace. Always trim with xargs before comparison.
[gotcha] Checking draft existence by listing all drafts is fragile. Better: fetch the specific message by ID and check for DRAFT label.
[pattern] Skill builder workflow: init_skill.py -> parallel agent team for files -> code-reviewer -> fix issues -> package_skill.py
[pattern] pyyaml is required for package_skill.py but not installed by default: `pip3 install --break-system-packages pyyaml`

## Research Findings (Persuasion Framework)
- Chris Do: Diagnose before prescribing. High-value questions ("What matters most?") before low-value ("How many people?"). Socratic selling.
- Hormozi: Value equation (dream outcome x likelihood / time x effort). Follow up with value adds, not "checking in". A-C-A for lost leads. Real scarcity only.
- StoryBrand: Client is hero, we are guide. Acknowledge challenge -> show expertise -> clear plan -> paint success.
- Cialdini: Reciprocity (give tips first), social proof (relevant experience), authority (specific numbers not claims), scarcity (real only).
- Voice filter: If it could describe any bartending service, it's tacky. Specific to how we work = us.

## Unresolved
- gmail-responder standalone on Railway still running (needs decision: keep or retire)
- email-master not yet symlinked to ~/.openclaw/skills/
- Cron jobs not yet registered via openclaw cron add
- moltbot.json not yet updated with email-master entry
