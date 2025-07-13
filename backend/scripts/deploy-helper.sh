#!/bin/bash

# BarkPark Deployment Helper Script
# Helps manage deployments to different environments

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "BarkPark Deployment Helper"
    echo ""
    echo "Usage: $0 [command] [environment]"
    echo ""
    echo "Commands:"
    echo "  deploy       Deploy to specified environment"
    echo "  status       Check deployment status"
    echo "  migrate      Run migrations on environment"
    echo "  rollback     Show rollback instructions"
    echo ""
    echo "Environments:"
    echo "  staging      Deploy to staging branch/environment"
    echo "  production   Deploy to main branch/production"
    echo ""
    echo "Examples:"
    echo "  $0 deploy staging"
    echo "  $0 status production"
    echo "  $0 migrate staging"
}

# Function to check current branch
check_branch() {
    current_branch=$(git branch --show-current)
    echo -e "${BLUE}Current branch: $current_branch${NC}"
}

# Function to deploy to environment
deploy() {
    local env=$1
    local target_branch=""
    
    case $env in
        staging)
            target_branch="staging"
            ;;
        production)
            target_branch="main"
            ;;
        *)
            echo -e "${RED}Error: Unknown environment '$env'${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${YELLOW}Deploying to $env environment (branch: $target_branch)${NC}"
    
    # Check for uncommitted changes
    if [[ -n $(git status -s) ]]; then
        echo -e "${RED}Error: You have uncommitted changes${NC}"
        echo "Please commit or stash your changes before deploying"
        exit 1
    fi
    
    # Fetch latest changes
    echo "Fetching latest changes..."
    git fetch origin
    
    # Show current status
    check_branch
    
    # Confirm deployment
    echo ""
    read -p "Deploy current branch to $env? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled"
        exit 0
    fi
    
    # Merge to target branch
    echo -e "${BLUE}Switching to $target_branch branch...${NC}"
    git checkout $target_branch
    
    echo -e "${BLUE}Merging changes...${NC}"
    git merge -
    
    echo -e "${BLUE}Pushing to $target_branch...${NC}"
    git push origin $target_branch
    
    echo -e "${GREEN}✓ Deployment to $env initiated!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Check Railway dashboard for deployment progress"
    echo "2. Monitor logs: railway logs --service=barkpark-$env"
    echo "3. Verify health: curl https://barkpark-$env.up.railway.app/api/health"
}

# Function to check deployment status
status() {
    local env=$1
    local url=""
    
    case $env in
        staging)
            url="https://barkpark-staging.up.railway.app/api/health"
            ;;
        production)
            url="https://barkpark-production.up.railway.app/api/health"
            ;;
        *)
            echo -e "${RED}Error: Unknown environment '$env'${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${BLUE}Checking $env environment status...${NC}"
    echo ""
    
    # Check health endpoint
    if curl -s "$url" | jq . 2>/dev/null; then
        echo ""
        echo -e "${GREEN}✓ $env environment is healthy${NC}"
    else
        echo -e "${RED}✗ Failed to reach $env environment${NC}"
        exit 1
    fi
}

# Function to run migrations
migrate() {
    local env=$1
    
    echo -e "${YELLOW}Running migrations on $env environment${NC}"
    echo ""
    echo "To run migrations manually:"
    echo ""
    
    case $env in
        staging)
            echo "railway run npm run db:migrate --service=barkpark-staging"
            ;;
        production)
            echo "railway run npm run db:migrate --service=barkpark-production"
            ;;
        *)
            echo -e "${RED}Error: Unknown environment '$env'${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    echo "Or check migration status:"
    echo "railway run npm run db:migrate:status --service=barkpark-$env"
}

# Function to show rollback instructions
rollback() {
    echo -e "${YELLOW}Rollback Instructions${NC}"
    echo ""
    echo "1. Quick rollback (Railway):"
    echo "   - Go to Railway dashboard"
    echo "   - Select the service to rollback"
    echo "   - Click 'Deployments' tab"
    echo "   - Find previous successful deployment"
    echo "   - Click '...' menu → 'Redeploy'"
    echo ""
    echo "2. Git rollback:"
    echo "   git checkout main"
    echo "   git reset --hard <previous-commit-hash>"
    echo "   git push --force origin main"
    echo ""
    echo "3. Database rollback (if needed):"
    echo "   Check migrations/rollback/ directory"
    echo "   railway run psql \$DATABASE_URL -f migrations/rollback/XXX_*.sql"
}

# Main script logic
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

command=$1
environment=$2

case $command in
    deploy)
        if [ -z "$environment" ]; then
            echo -e "${RED}Error: Environment required${NC}"
            usage
            exit 1
        fi
        deploy "$environment"
        ;;
    status)
        if [ -z "$environment" ]; then
            echo -e "${RED}Error: Environment required${NC}"
            usage
            exit 1
        fi
        status "$environment"
        ;;
    migrate)
        if [ -z "$environment" ]; then
            echo -e "${RED}Error: Environment required${NC}"
            usage
            exit 1
        fi
        migrate "$environment"
        ;;
    rollback)
        rollback
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$command'${NC}"
        usage
        exit 1
        ;;
esac