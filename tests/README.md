# App Tests

Complete test suite for app.py with unit, integration, and docker-based tests.

## Test Structure

```
tests/
├── unit/
│   └── test_app.py          # Unit tests (mocked Redis, fast)
└── integration/
    └── test_api.py          # Integration tests (real Redis/API)
```

## Running Tests

### 1. Unit Tests Only (Fast, No Dependencies)

Unit tests use mocked Redis and don't require any services running.

```bash
# Install test dependencies
pip install -r requirements.txt

# Run all unit tests
pytest tests/unit/ -v

# Run specific test
pytest tests/unit/test_app.py::TestCounterHandler::test_get_root_path_increments_counter -v

# Run with coverage report
pytest tests/unit/ --cov=app --cov-report=html
```

#### Available Unit Tests
- `test_get_root_path_increments_counter` - Verify GET / increments counter
- `test_get_with_query_params` - Verify query parameters are handled
- `test_get_invalid_path_returns_404` - Verify invalid paths return 404
- `test_response_contains_counter_value` - Verify counter in HTML response
- `test_run_starts_server` - Verify server initialization

---

### 2. Integration Tests (With Redis)

Integration tests require Redis and the app running.

#### Option A: Using Docker Compose

```bash
# Start all services (Redis + App + Tests)
docker-compose -f docker-compose.test.yml up --build

# Or run services separately:
# Terminal 1: Start Redis
docker run -p 6379:6379 redis:7-alpine

# Terminal 2: Start app
python app.py

# Terminal 3: Run integration tests
pytest tests/integration/ -v
```

#### Option B: Using Minikube

```bash
# Verify services are running
kubectl get pods

# Port-forward Redis (if needed)
kubectl port-forward svc/redis 6379:6379 &

# Port-forward App
kubectl port-forward svc/app 8000:8000 &

# Run integration tests
pytest tests/integration/ -v
```

#### Available Integration Tests
- `test_redis_connection` - Verify Redis connectivity
- `test_set_and_get_counter` - Verify Redis get/set operations
- `test_increment_counter` - Verify counter increment
- `test_api_health_check` - Verify API is responding
- `test_api_returns_html` - Verify response format
- `test_api_counter_displays` - Verify counter value in response
- `test_multiple_requests_increment_counter` - Verify counter increments across requests
- `test_api_invalid_path_404` - Verify 404 handling
- `test_redis_persistence` - Verify counter persistence
- `test_counter_increments_atomically` - Verify atomic increments

---

### 3. Run All Tests

```bash
# Run all tests (unit + integration where available)
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=app --cov-report=html --cov-report=term

# Run specific markers
pytest -m unit -v       # Only unit tests
pytest -m integration -v # Only integration tests
```

---

## Test Configuration

### pytest.ini
- `testpaths`: Search tests/ directory
- `python_files`: Files matching test_*.py
- `addopts`: Default options (-v, shorter tracebacks)
- `markers`: Custom test markers (unit, integration, e2e)

### Environment Variables

For integration tests, set these to customize Redis/API connection:

```bash
export REDIS_HOST=localhost      # Default: localhost
export REDIS_PORT=6379           # Default: 6379
export APP_URL=http://localhost:8000  # Default: http://localhost:8000

pytest tests/integration/ -v
```

---

## Docker Compose Testing

### Start All Services

```bash
docker-compose -f docker-compose.test.yml up --build
```

This starts:
1. **Redis** - Database
2. **App** - Python application
3. **Tests** - Runs pytest and generates coverage reports

Test results saved to `test-results/` directory.

### Individual Service Commands

```bash
# Start only Redis
docker-compose -f docker-compose.test.yml up redis

# Start only Redis + App (for local test development)
docker-compose -f docker-compose.test.yml up redis app

# Run tests against running services
docker-compose -f docker-compose.test.yml run tests
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: pip install -r requirements.txt
      
      - name: Run unit tests
        run: pytest tests/unit/ --cov=app
      
      - name: Run integration tests (with Docker Compose)
        run: docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

---

## Expected Test Results

### Unit Tests
```
tests/unit/test_app.py::TestCounterHandler::test_get_root_path_increments_counter PASSED
tests/unit/test_app.py::TestCounterHandler::test_get_with_query_params PASSED
tests/unit/test_app.py::TestCounterHandler::test_get_invalid_path_returns_404 PASSED
tests/unit/test_app.py::TestCounterHandler::test_response_contains_counter_value PASSED
tests/unit/test_app.py::TestServerRun::test_run_starts_server PASSED

====== 5 passed in 0.23s ======
```

### Integration Tests (with Redis)
```
tests/integration/test_api.py::TestAppIntegration::test_redis_connection PASSED
tests/integration/test_api.py::TestAppIntegration::test_set_and_get_counter PASSED
tests/integration/test_api.py::TestAppIntegration::test_api_counter_displays PASSED
tests/integration/test_api.py::TestAppWithRedisContainer::test_counter_increments_atomically PASSED

====== 4 passed in 1.45s ======
```

---

## Troubleshooting

### "Redis not available" - Integration tests skipped

**Solution**: Start Redis before running integration tests:
```bash
# Docker
docker run -p 6379:6379 redis:7-alpine

# Or Kubernetes
kubectl port-forward svc/redis 6379:6379
```

### "App not available at http://localhost:8000"

**Solution**: Start the app:
```bash
python app.py
```

### "ModuleNotFoundError: No module named 'redis'"

**Solution**: Install dependencies:
```bash
pip install -r requirements.txt
```

### Coverage report not generated

**Solution**: Install pytest-cov:
```bash
pip install pytest-cov
```

---

## Best Practices

1. **Always run unit tests first** - They're fast and catch logic errors
2. **Use ` docker-compose.test.yml` for CI/CD** - Ensures consistent environment
3. **Mock external services in unit tests** - Keep them fast and isolated
4. **Integration tests verify real behavior** - Use them before deployment
5. **Check coverage reports** - Aim for >80% code coverage

---

## Next Steps

- Add E2E tests for Kubernetes deployments (k8s/test-job.yml)
- Set up GitHub Actions for automated testing
- Add performance tests for load testing
- Implement security tests (dependency scanning, etc.)
