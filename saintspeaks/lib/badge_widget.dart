import 'package:flutter/material.dart';
import 'badge_service.dart';
import 'package:google_fonts/google_fonts.dart';
class BadgeWidget extends StatefulWidget {
  final bool showDetails;
  final VoidCallback? onTap;
  final String? userName;
  const BadgeWidget({
    Key? key,
    this.showDetails = false,
    this.onTap,
    this.userName,
  }) : super(key: key);
  @override
  BadgeWidgetState createState() => BadgeWidgetState();
}

class BadgeWidgetState extends State<BadgeWidget> {
  int _points = 0;
  BadgeInfo? _badgeInfo;
  @override
  void initState() {
    super.initState();
    _loadBadgeInfo();
  }
  Future<void> _loadBadgeInfo() async {
    final points = await BadgeService.getPoints();
    if (mounted) {
      setState(() {
        _points = points;
        _badgeInfo = BadgeService.getBadgeInfo(points);
      });
    }
  }
  void refresh() {
    _loadBadgeInfo();
  }
  @override
  Widget build(BuildContext context) {
    if (_badgeInfo == null) {
      return SizedBox.shrink();
    }
    if (widget.showDetails) {
      return _buildDetailedBadge();
    } else {
      return _buildCompactBadge();
    }
  }
  Widget _buildCompactBadge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color(_badgeInfo!.color).withOpacity(isDark ? 0.3 : 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(_badgeInfo!.color).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _badgeInfo!.icon,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(width: 6),
            Text(
              '$_points',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDetailedBadge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = BadgeService.getProgressToNextBadge(_points);
    final pointsToNext = BadgeService.getPointsToNextBadge(_points);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Color(_badgeInfo!.color).withOpacity(0.2),
                  Color(_badgeInfo!.color).withOpacity(0.1),
                ]
              : [
                  Color(_badgeInfo!.color).withOpacity(0.3),
                  Color(_badgeInfo!.color).withOpacity(0.15),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(_badgeInfo!.color).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message with user name
          if (widget.userName != null && widget.userName!.isNotEmpty) ...[
            Text(
              'Welcome, ${widget.userName}! 🙏',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 12),
          ],
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _badgeInfo!.icon,
                  style: TextStyle(fontSize: 32),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_badgeInfo!.name} Badge',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$_points Points',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pointsToNext != null) ...[
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next badge',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      '$pointsToNext pts',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white24 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(_badgeInfo!.color),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.stars,
                    color: Color(_badgeInfo!.color),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Maximum badge achieved! 🎉',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12),
          Divider(color: isDark ? Colors.white24 : Colors.black12),
          SizedBox(height: 8),
          Text(
            'How to earn points:',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPointInfo('Quote', '${BadgeService.POINTS_READ_QUOTE} pts', Icons.format_quote, isDark),
              _buildPointInfo('Article', '${BadgeService.POINTS_READ_ARTICLE} pts', Icons.article, isDark),
              _buildPointInfo('Question', '${BadgeService.POINTS_ASK_QUESTION} pts', Icons.question_answer, isDark),
              _buildPointInfo('Share', '${BadgeService.POINTS_SHARE_QUOTE} pts', Icons.share, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointInfo(String label, String points, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        SizedBox(height: 4),
        Text(
          points,
          style: GoogleFonts.notoSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 9,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
