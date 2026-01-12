---
name: google-sheets-service-account
category: integration
frameworks: [nextjs, node, vercel]
last_updated: 2026-01-11
version: Google Sheets API v4
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
*Updated 2026-01-12: Added Gemini array unwrapping bug fix*
