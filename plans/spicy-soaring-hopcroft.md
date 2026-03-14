# Plan: Make mirror-pipeline Usable from Claude Code

## Context

mirror-pipeline has 3 working compositions (BookkeepingDemo, InventoryDemo, CrmDemo), a render script (`scripts/render-lead.ts`), and 92 passing tests. But using it requires navigating to the project directory, hand-crafting a props JSON file, running the render script, and manually finding the output file. The user wants a streamlined way to use it from any Claude Code session, with Supabase Storage for output retrieval.

There's also a bug: `render-lead.ts` line 29 still maps `crm` to `BookkeepingDemo` instead of `CrmDemo`.

## Changes

### 1. Fix CrmDemo mapping in render-lead.ts
- **File**: `scripts/render-lead.ts:29`
- Change `crm: 'BookkeepingDemo'` to `crm: 'CrmDemo'`
- One-line fix.

### 2. Add Supabase Storage upload to render pipeline
- **Install**: `@supabase/supabase-js` via npm
- **New file**: `src/lib/storage/upload.ts`
  - `uploadVideo(filePath, leadSlug, format)` - uploads rendered MP4 to Supabase Storage bucket `mirror-videos`
  - Returns public URL
  - Uses `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` env vars (already in user's environment from other projects)
- **Modify**: `scripts/render-lead.ts`
  - After successful render, call `uploadVideo()` for each output file
  - Print the Supabase public URL
  - Add `--no-upload` flag to skip upload (for local-only use)
- **New file**: `tests/lib/storage.test.ts`
  - Test upload function with mocked Supabase client
  - Test error handling (missing env vars, upload failure)

### 3. Create Claude Code skill for one-command usage
- **New file**: `~/.claude/skills/mirror-pipeline.md`
- Skill name: `mirror-pipeline` (invoked as `/mirror-pipeline`)
- What the skill does:
  1. Takes lead info as arguments (name, pain quote, segment, current tool)
  2. Writes a props JSON file to `leads/props/{slug}.json`
  3. Runs `npm run pipeline` from the project directory
  4. Reports back the Supabase public URL(s)
- The skill runs commands against `/Users/ashleytower/Documents/GitHub/mirror-pipeline` regardless of current working directory

### 4. Add env vars to CLAUDE.md
- **File**: `CLAUDE.md` (project)
- Add `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to Environment Variables section

## Files to Modify
1. `scripts/render-lead.ts` - fix CrmDemo mapping + add Supabase upload
2. `CLAUDE.md` - add Supabase env vars

## Files to Create
1. `src/lib/storage/upload.ts` - Supabase Storage upload function
2. `tests/lib/storage.test.ts` - upload tests (TDD)
3. `~/.claude/skills/mirror-pipeline.md` - Claude Code skill

## Verification
1. `npm run ci` passes (typecheck, test, lint, build)
2. Test the skill by running: `/mirror-pipeline Sarah "entering receipts every Sunday" bookkeeping HoneyBook`
3. Verify the rendered video appears in Supabase Storage
4. Verify the public URL is accessible
