import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'articlesquotes.dart';
import 'articlesquotes_hi.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Configurable notification settings
  static const int NOTIFICATIONS_PER_DAY = 20; // Change this to 2 for production
  static const int SCHEDULE_DAYS_AHEAD = 30; // How many days to schedule in advance

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
      return [8, 19]; // Morning and evening
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

  static Future<void> initialize(BuildContext context) async {
    if (_initialized) return;

    // Initialize timezone database
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (e) {
      print('Timezone init error: $e, using UTC');
      try {
        tz.setLocalLocation(tz.UTC);
      } catch (e2) {
        print('Failed to set UTC timezone: $e2');
      }
    }

    // Create notification channel first (Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_quotes',
      'Daily Quotes',
      description: 'Daily motivational quotes from saints',
      importance: Importance.high,
    );

    // Create the notification channel
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Initialize notification plugin
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    try {
      final initialized = await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification tapped');
        },
      );

      if (initialized == true) {
        print('✓ Notifications initialized successfully');
        _initialized = true;
      } else {
        print('✗ Notification initialization returned false');
      }
    } catch (e) {
      print('✗ Error initializing notifications: $e');
    }

    // Request permission for Android 13+
    await _requestPermission();
  }

  static Future<bool> _requestPermission() async {
    try {
      final status = await Permission.notification.status;

      if (status.isGranted) {
        print('✓ Notification permission already granted');
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.notification.request();
        if (result.isGranted) {
          print('✓ Notification permission granted');
          return true;
        } else {
          print('✗ Notification permission denied');
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        print('✗ Notification permission permanently denied');
        return false;
      }

      return status.isGranted;
    } catch (e) {
      print('Permission check error (may be older Android): $e');
      return true; // Assume granted on older versions
    }
  }

  static Future<void> scheduleDailyQuoteNotifications(Locale locale) async {
    print('=== Starting notification scheduling ===');
    print('📅 Scheduling $NOTIFICATIONS_PER_DAY notifications per day for $SCHEDULE_DAYS_AHEAD days');

    if (!_initialized) {
      print('✗ Notifications not initialized');
      return;
    }

    // Request permission first
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      print('✗ No notification permission, skipping scheduling');
      return;
    }

    // Cancel existing notifications
    try {
      await _notificationsPlugin.cancelAll();
      print('✓ Cancelled existing notifications');
    } catch (e) {
      print('Error canceling notifications: $e');
    }

    // Schedule configurable notifications
    await _scheduleConfigurableNotifications(locale);

    print('=== Notification scheduling complete ===');
  }

  static Future<void> _scheduleConfigurableNotifications(Locale locale) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final notificationHours = _notificationHours;

      print('📋 Notification times: ${notificationHours.map((h) => '${h}:00').join(', ')}');

      int notificationId = 1000; // Starting ID for configurable notifications

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
          if (day == 0 && scheduledDate.isBefore(now)) {
            continue;
          }

          final quote = _getRandomQuote(locale);
          final title = _getNotificationTitle(hour);

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
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );

          print('✓ Notification ${notificationId - 1000} scheduled for: $scheduledDate ($title)');
        }
      }

      final totalScheduled = (notificationId - 1000);
      print('🎉 Successfully scheduled $totalScheduled notifications total');

    } catch (e) {
      print('✗ Error scheduling configurable notifications: $e');
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

  static Future<void> showTestNotification() async {
    try {
      // Get the quote of the day for the test notification
      final quote = await _getQuoteOfTheDay(const Locale('en')); // Default to English for test

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
        ),
      );
      print('✓ Test notification sent with Quote of the Day: ${quote['quote']}');
    } catch (e) {
      print('✗ Error showing test notification: $e');
    }
  }

  // Add Quote of the Day functionality
  static Future<Map<String, String>> _getQuoteOfTheDay(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD format

      // Check if we already have a quote for today
      final savedDate = prefs.getString('quote_of_day_date');
      final savedQuote = prefs.getString('quote_of_day_quote');
      final savedSaint = prefs.getString('quote_of_day_saint');

      if (savedDate == today && savedQuote != null && savedSaint != null) {
        // Return today's already selected quote
        return {'quote': savedQuote, 'saint': savedSaint};
      }

      // Generate new quote for today
      final quote = _getRandomQuote(locale);

      // Save today's quote
      await prefs.setString('quote_of_day_date', today);
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

  // Add automatic rescheduling method that should be called periodically
  static Future<void> checkAndRescheduleIfNeeded(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReschedule = prefs.getString('last_reschedule_date');
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Get pending notifications count
      final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();
      final totalPending = pendingNotifications.length;

      print('📋 Current pending notifications: $totalPending');

      // If we have less than 20 pending notifications or it's been more than 15 days since last reschedule
      if (totalPending < 20 || lastReschedule == null) {
        print('🔄 Auto-rescheduling notifications (pending: $totalPending)');
        await scheduleDailyQuoteNotifications(locale);
        await prefs.setString('last_reschedule_date', today);
      } else if (lastReschedule != null) {
        final lastDate = DateTime.parse(lastReschedule);
        final daysSinceReschedule = DateTime.now().difference(lastDate).inDays;

        if (daysSinceReschedule >= 15) {
          print('🔄 Auto-rescheduling notifications (15+ days since last reschedule)');
          await scheduleDailyQuoteNotifications(locale);
          await prefs.setString('last_reschedule_date', today);
        }
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
      if (locale.languageCode == 'hi') {
        final allQuotes = <Map<String, String>>[];
        for (final s in saintsHi) {
          for (final q in s.quotes) {
            allQuotes.add({'quote': q, 'saint': s.name});
          }
        }
        if (allQuotes.isNotEmpty) {
          return allQuotes[random.nextInt(allQuotes.length)];
        }
      } else {
        final allQuotes = <Map<String, String>>[];
        for (final s in saints) {
          for (final q in s.quotes) {
            allQuotes.add({'quote': q, 'saint': s.name});
          }
        }
        if (allQuotes.isNotEmpty) {
          return allQuotes[random.nextInt(allQuotes.length)];
        }
      }
    } catch (e) {
      print('Error getting random quote: $e');
    }

    return {'quote': 'Stay inspired!', 'saint': 'Talk with Saints'};
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
    read.add(articleId);
    await prefs.setStringList(_readArticlesKey, read.toList());
  }

  static Future<Set<String>> getReadQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_readQuotesKey)?.toSet() ?? <String>{};
  }

  static Future<void> markQuoteRead(String quoteId) async {
    final prefs = await SharedPreferences.getInstance();
    final read = prefs.getStringList(_readQuotesKey)?.toSet() ?? <String>{};
    read.add(quoteId);
    await prefs.setStringList(_readQuotesKey, read.toList());
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
