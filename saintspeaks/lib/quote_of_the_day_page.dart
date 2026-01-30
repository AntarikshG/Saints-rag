import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'articlesquotes_en.dart';
import 'articlesquotes_hi.dart';
import 'articlesquotes_bn.dart';
import 'articlesquotes_de.dart';
import 'articlesquotes_kn.dart';
import 'notification_service.dart';
import 'l10n/app_localizations.dart';

class QuoteOfTheDayPage extends StatefulWidget {
  final String? notificationQuote;
  final String? notificationSaint;

  const QuoteOfTheDayPage({
    Key? key,
    this.notificationQuote,
    this.notificationSaint,
  }) : super(key: key);

  @override
  _QuoteOfTheDayPageState createState() => _QuoteOfTheDayPageState();
}

class _QuoteOfTheDayPageState extends State<QuoteOfTheDayPage> {
  String quote = '';
  String saintName = '';
  String saintImage = '';
  bool isLoading = true;
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is ready for locale access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuoteOfTheDay();
    });
  }

  Future<void> _loadQuoteOfTheDay() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Ensure we have a valid context and locale
      if (!mounted) return;

      final locale = Localizations.localeOf(context);

      // Check if we have notification data to display
      Map<String, String> quoteData;
      if (widget.notificationQuote != null && widget.notificationSaint != null) {
        // Use the quote from the notification
        quoteData = {
          'quote': widget.notificationQuote!,
          'saint': widget.notificationSaint!,
        };
        print('📱 Using quote from notification: "${widget.notificationQuote}" by ${widget.notificationSaint}');
      } else {
        // Use the new method to get a fresh random quote each time
        quoteData = NotificationService.getRandomQuoteNow(locale);
        print('🎲 Loading random quote');
      }

      // Ensure we got valid quote data
      if (quoteData['quote'] == null || quoteData['saint'] == null) {
        throw Exception('Invalid quote data received');
      }

      // Get saint image from the quotes data
      final languageCode = locale.languageCode;

      String image = 'assets/images/vivekananda.jpg'; // default

      // Get the appropriate saints list based on language
      List<dynamic> saintsList;
      switch (languageCode) {
        case 'hi':
          saintsList = saintsHi;
          break;
        case 'bn':
          saintsList = saintsBn;
          break;
        case 'de':
          saintsList = saintsDe;
          break;
        case 'kn':
          saintsList = saintsKn;
          break;
        default:
          saintsList = saintsEn;
      }

      // Find the saint image
      for (final saint in saintsList) {
        if (saint.name == quoteData['saint']) {
          image = saint.image;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        quote = quoteData['quote']!;
        saintName = quoteData['saint']!;
        saintImage = image;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading quote of the day: $e');
      // Try again with a fallback approach if the first attempt failed
      try {
        // Use English as fallback locale if there was an issue
        final fallbackQuoteData = NotificationService.getRandomQuoteNow(Locale('en'));

        String image = 'assets/images/vivekananda.jpg';
        for (final saint in saintsEn) {
          if (saint.name == fallbackQuoteData['saint']) {
            image = saint.image;
            break;
          }
        }

        if (!mounted) return;
        setState(() {
          quote = fallbackQuoteData['quote'] ?? 'Stay inspired and blessed!';
          saintName = fallbackQuoteData['saint'] ?? 'Talk with Saints';
          saintImage = image;
          isLoading = false;
        });
      } catch (e2) {
        print('Fallback quote loading also failed: $e2');
        if (!mounted) return;
        setState(() {
          quote = 'Stay inspired and blessed!';
          saintName = 'Talk with Saints';
          saintImage = 'assets/images/vivekananda.jpg';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _shareQuoteScreenshot() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Preparing quote image...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Capture screenshot
      final Uint8List? imageBytes = await screenshotController.capture(
        pixelRatio: 3.0,
      );

      if (imageBytes != null) {
        // Get temporary directory
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/quote_of_the_day_${DateTime.now().millisecondsSinceEpoch}.png';

        // Save image to file
        final File imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);

        // Get share position origin for iOS
        final box = context.findRenderObject() as RenderBox?;
        final sharePositionOrigin = box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null;

        // Share the image with text
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: '"$quote"\n\n- $saintName\n\n✨ Shared from Talk with Saints App',
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        throw Exception('Failed to capture screenshot');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing quote: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyQuoteOfTheDay() async {
    final textToCopy = '"$quote"\n\n— $saintName';

    try {
      await Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Quote copied to clipboard!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy quote'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          loc.quoteOfTheDay,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.grey.shade900.withOpacity(0.95),
                      Colors.grey.shade800.withOpacity(0.95),
                    ]
                  : [
                      Colors.deepOrange.shade100.withOpacity(0.9),
                      Colors.orange.shade50.withOpacity(0.9),
                    ],
            ),
          ),
        ),
        actions: [
          if (!isLoading)
            IconButton(
              icon: Icon(
                Icons.share,
                color: isDark ? Colors.orange.shade300 : Colors.deepOrange.shade700,
              ),
              onPressed: _shareQuoteScreenshot,
              tooltip: 'Share Quote',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: isLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.orange.shade300 : Colors.deepOrange,
                  ),
                )
              : Screenshot(
                  controller: screenshotController,
                  child: Container(
                    padding: EdgeInsets.all(35),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [Colors.grey.shade800, Colors.grey.shade900]
                            : [Colors.white, Colors.orange.shade50],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isDark ? Colors.orange.shade800 : Colors.orange.shade200,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.deepOrange.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        // Saint image
                        if (saintImage.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.orange.shade900.withOpacity(0.5)
                                      : Colors.deepOrange.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundImage: AssetImage(saintImage),
                              radius: 55,
                              backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                            ),
                          ),
                        SizedBox(height: 28),

                        // Quote container
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade700 : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? Colors.orange.shade900 : Colors.orange.shade100,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.1),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.format_quote,
                                color: isDark
                                    ? Colors.orange.shade300
                                    : Colors.deepOrange.shade400,
                                size: 30,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '"$quote"',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 22),

                        // Saint attribution
                        Text(
                          '— $saintName',
                          style: GoogleFonts.notoSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.orange.shade300
                                : Colors.deepOrange.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 25),

                        // Bottom banner image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/quotesbanner.jpg',
                            fit: BoxFit.contain,
                            width: 400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ),
      floatingActionButton: !isLoading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _loadQuoteOfTheDay,
                  backgroundColor: isDark ? Colors.orange.shade700 : Colors.orange.shade600,
                  heroTag: "refresh",
                  child: Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Get New Quote',
                ),
                SizedBox(height: 16),
                FloatingActionButton.extended(
                  onPressed: _copyQuoteOfTheDay,
                  backgroundColor: isDark ? Colors.green.shade700 : Colors.green.shade600,
                  heroTag: "copy",
                  icon: Icon(Icons.copy, color: Colors.white),
                  label: Text(
                    'Copy Quote',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                FloatingActionButton.extended(
                  onPressed: _shareQuoteScreenshot,
                  backgroundColor: isDark ? Colors.deepOrange.shade700 : Colors.deepOrange.shade600,
                  heroTag: "share",
                  icon: Icon(Icons.share, color: Colors.white),
                  label: Text(
                    'Share Quote',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
