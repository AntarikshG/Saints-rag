import 'package:shared_preferences/shared_preferences.dart';

class BadgeService {
  static const String _pointsKey = 'user_points';

  // Point values for different actions
  static const int POINTS_READ_QUOTE = 5;
  static const int POINTS_READ_ARTICLE = 20;
  static const int POINTS_ASK_QUESTION = 10;
  static const int POINTS_SHARE_QUOTE = 30;

  // Badge thresholds
  static const int BRONZE_THRESHOLD = 0;
  static const int SILVER_THRESHOLD = 500;
  static const int GOLD_THRESHOLD = 1500;
  static const int PLATINUM_THRESHOLD = 2500;
  static const int DIAMOND_THRESHOLD = 5000;

  /// Get current points
  static Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }

  /// Add points for an action
  static Future<int> addPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPoints = prefs.getInt(_pointsKey) ?? 0;
    final newPoints = currentPoints + points;
    await prefs.setInt(_pointsKey, newPoints);
    return newPoints;
  }

  /// Award points for reading a quote
  static Future<int> awardQuotePoints() async {
    return await addPoints(POINTS_READ_QUOTE);
  }

  /// Award points for reading an article
  static Future<int> awardArticlePoints() async {
    return await addPoints(POINTS_READ_ARTICLE);
  }

  /// Award points for asking a question
  static Future<int> awardQuestionPoints() async {
    return await addPoints(POINTS_ASK_QUESTION);
  }

  /// Award points for sharing a quote
  static Future<int> awardSharePoints() async {
    return await addPoints(POINTS_SHARE_QUOTE);
  }

  /// Get current badge based on points
  static BadgeInfo getBadgeInfo(int points) {
    if (points >= DIAMOND_THRESHOLD) {
      return BadgeInfo(
        name: 'Diamond',
        icon: '💎',
        color: 0xFF00BCD4, // Cyan
        pointsForBadge: DIAMOND_THRESHOLD,
        nextThreshold: null,
      );
    } else if (points >= PLATINUM_THRESHOLD) {
      return BadgeInfo(
        name: 'Platinum',
        icon: '⭐',
        color: 0xFFE8E8E8, // Light gray/platinum
        pointsForBadge: PLATINUM_THRESHOLD,
        nextThreshold: DIAMOND_THRESHOLD,
      );
    } else if (points >= GOLD_THRESHOLD) {
      return BadgeInfo(
        name: 'Gold',
        icon: '🏆',
        color: 0xFFFFD700, // Gold
        pointsForBadge: GOLD_THRESHOLD,
        nextThreshold: PLATINUM_THRESHOLD,
      );
    } else if (points >= SILVER_THRESHOLD) {
      return BadgeInfo(
        name: 'Silver',
        icon: '🥈',
        color: 0xFFC0C0C0, // Silver
        pointsForBadge: SILVER_THRESHOLD,
        nextThreshold: GOLD_THRESHOLD,
      );
    } else {
      return BadgeInfo(
        name: 'Bronze',
        icon: '🥉',
        color: 0xFFCD7F32, // Bronze
        pointsForBadge: BRONZE_THRESHOLD,
        nextThreshold: SILVER_THRESHOLD,
      );
    }
  }

  /// Get progress to next badge (0.0 to 1.0)
  static double getProgressToNextBadge(int points) {
    final badgeInfo = getBadgeInfo(points);
    if (badgeInfo.nextThreshold == null) {
      return 1.0; // Max badge achieved
    }

    final pointsInCurrentTier = points - badgeInfo.pointsForBadge;
    final pointsNeededForNextTier = badgeInfo.nextThreshold! - badgeInfo.pointsForBadge;

    return pointsInCurrentTier / pointsNeededForNextTier;
  }

  /// Get points needed for next badge
  static int? getPointsToNextBadge(int points) {
    final badgeInfo = getBadgeInfo(points);
    if (badgeInfo.nextThreshold == null) {
      return null;
    }
    return badgeInfo.nextThreshold! - points;
  }
}

class BadgeInfo {
  final String name;
  final String icon;
  final int color;
  final int pointsForBadge;
  final int? nextThreshold;

  BadgeInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.pointsForBadge,
    this.nextThreshold,
  });
}
