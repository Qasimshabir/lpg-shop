#!/bin/bash

echo "🚀 Deploying LPG Dealer API to Vercel..."
echo ""

# Check if vercel CLI is installed
if ! command -v vercel &> /dev/null
then
    echo "❌ Vercel CLI not found. Installing..."
    npm install -g vercel
fi

echo "✅ Vercel CLI is ready"
echo ""

# Login to Vercel
echo "🔐 Logging in to Vercel..."
vercel login

echo ""
echo "📦 Deploying to production..."
vercel --prod

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "1. Copy your deployment URL"
echo "2. Open the Flutter app"
echo "3. Double-tap the gas station icon"
echo "4. Enter your Vercel URL (e.g., https://your-app.vercel.app)"
echo "5. Click 'Test' to verify connection"
echo "6. Click 'Save'"
echo ""
echo "🎉 Done!"
