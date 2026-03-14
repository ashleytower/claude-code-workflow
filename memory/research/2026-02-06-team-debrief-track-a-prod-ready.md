### 2026-02-06 - Track A: Production Readiness Team Debrief

## What went smoothly
- All 5 service migrations completed cleanly in parallel (3 agents)
- Voice pipeline cleanup was straightforward -- just removing dead env checks
- Code reviewer found the dual proxy pattern immediately
- Code simplifier unified all services to shared `callClaudeProxy()` in one pass

## What was hard
- [gotcha] `claudeProxy.ts` was created by Agent A without `toolChoice` support. Agent B needed `toolChoice` for validatorAgent and used `apiFetch` directly. The simplifier fixed this by adding `toolChoice` to the shared utility.
- [gotcha] validatorAgent used model `claude-3-haiku-20240307` which wasn't in the proxy ALLOWED_MODELS list. Agent B caught this and updated to `claude-haiku-4-5-20251001`.
- [gotcha] `claudeVoicePipelineBehaviors.test.ts` was failing because it still set `VITE_ELEVENLABS_API_KEY` instead of `VITE_CARTESIA_API_KEY`. Agent C fixed this during cleanup.

## Key learnings
- [pattern] Proxy migration pattern: replace `new Anthropic({ apiKey })` + `anthropic.messages.create()` with `callClaudeProxy({ messages, model, maxTokens })`. Response format is identical.
- [pattern] `apiFetch` vs `callClaudeProxy`: always use the typed shared utility. It handles error codes (401/429), typing, and centralizes the endpoint URL.
- [decision] `@anthropic-ai/sdk` only imported in `services/skills/metaToolSchema.ts` (type-only) and `api/claude.js` (server-side). Could be excluded from browser bundle with `import type`.

## Security verification
- 0 instances of `dangerouslyAllowBrowser` in services/
- 0 instances of `new Anthropic(` in services/
- 0 functional uses of `VITE_ANTHROPIC_API_KEY` in services/ (only a comment)
- All Claude calls route through `/api/claude` server-side proxy

## Files changed (20 files)
Services: claudeProxy.ts (new), episodeSummaryService.ts, memoryFilterService.ts, lossAnalysisService.ts, agents/validatorAgent.ts, agents/multiAgentValidation.ts, claudeVoicePipeline.ts
Components: VoiceAssistant.tsx
API: api/claude.js (toolChoice support)
Config: .env.example
Tests: 10 test files (5 new + 5 updated)

## Test results
- 1525/1528 tests pass (3 pre-existing CalendarWidget locale failures)
- 26 new proxy-specific tests all green
- Build clean, no type errors

## Unresolved (from Phase 1)
- ~~`claudeService.ts` has a local `callClaudeProxy` that duplicates the shared utility~~ RESOLVED in Phase 2
- ~~`@anthropic-ai/sdk` could use `import type` in metaToolSchema.ts~~ RESOLVED in Phase 2

---

### Phase 2: Agent Wiring + Follow-up Fixes (track-a-full team)

## What went smoothly
- All 3 agents completed their tasks independently without conflicts
- Agent B (workflowCoordinator + salesAgent): 30 tests, clean handler/endpoint separation
- Agent C (emailAgent + validatorAgent gating): 12 tests, safe fallback pattern on validator errors
- Agent A (reinforce/decay wiring + cleanup): 5+5 tests, deduplication + import type fix
- Code simplifier caught `catch (error: any)` pattern and standardized to `catch (error: unknown)` with type guards

## What was hard
- [gotcha] `storeClientCorrection` needed a keyword overlap heuristic (>0.2 threshold) to detect whether a correction aligns with or contradicts an existing behavior. Simple string matching would not work because correction summaries use different phrasing than stored behavior text.
- [gotcha] `detectContradiction` uses an opposites list (formal/casual, short/long, etc.) which is a reasonable heuristic but limited. Future improvement: use Claude to classify alignment/contradiction.
- [gotcha] In-memory `WorkflowCoordinator` state is lost between Vercel serverless cold starts. Not a blocker -- coordinator is designed for demo/staging. Production will need Supabase persistence.

## Key learnings
- [pattern] Handler/endpoint separation: API files (`api/agents/*.js`) handle HTTP (auth, CORS, body parsing) and delegate to handler modules (`services/agents/*Handler.ts`) for business logic. Handler returns `{ status, data?, error? }`.
- [pattern] Feature flag gating: `ENABLE_EMAIL_AGENT=true` env var gates the emailAgent in the email webhook. Dynamic `await import()` ensures the module isn't loaded when disabled.
- [pattern] Safe fallback in validators: If `validateBeforeSend` throws, the response is flagged for human review rather than auto-sending. Critical safety measure.
- [decision] `catch (error: unknown)` with `error instanceof Error ? error.message : String(error)` is the standard error handling pattern for this codebase.

## Files changed (12 files)
New handlers: workflowTriggerHandler.ts, qualifyLeadHandler.ts, emailAgentWiring.ts
New API endpoints: api/agents/workflow.js, api/agents/qualify-lead.js, api/agents/email-response.js
Modified: claudeService.ts (dedup), draftLearningService.ts (reinforce/decay), metaToolSchema.ts (import type), api/webhook/email.js (emailAgent integration)
Tests: agentWiring.test.ts (30), emailAgentWiring.test.ts (12), reinforceDecayWiring.test.ts (5), draftLearningStoreClientCorrection.test.ts (updated)

## Test results
- 1572/1575 tests pass (3 pre-existing CalendarWidget locale failures)
- 52 new tests all green
- Build clean, no type errors

## Unresolved
- In-memory WorkflowCoordinator state on serverless -- needs Supabase persistence for production
- `detectContradiction` heuristic is keyword-based -- could be improved with Claude classification
- `reinforceBehavior`/`decayBehavior` fire-and-forget tests use `setTimeout(200ms)` waits -- fragile on slow CI
