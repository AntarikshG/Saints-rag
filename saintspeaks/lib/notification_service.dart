import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'articlesquotes.dart';
import 'articlesquotes_hi.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _tzInitialized = false;

  static Future<void> initialize(BuildContext context) async {
    if (!_tzInitialized) {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(tz.local.name));
      _tzInitialized = true;
    }
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleDailyQuoteNotification(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final lastNotified = prefs.getString('lastQuoteNotificationDate');
    final todayStr = '${today.year}-${today.month}-${today.day}';
    if (lastNotified == todayStr) return; // Already notified today

    // Pick a random time between 10am and 8pm
    final random = Random();
    final hour = 10 + random.nextInt(10); // 10 to 19
    final minute = random.nextInt(60);
    final scheduledTime = tz.TZDateTime(
      tz.local,
      today.year,
      today.month,
      today.day,
      hour,
      minute,
    );
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return; // Don't schedule if time has passed

    // Get quote of the day
    String quote = '';
    String saint = '';
    if (locale.languageCode == 'hi') {
      final allSaints = saintsHi;
      final allQuotes = <Map<String, String>>[];
      for (final s in allSaints) {
        for (final q in s.quotes) {
          allQuotes.add({'quote': q, 'saint': s.name});
        }
      }
      if (allQuotes.isNotEmpty) {
        final picked = allQuotes[random.nextInt(allQuotes.length)];
        quote = picked['quote']!;
        saint = picked['saint']!;
      }
    } else {
      final allSaints = saints;
      final allQuotes = <Map<String, String>>[];
      for (final s in allSaints) {
        for (final q in s.quotes) {
          allQuotes.add({'quote': q, 'saint': s.name});
        }
      }
      if (allQuotes.isNotEmpty) {
        final picked = allQuotes[random.nextInt(allQuotes.length)];
        quote = picked['quote']!;
        saint = picked['saint']!;
      }
    }

    await _notificationsPlugin.zonedSchedule(
      0,
      'Quote of the Day',
      '"$quote"\n- $saint',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_quote_channel',
          'Daily Quote',
          channelDescription: 'Daily motivational quote notification',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    await prefs.setString('lastQuoteNotificationDate', todayStr);
  }
}

class ReadStatusService {
  static const String _readArticlesKey = 'read_articles';
  static const String _readQuotesKey = 'read_quotes';

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
}
