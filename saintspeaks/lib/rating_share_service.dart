import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class RatingShareService {
  static const String _appName = "Saints Speak";
  static const String _shareMessage = "🙏Talk with Saints on Android:\n\n I liked the app and recommend this for staying positive with wisdom of saints, hence sharing this divine experience! 🕉️\n\nDiscover wisdom from great saints and transform your spiritual journey with Talk with Saints.\n\nDownload now: https://play.google.com/store/apps/details?id=com.antarikshverse.talkwithsaints";

  /// Shows a dialog asking user to rate the app and share it
  static Future<void> showRatingShareDialog(BuildContext context) async {
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
                  'Spread Spirituality',
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
                'If you like the app and want to feel difference and spirituality in lives of others, please:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rate us 5 stars ⭐⭐⭐⭐⭐',
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
                      'Share with friends & family',
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
                  '🙏 Help others discover the path to inner peace and spiritual growth',
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
                'Later',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _shareApp(context);
              },
              icon: Icon(Icons.share, size: 20),
              label: Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _rateApp(context);
              },
              icon: Icon(Icons.star, size: 20),
              label: Text('Rate 5⭐'),
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
      _showThankYouMessage(context, 'Thank you for rating! 🙏');
    } catch (e) {
      // If in-app review fails, try to open store directly
      await _openAppStore();
      _showThankYouMessage(context, 'Thank you for your support! 🙏');
    }
  }

  /// Opens the app store for rating
  static Future<void> _openAppStore() async {
    // Replace these with your actual app store URLs
    const String androidUrl = 'https://play.google.com/store/apps/details?id=com.antarikshverse.talkwithsaints';
    const String iosUrl = 'https://apps.apple.com/app/saints-speak/idYOUR_APP_ID';

    try {
      // Try to determine platform and open appropriate store
      // For now, we'll use a generic approach
      final Uri url = Uri.parse(androidUrl); // Change based on platform detection
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch app store: $e');
    }
  }

  /// Shares the app with others
  static Future<void> _shareApp(BuildContext context) async {
    try {
      await Share.share(
        _shareMessage,
        subject: 'Discover Saints Speak - Spiritual Wisdom App 🙏',
      );

      _showThankYouMessage(context, 'Thank you for sharing the spiritual journey! 🌟');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to share at the moment. Please try again.'),
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
  static Future<void> quickShare() async {
    await Share.share(_shareMessage);
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
