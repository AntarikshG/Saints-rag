import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EkadashiDate {
  final DateTime date;
  final String name;

  EkadashiDate({required this.date, required this.name});

  factory EkadashiDate.fromString(String dateString) {
    DateTime? parsedDate;
    String name = '';

    try {
      // Try parsing standard date formats
      if (dateString.contains('-')) {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            // YYYY-MM-DD format
            parsedDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          } else {
            // DD-MM-YYYY format
            parsedDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
      } else if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          // MM/DD/YYYY format
          parsedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }
      }

      if (parsedDate != null) {
        name = _generateEkadashiName(parsedDate);
      }
    } catch (e) {
      print('Error parsing Ekadashi date: $dateString, error: $e');
      parsedDate = DateTime.now().add(Duration(days: 30));
      name = 'Ekadashi';
    }

    return EkadashiDate(
      date: parsedDate ?? DateTime.now().add(Duration(days: 30)),
      name: name,
    );
  }

  static String _generateEkadashiName(DateTime date) {
    final monthNames = [
      'Pausha', 'Magha', 'Phalguna', 'Chaitra', 'Vaishakha', 'Jyeshtha',
      'Ashadha', 'Shravana', 'Bhadrapada', 'Ashwin', 'Kartika', 'Margashirsha'
    ];

    final dayOfMonth = date.day;
    final phase = dayOfMonth <= 15 ? 'Shukla' : 'Krishna';
    final monthName = monthNames[date.month - 1];

    return '$phase $monthName Ekadashi';
  }

  bool isToday() {
    final today = DateTime.now();
    return date.year == today.year &&
           date.month == today.month &&
           date.day == today.day;
  }

  Duration get timeUntil {
    return date.difference(DateTime.now());
  }

  String get formattedDate {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  @override
  String toString() => '$name - ${date.day}/${date.month}/${date.year}';
}

class EkadashiService {
  static const String _cacheKey = 'cached_ekadashi_dates';
  static const String _lastFetchKey = 'last_ekadashi_fetch';
  static List<EkadashiDate>? _cachedDates;

  static Future<List<EkadashiDate>> getEkadashiDates() async {
    if (_cachedDates != null && _cachedDates!.isNotEmpty) {
      return _cachedDates!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final lastFetch = prefs.getString(_lastFetchKey);

      if (cachedJson != null && lastFetch != null) {
        final lastFetchDate = DateTime.parse(lastFetch);
        final daysSinceLastFetch = DateTime.now().difference(lastFetchDate).inDays;

        if (daysSinceLastFetch < 7) {
          final List<dynamic> cachedList = json.decode(cachedJson);
          _cachedDates = cachedList.map((dateStr) => EkadashiDate.fromString(dateStr)).toList();
          return _cachedDates!;
        }
      }

      final config = await ConfigService.fetchConfig();

      if (config.ekadashiDates.isNotEmpty) {
        _cachedDates = config.ekadashiDates
            .map((dateStr) => EkadashiDate.fromString(dateStr))
            .toList();

        _cachedDates!.sort((a, b) => a.date.compareTo(b.date));

        await prefs.setString(_cacheKey, json.encode(config.ekadashiDates));
        await prefs.setString(_lastFetchKey, DateTime.now().toIso8601String());

        return _cachedDates!;
      }
    } catch (e) {
      print('Error fetching Ekadashi dates: $e');
    }

    return [];
  }

  static Future<EkadashiDate?> getNextEkadashi() async {
    final dates = await getEkadashiDates();
    final now = DateTime.now();

    for (final ekadashiDate in dates) {
      if (ekadashiDate.date.isAfter(now)) {
        return ekadashiDate;
      }
    }

    return null;
  }

  static Future<EkadashiDate?> getTodaysEkadashi() async {
    final dates = await getEkadashiDates();

    for (final ekadashiDate in dates) {
      if (ekadashiDate.isToday()) {
        return ekadashiDate;
      }
    }

    return null;
  }

  static Future<List<EkadashiDate>> getUpcomingEkadashis({int count = 5}) async {
    final dates = await getEkadashiDates();
    final now = DateTime.now();

    return dates
        .where((date) => date.date.isAfter(now))
        .take(count)
        .toList();
  }

  static int getDaysUntilEkadashi(DateTime ekadashiDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(ekadashiDate.year, ekadashiDate.month, ekadashiDate.day);
    return targetDate.difference(today).inDays;
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_lastFetchKey);
    _cachedDates = null;
  }
}

class EkadashiPage extends StatefulWidget {
  @override
  _EkadashiPageState createState() => _EkadashiPageState();
}

class _EkadashiPageState extends State<EkadashiPage> {
  EkadashiDate? nextEkadashi;
  List<EkadashiDate> upcomingEkadashis = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEkadashiData();
  }

  Future<void> _loadEkadashiData() async {
    try {
      final next = await EkadashiService.getNextEkadashi();
      final upcoming = await EkadashiService.getUpcomingEkadashis(count: 10);

      setState(() {
        nextEkadashi = next;
        upcomingEkadashis = upcoming;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final mainGradient = brightness == Brightness.dark
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade900, Colors.grey.shade800],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.shade50,
              Colors.white,
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ekadashi Calendar',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: brightness == Brightness.dark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey.shade900, Colors.grey.shade800],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepOrange.shade100.withOpacity(0.9),
                      Colors.orange.shade50.withOpacity(0.9),
                    ],
                  ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: mainGradient),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.deepOrange,
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nextEkadashi != null) ...[
                      _buildNextEkadashiCard(),
                      SizedBox(height: 24),
                    ],
                    _buildUpcomingEkadashisList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNextEkadashiCard() {
    final daysUntil = EkadashiService.getDaysUntilEkadashi(nextEkadashi!.date);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.shade400,
            Colors.orange.shade300,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Next Ekadashi',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            nextEkadashi!.name,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            nextEkadashi!.formattedDate,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              daysUntil == 0
                  ? 'Today!'
                  : daysUntil == 1
                      ? 'Tomorrow'
                      : '$daysUntil days to go',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEkadashisList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Ekadashis',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        SizedBox(height: 16),
        ...upcomingEkadashis.map((ekadashi) => _buildEkadashiListItem(ekadashi)),
      ],
    );
  }

  Widget _buildEkadashiListItem(EkadashiDate ekadashi) {
    final daysUntil = EkadashiService.getDaysUntilEkadashi(ekadashi.date);
    final brightness = Theme.of(context).brightness;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.6)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.brightness_2,
              color: Colors.deepOrange,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ekadashi.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  ekadashi.formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: daysUntil <= 3
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daysUntil == 0
                  ? 'Today'
                  : daysUntil == 1
                      ? 'Tomorrow'
                      : '$daysUntil days',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: daysUntil <= 3
                    ? Colors.orange.shade700
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
