# Task Plan: [Brief Description]

## Goal
[One sentence describing the end state]

## Context
- **Project:** [project name]
- **Branch:** [feature branch name]
- **Started:** [date]
- **PRD/Issue:** [link or reference if applicable]

## Current Phase
Phase 1: Discovery

---

## Phases

### Phase 1: Discovery
- [ ] Understand requirements fully
- [ ] Check existing patterns (`Grep` codebase)
- [ ] Check `skills/` for reusable code
- [ ] Research docs if new integration (`Skill(research)`)
- **Status:** in_progress
- **Notes:**

### Phase 2: Planning
- [ ] Define approach and architecture
- [ ] Identify files to create/modify
- [ ] Document key decisions in table below
- [ ] Get plan approval (Plan mode)
- **Status:** pending
- **Notes:**

### Phase 3: Test First (TDD)
- [ ] Write failing test for core functionality
- [ ] Run test - confirm it fails for right reason
- [ ] Document test file location below
- **Status:** pending
- **Test file:**
- **Notes:**

### Phase 4: Implementation
- [ ] Write minimal code to pass test
- [ ] Run test - confirm it passes
- [ ] Refactor if needed (tests stay green)
- [ ] Repeat RED-GREEN-REFACTOR for each feature
- **Status:** pending
- **Notes:**

### Phase 5: Verification
- [ ] Run full test suite (`/verify-app`)
- [ ] Type check passes
- [ ] Build succeeds
- [ ] Manual test if applicable
- **Status:** pending
- **Notes:**

### Phase 6: Delivery
- [ ] `/commit-push-pr`
- [ ] `/learn` if new integration worth saving
- [ ] Update session_state.md
- **Status:** pending
- **Notes:**

---

## Files to Modify

| File | Change | Status |
|------|--------|--------|
|      |        | pending |

## Decisions Made

| Decision | Options Considered | Rationale |
|----------|-------------------|-----------|
|          |                   |           |

## Errors Encountered

| Error | Attempt | What I Tried | Resolution |
|-------|---------|--------------|------------|
|       | 1       |              |            |
|       | 2       |              |            |
|       | 3       | ASK USER     |            |

## Blockers

| Blocker | Waiting On | Workaround |
|---------|------------|------------|
|         |            |            |

---

## Rules
- Update phase status: `pending` -> `in_progress` -> `complete`
- Re-read this plan before major decisions
- Log ALL errors - prevents repetition
- After 3 failed attempts on same issue, ask user
- Never repeat the exact same failed action
