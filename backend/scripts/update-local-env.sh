#!/bin/bash

# Script to generate and update local JWT_SECRET
echo "🔐 Generating new local JWT_SECRET..."

ENV_FILE="../.env"
# Generate a secure random secret (64 bytes = 128 hex chars)
NEW_SECRET=$(openssl rand -hex 64)

if [ -f "$ENV_FILE" ]; then
    # Backup existing .env
    cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Created backup of .env file"
    
    # Update JWT_SECRET
    if grep -q "^JWT_SECRET=" "$ENV_FILE"; then
        # On macOS use -i '' for in-place editing
        sed -i '' "s/^JWT_SECRET=.*/JWT_SECRET=$NEW_SECRET/" "$ENV_FILE"
        echo "✅ Updated JWT_SECRET in .env"
    else
        echo "JWT_SECRET=$NEW_SECRET" >> "$ENV_FILE"
        echo "✅ Added JWT_SECRET to .env"
    fi
else
    echo "⚠️  No .env file found in backend directory"
    echo "Creating .env from .env.example..."
    cp ".env.example" "$ENV_FILE"
    sed -i '' "s/^JWT_SECRET=.*/JWT_SECRET=$NEW_SECRET/" "$ENV_FILE"
    echo "✅ Created .env with new JWT_SECRET"
fi

echo ""
echo "📝 Next steps:"
echo "1. Restart your local development server"
echo "2. All local tokens are now invalid"
echo "3. You'll need to log in again in your local environment"