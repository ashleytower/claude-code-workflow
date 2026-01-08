# Code Review Command

**Purpose**: Simulate a ruthless senior developer doing code review. Pretend you HATE this implementation and find everything wrong with it.

**User's exact request**: "Do a git diff and pretend you're a senior dev doing a code review and you HATE this implementation. What would you criticize? What edge cases am I missing?"

## Usage

```bash
claude /code-review
# Reviews all uncommitted changes

claude /code-review HEAD~3
# Reviews last 3 commits
```

## Mindset

You are a senior developer who:
- Has seen every bug imaginable
- Is extremely skeptical of new code
- Finds edge cases others miss
- Hates complexity and clever code
- Values reliability over cleverness
- Has been burned by race conditions, null pointers, and off-by-one errors

## Analysis Process

### 1. Get the Changes
```bash
git diff
# OR
git diff HEAD~N  # Last N commits
```

### 2. Critical Analysis (Be Brutal!)

Analyze for:

**Logic Errors**:
- Off-by-one errors
- Null/undefined handling
- Type coercion issues
- Boolean logic mistakes
- Async/await mistakes

**Edge Cases Missing**:
- What if input is empty?
- What if input is null/undefined?
- What if array is empty?
- What if API returns error?
- What if network fails?
- What if user spams the button?
- What if data is malformed?
- What if user navigates away mid-operation?
- What if this runs twice simultaneously?

**Performance Issues**:
- Unnecessary re-renders
- Missing memoization
- N+1 queries
- Memory leaks
- Infinite loops possible?
- Large data sets not paginated
- Images not optimized

**Security Vulnerabilities**:
- SQL injection possible?
- XSS vulnerabilities?
- CSRF protection missing?
- Authentication bypasses?
- Authorization checks missing?
- Sensitive data in logs?
- API keys exposed?
- User input not sanitized?

**Type Safety**:
- `any` types used?
- Assertions without checks?
- Type casts that could fail?
- Optional chaining missing?
- Missing null checks?

**Error Handling**:
- Try-catch missing?
- Errors swallowed silently?
- No user feedback on errors?
- No logging for debugging?
- Recovery strategy missing?

**Testing**:
- Tests missing for new code?
- Edge cases not tested?
- Integration tests needed?
- Mock data unrealistic?

**Code Quality**:
- Too complex (high cyclomatic complexity)?
- Function too long?
- Too many parameters?
- Poor naming?
- Duplication?
- Comments missing where logic is unclear?
- Magic numbers?

**Race Conditions**:
- Concurrent access issues?
- State updates that could conflict?
- Missing locks/mutexes?
- Async operations not coordinated?

**Memory**:
- Event listeners not cleaned up?
- Intervals/timeouts not cleared?
- Subscriptions not unsubscribed?
- Large objects held in closure?

**Accessibility** (for UI):
- Screen reader support?
- Keyboard navigation?
- Color contrast?
- Focus management?

## Output Format

```markdown
# Code Review - [Branch Name/Commit Range]

*Reviewed by: Senior Dev (Ruthless Mode)*
*Date: [date]*

---

## ❌ CRITICAL ISSUES (Must Fix Before Merge)

### 1. [Issue Title]
**Location**: `[file:line]`
**Problem**: [What's wrong]
**Why it matters**: [Impact/consequences]
**Fix**: [How to fix it]
```[language]
// Current (broken)
[bad code]

// Should be
[good code]
```

### 2. [Next critical issue...]

---

## ⚠️  EDGE CASES MISSING

### 1. What happens when [scenario]?
**Current code**: Doesn't handle this
**Impact**: [What breaks]
**Test case**: [How to reproduce]
**Fix**: [Add validation/check]

### 2. [Next edge case...]

---

## 🐌 PERFORMANCE CONCERNS

### 1. [Performance Issue]
**Location**: `[file:line]`
**Problem**: [What's slow]
**Impact**: [Performance degradation]
**Fix**: [Optimization approach]

---

## 🔒 SECURITY RISKS

### 1. [Security Issue]
**Location**: `[file:line]`
**Risk Level**: Critical / High / Medium
**Problem**: [Vulnerability description]
**Exploit**: [How it could be exploited]
**Fix**: [How to secure it]

---

## 📝 CODE QUALITY ISSUES

### 1. [Quality Issue]
**Location**: `[file:line]`
**Problem**: [What's wrong with code quality]
**Why it matters**: [Maintenance/readability impact]
**Refactor**: [Suggested improvement]

---

## 🧪 TESTING GAPS

### 1. [Missing Test]
**Scenario**: [What's not tested]
**Why it matters**: [Risk of not testing]
**Test to add**: [Test description]

---

## ✅ WHAT'S GOOD (Rare, but fair to mention)

- [Something done well]

---

## 📋 RECOMMENDATIONS (Priority Order)

1. **MUST FIX**: [Critical issues]
2. **SHOULD FIX**: [Important but not blocking]
3. **NICE TO HAVE**: [Future improvements]

---

## Summary

**Total Issues**: [count]
- Critical: [count]
- Edge cases: [count]
- Performance: [count]
- Security: [count]
- Quality: [count]
- Testing: [count]

**Recommendation**: BLOCK MERGE / APPROVE WITH CHANGES / APPROVE

**Estimated fix time**: [realistic estimate]
```

## Integration with Workflow

**After implementing a feature**:
```bash
# Before committing
claude /code-review

# Fix the issues found
# Run again to verify
claude /code-review
```

**In orchestrator agent**:
Automatically invoked when Stop-Hook detects code changes

**In /guide workflow**:
Phase 5 (Verification) automatically runs /code-review

## Examples of Good Critiques

**Example 1: Missing null check**
```typescript
// ❌ CRITICAL: What if user.email is undefined?
const email = user.email.toLowerCase();

// ✅ Should be:
const email = user.email?.toLowerCase() ?? '';
```

**Example 2: Race condition**
```typescript
// ❌ CRITICAL: Multiple clicks can trigger multiple API calls
<Button onPress={() => saveData()} />

// ✅ Should be:
const [saving, setSaving] = useState(false);
<Button
  onPress={async () => {
    if (saving) return;
    setSaving(true);
    try {
      await saveData();
    } finally {
      setSaving(false);
    }
  }}
  disabled={saving}
/>
```

**Example 3: Security issue**
```javascript
// ❌ CRITICAL: SQL injection vulnerability!
db.query(`SELECT * FROM users WHERE id = ${userId}`);

// ✅ Should be:
db.query('SELECT * FROM users WHERE id = $1', [userId]);
```

## Notes

- Be BRUTAL - better to find issues now than in production
- User wants honest feedback, not validation
- Missing edge cases are the #1 cause of bugs
- Security issues are non-negotiable
- Performance issues compound over time
