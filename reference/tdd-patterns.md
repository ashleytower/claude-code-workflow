# TDD Patterns Reference

Deep reference for test-driven development patterns. Load when needed.

## Test Doubles

| Type | Purpose | When to Use |
|------|---------|-------------|
| Mock | Verify interactions | Check if method was called with specific args |
| Stub | Return canned responses | Replace external service with fixed data |
| Fake | Working implementation | In-memory database for tests |
| Spy | Record calls | Verify call count, order |

### Python Mocking

```python
from unittest.mock import patch, MagicMock

# Patch external service
@patch('module.external_api')
def test_calls_api(mock_api):
    mock_api.return_value = {"status": "success"}

    result = my_function()

    mock_api.assert_called_once_with(expected_args)
    assert result["status"] == "success"

# Mock class method
@patch.object(MyClass, 'method_name')
def test_method(mock_method):
    mock_method.return_value = "mocked"
    # ...

# Context manager style
def test_with_context():
    with patch('module.function') as mock_fn:
        mock_fn.return_value = "value"
        result = code_under_test()
```

### JavaScript Mocking (Jest)

```javascript
// Mock module
jest.mock('./api', () => ({
  fetchData: jest.fn(() => Promise.resolve({ data: 'mocked' }))
}));

// Spy on method
const spy = jest.spyOn(object, 'method');
expect(spy).toHaveBeenCalledWith('arg');

// Mock implementation
mockFunction.mockImplementation(() => 'custom');
```

## Test Data Factories

```python
from uuid import uuid4
from datetime import datetime, timedelta

def create_user(**overrides):
    defaults = {
        "id": str(uuid4()),
        "email": f"user_{uuid4().hex[:8]}@example.com",
        "name": "Test User",
        "created_at": datetime.now(),
        "is_active": True,
    }
    return {**defaults, **overrides}

def create_order(**overrides):
    defaults = {
        "id": str(uuid4()),
        "user_id": str(uuid4()),
        "total": 100.00,
        "status": "pending",
        "items": [],
    }
    return {**defaults, **overrides}

# Usage
def test_order_total():
    user = create_user(name="John")
    order = create_order(user_id=user["id"], total=250.00)
    # ...
```

## Fixtures (pytest)

```python
import pytest

# Simple fixture
@pytest.fixture
def sample_user():
    return create_user(name="Fixture User")

# Fixture with cleanup
@pytest.fixture
def database_connection():
    conn = create_connection()
    yield conn
    conn.close()

# Scoped fixture (once per session)
@pytest.fixture(scope="session")
def app():
    return create_app(testing=True)

# Fixture that uses other fixtures
@pytest.fixture
def authenticated_client(app, sample_user):
    client = app.test_client()
    client.login(sample_user)
    return client

# Auto-use fixture
@pytest.fixture(autouse=True)
def reset_state():
    yield
    clear_all_caches()
```

## Async Testing

### Python (pytest-asyncio)

```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    result = await async_operation()
    assert result == expected

# Async fixture
@pytest.fixture
async def async_client():
    client = await create_async_client()
    yield client
    await client.close()
```

### JavaScript (Jest)

```javascript
test('async operation', async () => {
  const result = await asyncFunction();
  expect(result).toBe(expected);
});

// With done callback
test('callback style', (done) => {
  asyncFunction((result) => {
    expect(result).toBe(expected);
    done();
  });
});
```

## Integration Test Structure

```python
class TestUserWorkflow:
    """Integration tests for user registration flow."""

    @pytest.fixture(autouse=True)
    def setup(self, test_db, test_email_service):
        self.db = test_db
        self.email = test_email_service
        self.service = UserService(db=self.db, email=self.email)

    def test_registration_stores_user(self):
        result = self.service.register("new@example.com", "password123")

        user = self.db.get_user(result["id"])
        assert user is not None
        assert user["email"] == "new@example.com"

    def test_registration_sends_welcome_email(self):
        self.service.register("new@example.com", "password123")

        assert self.email.sent_count == 1
        assert self.email.last_recipient == "new@example.com"

    def test_duplicate_email_raises_error(self):
        self.service.register("existing@example.com", "pass1")

        with pytest.raises(DuplicateEmailError):
            self.service.register("existing@example.com", "pass2")
```

## Database Testing

```python
@pytest.fixture(scope="function")
def test_db():
    """Fresh database for each test."""
    db = create_test_database()
    db.migrate()
    yield db
    db.drop_all()

# Or with transactions (faster)
@pytest.fixture
def test_db(base_db):
    """Wrap each test in a transaction that rolls back."""
    connection = base_db.connect()
    transaction = connection.begin()
    yield connection
    transaction.rollback()
    connection.close()
```

## HTTP Mocking

### Python (responses)

```python
import responses

@responses.activate
def test_api_call():
    responses.add(
        responses.GET,
        "https://api.example.com/users",
        json={"users": []},
        status=200
    )

    result = fetch_users()

    assert result == []
    assert len(responses.calls) == 1
```

### Python (httpx + respx)

```python
import respx

@respx.mock
async def test_async_api():
    respx.get("https://api.example.com/data").respond(json={"key": "value"})

    result = await async_fetch()

    assert result["key"] == "value"
```

## Snapshot Testing

### JavaScript (Jest)

```javascript
test('component renders correctly', () => {
  const tree = renderer.create(<Button label="Click" />).toJSON();
  expect(tree).toMatchSnapshot();
});
```

### Python (syrupy)

```python
def test_api_response(snapshot):
    response = get_api_response()
    assert response == snapshot
```

## Test File Structure

```
tests/
├── unit/                    # Fast, isolated tests
│   ├── test_models.py
│   ├── test_validators.py
│   └── test_utils.py
├── integration/             # Tests with real dependencies
│   ├── test_api.py
│   ├── test_database.py
│   └── test_external_services.py
├── e2e/                     # Full system tests
│   └── test_user_flows.py
├── conftest.py              # Shared fixtures
├── factories.py             # Test data factories
└── fixtures/                # Static test data
    ├── sample_response.json
    └── test_image.png
```

## Common Patterns

### Testing Exceptions

```python
def test_invalid_input_raises():
    with pytest.raises(ValueError) as exc_info:
        process_data(None)

    assert "cannot be None" in str(exc_info.value)
```

### Testing Logs

```python
def test_logs_warning(caplog):
    with caplog.at_level(logging.WARNING):
        risky_operation()

    assert "potential issue" in caplog.text
```

### Testing Time

```python
from freezegun import freeze_time

@freeze_time("2026-01-15 12:00:00")
def test_time_sensitive():
    result = get_current_greeting()
    assert result == "Good afternoon"
```

### Testing Environment Variables

```python
def test_with_env(monkeypatch):
    monkeypatch.setenv("API_KEY", "test-key")

    result = get_api_key()

    assert result == "test-key"
```

## Coverage

```bash
# Python
pytest --cov=src --cov-report=html

# JavaScript
jest --coverage
```

Aim for:
- 80%+ on critical paths
- 100% on business logic
- Don't chase 100% overall (diminishing returns)
