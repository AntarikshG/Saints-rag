# Wisdom Sharing Feature - Implementation Guide

## Overview
This feature implements a weekly wisdom sharing prompt that encourages users to share quotes from the app with their friends or set their WhatsApp status. The prompt is designed to inspire users to practice **Gyaana Dāna** (the gift of knowledge), as emphasized by Swami Vivekananda.

## Feature Specifications

### Timing & Frequency
- **First Prompt**: Shown after the user has used the app for **at least 7 days**
- **Recurring Prompts**: Shown every **7 days** (once per week) thereafter
- **Non-Intrusive**: Displayed 2 seconds after the home page loads, giving users time to settle in

### Philosophy
The feature is inspired by Swami Vivekananda's teaching:
> "Knowledge is the highest form of charity."

When we share wisdom, we don't lose it—we multiply its power. Through this app, every insight shared can guide someone, uplift a mind, and spark positive change.

## Implementation Details

### Files Created/Modified

#### 1. New Service File
**`lib/wisdom_sharing_service.dart`**
- Manages the wisdom sharing prompt logic
- Tracks first app use date
- Calculates when to show prompts based on 7-day intervals
- Provides methods to show the dialog and reset state (for testing)

Key methods:
- `initializeFirstUseDate()` - Tracks when user first used the app
- `shouldShowWisdomPrompt()` - Determines if it's time to show the prompt
- `checkAndShowWisdomPrompt(context)` - Shows prompt if conditions are met
- `showWisdomSharingDialog(context)` - Displays the actual dialog

#### 2. Localization Files Updated
All language files have been updated with the wisdom sharing strings:

**Added Strings:**
- `wisdomSharingTitle` - Dialog title
- `wisdomSharingVivekanandaQuote` - Swami Vivekananda's quote
- `wisdomSharingMessage` - Main message about sharing wisdom
- `wisdomSharingGyaanaDana` - Gyaana Dāna call to action
- `wisdomSharingCallToAction` - Specific action items
- `wisdomSharingGotIt` - Acknowledgment button text

**Languages Supported:**
- ✅ English (en)
- ✅ Hindi (hi)
- ✅ German (de)
- ✅ Kannada (kn)

#### 3. Main Application File
**`lib/main.dart`**
- Added import for `wisdom_sharing_service.dart`
- Initialized the service in `main()` function
- Added prompt check in `HomePage._HomePageState.initState()`

### Dialog Design

The wisdom sharing dialog features:

1. **Beautiful Gradient Icon**
   - Amber to orange gradient circular background
   - Share icon in white

2. **Structured Content**
   - Title: "Share the Wisdom" (localized)
   - Vivekananda's quote in a highlighted box with quote marks
   - Main message explaining the power of sharing wisdom
   - Gyaana Dāna emphasis in a gradient container
   - Call to action about sharing quotes or WhatsApp status

3. **User Actions**
   - "Maybe Later" - Dismisses the dialog
   - "Got it!" - Primary action button (acknowledges and closes)

4. **Theme Support**
   - Works with both light and dark themes
   - Uses app's color scheme (deep orange/amber)

## User Experience Flow

```
Day 0: User installs app
  ↓
Days 1-6: User uses app
  ↓
Day 7: First wisdom sharing prompt appears
  ↓
User interacts with dialog
  ↓
7 days later: Prompt appears again
  ↓
Repeats every 7 days
```

## Integration with Existing Features

The wisdom sharing prompt integrates seamlessly with:

1. **Rating/Share Service**: Shows after the rating prompt check
2. **Notification Permission Dialog**: Respects the dialog queue
3. **User Profile Service**: Uses the same timing pattern
4. **Badge System**: Users can earn points by sharing quotes

## Testing the Feature

### Manual Testing
1. Install the app
2. Wait 7 days (or modify the constants for testing)
3. Open the app - prompt should appear 2 seconds after home page loads
4. Test in all supported languages
5. Verify the prompt appears again after another 7 days

### Testing with Modified Timing (for Development)
To test without waiting 7 days:

1. Open `lib/wisdom_sharing_service.dart`
2. Temporarily change:
   ```dart
   static const int _daysBeforeFirstPrompt = 0; // Changed from 7
   static const int _daysBetweenPrompts = 0; // Changed from 7
   ```
3. Clear app data or use: `WisdomSharingService.resetPromptState()`
4. Restart the app
5. Remember to restore the original values before committing!

### Debug Methods
The service includes debug methods:
```dart
// Reset the prompt state
await WisdomSharingService.resetPromptState();

// Get debug information
Map<String, dynamic> info = await WisdomSharingService.getDebugInfo();
print(info); // Shows days since first use, last prompt date, etc.
```

## Sharing Quotes from the App

Users can already share quotes in several ways:
1. **Quote Pages**: Each quote has a "Share" button that creates a beautiful image
2. **Badge System**: Sharing quotes awards 30 points per share
3. **WhatsApp Status**: The shared image is perfect for status updates

The wisdom sharing prompt reminds users about these features and encourages them to use them regularly.

## Localized Messages

### English
- Title: "Share the Wisdom"
- Vivekananda Quote: "Knowledge is the highest form of charity."
- Call to Action: "Share the quotes from this app with your friends or set your WhatsApp status to spread wisdom daily."

### Hindi (हिंदी)
- Title: "ज्ञान साझा करें"
- Vivekananda Quote: "ज्ञान दान का सर्वोच्च रूप है।"
- Call to Action: "इस ऐप के उद्धरणों को अपने दोस्तों के साथ साझा करें या दैनिक ज्ञान फैलाने के लिए अपनी WhatsApp स्थिति सेट करें।"

### German (Deutsch)
- Title: "Teilen Sie die Weisheit"
- Vivekananda Quote: "Wissen ist die höchste Form der Wohltätigkeit."
- Call to Action: "Teilen Sie die Zitate aus dieser App mit Ihren Freunden oder setzen Sie Ihren WhatsApp-Status, um täglich Weisheit zu verbreiten."

### Kannada (ಕನ್ನಡ)
- Title: "ಜ್ಞಾನವನ್ನು ಹಂಚಿಕೊಳ್ಳಿ"
- Vivekananda Quote: "ಜ್ಞಾನವು ದಾನದ ಅತ್ಯುನ್ನತ ರೂಪವಾಗಿದೆ."
- Call to Action: "ಈ ಅಪ್ಲಿಕೇಶನ್‌ನಿಂದ ಉಲ್ಲೇಖಗಳನ್ನು ನಿಮ್ಮ ಸ್ನೇಹಿತರೊಂದಿಗೆ ಹಂಚಿಕೊಳ್ಳಿ ಅಥವಾ ದೈನಂದಿನ ಜ್ಞಾನವನ್ನು ಹರಡಲು ನಿಮ್ಮ WhatsApp ಸ್ಥಿತಿಯನ್ನು ಹೊಂದಿಸಿ."

## SharedPreferences Keys

The service uses the following keys:
- `lastWisdomSharingPromptDate` - Timestamp of last prompt
- `firstAppUseDate` - Timestamp of first app usage
- `hasSeenWisdomPrompt` - Boolean flag indicating if user has seen the prompt

## Future Enhancements

Potential improvements:
1. Track how many times users actually share after seeing the prompt
2. Adjust frequency based on user engagement
3. Add analytics to see which language users engage most
4. A/B test different messages to optimize engagement
5. Add a "Don't show again" option (with careful consideration)

## Maintenance Notes

- The feature is fully localized and ready for new languages
- To add a new language, add the 6 wisdom sharing strings to the new language file
- The timing constants are easily adjustable in `wisdom_sharing_service.dart`
- The dialog design uses the app's theme colors automatically

## Success Metrics

Consider tracking:
- Number of users who see the prompt
- Number of users who share after seeing the prompt
- Retention rate of users who share wisdom
- Growth in app installs from shared content

---

**Implementation Date**: January 28, 2026
**Version**: 1.0
**Status**: ✅ Complete and Ready for Production
