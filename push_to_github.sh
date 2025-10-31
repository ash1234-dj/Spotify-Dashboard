#!/bin/bash

# GitHub Push Script for Music Story Companion
# This script will push your committed changes to GitHub

echo "🚀 Pushing Music Story Companion to GitHub..."
echo ""

# Change to project directory
cd "/Users/ashfaqahmed/Downloads/Spotify Dashboard 2" || exit 1

# Check if we have commits to push
if ! git status | grep -q "Your branch is ahead"; then
    echo "✅ Nothing to push - your branch is up to date!"
    exit 0
fi

echo "📊 Preparing to push..."
echo ""

# Show what will be pushed
echo "Commits to push:"
git log origin/main..main --oneline | head -5
echo ""

# Attempt to push
echo "Attempting to push to GitHub..."
echo ""

git push origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo "📁 Repository: https://github.com/ash1234-dj/Spotify-Dashboard"
    echo ""
    echo "🎉 Your Music Story Companion app is now on GitHub!"
else
    echo ""
    echo "❌ Push failed. You may need to authenticate."
    echo ""
    echo "Options:"
    echo "1. Run: git push origin main (and enter your credentials)"
    echo "2. Create a Personal Access Token at: https://github.com/settings/tokens"
    echo "3. Or use SSH authentication"
fi

