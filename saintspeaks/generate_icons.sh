#!/bin/zsh

# Navigate to project directory
cd "$(dirname "$0")"

echo "Generating app icons for iOS and Android..."
echo "=========================================="

# Update dependencies
echo "Step 1: Getting dependencies..."
flutter pub get

echo ""
echo "Step 2: Running flutter_launcher_icons..."
flutter pub run flutter_launcher_icons

echo ""
echo "=========================================="
echo "Icon generation complete!"
echo ""
echo "For iOS, the icons are located at:"
echo "  ios/Runner/Assets.xcassets/AppIcon.appiconset/"
echo ""
echo "For Android, the icons are located at:"
echo "  android/app/src/main/res/mipmap-*/"
echo ""
echo "Next steps:"
echo "1. Clean your build: flutter clean"
echo "2. Rebuild your app: flutter build ios"
echo "3. Test on a device or simulator"

