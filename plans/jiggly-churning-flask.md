# Instagram Engage Skill

## Context

Ashley wants to comment on Instagram posts for lead generation, same pattern as the working reddit-engage skill. Two modes: auto-discover (browse configured target accounts) and manual (user provides specific post URLs or @usernames). Instagram API is connected via Rube as @mtl_craftcocktails (Business account).

## File Structure

```
~/.claude/skills/instagram-engage/
├── SKILL.md
├── config/
│   └── targets.json            # Target accounts per campaign
└── scripts/
    ├── instagram-engage.sh     # Main orchestrator
    └── phases/
        ├── 01-discover.sh      # Fetch posts from target accounts or manual URLs
        ├── 02-score.sh         # Claude Haiku engagement-opportunity scoring (1-10)
        └── 03-engage.sh        # Draft comment, Telegram approve (IG prefix), post via API
```

Also modify: `~/.claude/skills/shared/lib/common.sh` - add "instagram" branch to `execute_browser_comments`.

## Config: targets.json

Same 3-campaign structure as reddit-engage. Per campaign:
- `target_accounts`: Instagram usernames to monitor (Business/Creator accounts)
- `hashtags`: For future hashtag search (stored for reference)
- `posts_per_account`: How many recent posts to fetch (default 5)
- `max_post_age_days`: Skip older posts (default 14)
- `notes`: Campaign-specific tone guidance

Campaigns: event-leads (wedding/venue accounts), managed-bar (MTL food/bar scene), voice-crm (solopreneur accounts).

## Phase 1: Discover (`01-discover.sh`)

**Auto mode** (`--campaign all`):
1. For each target account: call Rube `INSTAGRAM_GET_IG_USER_MEDIA` to get recent posts
2. Filter by age (max_post_age_days)
3. Normalize to standard shape (source_id, author, caption, post_url, media_type, etc.)
4. Dedup by source_id
5. Filter already-engaged via Supabase audit_log (action=instagram_comment)
6. Save to `~/.max-ai/instagram-engage/ig-posts-{campaign}-{date}.json`

**Manual mode** (`--posts "url1,@username"`):
- URLs: extract shortcode, resolve to media ID via API or browser
- @usernames: fetch recent posts like auto mode
- Default campaign = "manual" unless --campaign also specified

## Phase 2: Score (`02-score.sh`)

- Claude Haiku scores 1-10 for **engagement opportunity** (not buyer intent)
- Prompt evaluates: does caption invite conversation, is content relevant to our expertise, is post getting engagement, would comment feel natural
- Campaign-specific scoring context
- Threshold: >= 6 proceeds to engagement
- Save scored output

## Phase 3: Engage (`03-engage.sh`)

**Draft comments:**
- Max 300 chars (Instagram API limit), aim 100-200
- 1-3 sentences, warm and visual-reactive
- Strip em/en dashes (AI tells)
- No links, no "DM me", no marketing language
- Campaign-specific voice (event lover / cocktail nerd / fellow solopreneur)

**Telegram approval (IG prefix):**
- `IG OK N` - post as-is
- `IG EDIT N <text>` - post edited version
- `IG SKIP N` - don't post

**Posting - dual path:**
1. API first: Rube `INSTAGRAM_POST_IG_MEDIA_COMMENTS` (works for Business/Creator posts)
2. Browser fallback: queue for claude-in-chrome (personal accounts or API failures)

**Audit logging:** Supabase audit_log, action=instagram_comment, same structure as reddit

## Orchestrator: instagram-engage.sh

```
Arguments:
  --campaign <event-leads|managed-bar|voice-crm|all>  (default: all)
  --posts <url1,@user2>                               (manual mode)
  --max-comments <N>                                   (default: 10)
  --dry-run                                            (no API calls)
  --help
```

Flow: source common.sh, cron_lock, parse args, check env, source phases, run discover -> score -> engage.

## Safety

| Parameter | Value |
|-----------|-------|
| Daily comment cap | 10 (more conservative than Reddit's 15) |
| Delay between comments | 120s base + 0-60s jitter |
| Approval timeout | 3600s (1 hour) |
| Max comment length | 300 chars (hard enforced) |
| Max hashtags | 4 per comment |
| Em dash stripping | Always (post-processing) |
| Human approval | Required for every comment |
| Dedup | Supabase audit_log check |
| Cron lock | Prevents concurrent runs |

## Implementation Order

1. Create directory structure
2. Write `config/targets.json` (3 campaigns with Montreal-relevant accounts)
3. Write `scripts/instagram-engage.sh` (adapt from reddit-engage.sh)
4. Write `scripts/phases/01-discover.sh` (Rube Instagram API discovery)
5. Write `scripts/phases/02-score.sh` (adapt scoring prompt for engagement opportunity)
6. Write `scripts/phases/03-engage.sh` (draft + approve + post with API/browser dual path)
7. Update `shared/lib/common.sh` (add instagram platform to execute_browser_comments)
8. Write `SKILL.md`
9. Dry-run test both modes
10. Live test with 1 comment

## Verification

1. `jq '.' config/targets.json` - config parses
2. `instagram-engage.sh --campaign all --dry-run` - full pipeline, no API calls
3. `instagram-engage.sh --posts "@mtlfoodie" --dry-run` - manual mode
4. `instagram-engage.sh --campaign managed-bar --max-comments 1` - real single comment test
5. Verify Telegram IG OK/EDIT/SKIP prefix works
6. Verify audit_log entries in Supabase
7. Verify no comment exceeds 300 chars or contains em dashes

## Key Files to Reference

- `~/.claude/skills/reddit-engage/scripts/reddit-engage.sh` - primary template
- `~/.claude/skills/reddit-engage/scripts/phases/03-engage.sh` - comment drafting + approval pattern
- `~/.claude/skills/reddit-engage/scripts/phases/01-monitor.sh` - API discovery + dedup pattern
- `~/.claude/skills/reddit-engage/config/subreddits.json` - config schema reference
- `~/.claude/skills/shared/lib/common.sh` - shared utilities (needs instagram branch added)
