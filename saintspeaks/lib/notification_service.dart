import 'dart:math';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'articlesquotes_en.dart';
import 'articlesquotes_hi.dart';
import 'articlesquotes_bn.dart';
import 'articlesquotes_de.dart';
import 'articlesquotes_kn.dart';
import 'articlesquotes_sa.dart';
import 'ekadashi_service.dart';
import 'quote_of_the_day_page.dart';
import 'l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static GlobalKey<NavigatorState>? _navigatorKey;

  // SharedPreferences key for tracking if we've shown the permission dialog
  static const String _hasAskedNotificationPermissionKey = 'hasAskedNotificationPermission';

  // Configurable notification settings - Changed from 60 to 2 for better reliability
  static const int NOTIFICATIONS_PER_DAY = 2; // Morning and evening notifications
  static const int SCHEDULE_DAYS_AHEAD = 7; // Schedule for a full week

  // Ekadashi notification IDs - separate range to avoid conflicts
  static const int EKADASHI_NOTIFICATION_ID_START = 5000;

  // App update notification ID
  static const int APP_UPDATE_NOTIFICATION_ID = 9000;

  // Calculate notification times based on notifications per day
  static List<int> get _notificationHours {
    if (NOTIFICATIONS_PER_DAY <= 0) return [8]; // Fallback

    // Distribute notifications evenly across waking hours (6 AM to 11 PM = 17 hours)
    const int startHour = 6;  // 6 AM
    const int endHour = 23;   // 11 PM
    const int totalHours = endHour - startHour;

    if (NOTIFICATIONS_PER_DAY == 1) {
      return [8]; // Single notification at 8 AM
    } else if (NOTIFICATIONS_PER_DAY == 2) {
      return [8, 20]; // Morning (8 AM) and evening (8 PM)
    } else {
      // Distribute evenly across the day
      List<int> hours = [];
      for (int i = 0; i < NOTIFICATIONS_PER_DAY; i++) {
        int hour = startHour + (i * totalHours ~/ (NOTIFICATIONS_PER_DAY - 1));
        if (hour > endHour) hour = endHour;
        hours.add(hour);
      }
      return hours;
    }
  }

  // Get notification title based on time of day
  static String _getNotificationTitle(int hour) {
    if (hour < 10) return '🌅 Morning Wisdom';
    if (hour < 14) return '☀️ Midday Inspiration';
    if (hour < 18) return '🌤️ Afternoon Reflection';
    if (hour < 21) return '🌙 Evening Guidance';
    return '✨ Night Contemplation';
  }

  /// Check if we've already asked for notification permission
  static Future<bool> hasAskedForNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasAskedNotificationPermissionKey) ?? false;
  }

  /// Mark that we've asked for notification permission
  static Future<void> markNotificationPermissionAsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasAskedNotificationPermissionKey, true);
  }

  /// Show pre-permission dialog explaining notification benefits
  static Future<bool> showNotificationPermissionDialog(BuildContext context) async {
    print('📱 Showing notification permission dialog...');
    final loc = AppLocalizations.of(context)!;

    bool userAccepted = false;

    await showDialog(
      context: context,
      barrierDismissible: false, // User must interact with dialog
      builder: (_) => PopScope(
        canPop: false, // Prevent back button dismiss
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepOrange.shade300, Colors.deepOrange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                loc.notificationPermissionTitle,
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.notificationPermissionMessage,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('👤 User clicked "Maybe Later"');
                userAccepted = false;
                Navigator.pop(context);
              },
              child: Text(
                loc.maybeLater,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                print('✅ User clicked "Enable Notifications"');
                userAccepted = true;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                loc.enableNotifications,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    print('📱 Dialog closed. User accepted: $userAccepted');
    return userAccepted;
  }

  static Future<void> initialize(BuildContext? context, {GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) return;

    print('🚀 Initializing NotificationService...');

    // Store the navigator key for handling notification taps
    _navigatorKey = navigatorKey;

    // Initialize timezone database
    try {
      tzdata.initializeTimeZones();

      // Use device's local timezone by detecting the system timezone
      final DateTime now = DateTime.now();
      final String timeZoneOffset = now.timeZoneOffset.toString();
      final int offsetHours = now.timeZoneOffset.inHours;

      // Try to find the best matching timezone based on offset
      String? detectedTimeZone = _getTimezoneFromOffset(offsetHours);

      if (detectedTimeZone != null) {
        try {
          tz.setLocalLocation(tz.getLocation(detectedTimeZone));
          print('✓ Timezone set to $detectedTimeZone (offset: $timeZoneOffset)');
        } catch (e) {
          print('Failed to set detected timezone $detectedTimeZone: $e');
          tz.setLocalLocation(tz.UTC);
          print('✓ Timezone set to UTC as fallback');
        }
      } else {
        tz.setLocalLocation(tz.UTC);
        print('✓ Timezone set to UTC (could not detect local timezone)');
      }
    } catch (e) {
      print('Timezone init error: $e, using UTC');
      try {
        tz.setLocalLocation(tz.UTC);
        print('✓ Timezone set to UTC');
      } catch (e2) {
        print('Failed to set UTC timezone: $e2');
      }
    }

    // Create notification channels
    await _createNotificationChannels();

    // Initialize notification plugin
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings - don't auto-request permissions, we'll do it after showing dialog
    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    try {
      final initialized = await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification tapped: ${response.payload}');
          _handleNotificationTap(response);
        },
      );

      if (initialized == true) {
        print('✓ Notifications initialized successfully');
      } else if (initialized == false) {
        print('⚠️ Notification initialization returned false (this is normal on some platforms)');
      } else {
        print('⚠️ Notification initialization returned null');
      }

      // Mark as initialized regardless - we can still use notifications
      _initialized = true;
    } catch (e) {
      print('✗ Error initializing notifications: $e');
      _initialized = true; // Still mark as initialized to allow scheduling
    }

    // Don't automatically request permissions here
    // We'll show the pre-permission dialog first and request based on user's choice
  }

  /// Check if app was launched from a notification and handle it
  static Future<void> handleAppLaunchFromNotification() async {
    try {
      final notificationAppLaunchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();

      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
        print('🚀 App launched from notification with payload: $payload');

        if (payload != null) {
          // Give the app more time to fully initialize (especially on Android)
          // This ensures MaterialApp and navigator are fully built
          await Future.delayed(const Duration(milliseconds: 1500));

          // Handle the notification response
          if (notificationAppLaunchDetails.notificationResponse != null) {
            _handleNotificationTap(notificationAppLaunchDetails.notificationResponse!);
          }
        }
      } else {
        print('📱 App launched normally (not from notification)');
      }
    } catch (e) {
      print('⚠️ Error checking notification launch: $e');
    }
  }

  static Future<void> _createNotificationChannels() async {
    // Daily quotes channel
    const AndroidNotificationChannel quotesChannel = AndroidNotificationChannel(
      'daily_quotes',
      'Daily Quotes',
      description: 'Daily motivational quotes from saints',
      importance: Importance.high,
    );

    // Ekadashi notifications channel
    const AndroidNotificationChannel ekadashiChannel = AndroidNotificationChannel(
      'ekadashi_notifications',
      'Ekadashi Reminders',
      description: 'Notifications for upcoming Ekadashi dates',
      importance: Importance.high,
    );

    // App update notifications channel
    const AndroidNotificationChannel updateChannel = AndroidNotificationChannel(
      'app_update_notifications',
      'App Updates',
      description: 'Notifications about new app versions with new saints and features',
      importance: Importance.high,
    );

    // Create the notification channels
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(quotesChannel);
      await androidPlugin.createNotificationChannel(ekadashiChannel);
      await androidPlugin.createNotificationChannel(updateChannel);
      print('✓ Created notification channels');
    }
  }

  static Future<bool> _requestAllPermissions() async {
    bool allGranted = true;

    try {
      // For iOS, we need to request permissions through the plugin
      if (Platform.isIOS) {
        final bool? result = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );

        if (result == true) {
          print('✓ iOS notification permissions granted');
        } else {
          print('✗ iOS notification permissions denied');
          allGranted = false;
        }
      }

      // For Android, use permission_handler
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          print('✗ Notification permission denied');
          allGranted = false;
        } else {
          print('✓ Notification permission granted');
        }
      } else {
        print('✓ Notification permission already granted');
      }

    } catch (e) {
      print('Permission check error: $e');
      allGranted = false;
    }

    return allGranted;
  }

  static Future<void> scheduleDailyQuoteNotifications(Locale locale) async {
    print('=== Starting notification scheduling (inexact alarms only) ===');
    print('📅 Scheduling $NOTIFICATIONS_PER_DAY notifications per day for $SCHEDULE_DAYS_AHEAD days');

    if (!_initialized) {
      print('✗ Notifications not initialized - initializing now...');
      try {
        await initialize(null);
      } catch (e) {
        print('✗ Failed to initialize notifications: $e');
        return;
      }
    }

    // Request permissions
    final hasPermission = await _requestAllPermissions();
    if (!hasPermission) {
      print('⚠️ Notification permissions missing, but proceeding with scheduling');
    }

    // Cancel existing quote notifications (keep Ekadashi notifications)
    try {
      await _cancelQuoteNotifications();
      print('✓ Cancelled existing quote notifications');
    } catch (e) {
      print('Error canceling quote notifications: $e');
    }

    // Wait a bit to ensure cancellation completes
    await Future.delayed(Duration(milliseconds: 500));

    // Schedule quote notifications
    await _scheduleConfigurableNotifications(locale);

    // Also schedule Ekadashi notifications
    await scheduleEkadashiNotifications();

    // Save scheduling timestamp
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_schedule_date', DateTime.now().toIso8601String());
      print('✓ Saved scheduling timestamp');
    } catch (e) {
      print('Error saving schedule timestamp: $e');
    }

    print('=== Notification scheduling complete ===');
  }

  // Method to schedule Ekadashi notifications
  static Future<void> scheduleEkadashiNotifications() async {
    print('🌙 === Starting Ekadashi notification scheduling ===');

    try {
      // Get only the next 2 upcoming Ekadashi dates instead of 12
      final upcomingEkadashis = await EkadashiService.getUpcomingEkadashis(count: 2);

      if (upcomingEkadashis.isEmpty) {
        print('⚠️ No upcoming Ekadashi dates found');
        return;
      }

      // Cancel existing Ekadashi notifications
      await _cancelEkadashiNotifications();

      int notificationId = EKADASHI_NOTIFICATION_ID_START;
      int scheduledCount = 0;

      print('📅 Scheduling notifications for next ${upcomingEkadashis.length} Ekadashis only');

      for (final ekadashi in upcomingEkadashis) {
        final now = tz.TZDateTime.now(tz.local);

        // Schedule day-before notification (evening at 7 PM)
        final dayBeforeDate = tz.TZDateTime(
          tz.local,
          ekadashi.date.year,
          ekadashi.date.month,
          ekadashi.date.day - 1,
          19, // 7 PM
        );

        // Schedule day-of notification (morning at 6 AM)
        final dayOfDate = tz.TZDateTime(
          tz.local,
          ekadashi.date.year,
          ekadashi.date.month,
          ekadashi.date.day,
          6, // 6 AM
        );

        // Schedule day-before notification if it's in the future
        if (dayBeforeDate.isAfter(now)) {
          try {
            await _notificationsPlugin.zonedSchedule(
              notificationId++,
              '🌙 Tomorrow is Ekadashi',
              'Prepare for ${ekadashi.name} tomorrow. Consider fasting and spiritual practices.',
              dayBeforeDate,
              _getEkadashiNotificationDetails(isPreReminder: true),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: 'ekadashi_reminder',
            );
            scheduledCount++;
            print('✓ Scheduled day-before notification for ${ekadashi.name}: $dayBeforeDate');
          } catch (e) {
            print('✗ Failed to schedule day-before notification for ${ekadashi.name}: $e');
          }
        }

        // Schedule day-of notification if it's in the future
        if (dayOfDate.isAfter(now)) {
          try {
            await _notificationsPlugin.zonedSchedule(
              notificationId++,
              '🕉️ Today is Ekadashi',
              '${ekadashi.name} - A sacred day for fasting, meditation, and devotion.',
              dayOfDate,
              _getEkadashiNotificationDetails(isPreReminder: false),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: 'ekadashi_today',
            );
            scheduledCount++;
            print('✓ Scheduled day-of notification for ${ekadashi.name}: $dayOfDate');
          } catch (e) {
            print('✗ Failed to schedule day-of notification for ${ekadashi.name}: $e');
          }
        }
      }

      // Save Ekadashi scheduling timestamp
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_ekadashi_schedule_date', DateTime.now().toIso8601String());
        print('✓ Saved Ekadashi scheduling timestamp');
      } catch (e) {
        print('Error saving Ekadashi schedule timestamp: $e');
      }

      print('🎉 Successfully scheduled $scheduledCount Ekadashi notifications for next 2 Ekadashis');

    } catch (e) {
      print('✗ Error scheduling Ekadashi notifications: $e');
    }

    print('🌙 === Ekadashi notification scheduling complete ===');
  }

  static NotificationDetails _getEkadashiNotificationDetails({required bool isPreReminder}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'ekadashi_notifications',
        'Ekadashi Reminders',
        channelDescription: 'Notifications for upcoming Ekadashi dates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        styleInformation: BigTextStyleInformation(''),
        ticker: isPreReminder ? 'Ekadashi Tomorrow' : 'Ekadashi Today',
        visibility: NotificationVisibility.public,
        color: Color(0xFFFF6F00), // Orange color for Ekadashi notifications
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );
  }

  static Future<void> _cancelQuoteNotifications() async {
    try {
      final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();

      // Cancel notifications in the quote ID range (1000-4999)
      for (final notification in pendingNotifications) {
        if (notification.id >= 1000 && notification.id < EKADASHI_NOTIFICATION_ID_START) {
          await _notificationsPlugin.cancel(notification.id);
        }
      }
      print('✓ Cancelled quote notifications');
    } catch (e) {
      print('✗ Error cancelling quote notifications: $e');
    }
  }

  static Future<void> _cancelEkadashiNotifications() async {
    try {
      final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();

      // Cancel notifications in the Ekadashi ID range (5000+)
      for (final notification in pendingNotifications) {
        if (notification.id >= EKADASHI_NOTIFICATION_ID_START) {
          await _notificationsPlugin.cancel(notification.id);
        }
      }
      print('✓ Cancelled Ekadashi notifications');
    } catch (e) {
      print('✗ Error cancelling Ekadashi notifications: $e');
    }
  }

  // Method to show immediate Ekadashi test notification
  static Future<void> showTestEkadashiNotification() async {
    try {
      final nextEkadashi = await EkadashiService.getNextEkadashi();
      final title = nextEkadashi != null
          ? '🌙 Next Ekadashi: ${nextEkadashi.name}'
          : '🌙 Ekadashi Reminder Test';
      final body = nextEkadashi != null
          ? 'Coming up on ${nextEkadashi.date.day}/${nextEkadashi.date.month}/${nextEkadashi.date.year}'
          : 'This is a test notification for Ekadashi reminders.';

      await _notificationsPlugin.show(
        998,
        title,
        body,
        _getEkadashiNotificationDetails(isPreReminder: false),
        payload: 'ekadashi_test',
      );
      print('✓ Test Ekadashi notification sent');
    } catch (e) {
      print('✗ Error showing test Ekadashi notification: $e');
    }
  }

  // Enhanced method to check and reschedule notifications including Ekadashi
  static Future<void> checkAndRescheduleIfNeeded(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReschedule = prefs.getString('last_reschedule_date');
      final lastEkadashiSchedule = prefs.getString('last_ekadashi_schedule_date');
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Get pending notifications count
      final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();
      final totalPending = pendingNotifications.length;

      // Count Ekadashi notifications
      final ekadashiNotifications = pendingNotifications
          .where((n) => n.id >= EKADASHI_NOTIFICATION_ID_START)
          .length;

      print('📋 Current pending notifications: $totalPending (Ekadashi: $ekadashiNotifications)');

      bool needsReschedule = false;

      // Check if we need to reschedule quotes
      if (totalPending < 8 || lastReschedule == null) {
        needsReschedule = true;
      } else if (lastReschedule != null) {
        final lastDate = DateTime.parse(lastReschedule);
        final daysSinceReschedule = DateTime.now().difference(lastDate).inDays;
        if (daysSinceReschedule >= 5) {
          needsReschedule = true;
        }
      }

      // Check if we need to reschedule Ekadashi notifications
      bool needsEkadashiReschedule = false;
      if (ekadashiNotifications < 4 || lastEkadashiSchedule == null) {
        needsEkadashiReschedule = true;
      } else if (lastEkadashiSchedule != null) {
        final lastDate = DateTime.parse(lastEkadashiSchedule);
        final daysSinceReschedule = DateTime.now().difference(lastDate).inDays;
        if (daysSinceReschedule >= 30) { // Reschedule Ekadashi notifications monthly
          needsEkadashiReschedule = true;
        }
      }

      if (needsReschedule) {
        print('🔄 Auto-rescheduling all notifications');
        await scheduleDailyQuoteNotifications(locale);
      } else if (needsEkadashiReschedule) {
        print('🔄 Auto-rescheduling Ekadashi notifications');
        await scheduleEkadashiNotifications();
        await prefs.setString('last_ekadashi_schedule_date', today);
      }

    } catch (e) {
      print('✗ Error in auto-reschedule check: $e');
    }
  }

  static String _getRandomQuoteText(Locale locale) {
    final quote = _getRandomQuote(locale);
    return '"${quote['quote']}"\n\n- ${quote['saint']}';
  }

  static Map<String, String> _getRandomQuote(Locale locale) {
    final random = Random();

    try {
      final allQuotes = <Map<String, String>>[];

      if (locale.languageCode == 'hi') {
        for (final s in saintsHi) {
          for (final q in s.quotes) {
            allQuotes.add({'quote': q, 'saint': s.name});
          }
        }
      } else if (locale.languageCode == 'bn') {
        for (final s in saintsBn) {
          for (final q in s.quotes) {
            allQuotes.add({'quote': q, 'saint': s.name});
          }
        }
      } else if (locale.languageCode == 'kn') {
        for (final s in saintsKn) {
          for (final q in s.quotes) {
            allQuotes.add({'quote': q, 'saint': s.name});
          }
        }
      } else if (locale.languageCode == 'de') {
        for (final s in saintsDe) {
          for (final q in s.quotes) {
            allQuotes.add({'quote': q, 'saint': s.name});
          }
        }
      } else if (locale.languageCode == 'sa') {
        for (final s in saintsSa) {
          for (final q in s.quotes) {
            allQuotes.add({'quote': q, 'saint': s.name});
          }
        }
      } else {
        for (final s in saintsEn) {
          for (final q in s.quotes) {
            allQuotes.add({'quote': q, 'saint': s.name});
          }
        }
      }

      if (allQuotes.isNotEmpty) {
        return allQuotes[random.nextInt(allQuotes.length)];
      }
    } catch (e) {
      print('Error getting random quote: $e');
    }

    return {'quote': 'Stay inspired!', 'saint': 'Talk with Saints'};
  }

  // Private method to map timezone offsets to IANA timezone names
  static String? _getTimezoneFromOffset(int offsetHours) {
    // Common timezone mapping based on UTC offset (using valid IANA names)
    const Map<int, String> offsetMap = {
      -12: 'Etc/GMT+12',
      -11: 'Pacific/Midway',
      -10: 'Pacific/Honolulu',
      -9: 'America/Anchorage',
      -8: 'America/Los_Angeles',
      -7: 'America/Denver',
      -6: 'America/Chicago',
      -5: 'America/New_York',
      -4: 'America/Halifax',
      -3: 'America/Sao_Paulo',
      -2: 'Atlantic/South_Georgia',
      -1: 'Atlantic/Azores',
      0: 'Europe/London',
      1: 'Europe/Berlin',
      2: 'Europe/Athens',
      3: 'Europe/Moscow',
      4: 'Asia/Dubai',
      5: 'Asia/Karachi',
      6: 'Asia/Dhaka',
      7: 'Asia/Bangkok',
      8: 'Asia/Shanghai',
      9: 'Asia/Tokyo',
      10: 'Australia/Sydney',
      11: 'Pacific/Noumea',
      12: 'Pacific/Auckland',
    };

    // For India Standard Time (UTC+5:30), check for half-hour offset
    final DateTime now = DateTime.now();
    final int offsetMinutes = now.timeZoneOffset.inMinutes;

    // Handle special cases for half-hour and quarter-hour timezones
    if (offsetMinutes == 330) { // +5:30 (India Standard Time)
      return 'Asia/Kolkata';
    } else if (offsetMinutes == -210) { // -3:30 (Newfoundland)
      return 'America/St_Johns';
    } else if (offsetMinutes == 270) { // +4:30 (Afghanistan)
      return 'Asia/Kabul';
    } else if (offsetMinutes == 345) { // +5:45 (Nepal)
      return 'Asia/Kathmandu';
    } else if (offsetMinutes == 390) { // +6:30 (Myanmar)
      return 'Asia/Yangon';
    } else if (offsetMinutes == 570) { // +9:30 (Central Australia)
      return 'Australia/Adelaide';
    } else if (offsetMinutes == 630) { // +10:30 (Lord Howe Island)
      return 'Australia/Lord_Howe';
    }

    return offsetMap[offsetHours];
  }

  static Future<void> _scheduleConfigurableNotifications(Locale locale) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final notificationHours = _notificationHours;

      print('📋 Notification times: ${notificationHours.map((h) => '${h}:00').join(', ')}');

      int notificationId = 1000; // Starting ID for configurable notifications
      int successCount = 0;

      // Schedule notifications for each day
      for (int day = 0; day < SCHEDULE_DAYS_AHEAD; day++) {
        final baseDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: day));

        // Schedule notifications for each hour of this day
        for (int hourIndex = 0; hourIndex < notificationHours.length; hourIndex++) {
          final hour = notificationHours[hourIndex];
          final scheduledDate = baseDate.add(Duration(hours: hour));

          // Skip notifications that are in the past (only for today)
          if (day == 0 && scheduledDate.isBefore(now.add(Duration(minutes: 1)))) {
            print('⏭️ Skipping past notification: $scheduledDate');
            continue;
          }

          final quote = _getRandomQuote(locale);
          final title = _getNotificationTitle(hour);

          try {
            // Create payload with quote data
            final payload = 'daily_quote|${quote['quote']}|${quote['saint']}';

            await _notificationsPlugin.zonedSchedule(
              notificationId++,
              title,
              '"${quote['quote']}"\n\n- ${quote['saint']}',
              scheduledDate,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'daily_quotes',
                  'Daily Quotes',
                  channelDescription: 'Daily motivational quotes from saints',
                  importance: Importance.high,
                  priority: Priority.high,
                  showWhen: true,
                  icon: '@mipmap/ic_launcher',
                  enableVibration: true,
                  playSound: true,
                  autoCancel: true,
                  styleInformation: BigTextStyleInformation(''),
                  // Add these for better reliability
                  ticker: 'Daily Quote',
                  visibility: NotificationVisibility.public,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                  sound: 'default',
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: payload,
            );

            successCount++;
            print('✓ Notification ${notificationId - 1000} scheduled (inexact) for: $scheduledDate ($title)');
          } catch (e) {
            print('✗ Failed to schedule notification ${notificationId - 1000}: $e');
          }
        }
      }

      print('🎉 Successfully scheduled $successCount notifications total (all inexact)');

      // Verify scheduled notifications
      await Future.delayed(Duration(milliseconds: 1000));
      await checkPendingNotifications();

    } catch (e) {
      print('✗ Error scheduling notifications: $e');
    }
  }

  // Method to get current notification configuration info
  static String getNotificationConfigInfo() {
    final hours = _notificationHours;
    return 'Notifications: $NOTIFICATIONS_PER_DAY per day at ${hours.map((h) => '${h}:00').join(', ')}';
  }

  // Add method to reschedule notifications (call this monthly instead of weekly)
  static Future<void> rescheduleNotifications(Locale locale) async {
    print('=== Rescheduling notifications ===');
    await scheduleDailyQuoteNotifications(locale);
  }

  // Method to check pending notifications (for debugging)
  static Future<void> checkPendingNotifications() async {
    try {
      final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();
      print('📋 Pending notifications: ${pendingNotifications.length}');
      for (final notification in pendingNotifications) {
        print('   ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      print('✗ Error checking pending notifications: $e');
    }
  }

  static Future<void> showTestNotification(Locale locale) async {
    try {
      // Get the quote of the day for the test notification using the provided locale
      final quote = await _getQuoteOfTheDay(locale);

      // Create payload with quote data
      final payload = 'daily_quote|${quote['quote']}|${quote['saint']}';

      await _notificationsPlugin.show(
        999,
        '✅ Quote of the Day',
        '"${quote['quote']}"\n\n- ${quote['saint']}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notification channel',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: payload,
      );
      print('✓ Test notification sent with Quote of the Day (${locale.languageCode}): ${quote['quote']}');
    } catch (e) {
      print('✗ Error showing test notification: $e');
    }
  }

  // Add Quote of the Day functionality
  static Future<Map<String, String>> _getQuoteOfTheDay(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD format
      final languageCode = locale.languageCode;

      // Check if we already have a quote for today in the current language
      final savedDate = prefs.getString('quote_of_day_date');
      final savedLanguage = prefs.getString('quote_of_day_language');
      final savedQuote = prefs.getString('quote_of_day_quote');
      final savedSaint = prefs.getString('quote_of_day_saint');

      if (savedDate == today && savedLanguage == languageCode && savedQuote != null && savedSaint != null) {
        // Return today's already selected quote for this language
        return {'quote': savedQuote, 'saint': savedSaint};
      }

      // Generate new quote for today in the current language
      final quote = _getRandomQuote(locale);

      // Save today's quote with the language code
      await prefs.setString('quote_of_day_date', today);
      await prefs.setString('quote_of_day_language', languageCode);
      await prefs.setString('quote_of_day_quote', quote['quote']!);
      await prefs.setString('quote_of_day_saint', quote['saint']!);

      return quote;
    } catch (e) {
      print('Error getting quote of the day: $e');
      return _getRandomQuote(locale);
    }
  }

  // Public method to get Quote of the Day (for use in other parts of the app)
  static Future<Map<String, String>> getQuoteOfTheDay(Locale locale) async {
    return await _getQuoteOfTheDay(locale);
  }

  // New method to get a fresh random quote each time (for quote of the day page)
  static Map<String, String> getRandomQuoteNow(Locale locale) {
    return _getRandomQuote(locale);
  }

  // Handle notification tap - navigate to Quote of the Day page
  static void _handleNotificationTap(NotificationResponse response) {
    print('📱 Handling notification tap with payload: ${response.payload}');

    // Handle app update notification
    if (response.payload == 'app_update') {
      print('🔄 Opening app store for update');
      _openAppStoreForUpdate();
      return;
    }

    // Handle Ekadashi notification
    if (response.payload == 'ekadashi_test' || (response.payload?.startsWith('ekadashi') ?? false)) {
      print('🌙 Ekadashi notification tapped - no specific action needed');
      return;
    }

    // Try to navigate, with retry if context not available yet
    _navigateToQuoteOfDay(response, retryCount: 0);
  }

  static void _navigateToQuoteOfDay(NotificationResponse response, {int retryCount = 0}) {
    // Use the navigator key to navigate to the Quote of the Day page
    if (_navigatorKey?.currentContext != null) {
      final context = _navigatorKey!.currentContext!;

      // Parse the payload to extract quote data
      String? quoteText;
      String? saintName;

      if (response.payload != null && response.payload!.startsWith('daily_quote|')) {
        try {
          final parts = response.payload!.split('|');
          if (parts.length >= 3) {
            quoteText = parts[1];
            saintName = parts[2];
            print('📝 Parsed quote: "$quoteText" by $saintName');
          }
        } catch (e) {
          print('⚠️ Error parsing payload: $e');
        }
      }

      // Navigate to Quote of the Day page with the quote data
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuoteOfTheDayPage(
            notificationQuote: quoteText,
            notificationSaint: saintName,
          ),
        ),
      );
      print('✓ Navigated to Quote of the Day page');
    } else {
      // Context not available yet, retry up to 10 times with longer delays for Android
      if (retryCount < 10) {
        final delayMs = (retryCount + 1) * 500; // 500ms, 1000ms, 1500ms, 2000ms, etc.
        print('⚠️ Navigator context not available yet, retrying in ${delayMs}ms (attempt ${retryCount + 1}/10)');
        Future.delayed(Duration(milliseconds: delayMs), () {
          _navigateToQuoteOfDay(response, retryCount: retryCount + 1);
        });
      } else {
        print('❌ Navigator context not available after 10 retries. Cannot navigate.');
      }
    }
  }

  /// Open app store for update - called when update notification is tapped
  static Future<void> _openAppStoreForUpdate() async {
    try {
      // App store URLs
      const String androidUrl = 'https://play.google.com/store/apps/details?id=com.antarikshverse.talkwithsaints';
      const String iosUrl = 'https://apps.apple.com/app/id6757002070';

      final String storeUrl;

      if (Platform.isIOS) {
        storeUrl = iosUrl;
      } else if (Platform.isAndroid) {
        storeUrl = androidUrl;
      } else {
        print('[NotificationService] Unsupported platform for app store');
        return;
      }

      final Uri url = Uri.parse(storeUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        print('[NotificationService] ✓ Opened app store: $storeUrl');
      } else {
        print('[NotificationService] Cannot launch URL: $url');
      }
    } catch (e) {
      print('[NotificationService] Error opening app store: $e');
    }
  }

  /// Show app update notification
  static Future<void> showUpdateNotification(String latestVersion) async {
    try {
      await _notificationsPlugin.show(
        APP_UPDATE_NOTIFICATION_ID,
        '🎉 New Version Available!',
        'Version $latestVersion is now available with new saints and features. Tap to update now!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'app_update_notifications',
            'App Updates',
            channelDescription: 'Notifications about new app versions with new saints and features',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            autoCancel: true,
            styleInformation: BigTextStyleInformation(''),
            ticker: 'App Update Available',
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: 'app_update',
      );
      print('✓ App update notification sent');
    } catch (e) {
      print('✗ Error showing app update notification: $e');
    }
  }
}

class ReadStatusService {
  static const String _readArticlesKey = 'read_articles';
  static const String _readQuotesKey = 'read_quotes';
  static const String _bookmarkedQuotesKey = 'bookmarked_quotes';

  static Future<Set<String>> getReadArticles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_readArticlesKey)?.toSet() ?? <String>{};
  }

  static Future<void> markArticleRead(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final read = prefs.getStringList(_readArticlesKey)?.toSet() ?? <String>{};
    final wasNew = !read.contains(articleId);
    read.add(articleId);
    await prefs.setStringList(_readArticlesKey, read.toList());

    // Award points only if this is the first time reading this article
    if (wasNew) {
      // Import badge_service dynamically to avoid circular dependencies
      // The calling code will handle points awarding
    }
  }

  static Future<Set<String>> getReadQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_readQuotesKey)?.toSet() ?? <String>{};
  }

  static Future<void> markQuoteRead(String quoteId) async {
    final prefs = await SharedPreferences.getInstance();
    final read = prefs.getStringList(_readQuotesKey)?.toSet() ?? <String>{};
    final wasNew = !read.contains(quoteId);
    read.add(quoteId);
    await prefs.setStringList(_readQuotesKey, read.toList());

    // Award points only if this is the first time reading this quote
    if (wasNew) {
      // Import badge_service dynamically to avoid circular dependencies
      // The calling code will handle points awarding
    }
  }

  // Helper methods to check if quote/article was already read before marking
  static Future<bool> wasQuoteRead(String quoteId) async {
    final read = await getReadQuotes();
    return read.contains(quoteId);
  }

  static Future<bool> wasArticleRead(String articleId) async {
    final read = await getReadArticles();
    return read.contains(articleId);
  }

  static Future<Set<String>> getBookmarkedQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_bookmarkedQuotesKey)?.toSet() ?? <String>{};
  }

  static Future<void> bookmarkQuote(String quoteId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarked = prefs.getStringList(_bookmarkedQuotesKey)?.toSet() ?? <String>{};
    bookmarked.add(quoteId);
    await prefs.setStringList(_bookmarkedQuotesKey, bookmarked.toList());
  }

  static Future<void> removeBookmark(String quoteId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarked = prefs.getStringList(_bookmarkedQuotesKey)?.toSet() ?? <String>{};
    bookmarked.remove(quoteId);
    await prefs.setStringList(_bookmarkedQuotesKey, bookmarked.toList());
  }

  static Future<bool> isQuoteBookmarked(String quoteId) async {
    final bookmarked = await getBookmarkedQuotes();
    return bookmarked.contains(quoteId);
  }
}
