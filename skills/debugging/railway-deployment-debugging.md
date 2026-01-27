---
name: railway-deployment-debugging
category: debugging|deployment|infrastructure
frameworks: [python, fastapi, starlette]
last_updated: 2026-01-21
version: 1.0
---

# Railway Deployment Debugging

## Summary

This skill documents a debugging session where multiple issues cascaded, causing extended troubleshooting time. The root causes were: (1) Nixpacks detecting wrong providers, (2) invalid Google credentials, and (3) incorrect Starlette middleware syntax.

## Key Lesson: USE CONTEXT7 FIRST

**CRITICAL FAILURE**: Did not use Context7 MCP to look up Starlette middleware documentation before debugging. This would have immediately shown the correct `Middleware()` class syntax and saved 20+ minutes of trial and error.

```bash
# SHOULD HAVE DONE THIS FIRST:
# Use Context7 to look up Starlette middleware syntax
mcp__context7__search "starlette middleware configuration"
```

**Rule**: When encountering framework-specific errors, ALWAYS check documentation via Context7 before attempting fixes.

## The Problems Encountered

### Problem 1: Nixpacks Detecting Multiple Providers

**Symptom**: Railway build was running both Python AND Deno steps, causing confusion.

**Root Cause**: TypeScript files in `supabase/functions/` directory triggered Deno detection.

**Fix**: Create `nixpacks.toml` to force Python-only build:

```toml
# nixpacks.toml
# Force Python-only build (ignore Deno/TypeScript in supabase/)
providers = ["python"]
```

**Lesson**: When you have mixed language files, explicitly specify the Nixpacks provider.

### Problem 2: Invalid Google Service Account Credentials

**Symptom**:
```
google.auth.exceptions.RefreshError: ('invalid_grant: Invalid JWT Signature.', {'error': 'invalid_grant', 'error_description': 'Invalid JWT Signature.'})
```

**Root Cause**: Old/invalid service account JSON in Railway environment variables.

**Fix**: Update `GOOGLE_SERVICE_ACCOUNT_JSON` with new valid credentials.

**How to update in Railway**:
1. Go to Service > Variables tab
2. Click on the variable value to edit
3. Select all (Cmd+A), paste new JSON
4. Click checkmark to save
5. Click "Deploy" to apply changes

**Lesson**: When Google auth fails with "Invalid JWT Signature", the credentials themselves are wrong - not a code issue.

### Problem 3: Starlette Middleware Configuration (The Big One)

**Symptom**:
```
ValueError: not enough values to unpack (expected 3, got 2)
```
in `starlette/applications.py` at `build_middleware_stack`

**Root Cause**: Middleware was configured as a tuple instead of using the `Middleware` class.

**WRONG** (what was there):
```python
from starlette.middleware.cors import CORSMiddleware

app = Starlette(
    middleware=[
        (
            CORSMiddleware,
            {
                "allow_origins": ["*"],
                "allow_methods": ["GET", "POST"],
            }
        ),
    ],
)
```

**CORRECT** (the fix):
```python
from starlette.middleware import Middleware  # MUST IMPORT THIS
from starlette.middleware.cors import CORSMiddleware

app = Starlette(
    middleware=[
        Middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_methods=["GET", "POST"],
        ),
    ],
)
```

**Key Differences**:
1. Import `Middleware` from `starlette.middleware`
2. Use `Middleware()` class, not tuple
3. Pass kwargs directly, not as a dict

## Why I Spun in Circles

### 1. Did Not Consult Documentation

**What happened**: Saw the middleware error and started guessing at fixes instead of looking up the correct Starlette middleware syntax.

**Should have done**:
```bash
# Use Context7 to get authoritative docs
mcp__context7__resolve_library_id "starlette"
mcp__context7__get_library_docs --library-id "/starlette" --topic "middleware"
```

### 2. Multiple Cascading Issues

**What happened**: Fixed the Nixpacks issue, then hit credentials issue, then hit middleware issue. Each fix revealed the next problem.

**Should have done**: Run the app locally first to catch the middleware error before deploying.

### 3. Browser Automation Overhead

**What happened**: Used Chrome automation to update Railway variables, which is slow and error-prone.

**Better approach**: Use Railway CLI when possible:
```bash
railway variables set GOOGLE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
railway up
```

### 4. Not Testing Locally

**What happened**: Deployed to Railway and debugged via remote logs.

**Should have done**:
```bash
# Test locally first
python mcp_server_http.py

# Then deploy after confirming it works
railway up
```

## Debugging Checklist for Railway Deployments

### Before Deploying

- [ ] Test locally with production env vars
- [ ] Check `nixpacks.toml` if mixed language project
- [ ] Verify all required env vars are set
- [ ] Run `python -c "from app import app"` to catch import errors

### When Deployment Fails

1. **Check Build Logs**: Is Nixpacks detecting the right language?
2. **Check Deploy Logs**: Look for Python tracebacks
3. **Check HTTP Logs**: What endpoints are returning errors?

### Common Railway Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Wrong language detected | Mixed files | Add `nixpacks.toml` |
| Build succeeds, app crashes | Runtime error | Check Deploy Logs |
| 500 errors on all routes | Middleware/startup error | Check exception in Deploy Logs |
| Google auth fails | Invalid credentials | Update env var with fresh JSON |
| "Invalid JWT Signature" | Wrong/expired service account | Generate new key in GCP console |

## Quick Reference: Starlette Middleware

```python
from starlette.applications import Starlette
from starlette.middleware import Middleware
from starlette.middleware.cors import CORSMiddleware
from starlette.middleware.gzip import GZipMiddleware
from starlette.middleware.httpsredirect import HTTPSRedirectMiddleware

app = Starlette(
    routes=[...],
    middleware=[
        Middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        ),
        Middleware(GZipMiddleware, minimum_size=1000),
        Middleware(HTTPSRedirectMiddleware),
    ],
)
```

## Quick Reference: Nixpacks Configuration

```toml
# nixpacks.toml

# Force specific provider(s)
providers = ["python"]

# Or for Node.js
providers = ["node"]

# Custom build command
[phases.build]
cmds = ["pip install -r requirements.txt"]

# Custom start command
[start]
cmd = "uvicorn main:app --host 0.0.0.0 --port $PORT"
```

## Quick Reference: Railway CLI

```bash
# Login
railway login

# Link to project
railway link

# Set variables
railway variables set KEY=value

# Deploy
railway up

# View logs
railway logs

# Open dashboard
railway open
```

## Prevention Strategy

1. **ALWAYS use Context7** for framework documentation before coding/fixing
2. **Test locally first** before deploying to Railway
3. **Use Railway CLI** instead of browser when possible
4. **Check Nixpacks detection** on first deploy of mixed-language projects
5. **Validate credentials locally** before adding to Railway

## Related Skills

- `google-service-account.md` - Setting up Google Cloud credentials
- `starlette-fastapi.md` - Starlette/FastAPI patterns
- `railway-deployment.md` - Railway deployment basics

## Updates

- 2026-01-21: Initial creation from debugging session
