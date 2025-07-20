#!/bin/bash

echo "🚀 Syria Admin - Deploy Script"
echo "================================"

echo "📦 Building web app..."
flutter build web --release

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    echo "🌐 Deploying to Firebase..."
    firebase deploy --only hosting
    
    if [ $? -eq 0 ]; then
        echo "🎉 Deploy successful!"
        echo "🌍 Your app is live at: https://visitsyria-995.web.app"
    else
        echo "❌ Deploy failed!"
        exit 1
    fi
else
    echo "❌ Build failed!"
    exit 1
fi 