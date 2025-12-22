# iOS Notification Fix Guide

## Issues Fixed

Your notifications were being sent but not showing on iOS due to missing iOS-specific configurations. The following changes have been made:

### 1. **notification_service.dart** - Added iOS Support
- ✅ Added `DarwinInitializationSettings` for iOS notification initialization
- ✅ Added iOS notification details (`DarwinNotificationDetails`) to all notification types:
  - Daily quote notifications
  - Ekadashi notifications  
  - Test notifications
- ✅ Configured iOS notification presentation options (alert, badge, sound)

### 2. **AppDelegate.swift** - Added Notification Handling
- ✅ Imported `UserNotifications` framework
- ✅ Set up `UNUserNotificationCenter` delegate
- ✅ Added notification permission request at app launch
- ✅ Implemented foreground notification display (iOS 10+)
- ✅ Added notification tap handling

## Additional Steps Required

### Step 1: Add Background Modes Capability (Required for scheduled notifications)

1. Open your project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select the **Runner** target in the project navigator

3. Go to **Signing & Capabilities** tab

4. Click the **+ Capability** button

5. Add **Background Modes** and enable:
   - ☑️ **Background fetch**
   - ☑️ **Remote notifications**

### Step 2: Verify Info.plist (Optional - for better user experience)

Add these keys to `ios/Runner/Info.plist` if you want custom permission messages:

```xml
<key>NSUserNotificationsUsageDescription</key>
<string>We need permission to send you daily spiritual quotes and Ekadashi reminders</string>
```

### Step 3: Clean Build and Reinstall

Run these commands to ensure a clean build:

```bash
# Clean Flutter build
flutter clean

# Get dependencies
flutter pub get

# Clean iOS build
cd ios
pod deinstall
pod install
cd ..

# Rebuild and run on iOS device/simulator
flutter run
```

### Step 4: Test Notifications

1. **Delete the app** from your iOS device/simulator if already installed
2. **Reinstall** the app to ensure permission prompts appear
3. **Grant notification permissions** when prompted
4. **Test immediate notification** - Use your test button in the app
5. **Wait for scheduled notification** - Check if notifications appear at scheduled times

## Common iOS Notification Issues & Solutions

### Issue: Notifications not appearing even after fix
**Solutions:**
- Ensure notification permissions are granted (Settings > Your App > Notifications)
- Check "Do Not Disturb" is OFF on the device
- For simulators, notifications may be delayed - try on a real device
- Verify the app is not in "Focus Mode" or "Screen Time" restrictions

### Issue: Notifications only appear when app is open
**Solution:**
- Make sure Background Modes are enabled in Xcode capabilities
- Ensure the app has been launched at least once

### Issue: Permission dialog not showing
**Solution:**
- Delete and reinstall the app
- Or reset permissions: Settings > General > Transfer or Reset iPhone > Reset Location & Privacy

### Issue: Scheduled notifications not triggering
**Solution:**
- iOS may delay notifications if Low Power Mode is ON
- Ensure the device time/timezone is correct
- Test with an immediate notification first

## Verification Checklist

- [ ] iOS notification initialization settings added
- [ ] Darwin notification details added to all notification types
- [ ] AppDelegate.swift updated with UserNotifications support
- [ ] Background Modes capability enabled in Xcode
- [ ] App deleted and reinstalled on iOS device
- [ ] Notification permissions granted
- [ ] Test notification displays successfully
- [ ] Scheduled notifications appear at correct times

## Technical Notes

### iOS vs Android Differences:
- **Android**: Uses channels, explicit permission handling
- **iOS**: Uses Darwin notifications, permission requested through UNUserNotificationCenter
- **Scheduling**: iOS requires proper timezone configuration and may delay notifications to optimize battery

### Flutter Local Notifications on iOS:
- Uses Apple's UserNotifications framework (iOS 10+)
- Notifications are presented with banner, badge, and sound by default
- Foreground notifications need explicit handling (now implemented)
- Background notifications work automatically after permission granted

## Testing Commands

```bash
# Check current Flutter doctor status
flutter doctor -v

# Check iOS pods
cd ios && pod repo update && pod install && cd ..

# Run in debug mode with verbose logging
flutter run -v

# Build for iOS release
flutter build ios --release
```

## Support

If notifications still don't appear after following these steps:
1. Check device Console logs in Xcode (Window > Devices and Simulators)
2. Look for any notification-related errors in console
3. Verify the notification payload in logs
4. Check iOS Settings > Notifications > Talk With Saints for permission status

---

**Last Updated:** December 20, 2025
**Status:** ✅ All code changes applied - Requires Xcode capability configuration

