#!/bin/bash

# 🔒 Secure GitHub Push Script
# This script guides you through a safe and secure push to GitHub

set -e  # Exit on any error

echo "🔒 Secure GitHub Push Setup"
echo "=============================="
echo ""

# Check if we're in the right directory
if [ ! -f "README.md" ]; then
    echo "❌ Error: Not in the project directory"
    echo "Please run: cd '/Users/ashfaqahmed/Downloads/Spotify Dashboard 2'"
    exit 1
fi

echo "✅ Found project directory"
echo ""

# Configure secure credential storage
echo "🔐 Configuring secure credential storage..."
git config --global credential.helper osxkeychain
echo "✅ Credential storage configured"
echo ""

# Check if already pushed
if git diff origin/main..main --quiet 2>/dev/null; then
    echo "✅ Everything is already pushed to GitHub!"
    exit 0
fi

echo "📊 Current Status:"
echo "  Repository: https://github.com/ash1234-dj/Spotify-Dashboard"
echo "  Commits to push: $(git rev-list origin/main..main --count 2>/dev/null || echo "unknown")"
echo ""

# Show recent commits
echo "Recent commits to push:"
git log origin/main..main --oneline -3 2>/dev/null || true
echo ""

# Attempt push
echo "🚀 Attempting secure push..."
echo ""
echo "If prompted, you'll need:"
echo "  Username: ash1234-dj"
echo "  Password: Personal Access Token (not your GitHub password!)"
echo ""
echo "Create token at: https://github.com/settings/tokens"
echo "  • Name: Music Story Companion"
echo "  • Scope: repo (full control)"
echo "  • Expiration: 90 days"
echo ""

# Try to push
if git push origin main; then
    echo ""
    echo "✅ ✅ ✅ SUCCESS! ✅ ✅ ✅"
    echo ""
    echo "Your Music Story Companion app is now on GitHub!"
    echo "View it at: https://github.com/ash1234-dj/Spotify-Dashboard"
    echo ""
    echo "🎉 Congratulations!"
else
    echo ""
    echo "❌ Push failed."
    echo ""
    echo "Common solutions:"
    echo "1. Create a Personal Access Token at: https://github.com/settings/tokens"
    echo "2. Make sure token has 'repo' scope"
    echo "3. Use the token as your password (not GitHub password)"
    echo ""
    echo "Read SECURE_PUSH_COMMANDS.md for detailed instructions"
    echo ""
fi

