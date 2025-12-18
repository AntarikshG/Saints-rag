import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'config_service.dart';
import 'l10n/app_localizations.dart';
import 'articlesquotes.dart'; // For saints data
import 'rich_text_parser.dart'; // For FormattedSelectableText

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

  Future<void> _deleteFromHistory(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _history.removeAt(index);

    final historyJson = _history.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('ask_all_history', historyJson);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Talk to spiritual AI friend',
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
        decoration: BoxDecoration(gradient: brightness == Brightness.dark
            ? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade900, Colors.grey.shade800, Colors.black],
        )
            : LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.deepOrange.shade50, Colors.orange.shade50, Colors.white],
        )),
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: isDark ? Colors.grey[400] : Colors.grey
            ),
            SizedBox(height: 16),
            Text(
              loc.noPreviousQuestions,
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey[300] : Colors.grey
              )
            ),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['question']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.red.shade900.withOpacity(0.3)
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.red.shade700 : Colors.red.shade200
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showDeleteConfirmation(context, index),
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.delete,
                            color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  item['answer']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.orange),
              SizedBox(width: 8),
              Text('Delete Question?'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this question and answer? This action cannot be undone.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFromHistory(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Question deleted successfully'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class AskTab extends StatefulWidget {
  final Function(String, String) onSubmit;
  final String saintId;
  final String userName;
  AskTab({required this.onSubmit, required this.saintId, required this.userName});
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
  void initState() {
    super.initState();
    _controller.addListener(() {
      // Clear results when text changes after a question has been asked
      if (_hasTriedAsk) {
        setState(() {
          _hasTriedAsk = false;
          _lines.clear();
          _answer = null;
        });
      } else {
        // Trigger rebuild to update button state when text changes
        setState(() {});
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
            "My name is " + widget.userName + ". " + question,
            getEnglishSaintName(widget.saintId), // Use English saint name consistently
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Check if this is AnandMoyiMa or Baba Neeb Karori and disable Ask AI feature
    if (widget.saintId == 'anandmoyima' || widget.saintId == 'baba_neeb_karori') {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 64,
                  color: isDark ? Colors.grey[400] : Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Ask AI Feature Disabled',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.saintId == 'anandmoyima'
                    ? 'The Ask AI feature is not available for Anandamayi Ma.'
                    : 'The Ask AI feature is not available for Baba Neeb Karori.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Coming soon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.orange[300] : Colors.deepOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Please explore their quotes and teachings in the other tabs.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    bool showError = false;
    if (_hasTriedAsk && _lines.isNotEmpty && _answer == null) {
      final errorKeywords = ['error', 'failed', 'not running', 'no response', 'did not respond'];
      final firstLine = _lines.first.toLowerCase();
      showError = errorKeywords.any((kw) => firstLine.contains(kw));
    }

    // Check if user has entered text
    final hasText = _controller.text.trim().isNotEmpty;
    final canAsk = hasText && !_loading && !_configLoading;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced header section
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.grey.shade800, Colors.grey.shade700]
                        : [Colors.purple.shade50, Colors.purple.shade100],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade600 : Colors.purple.shade200
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.blue.shade600 : Colors.purple.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ask Your Spiritual Question',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      loc.askDisclaimer,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.purple.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Error display
              if (showError)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.red.shade700 : Colors.red.shade200
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: isDark ? Colors.red.shade400 : Colors.red.shade600
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lines.join('\n'),
                          style: TextStyle(
                            color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                            fontSize: 14
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Enhanced input section
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.purple).withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type your question below:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.purple.shade700,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _controller,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'e.g., How can I find inner peace? What is the meaning of life?',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade600 : Colors.purple.shade200
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.blue.shade400 : Colors.purple.shade400,
                              width: 2
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade600 : Colors.purple.shade200
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade800.withOpacity(0.5)
                              : Colors.purple.shade50,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Enhanced Ask AI Button - Always visible
                      Container(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: canAsk ? _askQuestion : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAsk
                                ? (isDark ? Colors.blue.shade600 : Colors.purple.shade600)
                                : Colors.grey.shade300,
                            foregroundColor: canAsk ? Colors.white : Colors.grey.shade500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: canAsk ? 6 : 2,
                            shadowColor: (isDark ? Colors.blue : Colors.purple).withOpacity(0.3),
                          ),
                          child: _loading
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
                                    'Getting wisdom from saints...',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    size: 22,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    hasText ? 'Ask AI Spiritual Friend' : 'Enter question to ask',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                        ),
                      ),

                      // Status indicator below button
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: canAsk ? Colors.green : (hasText ? Colors.orange : Colors.grey),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            canAsk
                              ? 'Ready to ask'
                              : (hasText ? (_loading ? 'Processing...' : 'Loading...') : 'Type your question first'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Answer section with improved styling
              if (_answer != null)
                Container(
                  margin: EdgeInsets.only(top: 24),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.grey.shade800, Colors.grey.shade700]
                          : [Colors.green.shade50, Colors.green.shade100],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade600 : Colors.green.shade200
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.green).withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.amber.shade600 : Colors.green.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '${loc.answer}:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      FormattedSelectableText(
                        _answer!,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: isDark ? Colors.grey[200] : Colors.green.shade800,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.flag_outlined),
                        label: Text('Flag as Incorrect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final url = (_config?.gradioServerLink ?? '') + '/gradio_api/call/flag_and_show';
                          try {
                            final response = await http.post(
                              Uri.parse(url),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                "data": []
                              }),
                            );
                            if (response.statusCode == 200) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Flag submitted. Thank you!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to flag. Please try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error submitting flag.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),

              // Add bottom padding to ensure content is visible above system UI
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
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
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      itemCount: history.length,
      itemBuilder: (context, i) {
        final item = history[i];
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['question'], style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(item['answer']),
              ],
            ),
          ),
        );
      },
    );
  }
}
