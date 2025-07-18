#!/bin/bash
# Setup script to install git hooks for BarkPark

echo "🔧 Setting up BarkPark git hooks..."

# Navigate to repository root
cd "$(git rev-parse --show-toplevel)"

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# BarkPark Pre-commit Hook
# Automated checks to prevent database sync issues and maintain code quality

echo "🔍 Running automated pre-commit checks..."

# Navigate to backend directory
cd backend 2>/dev/null || { echo "❌ ERROR: backend directory not found"; exit 1; }

# 1. Check for database schema drift
echo "📊 Checking database migration status..."
if ! npm run db:migrate:status | grep -q "All migrations applied"; then
    echo "❌ ERROR: Unapplied migrations detected!"
    echo "👉 Run: npm run db:migrate"
    exit 1
fi

# 2. Run database integrity test
echo "🔍 Running database integrity check..."
if ! npm test -- tests/database-integrity.test.js --silent; then
    echo "❌ ERROR: Database integrity check failed!"
    echo "This usually means there's a mismatch between your local DB and the application code."
    echo "Check for manual database changes that need to be captured in a migration."
    exit 1
fi

# 3. Check for console.logs in staged files
echo "🔍 Checking for console.log statements..."
STAGED_FILES=$(git diff --cached --name-only | grep -E '\.(js|jsx|ts|tsx)$' || true)
if [ -n "$STAGED_FILES" ]; then
    if echo "$STAGED_FILES" | xargs grep -l 'console\.log' 2>/dev/null; then
        echo "⚠️  WARNING: console.log found in staged files"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# 4. Check for common issues
echo "🔍 Checking for common issues..."

# Check for .env files
if git diff --cached --name-only | grep -E '\.env'; then
    echo "❌ ERROR: Attempting to commit .env file!"
    echo "Remove it with: git reset HEAD .env"
    exit 1
fi

# Check for AWS credentials
if git diff --cached --name-only | xargs grep -l 'AWS_SECRET_ACCESS_KEY\|AWS_ACCESS_KEY_ID' 2>/dev/null; then
    echo "❌ ERROR: AWS credentials detected in staged files!"
    exit 1
fi

# 5. Run critical tests (fast subset, not full suite)
echo "🧪 Running critical tests..."
if ! npm test -- tests/database-integrity.test.js tests/auth.test.js --silent --testTimeout=10000; then
    echo "❌ ERROR: Critical tests failed!"
    exit 1
fi

echo "✅ All pre-commit checks passed!"
echo "📝 Proceeding with commit..."
EOF

# Make hook executable
chmod +x .git/hooks/pre-commit

echo "✅ Git hooks installed successfully!"
echo ""
echo "The pre-commit hook will now run automatically before each commit to:"
echo "  • Check database migration status"
echo "  • Verify database integrity"
echo "  • Scan for console.logs and credentials"
echo "  • Run critical tests"
echo ""
echo "To test the hook manually, run: npm run precommit"