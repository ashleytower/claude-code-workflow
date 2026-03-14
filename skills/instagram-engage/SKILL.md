---
name: instagram-engage
description: Monitors target Instagram accounts for engaging posts across three campaigns (event leads, managed bar, voice CRM). Uses Instagram API via Rube for post discovery, Claude Haiku scoring, Telegram approval flow, and browser automation for posting comments.
homepage: https://github.com/ashleytower/max-ai-employee
metadata: {"clawdbot":{"emoji":"IG","requires":{"bins":["curl","jq"],"env":["SUPABASE_URL","SUPABASE_SERVICE_KEY","ANTHROPIC_API_KEY","TELEGRAM_BOT_TOKEN","TELEGRAM_CHAT_ID","RUBE_API_KEY"]}}}
requirements:
  - curl
  - jq
---

# Instagram Engagement

Monitors target Instagram accounts for recent posts, scores them with Claude Haiku for engagement opportunity, drafts helpful and genuine comments, sends to Telegram for approval, and posts via browser automation. Same human-in-the-loop pattern as reddit-engage and fb-group-monitor.

## User Context

**Campaigns**: MTL Craft Cocktails (events), Managed Bar Program (B2B), Voice CRM / AI Tools (product-led growth)
**Telegram**: Chat ID 8076125560
**Supabase**: Project clnxmkbqdwtyywmgtnjj
**User ID**: 3ed111ff-c28f-4cda-b987-1afa4f7eb081

## Setup

### 1. Environment Variables

```bash
export ANTHROPIC_API_KEY="your_anthropic_api_key"
export TELEGRAM_BOT_TOKEN="your_bot_token"
export TELEGRAM_CHAT_ID="8076125560"
export SUPABASE_URL="https://clnxmkbqdwtyywmgtnjj.supabase.co"
export SUPABASE_SERVICE_KEY="your_service_role_key"
export RUBE_API_KEY="your_rube_api_key"
```

### 2. Requirements

- Mac node with Chrome browser
- claude-in-chrome MCP extension installed and connected
- Rube API access with Instagram connection configured

### 3. Scheduled Execution

Daily at 12pm Eastern (after Reddit engage at 11am):
```bash
0 12 * * * cd /Users/ashleytower/max-ai-employee && ./skills/instagram-engage/scripts/instagram-engage.sh --campaign all
```

## How It Works

### Phase 1: Discover Instagram Posts

1. Read target accounts and hashtags from `config/targets.json`
2. For each campaign: iterate target accounts, fetch recent posts via Rube Instagram API
3. Normalize results to standard shape (source_id, author, caption, media_url, post_url, etc.)
4. Dedup by source_id (same post appearing in multiple hashtag searches)
5. Filter out already-engaged posts (checks Supabase audit_log for action=instagram_comment)
6. Filter by max_post_age_days (default 14 days)
7. Save raw posts to `~/.max-ai/instagram-engage/ig-posts-{campaign}-{date}.json`

### Phase 2: Score Posts

1. Iterate posts, call Claude Haiku with scoring prompt
2. Score 1-10 for engagement opportunity, extract post_theme
3. Filter: only posts scoring >= 6 proceed to engagement
4. Save scored output to `~/.max-ai/instagram-engage/ig-scored-{campaign}-{date}.json`

### Phase 3: Engage Posts (Human-in-the-Loop)

1. Draft genuine, non-promotional Instagram comments via Claude
2. Send draft to Telegram with "IG COMMENT DRAFT [N]" prefix
3. Ashley replies: OK N / EDIT N <text> / SKIP N
4. Approved comments queued for browser posting via claude-in-chrome
5. All actions logged to Supabase audit_log

## Safety Measures

| Measure | Detail |
|---------|--------|
| Rate limiting | 120s base + 0-60s jitter = 120-180s between comments |
| Daily cap | Max 10 comments per day (configurable via --max-comments) |
| No links | Instagram flags comments with external links |
| No marketing language | Comments are genuine, personal, conversational |
| Human approval | Every comment requires Telegram OK before posting |
| Dedup | Checks audit_log to never re-engage the same post |
| Dry run mode | `--dry-run` flag for testing without writes or API calls |
| Bilingual | Comments match the language of the original post |

## Target Accounts by Campaign

### Campaign 1: Event Leads (MTL Craft Cocktails)
- @mtl_weddings, @mariagesmontreal, @mtl_event_planner, @montrealweddings, @receptionsmtl
- Hashtags: #montrealwedding, #mtlevents, #montrealvenue, #weddingmontreal, #mtlwedding

### Campaign 2: Managed Bar Program (B2B)
- @mtlfoodie, @mtl_food, @tastemontreal, @mtlbarscene, @bfrfreres, @mtl_bartender
- Hashtags: #montrealbar, #mtlcocktails, #montrealfoodie, #cocktailbar, #mtldrinks, #montrealrestaurant

### Campaign 3: Voice CRM / AI Tools
- @solopreneurlife, @freelancecanada, @smallbizcanada, @womeninbizca, @canadianentrepreneur
- Hashtags: #solopreneur, #freelancelife, #smallbusinessowner, #crmtips, #canadiansmallbusiness

## Usage

```bash
# Full daily run (all campaigns)
./skills/instagram-engage/scripts/instagram-engage.sh --campaign all

# Specific campaign
./skills/instagram-engage/scripts/instagram-engage.sh --campaign managed-bar

# Manual mode: engage specific posts or accounts
./skills/instagram-engage/scripts/instagram-engage.sh --posts "https://instagram.com/p/ABC123,@mtlfoodie"

# Manual mode with campaign context for tone matching
./skills/instagram-engage/scripts/instagram-engage.sh --campaign event-leads --posts "https://instagram.com/p/XYZ789"

# Dry run (no API calls or writes)
./skills/instagram-engage/scripts/instagram-engage.sh --campaign all --dry-run

# Limit comments
./skills/instagram-engage/scripts/instagram-engage.sh --campaign all --max-comments 3

# Single test
./skills/instagram-engage/scripts/instagram-engage.sh --campaign managed-bar --max-comments 1
```

## Files

- `SKILL.md` - This documentation
- `scripts/instagram-engage.sh` - Main orchestrator
- `scripts/phases/01-discover.sh` - Instagram post discovery via Rube API
- `scripts/phases/02-score.sh` - Claude Haiku engagement scoring
- `scripts/phases/03-engage.sh` - Draft, approve, post comments
- `config/targets.json` - Target accounts and hashtags by campaign

## Integration with Other Skills

**lead-pipeline**: Shares campaign config and can surface Instagram leads
**reddit-engage**: Runs 1 hour before (11am), same approval UX
**fb-group-monitor**: Runs 2 hours before (10am), same approval UX
**Morning Brief**: Can include Instagram engagement summary
**audit_log**: All comments logged for compliance tracking

## API Usage

Typical daily run consumes:
- Rube API: 5-15 Instagram API calls (per campaign x target accounts)
- Claude API: ~10-25K tokens (Haiku for scoring + comment drafting)
- Supabase: 1-10 writes (audit_log entries)
- Telegram: 1-11 messages (drafts + summary)
