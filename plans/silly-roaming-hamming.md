# Plan: Fix Twilio SMS + Unified Contacts + Mem0->pgvector Migration

## Context

Three related issues need fixing:
1. **Twilio SMS service is down** -- Railway is running the wrong Docker image (OpenClaw gateway instead of Express SMS app). Incoming texts silently fail.
2. **No unified client model** -- SMS, email, and Instagram DMs each store contacts in separate tables with no cross-referencing. When Ashley asks "what did Sarah say?" Max can't search across channels.
3. **SMS correction rules stuck on Mem0** -- The twilio-sms service still promotes correction rules to Mem0 (sunset Feb 2026) instead of Supabase pgvector. Rules get extracted but never reach future drafts.

## Part 1: Fix Twilio SMS Railway Deploy (no code changes)

**Root cause**: `railway status` shows `Service: OpenClaw` from any directory. The CLI link is project-wide. The twilio-sms Dockerfile (`FROM node:20-slim`) is correct but was never deployed -- the OpenClaw gateway Dockerfile got deployed instead.

**Steps**:
```bash
# 1. Link CLI to twilio-sms service
cd /Users/ashleytower/Documents/GitHub/max-ai-employee/skills/twilio-sms
railway service link twilio-sms

# 2. Verify link
railway status  # Should show Service: twilio-sms

# 3. Deploy correct image
railway up

# 4. Verify env vars exist
railway variables  # Need: TWILIO_*, SUPABASE_*, ANTHROPIC_API_KEY, TELEGRAM_*

# 5. Verify health
curl -s https://twilio-sms-production-b6b8.up.railway.app/health
# Expected: {"status":"ok","timestamp":"..."}

# 6. Re-link CLI back to OpenClaw for normal use
cd /Users/ashleytower/Documents/GitHub/max-ai-employee
railway service link OpenClaw
```

**Phone number note**: Ashley texted 514-255-7557 but the Twilio number is +1 438 255 7557. Different numbers.

## Part 2: Unified Contacts Table

**Problem**: SMS uses `sms_conversations.phone_number`, email uses `email_queue.from_address`, IG uses `dm_queue.sender_username`. No table links them.

### 2a. Supabase Migration

**File**: `supabase/migrations/20260215000001_unified_contacts.sql`

```sql
-- Unified contacts: links phone + email + IG handle into one record
CREATE TABLE contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT '3ed111ff-c28f-4cda-b987-1afa4f7eb081',

  -- Contact identifiers (at least one required)
  phone_number TEXT,          -- E.164 format (+15145551234)
  email_address TEXT,         -- lowercase, bare address
  instagram_username TEXT,    -- no @ prefix

  -- Display
  display_name TEXT,          -- "Sarah Jones" or business name

  -- Tracking
  source TEXT,                -- first channel: sms, email, instagram, lead, manual
  preferred_channel TEXT,     -- sms, email, instagram
  last_contacted_at TIMESTAMPTZ,
  last_contact_channel TEXT,
  notes TEXT,                 -- free-form notes
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Partial unique indexes (allow NULLs, enforce uniqueness on non-NULL)
CREATE UNIQUE INDEX idx_contacts_phone ON contacts(user_id, phone_number) WHERE phone_number IS NOT NULL;
CREATE UNIQUE INDEX idx_contacts_email ON contacts(user_id, email_address) WHERE email_address IS NOT NULL;
CREATE UNIQUE INDEX idx_contacts_insta ON contacts(user_id, instagram_username) WHERE instagram_username IS NOT NULL;
CREATE INDEX idx_contacts_name ON contacts(user_id, display_name);

-- Enable RLS
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY contacts_user_policy ON contacts FOR ALL USING (user_id = '3ed111ff-c28f-4cda-b987-1afa4f7eb081');

-- Add contact_id FK to existing tables
ALTER TABLE sms_conversations ADD COLUMN contact_id UUID REFERENCES contacts(id);
ALTER TABLE email_queue ADD COLUMN contact_id UUID REFERENCES contacts(id);
ALTER TABLE dm_queue ADD COLUMN contact_id UUID REFERENCES contacts(id);

-- Helper: find or create contact by any identifier
CREATE OR REPLACE FUNCTION resolve_contact(
  p_user_id UUID,
  p_phone TEXT DEFAULT NULL,
  p_email TEXT DEFAULT NULL,
  p_instagram TEXT DEFAULT NULL,
  p_name TEXT DEFAULT NULL,
  p_source TEXT DEFAULT 'unknown'
) RETURNS UUID AS $$
DECLARE
  v_contact_id UUID;
  v_clean_email TEXT;
  v_clean_phone TEXT;
  v_clean_insta TEXT;
BEGIN
  -- Normalize inputs
  v_clean_phone := NULLIF(TRIM(p_phone), '');
  v_clean_email := LOWER(NULLIF(TRIM(
    CASE WHEN p_email ~ '<(.+)>' THEN (regexp_match(p_email, '<(.+)>'))[1]
    ELSE p_email END
  ), ''));
  v_clean_insta := LOWER(REPLACE(NULLIF(TRIM(p_instagram), ''), '@', ''));

  -- Try to find existing contact by any identifier
  SELECT id INTO v_contact_id FROM contacts
  WHERE user_id = p_user_id AND (
    (v_clean_phone IS NOT NULL AND phone_number = v_clean_phone) OR
    (v_clean_email IS NOT NULL AND email_address = v_clean_email) OR
    (v_clean_insta IS NOT NULL AND instagram_username = v_clean_insta)
  )
  LIMIT 1;

  IF v_contact_id IS NOT NULL THEN
    -- Merge any new identifiers into existing contact
    UPDATE contacts SET
      phone_number = COALESCE(phone_number, v_clean_phone),
      email_address = COALESCE(email_address, v_clean_email),
      instagram_username = COALESCE(instagram_username, v_clean_insta),
      display_name = COALESCE(display_name, p_name),
      last_contacted_at = NOW(),
      updated_at = NOW()
    WHERE id = v_contact_id;
    RETURN v_contact_id;
  END IF;

  -- Create new contact
  INSERT INTO contacts (user_id, phone_number, email_address, instagram_username, display_name, source)
  VALUES (p_user_id, v_clean_phone, v_clean_email, v_clean_insta, p_name, p_source)
  RETURNING id INTO v_contact_id;

  RETURN v_contact_id;
END;
$$ LANGUAGE plpgsql;

-- Helper: search contacts across all identifiers
CREATE OR REPLACE FUNCTION search_contacts(
  p_user_id UUID,
  p_query TEXT,
  p_limit INT DEFAULT 5
) RETURNS TABLE(
  id UUID,
  display_name TEXT,
  phone_number TEXT,
  email_address TEXT,
  instagram_username TEXT,
  last_contacted_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.display_name, c.phone_number, c.email_address, c.instagram_username, c.last_contacted_at
  FROM contacts c
  WHERE c.user_id = p_user_id AND (
    c.display_name ILIKE '%' || p_query || '%' OR
    c.phone_number ILIKE '%' || p_query || '%' OR
    c.email_address ILIKE '%' || p_query || '%' OR
    c.instagram_username ILIKE '%' || p_query || '%'
  )
  ORDER BY c.last_contacted_at DESC NULLS LAST
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;
```

### 2b. Wire SMS to resolve contacts

**File**: `skills/twilio-sms/src/services/supabase.js`

In `getOrCreateConversation()`, after finding/creating the conversation, call `resolve_contact` RPC with the phone number and optional client_name. Store returned `contact_id` on the `sms_conversations` row.

### 2c. Wire email-master to resolve contacts

**File**: `skills/email-master/email-master/scripts/process-emails.sh`

After drafting a reply, call `resolve_contact` RPC with `from_address` (email). Store `contact_id` on the `email_queue` row.

### 2d. Add contact resolution instructions to TOOLS.md

**File**: `workspace/TOOLS.md`

Add section telling Max about `search_contacts` RPC so he can search across channels:
```
## Client Lookup (Cross-Channel)
Search by name, phone, email, or Instagram handle:
SUPABASE_BETA_RUN_SQL_QUERY: {query: "SELECT * FROM search_contacts('3ed111ff...', 'Sarah')", read_only: true}
```

## Part 3: Migrate SMS Corrections from Mem0 to pgvector

### 3a. Create pgvector utility module

**File**: `skills/twilio-sms/src/services/pgvector.js` (NEW)

Node.js equivalents of bash `store_memory_with_embedding()` and `search_memories_pgvector()`:
- `storeMemoryWithEmbedding(content, category, importance, source)` -- calls Ollama nomic-embed-text for embedding, then Supabase `upsert_memory` RPC
- `searchMemoriesPgvector(query, threshold, limit)` -- calls Ollama for query embedding, then Supabase `match_memories` RPC
- Falls back gracefully if Ollama not running (skip embedding, store without it)

Uses same Ollama endpoint (localhost:11434) and Supabase credentials as bash version.

### 3b. Replace rule promotion

**File**: `skills/twilio-sms/src/services/corrections.js`

- Replace `promoteRuleToMem0()` (lines 122-179) with `promoteRuleToPgvector()` that calls `storeMemoryWithEmbedding()` from pgvector.js
- Format: `[DRAFT CORRECTION RULE] [${category}] ${rule}` (same as email-master)
- Category: `correction_rule`, importance: `7`
- Update caller at line 113

### 3c. Add pgvector semantic search to rule retrieval

**File**: `skills/twilio-sms/src/services/corrections.js`

- In `getRelevantCorrections()` (lines 184-222), add pgvector semantic search as primary lookup
- Keep existing FTS on `draft_corrections` as fallback
- Pattern matches email-master's `get_correction_rules()` in `corrections.sh`

### 3d. Replace Mem0 client context

**File**: `skills/twilio-sms/src/services/mem0.js`

- Replace `searchMem0()` (lines 87-146) with `searchMemoriesPgvector()` call
- Keep `getBusinessContext()` hardcoded defaults (they work fine)
- Update `searchClientContext()` to use pgvector instead of Mem0

## Files Modified

| File | Change |
|------|--------|
| `supabase/migrations/20260215000001_unified_contacts.sql` | NEW: contacts table + resolve/search functions |
| `skills/twilio-sms/src/services/pgvector.js` | NEW: Node.js pgvector utility (embed + search) |
| `skills/twilio-sms/src/services/corrections.js` | Replace Mem0 promotion with pgvector, add semantic search to retrieval |
| `skills/twilio-sms/src/services/mem0.js` | Replace Mem0 search with pgvector search |
| `skills/twilio-sms/src/services/supabase.js` | Call resolve_contact on new conversations |
| `skills/email-master/email-master/scripts/process-emails.sh` | Call resolve_contact after drafting |
| `workspace/TOOLS.md` | Add client lookup section |
| `CLAUDE.md` | Add contacts table to schema, update Twilio status |

## Verification

1. **Twilio deploy**: `curl -s https://twilio-sms-production-b6b8.up.railway.app/health` returns OK
2. **Send test SMS**: Text +1 438 255 7557, confirm Telegram approval notification arrives
3. **Contacts migration**: Run SQL migration, verify table exists with `\d contacts`
4. **resolve_contact**: Test with phone, email, IG -- verify dedup and merge
5. **search_contacts**: Search by partial name, verify cross-channel results
6. **pgvector promotion**: Trigger SMS correction, verify rule appears in `memory` table
7. **pgvector retrieval**: Draft new SMS, verify correction rules injected into prompt
8. **Cross-channel**: Verify email correction rules appear in SMS drafts and vice versa
