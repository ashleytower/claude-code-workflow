# Vercel Express + tRPC Serverless Deployment

**Purpose**: Deploy Express + tRPC apps to Vercel serverless functions using Build Output API v3.

**Last Updated**: 2026-01-09
**Status**: ✅ Production-tested

## When to Use

- Express apps with tRPC
- Apps with complex internal imports (`server/`, `drizzle/`, etc.)
- PostgreSQL/Supabase backend
- Need serverless scaling

## Prerequisites

- Express app exports directly: `export default app`
- TypeScript source in `api/` directory
- Database connection string (Supabase/PostgreSQL)

## CRITICAL: Use CommonJS Format

**Why**: Express and its dependencies (body-parser, depd, etc.) use dynamic `require()` calls that break in ESM bundles on Vercel serverless.

**Solution**: Bundle to CommonJS (`.cjs`) format instead of ESM (`.js`).

## Build Output API v3 Structure

Vercel's Build Output API v3 requires this directory structure:

```
.vercel/output/
  ├── config.json              # Routes and configuration
  ├── static/                  # Static files (frontend)
  └── functions/
      └── api.func/           # Serverless function
          ├── index.cjs       # CommonJS bundle
          └── .vc-config.json # Function configuration
```

## package.json Build Script

```json
{
  "scripts": {
    "build": "vite build && mkdir -p .vercel/output/functions/api.func && esbuild api/server.ts --platform=node --bundle --format=cjs --outfile=.vercel/output/functions/api.func/index.cjs && echo '{\"runtime\":\"nodejs24.x\",\"handler\":\"index.cjs\",\"launcherType\":\"Nodejs\"}' > .vercel/output/functions/api.func/.vc-config.json"
  }
}
```

**Breakdown**:
1. `vite build` - Builds React frontend to `dist/public`
2. `mkdir -p .vercel/output/functions/api.func` - Creates function directory
3. `esbuild api/server.ts --platform=node --bundle --format=cjs --outfile=.vercel/output/functions/api.func/index.cjs` - Bundles Express app as CommonJS
4. Creates `.vc-config.json` with Node.js 24 runtime config

**Key Points**:
- Use `--format=cjs` NOT `--format=esm`
- NO `--packages=external` - bundles ALL internal code
- Node.js built-ins are automatically external in CommonJS
- Output to `.vercel/output/functions/api.func/index.cjs`

## vercel.json Configuration

```json
{
  "buildCommand": "npm run build && mkdir -p .vercel/output/static && cp -r dist/public/* .vercel/output/static/ && echo '{\"version\":3,\"routes\":[{\"src\":\"/api/(.*)\",\"dest\":\"/api\"},{\"src\":\"/uploads/(.*)\",\"dest\":\"/api\"}]}' > .vercel/output/config.json"
}
```

**Breakdown**:
1. `npm run build` - Runs the build script above
2. `mkdir -p .vercel/output/static` - Creates static files directory
3. `cp -r dist/public/* .vercel/output/static/` - Copies frontend to static
4. Creates `.vercel/output/config.json` with version 3 and routing rules

**Important**: The `buildCommand` in vercel.json runs AFTER the `build` script in package.json.

## File Structure

```
/api
  /server.ts          # Express app source (exports default app)
/server
  /routers.ts         # tRPC routers
  /db.ts              # Database functions
  /_core              # Core utilities (LLM, auth, etc.)
/drizzle
  /schema.pg.ts       # Database schema
/client
  /src/...            # React frontend
/dist
  /public/...         # Built frontend (created by vite build)
/.vercel/output       # Build Output API v3 structure (created by build)
  /config.json        # Routes configuration
  /static/...         # Static frontend files
  /functions/
    /api.func/
      /index.cjs      # Bundled CommonJS function
      /.vc-config.json
/vercel.json          # Vercel configuration
/package.json         # Build scripts
```

## Express App Pattern (api/server.ts)

```typescript
import express from "express";
import { createExpressMiddleware } from "@trpc/server/adapters/express";
import { appRouter } from "../server/routers";
import { createContext } from "../server/_core/context";
import { initDb } from "../server/db";

const app = express();

// Database initialization (singleton pattern for cold starts)
let dbInitialized = false;
async function ensureDb() {
  if (!dbInitialized) {
    await initDb();
    dbInitialized = true;
    console.log("[Database] PostgreSQL initialized");
  }
}

// Middleware
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));

// Health check (simple, no database)
app.get("/api/ping", (req, res) => {
  res.json({ status: "ok", message: "pong" });
});

// Health check with database
app.get("/api/health", async (req, res) => {
  try {
    await ensureDb();
    res.json({ status: "ok", database: "connected" });
  } catch (error: any) {
    console.error("[Health] Error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
});

// tRPC with database initialization
app.use(
  "/api/trpc",
  async (req, res, next) => {
    await ensureDb();
    next();
  },
  createExpressMiddleware({
    router: appRouter,
    createContext,
  })
);

// CRITICAL: Export Express app directly (not wrapped in handler)
export default app;
```

**Key Patterns**:
- Singleton database initialization (runs once per cold start)
- Health check endpoints for testing
- Database initialization middleware for tRPC routes
- Direct export of Express app (Vercel handles the wrapping)

## Environment Variables via Rube MCP

**Use Rube MCP tools instead of CLI for managing Vercel environment variables:**

### 1. List Projects
```typescript
RUBE_SEARCH_TOOLS: "list Vercel projects"
RUBE_MULTI_EXECUTE_TOOL: {
  tool_slug: "VERCEL_GET_PROJECTS",
  arguments: { search: "project-name" }
}
```

### 2. List Current Environment Variables
```typescript
RUBE_MULTI_EXECUTE_TOOL: {
  tool_slug: "VERCEL_GET_PROJECTS",
  arguments: { search: "project-name" }
}
// Response includes env var IDs
```

### 3. Get Supabase Connection String
```typescript
RUBE_MULTI_EXECUTE_TOOL: [
  {
    tool_slug: "SUPABASE_LIST_ALL_PROJECTS",
    arguments: {}
  },
  {
    tool_slug: "SUPABASE_GET_PROJECT_S_PGBOUNCER_CONFIG",
    arguments: { ref: "project-ref" }
  }
]
```

### 4. Update Environment Variable
```typescript
RUBE_MULTI_EXECUTE_TOOL: {
  tool_slug: "VERCEL_EDIT_PROJECT_ENV",
  arguments: {
    idOrName: "project-name",
    envId: "env_id_from_list",
    key: "DATABASE_URL",
    value: "postgres://...",
    type: "encrypted",
    target: ["production", "preview", "development"]
  }
}
```

**Benefits**:
- No need to install Vercel CLI
- Programmatic access
- Can be automated in workflows
- Memory system tracks connections

## Deployment Checklist

1. ✅ Build script outputs to `.vercel/output/functions/api.func/index.cjs`
2. ✅ Build script creates `.vc-config.json` with Node.js 24 runtime
3. ✅ vercel.json copies frontend to `.vercel/output/static/`
4. ✅ vercel.json creates `.vercel/output/config.json` with routes
5. ✅ Environment variables set via Rube MCP
6. ✅ Express app exports directly (`export default app`)
7. ✅ Database initialization uses singleton pattern
8. ✅ Health check endpoints exist for testing

## Testing Deployment

```bash
# Test simple endpoint
curl https://your-app.vercel.app/api/ping
# Expected: {"status":"ok","message":"pong"}

# Test database connection
curl https://your-app.vercel.app/api/health
# Expected: {"status":"ok","database":"connected"}

# Test tRPC endpoint
curl https://your-app.vercel.app/api/trpc/yourProcedure
```

## Common Pitfalls & Solutions

### ❌ Problem: "Dynamic require of 'path' is not supported"
**Cause**: Using ESM format (`--format=esm`) with Express dependencies that use dynamic requires
**Solution**: Use CommonJS format (`--format=cjs`) and output to `.cjs` file

### ❌ Problem: "Cannot find module '/var/task/server/routers'"
**Cause**: Using `--packages=external` which prevents internal code from bundling
**Solution**: Remove `--packages=external` - esbuild will bundle internal code and keep node_modules external automatically

### ❌ Problem: "NOT_FOUND" for all /api routes
**Cause**: Function not properly configured in Build Output API v3 structure
**Solution**: Use `.vercel/output/functions/api.func/` directory structure with proper `.vc-config.json`

### ❌ Problem: "conflicting_file_path" error
**Cause**: Both `api/index.js` and `api/index.cjs` exist
**Solution**: Delete old `.js` file, only keep `.cjs` version

### ❌ Problem: "unused_function" error
**Cause**: vercel.json references function before it's built
**Solution**: Use Build Output API v3 - build creates the function, vercel.json just configures routes

### ❌ Problem: Environment variable changes not taking effect
**Cause**: Vercel doesn't auto-redeploy on env var changes
**Solution**: Trigger redeploy with empty commit: `git commit --allow-empty -m "chore: trigger redeploy" && git push`

### ❌ Problem: Handler wrapper anti-pattern
**Wrong**:
```typescript
export default async function handler(req, res) {
  await ensureDb();
  return app(req, res);
}
```
**Correct**:
```typescript
export default app;
```
**Reason**: Vercel's Express adapter expects the Express app directly, not wrapped

## Verification Steps

1. **Local Build Test**:
```bash
npm run build
ls -la .vercel/output/functions/api.func/
# Should show: index.cjs and .vc-config.json
```

2. **Check Bundle Size**:
```bash
du -h .vercel/output/functions/api.func/index.cjs
# Typical: 3-4 MB for Express + tRPC + dependencies
```

3. **Verify CommonJS Export**:
```bash
grep -n "module\.exports" .vercel/output/functions/api.func/index.cjs
# Should show: module.exports = __toCommonJS(...)
```

4. **Test After Deployment**:
```bash
# Test ping
curl https://your-app.vercel.app/api/ping

# Test health check
curl https://your-app.vercel.app/api/health

# Check logs via Rube MCP
RUBE_MULTI_EXECUTE_TOOL: {
  tool_slug: "VERCEL_GET_DEPLOYMENT_LOGS",
  arguments: { idOrUrl: "dpl_..." }
}
```

## Performance Notes

- **Cold Start**: ~1-2 seconds (includes database connection)
- **Warm Start**: ~50-200ms
- **Bundle Size**: 3.9 MB (typical for Express + tRPC + PostgreSQL)
- **Memory**: 1024 MB default (configurable in .vc-config.json)
- **Timeout**: 60 seconds default (configurable in .vc-config.json)

## Migration Path

**From Legacy Vercel (api/ auto-detection) → Build Output API v3**:

1. Update package.json build script to output to `.vercel/output/functions/api.func/`
2. Change format from `esm` to `cjs`
3. Update vercel.json to use `buildCommand` with Build Output API v3 structure
4. Remove `outputDirectory` and `functions` config from vercel.json
5. Test locally: `npm run build && ls -la .vercel/output/`
6. Deploy and test: `curl https://your-app.vercel.app/api/health`

## Troubleshooting

### View Deployment Logs
```typescript
// Via Rube MCP
RUBE_MULTI_EXECUTE_TOOL: {
  tool_slug: "VERCEL_GET_DEPLOYMENTS",
  arguments: { projectId: "project-name", limit: 1 }
}

// Then get logs
RUBE_MULTI_EXECUTE_TOOL: {
  tool_slug: "VERCEL_GET_DEPLOYMENT_LOGS",
  arguments: { idOrUrl: "dpl_..." }
}
```

### Check Function Configuration
```bash
# Verify .vc-config.json exists and is valid
cat .vercel/output/functions/api.func/.vc-config.json
# Expected: {"runtime":"nodejs24.x","handler":"index.cjs","launcherType":"Nodejs"}
```

### Debug Database Connection
Add verbose logging to `ensureDb()`:
```typescript
async function ensureDb() {
  if (!dbInitialized) {
    console.log("[Database] Connecting to:", process.env.DATABASE_URL?.replace(/:[^:]*@/, ':***@'));
    await initDb();
    dbInitialized = true;
    console.log("[Database] PostgreSQL initialized successfully");
  }
}
```

## Related Skills

- **Database**: See `~/.claude/skills/supabase-postgres.md`
- **Authentication**: See `~/.claude/skills/auth.md`
- **Environment Vars**: Use Rube MCP tools (documented above)

## Updates

- 2026-01-09: Initial skill based on invoice-app-fresh deployment
  - CommonJS format requirement discovered
  - Build Output API v3 structure documented
  - Rube MCP integration for env vars
  - Handler wrapper anti-pattern documented
  - All common pitfalls documented with solutions

---

**Philosophy**: This skill captures the actual working solution after extensive debugging. The key insights are:
1. CommonJS format is mandatory for Express on Vercel
2. Build Output API v3 requires specific directory structure
3. Rube MCP provides better workflow than CLI
4. Direct Express export (no wrapper) is required
