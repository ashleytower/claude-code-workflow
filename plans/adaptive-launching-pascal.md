# Testing Plan: Database Layer

## Scope
Test 39 database functions in `server/db.ts` (531 lines, currently 0% tested)

## Key Discovery
**Database is PostgreSQL (Supabase), not SQLite**. The db.ts uses:
- `drizzle-orm/postgres-js`
- `postgres` client
- Schema from `drizzle/schema.pg.ts`

---

## Testing Approach

### Option: `pg-mem` (In-Memory PostgreSQL)
Fast, no Docker required, runs in Vitest like regular tests.

```bash
npm install -D pg-mem
```

**Pros**: Fast, no external deps, CI-friendly
**Cons**: May have minor PostgreSQL behavior differences

---

## Implementation Steps

### Step 1: Install test dependencies
```bash
npm install -D pg-mem
```

### Step 2: Create test database setup
Create `server/test-db-setup.ts`:
- Initialize pg-mem with schema
- Export test database instance
- Export reset function for between tests

### Step 3: Create db.integration.test.ts
Test all 39 functions organized by entity:

**User functions (5)** - Lines 54-128
- `upsertUser()` - create new, update existing
- `getUserByOpenId()` - find by openId
- `getUserByTelegramId()` - find by telegramId
- `getUserById()` - find by id
- `updateUserTelegramId()` - update telegram link

**Invoice functions (10)** - Lines 131-247
- `createInvoice()` - returns id
- `getInvoiceById()` - find by id
- `getInvoiceByOriginalFileKey()` - find by S3 key
- `getInvoicesByUserId()` - list with pagination
- `findDuplicateInvoice()` - deduplication check
- `getInvoicesByDateRange()` - date filtering
- `updateInvoice()` - partial update
- `deleteInvoice()` - hard delete
- `getUnmatchedInvoices()` - reconciliation candidates
- `getInvoiceStats()` - count by status

**Statement functions (4)** - Lines 250-277
- `createStatement()` - returns id
- `getStatementById()` - find by id
- `getStatementsByUserId()` - list with limit
- `updateStatement()` - partial update

**Statement Item functions (4)** - Lines 280-333
- `createStatementItems()` - batch insert
- `getStatementItemsByStatementId()` - list by statement
- `updateStatementItem()` - partial update
- `getUnmatchedStatementItems()` - reconciliation candidates

**Reconciliation functions (4)** - Lines 336-363
- `createReconciliation()` - returns id
- `getReconciliationById()` - find by id
- `getReconciliationsByUserId()` - list with limit
- `updateReconciliation()` - partial update

**Discrepancy functions (5)** - Lines 366-440
- `createDiscrepancy()` - single insert
- `createDiscrepancies()` - batch insert
- `getDiscrepanciesByReconciliationId()` - list by reconciliation
- `getOpenDiscrepancies()` - cross-table query
- `updateDiscrepancy()` - partial update

**Settings functions (2)** - Lines 443-459
- `getOrCreateSettings()` - upsert pattern
- `updateSettings()` - partial update

**Processing Queue functions (4)** - Lines 462-491
- `addToProcessingQueue()` - returns id
- `getQueuedItems()` - list pending
- `updateQueueItem()` - partial update
- `getRecentQueueItems()` - list by user

**Dashboard function (1)** - Lines 494-530
- `getDashboardStats()` - aggregated counts

---

## Test Structure

```typescript
// server/db.integration.test.ts
describe('Database Functions', () => {
  beforeEach(() => {
    // Reset database to clean state
  });

  describe('User Functions', () => {
    it('upsertUser creates new user', async () => {});
    it('upsertUser updates existing user', async () => {});
    it('getUserByOpenId returns user', async () => {});
    it('getUserByOpenId returns undefined for unknown', async () => {});
    // ... etc
  });

  describe('Invoice Functions', () => {
    it('createInvoice returns id', async () => {});
    it('findDuplicateInvoice detects duplicates', async () => {});
    it('findDuplicateInvoice returns null for unique', async () => {});
    // ... etc
  });

  // ... other entities
});
```

---

## Files to Create/Modify

| Action | File |
|--------|------|
| Install | `pg-mem` package |
| Create | `server/test-db-setup.ts` (pg-mem initialization) |
| Create | `server/db.integration.test.ts` (all tests) |

---

## Verification

```bash
npm test
```

Expected:
- All 39 functions have at least one test
- Tests run in ~2-5 seconds (in-memory)
- No external database required

---

## Test Count Estimate

| Entity | Functions | Tests (min) |
|--------|-----------|-------------|
| User | 5 | 10 |
| Invoice | 10 | 20 |
| Statement | 4 | 8 |
| StatementItem | 4 | 8 |
| Reconciliation | 4 | 8 |
| Discrepancy | 5 | 10 |
| Settings | 2 | 4 |
| ProcessingQueue | 4 | 8 |
| Dashboard | 1 | 2 |
| **Total** | **39** | **~78** |
