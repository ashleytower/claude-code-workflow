### 2026-02-18 - Migration Hardening Team Debrief

**Team:** migration-hardening (5 agents + lead)

#### What Went Smoothly
- Security audit found real issues (UUID validation gap, payload size handling)
- Edge case testing confirmed Twilio signature validation works correctly
- Context7 docs verification confirmed cloudflared config patterns are correct
- E2E verification passed all 9 endpoint groups on first run after fixes

#### What Was Hard
- [gotcha] UUID validation needed on BOTH the Express middleware (web routes) AND the Telegram callback handler (handleCallbackQuery). The callback path bypasses Express route middleware entirely since it enters through POST / webhook.
- [gotcha] Reminder scheduler interval needs explicit cleanup on shutdown. Without it, the 60s interval fires during graceful shutdown and logs Supabase errors.
- [pattern] dm_queue table doesn't exist in Supabase. This is pre-existing (Instagram DM approval feature not fully set up), not a migration regression. Any agent testing DM routes will see PGRST205 errors.

#### Key Learnings
- [pattern] Cloudflare Tunnel provides WAF/DDoS/rate-limiting for free. No need for helmet or express-rate-limit when behind cloudflared.
- [pattern] Auth-gated routes (messages, simulate, reminders) use validateApiKey() middleware -- correctly return 401 without API key.
- [decision] Only /messages/search and /simulate are NOT exposed through cloudflared ingress rules. This is intentional security (dev/internal endpoints only accessible on localhost).

#### Unresolved
- dm_queue Supabase table needs to be created if Instagram DM approval is to work
- Vapi toolCalls format: the route expects `toolCallList` (Vapi's actual format), test agent sent `toolCalls` and got 400. This is correct behavior but could confuse future testers.
