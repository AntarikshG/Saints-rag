import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_service.dart';
import 'l10n/app_localizations.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool isScheduling = false;
  bool schedulingComplete = false;
  String statusMessage = '';
  int pendingNotifications = 0;

  @override
  void initState() {
    super.initState();
    _checkPendingNotifications();
  }

  Future<void> _checkPendingNotifications() async {
    try {
      await NotificationService.checkPendingNotifications();
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }

  Future<void> _scheduleDailyNotifications() async {
    setState(() {
      isScheduling = true;
      statusMessage = 'Scheduling notifications...';
      schedulingComplete = false;
    });

    try {
      final locale = Localizations.localeOf(context);
      await NotificationService.scheduleDailyQuoteNotifications(locale);

      setState(() {
        isScheduling = false;
        schedulingComplete = true;
        statusMessage = 'Daily notifications scheduled successfully! ✓';
      });

      await _checkPendingNotifications();
    } catch (e) {
      setState(() {
        isScheduling = false;
        schedulingComplete = false;
        statusMessage = 'Error scheduling notifications: $e';
      });
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      final locale = Localizations.localeOf(context);
      await NotificationService.showTestNotification(locale);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Test notification sent! Check your notification panel.'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          loc.setDailyNotifications,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      Colors.deepOrange.shade900.withOpacity(0.9),
                      Colors.orange.shade800.withOpacity(0.9),
                    ]
                  : [
                      Colors.deepOrange.shade100.withOpacity(0.9),
                      Colors.orange.shade50.withOpacity(0.9),
                    ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    Colors.grey.shade900,
                    Colors.black,
                  ]
                : [
                    Colors.deepOrange.shade50,
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon
                Center(
                  child: Container(
                    padding: EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.deepOrange.shade900.withOpacity(0.3)
                          : Colors.deepOrange.shade50,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      size: 60,
                      color: isDarkMode
                          ? Colors.deepOrange.shade300
                          : Colors.deepOrange.shade700,
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Main Information Card
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.deepOrange.shade700
                          : Colors.orange.shade100,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDarkMode
                                ? Colors.deepOrange.shade300
                                : Colors.deepOrange.shade600,
                            size: 26,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Daily Wisdom Notifications',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.deepOrange.shade300
                                    : Colors.deepOrange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),

                      // Description
                      Text(
                        'Receive two inspiring wisdom quotes from saints every day to enrich your spiritual journey:',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          height: 1.5,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Morning notification
                      _buildNotificationInfo(
                        icon: Icons.wb_sunny,
                        iconColor: Colors.orange.shade600,
                        time: '8:00 AM',
                        label: 'Morning Wisdom',
                        description: 'Start your day with inspiration',
                        isDarkMode: isDarkMode,
                      ),
                      SizedBox(height: 12),

                      // Evening notification
                      _buildNotificationInfo(
                        icon: Icons.nights_stay,
                        iconColor: Colors.indigo.shade400,
                        time: '8:00 PM',
                        label: 'Evening Guidance',
                        description: 'End your day with reflection',
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Permission Notice Card
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.amber.shade900.withOpacity(0.3)
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.amber.shade700
                          : Colors.amber.shade200,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: isDarkMode
                            ? Colors.amber.shade400
                            : Colors.amber.shade700,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Important: Enable Notifications',
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.amber.shade300
                                    : Colors.amber.shade900,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please grant notification permissions to receive daily wisdom quotes and maximize your benefit from this app. If you don\'t see any notifications, please check your device\'s app settings and ensure notification permissions are enabled.',
                              style: GoogleFonts.notoSans(
                                fontSize: 14,
                                height: 1.4,
                                color: isDarkMode
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                // Schedule Button
                ElevatedButton(
                  onPressed: isScheduling ? null : _scheduleDailyNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: Colors.deepOrange.withOpacity(0.5),
                  ),
                  child: isScheduling
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Scheduling...',
                              style: GoogleFonts.notoSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Enable Daily Notifications',
                              style: GoogleFonts.notoSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
                SizedBox(height: 16),

                // Test Notification Button
                OutlinedButton(
                  onPressed: _sendTestNotification,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange.shade600,
                    side: BorderSide(color: Colors.deepOrange.shade600, width: 2),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send),
                      SizedBox(width: 10),
                      Text(
                        'Send Test Notification',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Message
                if (statusMessage.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: schedulingComplete
                          ? (isDarkMode
                              ? Colors.green.shade900.withOpacity(0.3)
                              : Colors.green.shade50)
                          : (isDarkMode
                              ? Colors.red.shade900.withOpacity(0.3)
                              : Colors.red.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: schedulingComplete
                            ? (isDarkMode
                                ? Colors.green.shade700
                                : Colors.green.shade200)
                            : (isDarkMode
                                ? Colors.red.shade700
                                : Colors.red.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          schedulingComplete ? Icons.check_circle : Icons.error,
                          color: schedulingComplete
                              ? (isDarkMode
                                  ? Colors.green.shade400
                                  : Colors.green.shade700)
                              : (isDarkMode
                                  ? Colors.red.shade400
                                  : Colors.red.shade700),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            statusMessage,
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: schedulingComplete
                                  ? (isDarkMode
                                      ? Colors.green.shade300
                                      : Colors.green.shade900)
                                  : (isDarkMode
                                      ? Colors.red.shade300
                                      : Colors.red.shade900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationInfo({
    required IconData icon,
    required Color iconColor,
    required String time,
    required String label,
    required String description,
    required bool isDarkMode,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      time,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.deepOrange.shade300
                            : Colors.deepOrange.shade700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade500
                            : Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.notoSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
