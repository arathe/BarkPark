#!/bin/bash
# BarkPark Automated Staging Deployment
# Deploys to staging with comprehensive safety checks

set -e  # Exit on any error

echo "🚀 BarkPark Automated Staging Deployment"
echo "========================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Ensure we're in the backend directory
if [ ! -f "package.json" ] || [ ! -d "routes" ]; then
    echo -e "${RED}❌ ERROR: Must run from backend directory${NC}"
    exit 1
fi

# 2. Check current branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "staging" ]; then
    echo -e "${RED}❌ ERROR: Not on staging branch!${NC}"
    echo "Current branch: $CURRENT_BRANCH"
    echo "Run: git checkout staging"
    exit 1
fi

# 3. Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️  WARNING: You have uncommitted changes${NC}"
    git status --short
    read -p "Stash changes and continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git stash push -m "Auto-stash before staging deployment $(date +%Y%m%d_%H%M%S)"
        echo "Changes stashed. Run 'git stash pop' after deployment to restore."
    else
        exit 1
    fi
fi

# 4. Pull latest from origin
echo "📥 Pulling latest from origin/staging..."
git pull origin staging

# 5. Run database sync check
echo "🔍 Checking database synchronization..."
if ! npm run db:migrate:status | grep -q "All migrations applied"; then
    echo -e "${RED}❌ ERROR: Database migrations not in sync!${NC}"
    echo "Run: npm run db:migrate"
    exit 1
fi

# 6. Run database integrity test
echo "🔍 Running database integrity check..."
if ! npm test -- tests/database-integrity.test.js --silent; then
    echo -e "${RED}❌ ERROR: Database integrity check failed!${NC}"
    exit 1
fi

# 7. Run full test suite
echo "🧪 Running full test suite..."
echo "This may take a few minutes..."
if ! npm test; then
    echo -e "${RED}❌ ERROR: Tests failed!${NC}"
    echo "Fix failing tests before deploying to staging."
    exit 1
fi

# 8. Final confirmation
echo -e "${GREEN}✅ All checks passed!${NC}"
echo ""
echo "Ready to deploy to staging:"
echo "  Branch: $CURRENT_BRANCH"
echo "  Target: https://barkpark-barkpark-staging.up.railway.app"
echo ""
read -p "Deploy to staging? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# 9. Push to staging
echo "🚀 Pushing to staging..."
git push origin staging

# 10. Monitor deployment
echo "⏳ Waiting for Railway deployment to complete..."
echo "Check Railway dashboard: https://railway.app/dashboard"
echo ""

# Wait for deployment to propagate
for i in {1..6}; do
    echo -n "."
    sleep 10
done
echo ""

# 11. Verify deployment
echo "🔍 Verifying staging deployment..."
HEALTH_URL="https://barkpark-barkpark-staging.up.railway.app/health"

if curl -f -s "$HEALTH_URL" > /dev/null; then
    echo -e "${GREEN}✅ Staging deployment successful!${NC}"
    echo ""
    echo "Staging API Health Response:"
    curl -s "$HEALTH_URL" | python3 -m json.tool || curl -s "$HEALTH_URL"
    echo ""
    echo -e "${GREEN}🎉 Deployment complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Test staging API: https://barkpark-barkpark-staging.up.railway.app/api"
    echo "2. Build iOS app with staging scheme for TestFlight"
else
    echo -e "${RED}❌ WARNING: Staging health check failed!${NC}"
    echo "The deployment may still be in progress."
    echo "Check Railway logs: https://railway.app/dashboard"
    exit 1
fi