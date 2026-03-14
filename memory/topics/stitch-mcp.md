# Stitch MCP Configuration

### 2026-02-18 - Root cause analysis and FIX of Stitch MCP failures

## Current Working Configuration
[pattern] Stitch MCP is configured as a LOCAL stdio server in `~/.claude.json` (global scope):
```json
{
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@_davideast/stitch-mcp", "proxy"],
  "env": {
    "STITCH_PROJECT_ID": "16038115970111393225"
  }
}
```
It runs `@_davideast/stitch-mcp proxy` (v0.4.0) locally via npx.

## Stitch Project Details
- **Project ID**: `16439538952249900732`
- **Title**: "Found in Translation"
- **API Name**: `projects/16439538952249900732`
- **Previous**: `16038115970111393225` ("Mirror Pipeline") -- deleted/inaccessible
- **Visibility**: PRIVATE
- **Type**: TEXT_TO_UI
- **Created**: 2026-02-21
- **Previous ID (stale)**: `5224881548932927504` ("Claude Code Default") -- caused "not found" errors even though project existed in API listing. MCP proxy could not use it.

## What Was Fixed (2026-02-18)
[debug] **Issue 1 - Fake project ID**: `STITCH_PROJECT_ID=stitch-mcp-default` was a placeholder. Fixed by creating a real project via API and updating config.

[debug] **Issue 2 - No GCP quota project**: Fixed by running:
```bash
gcloud auth application-default set-quota-project gen-lang-client-0011792838
```

[debug] **Issue 3 - Stitch API not enabled**: Fixed by running:
```bash
gcloud services enable stitch.googleapis.com
```

[debug] **Issue 4 - No default gcloud project**: Fixed by running:
```bash
gcloud config set project gen-lang-client-0011792838
```

## GCP Setup
- **Quota project**: `gen-lang-client-0011792838` (Gemini API project)
- **Auth**: ash.cocktails@gmail.com via gcloud ADC
- **API**: stitch.googleapis.com enabled on gen-lang-client-0011792838

## Doctor Output (Post-Fix)
[gotcha] `npx @_davideast/stitch-mcp doctor` shows 4/5 green but "API request failed with status 400" on API test. This is likely a doctor bug -- the actual API works fine via curl. Don't trust the doctor API check.

## Key Gotchas
[gotcha] After updating `~/.claude.json`, you MUST restart Claude Code for the MCP server to pick up the new config. The MCP server reads config at startup.

[gotcha] The `init` command (`npx @_davideast/stitch-mcp init -c claude-code`) is INTERACTIVE and cannot be fully automated. Use `--defaults -y` flags, but auth mode selection still requires input.

[gotcha] The Stitch project ID in config is just the numeric ID (e.g., `16038115970111393225`), NOT the full path (`projects/16038115970111393225`).

### 2026-02-21 - Fixed stale project reference
[debug] Project `5224881548932927504` ("Claude Code Default") became unusable by the MCP proxy -- every call returned "Project not found or deleted" even though the project still existed in the API listing. Fix: created new project `16038115970111393225` ("Mirror Pipeline") via direct curl to `stitch.googleapis.com/v1/projects` and updated `STITCH_PROJECT_ID` in `~/.claude.json`. Restart Claude Code required for MCP to pick up the change.

## Alternative: Use STITCH_API_KEY
[pattern] Can bypass gcloud entirely by setting `STITCH_API_KEY` env var. Get key from Stitch web UI or GCP console.

## Available GCP Projects
- gen-lang-client-0011792838 (Gemini API) -- USED FOR QUOTA
- gen-lang-client-0101793514 (nexus)
- cobalt-entropy-436817-r8 (My First Project)
- atomic-rune-450718-q5 (n8n VM Instance 1)
- deepseek-email-automation
- packing-list-app-448014
- googly-crane-3sftc
