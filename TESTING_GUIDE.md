# BarkPark Testing Guide

## ⚠️ CRITICAL: Test Execution Must Be Sequential ⚠️

The BarkPark test infrastructure is designed for **sequential execution only**. Running tests in parallel will cause massive failures due to database conflicts.

## Quick Start

```bash
# ALWAYS use these commands:
cd backend && npm test              # Runs sequentially with --runInBand
cd backend && npm test -- tests/auth.test.js  # Run specific test file

# NEVER use:
cd backend && jest                  # Will run in parallel and fail!
```

## Why Tests Fail (And How We Fixed It)

### The Problem
- Jest runs tests in parallel by default
- Our tests share a single test database
- Parallel execution causes:
  - Deadlocks during TRUNCATE operations
  - Foreign key violations
  - Race conditions

### The Solution
- `package.json` now defaults to sequential execution
- All tests must use `beforeEach` (never `beforeAll`)
- Test data is created fresh for each test

## Critical Testing Patterns

### 1. Test Data Creation
```javascript
// ✅ CORRECT - Use beforeEach
beforeEach(async () => {
  const userData = testDataFactory.createUserData();
  testUser = await User.create(userData);
});

// ❌ WRONG - Never use beforeAll
beforeAll(async () => {
  // Data created here will be deleted by setup.js!
});
```

### 2. Mock Scoping
```javascript
// ✅ CORRECT - Import inside mock factory
jest.mock('../middleware/auth', () => {
  const jwt = require('jsonwebtoken');
  return {
    verifyToken: (req, res, next) => {
      // jwt is available here
    }
  };
});

// ❌ WRONG - Reference outer scope
const jwt = require('jsonwebtoken');
jest.mock('../middleware/auth', () => ({
  verifyToken: (req, res, next) => {
    // jwt is NOT available here!
  }
}));
```

### 3. Database Cleanup
```javascript
// ✅ CORRECT - Let setup.js handle it
// Don't add any cleanup code

// ❌ WRONG - Manual cleanup
afterEach(async () => {
  await pool.query('DELETE FROM users');
});
```

## Test Organization

### Directory Structure
```
backend/
├── tests/
│   ├── setup.js           # Global test setup (runs automatically)
│   ├── auth.test.js       # Authentication tests
│   ├── posts.test.js      # Post/feed tests
│   ├── models/           # Model-specific tests
│   │   ├── friendship.test.js
│   │   └── dogpark-postgis.test.js
│   ├── routes/           # Route-specific tests
│   │   ├── friends.test.js
│   │   └── dogs-photos.test.js
│   └── utils/            # Test utilities
│       ├── testDataFactory.js
│       └── testMocks.js
```

### Test Utilities

#### testDataFactory.js
Generates unique test data with timestamps:
```javascript
const userData = testDataFactory.createUserData();
// Returns: { email: 'test1234567890_1_abc123@example.com', ... }

const dogData = testDataFactory.createDogData(userId);
const parkData = testDataFactory.createParkData();
```

#### Global Mocks (setup.js)
These are automatically mocked:
- AWS SDK (S3)
- Nodemailer
- Don't re-mock these in your tests!

## Common Issues and Solutions

### Issue: "deadlock detected"
**Cause**: Multiple tests trying to TRUNCATE tables simultaneously
**Solution**: Ensure you're running with `npm test` (not `jest` directly)

### Issue: "foreign key constraint violation"
**Cause**: Creating child records before parent records
**Solution**: Create data in correct order:
```javascript
const user = await User.create(userData);
const dog = await Dog.create({ ...dogData, userId: user.id });
```

### Issue: "Invalid variable access" in mocks
**Cause**: Mock trying to access variables from outer scope
**Solution**: Import dependencies inside the mock factory function

### Issue: Tests pass individually but fail together
**Cause**: Tests are not properly isolated
**Solution**: 
- Use unique test data (testDataFactory)
- Don't share state between tests
- Use beforeEach, not beforeAll

## Running Tests

### Backend Tests
```bash
# Run all tests (sequential)
cd backend && npm test

# Run specific test suite
cd backend && npm test -- tests/auth.test.js

# Run with verbose output
cd backend && npm test -- --verbose

# Run tests matching pattern
cd backend && npm test -- --testNamePattern="should create user"

# Run with coverage
cd backend && npm test -- --coverage
```

### iOS Tests
```bash
# Run iOS unit tests
cd ios && xcodebuild test -project BarkPark.xcodeproj -scheme BarkPark \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.5'

# Run specific test class
cd ios && xcodebuild test -project BarkPark.xcodeproj -scheme BarkPark \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.5' \
  -only-testing:BarkParkTests/AuthenticationManagerTests
```

## Test Database Setup

The test database (`barkpark_test`) should be created from the main database:

```bash
# Create test database (one-time setup)
createdb barkpark_test
pg_dump barkpark | psql barkpark_test

# Apply any new migrations to test database
psql barkpark_test -f backend/migrations/XXX_migration_name.sql
```

## Writing New Tests

### Test Structure Template
```javascript
const request = require('supertest');
const app = require('../server');
const { User } = require('../models/User');
const testDataFactory = require('./utils/testDataFactory');

// Mock auth middleware
jest.mock('../middleware/auth', () => ({
  verifyToken: (req, res, next) => {
    req.user = { id: req.headers.authorization?.split(' ')[1] || '1' };
    next();
  }
}));

describe('Feature Name', () => {
  let testUser;
  let authToken;

  beforeEach(async () => {
    // Create test data
    const userData = testDataFactory.createUserData();
    testUser = await User.create(userData);
    authToken = testUser.id; // Simplified for testing
  });

  describe('POST /api/endpoint', () => {
    it('should perform action successfully', async () => {
      const response = await request(app)
        .post('/api/endpoint')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ data: 'test' })
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });
});
```

## CI/CD Considerations

When setting up CI/CD:
1. Always use `npm test` (not `jest` directly)
2. Ensure test database is properly initialized
3. Set required environment variables
4. Consider using separate test databases per CI job

## Performance Tips

- Sequential tests are slower but reliable
- To speed up development:
  - Run only the test file you're working on
  - Use `.only` to run specific tests
  - Use `--watch` mode for development

## Debugging Failed Tests

1. Run with verbose output: `npm test -- --verbose`
2. Add console.logs (they'll appear in test output)
3. Check the exact error message and stack trace
4. Verify test data is being created correctly
5. Ensure mocks are properly configured

## Test Success Metrics

- **Target**: >90% test success rate
- **History**:
  - Session 11: 68.3% → 89.8%
  - Session 12: 89.8% → 95.4%
  - Current: ~60-70% (sequential)

Remember: **Always run tests sequentially!** This is the key to avoiding the cascade of failures we've seen in the past.