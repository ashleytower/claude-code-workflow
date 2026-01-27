---
name: vercel-supabase-migration
category: deployment
frameworks: [express, nextjs, react]
last_updated: 2026-01-09
version: vercel-latest, supabase-latest
---

# Express + SQLite → Vercel + Supabase Migration

## Quick Start

**Framework Detection**: Detects Express + SQLite projects and provides migration path to Vercel serverless + Supabase PostgreSQL.

**When to use**:
- Migrating Express API to serverless
- Moving from SQLite to PostgreSQL
- Deploying to Vercel for free tier / autoscale
- Need unlimited database scale

**When NOT to use**:
- MVP/prototype stage (use Railway/Render instead)
- Small user base (<100 users) (SQLite is fine)
- Already working on Vercel (no migration needed)

## Installation

### Remove (Express + SQLite)
```bash
# These packages are NOT needed on Vercel
npm uninstall express better-sqlite3
```

### Add (Vercel + Supabase)
```bash
# Vercel serverless
npm install @vercel/node

# PostgreSQL client (Supabase compatible)
npm install postgres
npm install -D @types/pg

# Drizzle ORM (update if needed)
npm install drizzle-orm@latest
```

## Environment Variables

### Supabase Auth (instead of custom Google OAuth)
```env
# Supabase Project (from Supabase dashboard → Settings → API)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key  # Server-side only

# Database (from Supabase dashboard → Settings → Database)
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:6543/postgres
```

**Why use Supabase Auth vs custom Google OAuth:**
- ✅ Security: Asymmetric JWT signing (RS256/ES256), built-in RLS
- ✅ Simpler: No manual token management, auto-refresh
- ✅ Multi-provider: Google, GitHub, Apple, etc. - one interface
- ✅ Free tier: 50,000 MAUs (custom OAuth = more infrastructure)
- Source: [Supabase Auth Docs](https://supabase.com/docs/guides/auth)

### Supabase Storage (instead of AWS S3)
```env
# Storage is built-in - no additional env vars needed!
# Access via same Supabase client using buckets
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# Remove these (no longer needed)
# DATABASE_URL=file:./local.db  # SQLite
```

## Migration Steps

### Step 1: Database Schema Migration (1-2 days)

**Convert schema from SQLite to PostgreSQL**

```typescript
// BEFORE: drizzle/schema.ts (SQLite)
import { sqliteTable, text, integer, real } from "drizzle-orm/sqlite-core";

export const invoices = sqliteTable("invoices", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  userId: integer("user_id").notNull(),
  totalAmount: text("total_amount"),  // SQLite stores money as text!
  createdAt: integer("created_at", { mode: "timestamp" }),  // Unix timestamp
  isActive: integer("is_active", { mode: "boolean" }),  // 0 or 1
});

// AFTER: drizzle/schema.ts (PostgreSQL)
import { pgTable, serial, integer, decimal, timestamp, boolean } from "drizzle-orm/pg-core";

export const invoices = pgTable("invoices", {
  id: serial("id").primaryKey(),  // auto-increment
  userId: integer("user_id").notNull(),
  totalAmount: decimal("total_amount", { precision: 10, scale: 2 }),  // Native decimal
  createdAt: timestamp("created_at").defaultNow(),  // Native timestamp
  isActive: boolean("is_active").default(false),  // Native boolean
});
```

**Data Type Mapping**:
| SQLite | PostgreSQL | Notes |
|--------|------------|-------|
| `text` (money) | `decimal(10, 2)` | SQLite stores money as strings |
| `integer` (timestamp) | `timestamp` | SQLite uses Unix epochs |
| `integer` (boolean) | `boolean` | SQLite uses 0/1 |
| `real` | `decimal` or `float` | Use decimal for money |
| `text` | `text` or `varchar(n)` | Text works the same |

**Update Drizzle config**:

```typescript
// drizzle.config.ts
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./drizzle/schema.ts",
  out: "./drizzle/migrations",
  dialect: "postgresql",  // Changed from "sqlite"
  dbCredentials: {
    url: process.env.DATABASE_URL!,  // Supabase connection string
  },
});
```

**Generate and push schema**:

```bash
# Generate PostgreSQL migration
npx drizzle-kit generate

# Review migration SQL files in drizzle/migrations/

# Push to Supabase
npx drizzle-kit push
```

### Step 2: Database Connection Update (1 hour)

```typescript
// BEFORE: server/db.ts (SQLite)
import Database from "better-sqlite3";
import { drizzle } from "drizzle-orm/better-sqlite3";

const sqlite = new Database("local.db");
export const db = drizzle(sqlite);

// AFTER: server/db.ts (PostgreSQL)
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";

const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error("DATABASE_URL not set");

const client = postgres(connectionString);
export const db = drizzle(client);
```

**Most queries work as-is** - Drizzle abstracts the differences!

### Step 3: Express → Vercel Functions (2-3 days)

**Option A: Keep Express (Easier)**

Create `api/index.ts`:

```typescript
// api/index.ts - Vercel entry point
import express from "express";
import { createExpressMiddleware } from "@trpc/server/adapters/express";
import { appRouter } from "../server/routers";
import { createContext } from "../server/context";

const app = express();

app.use(
  "/trpc",
  createExpressMiddleware({
    router: appRouter,
    createContext,
  })
);

// Export for Vercel
export default app;
```

**Vercel config** (`vercel.json`):

```json
{
  "version": 2,
  "builds": [
    {
      "src": "api/index.ts",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/trpc/(.*)",
      "dest": "/api/index.ts"
    }
  ],
  "functions": {
    "api/index.ts": {
      "maxDuration": 60
    }
  }
}
```

**Option B: Pure Vercel Functions (More work)**

Split each tRPC router into separate function:

```typescript
// api/trpc/[trpc].ts
import { fetchRequestHandler } from "@trpc/server/adapters/fetch";
import { appRouter } from "../../server/routers";
import { createContext } from "../../server/context";

export const config = {
  runtime: "edge",
  maxDuration: 60,
};

export default async function handler(req: Request) {
  return fetchRequestHandler({
    endpoint: "/api/trpc",
    req,
    router: appRouter,
    createContext,
  });
}
```

### Step 4: Critical Async Operations Fix

**CRITICAL**: Serverless functions terminate after response. All async operations MUST be awaited!

```typescript
// BAD (works locally, FAILS on Vercel)
async function processInvoice(invoiceId: number) {
  const invoice = await getInvoiceById(invoiceId);

  // This will NOT execute on Vercel!
  syncToSheets(invoice);  // No await

  return { success: true };
}

// GOOD (works everywhere)
async function processInvoice(invoiceId: number) {
  const invoice = await getInvoiceById(invoiceId);

  // MUST await
  await syncToSheets(invoice);

  return { success: true };
}

// ALTERNATIVE: Use Vercel's waitUntil for background tasks
import { waitUntil } from "@vercel/functions";

async function processInvoice(invoiceId: number) {
  const invoice = await getInvoiceById(invoiceId);

  // Runs after response sent
  waitUntil(syncToSheets(invoice));

  return { success: true };
}
```

**Audit ALL async operations in your codebase** - search for promises without `await`.

### Step 5: Data Migration (1 day)

**Export from SQLite**:

```bash
# Export to JSON
sqlite3 local.db <<EOF
.mode json
.once invoices.json
SELECT * FROM invoices;
.once statements.json
SELECT * FROM statements;
EOF
```

**Transform data** (timestamps, decimals):

```typescript
// transform-data.ts
import fs from "fs";

const invoices = JSON.parse(fs.readFileSync("invoices.json", "utf-8"));

const transformed = invoices.map((inv: any) => ({
  ...inv,
  // Convert Unix timestamp to ISO string
  createdAt: new Date(inv.createdAt * 1000).toISOString(),
  // Convert text amount to decimal
  totalAmount: parseFloat(inv.totalAmount),
  // Convert 0/1 to boolean
  isActive: Boolean(inv.isActive),
}));

fs.writeFileSync("invoices-transformed.json", JSON.stringify(transformed, null, 2));
```

**Import to Supabase**:

```bash
# Use Supabase SQL Editor or psql
psql $DATABASE_URL <<EOF
COPY invoices(id, user_id, total_amount, created_at, is_active)
FROM '/path/to/invoices-transformed.json'
WITH (FORMAT json);
EOF
```

### Step 6: Testing (1 day)

```typescript
// Update test database connection
// tests/setup.ts
import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";

const testConnectionString = process.env.TEST_DATABASE_URL;
const client = postgres(testConnectionString);
export const testDb = drizzle(client);
```

**Test all database functions** - most should work without changes due to Drizzle ORM abstraction.

### Step 7: Deploy to Vercel (1 hour)

```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Set environment variables
vercel env add DATABASE_URL production
# Paste Supabase connection string

vercel env add GOOGLE_API_KEY production
# Add all other env vars

# Deploy
vercel --prod
```

## Common Use Cases

### Use Case 1: Keep Express + tRPC monolith
**Best for**: Faster migration, existing Express middleware

```typescript
// api/index.ts
import app from "../server/index";  // Your Express app
export default app;
```

### Use Case 2: Split into Vercel Functions
**Best for**: Better cold start times, smaller bundles

```typescript
// api/trpc/[trpc].ts - One function for all tRPC
// api/health.ts - Separate health check function
// api/webhooks/stripe.ts - Webhook handler
```

### Use Case 3: Hybrid (Recommended)
**Best for**: Balance between simplicity and performance

```typescript
// api/trpc/[trpc].ts - Main tRPC router
// api/webhooks/[...path].ts - Webhooks (need different timeout)
// api/cron/[...path].ts - Background jobs
```

## Gotchas

### 1. Cold Starts
**Issue**: First request after inactivity takes 1-3 seconds

**Solutions**:
- Use Vercel Pro for fewer cold starts
- Split large bundles
- Use edge runtime where possible
- Accept trade-off (free tier limitation)

### 2. Timeout Limits
**Issue**: Free tier = 10s, Pro = 60s max

**Solutions**:
- Optimize slow operations (OCR, reconciliation)
- Move long tasks to background jobs (Vercel Cron, Inngest)
- Split into multiple requests
- Use streaming responses

### 3. File System Access
**Issue**: Vercel functions are stateless, no persistent file storage

**Solutions**:
- Use S3/R2 for file storage (already doing this ✓)
- Don't rely on local file system
- Database is persistent (Supabase)

### 4. WebSocket Connections
**Issue**: Vercel doesn't support long-lived WebSocket connections

**Solutions**:
- Use Supabase Realtime for live updates
- Use Server-Sent Events (SSE)
- Or deploy WebSocket server separately (Railway)

### 5. Database Connection Pooling
**Issue**: Serverless creates many connections

**Solutions**:
- Supabase includes connection pooling (port 6543)
- Use connection string with `?pgbouncer=true`
- Or use `@neondatabase/serverless` for edge functions

```typescript
// Use Supabase connection pooler
const connectionString = process.env.DATABASE_URL?.replace(
  ":5432",
  ":6543"  // Connection pooler port
);
```

### 6. Tables Don't Exist After Schema Migration
**Issue**: OAuth/Database errors like `_DrizzleQueryError: Failed query: select ... from "users"` even though schema files exist

**Root Cause**: Schema files (e.g., `drizzle/schema.pg.ts`) define structure but DON'T create tables. Must run migrations!

**Diagnosis**:
```bash
# Check Vercel Runtime Logs → Look for:
# [Database] Failed to upsert user: _DrizzleQueryError
# This means tables don't exist in the database!

# Check if migrations exist
ls drizzle/migrations/*.sql  # If empty, no migrations created

# Verify DATABASE_URL is set
vercel env pull .env.local --environment production
grep DATABASE_URL .env.local
```

**Solution**:
```bash
# Link to Vercel project first
vercel link --project your-project-name --yes

# Pull production env vars (development may have different/invalid credentials)
vercel env pull .env.local --environment production --yes

# Export and push schema
export $(grep -v '^#' .env.local | xargs)
npx drizzle-kit push
```

### 7. Pooler vs Direct Connection for Migrations
**Issue**: `password authentication failed for user "postgres"` when running `drizzle-kit push`

**Root Cause**: Supabase pooler connection (pooler.supabase.com) may fail for DDL operations like CREATE TABLE

**Solution**: Use direct connection for migrations:
```bash
# Pooler (for app runtime - handles connection pooling)
DATABASE_URL=postgresql://postgres.[ref]:[password]@aws-1-us-east-1.pooler.supabase.com:5432/postgres

# Direct (for migrations - required for DDL)
DATABASE_URL=postgresql://postgres.[ref]:[password]@db.[ref].supabase.co:5432/postgres
```

**Get direct connection from Supabase Dashboard**:
1. Go to Project Settings → Database
2. Copy "Direct connection" string (NOT "Connection pooling")
3. Use for `drizzle-kit push` and migrations

### 8. Vercel Environment Variables Mismatch
**Issue**: Development env vars may be empty or have invalid credentials

**Diagnosis**:
```bash
# Pull development (default)
vercel env pull .env.local
# May only have VERCEL_OIDC_TOKEN!

# Pull production (has real credentials)
vercel env pull .env.local --environment production --yes
# Now has DATABASE_URL, JWT_SECRET, etc.
```

**Best Practice**: Always pull production env vars when debugging database issues

## Testing

### Local Development

```bash
# Use Supabase local dev
npx supabase init
npx supabase start

# Point to local Supabase
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres

# Run dev server
npm run dev

# Test with Vercel CLI
vercel dev
```

### Test Migration Without Breaking Production

```bash
# Create staging environment on Vercel
vercel --prod --scope=staging

# Deploy to staging first
vercel deploy --target=staging

# Test thoroughly
# If good, promote to production
vercel promote
```

## Updates

- **2026-01-26**: Added learnings from Supabase Site URL mismatch debugging
  - **CRITICAL**: When deploying to a new Vercel domain, update Supabase Auth → URL Configuration
  - `site_url` must match your production domain (OAuth redirects use this)
  - `uri_allow_list` must include your production domain pattern (e.g., `https://your-app.vercel.app/**`)
  - Use Rube MCP `SUPABASE_UPDATE_PROJECT_AUTH_CONFIG` to update these programmatically
  - Symptom: "Failed to save settings: Please login (10001)" after successful OAuth
  - Root cause: OAuth redirects to old domain, cookies don't transfer to new domain

- **2026-01-26**: Supabase password confusion (Supavisor pooler)
  - Supabase has TWO different passwords: **Database password** vs **Shared pooler password**
  - For Supavisor connection strings, use the **Database password** (not shared pooler password)
  - Connection string format: `postgresql://postgres.[ref]:[DATABASE_PASSWORD]@aws-1-us-east-1.pooler.supabase.com:5432/postgres`
  - If you get "password authentication failed", you're likely using the wrong password
  - Find Database password in: Supabase Dashboard → Project Settings → Database → Connection string → Copy password

- **2026-01-09**: Added learnings from debugging production OAuth failure
  - Tables must be created with `drizzle-kit push` (schema files don't create them!)
  - Pooler connection may fail for DDL operations - use direct connection
  - `vercel env pull --environment production` to get real credentials
  - Diagnostic flow: Vercel Runtime Logs → Drizzle errors → Check tables exist
  - Common error: "password authentication failed" = wrong connection type

- **2026-01-08**: Created skill from invoice app migration research
  - Comprehensive SQLite → PostgreSQL conversion
  - Express → Vercel serverless patterns
  - Async operation fixes for serverless
  - Data migration scripts
  - Gotchas from real migration planning

## Alternative: Railway/Render (No Migration Needed)

**If you want to deploy faster without migration**:

```bash
# Railway (keeps Express + SQLite)
railway init
railway up

# Render (keeps Express + SQLite)
# Just add render.yaml and deploy
```

**When to use Railway/Render instead**:
- MVP stage (need to ship fast)
- Small user base
- SQLite is sufficient (<10k records/user)
- Want to avoid migration complexity
- Can migrate to Vercel later

**Migration path**: Railway → Production → Profit → Vercel when needed

---

## Summary

**Migration Timeline**: 8-10 days for complete migration
**Difficulty**: Medium-High
**Risk**: Medium (breaking changes possible)

**Recommendation**:
- For MVP: Use Railway/Render (no migration)
- For scale: Use this skill to migrate to Vercel + Supabase

**Trade-offs**:
- Railway: Faster to deploy, costs $20-50/month, SQLite limits
- Vercel: More setup, free tier, unlimited scale

Choose based on: MVP speed vs long-term scale needs.
