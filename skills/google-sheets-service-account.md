---
name: google-sheets-service-account
category: integration
frameworks: [nextjs, node, vercel]
last_updated: 2026-01-12
version: Google Sheets API v4 + Drive API v3
---

# Google Sheets Service Account Integration

## Quick Start

Use service accounts for server-to-server Google Sheets access (no user OAuth required).

## Installation

```bash
npm install jose  # For JWT signing
```

## Environment Variables

```env
# For Vercel/Production
GOOGLE_SERVICE_ACCOUNT_EMAIL=your-service@project.iam.gserviceaccount.com
GOOGLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEv...full key...\n-----END PRIVATE KEY-----"
```

## Setup Code

### Service Account Token Generation (Vercel-compatible)

```typescript
// server/_core/googleAuth.ts
import { SignJWT, importPKCS8 } from "jose";
import fs from "fs/promises";
import path from "path";

const SERVICE_ACCOUNT_PATH = path.join(process.cwd(), "service_account.json");

async function getCredentials() {
    // Try environment variables first (for Vercel production)
    if (process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL && process.env.GOOGLE_PRIVATE_KEY) {
        return {
            client_email: process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL,
            private_key: process.env.GOOGLE_PRIVATE_KEY.replace(/\\n/g, '\n')
        };
    }

    // Fall back to local file (for development)
    const content = await fs.readFile(SERVICE_ACCOUNT_PATH, "utf-8");
    return JSON.parse(content);
}

export async function getServiceAccountToken(): Promise<string> {
    try {
        const credentials = await getCredentials();

        const privateKey = await importPKCS8(credentials.private_key, "RS256");
        const now = Math.floor(Date.now() / 1000);

        const jwt = await new SignJWT({
            iss: credentials.client_email,
            scope: "https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/drive",
            aud: "https://oauth2.googleapis.com/token",
            exp: now + 3600,
            iat: now
        })
            .setProtectedHeader({ alg: "RS256", typ: "JWT" })
            .sign(privateKey);

        const response = await fetch("https://oauth2.googleapis.com/token", {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: new URLSearchParams({
                grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
                assertion: jwt
            })
        });

        if (!response.ok) {
            throw new Error(`Failed to get token: ${await response.text()}`);
        }

        return (await response.json()).access_token;
    } catch (error) {
        console.error("[GoogleAuth] Failed to get service account token:", error);
        throw error;
    }
}
```

### Google Sheets Service

```typescript
// server/services/googleSheets.ts
export class GoogleSheetsService {
    private accessToken: string | null = null;

    setAccessToken(token: string) {
        this.accessToken = token;
    }

    async appendRows(spreadsheetId: string, sheetName: string, rows: any[][]) {
        const range = `${sheetName}!A:Z`;
        
        const response = await fetch(
            `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values/${encodeURIComponent(range)}:append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS`,
            {
                method: "POST",
                headers: {
                    "Authorization": `Bearer ${this.accessToken}`,
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({ values: rows })
            }
        );

        if (!response.ok) {
            throw new Error(`Failed to append rows: ${await response.text()}`);
        }

        return response.json();
    }
}
```

### Usage in API Route

```typescript
// In your upload handler
try {
    const accessToken = await getServiceAccountToken();
    const sheetsService = new GoogleSheetsService();
    sheetsService.setAccessToken(accessToken);
    
    await sheetsService.appendRows(spreadsheetId, "Sheet1", [[data1, data2, data3]]);
    
    // Mark as synced in database
    await db.update({ sheetsSynced: true });
} catch (syncError) {
    // GOTCHA: Don't throw here - let upload succeed even if sync fails
    console.error("[Sheets] Sync failed:", syncError);
}
```

## CRITICAL Gotchas

### 1. Service Account Must Have Sheet Access
**Problem:** Sync fails silently, `sheetsSynced` stays false  
**Solution:** Share the Google Sheet with the service account email as **Editor**
```
1. Open Google Sheet → Share
2. Add: your-service@project.iam.gserviceaccount.com
3. Set permission: Editor
4. Uncheck "Notify people"
```

### 2. Private Key Newline Escaping on Vercel
**Problem:** `Error: Invalid key` or JWT signing fails  
**Solution:** Vercel escapes newlines in env vars. Always use:
```typescript
private_key: process.env.GOOGLE_PRIVATE_KEY.replace(/\\n/g, '\n')
```

### 3. service_account.json Doesn't Exist on Vercel
**Problem:** `ENOENT: no such file or directory 'service_account.json'`  
**Solution:** Use environment variables in production, file fallback for local dev
```typescript
// Check env vars first, then fall back to file
if (process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL && process.env.GOOGLE_PRIVATE_KEY) {
    // Use env vars
} else {
    // Read from file (local dev only)
}
```

### 4. Private Key Must Include BEGIN/END Lines
**Problem:** `Invalid PEM formatted message`  
**Solution:** Copy the FULL key including headers:
```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhki...
...entire key...
-----END PRIVATE KEY-----
```
NOT just the base64 content.

### 5. Silent Sync Failures
**Problem:** Upload shows "complete" but data not in sheet  
**Solution:** 
- Check `sheetsSynced` flag in database (not just `status`)
- Add explicit logging: `console.log("[Sheets] Sync complete")`
- Don't swallow errors silently - at least log them

### 6. OAuth Client vs Service Account Confusion
**Problem:** Using wrong credentials type  
**Solution:** 
- **OAuth Client** (`client_id`, `client_secret`) = User login flow
- **Service Account** (`client_email`, `private_key`) = Server-to-server

Service account JSON looks like:
```json
{
  "type": "service_account",
  "project_id": "...",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "name@project.iam.gserviceaccount.com",
  ...
}
```

### 7. Local SQLite vs Production Database
**Problem:** Testing locally shows empty database  
**Solution:** Check which database you're connected to:
- Local: `sqlite.db` file (may be empty/stale)
- Production: Supabase/Postgres (actual data)

Always verify against production database when debugging sync issues.

## Debugging Checklist

When Google Sheets sync fails:

1. [ ] Check `sheetsSynced` column in database (not just `status`)
2. [ ] Verify service account email is shared with sheet as Editor
3. [ ] Check Vercel env vars are set (`GOOGLE_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_PRIVATE_KEY`)
4. [ ] Verify private key includes BEGIN/END lines
5. [ ] Check server logs for `[Sheets]` or `[GoogleAuth]` errors
6. [ ] Test service account token generation separately
7. [ ] Verify sheet ID and sheet name are correct in settings

## Vercel Environment Setup

1. Go to Vercel Dashboard → Project → Settings → Environment Variables
2. Add:
   - Name: `GOOGLE_SERVICE_ACCOUNT_EMAIL`
   - Value: `your-service@project.iam.gserviceaccount.com`
3. Add:
   - Name: `GOOGLE_PRIVATE_KEY`
   - Value: (paste full key with BEGIN/END lines, no quotes)
4. Redeploy

## Testing

```typescript
// Test service account token generation
const token = await getServiceAccountToken();
console.log("Token obtained:", token.substring(0, 20) + "...");

// Test sheet access
const sheetsService = new GoogleSheetsService();
sheetsService.setAccessToken(token);
const result = await sheetsService.appendRows(sheetId, "Test", [["test", new Date().toISOString()]]);
console.log("Appended:", result);
```

## Common Use Cases

### Sync Data After Processing
```typescript
// After processing upload
await processUpload(file);
await syncToSheets(processedData);
await db.update({ sheetsSynced: true });
```

### Batch Sync Multiple Items
```typescript
const rows = items.map(item => [item.id, item.name, item.amount]);
await sheetsService.appendRows(sheetId, "Items", rows);
```

## Updates

- 2026-01-11: Initial skill created from invoice-app debugging session
  - Discovered Vercel env var newline escaping issue
  - Documented service account sharing requirement
  - Added silent failure debugging checklist

## Gemini PDF Extraction Integration

When using Gemini 2.0 Flash for PDF extraction that syncs to Sheets:

### Environment Variable Name
```env
# WRONG - won't work
GEMINI_API_KEY=xxx

# RIGHT
GOOGLE_API_KEY=xxx
```

### CRITICAL: Array Response Bug

**THE BUG**: Gemini returns `[{...}]` (array) instead of `{...}` (object).

**SYMPTOMS**:
- Extraction shows "complete" but all fields are null
- `rawResponse` contains correct data but parsed fields are empty
- `sheetsSynced: true` but data columns are empty

**ROOT FIX** - Unwrap arrays at end of your JSON parser:

```typescript
// Unwrap single-element arrays (Gemini sometimes returns [{...}] instead of {...})
if (Array.isArray(result) && result.length > 0) {
  return result[0];
}
return result ?? {};
```

**WRONG** (bandaid fixes scattered everywhere):
```typescript
// DON'T do this - patches at multiple locations
if (Array.isArray(parsed)) parsed = parsed[0]; // Line 100
if (Array.isArray(result)) result = result[0]; // Line 200
```

**RIGHT**: One unwrap at the end of parser function.

### Debugging Extraction + Sheets Sync

When data extracts but doesn't appear in Sheets:

1. Check `rawExtractionData.rawResponse` in database
   - Starts with `[` → Array unwrapping bug
   - Starts with `{` → Different parsing issue
   - Empty → Gemini API issue (check GOOGLE_API_KEY)

2. Check parsed fields (institution, date, etc.)
   - All null but rawResponse has data → Parser not unwrapping

3. Check `sheetsSynced` flag
   - `true` but empty sheet → Extraction failed before sync
   - `false` → Sync failed (check service account permissions)

---

## OAuth Token Refresh for Webhook Handlers (Telegram, etc.)

When webhook handlers (like Telegram bots) need to access Google APIs on behalf of users, tokens expire and must be refreshed.

### The Problem

**Symptom**: Google Drive uploads fail with 403 "Service Accounts do not have storage quota" or tokens expire after 1 hour.

**Root Causes**:
1. OAuth flow missing `prompt: "consent"` - Google only returns refresh_token on FIRST authorization
2. Service account fallback used for Drive - service accounts CAN'T upload to personal Drive
3. Webhook handlers not refreshing expired tokens before API calls

### Root Fix 1: OAuth Must Force Consent

**CRITICAL**: Add `prompt: "consent"` to OAuth flow. Without it, Google only returns refresh_token the first time a user authorizes.

```typescript
// server/_core/oauth.ts
const url = client.generateAuthUrl({
  access_type: "offline",
  prompt: "consent", // CRITICAL: Forces refresh_token on every login
  scope: [
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/userinfo.profile",
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive.file",
  ],
});
```

### Root Fix 2: Service Account Fallback - Sheets Only, NOT Drive

**CRITICAL**: Service accounts CAN write to shared Google Sheets but CANNOT upload to Google Drive (no storage quota).

```typescript
/**
 * Get a valid Google access token for a user, refreshing if expired.
 * @param allowServiceAccountFallback - true for Sheets, false for Drive
 */
async function getValidGoogleToken(
  user: { openId: string; googleAccessToken: string | null; googleRefreshToken: string | null; googleTokenExpiresAt: Date | null },
  allowServiceAccountFallback: boolean = false
): Promise<string | null> {
  let token = user.googleAccessToken;

  // Check if token needs refresh
  if (!token || tokenNeedsRefresh(user.googleTokenExpiresAt)) {
    if (user.googleRefreshToken) {
      const refreshed = await refreshGoogleToken(user.googleRefreshToken);
      if (refreshed) {
        token = refreshed.accessToken;
        await upsertUser({
          openId: user.openId,
          googleAccessToken: refreshed.accessToken,
          googleTokenExpiresAt: refreshed.expiresAt,
        });
      } else {
        token = null;
      }
    } else {
      token = null;
    }
  }

  // Service account fallback ONLY for Sheets, NEVER for Drive
  if (!token && allowServiceAccountFallback) {
    try {
      token = await getServiceAccountToken();
    } catch (e) {
      return null;
    }
  }

  return token;
}
```

### Usage

```typescript
// For Google Drive - NO service account fallback (will fail with 403)
const driveToken = await getValidGoogleToken(user, false);
if (driveToken) {
  const drive = new GoogleDriveService({ accessToken: driveToken });
  await drive.uploadFile(fileName, fileBuffer, "image/jpeg", date);
}

// For Google Sheets - service account fallback OK
const sheetsToken = await getValidGoogleToken(user, true);
if (sheetsToken) {
  const sheets = new GoogleSheetsService({ accessToken: sheetsToken });
  await sheets.syncInvoice(sheetId, "Invoices", invoice);
}
```

### Root Fix 3: Telegram Account Linking via OAuth State

When users access via Telegram, they need to link their Telegram account to their Google OAuth account.

```typescript
// Telegram /start command - provide linking URL
bot.start(async (ctx) => {
  const telegramId = ctx.from.id.toString();
  const user = await getUserByTelegramId(telegramId);

  if (user) {
    await ctx.reply(`Welcome back! Send me a receipt photo.`);
  } else {
    const baseUrl = process.env.OAUTH_SERVER_URL || "https://your-app.vercel.app";
    const linkingUrl = `${baseUrl}/api/auth/google?telegramId=${telegramId}`;
    await ctx.reply(`Click to link your account:\n\n${linkingUrl}`);
  }
});

// OAuth login route - pass telegramId through state
app.get("/api/auth/google", (req, res) => {
  const telegramId = req.query.telegramId;
  let state: string | undefined;
  if (telegramId) {
    state = Buffer.from(JSON.stringify({ telegramId })).toString("base64");
  }

  const url = client.generateAuthUrl({
    access_type: "offline",
    prompt: "consent",
    scope: [...],
    state,
  });
  res.redirect(url);
});

// OAuth callback - extract telegramId and link account
app.get("/api/oauth/callback", async (req, res) => {
  const state = req.query.state;
  let telegramId: string | undefined;
  if (state) {
    try {
      const stateData = JSON.parse(Buffer.from(state, "base64").toString());
      telegramId = stateData.telegramId;
    } catch {}
  }

  // ... token exchange ...

  const userData = {
    openId: payload.sub,
    email: payload.email,
    googleAccessToken: tokens.access_token,
    googleRefreshToken: tokens.refresh_token,
    googleTokenExpiresAt: tokenExpiresAt,
  };

  // Link Telegram account if telegramId was passed
  if (telegramId) {
    userData.telegramId = telegramId;
  }

  await db.upsertUser(userData);
});
```

### Token Refresh Functions

```typescript
// server/_core/googleAuth.ts
export function tokenNeedsRefresh(expiresAt: Date | null | undefined): boolean {
  if (!expiresAt) return true;
  const fiveMinutesFromNow = new Date(Date.now() + 5 * 60 * 1000);
  return expiresAt < fiveMinutesFromNow;
}

export async function refreshGoogleToken(refreshToken: string): Promise<{ accessToken: string; expiresAt: Date } | null> {
  const client = new OAuth2Client(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET
  );
  client.setCredentials({ refresh_token: refreshToken });
  const { credentials } = await client.refreshAccessToken();

  if (!credentials.access_token) return null;

  return {
    accessToken: credentials.access_token,
    expiresAt: credentials.expiry_date ? new Date(credentials.expiry_date) : new Date(Date.now() + 3600000)
  };
}
```

### Required Environment Variables

```env
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxx
OAUTH_SERVER_URL=https://your-app.vercel.app
```

### Gotchas

1. **`prompt: "consent"` is REQUIRED** - Without it, Google only returns refresh_token on first auth. Users will get stuck with expired tokens.

2. **Service accounts CANNOT upload to Drive** - They have no storage quota. Only use for Sheets.

3. **Two user accounts problem** - If Telegram creates separate users, link via OAuth state parameter, not manual DB updates.

4. **Token refresh saves to database** - The helper updates the user record so subsequent calls use the fresh token.

---

## Complete Working Example: Telegram Bot with Drive + Sheets

Full working code for a Telegram bot that receives photos, uploads to Drive, and syncs to Sheets.

### Database Schema (Drizzle ORM)

```typescript
// drizzle/schema.ts
import { pgTable, serial, text, timestamp, integer } from "drizzle-orm/pg-core";

export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  openId: text("openId").notNull().unique(),
  email: text("email"),
  name: text("name"),
  telegramId: text("telegramId").unique(),
  googleAccessToken: text("googleAccessToken"),
  googleRefreshToken: text("googleRefreshToken"),
  googleTokenExpiresAt: timestamp("googleTokenExpiresAt"),
  createdAt: timestamp("createdAt").defaultNow(),
  updatedAt: timestamp("updatedAt").defaultNow(),
});

export const settings = pgTable("settings", {
  id: serial("id").primaryKey(),
  userId: integer("userId").notNull().references(() => users.id),
  invoiceSheetId: text("invoiceSheetId"),
  invoiceSheetName: text("invoiceSheetName").default("Invoices"),
});
```

### Complete Telegram Handler

```typescript
// server/services/telegram.ts
import { Telegraf } from "telegraf";
import { message } from "telegraf/filters";
import { getUserByTelegramId, upsertUser, getOrCreateSettings } from "../db";
import { refreshGoogleToken, tokenNeedsRefresh, getServiceAccountToken } from "../_core/googleAuth";
import { GoogleDriveService } from "./googleDrive";
import { GoogleSheetsService } from "./googleSheets";

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;

/**
 * Get valid Google token with automatic refresh.
 * @param allowServiceAccountFallback - true for Sheets, false for Drive
 */
async function getValidGoogleToken(
  user: {
    openId: string;
    googleAccessToken: string | null;
    googleRefreshToken: string | null;
    googleTokenExpiresAt: Date | null;
  },
  allowServiceAccountFallback: boolean = false
): Promise<string | null> {
  let token = user.googleAccessToken;

  if (!token || tokenNeedsRefresh(user.googleTokenExpiresAt)) {
    if (user.googleRefreshToken) {
      console.log("[Telegram] Refreshing expired token...");
      const refreshed = await refreshGoogleToken(user.googleRefreshToken);
      if (refreshed) {
        token = refreshed.accessToken;
        await upsertUser({
          openId: user.openId,
          googleAccessToken: refreshed.accessToken,
          googleTokenExpiresAt: refreshed.expiresAt,
        });
        console.log("[Telegram] Token refreshed successfully");
      } else {
        console.warn("[Telegram] Token refresh failed");
        token = null;
      }
    } else {
      console.warn("[Telegram] No refresh token - user needs to re-login");
      token = null;
    }
  }

  // Service account fallback ONLY for Sheets
  if (!token && allowServiceAccountFallback) {
    try {
      console.log("[Telegram] Using service account for Sheets");
      token = await getServiceAccountToken();
    } catch (e) {
      return null;
    }
  }

  return token;
}

export function setupTelegramBot() {
  if (!BOT_TOKEN) return null;
  const bot = new Telegraf(BOT_TOKEN);

  // /start - Provide linking URL for new users
  bot.start(async (ctx) => {
    const telegramId = ctx.from.id.toString();
    const user = await getUserByTelegramId(telegramId);

    if (user) {
      await ctx.reply("Welcome back! Send me a receipt photo.");
    } else {
      const baseUrl = process.env.OAUTH_SERVER_URL || "https://your-app.vercel.app";
      const linkingUrl = `${baseUrl}/api/auth/google?telegramId=${telegramId}`;
      await ctx.reply(
        `To link your account, click this link and sign in with Google:\n\n${linkingUrl}`
      );
    }
  });

  // Handle photo messages
  bot.on(message("photo"), async (ctx) => {
    const telegramId = ctx.from.id.toString();
    const user = await getUserByTelegramId(telegramId);

    if (!user) {
      await ctx.reply("Your account is not linked. Type /start to get linking instructions.");
      return;
    }

    await ctx.reply("Processing your receipt...");

    try {
      // Download photo from Telegram
      const photos = ctx.message.photo;
      const largestPhoto = photos[photos.length - 1];
      const file = await ctx.telegram.getFile(largestPhoto.file_id);
      const fileUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${file.file_path}`;
      const fileRes = await fetch(fileUrl);
      const fileBuffer = Buffer.from(await fileRes.arrayBuffer());
      const fileName = `receipt-${Date.now()}.jpg`;

      // 1. Upload to Google Drive (NO service account fallback)
      let googleDriveViewLink: string | null = null;
      const driveToken = await getValidGoogleToken(user, false);
      if (driveToken) {
        try {
          const drive = new GoogleDriveService({ accessToken: driveToken });
          const driveRes = await drive.uploadFile(fileName, fileBuffer, "image/jpeg", new Date());
          googleDriveViewLink = driveRes.viewLink;
          console.log("[Telegram] Drive upload success:", googleDriveViewLink);
        } catch (e) {
          console.error("[Telegram] Drive upload failed:", e);
        }
      } else {
        console.warn("[Telegram] No valid token for Drive upload");
      }

      // 2. Extract data from receipt (your extraction logic here)
      const extractedData = {
        store: "Example Store",
        amount: "25.99",
        date: new Date().toISOString().split("T")[0],
        photoUrl: googleDriveViewLink,
      };

      // 3. Sync to Google Sheets (service account fallback OK)
      const sheetsToken = await getValidGoogleToken(user, true);
      if (sheetsToken) {
        try {
          const settings = await getOrCreateSettings(user.id);
          if (settings.invoiceSheetId) {
            const sheets = new GoogleSheetsService({ accessToken: sheetsToken });
            await sheets.appendRows(settings.invoiceSheetId, settings.invoiceSheetName || "Invoices", [
              [extractedData.date, extractedData.store, extractedData.amount, extractedData.photoUrl]
            ]);
            console.log("[Telegram] Sheets sync success");
            await ctx.reply("Receipt processed and synced to Google Sheets!");
          }
        } catch (e) {
          console.error("[Telegram] Sheets sync failed:", e);
        }
      }

    } catch (error) {
      console.error("[Telegram] Processing error:", error);
      await ctx.reply("Failed to process receipt.");
    }
  });

  return bot;
}
```

### Complete OAuth Routes

```typescript
// server/_core/oauth.ts
import { OAuth2Client } from "google-auth-library";
import * as db from "../db";

export function registerOAuthRoutes(app: Express) {
  // Login route - accepts optional telegramId for linking
  app.get("/api/auth/google", (req, res) => {
    const { clientId, clientSecret } = getGoogleCredentials();
    const redirectUri = `${process.env.OAUTH_SERVER_URL}/api/oauth/callback`;

    const client = new OAuth2Client(clientId, clientSecret, redirectUri);

    // Pass telegramId through OAuth state if present
    const telegramId = req.query.telegramId as string;
    let state: string | undefined;
    if (telegramId) {
      state = Buffer.from(JSON.stringify({ telegramId })).toString("base64");
    }

    const url = client.generateAuthUrl({
      access_type: "offline",
      prompt: "consent", // CRITICAL: Always get refresh token
      scope: [
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/userinfo.profile",
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/drive.file",
      ],
      state,
    });

    res.redirect(url);
  });

  // Callback route - handles token exchange and Telegram linking
  app.get("/api/oauth/callback", async (req, res) => {
    const code = req.query.code as string;
    const state = req.query.state as string;

    // Extract telegramId from state if present
    let telegramId: string | undefined;
    if (state) {
      try {
        const stateData = JSON.parse(Buffer.from(state, "base64").toString());
        telegramId = stateData.telegramId;
      } catch {}
    }

    const { clientId, clientSecret } = getGoogleCredentials();
    const redirectUri = `${process.env.OAUTH_SERVER_URL}/api/oauth/callback`;
    const client = new OAuth2Client(clientId, clientSecret, redirectUri);

    const { tokens } = await client.getToken(code);
    client.setCredentials(tokens);

    const ticket = await client.verifyIdToken({
      idToken: tokens.id_token!,
      audience: clientId,
    });
    const payload = ticket.getPayload()!;

    const tokenExpiresAt = tokens.expiry_date
      ? new Date(tokens.expiry_date)
      : new Date(Date.now() + 3600 * 1000);

    // Build user data with optional telegramId linking
    const userData: any = {
      openId: payload.sub,
      name: payload.name || "User",
      email: payload.email!,
      googleAccessToken: tokens.access_token!,
      googleRefreshToken: tokens.refresh_token || undefined,
      googleTokenExpiresAt: tokenExpiresAt,
    };

    if (telegramId) {
      userData.telegramId = telegramId;
      console.log("[OAuth] Linking Telegram ID:", telegramId);
    }

    await db.upsertUser(userData);

    res.redirect("/");
  });
}
```

### All Required Environment Variables

```env
# Google OAuth (for user login and token refresh)
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxx

# Google Service Account (for Sheets fallback only - NOT for Drive)
GOOGLE_SERVICE_ACCOUNT_EMAIL=xxx@project.iam.gserviceaccount.com
GOOGLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"

# Google Drive folder (optional - for organizing uploads)
GOOGLE_DRIVE_FOLDER_ID=1abc123...

# Telegram Bot
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz

# App URLs
OAUTH_SERVER_URL=https://your-app.vercel.app
```

### Debugging Checklist

When Telegram uploads fail:

1. [ ] Check if user has `googleRefreshToken` in database (not just accessToken)
2. [ ] Verify OAuth flow includes `prompt: "consent"`
3. [ ] Check if user's `telegramId` is linked to correct account
4. [ ] For Drive: ensure NOT using service account fallback
5. [ ] For Sheets: verify service account email has Editor access to sheet
6. [ ] Check Vercel logs for `[Telegram]` prefixed messages
7. [ ] Verify all environment variables are set in Vercel

### Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Service Accounts do not have storage quota" | Using service account for Drive | Use user OAuth token, not service account |
| "invalid_grant" or "Token has been revoked" | Refresh token invalid | User must re-login via `/start` |
| "Your account is not linked" | telegramId not in database | User clicks linking URL from `/start` |
| Sheets sync works but Drive fails | Different fallback behavior | Drive needs user token, Sheets can use service account |

---
*Updated 2026-01-12: Complete rewrite with tested root fixes (prompt:consent, no Drive fallback, Telegram linking)*
