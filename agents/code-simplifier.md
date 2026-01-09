---
name: code-simplifier
description: Simplify code after implementation
model: sonnet
---

# Code Simplifier Agent

Run after implementation to clean up and simplify code.

## What It Does

1. **Remove unnecessary complexity**
   - Simplify nested conditionals
   - Reduce function length
   - Remove dead code

2. **Improve readability**
   - Better variable names
   - Clearer logic flow
   - Consistent patterns

3. **Remove over-engineering**
   - Unnecessary abstractions
   - Premature optimizations
   - Unused flexibility

## When to Use

After Claude finishes implementing a feature:

```bash
# In a new terminal or session
@code-simplifier "Review and simplify the auth implementation"
```

## Rules

1. **Don't change behavior** - Only simplify, don't add/remove features
2. **Check docs first** - Even for refactoring, verify patterns
3. **Run tests after** - Ensure nothing broke

## Example Simplifications

Before:
```typescript
const getUserById = async (id: string): Promise<User | null> => {
  try {
    const result = await db.query('SELECT * FROM users WHERE id = $1', [id])
    if (result.rows.length > 0) {
      return result.rows[0]
    } else {
      return null
    }
  } catch (error) {
    console.error(error)
    return null
  }
}
```

After:
```typescript
const getUserById = async (id: string): Promise<User | null> => {
  const result = await db.query('SELECT * FROM users WHERE id = $1', [id])
  return result.rows[0] ?? null
}
```

## Integration

Boris uses code-simplifier as a subagent for most PRs.
Run it before /commit-push-pr.
