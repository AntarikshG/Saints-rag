#!/bin/zsh

# iOS Icon Generation - Final Setup Script
# This script will generate iOS app icons from your apppic.png

echo "=================================================="
echo "iOS Icon Generator for Saints-rag/saintspeaks"
echo "=================================================="
echo ""

# Change to project directory
cd "$(dirname "$0")"
PROJECT_DIR=$(pwd)

echo "📁 Project Directory: $PROJECT_DIR"
echo ""

# Check if source image exists
if [ ! -f "assets/images/apppic.png" ]; then
    echo "❌ ERROR: Source image not found at assets/images/apppic.png"
    exit 1
fi

echo "✅ Source image found: assets/images/apppic.png"
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "⚠️  WARNING: Flutter command not found in PATH"
    echo ""
    echo "Please run these commands manually:"
    echo "  1. Open Terminal"
    echo "  2. cd $PROJECT_DIR"
    echo "  3. flutter pub get"
    echo "  4. flutter pub run flutter_launcher_icons"
    echo ""
    echo "Or try: dart run flutter_launcher_icons"
    echo ""
    exit 1
fi

echo "✅ Flutter found: $(which flutter)"
echo ""

# Run pub get
echo "📦 Step 1/3: Getting dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Failed to get dependencies"
    exit 1
fi
echo ""

# Generate icons
echo "🎨 Step 2/3: Generating icons..."
flutter pub run flutter_launcher_icons

if [ $? -ne 0 ]; then
    echo "⚠️  Primary method failed, trying alternative..."
    dart run flutter_launcher_icons

    if [ $? -ne 0 ]; then
        echo "❌ Icon generation failed"
        echo ""
        echo "Manual alternative:"
        echo "  1. Visit: https://appicon.co/"
        echo "  2. Upload: assets/images/apppic.png"
        echo "  3. Download iOS icons"
        echo "  4. Extract to: ios/Runner/Assets.xcassets/AppIcon.appiconset/"
        exit 1
    fi
fi

echo ""
echo "✅ Icon generation complete!"
echo ""

# Verify icons were created
echo "🔍 Step 3/3: Verifying iOS icons..."
IOS_ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ -f "$IOS_ICON_DIR/Icon-App-1024x1024@1x.png" ]; then
    echo "✅ iOS icons generated successfully!"
    echo ""
    echo "Generated icons in: $IOS_ICON_DIR"
    ls -1 "$IOS_ICON_DIR" | grep "Icon-App-" | wc -l | xargs echo "  Total icon files:"
else
    echo "⚠️  Warning: Could not verify icon generation"
    echo "  Please check: $IOS_ICON_DIR"
fi

echo ""
echo "=================================================="
echo "✨ Setup Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. flutter clean"
echo "  2. flutter build ios"
echo "  3. Test your app on an iOS device or simulator"
echo ""
echo "The app icon should now appear on your iOS device!"
echo "=================================================="

