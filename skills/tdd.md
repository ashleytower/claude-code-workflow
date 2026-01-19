---
name: tdd
description: Test-driven development workflow. Invoke when you want test-first discipline for features or bug fixes.
---

# TDD Skill - Test First Development

## Uncle Bob's Three Laws

1. Write no production code until you have a failing test
2. Write only enough test to demonstrate a failure
3. Write only enough production code to pass the test

## The Loop

```
RED    → Write failing test
GREEN  → Minimal code to pass
REFACTOR → Clean up, tests stay green
```

## Before Writing Tests

Use existing research tools:
- `Skill(research)` for framework patterns
- Context7 MCP for library-specific testing docs
- `Grep` codebase for existing test patterns

```bash
# Find existing test patterns
Grep: "def test_|it\(|test\(" output_mode: content

# Find test configuration
Glob: "**/conftest.py" or "**/jest.config.*"
```

## Test Naming

`test_{unit}_{scenario}_{expected_result}`

Examples:
- `test_user_empty_email_raises_validation_error`
- `test_payment_successful_creates_invoice`
- `test_search_no_results_returns_empty_list`

## Test Structure (AAA)

```python
def test_example():
    # Arrange - Set up test data
    user = create_test_user(email="test@example.com")

    # Act - Execute code under test
    result = user.get_display_name()

    # Assert - Verify result
    assert result == "test@example.com"
```

## Edge Cases (Always Test)

- Empty input
- Invalid types
- Boundary values (0, -1, max)
- Null/None handling
- Error conditions
- Concurrent access (if applicable)

## Parameterized Tests

```python
@pytest.mark.parametrize("input,expected", [
    ("", False),
    ("invalid", False),
    ("user@example.com", True),
    ("user+tag@example.com", True),
])
def test_email_validation(input, expected):
    assert is_valid_email(input) == expected
```

## Frameworks

| Language | Framework | Run Command |
|----------|-----------|-------------|
| Python | pytest | `pytest -v` |
| JavaScript | Jest | `npm test` |
| TypeScript | Vitest | `npx vitest` |
| Go | testing | `go test ./...` |
| Rust | cargo | `cargo test` |

## Workflow

1. **Clarify** - What should this do? What are edge cases?
2. **Research** - Check docs for testing patterns (`Skill(research)`)
3. **Write Test** - Describe expected behavior
4. **Run Test** - Confirm it fails for the right reason
5. **Write Code** - Minimal implementation
6. **Run Test** - Confirm it passes
7. **Refactor** - Clean up, run tests again

## When to Use TDD

**Good for:**
- Business logic
- Data transformations
- Bug fixes (reproduce bug as test first)
- API endpoints
- Complex algorithms

**Skip for:**
- Quick UI prototypes
- Config changes
- One-off scripts
- Exploratory coding

## Deep Reference

For mocking, fixtures, factories, and integration patterns:
```bash
Read: ~/.claude/reference/tdd-patterns.md
```

## Integration

Works with other skills:
- `Skill(research)` - Find testing patterns first
- `Skill(verify-app)` - Run full test suite after
- `Skill(commit-push-pr)` - Commit when tests pass
