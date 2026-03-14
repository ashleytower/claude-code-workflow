# Lead Gen Fix Team Debrief - 2026-02-07

## Team
3 phases, 16 agents total:
- Phase 1: 4 implementers (sql, supabase, fb, pipeline) + 4 spec reviewers
- Phase 2: 2 implementers (utils-extractor, cleanup-agent)
- Phase 3: 3 final reviewers (build, code, simplifier) + 1 critical-fixer

## What went smoothly
- Phase 1 parallel dispatch: 4 agents on non-overlapping files, zero conflicts
- All 4 spec reviews passed first try
- Build verification: 46/46 checks passed
- Shared utils extraction clean (~285 lines removed)

## What was hard
- [gotcha] SQL migration and code were written by different agents with no shared contract. The lead_scrape_runs table had completely different column names than what write-supabase.sh expected (raw_results_count vs leads_found, etc.)
- [gotcha] UNIQUE(user_id, fingerprint) composite constraint doesn't work with PostgREST on_conflict=fingerprint (single column). Had to change to UNIQUE(fingerprint) alone.
- [gotcha] Final code review caught 3 more criticals AFTER Phase 1 spec reviews passed. The spec reviewers checked what was requested, but didn't cross-reference write-supabase.sh against the ACTUAL SQL migration columns for lead_scrape_runs.

## Key learnings
- [pattern] Always define a data contract BEFORE dispatching parallel agents. We did this for the leads table but missed lead_scrape_runs.
- [pattern] Spec reviewers check "did you do what was asked" but NOT "does it work end-to-end." Final code review is essential for cross-file consistency.
- [pattern] PostgREST on_conflict requires matching unique constraint exactly -- composite uniques need all columns listed.
- [pattern] Process substitution `< <()` is the fix for bash subshell variable loss in while-read loops.
- [pattern] Shared lib with double-source guard `[[ -n "${_LOADED:-}" ]] && return 0` prevents issues.
- [debug] fb-monitor score_posts: bash functions can't modify caller variables. Must echo results to stdout and capture with $().

## Unresolved (deferred, not blocking)
- Raw curl in write-supabase.sh and 04-score-and-alert.sh could use supabase_query() from shared lib
- MAX_GROUPS redundancy in fb-monitor.sh
- SCORING_MODEL defined in 3+ places (drift risk)
- Dead APIFY_*_ACTOR vars in scraper files
- Dead default keyword vars in scraper files
- monitor/all case duplication in fb-monitor.sh (~13 lines)
