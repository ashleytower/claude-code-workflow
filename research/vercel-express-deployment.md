# Research: Vercel Express Serverless Deployment

*Researched on: 2026-01-09*

## Official Documentation

**Source**: [Express on Vercel](https://vercel.com/docs/frameworks/backend/express)
**Current Version**: Vercel CLI 47.0.5+ required
**Last Updated**: 2026
**Status**: ✓ Active

### Key Points
- Express apps deploy with **zero configuration**
- Becomes a single Vercel Function using Fluid Compute
- Automatic scaling based on traffic
- Prevents cold starts with active CPU billing
- Bundle size limit: 250MB
- **Vercel does NOT bundle code** (no Webpack/Rollup)

### Critical Requirements

1. **Export Method** (choose one):
   ```javascript
   // Option 1: Default export (REQUIRED for serverless)
   export default app

   // Option 2: Port listener
   app.listen(port)
   ```

2. **Static Assets**:
   - ❌ `express.static()` does NOT work on Vercel
   - ✅ Must use `public/` directory
   - Served via CDN automatically

3. **Error Handling**:
   - Express swallows errors → function undefined state
   - Must implement proper error middleware

### Breaking Changes
- Old pattern: Wrapping Express in handler function ❌
- New pattern: Export Express app directly ✓

## Boilerplates/Examples Found

### Option 1: Official Vercel Template
- **GitHub**: [Express on Vercel Template](https://vercel.com/templates/backend/express-js-on-vercel)
- **Stars**: N/A (official)
- **Last Updated**: 2026
- **Status**: ✓ Active
- **What it includes**: Basic Express setup, zero config
- **Pros**: Official, maintained by Vercel
- **Cons**: Minimal example

### Option 2: Community Examples
- **tRPC + Express**: Most examples use Next.js instead
- **GitHub**: [nexxeln/trpc-nextjs](https://github.com/nexxeln/trpc-nextjs)
- **Status**: ⚠ Next.js-focused, not standalone Express

### Recommendation
Use official Vercel pattern: export Express app directly as default export.

## Current Best Practices (2026)

### Pattern 1: Direct Export (CORRECT)
```javascript
// api/index.js
import express from 'express'
import { createExpressMiddleware } from '@trpc/server/adapters/express'

const app = express()

// Middleware
app.use(express.json())

// tRPC
app.use('/api/trpc', createExpressMiddleware({
  router: appRouter,
  createContext,
}))

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' })
})

// Export directly (NOT wrapped in handler)
export default app
```

**Why**: Vercel expects Express app as default export, wrapping breaks serverless lifecycle.

### Pattern 2: Error Handling
```javascript
// Error middleware
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).json({ error: 'Internal Server Error' })
})

export default app
```

**Why**: Prevents function from entering undefined state.

### Pattern 3: Database Connection
```javascript
// Singleton pattern for connection pooling
let db = null

async function getDb() {
  if (!db) {
    db = await createConnection()
  }
  return db
}

app.use(async (req, res, next) => {
  req.db = await getDb()
  next()
})
```

**Why**: Serverless functions reuse connections between invocations.

## Deprecated Patterns (DO NOT USE)

### Anti-Pattern 1: Handler Wrapper
```javascript
// BAD (don't do this!)
async function handler(req, res) {
  await someSetup()
  return app(req, res)
}
export default handler
```

**Why deprecated**: Breaks Vercel's Express integration, causes FUNCTION_INVOCATION_FAILED
**Use instead**: Export Express app directly

### Anti-Pattern 2: express.static()
```javascript
// BAD (doesn't work on Vercel!)
app.use(express.static('uploads'))
```

**Why deprecated**: Vercel doesn't support file system static serving
**Use instead**: Use `public/` directory or external storage (S3, Supabase Storage)

### Anti-Pattern 3: No Bundling for Complex Apps
```bash
# BAD for complex apps with many imports
# Deploying raw TypeScript without bundling
```

**Why problematic**: Vercel transpiles TS but doesn't resolve complex internal imports (like `../drizzle/schema.pg`)
**Use instead**: Bundle server code when you have complex import chains

**IMPORTANT**: Vercel doesn't bundle FOR you, but you CAN (and often SHOULD) bundle yourself for complex apps:
```bash
# GOOD - Bundle all server code together
esbuild api/index.ts --platform=node --bundle --format=esm --outfile=api/index.js --packages=external
```

Then update vercel.json to use the bundled .js file:
```json
{
  "functions": {
    "api/index.js": { "maxDuration": 60 }
  }
}
```

## Dependencies & Versions

| Package | Version | Status |
|---------|---------|--------|
| express | Latest | ✓ Compatible |
| @trpc/server | 11.x | ✓ Compatible |
| drizzle-orm | Latest | ✓ Compatible |
| postgres | Latest | ✓ Compatible |

## Community Insights

### Common Pain Points
- Confusion about export patterns (handler wrapper vs direct export)
- Static file serving with express.static()
- Database connection pooling in serverless
- Cold starts (solved with Fluid Compute)

### Recommended Approaches
- Export Express app directly
- Use Supabase/Neon for serverless-friendly databases
- Implement connection pooling
- Keep functions stateless

### Things to Avoid
- Wrapping Express in handler functions
- Using express.static() for file serving
- Manual bundling/transpilation
- Long-running background processes

## Code Examples (From Official Docs)

### Example 1: Basic Express + tRPC
```javascript
// api/index.js
import express from 'express'
import { createExpressMiddleware } from '@trpc/server/adapters/express'
import { appRouter } from '../server/routers'

const app = express()

app.use(express.json())

app.use('/api/trpc', createExpressMiddleware({
  router: appRouter,
  createContext: () => ({}),
}))

export default app
```

### Example 2: With Database
```javascript
// api/index.js
import express from 'express'
import { initDb } from '../server/db'

const app = express()

let dbInitialized = false

app.use(async (req, res, next) => {
  if (!dbInitialized) {
    await initDb()
    dbInitialized = true
  }
  next()
})

export default app
```

## Ready-to-Use Checklist

- [x] Official docs reviewed
- [x] Latest version confirmed (CLI 47.0.5+)
- [x] Best practices documented
- [x] Deprecated patterns identified
- [x] Dependencies verified as current
- [x] Code examples available

## Notes

### Important Limitations
- Bundle size: 250MB max
- No manual bundling needed/wanted
- Static files must be in `public/`
- Functions are stateless between requests
- Connection pooling essential for databases

### Vercel vs Traditional Hosting
- ✓ Auto-scaling
- ✓ Zero cold starts (Fluid Compute)
- ✓ CDN for static files
- ❌ No long-running background jobs
- ❌ No persistent file system
- ❌ Limited to 60s max execution (Pro plan)

### When NOT to Use Vercel
- Long-running batch jobs
- WebSocket servers (use Supabase Realtime instead)
- Large file uploads (>4.5MB, use direct S3)
- Background workers (use external queue)

## Sources

- [Express on Vercel](https://vercel.com/docs/frameworks/backend/express)
- [Vercel Functions](https://vercel.com/docs/functions)
- [Using Express with Vercel](https://examples.vercel.com/kb/guide/using-express-with-vercel)
- [tRPC Fetch Adapter](https://trpc.io/docs/server/adapters/fetch)
- [Deploy Express to Vercel](https://syntackle.com/blog/how-to-create-and-deploy-an-express-js-app-to-vercel-ljgvGrsCH7ioHsAxuw3G/)
