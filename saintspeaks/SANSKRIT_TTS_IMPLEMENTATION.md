# Sanskrit TTS Language Support - Implementation Summary

## Overview
Sanskrit language (sa-IN) has been added as a supported Text-to-Speech (TTS) language for both article reading and ebook reading features, as well as the Ask AI feature in the SaintSpeaks app.

## Changes Made

### 1. Article Reading TTS Support (`lib/main.dart`)
- **Line 96-106**: Added `'sa-IN': 'Sanskrit (India)'` to the `_supportedTtsLanguages` map
- Updated comment to reflect Sanskrit addition: "English, Hindi, Kannada, Sanskrit, and German"

### 2. Ebook Reading TTS Support (`lib/epub_reader.dart`)
- **Line 104-113**: Added `'sa-IN': 'Sanskrit (India)'` to the `_supportedTtsLanguages` map
- **Line 2478-2479**: Added Sanskrit test text condition: `'इदं परीक्षणम् अस्ति।'` (This is a test)
- Updated comment to reflect Sanskrit addition: "English, Hindi, Kannada, Sanskrit, and German variants"

### 3. Ask AI Page TTS/STT Support (`lib/ask_ai_page.dart`)
- **Line 563-575**: Added `'sa-IN': 'Sanskrit (India)'` to both `_supportedLanguages` and `_sttLanguageCodes` maps
- This enables Sanskrit for both text-to-speech (reading AI responses) and speech-to-text (voice input for questions)

### 4. Backup File Update (`lib/main_backup_4language.dart`)
- **Line 81-90**: Added `'sa-IN': 'Sanskrit (India)'` along with other missing languages for consistency

## Technical Details

### Language Code
- **Code**: `sa-IN`
- **Display Name**: Sanskrit (India)
- **Test Text**: `इदं परीक्षणम् अस्ति।` (This is a test)
- **STT Code**: `sa_IN`

### How It Works
1. The app maintains a curated list of supported TTS languages in `_supportedTtsLanguages` map
2. Users can select Sanskrit from the language dropdown in TTS settings
3. The app will use device's TTS engine to read Sanskrit text if available
4. For ebooks, users can test the Sanskrit voice using the "Test Voice" button
5. In Ask AI, users can use Sanskrit for both voice input (STT) and voice output (TTS)

### Device Requirements
- The device must have a TTS engine that supports Sanskrit (sa-IN)
- Common TTS engines like Google TTS support Sanskrit on Android
- iOS may require additional voice download from Settings > Accessibility > Spoken Content
- For STT (speech-to-text), the device needs speech recognition support for Sanskrit

## Usage

### For Article Reading
1. Open any article
2. Tap the TTS controls toggle
3. Select "Sanskrit (India)" from the language dropdown
4. Adjust speed and pitch as needed
5. Press play to hear the article read in Sanskrit

### For Ebook Reading
1. Open any ebook
2. Go to reading settings
3. Scroll to Text-to-Speech Settings
4. Select "Sanskrit (India)" from the language dropdown
5. Optionally test the voice using the "Test Voice" button
6. Use the TTS playback controls while reading

### For Ask AI Feature
1. Go to the Ask AI page
2. Tap the language selector
3. Choose "Sanskrit (India)"
4. For voice input: Tap the microphone button and speak your question in Sanskrit
5. For voice output: After receiving an AI response, use the TTS button to hear it read in Sanskrit

## Files Modified
1. `/saintspeaks/lib/main.dart`
2. `/saintspeaks/lib/epub_reader.dart`
3. `/saintspeaks/lib/ask_ai_page.dart`
4. `/saintspeaks/lib/main_backup_4language.dart`

## Testing Checklist
- [ ] Sanskrit appears in language dropdown for articles
- [ ] Sanskrit appears in language dropdown for ebooks
- [ ] Sanskrit appears in language dropdown for Ask AI
- [ ] Test voice button works with Sanskrit in ebook reader
- [ ] Article TTS reads Sanskrit content correctly
- [ ] Ebook TTS reads Sanskrit content correctly
- [ ] Ask AI TTS reads Sanskrit responses correctly
- [ ] Ask AI STT recognizes Sanskrit voice input
- [ ] Settings are persisted after app restart
- [ ] Voice selection shows Sanskrit-compatible voices (if available)

## Notes
- The actual TTS quality depends on the device's installed TTS engine
- Not all devices may have Sanskrit TTS voices installed by default
- Users may need to download additional language data from their device settings
- The Sanskrit content in the app (like Ramakrishna's quotes in `ramakrishna_sa.dart`) can now be read aloud using TTS
- STT (speech recognition) for Sanskrit may have limited accuracy depending on the device's language support

## Related Files
- `/saintspeaks/lib/saints_sa/ramakrishna_sa.dart` - Contains Sanskrit content that can benefit from this feature
- Other `*_sa.dart` files in the saints_sa folder with Sanskrit content

## Date Implemented
January 31, 2026
