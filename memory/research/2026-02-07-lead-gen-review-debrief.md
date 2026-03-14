# Lead Gen Pipeline Review Debrief - 2026-02-07

## Team
3 agents (code-reviewer, build-verifier, code-simplifier) ran in parallel.

## What went smoothly
- All shell scripts pass `bash -n` syntax checks
- File permissions, shebangs, paths, JSON configs all correct
- No credential leaks, no MTL Craft Cocktails cross-contamination
- fb-group-monitor has solid dry-run coverage

## What was hard / broke
- SQL migration and shell code are completely out of sync (5 CRITICAL issues)
- Column names, table names, CHECK constraints all mismatch
- FB monitor `score_posts` result never propagated to caller (functional bug)
- lead-pipeline has no --dry-run mode at all

## Key learnings
- [gotcha] SQL migration creates `lead_scrape_runs` but code uses `scrape_runs` -- 404 at runtime
- [gotcha] `leads` table columns in SQL don't match what code inserts (name vs business_name, metadata vs raw_data, etc.)
- [gotcha] CHECK constraint on `source` column is too restrictive -- doesn't allow `google-maps-reviews`, `review-sites`, `reddit-comment`
- [gotcha] FB monitor scored data lost because bash functions can't modify caller's variables by assignment
- [gotcha] write-supabase.sh uses non-standard `on_conflict` header instead of PostgREST query parameter
- [pattern] fb-monitor's 3-tier md5 fallback (md5sum -> md5 -> openssl md5) is the right portable pattern
- [pattern] fb-monitor's `call_claude_api` with model parameter and curl --max-time is better than lead-pipeline's version

## Unresolved
- All 5 CRITICAL schema mismatches need fixing before first run
- --refresh-venues flag referenced in moltbot.json but not implemented
- audit_log table referenced by engage-posts but not in this migration
- Hardcoded sheetId:0 may write all campaigns to same Google Sheets tab
