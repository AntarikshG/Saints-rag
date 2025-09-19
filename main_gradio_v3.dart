import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'articlesquotes.dart';
import 'articlesquotes_hi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
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
        padding: EdgeInsets.all(16),
        child: Text(body, style: TextStyle(fontSize: 18)),
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

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  String _userName = 'Seeker';
  void _setUserName(String name) {
    setState(() {
      _userName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motivational Saints',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
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
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: saints.length,
        itemBuilder: (context, i) => ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(saints[i].image)),
          title: Text(saints[i].name),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SaintPage(
                saint: saints[i],
                userName: userName,
              ),
            ),
          ),
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
      appBar: AppBar(title: Text(loc.contact)),
      body: Center(
        child: Text(loc.contactUs),
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

class QuotesTab extends StatelessWidget {
  final List<String> quotes;
  final String image;
  QuotesTab({required this.quotes, required this.image});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: quotes.length + 1,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Image.network(image, height: 200, fit: BoxFit.cover);
        }
        final quote = quotes[i - 1];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote, color: Colors.grey[400], size: 32),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quote,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ArticlesTab extends StatelessWidget {
  final List<Article> articles;
  ArticlesTab({required this.articles});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: articles.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, i) {
        final a = articles[i];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(
              a.heading,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            onTap: () {
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

  Future<void> _askQuestion() async {
    setState(() {
      _lines.clear();
      _loading = true;
    });
    final question = _controller.text;
    _client = http.Client();

    final String gradioStreamUrl = 'http://127.0.0.1:7860/gradio_api/call/submit';

    try {
      final postResponse = await _client!.post(
        Uri.parse(gradioStreamUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "data": [
            widget.userName + ": " + question,
            widget.saint,
            "History",
            // Pass userName to backend
          ]
        }),
      );

      if (postResponse.statusCode != 200) {
        setState(() {
          _lines.add('POST failed: ${postResponse.statusCode}');
          _loading = false;
        });
        return;
      }

      final eventId = jsonDecode(postResponse.body)['event_id'] ?? '';
      if (eventId.isEmpty) {
        setState(() {
          _lines.add('No event_id in response');
          _loading = false;
        });
        return;
      }

      final streamUrl = 'http://127.0.0.1:7860/gradio_api/call/submit/$eventId';
      final request = http.Request('GET', Uri.parse(streamUrl));
      final response = await _client!.send(request);

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && trimmed != 'data' && trimmed != 'null') {
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
          setState(() {
            _lines
              ..clear()
              ..add(displayLine);
            _answer = displayLine;
          });
        }
      },onDone: () {
        setState(() {
          _loading = false;
        });
        if (_answer != null) {
          widget.onSubmit(question, _answer!);
        }
      }, onError: (e) {
        setState(() {
          _lines.add('Error: Server seems to be down. Please try later.');
          _loading = false;
        });
      });
    } catch (e) {
      setState(() {
        _lines.add('Error: Server seems to be down. Please try later.');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                child: SelectableText('${loc.answer}: $_answer'),
              ),
            if (_lines.isNotEmpty && _lines.first.startsWith('Error:'))
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: SelectableText(_lines.join('\n')),
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
