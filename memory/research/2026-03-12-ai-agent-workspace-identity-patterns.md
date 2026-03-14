# AI Agent Workspace & Identity File Patterns Research

Date: 2026-03-12
Tags: [research] [pattern]

## Summary

Research into how people structure AI agent workspace/identity files, modular system prompts, context management, and lazy-loading patterns for multi-role AI employees.

## Key Findings

### 1. OpenClaw Community Patterns
- Workspace-as-Kernel: SOUL.md (behavior), TOOLS.md (capabilities), IDENTITY.md (persona), HEARTBEAT.md (execution cadence)
- MEMORY.md as curated long-term memory, daily logs in memory/YYYY-MM-DD.md
- Git-track entire workspace for version-controlled AI personality
- Ken Huang's 7-part design patterns series covers kernel, orchestration, tooling, reliability, security, evaluation
- `openclaw doctor` validates config after changes

### 2. Modular System Prompt Design
- LangGPT framework: Role > Profile > Goal > Rules > Workflow > Tools (with variables, commands, conditional logic)
- Prompt routers > monolithic prompts: faster, cheaper, easier to maintain
- Routing methods: LLM-based, fine-tuned classifier, vector distance/embeddings, ML decision trees
- XML tags for nested/structured sections; Markdown for general use (15% fewer tokens than JSON)
- Anthropic recommends: smallest possible set of high-signal tokens

### 3. Agent Framework Memory Patterns
- CrewAI: role-based agents defined via YAML (role, goal, backstory, tools) - best for "team of agents"
- LangGraph: stateful graphs with central state object, persistent memory across sessions, reducer logic for concurrent updates
- AutoGen: conversation-based multi-agent with message lists
- All three support short-term + long-term memory; LangGraph most mature for production

### 4. Token-Efficient Knowledge Access
- RAG beats system prompt stuffing for large knowledge bases (40-60% cost savings)
- Hybrid approach: sliding window for recent context + RAG for knowledge base
- Context engineering = finding smallest high-signal token set
- Avoid "context obesity" - stuffing everything in case it's needed

### 5. Lazy Loading / Progressive Context
- Three-tier progressive disclosure: metadata (~100 tokens at startup) > skill body (~5K tokens on invocation) > referenced files (on demand)
- 98% token reduction possible (150K -> 2K)
- Dynamic Context Loading for MCP: server descriptions at startup, tool summaries on request, full schemas only on use
- Speakeasy achieved 100x reduction with dynamic toolsets
- Claude Code's tool lazy loading = 95% context reduction

### 6. Context Engineering (Anthropic Official)
- "Finding smallest possible set of high-signal tokens that maximize likelihood of desired outcomes"
- Avoid hardcoding complex brittle logic in prompts
- For long-running agents: progress files + git history for state recovery
- Code execution with MCP reduces tool definition bloat
- Different prompt for first context window vs continuation

## Specific Recommendations for Max AI Employee

1. **Split MEMORY.md (311 lines) into topic files** - load only relevant business context per task (pricing.md, suppliers.md, logistics.md)
2. **Add routing metadata to TOOLS.md** - tag tools by domain so irrelevant tools don't load
3. **Implement three-tier skill loading** - already partially done with OpenClaw's available_skills list
4. **Consider vector-based routing** - embed skill descriptions, match incoming query to relevant skill via cosine similarity
5. **IDENTITY.md (274 lines) could be trimmed** - separate "who Max is" (always loaded) from "detailed business context" (loaded on demand)
