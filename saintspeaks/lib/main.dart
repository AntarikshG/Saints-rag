import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'dart:async';
import 'articlesquotes.dart';
import 'articlesquotes_hi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'notification_service.dart';
import 'rotating_banner.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// Book reading imports
import 'books_library.dart';
import 'books_tab.dart';
import 'rating_share_service.dart';
import 'ekadashi_service.dart';
import 'ask_ai_page.dart';
import 'user_profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Track app usage for rating/share service
  await RatingShareService.trackAppUsage();

  // Configure system UI overlay style for edge-to-edge display
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Enable edge-to-edge mode
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  runApp(MyApp());
}

class ArticlePage extends StatelessWidget {
  final String heading;
  final String body;
  ArticlePage({required this.heading, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(heading)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SelectableText(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class SaintImagePlaceholder extends StatelessWidget {
  final String imagePath;
  const SaintImagePlaceholder({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.grey[200],
          child: imagePath.isNotEmpty
              ? (imagePath.startsWith('assets/')
                  ? Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _defaultIcon(),
                    )
                  : Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _defaultIcon(),
                    ))
              : _defaultIcon(),
        ),
      ),
    );
  }

  Widget _defaultIcon() => Center(
        child: Icon(Icons.account_circle, size: 80, color: Colors.grey[400]),
      );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  String _userName = 'Seeker';
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        print('🚀 Initializing app notifications...');
        await NotificationService.initialize(context);

        // Check and auto-reschedule if needed instead of always scheduling
        await NotificationService.checkAndRescheduleIfNeeded(_locale);

        print('✅ App notification setup complete');
      } catch (e) {
        print('❌ Error setting up notifications: $e');
        // Still try to schedule notifications as fallback
        try {
          await NotificationService.scheduleDailyQuoteNotifications(_locale);
        } catch (e2) {
          print('❌ Fallback notification scheduling failed: $e2');
        }
      }
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('locale');
    final userName = prefs.getString('userName');
    setState(() {
      if (langCode != null) _locale = Locale(langCode);
      if (userName != null && userName.isNotEmpty) _userName = userName;
      _prefsLoaded = true;
    });
  }

  Future<void> _saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    _saveLocale(locale);
    // Reschedule notifications with new language
    NotificationService.scheduleDailyQuoteNotifications(locale);
  }

  void _setUserName(String name) {
    setState(() {
      _userName = name;
    });
    _saveUserName(name);
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return MaterialApp(
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.orange.shade50, Colors.deepOrange.shade100],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Loading Saints...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepOrange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Motivational Saints',
      themeMode: _themeMode,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        primaryColor: Colors.deepOrange,
        textTheme: GoogleFonts.notoSansTextTheme().copyWith(
          headlineLarge: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange.shade800,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: Colors.deepOrange.shade700,
          ),
          titleLarge: GoogleFonts.notoSans(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: Colors.deepOrange.withOpacity(0.3),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.deepOrange.shade800,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange.shade800,
          ),
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ).copyWith(
          primary: Colors.deepOrange,
          secondary: Colors.orange,
          surface: Colors.white,
          background: Colors.grey.shade50,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            shadowColor: Colors.deepOrange.withOpacity(0.4),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepOrange,
        textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme).copyWith(
          headlineLarge: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade300,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade400,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: Colors.orange.withOpacity(0.3),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade900,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.orange.shade300,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade300,
          ),
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            shadowColor: Colors.orange.withOpacity(0.4),
          ),
        ),
      ),
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomePage(
        onThemeChange: _changeTheme,
        themeMode: _themeMode,
        userName: _userName,
        onSetUserName: _setUserName,
        onLocaleChange: _changeLocale,
        locale: _locale,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final void Function(ThemeMode) onThemeChange;
  final ThemeMode themeMode;
  final String userName;
  final void Function(String) onSetUserName;
  final void Function(Locale) onLocaleChange;
  final Locale locale;

  HomePage({
    required this.onThemeChange,
    required this.themeMode,
    required this.userName,
    required this.onSetUserName,
    required this.onLocaleChange,
    required this.locale,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Show first-time name dialog after the UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProfileService.showFirstTimeNameDialog(context, widget.onSetUserName);
      // Check and show rating prompt if conditions are met
      RatingShareService.checkAndShowRatingPrompt(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final List<dynamic> saintList = isHindi ? saintsHi : saints;
    // Theme-aware gradients
    final mainGradient = brightness == Brightness.dark
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
              Colors.black,
            ],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.shade50,
              Colors.orange.shade50,
              Colors.white,
            ],
          );
    final drawerGradient = brightness == Brightness.dark
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade900, Colors.grey.shade800],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepOrange.shade50, Colors.white],
          );
    final appBarGradient = brightness == Brightness.dark
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
          );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          loc.inspiringSaints,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: appBarGradient,
          ),
        ),
      ),
      drawer: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: drawerGradient,
            ),
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.only(bottom: 24), // Add bottom padding for system nav bar
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: appBarGradient,
                    ),
                    child: DrawerHeader(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/antarikshverse.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.self_improvement,
                                      size: 35,
                                      color: Colors.deepOrange,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            loc.menu,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildDrawerItem(context, Icons.contact_page, loc.contact, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ContactPage()));
                  }),
                  _buildDrawerItem(context, Icons.color_lens, loc.selectTheme, () {
                    Navigator.pop(context);
                    _showThemeDialog(context);
                  }),
                  _buildDrawerItem(context, Icons.language, loc.language, () {
                    Navigator.pop(context);
                    _showLanguageDialog(context);
                  }),
                  _buildDrawerItem(context, Icons.person, loc.setName, () {
                    Navigator.pop(context);
                    _showNameDialog(context);
                  }),
                  _buildDrawerItem(context, Icons.note, loc.spiritualDiary, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SpiritualDiaryPage()));
                  }),
                  _buildDrawerItem(context, Icons.bookmark, loc.bookmarkedQuotes, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BookmarkedQuotesPage()));
                  }),
                  _buildDrawerItem(context, Icons.brightness_2, loc.nextEkadashi, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EkadashiPage()));
                  }),
                  _buildDrawerItem(context, Icons.library_books, loc.myBooksLibrary, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BooksLibraryPage()));
                  }),
                  _buildDrawerItem(context, Icons.info, loc.aboutApp, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AboutAppPage()));
                  }),
                  _buildDrawerItem(context, Icons.star, loc.rateAndShareApp, () {
                    Navigator.pop(context);
                    RatingShareService.showRatingShareDialog(context);
                  }),
                  _buildDrawerItem(context, Icons.notifications_active, loc.setDailyNotifications, () async {
                    Navigator.pop(context);

                    // Show current notification configuration
                    final configInfo = NotificationService.getNotificationConfigInfo();
                    await NotificationService.showTestNotification();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('✅ Test notification sent!'),
                            SizedBox(height: 4),
                            Text(configInfo, style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }),
                  _buildDrawerItem(context, Icons.coffee, loc.buyMeACoffee, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BuyMeACoffeePage()));
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false, // Allow content behind AppBar since extendBodyBehindAppBar is true
        child: Container(
          decoration: BoxDecoration(
            gradient: mainGradient,
          ),
          child: Column(
            children: [
              SizedBox(height: 100), // Space for AppBar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: RotatingBanner(
                    imagePaths: [
                      'assets/images/banner.jpeg',
                      'assets/images/banner1.jpeg',
                      'assets/images/banner2.jpeg',
                      'assets/images/banner3.jpeg',
                      'assets/images/banner4.jpeg',
                      'assets/images/banner5.jpeg',
                      'assets/images/banner6.jpeg',
                      'assets/images/banner7.jpeg',
                      'assets/images/banner8.jpeg',
                      'assets/images/banner9.jpeg',
                      'assets/images/banner10.jpg',
                      'assets/images/banner11.jpg',
                      'assets/images/Antariksh.jpg',
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Quote of the Day Card - Made smaller
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: brightness == Brightness.dark
                      ? LinearGradient(colors: [Colors.grey.shade900, Colors.grey.shade800])
                      : LinearGradient(colors: [Colors.white, Colors.orange.shade50]),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.15),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QuoteOfTheDayPage()),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade50,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.format_quote,
                              color: Colors.deepOrange.shade700,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.quoteOfTheDay,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: brightness == Brightness.dark
                                        ? Colors.orange.shade300
                                        : Colors.deepOrange.shade800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Daily wisdom',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: brightness == Brightness.dark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.deepOrange.shade700,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Ask AI Button - New addition
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: brightness == Brightness.dark
                      ? LinearGradient(colors: [Colors.purple.shade900, Colors.purple.shade800])
                      : LinearGradient(colors: [Colors.white, Colors.purple.shade50]),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.15),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AskAIPage(userName: widget.userName)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.psychology,
                              color: Colors.purple.shade700,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.talkToSpiritualAIFriend,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: brightness == Brightness.dark
                                        ? Colors.purple.shade300
                                        : Colors.purple.shade800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Get wisdom from all saints',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: brightness == Brightness.dark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.purple.shade700,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppLocalizations.of(context)!.chooseSpiritualGuide,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.deepOrange.shade800,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0, // Changed from 0.85 to 1.0 to make boxes smaller
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: saintList.length,
                  itemBuilder: (context, i) => Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(20),
                    shadowColor: Colors.deepOrange.withOpacity(0.25),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.deepOrange.shade50,
                          ],
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SaintPage(
                              saint: saintList[i],
                              userName: widget.userName,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10), // Reduced from 12 to 10
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Hero(
                                tag: 'saint_${saintList[i].id}',
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepOrange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 30, // Reduced from 35 to 30
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 27, // Reduced from 32 to 27
                                      backgroundImage: saintList[i].image.startsWith('assets/')
                                          ? AssetImage(saintList[i].image) as ImageProvider
                                          : NetworkImage(saintList[i].image),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8), // Reduced from 12 to 8
                              Text(
                                saintList[i].name,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 14, // Reduced from 16 to 14
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange.shade800,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepOrange.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.deepOrange.shade700, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey.shade800,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.chooseTheme,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(loc.system, ThemeMode.system, context),
            _buildThemeOption(loc.light, ThemeMode.light, context),
            _buildThemeOption(loc.dark, ThemeMode.dark, context),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String title, ThemeMode mode, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.themeMode == mode ? Colors.deepOrange.shade50 : null,
      ),
      child: RadioListTile(
        title: Text(title),
        value: mode,
        groupValue: widget.themeMode,
        activeColor: Colors.deepOrange,
        onChanged: (val) {
          widget.onThemeChange(mode);
          Navigator.pop(context);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.language,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(loc.english, Locale('en'), context),
            _buildLanguageOption(loc.hindi, Locale('hi'), context),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String title, Locale localeOption, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.locale == localeOption ? Colors.deepOrange.shade50 : null,
      ),
      child: RadioListTile<Locale>(
        title: Text(title),
        value: localeOption,
        groupValue: widget.locale,
        activeColor: Colors.deepOrange,
        onChanged: (val) {
          widget.onLocaleChange(localeOption);
          Navigator.pop(context);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showNameDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: widget.userName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.enterYourName,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: loc.name,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.deepOrange, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onSetUserName(controller.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }
}

class SaintPage extends StatefulWidget {
  final dynamic saint; // Accept both Saint and SaintHi
  final String userName;
  SaintPage({required this.saint, required this.userName});
  @override
  _SaintPageState createState() => _SaintPageState();
}

// New page to display single quote with navigation
class SingleQuoteViewPage extends StatefulWidget {
  final List<String> quotes;
  final int initialIndex;
  final String saintName;
  final String saintId;
  final String image;

  SingleQuoteViewPage({
    required this.quotes,
    required this.initialIndex,
    required this.saintName,
    required this.saintId,
    required this.image,
  });

  @override
  _SingleQuoteViewPageState createState() => _SingleQuoteViewPageState();
}

class _SingleQuoteViewPageState extends State<SingleQuoteViewPage> {
  late PageController _pageController;
  late int _currentIndex;
  Set<String> _readQuotes = {};
  Set<String> _bookmarkedQuotes = {};
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadReadQuotes();
    _loadBookmarkedQuotes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadReadQuotes() async {
    final read = await ReadStatusService.getReadQuotes();
    setState(() {
      _readQuotes = read;
    });
  }

  Future<void> _loadBookmarkedQuotes() async {
    final bookmarked = await ReadStatusService.getBookmarkedQuotes();
    setState(() {
      _bookmarkedQuotes = bookmarked;
    });
  }

  String _quoteId(String quote) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    String saintNameForId;

    if (isHindi) {
      final hindiSaint = saintsHi.firstWhere((s) => s.id == widget.saintId, orElse: () => saintsHi[0]);
      saintNameForId = hindiSaint.name;
    } else {
      saintNameForId = widget.saintName;
    }

    return '$saintNameForId|||$quote';
  }

  Future<void> _toggleBookmark(String quote) async {
    final id = _quoteId(quote);
    final isBookmarked = _bookmarkedQuotes.contains(id);

    if (isBookmarked) {
      await ReadStatusService.removeBookmark(id);
      setState(() {
        _bookmarkedQuotes.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote removed from bookmarks'), duration: Duration(seconds: 1)),
      );
    } else {
      await ReadStatusService.bookmarkQuote(id);
      setState(() {
        _bookmarkedQuotes.add(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote bookmarked!'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _shareQuote(String quote) async {
    try {
      final image = await _screenshotController.captureFromWidget(
        MediaQuery(
          data: MediaQueryData(),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 650,
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.deepOrange.shade50, Colors.orange.shade50],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade200, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App branding header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/apppic.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Talk with Saints',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),

                  // Saint image
                  if (widget.image.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundImage: AssetImage(widget.image),
                        radius: 55,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  SizedBox(height: 28),

                  // Quote container
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.orange.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: Colors.deepOrange.shade400,
                          size: 30,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '"$quote"',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22),

                  // Saint attribution
                  Text(
                    '— ${widget.saintName}',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 25),

                  // Bottom app promotion
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepOrange.shade50, Colors.orange.shade50],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.deepOrange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download,
                          size: 16,
                          color: Colors.deepOrange.shade700,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Talk with Saints App on Android',
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: Colors.deepOrange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      // Get share position origin for iOS
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: '"$quote"\n\n— ${widget.saintName}\n\n✨ Shared from Talk with Saints App\nDownload now for daily spiritual wisdom!',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share quote')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.saintName}'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_currentIndex + 1} / ${widget.quotes.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: brightness == Brightness.dark
                      ? Colors.orange.shade300
                      : Colors.deepOrange.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: brightness == Brightness.dark
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.deepOrange.shade50, Colors.white],
          ),
        ),
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) async {
            setState(() {
              _currentIndex = index;
            });
            // Mark quote as read when viewed
            final quote = widget.quotes[index];
            final id = _quoteId(quote);
            await ReadStatusService.markQuoteRead(id);
            setState(() {
              _readQuotes.add(id);
            });
          },
          itemCount: widget.quotes.length,
          itemBuilder: (context, index) {
            final quote = widget.quotes[index];
            final id = _quoteId(quote);
            final isBookmarked = _bookmarkedQuotes.contains(id);

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    // Saint Image
                    Hero(
                      tag: 'saint_quote_${widget.saintId}',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 56,
                            backgroundImage: widget.image.startsWith('assets/')
                                ? AssetImage(widget.image) as ImageProvider
                                : NetworkImage(widget.image),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    // Quote Card
                    Container(
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.2),
                            blurRadius: 30,
                            offset: Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: 40,
                            color: Colors.deepOrange.shade400,
                          ),
                          SizedBox(height: 20),
                          Text(
                            quote,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              height: 1.6,
                              color: brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.deepOrange.shade900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 30),
                          Text(
                            '- ${widget.saintName}',
                            style: GoogleFonts.notoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: brightness == Brightness.dark
                                  ? Colors.orange.shade300
                                  : Colors.deepOrange.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          label: isBookmarked ? 'Bookmarked' : 'Bookmark',
                          onPressed: () => _toggleBookmark(quote),
                          color: isBookmarked ? Colors.orange : Colors.grey,
                        ),
                        SizedBox(width: 20),
                        _buildActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          onPressed: () => _shareQuote(quote),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    // Navigation Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, size: 28),
                          color: _currentIndex > 0
                              ? Colors.deepOrange
                              : Colors.grey.shade400,
                          onPressed: _currentIndex > 0
                              ? () => _pageController.previousPage(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                        SizedBox(width: 20),
                        Text(
                          'Swipe to navigate',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(width: 20),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios, size: 28),
                          color: _currentIndex < widget.quotes.length - 1
                              ? Colors.deepOrange
                              : Colors.grey.shade400,
                          onPressed: _currentIndex < widget.quotes.length - 1
                              ? () => _pageController.nextPage(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
      ),
    );
  }
}

class _SaintPageState extends State<SaintPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Database db;
  List<Map<String, dynamic>> history = [];
  bool _useHindi = false;

  // Helper function to get English saint name based on saint ID
  String getEnglishSaintName(String saintId) {
    // Handle the special "ALL" case
    if (saintId == "ALL") {
      return "All";
    }

    final englishSaint = saints.firstWhere(
      (saint) => saint.id == saintId,
      orElse: () => saints[0], // fallback to first saint if not found
    );
    return englishSaint.name;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    setState(() {
      _useHindi = locale.languageCode == 'hi';
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Changed from 4 to 5 for Books tab
    _initDb();
  }

  Future<void> _initDb() async {
    db = await openDatabase(
      p.join(await getDatabasesPath(), 'qna.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE qna(id INTEGER PRIMARY KEY, saint TEXT, question TEXT, answer TEXT)',
        );
      },
      version: 1,
    );
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'qna',
      where: 'saint = ?',
      whereArgs: [widget.saint.name],
      orderBy: 'id DESC',
    );
    setState(() {
      history = maps;
    });
  }

  Future<void> _addQnA(String question, String answer) async {
    await db.insert('qna', {
      'saint': widget.saint.name,
      'question': question,
      'answer': answer,
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final saintId = widget.saint.id;
    final saintName = widget.saint.name;
    final saintImage = widget.saint.image;
    final saintQuotes = widget.saint.quotes;
    final saintArticles = widget.saint.articles;
    return Scaffold(
      appBar: AppBar(
        title: Text(saintName),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.quotes),
            Tab(text: loc.articles),
            Tab(text: loc.ask),
            Tab(text: loc.history),
            Tab(text: 'Books'), // New Books tab
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          QuotesTab(
            quotes: saintQuotes,
            image: saintImage,
            saintName: saintName,
            saintId: saintId, // Pass saint ID to QuotesTab
          ),
          ArticlesTab(
            articles: isHindi
                ? (saintArticles as List).map<Article>((a) => Article(heading: a.heading, body: a.body)).toList()
                : saintArticles as List<Article>,
          ),
          AskTab(
            onSubmit: (q, a) => _addQnA(q, a),
            saintId: saintId, // Pass saint ID instead of saint name
            userName: widget.userName,
          ),
          HistoryTab(history: history),
          BooksTab(saintId: saintId, saintName: saintName), // Pass both saint ID and name to BooksTab
        ],
      ),
    );
  }
}

class QuotesTab extends StatefulWidget {
  final List<String> quotes;
  final String image;
  final String saintName;
  final String saintId; // Add saint ID to find the correct Hindi name
  QuotesTab({required this.quotes, required this.image, required this.saintName, required this.saintId});
  @override
  _QuotesTabState createState() => _QuotesTabState();
}

class _QuotesTabState extends State<QuotesTab> {
  Set<String> _readQuotes = {};
  Set<String> _bookmarkedQuotes = {};

  @override
  void initState() {
    super.initState();
    _loadReadQuotes();
    _loadBookmarkedQuotes();
  }

  Future<void> _loadReadQuotes() async {
    final read = await ReadStatusService.getReadQuotes();
    setState(() {
      _readQuotes = read;
    });
  }

  Future<void> _loadBookmarkedQuotes() async {
    final bookmarked = await ReadStatusService.getBookmarkedQuotes();
    setState(() {
      _bookmarkedQuotes = bookmarked;
    });
  }

  String _quoteId(String quote) {
    // Use the correct saint name based on current language
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    String saintNameForId;

    if (isHindi) {
      // Find the Hindi saint name using the saint ID
      final hindiSaint = saintsHi.firstWhere((s) => s.id == widget.saintId, orElse: () => saintsHi[0]);
      saintNameForId = hindiSaint.name;
    } else {
      saintNameForId = widget.saintName;
    }

    return '$saintNameForId|||$quote';
  }

  Future<void> _toggleBookmark(String quote) async {
    final id = _quoteId(quote);
    final isBookmarked = _bookmarkedQuotes.contains(id);

    if (isBookmarked) {
      await ReadStatusService.removeBookmark(id);
      setState(() {
        _bookmarkedQuotes.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote removed from bookmarks')),
      );
    } else {
      await ReadStatusService.bookmarkQuote(id);
      setState(() {
        _bookmarkedQuotes.add(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote bookmarked!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quoteTextStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontStyle: FontStyle.italic,
      fontSize: 18,
      height: 1.4,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepOrange.shade50,
            Colors.white,
          ],
        ),
      ),
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 100, // Use MediaQuery for system padding + extra space
        ),
        itemCount: widget.quotes.length + 1,
        separatorBuilder: (context, index) => SizedBox(height: 16),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Container(
              margin: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: SaintImagePlaceholder(imagePath: widget.image),
              ),
            );
          }
          final quote = widget.quotes[i - 1];
          final id = _quoteId(quote);
          final isRead = _readQuotes.contains(id);
          final isBookmarked = _bookmarkedQuotes.contains(id);

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              elevation: isRead ? 4 : 8,
              borderRadius: BorderRadius.circular(20),
              shadowColor: isRead
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.deepOrange.withOpacity(0.4),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isRead
                        ? [Colors.white, Colors.grey.shade50]
                        : [Colors.white, Colors.orange.shade50],
                  ),
                  border: isRead
                      ? null
                      : Border.all(color: Colors.deepOrange.shade100, width: 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    // Navigate to single quote view page
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SingleQuoteViewPage(
                          quotes: widget.quotes,
                          initialIndex: i - 1,
                          saintName: widget.saintName,
                          saintId: widget.saintId,
                          image: widget.image,
                        ),
                      ),
                    );
                    // Reload read status after returning from single quote view
                    _loadReadQuotes();
                    _loadBookmarkedQuotes();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(12), // Reduced from 16 to 12
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isRead)
                              Container(
                                margin: EdgeInsets.only(top: 4, right: 12),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                '"$quote"',
                                style: quoteTextStyle?.copyWith(
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                                  color: isRead
                                      ? Colors.grey.shade700
                                      : Colors.deepOrange.shade800,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: isBookmarked
                                    ? Colors.orange.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                  color: isBookmarked ? Colors.orange.shade700 : Colors.grey.shade600,
                                  size: 22,
                                ),
                                onPressed: () => _toggleBookmark(quote),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          );
        },
      ),
    );
  }
}

class ArticlesTab extends StatefulWidget {
  final List<Article> articles;
  ArticlesTab({required this.articles});

  @override
  _ArticlesTabState createState() => _ArticlesTabState();
}

class _ArticlesTabState extends State<ArticlesTab> {
  Set<String> _readArticles = {};

  @override
  void initState() {
    super.initState();
    _loadReadArticles();
  }

  Future<void> _loadReadArticles() async {
    final read = await ReadStatusService.getReadArticles();
    setState(() {
      _readArticles = read;
    });
  }

  String _articleId(Article a) {
    // Use heading + saint as unique ID (adjust if you have a better unique key)
    return a.heading;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 100, // Use MediaQuery for system padding + extra space
      ),
      itemCount: widget.articles.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, i) {
        final a = widget.articles[i];
        final id = _articleId(a);
        final isRead = _readArticles.contains(id);
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: isRead ? null : Icon(Icons.fiber_manual_record, color: Colors.blue, size: 14),
            title: Text(
              a.heading,
              style: TextStyle(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                a.body,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Icon(Icons.article, color: Colors.blueGrey[300]),
            onTap: () async {
              await ReadStatusService.markArticleRead(id);
              setState(() {
                _readArticles.add(id);
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticlePage(heading: a.heading, body: a.body),
                ),
              );
            },
          ),
        );
      },
    );
  }
}


class SpiritualDiaryPage extends StatefulWidget {
  @override
  _SpiritualDiaryPageState createState() => _SpiritualDiaryPageState();
}

class _SpiritualDiaryPageState extends State<SpiritualDiaryPage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;
  Database? _db;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _initDbAndLoadEntries();
  }

  Future<void> _initDbAndLoadEntries() async {
    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'spiritual_diary.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS diary_entries(id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT, created_at TEXT, title TEXT)'
        );
      },
      version: 1,
    );
    _db = db;
    await _loadEntries();
    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadEntries() async {
    if (_db == null) return;
    final List<Map<String, dynamic>> entries = await _db!.query(
      'diary_entries',
      orderBy: 'created_at DESC',
    );
    setState(() {
      _entries = entries;
    });
  }

  Future<void> _saveEntry() async {
    if (_db == null || _controller.text.trim().isEmpty) return;

    final now = DateTime.now();
    final title = _controller.text.trim().length > 50
        ? _controller.text.trim().substring(0, 50) + '...'
        : _controller.text.trim();

    await _db!.insert('diary_entries', {
      'content': _controller.text.trim(),
      'created_at': now.toIso8601String(),
      'title': title,
    });

    _controller.clear();
    await _loadEntries();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entry saved successfully!')),
    );
  }

  Future<void> _exportDiary() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No entries to export')),
      );
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/spiritual_diary_export.txt');

      String exportContent = 'Spiritual Diary Export\n';
      exportContent += '=' * 30 + '\n\n';

      for (var entry in _entries.reversed) {
        final date = DateTime.parse(entry['created_at']);
        exportContent += 'Date: ${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}\n';
        exportContent += '-' * 40 + '\n';
        exportContent += '${entry['content']}\n\n';
        exportContent += '=' * 40 + '\n\n';
      }

      await file.writeAsString(exportContent);

      // Get share position origin for iOS
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Spiritual Diary Export',
        subject: 'Spiritual Diary',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting diary: $e')),
      );
    }
  }

  Future<void> _deleteEntry(int id) async {
    if (_db == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Entry'),
        content: Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db!.delete('diary_entries', where: 'id = ?', whereArgs: [id]);
      await _loadEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entry deleted')),
      );
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (entryDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.spiritualDiary),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: Icon(Icons.share),
              onPressed: _exportDiary,
              tooltip: 'Export Diary',
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // New entry section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Write a new entry',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _controller,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Share your thoughts, reflections, and spiritual insights...',
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _saveEntry,
                        icon: Icon(Icons.add),
                        label: Text('Add Entry'),
                      ),
                    ],
                  ),
                ),
                // Entries list
                Expanded(
                  child: _entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.book,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No entries yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start writing your spiritual journey',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDate(entry['created_at']),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, size: 20),
                                          onPressed: () => _deleteEntry(entry['id']),
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      entry['content'],
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class AboutAppPage extends StatefulWidget {
  @override
  _AboutAppPageState createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  late YoutubePlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Don't initialize controller here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the current locale to determine which video to show
    final locale = Localizations.localeOf(context);
    final isHindi = locale.languageCode == 'hi';
    final expectedVideoId = isHindi ? '-xgEbJzLs5k' : '7OXjZOvLW0Y';

    // Initialize controller only once
    if (!_isInitialized) {
      _controller = YoutubePlayerController(
        initialVideoId: expectedVideoId,
        flags: YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
        ),
      );
      _isInitialized = true;
    } else {
      // If language changes after initialization, load the new video
      if (_controller.metadata.videoId != expectedVideoId) {
        _controller.load(expectedVideoId);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Show loading indicator until controller is initialized
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.aboutApp)),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.deepOrange,
        progressColors: ProgressBarColors(
          playedColor: Colors.deepOrange,
          handleColor: Colors.deepOrangeAccent,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text(loc.aboutApp)),
          body: SafeArea(
            // Ensures content isn't hidden behind system UI (bottom nav / home indicator)
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/apppic.png',
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      loc.aboutApp,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Text(
                      loc.aboutAppInstructions,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 30),
                    // YouTube Video Player
                    Text(
                      loc.watchOurVideo,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: player,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BookmarkedQuotesPage extends StatefulWidget {
  @override
  _BookmarkedQuotesPageState createState() => _BookmarkedQuotesPageState();
}

class _BookmarkedQuotesPageState extends State<BookmarkedQuotesPage> {
  Set<String> _bookmarkedQuotes = {};
  List<Map<String, String>> _allQuotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarkedQuotes();
  }

  Future<void> _loadBookmarkedQuotes() async {
    final bookmarked = await ReadStatusService.getBookmarkedQuotes();
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    // Get all quotes from all saints
    final allQuotes = <Map<String, String>>[];

    if (isHindi) {
      for (final saint in saintsHi) {
        for (final quote in saint.quotes) {
          final quoteId = '${saint.name}|||$quote';
          if (bookmarked.contains(quoteId)) {
            allQuotes.add({
              'quote': quote,
              'saint': saint.name,
              'image': saint.image,
              'id': quoteId,
            });
          }
        }
      }
    } else {
      for (final saint in saints) {
        for (final quote in saint.quotes) {
          final quoteId = '${saint.name}|||$quote';
          if (bookmarked.contains(quoteId)) {
            allQuotes.add({
              'quote': quote,
              'saint': saint.name,
              'image': saint.image,
              'id': quoteId,
            });
          }
        }
      }
    }

    setState(() {
      _bookmarkedQuotes = bookmarked;
      _allQuotes = allQuotes;
      _loading = false;
    });
  }

  Future<void> _removeBookmark(String quoteId) async {
    await ReadStatusService.removeBookmark(quoteId);
    setState(() {
      _bookmarkedQuotes.remove(quoteId);
      _allQuotes.removeWhere((quote) => quote['id'] == quoteId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quote removed from bookmarks')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Bookmarked Quotes',
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
              colors: [
                Colors.orange.shade100.withOpacity(0.9),
                Colors.deepOrange.shade50.withOpacity(0.9),
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
            colors: [
              Colors.orange.shade50,
              Colors.white,
            ],
          ),
        ),
        child: _loading
          ? Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                  strokeWidth: 3,
                ),
              ),
            )
          : _allQuotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bookmark_border,
                          size: 60,
                          color: Colors.orange.shade300,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No bookmarked quotes yet',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Start bookmarking your favorite quotes!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    SizedBox(height: 100), // Space for AppBar
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.all(16),
                        itemCount: _allQuotes.length,
                        separatorBuilder: (context, index) => SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final quote = _allQuotes[index];
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(20),
                              shadowColor: Colors.orange.withOpacity(0.3),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white, Colors.orange.shade50],
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 25,
                                              backgroundColor: Colors.white,
                                              child: CircleAvatar(
                                                radius: 22,
                                                backgroundImage: quote['image']!.startsWith('assets/')
                                                    ? AssetImage(quote['image']!) as ImageProvider
                                                    : NetworkImage(quote['image']!),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              quote['saint']!,
                                              style: GoogleFonts.playfairDisplay(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.orange.shade800,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.bookmark,
                                                color: Colors.orange.shade700,
                                                size: 22,
                                              ),
                                              onPressed: () => _removeBookmark(quote['id']!),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.orange.shade100),
                                        ),
                                        child: Text(
                                          '"${quote['quote']!}"',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                            height: 1.5,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),);
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.contact,
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
              colors: [
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
            colors: [
              Colors.deepOrange.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 120), // Space for AppBar
                  Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/antarikshverse.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 24),
                        RichText(
                          textAlign: TextAlign.center,
                          text: _buildContactTextWithClickableEmail(
                            loc.contactUs,
                            context,
                          ),
                        ),
                        SizedBox(height: 32),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            'assets/images/Antariksh.jpg',
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 50), // Add bottom padding to ensure content is fully visible
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _buildContactTextWithClickableEmail(String text, BuildContext context) {
    // Extract the email from the text
    final emailRegex = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+');
    final emailMatch = emailRegex.firstMatch(text);

    if (emailMatch == null) {
      // No email found, return plain text
      return TextSpan(
        text: text,
        style: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: Colors.grey.shade800,
        ),
      );
    }

    final email = emailMatch.group(0)!;
    final emailStart = emailMatch.start;
    final emailEnd = emailMatch.end;

    // Split text into parts: before email, email, after email
    final beforeEmail = text.substring(0, emailStart);
    final afterEmail = text.substring(emailEnd);

    return TextSpan(
      style: GoogleFonts.notoSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: Colors.grey.shade800,
      ),
      children: [
        TextSpan(text: beforeEmail),
        TextSpan(
          text: email,
          style: TextStyle(
            color: Colors.deepOrange.shade700,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final emailUri = Uri.parse('mailto:$email');
              try {
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.email, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Opening email app...'),
                        ],
                      ),
                      backgroundColor: Colors.deepOrange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  throw Exception('Could not launch email');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open email app. Email: $email'),
                    backgroundColor: Colors.red.shade400,
                    action: SnackBarAction(
                      label: 'Copy',
                      textColor: Colors.white,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: email));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Email copied to clipboard!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            },
        ),
        TextSpan(text: afterEmail),
      ],
    );
  }
}

class BuyMeACoffeePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          isHindi ? 'मुझे कॉफी खरीदें' : 'Buy me a coffee',
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
              colors: [
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
            colors: [
              Colors.deepOrange.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.coffee,
                        size: 60,
                        color: Colors.deepOrange.shade700,
                      ),
                      SizedBox(height: 24),
                      RichText(
                        text: TextSpan(
                          text: isHindi ? '☕ मुझे कॉफी खरीदें' : '☕ Buy me a coffee',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.deepOrange.shade700,
                            decoration: TextDecoration.underline,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final url = Uri.parse('https://www.buymeacoffee.com/AntarikshVerse');
                              try {
                                print('Attempting to launch URL: $url');

                                // First try with external application mode
                                bool launched = false;

                                try {
                                  if (await canLaunchUrl(url)) {
                                    launched = await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication
                                    );
                                    print('External app launch result: $launched');
                                  }
                                } catch (e) {
                                  print('External app launch failed: $e');
                                }

                                // If external app failed, try platform default
                                if (!launched) {
                                  try {
                                    launched = await launchUrl(
                                      url,
                                      mode: LaunchMode.platformDefault
                                    );
                                    print('Platform default launch result: $launched');
                                  } catch (e) {
                                    print('Platform default launch failed: $e');
                                  }
                                }

                                // If still failed, try in-app web view
                                if (!launched) {
                                  try {
                                    launched = await launchUrl(
                                      url,
                                      mode: LaunchMode.inAppWebView
                                    );
                                    print('In-app webview launch result: $launched');
                                  } catch (e) {
                                    print('In-app webview launch failed: $e');
                                  }
                                }

                                if (!launched) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isHindi
                                        ? 'लिंक खोलने में असमर्थ। कृपया मैन्युअल रूप से buymeacoffee.com/AntarikshVerse पर जाएं।'
                                        : 'Unable to open link. Please visit buymeacoffee.com/AntarikshVerse manually.'
                                      ),
                                      duration: Duration(seconds: 5),
                                      action: SnackBarAction(
                                        label: 'Copy URL',
                                        onPressed: () {
                                          // Copy to clipboard
                                          Clipboard.setData(ClipboardData(text: 'https://www.buymeacoffee.com/AntarikshVerse'));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('URL copied to clipboard!'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                } else {
                                  print('URL launched successfully');
                                }
                              } catch (e) {
                                print('General URL launch error: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text((isHindi
                                      ? 'ब्राउज़र खोलने में विफल: '
                                      : 'Failed to open browser: ') + e.toString()
                                    ),
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                              }
                            },
                        ),
                      ),
                      SizedBox(height: 32),
                      Text(
                        isHindi ? loc.supportTextHi : loc.supportTextEn,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuoteOfTheDayPage extends StatefulWidget {
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
      // Use the new method to get a fresh random quote each time
      final quoteData = NotificationService.getRandomQuoteNow(locale);

      // Ensure we got valid quote data
      if (quoteData['quote'] == null || quoteData['saint'] == null) {
        throw Exception('Invalid quote data received');
      }

      // Get saint image from the quotes data
      final isHindi = locale.languageCode == 'hi';

      String image = 'assets/images/vivekananda.jpg'; // default

      if (isHindi) {
        // Cast to proper type for Hindi saints
        for (final saint in saintsHi) {
          if (saint.name == quoteData['saint']) {
            image = saint.image;
            break;
          }
        }
      } else {
        // Cast to proper type for English saints
        for (final saint in saints) {
          if (saint.name == quoteData['saint']) {
            image = saint.image;
            break;
          }
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
        for (final saint in saints) {
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
              colors: [
                Colors.deepOrange.shade100.withOpacity(0.9),
                Colors.orange.shade50.withOpacity(0.9),
              ],
            ),
          ),
        ),
        actions: [
          if (!isLoading)
            IconButton(
              icon: Icon(Icons.share, color: Colors.deepOrange.shade700),
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
            colors: [
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                )
              : Screenshot(
                  controller: screenshotController,
                  child: Container(
                    padding: EdgeInsets.all(35),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.orange.shade50],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.orange.shade200, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App branding header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepOrange.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/apppic.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Talk with Saints',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),

                        // Saint image
                        if (saintImage.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundImage: AssetImage(saintImage),
                              radius: 55,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        SizedBox(height: 28),

                        // Quote container
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.orange.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.format_quote,
                                color: Colors.deepOrange.shade400,
                                size: 30,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '"$quote"',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                  color: Colors.grey.shade800,
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
                            color: Colors.deepOrange.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 25),

                        // Bottom app promotion
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepOrange.shade50, Colors.orange.shade50],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.deepOrange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.download,
                                size: 16,
                                color: Colors.deepOrange.shade700,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Talk with Saints App on Android',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 13,
                                    color: Colors.deepOrange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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
                  backgroundColor: Colors.orange.shade600,
                  heroTag: "refresh",
                  child: Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Get New Quote',
                ),
                SizedBox(height: 16),
                FloatingActionButton.extended(
                  onPressed: _shareQuoteScreenshot,
                  backgroundColor: Colors.deepOrange.shade600,
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

class AskAIPage extends StatefulWidget {
  final String userName;

  const AskAIPage({required this.userName, Key? key}) : super(key: key);

  @override
  _AskAIPageState createState() => _AskAIPageState();
}

class _AskAIPageState extends State<AskAIPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('ask_all_history') ?? [];
    setState(() {
      _history = historyJson.map((item) => Map<String, String>.from(jsonDecode(item))).toList();
    });
  }

  Future<void> _saveToHistory(String question, String answer) async {
    final prefs = await SharedPreferences.getInstance();
    final newEntry = {'question': question, 'answer': answer, 'timestamp': DateTime.now().toIso8601String()};
    _history.insert(0, newEntry);
    if (_history.length > 50) _history = _history.take(50).toList();

    final historyJson = _history.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('ask_all_history', historyJson);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;

    final gradient = brightness == Brightness.dark
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade900, Colors.grey.shade800, Colors.black],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepOrange.shade50, Colors.orange.shade50, Colors.white],
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.talkToSpiritualAIFriend,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: brightness == Brightness.dark
                ? LinearGradient(colors: [Colors.grey.shade900, Colors.grey.shade800])
                : LinearGradient(colors: [Colors.deepOrange.shade100.withOpacity(0.9), Colors.orange.shade50.withOpacity(0.9)]),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.ask),
            Tab(text: loc.history),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: TabBarView(
          controller: _tabController,
          children: [
            AskTab(
              saintId: "ALL",
              userName: widget.userName,
              onSubmit: _saveToHistory,
            ),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final loc = AppLocalizations.of(context)!;
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(loc.noPreviousQuestions, style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final date = DateTime.parse(item['timestamp']!);
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['question']!,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  item['answer']!,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

