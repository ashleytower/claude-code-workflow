### 2026-02-06 - OpenClaw & Agent Orchestration Research (Team Debrief)

[research] Four-agent parallel research into OpenClaw, Claude Agent SDK, orchestration frameworks, and mtl-craft-cocktails-ai.

**What went smoothly**: All four agents completed independently. Web searches returned rich results. Repo analysis was thorough.

**Key learnings**:
- [pattern] OpenClaw architecture: Gateway (Node.js WebSocket) + Agent Runtime + Skills Platform + Channel Adapters. Hub-and-spoke model. 145k GitHub stars.
- [gotcha] OpenClaw has serious security issues: CVE-2026-25253, Gartner/Palo Alto warnings, creator says "I ship code I don't read"
- [pattern] Claude Agent SDK (`@anthropic-ai/claude-agent-sdk`) provides same engine as Claude Code, programmable via `query()`. Supports subagents, MCP servers, session resume.
- [pattern] Agent Teams in Claude Code = experimental CLI feature (not in SDK). Good for dev tasks, not persistent assistant workflows.
- [research] Best frameworks for personal AI assistant: Mastra (TS, 150k weekly downloads), LangGraph (Python, best state mgmt), Gru (simplest OpenClaw alt)
- [research] Composio solves OAuth for 500+ services. This is the answer for agent credential management.
- [research] n8n self-hosted is fastest path to prototype (hours). Mastra or LangGraph for custom build (days).
- [pattern] mtl-craft-cocktails-ai already has 105 voice tools across 13 skill bundles, workflow coordinator, and multi-agent validation designed -- but proactive agents are all `auto: false`. Activation is the biggest unlock.
- [gotcha] App exposes VITE_ANTHROPIC_API_KEY client-side. Fine for single-user but needs server proxy for multi-user.

**Unresolved**: How to bridge Claude Agent SDK with a messaging bot (Telegram) while maintaining session persistence and proactive scheduling. Multiple open-source examples exist but none are production-hardened.
