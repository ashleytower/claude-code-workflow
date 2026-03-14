# Team Debrief: Lead Generation Pipeline Build - 2026-02-07

## Team Composition
- **team-lead** (me): Coordinated team, created Google Sheet via Rube, updated moltbot.json, fixed model typo
- **db-agent**: Created Supabase migration
- **pipeline-agent**: Built lead-pipeline skill (11 files)
- **fb-monitor-agent**: Built fb-group-monitor skill (8 files)
- **code-reviewer**: Reviewed all generated code

## What Went Smoothly
- Supabase migration (task 1) completed fastest - clean schema, matched existing patterns
- Google Sheet creation via Rube worked first try - 3 tabs with headers and frozen rows
- All 3 build agents ran in parallel effectively, no file conflicts
- campaigns.json and keywords.json comprehensive with all research keywords

## What Was Hard
- Agent coordination timing: had to poll file system to track progress since task list updates were delayed
- FB monitor agent took longest due to large keywords.json file

## Key Learnings
- [pattern] Model ID for Haiku is `claude-3-5-haiku-20251022` (2025 not 2024) - fb-monitor had this wrong initially
- [config] Google Sheet "MTL Craft - Lead Pipeline" ID: `1G3tGOSQ4sVEdE8ibzMkrgXwGbLnIvR--BQ_463-svPw`
- [config] Tab sheetIds: CRM=0, Bars=1879904038, Events=2055973834
- [pattern] Rube GOOGLESHEETS_CREATE_GOOGLE_SHEET1 creates with "Sheet1" default, must rename via UPDATE_SHEET_PROPERTIES
- [pattern] GOOGLESHEETS_ADD_SHEET returns sheetId at data.replies[0].addSheet.properties.sheetId

## Files Created (22 total)
1. `supabase/migrations/20260207000001_lead_generation.sql`
2. `skills/lead-pipeline/SKILL.md`
3. `skills/lead-pipeline/scripts/lead-pipeline.sh`
4. `skills/lead-pipeline/scripts/scrapers/google-maps-discover.sh`
5. `skills/lead-pipeline/scripts/scrapers/google-maps-reviews.sh`
6. `skills/lead-pipeline/scripts/scrapers/review-sites.sh`
7. `skills/lead-pipeline/scripts/scrapers/reddit-search.sh`
8. `skills/lead-pipeline/scripts/analyzers/score-leads.sh`
9. `skills/lead-pipeline/scripts/outputs/write-supabase.sh`
10. `skills/lead-pipeline/scripts/outputs/write-sheets.sh`
11. `skills/lead-pipeline/scripts/outputs/send-alerts.sh`
12. `skills/lead-pipeline/config/campaigns.json`
13. `skills/fb-group-monitor/SKILL.md`
14. `skills/fb-group-monitor/scripts/fb-monitor.sh`
15. `skills/fb-group-monitor/scripts/phases/01-discover-groups.sh`
16. `skills/fb-group-monitor/scripts/phases/02-join-groups.sh`
17. `skills/fb-group-monitor/scripts/phases/03-monitor-posts.sh`
18. `skills/fb-group-monitor/scripts/phases/04-score-and-alert.sh`
19. `skills/fb-group-monitor/config/groups.json`
20. `skills/fb-group-monitor/config/keywords.json`

## Files Modified (1)
21. `moltbot.json` - Added 2 skill entries + 5 scheduled jobs

## Unresolved
- Google Sheet conditional formatting (red=HOT, orange=WARM) not applied yet - needs Rube batchUpdate with formatting requests
- Apify account setup needed before first live run
- FB group discovery/join phases need manual execution via claude-in-chrome
- LEAD_SHEET_ID env var needs to be set in deployment environment
