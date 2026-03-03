#!/bin/bash

# 🎯 Quick Test Script - iOS Audio Fix
# Run this to apply the fix and test

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎵 iOS Audio Playback Fix - Test Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Navigate to project
cd "$(dirname "$0")"
echo "📁 Working directory: $(pwd)"
echo ""

# Step 1: Clean
echo "🧹 Step 1/3: Cleaning Flutter project..."
flutter clean
echo "✅ Clean complete"
echo ""

# Step 2: Get dependencies
echo "📦 Step 2/3: Installing dependencies..."
flutter pub get
echo "✅ Dependencies installed"
echo ""

# Step 3: Run
echo "🚀 Step 3/3: Starting app..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 TESTING INSTRUCTIONS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. ⬇️  Delete any previously downloaded meditation"
echo "2. 📥 Tap 'DOWNLOAD & PLAY' on a meditation"
echo "3. 👀 Watch console output for:"
echo ""
echo "   LOOK FOR:"
echo "   ✅ 'File appears to be a valid MP3'"
echo "   ✅ 'Playback started successfully'"
echo ""
echo "   OR (fallback):"
echo "   ⚠️  'Local file playback failed'"
echo "   ✅ 'Streaming playback started successfully'"
echo ""
echo "4. 🎵 Audio should play either way!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Starting app in 3 seconds..."
sleep 3

flutter run
