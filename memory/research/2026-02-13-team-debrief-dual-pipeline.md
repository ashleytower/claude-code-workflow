# Team Debrief: Dual-Mode Mirror Pipeline

## Date: 2026-02-13
## Team: dual-pipeline (team-lead + generic-builder + ashley-builder)

## What went smoothly
- Both agents completed their work independently with zero conflicts
- All 158 tests passed on first integration
- Ashley pipeline: clean composition migration with thin re-export wrappers for shared scenes
- Generic pipeline: all 5 DemoScene types (screenshot, before-after, feature-list, voice-command, step-flow) worked correctly
- Type relaxation (segment enum → string) was backward-compatible with all existing tests

## What was hard
- **Remotion + node:fs**: Generic registry imported loader.ts which uses node:fs. Webpack (Remotion bundler) cannot handle `node:` URIs. Fix: switch to static JSON imports in registry, keep loader for CLI only. Wasted one build cycle.
- **Zod 3.22.3 constraints**: z.discriminatedUnion + z.intersection is fragile in this version. Tests pass but needs documentation.
- **Segment enum relaxation**: Had to update 6+ files (schema, enrichment types, script types, template types, enrichment prompt, enrichment validation). Each type had its own hardcoded `'bookkeeping' | 'inventory' | 'crm'` union.
- **Test segment values**: Ashley builder used placeholder `'crm'` segment for new product tests since schema hadn't been relaxed yet. Had to fix 4 test files during integration.

## Key learnings
- Remotion registry code runs in Webpack context — no Node.js built-ins allowed
- When relaxing a type union to string, grep for ALL occurrences across types, schemas, validation, and prompts — they accumulate
- Agent teams work well when file boundaries are clear. Both agents created ~20 files each with zero conflicts.
- Code reviewer caught 6 real issues including the ImageSegment type not being relaxed and enrichment prompt still hardcoding 3 segments

## Unresolved
- GenericLeadPropsSchema.demoContent uses z.record(z.unknown()) which loses type safety at Remotion schema level. Accepted as limitation.
- Enrichment prompt is now dynamic but LLM behavior may need tuning for new segments
