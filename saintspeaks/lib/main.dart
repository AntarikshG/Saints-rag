import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'articlesquotes.dart';
import 'articlesquotes_hi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';
import 'notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class MainBannerImage extends StatelessWidget {
  final String imagePath;
  const MainBannerImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.grey[200],
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(Icons.image, size: 80, color: Colors.grey[400]),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
      await NotificationService.initialize(context);
      await NotificationService.scheduleDailyQuoteNotification(_locale);
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
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Motivational Saints',
      themeMode: _themeMode,
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansTextTheme(),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
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

class HomePage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.inspiringSaints)),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text(loc.menu)),
            ListTile(
              leading: Icon(Icons.contact_page),
              title: Text(loc.contact),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ContactPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.color_lens),
              title: Text(loc.selectTheme),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(loc.chooseTheme),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile(
                          title: Text(loc.system),
                          value: ThemeMode.system,
                          groupValue: themeMode,
                          onChanged: (val) {
                            onThemeChange(ThemeMode.system);
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile(
                          title: Text(loc.light),
                          value: ThemeMode.light,
                          groupValue: themeMode,
                          onChanged: (val) {
                            onThemeChange(ThemeMode.light);
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile(
                          title: Text(loc.dark),
                          value: ThemeMode.dark,
                          groupValue: themeMode,
                          onChanged: (val) {
                            onThemeChange(ThemeMode.dark);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.language),
              title: Text(loc.language),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(loc.language),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<Locale>(
                          title: Text(loc.english),
                          value: const Locale('en'),
                          groupValue: locale,
                          onChanged: (val) {
                            onLocaleChange(const Locale('en'));
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile<Locale>(
                          title: Text(loc.hindi),
                          value: const Locale('hi'),
                          groupValue: locale,
                          onChanged: (val) {
                            onLocaleChange(const Locale('hi'));
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text(loc.setName),
              onTap: () {
                Navigator.pop(context);
                final controller = TextEditingController(text: userName);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(loc.enterYourName),
                    content: TextField(
                      controller: controller,
                      decoration: InputDecoration(labelText: loc.name),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          onSetUserName(controller.text.trim());
                          Navigator.pop(context);
                        },
                        child: Text(loc.save),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.note),
              title: Text('Spiritual diary'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SpiritualDiaryPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text(loc.aboutApp),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AboutAppPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.format_quote),
              title: Text(loc.quoteOfTheDay),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuoteOfTheDayPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.coffee),
              title: Text('Buy me a coffee'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BuyMeACoffeePage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          MainBannerImage(imagePath: 'assets/images/foursaints.jpg'),
          Expanded(
            child: ListView.builder(
              itemCount: saints.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    elevation: 4,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SaintPage(
                        saint: saints[i],
                        userName: userName,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: saints[i].image.startsWith('assets/')
                            ? AssetImage(saints[i].image) as ImageProvider
                            : NetworkImage(saints[i].image),
                      ),
                      SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          saints[i].name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.contact)),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32.0, bottom: 24.0),
                  child: Image.asset(
                    'assets/images/antarikshverse.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SelectableText(
                    loc.contactUs,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Image.asset(
                  'assets/images/Antariksh.jpg',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BuyMeACoffeePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    return Scaffold(
      appBar: AppBar(title: Text(isHindi ? 'मुझे कॉफी खरीदें' : 'Buy me a coffee')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  text: isHindi ? '☕ मुझे कॉफी खरीदें' : '☕ Buy me a coffee',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 20,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final url = Uri.parse('https://www.buymeacoffee.com/AntarikshVerse');
                      try {
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isHindi ? 'लिंक खोलने के लिए कोई ब्राउज़र नहीं मिला।' : 'No browser found to open the link.')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text((isHindi ? 'ब्राउज़र खोलने में विफल: ' : 'Failed to open browser: ') + e.toString())),
                        );
                      }
                    },
                ),
              ),
              SizedBox(height: 32),
              Text(
                isHindi ? loc.supportTextHi : loc.supportTextEn,
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SaintPage extends StatefulWidget {
  final Saint saint;
  final String userName;
  SaintPage({required this.saint, required this.userName});
  @override
  _SaintPageState createState() => _SaintPageState();
}

class _SaintPageState extends State<SaintPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Database db;
  List<Map<String, dynamic>> history = [];
  bool _useHindi = false;

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
    _tabController = TabController(length: 4, vsync: this);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isHindi
            ? saintsHi.firstWhere((s) => s.id == widget.saint.id, orElse: () => saintsHi[0]).name
            : widget.saint.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.quotes),
            Tab(text: loc.articles),
            Tab(text: loc.ask),
            Tab(text: loc.history),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          QuotesTab(
            quotes: isHindi
                ? saintsHi.firstWhere((s) => s.id == widget.saint.id, orElse: () => saintsHi[0]).quotes
                : widget.saint.quotes,
            image: widget.saint.image,
          ),
          ArticlesTab(
            articles: isHindi
                ? saintsHi.firstWhere((s) => s.id == widget.saint.id, orElse: () => saintsHi[0]).articles.map((a) => Article(heading: a.heading, body: a.body)).toList()
                : widget.saint.articles,
          ),
          AskTab(
            onSubmit: (q, a) => _addQnA(q, a),
            saint: widget.saint.name,
            userName: widget.userName,
          ),
          HistoryTab(history: history),
        ],
      ),
    );
  }
}

class QuotesTab extends StatefulWidget {
  final List<String> quotes;
  final String image;
  QuotesTab({required this.quotes, required this.image});
  @override
  _QuotesTabState createState() => _QuotesTabState();
}

class _QuotesTabState extends State<QuotesTab> {
  Set<String> _readQuotes = {};

  @override
  void initState() {
    super.initState();
    _loadReadQuotes();
  }

  Future<void> _loadReadQuotes() async {
    final read = await ReadStatusService.getReadQuotes();
    setState(() {
      _readQuotes = read;
    });
  }

  String _quoteId(String quote) {
    // Use quote text as unique ID (adjust if you have a better unique key)
    return quote;
  }

  @override
  Widget build(BuildContext context) {
    final quoteTextStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, fontSize: 18);
    return ListView.separated(
      itemCount: widget.quotes.length + 1,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == 0) {
          return SaintImagePlaceholder(imagePath: widget.image);
        }
        final quote = widget.quotes[i - 1];
        final id = _quoteId(quote);
        final isRead = _readQuotes.contains(id);
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Theme.of(context).cardColor,
          child: ListTile(
            leading: isRead ? null : Icon(Icons.fiber_manual_record, color: Colors.blue, size: 14),
            title: Text(
              quote,
              style: quoteTextStyle?.copyWith(
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                color: isRead ? Theme.of(context).colorScheme.onSurface : Colors.blueAccent,
              ),
            ),
            onTap: () async {
              await ReadStatusService.markQuoteRead(id);
              setState(() {
                _readQuotes.add(id);
              });
            },
          ),
        );
      },
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
                style: TextStyle(fontSize: 16, color: Colors.black87),
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

class AskTab extends StatefulWidget {
  final Function(String, String) onSubmit;
  final String saint;
  final String userName;
  AskTab({required this.onSubmit, required this.saint, required this.userName});
  @override
  _AskTabState createState() => _AskTabState();
}

class _AskTabState extends State<AskTab> {
  final _controller = TextEditingController();
  final List<String> _lines = [];
  String? _answer;
  bool _loading = false;
  StreamSubscription<String>? _subscription;
  http.Client? _client;
  AppConfig? _config;
  bool _configLoading = true;
  String? _configError;
  bool _hasTriedAsk = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_hasTriedAsk) {
        setState(() {
          _hasTriedAsk = false;
          _lines.clear();
          _answer = null;
        });
      }
    });
    _fetchConfig();
  }

  Future<void> _fetchConfig() async {
    setState(() {
      _configLoading = true;
      _configError = null;
    });
    try {
      print('AskTab: Starting to fetch config...');
      final config = await ConfigService.fetchConfig();
      if (!mounted) return;
      setState(() {
        _config = config;
        _configLoading = false;
      });
    } catch (e) {
      print('AskTab: Error fetching config: ' + e.toString());
      if (!mounted) return;
      setState(() {
        _configError = 'Failed to load configuration.';
        _configLoading = false;
      });
    }
  }

  Future<void> _askQuestion() async {
    setState(() {
      _hasTriedAsk = true;
    });
    if (_configLoading) {
      setState(() {
        _lines.clear();
        _lines.add('Configuration is still loading. Please wait and try again.');
        _loading = false;
        _answer = null;
      });
      return;
    }
    if (_configError != null) {
      setState(() {
        _lines.clear();
        _lines.add(_configError!);
        _loading = false;
        _answer = null;
      });
      return;
    }
    if (_config == null || !_config!.gradioServerRunning) {
      setState(() {
        _lines.clear();
        _lines.add('Gradio server is not running. Please try again later.');
        _loading = false;
        _answer = null;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _lines.clear();
      _loading = true;
      _answer = null;
    });
    final question = _controller.text;
    _client = http.Client();
    final String gradioStreamUrl = _config!.gradioServerLink + '/gradio_api/call/query_rag_stream';
    final String language = Localizations.localeOf(context).languageCode;
    print('AskTab: Using Gradio link: ' + gradioStreamUrl);
    print('AskTab: Sending language context: ' + language);
    try {
      final postResponse = await _client!.post(
        Uri.parse(gradioStreamUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "data": [
            widget.userName + ": " + question,
            widget.saint,
            language // Pass language context to backend
          ]
        }),
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception('Server timeout. Please try again later.');
      });

      if (!mounted) return;
      if (postResponse.statusCode != 200) {
        setState(() {
          _lines.add('Apologies, Server is down, Please try later : POST failed: ${postResponse.statusCode}');
          _loading = false;
          _answer = null;
        });
        return;
      }

      final eventId = jsonDecode(postResponse.body)['event_id'] ?? '';
      if (eventId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _lines.add('No event_id in response');
          _loading = false;
          _answer = null;
        });
        return;
      }

      // Use config gradioServerLink for stream URL
      final streamUrl = _config!.gradioServerLink + '/gradio_api/call/query_rag_stream/' + eventId;
      final request = http.Request('GET', Uri.parse(streamUrl));
      final responseFuture = _client!.send(request);
      late http.StreamedResponse response;
      try {
        response = await responseFuture.timeout(const Duration(seconds: 15), onTimeout: () {
          throw Exception('Server timeout. Please try again later.');
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _lines.add('Error: Server did not respond in time. Please try later.');
          _loading = false;
          _answer = null;
        });
        return;
      }

      bool gotResponse = false;
      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && trimmed != 'data' && trimmed != 'null') {
          gotResponse = true;
          String displayLine = trimmed;
          final match = RegExp(r'\[\s*\[(.*?)\]\s*\]').firstMatch(displayLine);
          if (match != null) {
            displayLine = match.group(1) ?? '';
          }
          if (displayLine.startsWith('"') && displayLine.endsWith('"')) {
            try {
              displayLine = jsonDecode(displayLine);
            } catch (_) {}
          } else {
            displayLine = displayLine.replaceAll(r'\n', '\n');
            displayLine = displayLine.replaceAllMapped(
              RegExp(r'\\u([0-9a-fA-F]{4})'),
                  (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
            );
            displayLine = displayLine.replaceAll(r'\\', r'\');
            displayLine = displayLine.replaceAll(r'\"', '"');
            displayLine = displayLine.replaceAll('[', '');
            displayLine = displayLine.replaceAll('",', '\n');
          }
          if (!mounted) return;
          setState(() {
            _lines.clear(); // Clear error lines on success
            // Remove the question if it appears at the start of the answer
            String answerText = displayLine;
            final question = _controller.text.trim();
            final idx = answerText.indexOf(question);
            if (idx != -1) {
              // Take everything after the question
              answerText = answerText.substring(idx + question.length).trim();
              // Optionally, remove leading punctuation or newlines
              answerText = answerText.replaceFirst(RegExp(r'^[:\-\s]+'), '');
            }
            _answer = answerText;
          });
        }
      }, onDone: () {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
        if (!gotResponse) {
          setState(() {
            _lines.add('No response from server. Please try again later.');
            _answer = null;
          });
        } else if (_answer != null) {
          widget.onSubmit(question, _answer!);
        }
      }, onError: (e) {
        if (!mounted) return;
        setState(() {
          _lines.add('Error: Server seems to be down. Please try later.');
          _loading = false;
          _answer = null;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lines.add('Error: Server seems to be down. Please try later');
        _loading = false;
        _answer = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    bool showError = false;
    if (_hasTriedAsk && _lines.isNotEmpty && _answer == null) {
      final errorKeywords = ['error', 'failed', 'not running', 'no response', 'did not respond'];
      final firstLine = _lines.first.toLowerCase();
      showError = errorKeywords.any((kw) => firstLine.contains(kw));
    }
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                loc.askDisclaimer,
                style: TextStyle(
                  fontSize: 13, // Revert disclaimer font size to original
                  color: Colors.orange[800],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (showError)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(_lines.join('\n'), style: TextStyle(color: Colors.red, fontSize: 15)),
              ),
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: loc.askAQuestion),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _askQuestion,
              child: Text(loc.ask),
            ),
            if (_loading) CircularProgressIndicator(),
            if (_answer != null)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText('${loc.answer}: $_answer', style: TextStyle(fontSize: 20)),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.flag),
                      label: Text('Flag as Incorrect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final url = (_config?.gradioServerLink ?? '') + '/gradio_api/call/flag_and_show';
                        try {
                          final response = await http.post(
                            Uri.parse(url),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              "data": [

                              ]
                            }),
                          );
                          if (response.statusCode == 200) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Flag submitted. Thank you!')),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to flag. Please try again.')),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error submitting flag.')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  HistoryTab({required this.history});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (history.isEmpty) return Center(child: Text(loc.noPreviousQuestions));
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, i) => ListTile(
        title: Text('Q: \'${history[i]['question']}\''),
        subtitle: Text('${loc.answer}: ${history[i]['answer']}'),
      ),
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

  @override
  void initState() {
    super.initState();
    _initDbAndLoadNote();
  }

  Future<void> _initDbAndLoadNote() async {
    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'notepad.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS notepad(id INTEGER PRIMARY KEY, content TEXT, updated_at TEXT)'
        );
        await db.insert('notepad', {'id': 1, 'content': '', 'updated_at': DateTime.now().toIso8601String()});
      },
      version: 1,
    );
    _db = db;
    final List<Map<String, dynamic>> notes = await db.query('notepad', where: 'id = ?', whereArgs: [1]);
    if (notes.isNotEmpty) {
      _controller.text = notes.first['content'] ?? '';
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _saveNote() async {
    if (_db == null) return;
    await _db!.update(
      'notepad',
      {
        'content': _controller.text,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Note saved!')),
    );
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
      appBar: AppBar(title: Text(loc.spiritualDiary)),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: loc.spiritualDiary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _saveNote,
                    icon: Icon(Icons.save),
                    label: Text(loc.save),
                  ),
                ],
              ),
            ),
    );
  }
}

class AboutAppPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.aboutApp)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/apppic.png', // Use your available image as aboutapp.jpg is not present
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
            ],
          ),
        ),
      ),
    );
  }
}

class QuoteOfTheDayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final random = Random();
    String quote = '';
    String saintName = '';
    String saintImage = '';
    if (isHindi) {
      final allSaints = saintsHi;
      final allQuotes = <Map<String, String>>[];
      for (final s in allSaints) {
        for (final q in s.quotes) {
          allQuotes.add({'quote': q, 'saint': s.name, 'image': s.image});
        }
      }
      if (allQuotes.isNotEmpty) {
        final picked = allQuotes[random.nextInt(allQuotes.length)];
        quote = picked['quote']!;
        saintName = picked['saint']!;
        saintImage = picked['image']!;
      }
    } else {
      final allSaints = saints;
      final allQuotes = <Map<String, String>>[];
      for (final s in allSaints) {
        for (final q in s.quotes) {
          allQuotes.add({'quote': q, 'saint': s.name, 'image': s.image});
        }
      }
      if (allQuotes.isNotEmpty) {
        final picked = allQuotes[random.nextInt(allQuotes.length)];
        quote = picked['quote']!;
        saintName = picked['saint']!;
        saintImage = picked['image']!;
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(loc.quoteOfTheDay)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (saintImage.isNotEmpty)
                CircleAvatar(
                  backgroundImage: AssetImage(saintImage),
                  radius: 60,
                ),
              SizedBox(height: 24),
              Text(
                '"$quote"',
                style: TextStyle(fontSize: 22, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Text(
                '- $saintName',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
