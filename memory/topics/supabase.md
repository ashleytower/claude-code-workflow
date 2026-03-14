# Supabase Learnings

## Notes

### 2026-02-06 - Seeded from existing skills
[pattern] See ~/.claude/skills/supabase-google-oauth.md for OAuth setup. Notes below capture quick gotchas not in the skill file.

### 2026-02-08 - Tasks table schema bugs fixed
[gotcha] The tasks table had `status CHECK ('done')` but task.sh and nightly-builder sent `'completed'`. Migration `20260208000001` standardizes on `completed`. Also added `task_type`, `result`, `repo` columns needed by nightly-builder parallel pipeline.

### 2026-02-08 - Seed data was completely wrong
[gotcha] seed.sql had wrong UUID (`550e8400...` instead of `3ed111ff...`), wrong business name ("Tower Consulting"), wrong city ("New York"), wrong timezone, and only 4 of 11 scheduled jobs. Full rewrite done. Always use `3ed111ff-c28f-4cda-b987-1afa4f7eb081` as the user_id.

### 2026-02-08 - Mem0 user_id must be "ashley"
[gotcha] 99 memories exist under user_id `ashley` in Mem0. The mem0-memory skill defaulted to `max`, causing SMS and email drafter to find nothing. Fixed across 7 files. Always use `ashley` for Mem0 user_id.

### 2026-02-08 - draft_corrections table + correction pipeline
[pattern] New `draft_corrections` table (migration `20260209000001`) stores edit/reject feedback across SMS, email, Reddit, Facebook, Instagram DM. Has full-text search via `search_vector` tsvector column. Correction rules extracted via Claude Haiku and promoted to Mem0 with `[DRAFT CORRECTION RULE]` prefix. Mem0 ADD tool argument key is `memory` (not `text`). Supabase column is `source_record_id` (not `source_id`), `rule_category` (not `category`).

### 2026-02-08 - Bash shared lib path gotcha
[gotcha] From `skills/*/scripts/phases/` to `skills/shared/lib/`, use `../../../shared/lib` (3 levels up), NOT `../../../../shared/lib` (4 levels). The `phases/` directory is 3 levels deep inside `skills/`.

### 2026-02-12 - Events table insert schema
[gotcha] The `events` table requires top-level columns (id, client_name, event_date, status) PLUS the data JSONB column. Inserting only `{ data: eventData }` fails silently with a Supabase error because `id text primary key` has no default generator. Correct pattern from supabaseService.ts:
```js
.upsert({
    id: normalizedEvent.id,
    client_name: normalizedEvent.clientName,
    event_date: normalizedDate,
    status: normalizedEvent.status || 'Inquiry',
    data: { ...normalizedEvent, eventDate: normalizedDate }
})
```
Event IDs use `event-${Date.now()}` convention. Status values: 'Inquiry', 'Confirmed', etc. Migration 007 adds `lead_status` column with CHECK constraint ('new_inquiry', 'quote_sent', etc.) — this is separate from the `status` column.

### 2026-02-15 - draft_corrections.promoted_to_mem0 is a legacy column name
[gotcha] The `draft_corrections` table has a boolean column `promoted_to_mem0`. This column now tracks promotion to pgvector memory (not Mem0), but the column name was never renamed during the Mem0-to-pgvector migration. Renaming would require updating corrections.sh (`promote_rule_to_pgvector()`) and the tools-reference.md schema docs. Documented here rather than changing the DB schema -- the column works fine, just the name is outdated.
