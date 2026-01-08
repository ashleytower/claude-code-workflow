---
name: auth
description: Smart authentication - picks best solution for your framework
---

# Auth Skill - Stop Wasting Time on Auth

**Last updated**: 2026-01-08
**Auto-updates**: Weekly (run `~/.claude/scripts/update-auth-docs.sh`)

---

## Quick Decision Tree

```
What framework?
├─ Next.js → Clerk (fastest) or Supabase (cheapest)
├─ React Native/Expo → Supabase (best mobile support)
├─ FastAPI/Python → Supabase (best backend integration)
└─ Other → NextAuth.js/Auth.js (most flexible)
```

---

## Framework-Specific Guides

### Next.js Authentication

**RECOMMENDED: Clerk**
- **Why**: 1-day implementation vs 2-5 days for others
- **Free tier**: 10,000 MAU
- **Features**: Pre-built UI, MFA, social logins, breach detection
- **Best for**: Fast shipping, polished UI, enterprise features

**Installation**:
```bash
npm install @clerk/nextjs
```

**Implementation** (Next.js 15 App Router):
```typescript
// app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs'

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  )
}

// middleware.ts
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server'

const isProtectedRoute = createRouteMatcher(['/dashboard(.*)'])

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) await auth.protect()
})

export const config = {
  matcher: ['/((?!.*\\..*|_next).*)', '/', '/(api|trpc)(.*)'],
}

// app/sign-in/[[...sign-in]]/page.tsx
import { SignIn } from '@clerk/nextjs'

export default function SignInPage() {
  return <SignIn />
}

// Protected page
import { auth } from '@clerk/nextjs/server'

export default async function Dashboard() {
  const { userId } = await auth()
  if (!userId) redirect('/sign-in')

  return <div>Protected content</div>
}
```

**Docs**: https://clerk.com/docs/quickstarts/nextjs

---

**ALTERNATIVE: Supabase Auth**
- **Why**: 50,000 MAU free, database integration, RLS
- **Free tier**: 50,000 MAU (5x more than Clerk)
- **Features**: Row-level security, PostgreSQL integration
- **Best for**: Database-heavy apps, cost optimization

**Installation**:
```bash
npm install @supabase/supabase-js @supabase/ssr
```

**Implementation** (Next.js 15 App Router):
```typescript
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          )
        },
      },
    }
  )
}

// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'

export async function middleware(request) {
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
        },
      },
    }
  )

  const { data: { user } } = await supabase.auth.getUser()

  if (!user && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return NextResponse.next()
}

// app/login/page.tsx
'use client'
import { createClient } from '@/lib/supabase/client'

export default function Login() {
  const supabase = createClient()

  async function handleLogin(e) {
    e.preventDefault()
    const { error } = await supabase.auth.signInWithPassword({
      email: e.target.email.value,
      password: e.target.password.value,
    })
    if (!error) router.push('/dashboard')
  }

  return (
    <form onSubmit={handleLogin}>
      <input name="email" type="email" required />
      <input name="password" type="password" required />
      <button type="submit">Sign in</button>
    </form>
  )
}
```

**Docs**: https://supabase.com/docs/guides/auth/quickstarts/nextjs

---

### React Native/Expo Authentication

**RECOMMENDED: Supabase**
- **Why**: Best mobile support, works with Expo
- **Free tier**: 50,000 MAU
- **Features**: OAuth, magic links, RLS
- **Best for**: Mobile-first apps, cross-platform

**Installation**:
```bash
npx expo install @supabase/supabase-js @react-native-async-storage/async-storage expo-secure-store expo-web-browser expo-auth-session
```

**Implementation**:
```typescript
// lib/supabase.ts
import 'react-native-url-polyfill/auto'
import AsyncStorage from '@react-native-async-storage/async-storage'
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  process.env.EXPO_PUBLIC_SUPABASE_URL!,
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      storage: AsyncStorage,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  }
)

// app/login.tsx
import { useState } from 'react'
import { View, TextInput, Button } from 'react-native'
import { supabase } from '@/lib/supabase'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  async function signIn() {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    if (!error) router.push('/home')
  }

  return (
    <View>
      <TextInput
        placeholder="Email"
        value={email}
        onChangeText={setEmail}
        autoCapitalize="none"
      />
      <TextInput
        placeholder="Password"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
      />
      <Button title="Sign in" onPress={signIn} />
    </View>
  )
}

// app/_layout.tsx
import { useEffect, useState } from 'react'
import { Session } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'

export default function RootLayout() {
  const [session, setSession] = useState<Session | null>(null)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
    })

    return () => subscription.unsubscribe()
  }, [])

  return session ? <AuthenticatedApp /> : <AuthFlow />
}
```

**OAuth (Google)**:
```typescript
import * as WebBrowser from 'expo-web-browser'

WebBrowser.maybeCompleteAuthSession()

async function signInWithGoogle() {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: 'myapp://auth/callback',
    },
  })
}
```

**IMPORTANT**: If you add Google sign-in, must also add Apple sign-in (App Store requirement)

**Docs**: https://supabase.com/docs/guides/auth/quickstarts/react-native

---

**ALTERNATIVE: Clerk**
- **Why**: Beautiful UI components, enterprise features
- **Note**: Clerk + Supabase integration deprecated as of April 2025
- **Use**: Standalone Clerk (no database integration)

**Installation**:
```bash
npm install @clerk/clerk-expo
```

**Docs**: https://clerk.com/docs/quickstarts/expo

---

### FastAPI/Python Authentication

**RECOMMENDED: Supabase**
- **Why**: Python SDK, database integration
- **Free tier**: 50,000 MAU
- **Features**: JWT tokens, RLS, PostgreSQL

**Installation**:
```bash
pip install supabase
```

**Implementation**:
```python
# lib/supabase.py
from supabase import create_client, Client
import os

supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)

# routes/auth.py
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel

router = APIRouter()

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/login")
async def login(request: LoginRequest):
    try:
        response = supabase.auth.sign_in_with_password({
            "email": request.email,
            "password": request.password
        })
        return {
            "access_token": response.session.access_token,
            "user": response.user
        }
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))

# Protected route
from fastapi import Header

async def get_current_user(authorization: str = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing token")

    token = authorization.split("Bearer ")[1]

    try:
        user = supabase.auth.get_user(token)
        return user
    except:
        raise HTTPException(status_code=401, detail="Invalid token")

@router.get("/protected")
async def protected_route(user = Depends(get_current_user)):
    return {"message": f"Hello {user.email}"}
```

**Docs**: https://supabase.com/docs/reference/python

---

## Decision Matrix

| Framework | Best Choice | Why | Free Tier | Time to Implement |
|-----------|-------------|-----|-----------|-------------------|
| Next.js (fast) | Clerk | Pre-built UI, enterprise features | 10K MAU | 1 day |
| Next.js (cheap) | Supabase | 5x more free tier, RLS | 50K MAU | 2 days |
| React Native | Supabase | Best mobile support, Expo integration | 50K MAU | 2 days |
| Expo | Supabase | Official Expo docs | 50K MAU | 2 days |
| FastAPI | Supabase | Python SDK, database integration | 50K MAU | 1 day |
| Any framework | NextAuth.js | Complete control, zero cost | Unlimited | 3-5 days |

---

## Common Patterns

### Email/Password
All solutions support this. Simplest to implement.

### Social Login (OAuth)
- **Clerk**: Google, GitHub, Apple, etc. (pre-configured)
- **Supabase**: Google, GitHub, Apple (need OAuth app setup)
- **NextAuth**: Any OAuth provider (full control)

### Magic Links
- **Clerk**: Built-in
- **Supabase**: Built-in
- **NextAuth**: Custom implementation

### MFA/2FA
- **Clerk**: Built-in (SMS, authenticator app)
- **Supabase**: Email/phone OTP
- **NextAuth**: Custom implementation

### Passwordless
- **Clerk**: Passkeys, magic links
- **Supabase**: Magic links, phone OTP
- **NextAuth**: Custom implementation

---

## Implementation Checklist

### Step 1: Choose Solution
Based on framework + requirements from matrix above

### Step 2: Environment Variables
```bash
# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=

# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=  # For admin operations
```

### Step 3: Install & Configure
Follow implementation guide for your framework above

### Step 4: Protect Routes
- Next.js: middleware.ts
- React Native: Check session in _layout.tsx
- FastAPI: Depends(get_current_user)

### Step 5: Add UI
- Clerk: Pre-built components
- Supabase: Build your own (use shadcn/ui)
- NextAuth: Build your own

### Step 6: Test
- Sign up
- Sign in
- Sign out
- Protected routes block unauthorized
- Session persists on refresh

---

## Security Checklist

- [ ] HTTPS only (no HTTP)
- [ ] Secure cookies (httpOnly, secure, sameSite)
- [ ] CSRF protection
- [ ] Rate limiting on auth endpoints
- [ ] Password requirements enforced
- [ ] Email verification required
- [ ] Session expiration configured
- [ ] Refresh token rotation
- [ ] Audit logs enabled

---

## Production Checklist

- [ ] Error handling (network failures, invalid credentials)
- [ ] Loading states (sign in, sign out)
- [ ] Success messages
- [ ] Redirect after login
- [ ] Remember me (optional)
- [ ] Forgot password flow
- [ ] Profile management
- [ ] Delete account flow

---

## Cost Comparison (2026)

| Solution | Free Tier | Paid (per MAU) | Enterprise |
|----------|-----------|----------------|------------|
| Clerk | 10K MAU | $0.02/MAU | Custom |
| Supabase | 50K MAU | $0.00068/MAU | Custom |
| NextAuth | Unlimited | Infrastructure only | N/A |

**MAU** = Monthly Active Users

---

## Common Issues

### Issue: Session not persisting
**Clerk**: Check middleware matcher
**Supabase**: Verify storage (AsyncStorage for RN, cookies for Next.js)

### Issue: OAuth redirect fails
**All**: Check redirect URL matches configured URL exactly
**React Native**: Must use custom URL scheme (myapp://auth/callback)

### Issue: Protected routes accessible without auth
**Next.js**: Middleware not matching routes correctly
**React Native**: Session check missing in _layout.tsx

### Issue: CORS errors
**Supabase**: Add domain to allowed origins in Supabase dashboard

---

## Weekly Update Process

This skill auto-updates weekly. Manual update:

```bash
~/.claude/scripts/update-auth-docs.sh
```

Updates:
1. Latest versions
2. Breaking changes
3. New features
4. Security patches
5. Best practices

---

## Output Format

When user asks to add auth:

```markdown
## Auth Implementation Plan

**Framework detected**: [framework]
**Recommended solution**: [Clerk/Supabase/NextAuth]
**Reasoning**: [why this choice]
**Implementation time**: [estimate]

### Step 1: Install
[exact commands]

### Step 2: Configure
[environment variables needed]

### Step 3: Implementation
[code snippets for this framework]

### Step 4: Test
[test checklist]

**Ready to implement?**
```

---

## Sources

- [Clerk Next.js Guide](https://clerk.com/articles/complete-authentication-guide-for-nextjs-app-router)
- [Supabase Next.js Quickstart](https://supabase.com/docs/guides/auth/quickstarts/nextjs)
- [Supabase React Native Guide](https://supabase.com/docs/guides/auth/quickstarts/react-native)
- [Expo Authentication Docs](https://docs.expo.dev/develop/authentication/)
- [Clerk vs Supabase Comparison](https://medium.com/better-dev-nextjs-react/clerk-vs-supabase-auth-vs-nextauth-js-the-production-reality-nobody-tells-you-a4b8f0993e1b)

**Last verified**: 2026-01-08
