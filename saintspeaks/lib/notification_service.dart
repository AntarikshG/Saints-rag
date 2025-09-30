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

  static Future<void> scheduleDailyQuoteNotifications(Locale locale) async {
    // Cancel any existing notifications
    await _notificationsPlugin.cancelAll();

    // Use periodic notifications instead of exact scheduling
    await _schedulePeriodicNotifications(locale);
  }

  static Future<void> _schedulePeriodicNotifications(Locale locale) async {
    // Schedule morning notification (around 9 AM with some flexibility)
    await _notificationsPlugin.periodicallyShow(
      0, // Morning notification ID
      'Morning Wisdom',
      _getRandomQuoteText(locale),
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_quote_channel',
          'Daily Quotes',
          channelDescription: 'Daily motivational quote notifications',
          importance: Importance.max,
          priority: Priority.high,
          when: null, // Let system decide timing
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
    );

    // Schedule a second daily notification with offset
    await _scheduleSecondDailyNotification(locale);
  }

  static Future<void> _scheduleSecondDailyNotification(Locale locale) async {
    final now = tz.TZDateTime.now(tz.local);
    final random = Random();

    // Schedule evening notification for today (if time hasn't passed) or tomorrow
    var eveningTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      17 + random.nextInt(3), // 5-7 PM with some randomness
      random.nextInt(60),
    );

    // If evening time has passed today, schedule for tomorrow
    if (eveningTime.isBefore(now)) {
      eveningTime = eveningTime.add(Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      1, // Evening notification ID
      'Evening Reflection',
      _getRandomQuoteText(locale),
      eveningTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_quote_channel',
          'Daily Quotes',
          channelDescription: 'Daily motivational quote notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact, // Use inexact instead of exact
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
    );
  }

  static String _getRandomQuoteText(Locale locale) {
    final quote = _getRandomQuote(locale);
    return '"${quote['quote']}"\n- ${quote['saint']}';
  }

  static Map<String, String> _getRandomQuote(Locale locale) {
    final random = Random();
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

    return {'quote': quote, 'saint': saint};
  }

  // Alternative approach: Use a simple daily notification that varies content
  static Future<void> scheduleSimpleDailyNotifications(Locale locale) async {
    await _notificationsPlugin.cancelAll();

    // Single periodic notification that will show different quotes
    await _notificationsPlugin.periodicallyShow(
      100, // Simple notification ID
      'Daily Inspiration',
      'Tap to read today\'s wisdom from the saints',
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_inspiration_channel',
          'Daily Inspiration',
          channelDescription: 'Daily spiritual inspiration',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showWhen: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  // Keep the old method for backward compatibility but mark as deprecated
  @deprecated
  static Future<void> scheduleDailyQuoteNotification(Locale locale) async {
    await scheduleDailyQuoteNotifications(locale);
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

  // Bookmark functionality
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
