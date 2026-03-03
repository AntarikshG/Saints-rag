# Notification Permission Dialog Implementation

## Summary
Implemented a pre-permission dialog that explains the notification feature (morning and evening quotes) before requesting permissions. This improves user consent and permission grant rates by setting proper expectations.

## Changes Made

### 1. Localization Files (ARB)
Added new localized strings in all supported languages:

**Files Modified:**
- `lib/l10n/app_en.arb` (English)
- `lib/l10n/app_hi.arb` (Hindi)
- `lib/l10n/app_de.arb` (German)
- `lib/l10n/app_kn.arb` (Kannada)

**New Strings:**
- `notificationPermissionTitle`: "Daily Spiritual Wisdom"
- `notificationPermissionMessage`: Explains morning and evening quotes feature with benefits
- `enableNotifications`: Button to accept and enable
- `maybeLater`: Button to skip for now

### 2. NotificationService.dart
**File:** `lib/notification_service.dart`

**Added:**
- Import for `google_fonts` and `app_localizations`
- Constant `_hasAskedNotificationPermissionKey` for tracking permission prompt status
- Method `hasAskedForNotificationPermission()`: Check if permission dialog was shown before
- Method `markNotificationPermissionAsAsked()`: Mark dialog as shown
- Method `showNotificationPermissionDialog()`: Display beautiful pre-permission dialog

**Modified:**
- `initialize()`: Removed automatic permission request
- iOS initialization settings: Changed `requestAlertPermission`, `requestBadgePermission`, `requestSoundPermission` from `true` to `false`

### 3. iOS AppDelegate.swift
**File:** `ios/Runner/AppDelegate.swift`

**Modified:**
- Removed automatic permission request code from `application:didFinishLaunchingWithOptions`
- Now only sets up notification center delegate
- Permission request is handled by Flutter after user accepts dialog

### 4. Main.dart
**File:** `lib/main.dart`

**Modified:**
- `MyApp._MyAppState.initState()`: Only initializes notification service, doesn't request permissions
- `HomePage._HomePageState.initState()`: Added logic to show notification permission dialog AFTER name dialog
  - Shows dialog only on first app launch
  - Waits for name dialog to complete first
  - Adds 500ms delay between dialogs for better UX
  - Requests permissions and schedules notifications only if user accepts

## User Flow

### First Time App Launch:
1. App initializes notification service (no permission request yet)
2. User sees name dialog first (if not set before)
3. After name dialog closes, user sees notification permission dialog
4. Dialog explains:
   - Morning wisdom quotes (🌅)
   - Evening reflection quotes (🌙)
   - Benefits of the feature
5. User chooses:
   - **"Enable Notifications"**: Permissions requested, notifications scheduled
   - **"Maybe Later"**: No permissions requested, can enable later from menu

### Subsequent App Launches:
- Dialog not shown again (tracked in SharedPreferences)
- Existing permissions are checked and notifications auto-rescheduled if needed

## Benefits

1. ✅ **Better User Experience**: Users understand WHY they're being asked for permissions
2. ✅ **Higher Grant Rates**: Explaining value increases likelihood of permission grant
3. ✅ **Transparent**: Users know exactly what notifications they'll receive (morning & evening)
4. ✅ **Non-intrusive**: Option to skip and enable later
5. ✅ **Professional**: Matches the pattern of name dialog with beautiful UI
6. ✅ **Localized**: Works in all supported languages (English, Hindi, German, Kannada)

## Testing Checklist

- [ ] Delete app and reinstall to test first-time flow
- [ ] Verify name dialog shows first
- [ ] Verify notification permission dialog shows after name dialog
- [ ] Test "Enable Notifications" button - permissions requested
- [ ] Test "Maybe Later" button - no permissions requested
- [ ] Verify dialog doesn't show on second app launch
- [ ] Test on both Android and iOS
- [ ] Verify notifications work after accepting permissions
- [ ] Test in all supported languages

## Notes

- Dialog timing: 500ms delay between name and notification dialogs
- Permission status saved in SharedPreferences with key `hasAskedNotificationPermission`
- User can still enable notifications later via "Set Daily Notifications" menu option
- iOS no longer auto-requests permissions on app launch
- Android permission dialog shows after user accepts pre-permission dialog
