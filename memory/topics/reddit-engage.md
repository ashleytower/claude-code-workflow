# Reddit Engage - Notes

### 2026-02-16 - AI writing tells to always strip
[gotcha] Always remove em dashes, en dashes, and non-breaking hyphens from AI-drafted Reddit comments. Replace with commas or regular hyphens. These are dead giveaways for AI-generated text. Also keep comments to 2-3 sentences max, casual tone, personal experience style. Ashley's preferred voice: "Oh man, I know the feeling. We tried X and it worked." Not preachy advice columns.

### 2026-02-16 - Telegram bot blocked
[debug] Rube-connected Telegram bot (7598474421) is blocked by Ashley's account. Cannot send automated alerts until unblocked. Workaround: present drafts directly in Claude Code session.

### 2026-02-16 - First Reddit monitor run
[pattern] Searched 76 posts across 12 subreddits, 3 campaigns. 5 engagement-worthy posts (score >= 5). Best lead was 9/10 bar layout post in r/bartenders. Montreal-specific subreddits (r/montreal, r/MontrealFood) had no bar/event buyer intent posts this run. General industry subreddits produced better leads.

### 2026-02-16 - Posted comments, need reply monitoring
[pattern] Posted 5 comments as u/Quirky-Potential93. Comment IDs to monitor for replies:
- t1_o5qnwmc (r/bartenders, post 1r2cetm) - bar layout, 9/10
- t1_o5qnwmh (r/Restaurant101, post 1r5rnjv) - slow season, 6/10
- t1_o5qnwmo (r/Entrepreneurs, post 1qzy9my) - empty tuesdays, 6/10
- t1_o5qnwmf (r/shopify, post 1r61gm5) - gorgias pricing, 6/10
- t1_o5qnwoe (r/WhichCRM, post 1r626qb) - best CRMs, 5/10
Use REDDIT_RETRIEVE_POST_COMMENTS with article ID to check for replies to these comments.

### 2026-02-16 - Google Sheet for lead tracking created
[config] Reddit & FB Lead Tracker: https://docs.google.com/spreadsheets/d/18JCSzCpUznN3PKba8HK9_bswz-S3vgwtCs4H56sRdBQ/edit
Spreadsheet ID: 18JCSzCpUznN3PKba8HK9_bswz-S3vgwtCs4H56sRdBQ
Added LEAD_SHEET_ID to max-ai-employee/.env
Columns: Date, Campaign, Platform, Subreddit/Group, Post Title, Post URL, Intent Score, Comment ID, Comment Text, Replies, Status, Notes
Connected as ash.cocktails@gmail.com via Rube Google Sheets toolkit.

### 2026-02-16 - Morning reply check procedure
[pattern] To check replies on posted comments:
1. Use RUBE_MULTI_EXECUTE_TOOL with REDDIT_RETRIEVE_POST_COMMENTS for each article ID
2. Parse comment trees looking for parent_id matching our comment IDs (t1_ prefix)
3. Update Google Sheet "Replies" column with count
4. If reply has buyer intent, draft a follow-up and alert via Telegram
Post IDs to check: 1r2cetm, 1r5rnjv, 1qzy9my, 1r61gm5, 1r626qb
Add to morning brief or run "check Reddit replies" in any Claude Code session.
