#!/bin/bash

API_URL="https://barkpark-production.up.railway.app/api"
EMAIL="test_$(date +%s)@example.com"
PASSWORD="TestPassword123!"

echo "=== Testing BarkPark API Endpoints ==="
echo ""

# Test 1: Registration
echo "1. Testing Registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\",
    \"firstName\": \"Test\",
    \"lastName\": \"User\"
  }")

echo "Response: $REGISTER_RESPONSE"
echo ""

# Extract token if registration was successful
TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"token":"[^"]*' | sed 's/"token":"//')

# Test 2: Login
echo "2. Testing Login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

echo "Response: $LOGIN_RESPONSE"
echo ""

# Extract token from login if we don't have one
if [ -z "$TOKEN" ]; then
  TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | sed 's/"token":"//')
fi

# If still no token, try a test account
if [ -z "$TOKEN" ]; then
  echo "3. Trying test account..."
  TEST_LOGIN=$(curl -s -X POST "$API_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{
      \"email\": \"test@example.com\",
      \"password\": \"password123\"
    }")
  
  echo "Response: $TEST_LOGIN"
  TOKEN=$(echo "$TEST_LOGIN" | grep -o '"token":"[^"]*' | sed 's/"token":"//')
  echo ""
fi

if [ -z "$TOKEN" ]; then
  echo "⚠️  No valid token obtained. Cannot test authenticated endpoints."
  exit 1
fi

echo "✅ Got auth token: ${TOKEN:0:20}..."
echo ""

# Test authenticated endpoints
echo "4. Testing Get Profile..."
curl -s -X GET "$API_URL/auth/me" \
  -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "5. Testing Get Parks (NYC location)..."
curl -s -X GET "$API_URL/parks?latitude=40.7128&longitude=-74.0060&radius=10" \
  -H "Authorization: Bearer $TOKEN" | jq '.parks[0]'

echo ""
echo "6. Testing Search Parks..."
curl -s -X GET "$API_URL/parks/search?q=Central" \
  -H "Authorization: Bearer $TOKEN" | jq '.parks | length'

echo ""
echo "7. Testing Get Dogs..."
curl -s -X GET "$API_URL/dogs" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

echo ""
echo "8. Testing Get Friends..."
curl -s -X GET "$API_URL/friends" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

echo ""
echo "=== API Testing Complete ==="