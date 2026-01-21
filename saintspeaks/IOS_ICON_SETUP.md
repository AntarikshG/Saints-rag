# iOS Icon Setup Guide

## Automated Method (Recommended)

Your `pubspec.yaml` is now configured correctly. To generate iOS icons:

### Option 1: Use the Script
```bash
./generate_icons.sh
```

### Option 2: Run Commands Manually
```bash
# Navigate to project folder
cd /Users/antarikshbhardwaj/AndroidStudioProjects/Saints-rag/saintspeaks

# Get dependencies
flutter pub get

# Generate icons
flutter pub run flutter_launcher_icons
```

### Option 3: Use Dart Command
```bash
dart run flutter_launcher_icons
```

## Manual Method (If Automated Fails)

If the automated icon generation doesn't work, you can manually create iOS icons:

### 1. Prepare Your Icon Image
- Use `assets/images/apppic.png` (your app icon)
- Image should be at least 1024x1024 pixels
- PNG format with no transparency (iOS requirement)

### 2. Generate Icon Sizes Online
Use one of these free online tools:
- https://appicon.co/ (Recommended - generates all iOS sizes)
- https://makeappicon.com/
- https://www.appicon.build/

Upload your `apppic.png` and download the iOS icon set.

### 3. Replace Icons Manually
Extract the downloaded icons and replace the files in:
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

Required iOS icon sizes:
- Icon-App-20x20@2x.png (40x40)
- Icon-App-20x20@3x.png (60x60)
- Icon-App-29x29@1x.png (29x29)
- Icon-App-29x29@2x.png (58x58)
- Icon-App-29x29@3x.png (87x87)
- Icon-App-40x40@2x.png (80x80)
- Icon-App-40x40@3x.png (120x120)
- Icon-App-60x60@2x.png (120x120)
- Icon-App-60x60@3x.png (180x180)
- Icon-App-76x76@1x.png (76x76)
- Icon-App-76x76@2x.png (152x152)
- Icon-App-83.5x83.5@2x.png (167x167)
- Icon-App-1024x1024@1x.png (1024x1024) - Required for App Store

### 4. Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter build ios
```

### 5. Test
Run the app on an iOS device or simulator to verify the icon appears correctly.

## Troubleshooting

### Issue: Icons not showing after generation
**Solution:**
1. Clean build: `flutter clean`
2. Delete `ios/Pods` and `ios/Podfile.lock`
3. Run `cd ios && pod install`
4. Rebuild: `flutter build ios`

### Issue: flutter_launcher_icons command not found
**Solution:**
1. Ensure Flutter is in PATH: `flutter doctor`
2. Run `flutter pub get` first
3. Try alternative: `dart run flutter_launcher_icons`

### Issue: Icon has transparency (iOS rejects)
**Solution:**
The configuration now includes `remove_alpha_ios: true` which handles this automatically.
If manual upload, ensure your icon has NO transparency.

## Current Configuration

Your `pubspec.yaml` configuration:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/apppic.png"
  remove_alpha_ios: true
  min_sdk_android: 21
```

## Verification

After generating icons, verify they exist:
```bash
ls -la ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

You should see all the icon files with proper sizes.

## Additional Resources

- [Flutter Icon Documentation](https://flutter.dev/docs/deployment/ios#review-xcode-project-settings)
- [flutter_launcher_icons Package](https://pub.dev/packages/flutter_launcher_icons)
- [Apple Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)

