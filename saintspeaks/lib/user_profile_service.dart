import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';

class UserProfileService {
  static const String _userNameKey = 'userName';
  static const String _hasPromptedForNameKey = 'hasPromptedForName';

  /// Check if user has set their name
  static Future<bool> hasUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString(_userNameKey);
    return userName != null && userName.isNotEmpty && userName != 'Seeker';
  }

  /// Check if we've already prompted the user for their name
  static Future<bool> hasPromptedForName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasPromptedForNameKey) ?? false;
  }

  /// Mark that we've prompted the user for their name
  static Future<void> markAsPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasPromptedForNameKey, true);
  }

  /// Get the user's name
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? 'Seeker';
  }

  /// Save the user's name
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  /// Show first-time name dialog
  static Future<void> showFirstTimeNameDialog(
    BuildContext context,
    Function(String) onSetUserName,
  ) async {
    // Check if user already has a name or if we've already prompted
    final hasName = await hasUserName();
    final hasPrompted = await hasPromptedForName();

    if (hasName || hasPrompted) {
      return; // Don't show the dialog
    }

    // Mark as prompted so we don't show again
    await markAsPrompted();

    // Wait a bit for the UI to settle
    await Future.delayed(Duration(milliseconds: 500));

    if (!context.mounted) return;

    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false, // User must interact with dialog
      builder: (_) => PopScope(
        canPop: false, // Prevent back button dismiss
        child: AlertDialog(
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? Colors.deepOrange.shade900.withOpacity(0.3) : Colors.deepOrange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add,
                  size: 40,
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(height: 16),
              Text(
                loc.enterYourName,
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Help the spiritual saints personalize their wisdom just for you',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: loc.name,
                  labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  hintText: 'Enter your name',
                  hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  prefixIcon: Icon(Icons.person, color: Colors.deepOrange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // User skips - keep default "Seeker"
                Navigator.pop(context);
              },
              child: Text(
                'Skip for now',
                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  onSetUserName(name);
                  Navigator.pop(context);

                  // Show a welcoming snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🙏 Welcome, $name! The saints are ready to guide you.'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                loc.save,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
