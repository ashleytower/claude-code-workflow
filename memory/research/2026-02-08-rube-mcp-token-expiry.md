# Rube MCP Token Expiry Research

## Date: 2026-02-08

## Problem
Every new Claude Code session, the Rube MCP token appears expired. The user runs `npx -y @jlowin/rube-mcp` in Claude Desktop config.

## Root Causes Found (3 issues compounding)

### 1. The `@jlowin/rube-mcp` npm package no longer exists
- Running `npx -y @jlowin/rube-mcp` returns **npm 404 Not Found**
- The package was either deprecated, removed, or moved to `@composio/rube-mcp`
- The npm error message "Access token expired or revoked" is misleading -- it is actually a package-not-found error combined with npm auth state
- This is the PRIMARY cause of "token expired" errors in new sessions

### 2. Rube JWT has no `exp` claim but is rotated server-side
- Current token in `RUBE_TOKEN` env var: issued 2026-02-01 (`iat: 1770002508`)
- JWT payload: `{"userId":"user_01K8KBV1D9FCC1RBRX508TGSPD","orgId":"org_01K8KBV33H87VB4FYRTBCF492T","iat":1770002508}`
- No `exp` (expiration) claim in the JWT
- Rube/Composio can invalidate tokens server-side at any time with no client notification
- No documented token lifetime; likely rotated every few days or on certain events

### 3. Individual app OAuth tokens expire naturally
- Per-app OAuth tokens (Google, Slack, etc.) expire per OAuth spec (~1 hour)
- Composio auto-refreshes using refresh tokens
- Only marked EXPIRED after multiple refresh failures
- If the MCP connection itself is broken (cause #1), the refresh never triggers

## Auth Architecture (3 layers)

```
Layer 1: Rube JWT (RUBE_TOKEN)
  - Identifies YOU to the Rube MCP endpoint
  - Generated at rube.app dashboard or via CLI setup
  - Sent as Bearer token in Authorization header
  - No documented expiry; server-side rotation

Layer 2: Composio API Key (COMPOSIO_API_KEY)
  - Long-lived API key from platform.composio.dev/settings
  - Used to authenticate with Composio's platform
  - Does NOT expire like OAuth tokens
  - Can be used as X-API-Key header for MCP

Layer 3: Individual App OAuth Tokens
  - Per-app (Google, Slack, GitHub, etc.)
  - Managed entirely by Composio
  - Auto-refreshed server-side
  - You never touch these directly
```

## Current Config State

**Claude Desktop** (`~/Library/Application Support/Claude/claude_desktop_config.json`):
```json
"rube": {
  "command": "npx",
  "args": ["-y", "@jlowin/rube-mcp"]   // <-- BROKEN: package removed from npm
}
```

**Environment** (`~/.zshenv`):
```
export RUBE_TOKEN="eyJhbGciOiJIUzI1NiJ9..."   // JWT issued 2026-02-01
```

**mcporter** (`~/.mcporter/mcporter.json`):
- Contains same token as RUBE_TOKEN env var
- Has baseUrl `https://rube.app/mcp` and Bearer auth header

## Solutions (ranked)

### Solution 1: HTTP transport with Composio API key (BEST)
No npx, no npm, no stdio. Direct HTTP to Rube endpoint.

For Claude Code:
```bash
claude mcp add --transport http rube -s user "https://rube.app/mcp" --header "X-API-Key:YOUR_COMPOSIO_API_KEY"
```

For Claude Desktop config:
```json
"rube": {
  "type": "http",
  "url": "https://rube.app/mcp",
  "headers": {
    "X-API-Key": "YOUR_COMPOSIO_API_KEY"
  }
}
```

Get key from: https://platform.composio.dev/settings

### Solution 2: Update to the correct npm package
Replace `@jlowin/rube-mcp` with `@composio/mcp@latest`:

```json
"rube": {
  "command": "npx",
  "args": [
    "@composio/mcp@latest",
    "setup",
    "https://rube.app/mcp",
    "rube",
    "--client", "claude"
  ]
}
```

### Solution 3: Use the new rube-mcp-server installer
```bash
npx -y @composio/rube-mcp-server@latest install
```
Then restart Claude Desktop. This auto-configures everything.

### Solution 4: Generate fresh Rube token + fix package name
1. Go to https://rube.app, log in, generate new token
2. Update `~/.zshenv`: `export RUBE_TOKEN="new_token_here"`
3. Update Claude Desktop config to use `@composio/rube-mcp` instead of `@jlowin/rube-mcp`
4. Update `~/.mcporter/mcporter.json` Bearer token

### Solution 5: Cron job to refresh token (workaround)
If server-side rotation is the issue, a cron that calls `RUBE_MANAGE_CONNECTIONS` periodically could keep the session alive. Untested.

## Recommendation
Do Solution 1 (HTTP transport + Composio API key). It eliminates:
- npm package dependency (no more 404s)
- npx cold-start latency
- stdio transport flakiness
- JWT rotation issues (API key is more stable than JWT)

Then do Solution 3 as a second step to also fix the Claude Desktop integration.
