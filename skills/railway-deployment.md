---
name: railway-deployment
category: deployment
frameworks: [python, fastapi, nodejs]
last_updated: 2026-01-26
version: Railway CLI 3.x
---

# Railway Deployment Patterns

## Quick Start

```bash
# Install CLI
curl -fsSL https://railway.app/install.sh | sh

# Login
railway login

# Link project
railway link

# Deploy
git push origin main  # Auto-deploys if connected
# OR
railway up  # Manual deploy
```

## Project Structure

### Python FastAPI
```
project/
├── main.py              # Entry point
├── requirements.txt     # Dependencies
├── railway.json         # Railway config
├── nixpacks.toml        # Build config
└── .env.example         # Env var template
```

### Entry Point (main.py)
```python
"""Railway entry point"""
import os
import uvicorn
from your_app import app

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
```

### Railway Config
```json
// railway.json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {"builder": "NIXPACKS"},
  "deploy": {
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### Build Config
```toml
# nixpacks.toml
# Force Python-only build (useful for monorepos)
providers = ["python"]

# Or specify exact start command
[start]
cmd = "python main.py"
```

## Environment Variables

### CRITICAL GOTCHA: Shared Variables

**Adding a variable to "Shared" does NOT automatically add it to services!**

Steps to share variables:
1. Project → Shared Variables → Add
2. Go to EACH service
3. Click the "ADD" button next to the variable
4. "ADD" = not using it, "ADDED" = actually in service

Visual check:
```
Variable: GOOGLE_API_KEY
├── Service1: ADD      ← NOT USING IT
├── Service2: ADDED    ← USING IT
└── Service3: ADD      ← NOT USING IT
```

### Common Variables

```env
# Auto-provided by Railway
PORT=8080  # Don't set manually
RAILWAY_ENVIRONMENT=production

# Your variables
DATABASE_URL=postgresql://...
API_KEY=xxx

# For Python logging
LOG_LEVEL=INFO
DEBUG=false
```

## Multiple Services Pattern

### When to Use
- Voice agent + API server (separate resource needs)
- Worker + Web server
- Different scaling requirements

### Setup
1. Create project
2. Add service from GitHub repo
3. Configure start command per service
4. Share environment variables

### Example: Voice App

**Service 1: API Server**
- Start: `uvicorn simple_api:app --host 0.0.0.0 --port $PORT`
- Resources: 512MB RAM
- Exposes: REST endpoints

**Service 2: Voice Agent**
- Start: `python livekit_agent.py`
- Resources: 1GB RAM
- Connects to: LiveKit Cloud

### Service-Specific Start Commands

Option 1: Different main files
```bash
# Service 1
python main_api.py

# Service 2
python main_worker.py
```

Option 2: Same file, different commands
```bash
# Service 1
python main.py serve

# Service 2
python main.py worker
```

## Debugging

### Check Deployment Status
```bash
railway status
railway logs
railway logs --tail 100
```

### Verify Environment
```bash
railway variables
railway run env | grep MY_VAR
```

### Common Issues

#### 1. "Service Unavailable" (503)
- Check logs: `railway logs`
- Verify PORT is not hardcoded
- Check health endpoint

#### 2. Variable Not Found
- Verify "ADDED" status in Railway UI
- Check spelling (case-sensitive)
- Redeploy after adding

#### 3. Build Fails
```bash
# Check build logs in Railway UI
# Common fixes:
# - Add nixpacks.toml for mixed repos
# - Specify Python version in runtime.txt
# - Check requirements.txt syntax
```

#### 4. Deployment Doesn't Update
- Check commit SHA in Railway matches latest
- Verify auto-deploy is enabled
- Try manual: `railway up`

#### 5. Silent Mock Fallback Hides Real Errors
**Symptom**: Agent returns empty/wrong data, app seems to work but data is wrong

**Cause**: Code falls back to mock mode when auth fails
```python
# BAD - Silent fallback
try:
    sheets = GoogleSheets(credentials)
except:
    sheets = MockSheets()  # Silently uses fake data!
```

**Fix**: Fail loudly on auth errors
```python
# GOOD - Explicit failure
try:
    sheets = GoogleSheets(credentials)
except Exception as e:
    raise RuntimeError(f"Google Sheets auth failed: {e}")
```

#### 6. Multiple Auth Methods Cause Confusion
For Google APIs, you only need ONE of:
- `GOOGLE_SERVICE_ACCOUNT_JSON` - Full JSON string (recommended for servers)
- `GOOGLE_API_KEY` - Simple API key (also works)
- `GOOGLE_CLIENT_ID/SECRET` - OAuth (NOT needed for server-to-server)

Don't mix them. Pick one and use it consistently.

#### 7. Response Shape Changes Between Query Types
**Symptom**: KeyError or undefined when accessing response fields

**Example**: Syrup queries
```python
# With size specified:
{"found": True, "quantity": 9, "item": "Ginger 4oz"}

# Without size:
{"found": True, "multiple_sizes": True, "message": "Which size?"}
# NO quantity field!
```

**Fix**: Always check for variant response shapes
```python
if result.get("multiple_sizes"):
    return f"Which size? {result.get('message')}"
quantity = result.get("quantity", 0)
```

### Log Verification Pattern

Always log auth status on startup:
```python
logger.info(f"Google Sheets authenticated: {sheets_connected}")
logger.info(f"Environment: {os.getenv('RAILWAY_ENVIRONMENT')}")
```

Check logs for these messages after deploy to verify env vars loaded.

### Debugging Checklist: "Agent Returns Wrong Data"

When your agent can't find items or returns hallucinated responses:

1. [ ] Check Railway logs for "Google Sheets authenticated" message
2. [ ] Verify env vars show "ADDED" (not "ADD") in each service
3. [ ] Check latest commit SHA matches Railway deployment
4. [ ] Test locally with same env vars first
5. [ ] Look for silent mock/fallback code paths
6. [ ] Verify response shape handling for all query types

## Domain & HTTPS

Railway provides:
- Free `*.up.railway.app` domain
- Automatic HTTPS
- Custom domain support

### Custom Domain
1. Settings → Domains → Add
2. Add CNAME record: `your-app.railway.app`
3. Wait for SSL provisioning

## Health Checks

Railway expects a successful response to determine service health.

```python
@app.get("/health")
async def health_check():
    return {
        "status": "ok",
        "version": "1.0.0",
        "sheets_connected": bool(sheets_service.authenticated)
    }
```

## Costs

| Resource | Included Free | Overage |
|----------|---------------|---------|
| RAM | 512MB | $0.000231/GB/min |
| CPU | Shared | $0.000463/vCPU/min |
| Egress | 100GB/mo | $0.10/GB |
| Build | 500 hrs/mo | $0.01/min |

**Tip**: Start services only when needed. Pause dev environments.

## Auto-Deploys

### GitHub Integration
1. Project Settings → Connect GitHub
2. Select repo and branch
3. Every push triggers deploy

### Disable for Specific Commits
```bash
git commit -m "docs: update readme [skip ci]"
```

## Dependabot Integration

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "python"
```

Railway auto-deploys Dependabot PRs when merged.

## Monorepo Support

For repos with multiple apps:

```toml
# nixpacks.toml
providers = ["python"]  # Ignore other languages

[phases.setup]
nixPkgs = ["python311"]

[phases.install]
cmds = ["pip install -r requirements.txt"]

[start]
cmd = "python main.py"
```

Or use Railway's root directory setting:
- Service Settings → Root Directory → `/backend`

## Multi-Repo Service Pattern (twilio-sms)

When a Railway service deploys from a **separate repo** (not the monorepo), code changes in the monorepo must be synced manually.

### Architecture

```
max-ai-employee (monorepo)          ashleytower/twilio-sms-webhook (deploy repo)
├── skills/twilio-sms/              ├── Dockerfile
│   ├── Dockerfile                  ├── package.json
│   ├── package.json                ├── railway.json
│   ├── railway.json                └── src/
│   └── src/                            ├── index.js
│       ├── index.js                    ├── routes/
│       ├── routes/                     ├── services/
│       ├── services/                   └── utils/
│       └── utils/
├── Dockerfile          ← OpenClaw gateway (NOT twilio-sms)
└── src/server.js       ← OpenClaw gateway wrapper
```

### Deploy Workflow

```bash
# 1. Make changes in monorepo
#    Edit skills/twilio-sms/src/...

# 2. Commit to monorepo
git add skills/twilio-sms/ && git commit -m "feat: ..." && git push

# 3. Sync to deploy repo
git clone https://github.com/ashleytower/twilio-sms-webhook.git /tmp/twilio-sync
rsync -av --exclude='node_modules' --exclude='.git' --exclude='.env' \
  skills/twilio-sms/ /tmp/twilio-sync/
cd /tmp/twilio-sync && git add -A && git commit -m "sync from monorepo" && git push

# 4. Railway auto-deploys from twilio-sms-webhook push
```

### Railway Service Config

| Setting | Value |
|---------|-------|
| Source Repo | `ashleytower/twilio-sms-webhook` |
| Branch | `main` |
| Root Directory | (blank -- repo root IS the app) |
| Builder | `DOCKERFILE` |
| Healthcheck | `/health` |

### twilio-sms Dockerfile

```dockerfile
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
```

### Gotchas

#### 8. Monorepo Push Does NOT Deploy twilio-sms
**Symptom**: Push to `max-ai-employee` main, twilio-sms service doesn't update.

**Cause**: twilio-sms deploys from `ashleytower/twilio-sms-webhook`, not the monorepo. The monorepo push only affects the OpenClaw gateway service.

**Fix**: Always sync to the deploy repo after monorepo changes (see workflow above).

#### 9. Connecting Monorepo to twilio-sms Service Deploys Gateway
**Symptom**: After connecting `ashleytower/max-ai-employee` to twilio-sms service, it shows `[wrapper] setup wizard` logs instead of Express server.

**Cause**: Railway finds the ROOT Dockerfile (`CMD ["node", "src/server.js"]` = OpenClaw gateway). Even with `RAILWAY_ROOT_DIRECTORY=skills/twilio-sms`, the root Dockerfile takes precedence during auto-deploy.

**Fix**: Keep the separate deploy repo. Never connect the monorepo to the twilio-sms service.

#### 10. `railway up` From Subdirectory Still Uses Wrong Dockerfile
**Symptom**: Running `railway up` from `skills/twilio-sms/` still deploys the gateway wrapper.

**Cause**: When a GitHub source was connected, Railway's auto-deploy from the push overrides the `railway up` deployment. The auto-deploy builds from the connected repo (which was stale/wrong).

**Fix**: Disconnect the GitHub source before using `railway up`, or keep the source connected and push to the correct repo instead.

#### 11. `railway variables` Truncates Long Values
**Symptom**: API key copied from `railway variables` table output is rejected (401 Unauthorized).

**Cause**: The table display truncates long values to fit the terminal width.

**Fix**: Use `railway variables --json | python3 -c "import json,sys; print(json.load(sys.stdin)['VAR_NAME'])"` to get the full value.

---

*Updated 2026-02-16: Added twilio-sms multi-repo deployment pattern, monorepo vs deploy repo gotchas*
