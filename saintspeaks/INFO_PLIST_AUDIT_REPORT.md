# Info.plist Audit Report
**Date:** February 3, 2026

## Summary
The iOS Info.plist file has been audited for unused permissions and old audio configurations.

## Current Permissions in Info.plist

### ✅ REQUIRED - Currently Used
1. **NSMicrophoneUsageDescription** - ✅ KEEP
   - Used by: `speech_to_text` package in Ask AI feature
   - Purpose: Voice input for asking spiritual questions
   
2. **NSSpeechRecognitionUsageDescription** - ✅ KEEP
   - Used by: `speech_to_text` package in Ask AI feature
   - Purpose: Convert spoken questions to text

3. **NSSpeechSynthesisUsageDescription** - ✅ KEEP
   - Used by: `flutter_tts` package
   - Purpose: Text-to-speech for reading books and articles aloud
   - Files: `epub_reader.dart`, `main.dart` (ArticlePage)

4. **NSPhotoLibraryAddUsageDescription** - ✅ KEEP
   - Used by: Quote sharing feature with `screenshot` and `share_plus` packages
   - Purpose: Save and share quote images

5. **NSPhotoLibraryUsageDescription** - ✅ KEEP
   - Used by: Quote sharing feature
   - Purpose: Share quote images

### ❌ NOT USED - Can Be Removed
1. **NSCameraUsageDescription** - ❌ REMOVE
   - Status: NOT USED
   - Reason: App doesn't use camera or `image_picker` package
   - Impact: Removing this will reduce app review scrutiny

2. **NSLocationWhenInUseUsageDescription** - ❌ REMOVE
   - Status: NOT USED
   - Reason: App doesn't use location services or geolocation
   - Note: Ekadashi timings are pre-configured, not location-based
   - Impact: Removing this will improve user trust and reduce permission prompts

## Audio Configuration Review

### Current Audio Setup
- **UIBackgroundModes**: `audio` - ✅ CORRECT
  - Required for: Background audio playback in meditation feature
  - Used by: `just_audio` package in `meditation_service.dart`
  - Status: Modern, correct implementation using AudioPlayer

### Audio Implementation Details
✅ **Modern audio implementation found:**
- Using `just_audio` package (modern, recommended)
- File: `meditation_service.dart`
- Features:
  - Background audio playback
  - Audio session management for iOS
  - Stream-based state management
  - Proper lifecycle handling

✅ **No old audio methods found:**
- No deprecated AVAudioPlayer usage
- No old AVFoundation direct calls
- Clean, modern implementation

## Recommendations

### 1. Remove Unused Permissions (High Priority)
Remove these two permissions from Info.plist:

```xml
<!-- REMOVE THIS -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture and share spiritual moments</string>

<!-- REMOVE THIS -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses your location to provide location-based spiritual content and Ekadashi timings</string>
```

**Benefits:**
- Reduced App Store review questions
- Improved user trust (fewer permissions)
- Cleaner permission flow
- Better privacy compliance

### 2. Keep Audio Background Mode
The `audio` background mode is correctly configured and required for:
- Meditation audio playback
- Background TTS reading (books/articles)

### 3. Update Permission Descriptions (Optional)
Consider making permission descriptions more specific:

**Current NSMicrophoneUsageDescription:**
```
This app uses microphone to enable voice input for asking spiritual questions
```

**Suggested (more specific):**
```
This app uses microphone for voice input in the "Ask AI" feature to help you ask spiritual questions
```

## Other Findings

### ✅ Good Configurations
1. **ITSAppUsesNonExemptEncryption**: `false` - Correct for App Store
2. **UIBackgroundModes**: Properly configured for audio and notifications
3. **NSAppTransportSecurity**: Allows HTTP (needed for external content)
4. **Localization**: Properly configured for en, hi, de

### ⚠️ Note
The `NSAllowsArbitraryLoads` is set to `true`. While this works, consider:
- Ensuring all external URLs use HTTPS where possible
- This is acceptable for apps loading content from various sources

## Implementation Steps

1. **Edit Info.plist:**
   - Remove `NSCameraUsageDescription` key and value
   - Remove `NSLocationWhenInUseUsageDescription` key and value

2. **Test:**
   - Verify all features still work
   - Test Ask AI voice input
   - Test quote sharing
   - Test meditation playback
   - Test TTS reading

3. **Update Privacy Policy (if needed):**
   - Remove references to camera access
   - Remove references to location access

## Conclusion

The Info.plist is mostly well-configured, but contains **2 unused permissions** that should be removed. The audio implementation is modern and correct, using the recommended `just_audio` package with no legacy code.

**Action Required:** Remove camera and location permissions before next App Store submission.
