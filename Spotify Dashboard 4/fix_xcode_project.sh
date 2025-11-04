#!/bin/bash

echo "🔧 Fixing Xcode Project Issues..."

# Navigate to project directory
cd "$(dirname "$0")"

# Clear Xcode caches
echo "📦 Clearing Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Spotify_Dashboard-*
rm -rf ~/Library/Caches/org.swift.swiftpm

# Clear Swift Package Manager cache
echo "📦 Clearing Swift Package Manager cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm

# Resolve packages
echo "📥 Resolving Swift packages..."
xcodebuild -resolvePackageDependencies -project "Spotify Dashboard.xcodeproj" 2>&1 | grep -E "(Resolved|error)" || echo "Package resolution completed"

echo "✅ Done! Please:"
echo "1. Close Xcode completely"
echo "2. Reopen Xcode"
echo "3. Open the project"
echo "4. Wait for packages to resolve (watch the progress bar)"
echo "5. Product → Clean Build Folder (Shift + Cmd + K)"
echo "6. Product → Build (Cmd + B)"


