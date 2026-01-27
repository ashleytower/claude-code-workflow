---
name: supabase-google-oauth
category: auth
frameworks: [react, nextjs, express]
last_updated: 2026-01-19
version: supabase-latest
---

# Supabase Google OAuth Debugging

## Quick Reference

**When to use**: Debugging Google OAuth sign-in issues with Supabase Auth

**Common symptoms**:
- OAuth redirects to wrong callback URL
- `bad_oauth_state` errors
- User lands on login screen after OAuth completes
- Database query errors during OAuth callback
- RLS policy blocking user queries

## Environment Variables

### Client-side (Vite/React)
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### Server-side
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Database - Use Supavisor for serverless!
DATABASE_URL=postgresql://postgres.[ref]:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require
```

## Identifying Auth System in Use

**Check the OAuth redirect_uri in browser URL bar during sign-in:**

```
# Supabase Auth (correct)
redirect_uri=https://your-project.supabase.co/auth/v1/callback

# Legacy OAuth (wrong - goes to your app's callback)
redirect_uri=https://your-app.vercel.app/api/oauth/callback
```

**Check Google consent screen title:**
- Shows `your-project.supabase.co` = Supabase Auth
- Shows your app domain = Legacy OAuth

## Setup Code

### Client: Supabase Detection
```typescript
// lib/supabase.ts
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const isSupabaseConfigured = () =>
  Boolean(supabaseUrl && supabaseAnonKey);

export const supabase = isSupabaseConfigured()
  ? createClient(supabaseUrl!, supabaseAnonKey!)
  : null;
```

### Client: Error Handler (CRITICAL)
```typescript
// main.tsx - Prevent redirect loop to legacy OAuth
import { isSupabaseConfigured } from "@/lib/supabase";
import { UNAUTHED_ERR_MSG } from "@shared/const";
import { TRPCClientError } from "@trpc/client";

const redirectToLoginIfUnauthorized = (error: unknown) => {
  if (!(error instanceof TRPCClientError)) return;
  if (typeof window === "undefined") return;

  const isUnauthorized = error.message === UNAUTHED_ERR_MSG;
  if (!isUnauthorized) return;

  // CRITICAL: If Supabase is configured, let auth hook handle it
  // via login screen (using Supabase Auth)
  if (isSupabaseConfigured()) return;

  // Only use legacy OAuth redirect if Supabase is NOT configured
  window.location.href = getLoginUrl();
};
```

### Client: Sign-in with Google
```typescript
// components/LoginScreen.tsx
import { supabase } from "@/lib/supabase";

const handleGoogleSignIn = async () => {
  const { error } = await supabase!.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: window.location.origin,
      scopes: "email profile", // Add more scopes as needed
    },
  });
  if (error) console.error("OAuth error:", error);
};
```

### Server: Supabase Client
```typescript
// server/_core/supabase.ts
import { createClient, SupabaseClient } from "@supabase/supabase-js";

export const isSupabaseConfigured = () =>
  Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_ANON_KEY);

const PLACEHOLDER_URL = "https://placeholder.supabase.co";
const PLACEHOLDER_KEY = "placeholder-key";

// Admin client (bypasses RLS) - for server-side operations
export const supabaseAdmin: SupabaseClient =
  process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY
    ? createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
        auth: { autoRefreshToken: false, persistSession: false },
      })
    : createClient(PLACEHOLDER_URL, PLACEHOLDER_KEY);

// Regular client (respects RLS)
export const supabase: SupabaseClient =
  process.env.SUPABASE_URL && process.env.SUPABASE_ANON_KEY
    ? createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY, {
        auth: { autoRefreshToken: false, persistSession: false },
      })
    : createClient(PLACEHOLDER_URL, PLACEHOLDER_KEY);
```

## Common Issues & Fixes

### 1. `bad_oauth_state` Error

**Symptom**: After OAuth consent, redirected with `?error=invalid_request&error_code=bad_oauth_state`

**Cause**: Stale OAuth state from previous session or browser cache

**Fix**:
1. Clear browser cookies for your app domain
2. Clear Supabase auth state: `supabase.auth.signOut()`
3. Start fresh OAuth flow from login screen
4. Do NOT reuse old OAuth URLs - always start from "Sign in with Google" button

### 2. OAuth Redirects to Legacy Callback

**Symptom**: OAuth goes to `/api/oauth/callback` instead of Supabase

**Cause**: Client error handler redirecting to legacy OAuth URL

**Fix**: Add `isSupabaseConfigured()` check before redirect (see Error Handler code above)

**Diagnosis**:
```javascript
// Check in browser console
console.log('VITE_SUPABASE_URL:', import.meta.env.VITE_SUPABASE_URL);
console.log('VITE_SUPABASE_ANON_KEY:', import.meta.env.VITE_SUPABASE_ANON_KEY);
```

### 3. RLS Policies Blocking Queries

**Symptom**: Database queries fail with permission errors after successful OAuth

**Cause**: Row Level Security policies too restrictive

**Diagnosis**:
```sql
-- Check existing policies
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies
WHERE tablename IN ('users', 'invoices', 'statements');
```

**Fix**: Drop overly restrictive policies or use service role for server operations
```sql
-- Drop restrictive policy
DROP POLICY IF EXISTS "policy_name" ON table_name;

-- Or create permissive policy
CREATE POLICY "allow_authenticated" ON users
  FOR ALL
  TO authenticated
  USING (true);
```

### 4. Supavisor Connection String Issues

**Symptom**: Database connection fails in production serverless environment

**Cause**: Using direct connection instead of Supavisor pooler

**Fix**: Use Supavisor connection string (port 6543, pooler.supabase.com):
```
# Wrong (direct connection - fails in serverless)
postgresql://postgres.[ref]:[pw]@db.[ref].supabase.co:5432/postgres

# Correct (Supavisor pooler - works in serverless)
postgresql://postgres.[ref]:[pw]@aws-0-us-east-1.pooler.supabase.com:6543/postgres?sslmode=require
```

### 5. User Session Not Persisting

**Symptom**: User authenticated but appears logged out on page refresh

**Cause**: Session not being checked on app load

**Fix**: Add auth state listener
```typescript
// App.tsx or auth hook
useEffect(() => {
  const { data: { subscription } } = supabase!.auth.onAuthStateChange(
    (event, session) => {
      if (session) {
        setUser(session.user);
      } else {
        setUser(null);
      }
    }
  );

  // Check existing session on mount
  supabase!.auth.getSession().then(({ data: { session } }) => {
    if (session) setUser(session.user);
  });

  return () => subscription.unsubscribe();
}, []);
```

## Debugging Flow

1. **Check Vercel Runtime Logs** for database/auth errors
2. **Check browser Network tab** for OAuth redirect URLs
3. **Verify env vars** in Vercel dashboard (all environments)
4. **Test connection string** with psql or Drizzle Studio
5. **Check RLS policies** in Supabase SQL Editor

## Supabase Dashboard Setup

### Google Provider Configuration

1. Go to Authentication > Providers > Google
2. Enable Google provider
3. Add Google OAuth credentials:
   - Client ID from Google Cloud Console
   - Client Secret from Google Cloud Console
4. Add authorized redirect URI to Google Console:
   ```
   https://your-project.supabase.co/auth/v1/callback
   ```

### Google Cloud Console Setup

1. Go to APIs & Services > Credentials
2. Create OAuth 2.0 Client ID (Web application)
3. Add authorized redirect URIs:
   ```
   https://your-project.supabase.co/auth/v1/callback
   ```
4. Add authorized JavaScript origins:
   ```
   https://your-app.vercel.app
   http://localhost:5000
   ```

## Testing Checklist

- [ ] Sign out completely (clear cookies)
- [ ] Click "Sign in with Google"
- [ ] Verify redirect_uri shows Supabase domain
- [ ] Complete Google consent
- [ ] Verify redirect back to app
- [ ] Verify dashboard shows authenticated state
- [ ] Refresh page - session persists
- [ ] Sign out and sign back in - works

## Updates

- **2026-01-19**: Created from debugging invoice-app OAuth issues
  - Key fix: `isSupabaseConfigured()` check in error handler
  - Supavisor connection string for serverless
  - RLS policy debugging
  - OAuth state error resolution
