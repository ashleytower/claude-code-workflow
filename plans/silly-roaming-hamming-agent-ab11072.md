# Fix twilio-sms Railway Service Deployment

## Problem

The twilio-sms Railway service at `twilio-sms-production-b6b8.up.railway.app` is broken. It returns HTTP 500 with "SETUP_PASSWORD is not set" because the **root OpenClaw gateway Dockerfile** (node:22, `src/server.js`) was deployed to the twilio-sms service instead of the correct **twilio-sms Dockerfile** (node:20-slim, `src/index.js`).

## Root Cause

`railway status` shows the CLI is linked to **Service: OpenClaw** regardless of directory. The Railway CLI link is project-wide, not per-directory. There is no `.railway` file in `skills/twilio-sms/` to persist a per-directory service link.

## Diagnosis (Read-Only, Completed)

- [x] `skills/twilio-sms/Dockerfile` is correct: `FROM node:20-slim`, runs `npm start` -> `node src/index.js`
- [x] Root `Dockerfile` is the OpenClaw gateway: `FROM node:22-bookworm`, runs `node src/server.js`
- [x] `railway status` from both root and twilio-sms dir shows `Service: OpenClaw`
- [x] `railway service status` only shows OpenClaw service
- [x] `skills/twilio-sms/railway.json` config is correct
- [x] `skills/twilio-sms/package.json` is correct: Express app, port 5000

## Plan

### Step 1: Link to twilio-sms service
```bash
cd /Users/ashleytower/Documents/GitHub/max-ai-employee/skills/twilio-sms
railway service link twilio-sms
```

### Step 2: Verify the link
```bash
railway status
# Should show: Service: twilio-sms (not OpenClaw)
```

### Step 3: Deploy from the twilio-sms directory
```bash
cd /Users/ashleytower/Documents/GitHub/max-ai-employee/skills/twilio-sms
railway up
```

### Step 4: Verify environment variables
```bash
railway variables
```
Required: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER, SUPABASE_URL, SUPABASE_SERVICE_KEY, ANTHROPIC_API_KEY, TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID, NODE_ENV

### Step 5: Verify health endpoint
```bash
curl -s https://twilio-sms-production-b6b8.up.railway.app/health
```
Expected: `{"status":"ok","timestamp":"..."}`

### Step 6: Re-link back to OpenClaw
```bash
cd /Users/ashleytower/Documents/GitHub/max-ai-employee
railway service link OpenClaw
```

## No Code Changes Required

The `skills/twilio-sms/` code is correct. Only operational fix needed: deploy the right Docker image.
