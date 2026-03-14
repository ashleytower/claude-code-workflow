---
name: nexus-code-review
description: Code review pipeline using NEXUS agent sequence. Git Workflow Master -> Code Reviewer -> API Tester -> Reality Checker. Use after implementation before merging any feature branch.
---

# NEXUS Code Review Pipeline

A structured multi-agent code review pipeline that catches bugs, validates APIs, and gates quality before merge.

## When to Use

- After implementing any non-trivial feature
- Before merging a feature branch to main
- When a PR needs thorough review
- After fixing a bug (regression check)
- As part of NEXUS-Sprint Phase 4 (Quality & Hardening)

## Pipeline Overview

```
Git Workflow Master -> Code Reviewer -> API Tester -> Reality Checker
```

---

## Step 1: Git Workflow Master (Diff & Context)

Gather the changeset and produce a clean diff summary for the reviewers.

Activation prompt:

```
Activate Git Workflow Master.

Repository: [PATH OR REPO URL]
Branch: [FEATURE BRANCH NAME]
Base branch: [main / develop]

Produce:
1. Git diff summary — what changed, by file
2. Commit history for this branch (commit messages + file list per commit)
3. Files changed (categorized: new / modified / deleted)
4. Test files changed or added
5. Any migrations or schema changes
6. Environment variable changes
7. Package.json / dependency changes

Output: Structured changeset summary ready for Code Reviewer.
```

**Gate**: Changeset summary complete before Code Reviewer activates.

---

## Handoff 1: Git Workflow Master -> Code Reviewer

```
FROM: Git Workflow Master
TO: Code Reviewer
TASK: Code review for [branch/feature name]
CONTEXT:
  - Branch: [branch name]
  - Files changed: [count]
  - New files: [list]
  - Modified files: [list]
  - Migrations: [yes/no — describe if yes]
  - Dependency changes: [yes/no — list if yes]
DELIVERABLES: Changeset summary
QUALITY STATUS: PASS
ACCEPTANCE CRITERIA FOR NEXT PHASE:
  - [ ] All blockers identified
  - [ ] Security issues flagged
  - [ ] Logic errors caught
  - [ ] Suggestions categorized by severity
```

---

## Step 2: Code Reviewer (Review)

Activation prompt:

```
Activate Code Reviewer.

Changeset: [PASTE GIT WORKFLOW MASTER OUTPUT]
Project context: [BRIEF DESCRIPTION OF WHAT THE FEATURE DOES]
Stack: [TECH STACK — e.g., React Native + Expo + Supabase + TypeScript]

Review for:

BLOCKERS (must fix before merge):
- Logic errors that would cause incorrect behavior
- Security vulnerabilities (injection, auth bypass, data exposure)
- Type safety violations (any/as without justification)
- Missing error handling (unhandled promises, missing try/catch)
- Race conditions or state management issues
- Broken tests or missing tests for new behavior
- RLS policies missing for new Supabase tables
- Hardcoded secrets or credentials

SUGGESTIONS (should fix, non-blocking):
- Code duplication that should be extracted
- Variable/function naming that reduces clarity
- Missing edge case handling
- Performance concerns (unnecessary re-renders, N+1 queries)
- Overly complex logic that could be simplified

NITS (optional, polish):
- Style inconsistencies
- Comment quality
- Minor refactor opportunities

Output format:
## BLOCKERS
[list with file:line references]

## SUGGESTIONS
[list with file:line references]

## NITS
[list, brief]

## Overall Assessment
[1-2 sentences]
```

**Gate**: Zero blockers before advancing. Suggestions reviewed and accepted/rejected.

---

## Handoff 2: Code Reviewer -> API Tester

```
FROM: Code Reviewer
TO: API Tester
TASK: API endpoint validation for [feature name]
CONTEXT:
  - Blockers found: [N — list or "none"]
  - Blockers resolved: [yes/no]
  - New API endpoints: [list with methods and paths]
  - Modified endpoints: [list]
  - Auth requirements: [Bearer token / session / public]
  - Base URL: [local dev URL or staging URL]
DELIVERABLES: Code review report
QUALITY STATUS: PASS (blockers resolved) / NEEDS WORK (blockers pending)
ACCEPTANCE CRITERIA FOR NEXT PHASE:
  - [ ] All new endpoints return correct status codes
  - [ ] Auth is enforced (401/403 for unauthorized)
  - [ ] Validation errors return 400/422 with useful messages
  - [ ] Happy path returns correct response shape
  - [ ] Response time < 200ms P95
```

---

## Step 3: API Tester (Endpoint Validation)

Only run this step if the changeset includes API changes. Skip to Reality Checker if UI-only.

Activation prompt:

```
Activate API Tester.

Context: [PASTE CODE REVIEWER HANDOFF]

Endpoints to test: [LIST OF ENDPOINTS]
Base URL: [URL]
Auth: [METHOD AND TOKEN/CREDENTIALS]

For each endpoint, test:
1. Happy path — valid request returns expected response and status code
2. Auth enforcement — missing/invalid token returns 401 or 403
3. Input validation — invalid input returns 400/422 with error details
4. Not found — invalid ID returns 404
5. Response shape — JSON matches expected schema
6. Response time — measure P95 latency

Output format per endpoint:
### [METHOD] /path
- Happy path: PASS / FAIL — [status code, response summary]
- Auth check: PASS / FAIL — [status code]
- Validation: PASS / FAIL — [error details]
- Not found: PASS / FAIL (if applicable)
- Latency: [Xms]
- curl command: [for reproducibility]

Summary: [N/M endpoints passing]
```

**Gate**: All endpoints pass happy path and auth checks before Reality Checker.

---

## Handoff 3: API Tester -> Reality Checker

```
FROM: API Tester
TO: Reality Checker
TASK: Final quality gate for [feature name]
CONTEXT:
  - Feature: [description]
  - Code review: blockers resolved, [N] suggestions applied
  - API testing: [N/M endpoints passing — or "N/A, no API changes"]
  - CI status: [run results]
DELIVERABLES: Code review + API test results
QUALITY STATUS: PENDING REALITY CHECK
ACCEPTANCE CRITERIA FOR PASS:
  - [ ] Zero blockers from code review
  - [ ] All API endpoints pass (if applicable)
  - [ ] TypeScript: zero errors
  - [ ] Tests: all pass (or pre-existing failures only, documented)
  - [ ] Lint: zero errors
  - [ ] No hardcoded secrets or credentials
  - [ ] RLS policies present for any new Supabase tables
```

---

## Step 4: Reality Checker (Final Gate)

Activation prompt:

```
Activate Reality Checker.

YOUR DEFAULT VERDICT IS: NEEDS WORK

What is being validated: [FEATURE NAME] — code review pipeline complete

Evidence provided:
- Code review: [PASTE SUMMARY]
- API test results: [PASTE OR "N/A"]
- CI results: [PASTE OUTPUT]

Acceptance criteria:
- [ ] Zero code review blockers
- [ ] All API endpoints pass (happy path + auth)
- [ ] TypeScript: zero errors
- [ ] Tests: all pass or pre-existing failures documented
- [ ] Lint: zero errors
- [ ] No secrets or credentials in code
- [ ] RLS policies for all new tables
- [ ] Error handling present on all new async operations

Issue PASS only when all criteria are met with evidence.
Issue NEEDS WORK with specific line references for any failing criterion.
```

---

## Output After Reality Checker PASS

Feature branch is ready to merge. Next steps:
1. Apply any remaining suggestions (optional)
2. Run `/commit-push-pr` to create PR
3. Merge after PR review

## Output Format Summary

All reviewers must use this severity taxonomy:

| Label | Meaning | Blocking? |
|-------|---------|-----------|
| BLOCKER | Incorrect behavior, security issue, broken test | Yes |
| SUGGESTION | Should fix, non-blocking | No |
| NIT | Polish, optional | No |

File references must include `file.ts:lineNumber` format for every finding.
