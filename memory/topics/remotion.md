# Remotion

### 2026-02-12 - Mirror Pipeline Phase 1+2 Build
[gotcha] Anthropic SDK (@anthropic-ai/sdk) has a peer dep on newer Zod, but Remotion pins zod@3.22.3. Use `--legacy-peer-deps` when installing. No functional impact.

[gotcha] Remotion's default ESLint config has no TypeScript parser. Must add `typescript-eslint` as dev dep and configure parser in eslint.config.js for .ts files to lint.

[gotcha] Vitest mock pattern for Anthropic SDK requires class-based mock (mock the constructor), not vi.fn().mockImplementation — the SDK exports a class, not a function.
