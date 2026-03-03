import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';

/// Service to prompt users weekly to share wisdom from the app
/// Implements Gyaana Dāna (sharing of knowledge) philosophy
class WisdomSharingService {
  // SharedPreferences keys
  static const String _lastWisdomPromptKey = 'lastWisdomSharingPromptDate';
  static const String _firstAppUseDateKey = 'firstAppUseDate';
  static const String _hasSeenWisdomPromptKey = 'hasSeenWisdomPrompt';

  // Timing constants
  static const int _daysBeforeFirstPrompt = 7; // Show first prompt after 7 days
  static const int _daysBetweenPrompts = 7; // Show every 7 days thereafter

  /// Track first app use date if not already tracked
  static Future<void> initializeFirstUseDate() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_firstAppUseDateKey)) {
      await prefs.setInt(_firstAppUseDateKey, DateTime.now().millisecondsSinceEpoch);
      print('📅 First app use date recorded for wisdom sharing prompts');
    }
  }

  /// Get the number of days since first app use
  static Future<int> getDaysSinceFirstUse() async {
    final prefs = await SharedPreferences.getInstance();
    final firstUseMillis = prefs.getInt(_firstAppUseDateKey);

    if (firstUseMillis == null) {
      // If not set, initialize it now
      await initializeFirstUseDate();
      return 0;
    }

    final firstUseDate = DateTime.fromMillisecondsSinceEpoch(firstUseMillis);
    return DateTime.now().difference(firstUseDate).inDays;
  }

  /// Check if we should show the wisdom sharing prompt
  static Future<bool> shouldShowWisdomPrompt() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user has used the app for at least 7 days
    final daysSinceFirstUse = await getDaysSinceFirstUse();
    if (daysSinceFirstUse < _daysBeforeFirstPrompt) {
      return false;
    }

    // Check when we last prompted
    final lastPromptMillis = prefs.getInt(_lastWisdomPromptKey);
    if (lastPromptMillis == null) {
      // Never prompted before and user has used app for 7+ days - show prompt
      return true;
    }

    final lastPromptDate = DateTime.fromMillisecondsSinceEpoch(lastPromptMillis);
    final daysSinceLastPrompt = DateTime.now().difference(lastPromptDate).inDays;

    // Show prompt if it's been 7+ days since last prompt
    return daysSinceLastPrompt >= _daysBetweenPrompts;
  }

  /// Mark that we've shown the wisdom sharing prompt
  static Future<void> _markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastWisdomPromptKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setBool(_hasSeenWisdomPromptKey, true);
  }

  /// Check and automatically show wisdom sharing prompt if conditions are met
  static Future<void> checkAndShowWisdomPrompt(BuildContext context) async {
    if (await shouldShowWisdomPrompt()) {
      // Wait a bit before showing to not overwhelm user
      await Future.delayed(Duration(seconds: 2));
      if (context.mounted) {
        await showWisdomSharingDialog(context);
        await _markPromptShown();
      }
    }
  }

  /// Show the wisdom sharing dialog
  static Future<void> showWisdomSharingDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            children: [
              // Gradient icon container
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.share_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                loc.wisdomSharingTitle,
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.deepOrange.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Swami Vivekananda quote
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.format_quote,
                        color: Colors.deepOrange.shade400,
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        loc.wisdomSharingVivekanandaQuote,
                        style: GoogleFonts.notoSerif(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                          color: Colors.brown.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '— Swami Vivekananda',
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepOrange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Main message
                Text(
                  loc.wisdomSharingMessage,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 16),
                // Gyaana Dāna emphasis
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade100, Colors.orange.shade100],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.deepOrange.shade700,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.wisdomSharingGyaanaDana,
                          style: GoogleFonts.notoSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepOrange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Call to action
                Text(
                  loc.wisdomSharingCallToAction,
                  style: GoogleFonts.notoSans(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                loc.maybeLater,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // User can explore the app to share quotes
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                loc.wisdomSharingGotIt,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Reset wisdom sharing prompt state (for testing/debugging)
  static Future<void> resetPromptState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastWisdomPromptKey);
    await prefs.remove(_hasSeenWisdomPromptKey);
    print('🔄 Wisdom sharing prompt state reset');
  }

  /// Get debug info about wisdom sharing state
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final daysSinceFirstUse = await getDaysSinceFirstUse();
    final shouldShow = await shouldShowWisdomPrompt();

    final lastPromptMillis = prefs.getInt(_lastWisdomPromptKey);
    final lastPromptDate = lastPromptMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(lastPromptMillis)
        : null;

    return {
      'daysSinceFirstUse': daysSinceFirstUse,
      'shouldShowPrompt': shouldShow,
      'lastPromptDate': lastPromptDate?.toIso8601String(),
      'hasSeenPrompt': prefs.getBool(_hasSeenWisdomPromptKey) ?? false,
    };
  }
}
