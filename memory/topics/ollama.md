# Ollama

## 2026-02-15 - Ollama fallback in email-master
[gotcha] The `ollama_prefilter()` function in process-emails.sh calls `call_ollama()`, which auto-falls back to Claude API if Ollama is down. But there was NO alert -- credits could be wasted silently. Fixed by adding Telegram alert when fallback triggers (once per run, not per email).

[pattern] Ollama pre-filter runs BEFORE paid Claude draft. If Ollama classifies as "skip", we mark the email as transactional and skip drafting (saves ~$0.01/email). If Ollama is down, fallback lets everything through to Claude (safe default, but costs money).

[pattern] `call_ollama()` in common.sh checks if Ollama is reachable with 2s timeout (`curl -s --max-time 2 "${OLLAMA_URL}/api/tags"`). If unreachable, it logs "Ollama not running, falling back to Claude API" and calls `call_claude_api()` instead. This fallback is transparent to callers.
