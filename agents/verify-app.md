---
name: verify-app
description: Run all tests and verification
model: sonnet
---

# Verify App Agent

Run comprehensive verification before commit.

## Steps

### 1. Tests
```bash
npm test -- --coverage
# or: pytest --cov=src tests/
```

### 2. Type Check
```bash
npx tsc --noEmit
# or: mypy src/
```

### 3. Lint
```bash
npm run lint
# or: ruff check src/
```

### 4. Build
```bash
npm run build
```

### 5. Security
```bash
npm audit --audit-level=moderate
```

## After Verification

If all pass, suggest:
1. `/commit-push-pr` - create PR
2. `/learn 'feature-name'` - if new integration detected

## Skill Detection

Check package.json for new integrations:
- stripe -> suggest `/learn 'stripe-payments'`
- resend -> suggest `/learn 'resend-emails'`
- @clerk -> suggest `/learn 'clerk-auth'`
