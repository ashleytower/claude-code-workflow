# Vercel Learnings

## Notes

### 2026-02-06 - Seeded from existing skills
[pattern] See ~/.claude/skills/vercel-express-deployment.md for full deployment patterns. Notes below capture quick gotchas not in the skill file.

### 2026-02-06 - Functions config glob patterns cause unused_function error
[gotcha] On Vite framework preset, adding a second `functions` entry with a more specific glob (e.g., `"api/cron/*.js"` or `"api/cron/**/*.js"`) causes deployment error: `unused_function: The pattern doesn't match any Serverless Functions`. The general `"api/**/*.js"` pattern works fine. Fix: use `export const config = { maxDuration: 60 }` inside the individual function files instead of vercel.json overrides. This per-file config correctly overrides the global maxDuration.

### 2026-02-06 - Env var changes require redeployment
[gotcha] Updating env vars via API (VERCEL_ADD_ENVIRONMENT_VARIABLE with upsert:true) does NOT take effect on the running deployment. Must trigger VERCEL_CREATE_NEW_DEPLOYMENT (pass deploymentId of latest prod deploy) for changes to propagate. Project ID for mtl-craft-cocktails-ai is `prj_eDmFiwRmGHXbfUAbkYkwZJrZXvCK`.

### 2026-02-10 - npm ERESOLVE peer dep conflict breaks Vercel build
[gotcha] Vercel's `npm install` is stricter than local npm. When local npm shows "ERESOLVE overriding peer dependency" warnings, Vercel fails with `npm error code ERESOLVE`. Fix: add `.npmrc` with `legacy-peer-deps=true` to the repo root. Specific case: `eslint@^10.0.0` + `typescript-eslint@^8.55.0` (peer dep only supports eslint 8/9). Three consecutive deployments failed before adding `.npmrc`.

### 2026-02-06 - ANTHROPIC_API_KEY vs VITE_ANTHROPIC_API_KEY
[gotcha] Server-side functions use `process.env.ANTHROPIC_API_KEY` (no VITE_ prefix). VITE_ prefix vars are for client-side only (Vite inlines them at build). Both must be set separately in Vercel. If the server-side key returns "Server authentication error with AI provider", it means the key IS set but Anthropic rejected it (401 from Anthropic) -- check if the value matches the valid key.
