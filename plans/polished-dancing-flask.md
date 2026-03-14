# Max AI Employee: Memory Consolidation + Goal-Pursuit Loop

## Context

Max's memory is fragmented across 4 systems (Mem0, Supabase memory table, MEMORY.md, elite-longterm-memory). None auto-capture from conversations. The goal: consolidate to Supabase pgvector (owned, portable, free), build an OpenClaw auto-memory plugin (inspired by Supermemory's hooks), add a goal-pursuit loop so brain dumps become overnight action, and clean up accumulated dead code.

## Phase 1: Cleanup (Remove Dead Weight)

**Why first:** Don't build on a messy foundation.

| Action | Details |
|--------|---------|
| Remove 42 broken symlinks | `~/.openclaw/skills/` has symlinks to non-existent `.agents/` dir |
| Remove 19 stale directories | Third-party marketplace skills not used by Max (auth, cartesia-tts, etc.) |
| Fix inconsistent symlink paths | Some point to `/Users/ashleytower/max-ai-employee/` (old), should be `Documents/GitHub/max-ai-employee/` |
| Unsymlink legacy skills | `email-drafter`, `elite-longterm-memory`, `mem0-memory` |
| Archive dead code | Move `gmail-responder` + `email-drafter` to `skills/_archived/` |
| Delete stale file | `skills/email-master/email-master.skill` (36KB orphan) |
| Update CLAUDE.md | Reflect actual skill count and status |

**Verification:** `ls -la ~/.openclaw/skills/ | wc -l` drops from ~99 to ~40. All cron jobs still fire. `DRY_RUN=true` each active skill.

## Phase 2: Memory Consolidation (Supabase pgvector + OpenClaw Plugin)

### 2.1 Supabase pgvector Setup

Migration: `supabase/migrations/20260214000001_pgvector_memory.sql`

```sql
CREATE EXTENSION IF NOT EXISTS vector;
ALTER TABLE memory ADD COLUMN embedding vector(768);
ALTER TABLE memory ADD COLUMN metadata JSONB DEFAULT '{}';
ALTER TABLE memory ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
CREATE INDEX idx_memory_embedding ON memory USING hnsw (embedding vector_cosine_ops);
```

Plus two RPC functions:
- `match_memories(user_id, embedding, threshold, count)` -- semantic search
- `upsert_memory(user_id, content, embedding, category, importance)` -- dedup-aware insert (>0.92 similarity = update)

### 2.2 Build OpenClaw memory-pgvector Plugin

Location: `plugins/memory-pgvector/`

Follows exact pattern of Supermemory's plugin + OpenClaw's built-in `memory-lancedb`:

```
plugins/memory-pgvector/
  index.ts                # register() -> hooks + tools + CLI
  openclaw.plugin.json    # Config schema
  package.json
  hooks/
    recall.ts             # before_agent_start: embed query -> pgvector search -> inject context
    capture.ts            # agent_end: extract last turn -> embed -> upsert_memory
  lib/
    ollama.ts             # POST localhost:11434/api/embed -> 768-dim vector
    supabase.ts           # REST calls to match_memories + upsert_memory RPCs
  tools/
    search.ts             # memory_search tool (agent can search explicitly)
    store.ts              # memory_store tool (agent can store explicitly)
    forget.ts             # memory_forget tool
```

**Key hooks (from Supermemory, adapted):**
- `api.on("before_agent_start")` -> embed user prompt via Ollama -> `match_memories()` -> return `{ prependContext: "<memory-context>..." }`
- `api.on("agent_end")` -> extract last user+assistant turn -> filter short messages -> embed via Ollama -> `upsert_memory()`

**Embedding model:** `nomic-embed-text:latest` (768 dims, free, local, state-of-art for its size). Already have Ollama installed, just `ollama pull nomic-embed-text:latest`.

**Fallback:** If Ollama not running, skip silently (no paid API fallback for auto-operations).

### 2.3 Add `call_ollama_embed()` to shared/lib/common.sh

For bash scripts that need to store memories directly (corrections, heartbeat).

### 2.4 Mem0 Migration Script

`scripts/migrate-mem0-to-pgvector.sh`: Export Mem0 memories via Rube MCP, embed with Ollama, insert into Supabase. Additive (doesn't delete from Mem0 until verified).

### 2.5 Update Mem0 References

| File | Change |
|------|--------|
| `skills/shared/lib/corrections.sh` | `promote_rule_to_mem0()` -> `promote_rule_to_pgvector()` |
| `skills/email-master/.../process-emails.sh` | Replace `MEM0_PERFORM_SEMANTIC_SEARCH` with Supabase `match_memories` |
| `skills/heartbeat/scripts/draft-dm-replies.sh` | Same replacement |
| `workspace/TOOLS.md` | Update memory tool references |
| `workspace/AGENTS.md` | Update memory search instructions |

### 2.6 Retire Old Memory Skills

Unsymlink + archive: `memory-sync`, `mem0-memory`, `elite-longterm-memory`

**Verification:** `grep -r MEM0_ skills/ --include="*.sh" -l` returns only archived files. Plugin shows in `openclaw plugins list`. Send Max a Telegram message, verify memory context injected in logs.

## Phase 3: Goal-Pursuit Loop

### 3.1 Goals Table

Migration: `supabase/migrations/20260214000002_goals_table.sql`

```sql
CREATE TABLE goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_context(id),
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active','paused','achieved','abandoned')),
  progress_pct INTEGER DEFAULT 0,
  category TEXT DEFAULT 'business',
  target_date TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tasks ADD COLUMN goal_id UUID REFERENCES goals(id) ON DELETE SET NULL;
```

Plus helper functions: `get_goal_progress(goal_id)`, `get_active_goals(user_id)`

### 3.2 Brain Dump Skill

Location: `skills/brain-dump/`

```
skills/brain-dump/
  SKILL.md              # OpenClaw skill definition
  scripts/
    brain-dump.sh       # Freeform text -> goals + tasks (via Ollama/Haiku)
    goal.sh             # CLI: list, get, add, pause, achieve, abandon, decompose
    weekly-goal-review.sh  # Sunday 10am summary cron
```

**brain-dump.sh flow:**
1. Accept freeform text from Telegram
2. Call LLM with decomposition prompt -> JSON `{goals: [{title, tasks: [{title, task_type, priority}]}]}`
3. INSERT goals + tasks into Supabase (tasks linked via `goal_id`)
4. Telegram: "Created X goals with Y tasks. Running tonight."
5. Limits: max 5 goals per dump, max 5 tasks per goal

### 3.3 Heartbeat Integration

Add to `skills/heartbeat/scripts/heartbeat-check.sh`:

- Check 5: Goal Progress -- query `get_active_goals()`, surface stalled goals (0 progress in 24h), near-complete goals (80%+)
- Zero LLM cost (pure SQL)

### 3.4 Nightly Builder Goal-Awareness

Modify `skills/nightly-builder/scripts/nightly-builder.sh`:

- When fetching tasks, include goal context in the task prompt
- After task completion, auto-update goal progress via `get_goal_progress()` RPC
- If all tasks for a goal are done, notify via Telegram: "Goal X achieved!"

### 3.5 Weekly Goal Review Cron

`weekly-goal-review.sh` (Sunday 10am):
- Fetch active goals with progress delta since last week
- Generate summary via Ollama (free)
- Telegram report: goals on track, stalled, recommended next actions
- Register: `openclaw cron add --schedule "0 10 * * 0"`

**Verification:** Brain dump via Telegram creates goals + tasks. Nightly builder picks them up. Heartbeat shows progress. Weekly review fires.

## Phase 4: Code Review + Simplification

Standard pipeline:
1. `@code-reviewer` reviews all changes
2. `@code-simplifier` cleanup pass
3. `@verify-app` full validation
4. Update CLAUDE.md architecture section
5. Commit + PR

## Execution Order & Parallelism

```
Phase 1 (cleanup)              <- Do first, sequential
  |
  +-- Phase 2.1 (pgvector migration) \
  +-- Phase 3.1 (goals migration)     } Can apply together
  |
  +-- Phase 2.2 (plugin build)  \
  +-- Phase 3.2 (brain dump)     } Parallel agent team
  +-- Phase 2.3 (common.sh)    /
  |
  +-- Phase 2.4 (Mem0 migration)      <- After plugin works
  +-- Phase 2.5 (update references)   <- After migration verified
  +-- Phase 3.3-3.5 (integrations)    <- After goals table exists
  |
Phase 4 (review + simplify)           <- Last
```

## Critical Files

| File | Action |
|------|--------|
| `skills/shared/lib/common.sh` | Add `call_ollama_embed()` |
| `skills/shared/lib/corrections.sh` | Replace `promote_rule_to_mem0()` |
| `skills/email-master/.../process-emails.sh` | Replace Mem0 search calls |
| `skills/heartbeat/scripts/heartbeat-check.sh` | Add goal progress check |
| `skills/nightly-builder/scripts/nightly-builder.sh` | Add goal-awareness |
| `plugins/memory-pgvector/` (NEW) | Full OpenClaw memory plugin |
| `skills/brain-dump/` (NEW) | Brain dump + goal management |
| `supabase/migrations/` (NEW x2) | pgvector + goals schema |
| `CLAUDE.md` | Update architecture, skill inventory, data flows |
| `workspace/TOOLS.md` | Update memory references |
| `workspace/AGENTS.md` | Update memory search instructions |

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Ollama not running | Plugin skips silently. Bash fallback to `call_claude_api()` |
| Breaking cron jobs during cleanup | Phase 1 only touches symlinks. Cron refs full script paths. |
| Mem0 data loss | Migration is additive. Mem0 stays read-only until verified. |
| Brain dump task explosion | Max 5 goals x 5 tasks per dump. Nightly builder MAX_TASKS=5. |
| OpenClaw plugin API changes | Follows exact pattern of built-in memory-lancedb extension. |

## Cost Impact

| Before | After |
|--------|-------|
| Mem0 API calls ($) | Supabase pgvector ($0, already paying) |
| No auto-memory | Auto-capture/recall on every conversation ($0, Ollama) |
| No goal tracking | Full goal-pursuit loop ($0, Ollama + Claude Code CLI free) |
| Brain dumps forgotten | Brain dumps -> structured goals -> overnight execution |
