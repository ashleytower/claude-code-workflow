# Lead Gen Pipeline Patterns Research - 2026-02-07

## Key Findings

### Supabase Upsert
- [gotcha] PostgREST expects on_conflict as QUERY PARAMETER not header. Header is silently ignored.
- [pattern] Prefer header: `resolution=merge-duplicates,return=representation`
- [pattern] Consider fingerprint as GENERATED ALWAYS AS (md5(source || ':' || source_id)) STORED column
- [pattern] Batch upserts (10-50 leads per call) instead of one-at-a-time loop

### Google Sheets
- [gotcha] appendCells requires numeric sheetId, not tab name. sheetId:0 = first tab always.
- [pattern] values.append is simpler - uses tab name directly: `'Tab Name'!A:L`
- [pattern] Batch rows into single append call instead of per-lead loop

### Claude Scoring
- [pattern] Use tool_use for structured output - guarantees valid JSON, no regex fallback needed
- [pattern] Prompt caching: 90% savings on repeated system prompts after 2 requests
- [pattern] Batch 5-10 leads per API call by including all in one message
- [research] Claude Haiku 4.5 (claude-haiku-4-5-20250625) may be cheaper/better than 3.5 Haiku

### Reddit Monitoring
- [pattern] Snoostorm event-based streaming (real-time vs periodic batch)
- [pattern] Store last-seen post IDs to avoid re-scoring
- [pattern] Multi-subreddit: `sub1+sub2+sub3` syntax reduces API calls
- [gotcha] time_filter: "month" re-processes old content every run

### Facebook Groups
- [pattern] Two-phase session: manual login once, save state, reuse for all runs
- [pattern] Self-healing selectors with AI-assisted repair
- [gotcha] Never automate FB login repeatedly - triggers account locks
- [gotcha] Playwright > Selenium for modern SPAs

### Apify Google Maps
- [pattern] Orchestrator actor splits queries into parallel runs + auto-dedup
- [pattern] Disable histogram/openingHours/peopleAlsoSearch to reduce cost
- [gotcha] Set BOTH maxCrawledPlacesPerSearch AND maxCrawledPlaces as backstop

## Sources
- Apify docs, PostgREST docs, Supabase discussions, GitHub repos (bbilly1/reddit-bot, MasuRii/FBScrapeIdeas, thanh2004nguyen/facebook-group-scraper), Cargo/Clay blog posts, Google Sheets API docs
