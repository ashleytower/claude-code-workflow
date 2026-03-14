### 2026-02-07 - Team Debrief: Max Hardening Sprint

[decision] 4-agent team completed audit and hardening of Max AI Employee in one session.

## What went smoothly
- Dashboard assignment feature (Ashley/Max) -- straightforward, built clean
- SMS bug fixes (4 critical) -- all minimal, targeted changes
- Voice forwarding route implementation -- clean Express route following existing patterns
- Research agent produced actionable competitive analysis

## What was hard
- Vapi phone number is the SAME as Twilio number (+14382557557). This means Vapi imported the Twilio number via trunk. The voice forwarding code may conflict with Vapi's direct connection. Needs manual investigation in Twilio Console.
- Railway CLI not logged in, couldn't verify deployment status programmatically
- No Twilio toolkit in Rube/Composio -- had to note manual steps for webhook config

## Key learnings
- [gotcha] Vapi assistant "Max AI Employee" (ID: 1427681a-7f23-46f9-9714-2f82c4b8c9fb) exists and has handled 10 real calls, but `transfer_to_ashley` tool is NOT attached to it (toolIds is empty)
- [gotcha] ASHLEY_PHONE_NUMBER and VAPI_PHONE_NUMBER env vars need to be set in Railway for voice forwarding to work
- [gotcha] Twilio voice webhook must be pointed to /voice/incoming for the new route to work
- [pattern] OpenClaw (145k stars) is the main competitor but focuses on general-purpose. Max's moat is business automation for solo founders (lead gen, approval flows, telephony)
- [decision] Don't try to out-OpenClaw OpenClaw. Double down on business capabilities.

## What was done
1. Dashboard: Added Assign To (Ashley/Max) in create modal, detail panel, filter bar, card badges
2. Voice: Created /voice/incoming, /voice/mode routes with TwiML and Supabase persistence
3. SMS fixes: Message dedup, SMS length validation, timing-safe API key, auto-approve on Telegram failure
4. Config audit: Verified Vapi assistant exists, found missing env vars and webhook config
5. Research: Full competitive analysis saved to ~/.claude/memory/research/2026-02-07-best-claude-bots.md

## Unresolved
- Need to set ASHLEY_PHONE_NUMBER and VAPI_PHONE_NUMBER in Railway
- Need to verify/set Twilio voice webhook URL in Twilio Console
- Need to attach transfer_to_ashley tool to Vapi Max assistant
- Need to deploy updated code to Railway
- Phone number conflict: Vapi and Twilio sharing same number needs investigation
