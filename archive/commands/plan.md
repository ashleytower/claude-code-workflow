# Plan Command

**Purpose**: Create a structured execution plan that becomes the ONLY context needed for the execution session (context reset pattern).

## Usage

```bash
claude /plan [feature-name]
# Example: claude /plan user-authentication
```

## Prerequisites

Before running this command:
1. You should have run `/prime` to load context
2. You should have run `/research` for the tech/patterns
3. You should have run `/ui-design` if this includes UI
4. You should have discussed the feature with Claude

## Process

### 1. Gather Information

From the conversation and loaded context:
- What are we building? (from discussion)
- Why are we building it? (from PRD)
- What research did we do? (from .claude/research/)
- What UI was approved? (from .claude/designs/)
- What files will be affected? (from codebase exploration)

### 2. Create Structured Plan

Output to: `.claude/plans/[feature-name].md`

## Plan Template

```markdown
# Feature Plan: [Feature Name]

**Created**: [date]
**For Execution**: Run in FRESH session with ONLY this plan as context

---

## Feature Overview

**What**: [One sentence description]
**Why**: [Business value / user benefit]
**Priority**: High / Medium / Low
**Estimated Scope**: Small / Medium / Large

---

## Context References

**PRD**: [Project name] - [relevant section]
**Research**: .claude/research/[topic].md
**UI Design**: .claude/designs/[component].md (if applicable)
**Related Files**: [list of files to modify/create]

---

## User Story

As a [user type]
I want to [action]
So that [benefit]

**Acceptance Criteria**:
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

---

## Technical Approach

**Stack**:
- Frontend: [tech]
- Backend: [tech]
- Database: [tech]
- Third-party: [services]

**Key Decisions**:
1. Decision: [what] - Reasoning: [why]
2. Decision: [what] - Reasoning: [why]

**Dependencies**:
```bash
# New packages to install
npm install [packages]
# OR
pip install [packages]
```

**Versions** (from research):
- [package]: v[version] (latest verified)

---

## Implementation Tasks

### Task 1: [Task Name]

**Files to modify/create**:
- `path/to/file.ts`

**Implementation**:
[Detailed description with code examples from research]

```typescript
// Example implementation
[code from official docs/boilerplate]
```

**Tests**:
- [ ] Test case 1
- [ ] Test case 2

### Task 2: [Task Name]

[Same structure]

### Task 3: [Task Name]

[Same structure]

---

## Testing Strategy

**Unit Tests**:
- [ ] Test [functionality]
- [ ] Test [edge case]

**Integration Tests**:
- [ ] Test [integration]

**E2E Tests**:
- [ ] User can [action]
- [ ] Error handling for [scenario]

**Manual Testing Checklist**:
- [ ] Test on iOS
- [ ] Test on Android (if React Native)
- [ ] Test error states
- [ ] Test loading states
- [ ] Test accessibility

---

## Edge Cases to Handle

From `/code-review` thinking:

1. **What if [scenario]?**
   - Handle by: [solution]

2. **What if [scenario]?**
   - Handle by: [solution]

3. [More edge cases...]

---

## Security Considerations

- [ ] Input validation
- [ ] Authentication/authorization
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] Sensitive data handling
- [ ] API key security

---

## Performance Considerations

- [ ] Optimize [bottleneck]
- [ ] Use FlashList for lists (if applicable)
- [ ] Memoize [component/function]
- [ ] Lazy load [resource]

---

## Verification Steps

After implementation:

**Automated**:
```bash
npm test  # or pytest
npm run lint
npm run type-check  # or mypy
```

**Manual**:
1. [ ] Feature works as described
2. [ ] UI matches approved design
3. [ ] Error handling works
4. [ ] Performance is acceptable
5. [ ] Works on all platforms

**Commands to run**:
- `/code-review` - Get ruthless feedback
- `/verify-app` - E2E testing

---

## Success Criteria

Feature is complete when:
- [ ] All tasks implemented
- [ ] All tests passing
- [ ] Code review has no critical issues
- [ ] Manual testing checklist complete
- [ ] UI matches approved design (if applicable)
- [ ] Performance acceptable
- [ ] Ready to commit

---

## Notes

[Any additional context, warnings, or considerations for the execution session]

---

## Execution Command

To execute this plan in a FRESH session:

```bash
claude /execute .claude/plans/[feature-name].md
```

**IMPORTANT**: Start a NEW Claude Code session for execution (context reset!)
```

## Integration with Workflow

### Planning Session
```bash
# Terminal 1
claude /prime
claude "Plan the user authentication feature"
claude /plan user-authentication
# → Creates .claude/plans/user-authentication.md
```

### Context Reset
```bash
# Close Terminal 1
# Open NEW Terminal
```

### Execution Session
```bash
# Fresh Terminal (no history)
claude /execute .claude/plans/user-authentication.md
```

## What Makes a Good Plan

**Comprehensive**:
- All context needed for execution
- No external references required (everything in the plan)
- Code examples from research included

**Actionable**:
- Clear task breakdown
- Specific file paths
- Concrete acceptance criteria

**Self-Contained**:
- Execution session needs ONLY this plan
- No need to prime or explore
- All research findings included

**Testable**:
- Clear verification steps
- Defined success criteria
- Testing strategy included

## In /guide Workflow

Phase 4 (Planning) runs:
1. `/prime` - Load context
2. Discussion about approach
3. `/plan [feature]` - Create structured plan
4. Review plan with user
5. Move to Phase 5 (context reset)

## Example Output

```
✅ PLAN CREATED

Feature: User Authentication
Plan file: .claude/plans/user-authentication.md

Plan includes:
├─ Context references (PRD, research, UI design)
├─ User story + acceptance criteria
├─ Technical approach (Supabase auth)
├─ 8 implementation tasks
├─ Testing strategy (unit, integration, E2E)
├─ 12 edge cases identified
├─ Security checklist
├─ Verification steps
└─ Success criteria

Plan is ready for execution!

Next steps:
1. Review .claude/plans/user-authentication.md
2. If looks good: Close this session
3. Start NEW session: claude /execute .claude/plans/user-authentication.md
```

## Notes

- Plans are documentation (keep them!)
- Reference in PR descriptions
- Update if approach changes
- Archive completed plans for reference
- Critical part of context reset pattern
