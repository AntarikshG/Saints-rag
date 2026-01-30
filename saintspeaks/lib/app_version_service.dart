import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'config_service.dart';
import 'notification_service.dart';

class AppVersionService {
  static const String _lastUpdateCheckKey = 'last_update_notification_date';
  static const int _daysBeforeNextReminder = 7;

  // App store URLs from RatingShareService
  static const String _androidStoreUrl = 'https://play.google.com/store/apps/details?id=com.antarikshverse.talkwithsaints';
  static const String _iosStoreUrl = 'https://apps.apple.com/app/id6757002070';

  /// Compare two version strings (e.g., "2.3.0" vs "2.2.0")
  /// Returns: 1 if v1 > v2, -1 if v1 < v2, 0 if equal
  static int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Ensure both have at least 3 parts (major.minor.patch)
    while (parts1.length < 3) parts1.add(0);
    while (parts2.length < 3) parts2.add(0);

    for (int i = 0; i < 3; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }

    return 0;
  }

  /// Get current app version from package info
  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('[AppVersionService] Error getting package info: $e');
      return '2.2.0'; // Fallback to current known version
    }
  }

  /// Check if we should show update notification
  static Future<bool> shouldShowUpdateNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckDate = prefs.getString(_lastUpdateCheckKey);

      if (lastCheckDate == null) {
        return true; // First time check
      }

      final lastCheck = DateTime.parse(lastCheckDate);
      final daysSinceLastCheck = DateTime.now().difference(lastCheck).inDays;

      return daysSinceLastCheck >= _daysBeforeNextReminder;
    } catch (e) {
      print('[AppVersionService] Error checking last notification date: $e');
      return true; // If error, allow notification
    }
  }

  /// Mark that we showed update notification
  static Future<void> _markUpdateNotificationShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUpdateCheckKey, DateTime.now().toIso8601String());
      print('[AppVersionService] ✓ Update notification timestamp saved');
    } catch (e) {
      print('[AppVersionService] Error saving notification timestamp: $e');
    }
  }

  /// Check for app update and show notification if needed
  static Future<void> checkAndNotifyUpdate() async {
    try {
      print('[AppVersionService] === Checking for app update ===');

      // Get current app version
      final currentVersion = await getCurrentVersion();
      print('[AppVersionService] Current version: $currentVersion');

      // Fetch latest version from config
      final config = await ConfigService.fetchConfig();
      final latestVersion = config.latestAppVersion;
      print('[AppVersionService] Latest version: $latestVersion');

      // Compare versions
      final comparison = compareVersions(latestVersion, currentVersion);

      if (comparison > 0) {
        // Latest version is newer
        print('[AppVersionService] Update available: $currentVersion -> $latestVersion');

        // Check if we should show notification
        if (await shouldShowUpdateNotification()) {
          print('[AppVersionService] Showing update notification');
          await NotificationService.showUpdateNotification(latestVersion);
          await _markUpdateNotificationShown();
        } else {
          print('[AppVersionService] Too soon for another reminder');
        }
      } else {
        print('[AppVersionService] App is up to date');
      }

    } catch (e) {
      print('[AppVersionService] Error checking for updates: $e');
    }
  }

  /// Open app store for update
  static Future<void> openAppStore() async {
    try {
      final String storeUrl;

      if (Platform.isIOS) {
        storeUrl = _iosStoreUrl;
      } else if (Platform.isAndroid) {
        storeUrl = _androidStoreUrl;
      } else {
        print('[AppVersionService] Unsupported platform for app store');
        return;
      }

      final Uri url = Uri.parse(storeUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        print('[AppVersionService] ✓ Opened app store: $storeUrl');
      } else {
        print('[AppVersionService] Cannot launch URL: $url');
      }
    } catch (e) {
      print('[AppVersionService] Error opening app store: $e');
    }
  }

  /// Clear update check history (for testing)
  static Future<void> clearUpdateCheckHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUpdateCheckKey);
    print('[AppVersionService] Update check history cleared');
  }
}
