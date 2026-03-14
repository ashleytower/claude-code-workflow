### 2026-02-08 - browser-use Library Research

[research] Deep dive on browser-use (github.com/browser-use/browser-use) for potential Max AI Employee integration.

**What it is**: Python library (MIT, v0.11.9) that lets LLMs control browsers via natural language. 78k+ GitHub stars. Uses Playwright + CDP under the hood. Python 3.11+ required.

**Key facts**:
- LLM agent loop: task -> observe page state -> decide action -> execute -> repeat
- Supports OpenAI, Anthropic, Google, Groq, Ollama, and their own ChatBrowserUse model
- ChatBrowserUse pricing: $0.20/M input, $2.00/M output tokens
- Has CLI, sandbox deployment, Docker support, MCP integration
- Cloud offering for stealth browsers, proxy rotation, CAPTCHA handling

**Honest assessment**:
- [gotcha] Our existing browser-automation skill uses Playwright (Node.js) with hardcoded selectors. browser-use would replace this with LLM-driven navigation (Python).
- [gotcha] Language mismatch: browser-use is Python-only, our stack is Node.js. Would need a Python sidecar or subprocess approach.
- [gotcha] CVE-2025-47241 was a critical security vuln (patched in 0.1.45). Shows the project has had security issues.
- [gotcha] Ollama integration (#584) reported broken - local LLM support unreliable.
- [gotcha] CAPTCHA handling requires their paid Cloud service. Local instances cannot handle CAPTCHAs.
- [gotcha] Vision-based agents struggle with small targets (date pickers, icon grids). Even 1% failure rate compounds at scale.
- [decision] For Max's use case (deterministic tasks like bill pay, food ordering), hardcoded Playwright selectors are MORE reliable than LLM-driven navigation. LLM approach better for open-ended research tasks.
- [pattern] Hybrid approach is the industry consensus: use DOM/selector-based automation for known sites, LLM-driven for unknown/dynamic sites.

**Cost concern**: Each browser task burns LLM tokens for EVERY step (screenshot analysis, action decision). A simple food order could cost $0.10-0.50 in tokens per run vs. $0 for scripted Playwright.

**Verdict**: Not a replacement for our existing Playwright skill. Potential addition for exploratory/research browser tasks where selectors aren't pre-configured. Consider as a fallback layer, not primary automation.
