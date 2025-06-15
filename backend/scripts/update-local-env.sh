#!/bin/bash

# Script to update local JWT_SECRET
echo "🔐 Updating local JWT_SECRET..."

ENV_FILE="../.env"
NEW_SECRET="6cffb160bf50e93e8baeef5f57861174588b2c07dcd6941571ba5d9eb1adca090d0c7ab63449ccd1558c306aaf56136ef77fb3d958821ca6c9b719706e475fa7"

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