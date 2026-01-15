---
name: verify-app
description: Comprehensive E2E verification
model: sonnet
---

# Verify App - E2E Testing & Verification

Comprehensive end-to-end verification of your application after implementation.

## What This Does

**Post-implementation verification loop**:
1. **Run all tests** (unit, integration, E2E)
2. **Type check** (TypeScript/Python)
3. **Lint check** (ESLint, Pylint, etc.)
4. **Build verification** (ensure builds succeed)
5. **Manual test guidance** (critical paths to test manually)
6. **Performance check** (bundle size, load time)
7. **Security scan** (dependencies, vulnerabilities)

## Process

### 1. Automated Tests

```bash
# Run all test suites
npm test
# or
pytest

# Check coverage
npm run test:coverage
```

**Requirement**: ≥80% coverage for critical paths

### 2. Type Checking

```bash
# TypeScript
npx tsc --noEmit

# Python
mypy .
```

**Requirement**: Zero type errors

### 3. Linting

```bash
# TypeScript/JavaScript
npm run lint

# Python
pylint src/
black --check .
```

**Requirement**: All linting rules pass

### 4. Build Verification

```bash
# Next.js
npm run build

# React Native
npx expo build:ios
npx expo build:android

# FastAPI
python -m build
```

**Requirement**: Clean build with no errors

### 5. Screenshot Verification Protocol (UI)

**Problem solved**: Claude reviews screenshots, ignores errors, claims completion too early.

**Setup** (in your E2E test file):
```typescript
// tests/e2e/screenshots.spec.ts
import { test, expect } from '@playwright/test';

test('capture UI states', async ({ page }) => {
  await page.goto('/');
  await page.screenshot({ path: 'screenshots/01_home.png' });

  await page.click('[data-testid="login-button"]');
  await page.screenshot({ path: 'screenshots/02_login_modal.png' });

  // ... capture all functional states
});
```

**Verification Process**:

1. **Run E2E tests** → Screenshots captured to `screenshots/` folder
2. **Review EVERY screenshot** - no skipping
3. **For each screenshot**:
   - If UI correct → Rename to `verified_01_home.png`
   - If UI has errors → Fix code → Re-run tests → Re-capture
4. **Critical rule**: After renaming all screenshots, do NOT claim completion
5. **Next iteration** verifies all files have `verified_` prefix
6. **Only then** output completion promise

**Why 2+ loops are required**:
- Loop 1: Implement, test, review screenshots, rename to `verified_`
- Loop 2: Confirm ALL screenshots have `verified_` prefix, then complete

**Screenshot Checklist**:
```markdown
## Screenshot Verification

- [ ] All screenshots captured (no missing states)
- [ ] Each screenshot reviewed for UI errors:
  - [ ] Components render correctly (no broken layouts)
  - [ ] Text is readable (no overflow, truncation)
  - [ ] Colors/spacing match design
  - [ ] Interactive states visible (hover, focus, disabled)
  - [ ] Responsive layouts correct (if applicable)
- [ ] All screenshots renamed to `verified_[name].png`
- [ ] No unverified screenshots remain
```

**Integration with Ralph Loop**:
```bash
/ralph-loop "Implement [feature]" --max-iterations 5
# Loop continues until:
# 1. All tests pass
# 2. ALL screenshots have verified_ prefix
# 3. THEN completion promise is output
```

### 6. Manual Test Guidance

Generates checklist based on changes:

```markdown
🧪 MANUAL TESTING CHECKLIST

Based on your changes, test:

- [ ] Login flow (new auth added)
  - Try valid credentials
  - Try invalid credentials
  - Check password reset

- [ ] Profile page (UI changes)
  - Check on iPhone SE (small screen)
  - Check on iPad (large screen)
  - Test dark mode

- [ ] API endpoints (new routes added)
  - Test with valid data
  - Test with invalid data
  - Check error responses
  - Verify authentication required
```

### 6. Performance Check

```bash
# Bundle size
npm run build -- --analyze

# React Native bundle
npx expo export --dump-sourcemap

# Load time
lighthouse [URL] --only-categories=performance
```

**Thresholds**:
- Bundle size < 500KB (initial)
- FCP < 1.8s
- LCP < 2.5s

### 7. Security Scan

```bash
# Dependency audit
npm audit
pip-audit

# Check for secrets
git secrets --scan

# Dependency vulnerabilities
snyk test
```

**Requirement**: Zero critical/high vulnerabilities

## Output Report

```markdown
✅ VERIFICATION COMPLETE

## Test Results
✓ Unit tests: 234/234 passed (100%)
✓ Integration tests: 45/45 passed
✓ E2E tests: 12/12 passed
✓ Coverage: 87% (target: 80%)

## Type Checking
✓ TypeScript: 0 errors

## Linting
✓ ESLint: All rules passed

## Build
✓ Next.js build: Success
  - Bundle size: 423KB (within limit)

## Performance
✓ Lighthouse score: 94
  - FCP: 1.2s
  - LCP: 1.8s

## Security
✓ npm audit: 0 vulnerabilities
✓ No secrets detected

## Manual Testing Checklist
[ ] Login flow
[ ] Profile page
[ ] API endpoints

## Status: ✅ READY TO COMMIT

All automated checks passed.
Complete manual testing checklist above before committing.
```

## Integration with /guide

Step 7 of /guide workflow:

```bash
/guide → Plan → Execute → /verify-app → /commit-push-pr
```

## Integration with @orchestrator

Orchestrator automatically invokes verification after code changes:

```javascript
if (hasChanges) {
  Task(@verify-app "Verify recent changes")
}
```

## Integration with Ralph Loop

```bash
# Ralph Loop includes verification in completion check
/ralph-loop "Implement auth system"
# → Automatically runs verification each iteration
# → Only marks complete when verification passes
```

## Voice Notifications

```bash
# All checks pass
"All verification checks passed. Ready to commit."

# Some checks fail
"Verification found 3 issues. Please review."
```

## Quick Verify (Subset)

```bash
# Just tests
/verify-app --tests-only

# Just type check
/verify-app --types-only

# Just build
/verify-app --build-only
```

## CI/CD Integration

This command mirrors your CI/CD pipeline locally, so you catch issues before pushing:

**Local**:
```bash
/verify-app
```

**CI/CD** (GitHub Actions):
```yaml
- run: npm test
- run: npm run type-check
- run: npm run lint
- run: npm run build
```

If /verify-app passes, CI/CD will pass.

## Failure Investigation

If verification fails:

1. **Review output** for specific failures
2. **Fix issues** one by one
3. **Re-run verification**: `/verify-app`
4. **Consider**: `/system-evolve` to prevent future occurrences

## Notes

- Runs before every commit (via hooks)
- Catches issues early (cheaper to fix)
- Mirrors CI/CD locally
- Saves push/wait/fail cycles
- Part of quality enforcement

---

**Philosophy**: Catch issues locally before pushing. Fast feedback loop.
