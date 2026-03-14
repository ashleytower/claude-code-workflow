# Team Debrief: instagram-engage skill implementation
Date: 2026-02-17

## What went smoothly
- Config, orchestrator, and SKILL.md adapted cleanly from reddit-engage patterns
- Phase scripts (discover, score, engage) mapped well to Instagram equivalents
- Two-agent parallelization worked -- all 7 tasks completed in ~3 minutes

## What was hard
- Field name consistency: orchestrator copied `intent_score` from reddit-engage instead of using `engagement_score`. Caught in code review.
- Dead code: discover phase included an internal manual-mode check that the orchestrator bypasses entirely. Had to remove post-review.
- Scoring model docs vs reality: SKILL.md and comments say "Claude Haiku" but code calls `call_ollama` (tries local Llama 3.2 first, falls back to Claude). This is inherited from reddit-engage -- the `SCORING_MODEL` variable is exported but never consumed by `call_ollama`. Pre-existing pattern debt.

## Key learnings
- [gotcha] When adapting reddit-engage to a new platform, the `intent_score` field name leaks through comments and sort calls. Search-and-replace all instances.
- [gotcha] The `call_ollama` function in common.sh hardcodes `llama3.2` and does not use the `SCORING_MODEL` env var. The variable is dead code across all engage skills.
- [pattern] Instagram engagement scoring uses `engagement_score` + `hook` fields (vs Reddit's `intent_score` + `pain_point`). This is intentional -- Instagram is about engagement opportunity, not buyer intent.
- [pattern] Instagram dual-post path (API first via Rube, browser fallback) is unique to this skill. Reddit only uses browser posting.
- [decision] Audit log `details` shape differs between platforms (Instagram has `method` + `account`, Reddit has `subreddit`). Queries must be platform-aware.

## Unresolved
- Cross-skill Telegram message consumption: running reddit-engage and instagram-engage simultaneously could consume each other's approval messages (both advance the offset for non-matching messages from the correct chat). Not blocking but worth noting for future scheduling.
- `SCORING_MODEL` env var is exported but unused by `call_ollama` -- affects all engage skills, not just instagram.
