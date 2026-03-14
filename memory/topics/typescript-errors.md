
### 2026-02-07 - MTL Craft Cocktails Verification Findings
[gotcha] QuoteData type definition is incomplete. Portal components (ContractTab, PayTab, ProposalTab) access properties that don't exist: signedAt, signedBy, paid, paidAmount, barRental, glassware, polishedCopy. This causes 9 TypeScript errors and will fail at runtime when users try to sign contracts or track payments.
**FIXED:** Added 7 optional fields to QuoteData interface in types/quote.ts (lines 71-77).

[pattern] Handler signature mismatches in App.tsx: Email handlers expect (emailId: string) but receive (email: Email), causing type errors. This pattern repeated in 3 places (lines 896, 1179, 1377).
**FIXED:** Updated usePanelHandlers type to expect `(email: Email) => Promise<void>` and wrapped handler to convert async to sync. Fixed proposalActions signature to accept `(eventData: EventData | null) => void`.

[gotcha] WorkflowCoordinator methods listActiveWorkflows() and getPendingApprovals() return undefined instead of arrays, causing 3 test failures. Methods exist but don't return expected data structure.
**FIXED:** Already resolved by workflow-fixer teammate.

[debug] Voice workflow handlers (onStartWorkflow, onGetWorkflowStatus, etc.) not defined in VoiceToolHandlers interface, causing 7 TypeScript errors in salesWorkflowBaseHandlers.ts. Sales workflow voice commands won't work.
**FIXED:** Added 6 workflow handlers to VoiceToolContext.tsx with correct signatures from useSalesWorkflowHandlers.ts.

[gotcha] Missing await in workflowTriggerHandler.ts lines 205, 213 - calling .map() on Promise<WorkflowState[]> instead of awaited array. Will cause runtime error.
**FIXED:** Added `await` keywords at lines 199 and 200 in workflowTriggerHandler.ts.

[gotcha] Duplicate PendingApproval export in approvalQueueService.ts line 336 conflicts with line 35.
**FIXED:** Removed duplicate export statement.

[pattern] Dynamic/static import conflicts on 15 modules (supabaseClient, fuzzyMatch, actionLogService, etc.) prevents proper code splitting. Vite warns but builds successfully. Consider standardizing to static imports.

[gotcha] Build succeeds with 38 TypeScript errors because Vite doesn't fail on type errors by default. Must run npx tsc --noEmit separately to catch these before deployment.
