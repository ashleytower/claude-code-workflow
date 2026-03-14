# Alex Finn OpenClaw Research
### 2026-02-18 - Comprehensive findings from YouTube and web

[research] Compiled from multiple web searches, video transcripts (Recapio), tweets, and article summaries.

## Key Videos

1. **"ClawdBot is the most powerful AI tool I've ever used in my life. Here's how to set it up"**
   - URL: https://www.youtube.com/watch?v=Qkqe-uRhQJE
   - Duration: 27:46 | Views: 657K+ | Date: Jan 24, 2026
   - Setup walkthrough, model selection, security warnings

2. **"LIVE: How I'm using ClawdBot to change my life"**
   - Live stream covering Mac Mini vs VPS, memory management, local models
   - Key quote: "If you run it on a VPS, you're getting like 20% of the power"

3. **"Every Single Lesson I've Learned About OpenClaw" (Feb 16, 2026)**
   - Tweeted: https://x.com/AlexFinn/status/2023439732328525890
   - 210+ hours of usage distilled. Covers setup, use cases, VPS critique, security

4. **"6 OpenClaw Use Cases That Could Actually Change Your Life"**
   - Second brain, morning briefs, content engine, coding agent, competitor monitoring

5. **Claude Sonnet 4.6 + OpenClaw video (Feb 2026)**
   - Tweeted: https://x.com/AlexFinn/status/2023886604071551071
   - How to hook up Sonnet 4.6, two use cases

## Core Recommendations

### Hardware: Mac Mini > VPS
- "VPS gives 20% of the power" - strongly favors local Mac setup
- Data stays on your machine when local
- Mac Mini is de facto reference hardware for the community
- 16GB sufficient for cloud API calls; more if running local models
- Predicts hardware demand spike within 12 months

### Security Hardening Checklist (Priority Order)
1. Never expose gateway directly to internet (no port-forwarding/public web-UI)
2. Isolate completely - separate machine/VM, no personal browser profiles
3. Minimize permissions - only activate essential skills
4. Use dedicated accounts - agent gets separate email/chat, never personal
5. Force approvals - irreversible actions require confirmation
6. Secure secrets properly - tokens in vault, rotated regularly
7. Enable audit logging - track what/when/why
8. Vet skill sources - supply chain risk in skill marketplaces

### Three Security Questions Before Launch
1. What data must the agent NEVER access?
2. Which actions require manual confirmation?
3. Which integrations are genuinely necessary vs nice-to-have?

### Local Models (LM Studio)
- Steps: Download LMStudio -> tell OpenClaw your hardware specs -> determine largest model -> identify workflows to replace -> have OpenClaw walk you through download + API setup
- Must load model with maximum context length
- Enable "serve on local network" in server settings (critical)
- Default: http://127.0.0.1:1234

### Model Selection
- Claude Opus: best intelligence + personality (~$200/mo)
- ChatGPT: intelligent but robotic
- MiniMax: budget option (~$10/mo)
- Codec CLI for coding muscle, Opus for higher-level thinking

### Memory Management
- Implement memory flush and session memory search prompts
- Session memory hook is most important - saves context before window fills
- Each Telegram group = separate conversation context/memory
- Brain dump your background, preferences, goals into chat early

### Morning Briefs
- Schedule daily at set time (e.g., 8am)
- Include: news, weather, task summaries, competitor monitoring
- "Henry" (Finn's agent) sends morning briefs with YouTube competitor analysis, AI news, overnight work summary

### Second Brain
- Text anything via Telegram/iMessage/Discord to capture
- OpenClaw memory stores permanently
- Can build/deploy Next.js searchable memory UI
- Cumulative - gets more powerful over time

### "Reverse Prompting"
- Ask the agent what it CAN do based on what it knows about your workflows
- Uncovers unexpected capabilities

## Gotchas
- [gotcha] OpenClaw binds to 0.0.0.0 by default - 135K+ instances found wide open on internet
- [gotcha] "Zero guardrails" + tool access = agent can execute wrong actions from misunderstanding
- [gotcha] API costs accumulate rapidly depending on model choice
- [gotcha] Neglecting personalization severely limits effectiveness
- [gotcha] Setup is a "threat-modeling moment" not just clicking through
- [gotcha] "Can do anything" != "should do anything" - restrict capabilities upfront

## Other Appearances
- This Week in Startups E2247 (podcast with Jason Calacanis + Matt Van Horn)
- Full ClawdBot Bootcamp (paid, via Vibe Coding Academy, 230+ members)
- Skool community: https://www.skool.com/@alex-finn-9189
- Newsletter: https://www.alexfinn.ai/
