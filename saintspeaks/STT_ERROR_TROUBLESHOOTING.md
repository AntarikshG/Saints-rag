# STT Error Troubleshooting Guide

## Error: `error_no_match` on Simulator/Emulator

### Issue You're Experiencing
```
I/flutter (32027): STT Status: notListening
I/flutter (32027): STT Status: done
I/flutter (32027): STT Error: SpeechRecognitionError msg: error_no_match, permanent: true
```

### ✅ Root Cause
**This is EXPECTED behavior on simulators/emulators!**

The error occurs because:
- **iOS Simulators** don't have access to real microphone hardware
- **Android Emulators** typically don't have proper speech recognition engines installed
- The STT (Speech-to-Text) service cannot capture or process real audio
- `error_no_match` means no speech was detected (because there's no real microphone input)

### ✅ Solution
**Test on a real physical device!**

Voice input features require:
- ✅ Real microphone hardware
- ✅ Proper speech recognition engine installed
- ✅ Microphone permissions granted
- ✅ Internet connection (for cloud-based recognition)

## What Was Fixed

### Enhanced Error Handling
I've added improved error messages that will help users understand what's happening:

#### 1. Better Error Messages
- **No match error**: "No speech detected. Please try again or check your microphone."
- **Emulator detection**: Adds note about emulator/simulator limitations
- **Network error**: "Network error. Please check your internet connection."
- **Busy error**: "Speech recognizer is busy. Please try again in a moment."
- **Not available**: "Speech recognition not available on this device."

#### 2. Proactive Warning
- Shows a warning when starting voice input on detected emulators
- Orange-colored SnackBar with clear message
- Duration: 3 seconds

#### 3. Detailed Error Logging
- All errors are logged to console with full details
- Helps with debugging specific issues

## Testing on Real Device

### iOS (iPhone/iPad)
1. **Build and deploy** to your physical iOS device
2. **Grant microphone permission** when prompted
3. **Tap the microphone button** in the Ask AI input section
4. **Speak clearly** in your selected language
5. **Watch the text appear** in the input field

### Android (Phone/Tablet)
1. **Build and deploy** to your physical Android device
2. **Grant microphone permission** when prompted
3. **Ensure internet connection** is active
4. **Tap the microphone button** in the Ask AI input section
5. **Speak clearly** in your selected language
6. **Watch the text appear** in the input field

## Permissions Required

### iOS (Info.plist)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for voice input</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need access to speech recognition for voice input</string>
```

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

## Common STT Errors and Solutions

### Error: `error_no_match`
**Cause**: No speech detected
**Solutions**:
- Speak louder and clearer
- Check microphone is not blocked
- Ensure you're speaking in the selected language
- Test on a real device (not emulator)

### Error: `error_network`
**Cause**: Network connectivity issue
**Solutions**:
- Check internet connection
- Try WiFi instead of cellular data
- Check firewall/VPN settings

### Error: `error_busy`
**Cause**: Speech recognizer is already in use
**Solutions**:
- Wait a moment and try again
- Restart the app if persistent

### Error: `error_not_available`
**Cause**: Speech recognition not available on device
**Solutions**:
- Check device has Google app installed (Android)
- Update device OS to latest version
- Check language is supported by device

### Error: `error_permission_denied`
**Cause**: Microphone permission not granted
**Solutions**:
- Grant microphone permission in device settings
- Reinstall app and grant permission when prompted

## Testing Checklist

### ✅ Before Testing Voice Input
- [ ] Using a real physical device (not emulator/simulator)
- [ ] Microphone permission granted
- [ ] Internet connection active
- [ ] Quiet environment for testing
- [ ] Correct language selected in voice settings
- [ ] Device volume is not muted

### ✅ Expected Behavior
- [ ] Microphone button turns red when listening
- [ ] "Listening... Speak your question" message appears
- [ ] Text appears in input field as you speak
- [ ] Listening stops automatically when you finish
- [ ] Text can be edited before submitting

### ✅ On Emulator/Simulator
- [ ] Warning message appears when starting voice input
- [ ] Error message clearly indicates emulator limitation
- [ ] App doesn't crash (graceful error handling)

## Language-Specific Notes

### English (en-US, en-GB, en-IN)
- Most widely supported
- Usually works offline on modern devices
- High accuracy

### Hindi (hi-IN)
- Requires Google app on Android
- May require internet connection
- Ensure keyboard/language pack installed

### German (de-DE)
- Good support on most devices
- May require language pack download
- Check device language settings

## Tips for Best Results

### 1. Environment
- 🔇 **Quiet environment** - Minimize background noise
- 📱 **Hold device properly** - Don't cover microphone
- 🎤 **Speak clearly** - Normal pace, clear pronunciation

### 2. Language Settings
- ✅ **Match language** - Select STT language matching what you'll speak
- ✅ **Check device language** - Ensure language pack installed on device
- ✅ **Test first** - Try device's built-in voice input first

### 3. Troubleshooting
- 🔄 **Restart app** if voice input stops working
- 📲 **Update device OS** for better recognition
- 🌐 **Check internet** for cloud-based recognition

## Developer Notes

### Changes Made to Code
1. **Enhanced error handler** with specific error type detection
2. **Emulator detection** (basic) with warning message
3. **Extended SnackBar duration** for better visibility
4. **Action button** on error messages for dismissal
5. **Color coding** (orange for warnings, red for errors)

### Error Types Handled
- `error_no_match` - No speech detected
- `error_network` - Network connectivity issue
- `error_busy` - Recognizer busy
- `error_not_available` - Feature not available
- Generic errors with full error message

### Testing Commands
```bash
# iOS Simulator (will show error - expected)
flutter run -d "iPhone 15 Pro"

# iOS Real Device
flutter run -d "Your iPhone Name"

# Android Emulator (will show error - expected)
flutter run -d emulator-5554

# Android Real Device
flutter run -d "Device ID from adb devices"
```

## Summary

### ❌ On Emulator/Simulator
- Voice input **WILL NOT WORK** properly
- Errors are **EXPECTED** and **NORMAL**
- Use for testing UI/UX only, not voice functionality

### ✅ On Real Device
- Voice input **SHOULD WORK** perfectly
- All languages supported by device will work
- Requires proper permissions and internet connection

### 🎯 Recommendation
**Always test voice features on real hardware!**

---

**Status**: ✅ Error handling improved
**Next Step**: 📱 Test on a real physical device
**Expected Result**: ✅ Voice input works perfectly on real device
