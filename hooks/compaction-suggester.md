# Compaction Suggester Hook

Suggests context compaction when conversation gets long.

## Trigger
After every 10 tool calls, check if compaction would help.

## Signs to compact
- Repeated file reads of same files
- Long error traces that are now resolved
- Exploration phase complete, moving to implementation
- Context includes outdated plan versions

## Suggestion format
```
Context is getting long. Consider running /compact to:
- Summarize exploration findings
- Clear resolved error traces
- Keep only current plan version
```

## Note
This is a reminder pattern, not an automated hook.
Check context usage with `claude --usage` if available.
