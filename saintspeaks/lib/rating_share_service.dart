import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'l10n/app_localizations.dart';

class RatingShareService {
  static const String _appName = "Saints Speak";

  // SharedPreferences keys
  static const String _lastRatingPromptKey = 'lastRatingPromptDate';
  static const String _hasUserRatedKey = 'hasUserRated';
  static const String _firstInstallDateKey = 'firstInstallDate';
  static const String _appOpenCountKey = 'appOpenCount';
  static const int _daysBeforeNextPrompt = 5;
  static const int _minimumDaysToPrompt = 5; // User must have app installed for 5+ days
  static const int _minimumAppOpens = 3; // User must have opened app 3+ times (regular user)

  /// Initialize tracking on app start - records first install date and increments app open count
  static Future<void> trackAppUsage() async {
    final prefs = await SharedPreferences.getInstance();

    // Record first install date if not already set
    if (!prefs.containsKey(_firstInstallDateKey)) {
      await prefs.setInt(_firstInstallDateKey, DateTime.now().millisecondsSinceEpoch);
    }

    // Increment app open count
    final currentCount = prefs.getInt(_appOpenCountKey) ?? 0;
    await prefs.setInt(_appOpenCountKey, currentCount + 1);
  }

  /// Get the number of days since first install
  static Future<int> getDaysSinceInstall() async {
    final prefs = await SharedPreferences.getInstance();
    final firstInstallMillis = prefs.getInt(_firstInstallDateKey);

    if (firstInstallMillis == null) {
      return 0;
    }

    final firstInstallDate = DateTime.fromMillisecondsSinceEpoch(firstInstallMillis);
    return DateTime.now().difference(firstInstallDate).inDays;
  }

  /// Get the number of times the app has been opened
  static Future<int> getAppOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_appOpenCountKey) ?? 0;
  }

  /// Check if user is a regular user (meets minimum usage criteria)
  static Future<bool> isRegularUser() async {
    final daysSinceInstall = await getDaysSinceInstall();
    final appOpenCount = await getAppOpenCount();

    // User is regular if they've had the app for 5+ days AND opened it 3+ times
    return daysSinceInstall >= _minimumDaysToPrompt && appOpenCount >= _minimumAppOpens;
  }

  /// Check if we should show the rating prompt
  /// Returns true if user is regular, hasn't rated, and it's been 5+ days since last prompt
  static Future<bool> shouldShowRatingPrompt() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user has already rated
    final hasRated = prefs.getBool(_hasUserRatedKey) ?? false;
    if (hasRated) {
      return false;
    }

    // Check if user is a regular user (5+ days since install AND 3+ app opens)
    if (!await isRegularUser()) {
      return false;
    }

    // Check when we last prompted
    final lastPromptMillis = prefs.getInt(_lastRatingPromptKey);
    if (lastPromptMillis == null) {
      // Never prompted before, but user is regular - show prompt
      return true;
    }

    final lastPromptDate = DateTime.fromMillisecondsSinceEpoch(lastPromptMillis);
    final daysSinceLastPrompt = DateTime.now().difference(lastPromptDate).inDays;

    return daysSinceLastPrompt >= _daysBeforeNextPrompt;
  }

  /// Mark that we've shown the rating prompt
  static Future<void> _markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastRatingPromptKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Mark that the user has rated the app
  static Future<void> _markUserRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasUserRatedKey, true);
  }

  /// Check and automatically show rating prompt if conditions are met
  static Future<void> checkAndShowRatingPrompt(BuildContext context) async {
    if (await shouldShowRatingPrompt()) {
      // Wait a bit before showing to not overwhelm user on app start
      await Future.delayed(Duration(seconds: 3));
      if (context.mounted) {
        await showRatingShareDialog(context);
        await _markPromptShown();
      }
    }
  }

  /// Shows a dialog asking user to rate the app and share it
  static Future<void> showRatingShareDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 28,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.spreadSpirituality,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange.shade800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.rateShareDialogContent,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.rateUs5Stars,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.share, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.shareWithFriendsFamily,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  loc.helpOthersDiscover,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.deepOrange.shade700,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                loc.later,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _shareApp(context);
              },
              icon: Icon(Icons.share, size: 20),
              label: Text(loc.share),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _markUserRated(); // Mark that user has rated
                _rateApp(context);
              },
              icon: Icon(Icons.star, size: 20),
              label: Text(loc.rate5Star),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Opens the app rating dialog
  static Future<void> _rateApp(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    try {
      final InAppReview inAppReview = InAppReview.instance;

      // Check if in-app review is available
      if (await inAppReview.isAvailable()) {
        // Show in-app review dialog
        await inAppReview.requestReview();
      } else {
        // Fallback to opening store
        await _openAppStore();
      }

      // Show thank you message
      _showThankYouMessage(context, loc.thankYouForRating);
    } catch (e) {
      // If in-app review fails, try to open store directly
      await _openAppStore();
      _showThankYouMessage(context, loc.thankYouForSupport);
    }
  }

  /// Opens the app store for rating
  static Future<void> _openAppStore() async {
    // Replace these with your actual app store URLs
    const String androidUrl = 'https://play.google.com/store/apps/details?id=com.antarikshverse.talkwithsaints';
    const String iosUrl = 'https://apps.apple.com/us/app/talk-with-saints-ai/id6757002070';

    try {
      // Determine platform and use appropriate store URL
      final String storeUrl;
      if (Theme.of(WidgetsBinding.instance.rootElement!).platform == TargetPlatform.iOS) {
        storeUrl = iosUrl;
      } else {
        storeUrl = androidUrl;
      }

      final Uri url = Uri.parse(storeUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch app store: $e');
    }
  }

  /// Shares the app with others
  static Future<void> _shareApp(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;

    try {
      // Get share position origin for iOS
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      // Load the promote image from assets
      final ByteData imageData = await rootBundle.load('assets/images/Promote_1.jpeg');
      final List<int> bytes = imageData.buffer.asUint8List();

      // Get temporary directory to save the image
      final tempDir = await getTemporaryDirectory();
      final imagePath = '${tempDir.path}/promote_1.jpeg';
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(bytes);

      // Share both text and image
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: loc.shareMessageAndroid,
        subject: loc.shareSubject,
        sharePositionOrigin: sharePositionOrigin,
      );

      _showThankYouMessage(context, loc.thankYouForSharing);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.unableToShare),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  /// Shows a thank you message to the user
  static void _showThankYouMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.favorite, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.deepOrange,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Quick share function for use in other parts of the app
  static Future<void> quickShare({Rect? sharePositionOrigin}) async {
    const shareMessage = "🙏Talk with Saints on Android:\n\n I liked the app and recommend this for staying positive with wisdom of saints, hence sharing this divine experience! 🕉️\n\nDiscover wisdom from great saints and transform your spiritual journey with Talk with Saints.\n\nDownload now: https://play.google.com/store/apps/details?id=com.antarikshverse.talkwithsaints";

    try {
      // Load the promote image from assets
      final ByteData imageData = await rootBundle.load('assets/images/Promote_1.jpeg');
      final List<int> bytes = imageData.buffer.asUint8List();

      // Get temporary directory to save the image
      final tempDir = await getTemporaryDirectory();
      final imagePath = '${tempDir.path}/promote_1.jpeg';
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(bytes);

      // Share both text and image
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: shareMessage,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      // Fallback to text-only sharing if image sharing fails
      await Share.share(shareMessage, sharePositionOrigin: sharePositionOrigin);
    }
  }

  /// Quick rate function for use in other parts of the app
  static Future<void> quickRate() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await _openAppStore();
      }
    } catch (e) {
      await _openAppStore();
    }
  }
}
