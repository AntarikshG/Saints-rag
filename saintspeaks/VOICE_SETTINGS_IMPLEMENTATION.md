# Voice Settings Implementation for Ask AI Page

## Date: January 24, 2026

## Overview
Successfully implemented comprehensive voice settings configuration for both Text-to-Speech (TTS) and Speech-to-Text (STT) functionality on the Ask AI page, allowing users to customize their voice interaction experience.

## Features Implemented

### 1. TTS (Text-to-Speech) Button
- **Main Control Button**: Prominent purple button to read answers aloud
- **State Management**: Dynamic button text and icon based on playback state
  - "Read Answer Aloud" (🔊) when idle
  - "Pause Reading" (⏸️) when playing
  - "Resume Reading" (▶️) when paused
- **Stop Button**: Conditional stop button visible only when TTS is active

### 2. Voice Settings Dialog
Accessible via a settings icon button in the header section.

#### TTS Configuration Options:
- **Language Selection**: Dropdown with supported languages
  - English (US)
  - English (UK)
  - English (India)
  - Hindi (India)
  - German (Germany)
- **Speech Rate**: Slider control (0.1 - 1.0)
- **Pitch**: Slider control (0.5 - 2.0)

#### STT Configuration Options:
- **Language Selection**: Dropdown with supported languages matching TTS languages
- Automatically uses selected language for voice input recognition

### 3. Persistent Settings
All settings are saved to SharedPreferences and persist across app sessions:
- `ask_ai_tts_language`: Selected TTS language
- `ask_ai_tts_rate`: Speech rate
- `ask_ai_tts_pitch`: Speech pitch
- `ask_ai_stt_language`: Selected STT language

## Technical Implementation

### State Variables Added
```dart
// STT
String _sttLanguage = 'en_US';
List<String> _availableSttLanguages = [];

// TTS
String _ttsLanguage = 'en-US';
double _ttsRate = 0.5;
double _ttsPitch = 1.0;
List<dynamic> _availableTtsLanguages = [];

// Language mappings
Map<String, String> _supportedLanguages
Map<String, String> _sttLanguageCodes
```

### Key Methods

#### Settings Management
- `_loadSettings()`: Loads saved settings from SharedPreferences on initialization
- `_saveSettings()`: Saves current settings to SharedPreferences
- `_showVoiceSettings()`: Displays the settings dialog

#### TTS Controls
- `_initializeTts()`: Initializes TTS with saved settings and fetches available languages
- `_startTts()`: Starts reading the answer using configured settings
- `_pauseTts()`: Pauses current playback
- `_stopTts()`: Stops playback completely

#### STT Controls
- `_initializeSpeechToText()`: Initializes STT and fetches available locales
- `_startListening()`: Starts voice input with selected language
- `_stopListening()`: Stops voice input

### UI Components

#### Settings Button Location
Added in the header section, right side:
```
[🧠 Psychology Icon] [Question Title] [⚙️ Settings Icon]
```

#### Settings Dialog Structure
```
┌─────────────────────────────────────┐
│ 🔊 Voice Settings                   │
├─────────────────────────────────────┤
│ Text-to-Speech (Reading)            │
│   Language: [Dropdown]              │
│   Speech Rate: [Slider] 0.5         │
│   Pitch: [Slider] 1.0               │
│                                     │
│ Speech-to-Text (Voice Input)        │
│   Language: [Dropdown]              │
│                                     │
│                [Close]              │
└─────────────────────────────────────┘
```

#### TTS Button Layout
```
┌────────────────────────────────────┐
│  🔊 Read Answer Aloud              │  (Purple, full width)
└────────────────────────────────────┘
┌────────────────────────────────────┐
│  ⭕ Stop Reading                   │  (Outlined, only when active)
└────────────────────────────────────┘
┌─────────────────┬──────────────────┐
│ 📋 Copy Text    │ 📤 Share Image   │
└─────────────────┴──────────────────┘
┌────────────────────────────────────┐
│  🚩 Flag                           │
└────────────────────────────────────┘
```

## Supported Languages

### Language Codes Mapping
- **English (US)**: TTS: `en-US`, STT: `en_US`
- **English (UK)**: TTS: `en-GB`, STT: `en_GB`
- **English (India)**: TTS: `en-IN`, STT: `en_IN`
- **Hindi (India)**: TTS: `hi-IN`, STT: `hi_IN`
- **German (Germany)**: TTS: `de-DE`, STT: `de_DE`

## User Workflow

### Setting Up Voice Preferences
1. User taps the settings icon (🔊⚙️) in the header
2. Settings dialog opens with current settings
3. User can adjust:
   - TTS language, speed, and pitch
   - STT language for voice input
4. Changes are applied immediately and saved automatically
5. User closes dialog

### Using TTS to Read Answers
1. User asks a question and receives an answer
2. User taps "Read Answer Aloud" button
3. Answer is read using configured language, rate, and pitch
4. User can pause/resume or stop at any time
5. TTS automatically stops when asking a new question

### Using STT for Voice Input
1. User taps the microphone button in the input section
2. Voice recognition starts using selected STT language
3. User speaks their question
4. Recognized text appears in the input field
5. User can edit or directly submit the question

## Integration Points

### Lifecycle Management
- Settings loaded in `initState()`
- TTS/STT initialized with loaded settings
- Proper cleanup in `dispose()` method
- TTS stops automatically on new question submission

### Error Handling
- Graceful handling of TTS/STT initialization failures
- User feedback via SnackBar for errors
- Fallback to default settings if saved settings fail to load

## Benefits

### For Users
✅ Personalized voice experience with preferred language
✅ Adjustable speech speed for comfortable listening
✅ Pitch control for voice preference
✅ Consistent settings across sessions
✅ Easy access to settings via prominent icon
✅ Real-time preview of settings changes

### For Developers
✅ Clean separation of concerns
✅ Persistent settings architecture
✅ Extensible language support system
✅ Comprehensive error handling
✅ Well-documented code with print statements for debugging

## Future Enhancements (Potential)
- Voice preview button in settings to test TTS settings
- Advanced STT options (punctuation, profanity filter)
- Custom voice selection (if available on device)
- Language auto-detection for STT
- Multi-language support within single answer (mixed-language TTS)

## Testing Checklist
- [ ] TTS plays answer with correct language
- [ ] TTS respects speech rate setting
- [ ] TTS respects pitch setting
- [ ] Settings persist after app restart
- [ ] STT recognizes voice in selected language
- [ ] Settings button is visible and accessible
- [ ] Settings dialog displays correctly in light/dark mode
- [ ] All dropdown menus show correct options
- [ ] Sliders update values in real-time
- [ ] TTS stops when starting new question
- [ ] Error messages display appropriately

## Files Modified
- `/Users/antarikshbhardwaj/AndroidStudioProjects/Saints-rag/saintspeaks/lib/ask_ai_page.dart`

## Dependencies Used
- `flutter_tts: ^3.8.5` (already in project)
- `speech_to_text` (already in project)
- `shared_preferences` (already in project)

## Code Statistics
- **New State Variables**: 8
- **New Methods**: 3 (loadSettings, saveSettings, showVoiceSettings)
- **Modified Methods**: 3 (initializeTts, initializeSpeechToText, startListening)
- **New UI Components**: 1 (Settings Dialog), 1 (Settings Button)
- **Lines Added**: ~250

## Notes
- All settings changes are applied immediately (no need to restart)
- Settings are saved automatically when changed
- TTS/STT initialization fetches available languages from the device
- Language availability may vary by device and installed TTS/STT engines
- The implementation follows the same pattern used in other parts of the app (main.dart, epub_reader.dart)

## Conclusion
The voice settings implementation provides users with complete control over their voice interaction experience in the Ask AI feature. The intuitive UI, persistent settings, and real-time feedback create a seamless and personalized user experience.
