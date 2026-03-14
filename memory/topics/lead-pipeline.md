# Lead Pipeline

### 2026-02-07 - DRY_RUN stdout/stderr gotchas
[gotcha] `log()` in common.sh used `tee` which writes to stdout. Any bash function captured via `$()` (like `result=$(run_campaign ...)`) would include log messages in the return value, corrupting JSON data. Fix: `log()` must write to stderr + file: `echo "..." | tee -a "$LOG_FILE" >&2`. This matches how `error()` already works.

[gotcha] DRY_RUN guards in scrapers must be placed BEFORE any `log()` calls in the function, otherwise the log message leaks to stdout even in dry-run mode.

[gotcha] `for query in $queries` word-splits multi-word search queries like "cocktail bar Montreal" into separate words. Should use `while IFS= read -r query` instead. Pre-existing issue in lead-pipeline.sh run_campaign().

[pattern] Standard dry-run guard for scraper functions:
```bash
if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log "[DRY RUN] Would call Rube API for <scraper>: $param" >&2
    echo "[]"
    return 0
fi
```

[gotcha] PostgREST response format varies: single POST returns `[{...}]` (array), but dry-run mock returns `{"id":"dry-run"}` (object). ID extraction must check both `.id` and `.[0].id`.

[gotcha] Railway env var is `SUPABASE_SERVICE_ROLE_KEY` but scripts expect `SUPABASE_SERVICE_KEY`. Must map when setting up env.

### 2026-02-07 - Architecture notes
[pattern] Bash subshell variable loss: piped `while read` loops run in subshells, losing variable changes. Fix: process substitution `< <(echo "$data" | jq -c '.[]')`.
[pattern] Bash functions can't modify caller variables. Must echo to stdout and capture with `$()`.
[pattern] Shared lib with double-source guard: `[[ -n "${_COMMON_SH_LOADED:-}" ]] && return 0`.
