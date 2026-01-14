# Plan: Add Sales Invoice Tracking for NET Tax Position

## Goal
Track both expense receipts AND sales invoices to show NET tax position:
- **Tax Collected** (GST/QST from invoices sent to clients)
- **Tax Paid** (GST/QST from expense receipts)
- **NET Position** = Collected - Paid (positive = owing, negative = refund)

## User Requirements
- Creates invoices in another tool (Wave, QuickBooks, etc.)
- Uploads sales invoices here for tax tracking
- Wants payment status tracking (Sent/Paid) but no reminder emails
- Primary goal: See NET tax position on dashboard ("Accountant's Joy")

---

## Implementation Plan

### Phase 1: Database Schema

**File: `drizzle/schema.ts`**

Add to invoices table:
```typescript
invoiceType: text("invoiceType", { enum: ["expense", "sales"] }).default("expense"),
clientName: text("clientName"),  // For sales invoices (who you billed)
invoiceNumber: text("invoiceNumber"),  // Your invoice # to client
paymentStatus: text("paymentStatus", { enum: ["sent", "paid", "overdue"] }),
paymentDate: timestamp("paymentDate"),
dueDate: timestamp("dueDate"),
```

Run migration: `npm run db:push`

### Phase 2: Extraction Service

**File: `server/services/extraction.ts`**

Update `extractInvoiceData()` prompt to:
1. Detect invoice type based on document content:
   - "Invoice To:", "Bill To:", "Client:" → `sales` type
   - "Receipt", "Thank you for your purchase", vendor branding → `expense` type
2. Extract `clientName` and `invoiceNumber` for sales invoices
3. Extract `dueDate` if present (Net 30, Due Date, etc.)

Add to extraction result interface:
```typescript
invoiceType: "expense" | "sales";
clientName?: string;
invoiceNumber?: string;
dueDate?: string;
```

### Phase 3: Upload Flow

**File: `client/src/pages/Upload.tsx`**

Update tab options from 2 to 3:
- "Expense Receipt" (current default)
- "Sales Invoice" (NEW)
- "Bank Statement" (current)

Pass selected type to upload mutation so backend knows context.

### Phase 4: Tax Stats Query

**File: `server/db.ts`**

Add new function:
```typescript
export async function getTaxStats(userId: number) {
  // SUM(gst + qst) WHERE invoiceType = 'sales' AND status = 'completed'
  const taxCollected = ...

  // SUM(gst + qst) WHERE invoiceType = 'expense' AND status = 'completed'
  const taxPaid = ...

  return {
    taxCollected,
    taxPaid,
    netTaxPosition: taxCollected - taxPaid
  };
}
```

Update `getDashboardStats()` to include tax stats.

### Phase 5: Dashboard Update

**File: `client/src/pages/Dashboard.tsx`**

Update "Accountant's Joy" card (lines 285-296):

```typescript
const netTax = stats?.netTaxPosition ?? 0;
const isRefund = netTax < 0;

// Display
<p className={isRefund ? "text-green-600" : "text-gray-900"}>
  ${Math.abs(netTax).toFixed(2)}
</p>
<Badge className={isRefund ? "bg-green-100 text-green-700" : "bg-orange-100 text-orange-700"}>
  {isRefund ? "REFUND DUE" : "TAX OWING"}
</Badge>
<p className="text-xs text-gray-500">
  Collected: ${taxCollected} | Paid: ${taxPaid}
</p>
```

### Phase 6: Invoices Page Filter

**File: `client/src/pages/Invoices.tsx`**

Add type filter toggle at top:
- "All" | "Expenses" | "Sales"

For sales invoices, show:
- Client name (instead of store)
- Invoice number
- Payment status badge (Sent/Paid/Overdue)
- Action: "Mark as Paid" dropdown option

### Phase 7: Payment Status Update

**File: `server/routers.ts`**

Add mutation to update payment status:
```typescript
markAsPaid: protectedProcedure
  .input(z.object({ id: z.number(), paymentDate: z.date().optional() }))
  .mutation(async ({ input, ctx }) => {
    await updateInvoice(input.id, ctx.user.id, {
      paymentStatus: "paid",
      paymentDate: input.paymentDate || new Date()
    });
  })
```

---

## Files to Modify

| File | Changes |
|------|---------|
| `drizzle/schema.ts` | Add invoiceType, clientName, invoiceNumber, paymentStatus, dueDate, paymentDate fields |
| `server/db.ts` | Add getTaxStats(), update getDashboardStats() |
| `server/services/extraction.ts` | Update prompt to detect invoice type, extract client info |
| `server/routers.ts` | Add markAsPaid mutation |
| `client/src/pages/Upload.tsx` | Add "Sales Invoice" tab option |
| `client/src/pages/Dashboard.tsx` | Update "Accountant's Joy" to show NET tax position |
| `client/src/pages/Invoices.tsx` | Add type filter, show client name for sales, payment status |

---

## Verification

1. **Upload test**: Upload a sales invoice PDF, verify extraction detects type and extracts client/amount/tax
2. **Upload test**: Upload expense receipt, verify it defaults to expense type
3. **Dashboard test**: With mixed invoices, verify NET tax calculation is correct
4. **Filter test**: Toggle between Expenses/Sales on Invoices page
5. **Payment test**: Mark a sales invoice as paid, verify status updates
6. **Run tests**: `npm test` - ensure no regressions

---

## Data Migration (Optional)

All existing invoices will default to `invoiceType: "expense"` which is correct since the app currently only tracks expense receipts.

No data migration needed - new field has sensible default.
