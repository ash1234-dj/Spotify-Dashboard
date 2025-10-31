#!/bin/bash

# Xcode Package Reset Script for Spotify Dashboard
# This script resets Xcode package caches and forces package resolution

echo "🧹 Cleaning Xcode caches..."

# Clear DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/Spotify_Dashboard-*
echo "✓ DerivedData cleared"

# Clear Package caches (but keep Package.resolved)
# Note: We keep Package.resolved so Xcode knows what versions to use
echo "✓ Package.resolved kept for version consistency"

# Resolve packages
cd "$(dirname "$0")"
echo "📦 Resolving Swift packages..."
xcodebuild -resolvePackageDependencies -project "Spotify Dashboard.xcodeproj" 2>&1 | tail -5

echo ""
echo "✅ Reset complete!"
echo ""
echo "📝 Next steps in Xcode:"
echo "   1. Close Xcode completely (Cmd + Q)"
echo "   2. Reopen the project"
echo "   3. Wait for 'Resolving Package Graph' to complete"
echo "   4. Build (Cmd + B) or Run (Cmd + R)"
echo ""


