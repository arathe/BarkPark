#!/bin/bash

# Load test token from .env.test
export $(grep TEST_USER_TOKEN .env.test | xargs)

# Check if token is set
if [ -z "$TEST_USER_TOKEN" ]; then
    echo "Error: TEST_USER_TOKEN not found. Run 'npm run generate-test-token' first."
    exit 1
fi

# API base URL
API_URL="https://barkpark-production.up.railway.app/api"

# Function to make authenticated API calls
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ -z "$data" ]; then
        curl -s -X "$method" "$API_URL$endpoint" \
            -H "Authorization: Bearer $TEST_USER_TOKEN" \
            -H "Content-Type: application/json" | jq .
    else
        curl -s -X "$method" "$API_URL$endpoint" \
            -H "Authorization: Bearer $TEST_USER_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" | jq .
    fi
}

# Export function for use in other scripts
export -f api_call
export TEST_USER_TOKEN
export API_URL

echo "Test API Helper loaded. Token available as \$TEST_USER_TOKEN"
echo "Use api_call METHOD ENDPOINT [DATA] to make authenticated requests"