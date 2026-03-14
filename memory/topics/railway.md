# Railway Learnings

## Notes

### 2026-02-06 - Seeded from existing skills
[pattern] See ~/.claude/skills/railway-deployment.md for full deployment patterns. Notes below capture quick gotchas not in the skill file.

### 2026-02-15 - railway up uses repo root, not CWD
[gotcha] `railway up` always uploads from the git repo root, regardless of your current directory. `RAILWAY_ROOT_DIRECTORY` env var only works for GitHub-connected deploys. To deploy a subdirectory via CLI, use `railway up --path-as-root skills/twilio-sms`. Without this flag, it builds the root Dockerfile even if you're cd'd into the subdirectory.

### 2026-02-15 - railway service link requires service ID in non-TTY
[gotcha] `railway service link` is interactive and fails in non-TTY. Use `railway service link <service-id>` with the UUID directly. Get service IDs from `railway status --json | jq '.environments.edges[0].node.serviceInstances.edges[] | {name: .node.serviceName, id: .node.serviceId}'`. Twilio SMS service ID: `ff2f0d55-71ee-4eb4-8630-01ad989902b6`.

### 2026-02-15 - railway up deploys to currently linked service
[gotcha] `railway up` deploys to whichever service is currently linked via `railway service link`. If you're deploying to service B but the CLI is linked to service A, it deploys to A silently. ALWAYS verify with `railway status` before deploying. Sequence: `railway service link <target-uuid>` -> `railway up --path-as-root <dir>` -> verify -> `railway service link <original-uuid>` to re-link.

### 2026-02-16 - twilio-sms deployment uses separate repo
[gotcha] The twilio-sms Railway service deploys from a SEPARATE GitHub repo: `ashleytower/twilio-sms-webhook`. NOT from the max-ai-employee monorepo. When code changes are made in `skills/twilio-sms/`, they must be synced to the webhook repo: `rsync -av --exclude='node_modules' --exclude='.git' --exclude='.env' skills/twilio-sms/ <clone-of-twilio-sms-webhook>/` then push. The monorepo `git push` does NOT auto-deploy twilio-sms. The root Dockerfile in max-ai-employee is for the OpenClaw gateway -- connecting the monorepo to twilio-sms service would deploy the gateway code instead.

[debug] Spent 30+ min debugging why `railway up` from `skills/twilio-sms/` kept deploying the OpenClaw gateway. Root cause: the service had `ashleytower/twilio-sms-webhook` as its GitHub source. A git push to the monorepo caused Railway to build from the wrong repo/Dockerfile. Fix: keep the separate repo connected, sync code there manually.
