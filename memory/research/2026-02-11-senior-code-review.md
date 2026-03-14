# Senior Code Review: MTL CRM + Max AI Employee
## 2026-02-11 -- 7-Agent Parallel Review

### Scope
- **MTL CRM** (`mtl-craft-cocktails-ai`): Voice-first React 19 CRM, Deepgram STT + Claude + Cartesia TTS, Supabase, Vercel
- **Max AI** (`max-ai-employee`): OpenClaw gateway on Railway, 38 bash skills, 16 cron jobs, Mac node execution

### Final Tally
| Reviewer | Criticals | Majors | Minors |
|----------|-----------|--------|--------|
| Agent Architecture | 4 | 7 | 6 |
| Email Systems | 4 | 7 | 8 |
| Voice Pipeline | 4 | 7 | 6 |
| Database/Schema | 3 | 5 | 6 |
| OpenClaw/Max | 3 | 7 | 8 |
| Frontend/UX | 4 | 7 | 7 |
| Security | 3 | 6 | 4 |
| **TOTAL** | **25** | **46** | **45** |

---

### CRITICAL FINDINGS (Top 10 -- Fix First)

1. **Secrets in git history** (Security C1) -- railway-vars-backup.json at commit 79116e7. Rotate ALL keys + git filter-repo purge.
2. **API keys in browser** (Voice C1, Frontend C3) -- Deepgram, Cartesia, Gemini, Google Sheets keys shipped in client JS bundle.
3. **No frontend auth** (Frontend C2) -- Anyone at `/` gets full CRM with all business data.
4. **OAuth CSRF + token exposure** (Security C2) -- No state parameter, refresh token rendered in HTML.
5. **Wildcard CORS on mixologist-chat** (Security C3) -- Any website can trigger Claude API calls.
6. **Shell injection via email** (Email C3) -- Email content in bash variables with active command substitution.
7. **dm_queue open RLS** (DB C2) -- `USING (true)` allows anyone with anon key to read/write all DM data.
8. **SalesAgent.extractSalesData stub** (Agent C4) -- Returns empty data; all proposals use 50-guest defaults.
9. **No Deepgram reconnection** (Voice C2) -- WebSocket drops = silent death, user sees "Listening..." with nothing happening.
10. **Utterance dropping** (Voice C3) -- isProcessing gate silently drops user speech during processing.

### MAJOR THEMES

**Security (across both codebases):**
- Service key used everywhere, RLS bypassed in practice
- Unauthenticated cron/public endpoints
- Prompt injection via email -> correction rules -> future drafts
- Gateway token leaked in URL redirect
- Nightly builder has an unused function with unrestricted Bash

**Reliability:**
- No streaming in voice pipeline (2-5s dead silence)
- No timeouts on WorkflowCoordinator or curl calls in common.sh
- Race conditions: concurrent cron runs, nightly builder lock TOCTOU
- Schema drift: email_queue columns in code don't match migration
- No auto-restart on gateway crash

**Architecture Debt:**
- App.tsx is 1,566-line god component
- VoiceToolContext is 343-line god interface (120+ optional methods)
- Two incompatible ThinkingProtocol base classes
- Two parallel tool-loading architectures (direct vs meta-tool)
- Intent detection regex has severe false positives
- moltbot.json severely out of sync with reality

**Test Coverage Gaps:**
- Max AI email-master: 0 tests (1,179 lines of bash)
- Voice core pipeline: 0 tests
- Max AI has no test infrastructure at all

### PRIORITY REMEDIATION ORDER

**Immediate (security):**
1. Rotate all leaked secrets + git filter-repo purge
2. Fix wildcard CORS on mixologist-chat (1 line)
3. Add CSRF state to OAuth flow
4. Move API keys to server-side proxies

**Short-term (reliability):**
5. Add UNIQUE constraint on email_queue.gmail_message_id
6. Fix dm_queue RLS policies
7. Add Deepgram reconnection logic
8. Implement voice streaming (STT -> LLM -> TTS)
9. Add auth to frontend

**Medium-term (architecture):**
10. Split App.tsx into domain modules
11. Replace intent detection regex with LLM classification
12. Implement SalesAgent.extractSalesData
13. Unify email filter lists
14. Add test suite for Max AI bash scripts
