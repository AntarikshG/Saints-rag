import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'config_service.dart';
import 'l10n/app_localizations.dart';
import 'articlesquotes.dart'; // For saints data
import 'rich_text_parser.dart'; // For FormattedSelectableText
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class AskAIPage extends StatefulWidget {
  final String userName;

  const AskAIPage({required this.userName, Key? key}) : super(key: key);

  @override
  _AskAIPageState createState() => _AskAIPageState();
}

class _AskAIPageState extends State<AskAIPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, String>> _history = [];
  final Map<int, ScreenshotController> _historyScreenshotControllers = {};

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

  Future<void> _shareHistoryItem(int index) async {
    try {
      // Get or create screenshot controller for this index
      if (!_historyScreenshotControllers.containsKey(index)) {
        _historyScreenshotControllers[index] = ScreenshotController();
      }

      final controller = _historyScreenshotControllers[index]!;

      // Capture the screenshot
      final imageBytes = await controller.capture();
      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to capture image. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get the temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/qa_history_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // Share the image
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Wisdom from Saints',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

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

        // Create screenshot controller if not exists
        if (!_historyScreenshotControllers.containsKey(index)) {
          _historyScreenshotControllers[index] = ScreenshotController();
        }

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Screenshot(
                controller: _historyScreenshotControllers[index]!,
                child: Container(
                  color: Theme.of(context).cardColor,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question section
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.blue.shade700 : Colors.blue.shade200
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.question_answer,
                                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Question:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              item['question']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      // Answer section
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: isDark ? Colors.amber.shade400 : Colors.green.shade700,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Answer:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.amber.shade400 : Colors.green.shade700,
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
                      SizedBox(height: 12),
                      // Banner image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          isDark
                              ? 'assets/images/quotesbanner_dark.jpg'
                              : 'assets/images/quotesbanner.jpg',
                          width: double.infinity,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 60,
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                              child: Center(
                                child: Text(
                                  'Saints Speak',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action buttons outside screenshot
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Text(
                      '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey
                      ),
                    ),
                    Spacer(),
                    // Share button
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue.shade900.withOpacity(0.3)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.blue.shade700 : Colors.blue.shade200
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _shareHistoryItem(index),
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.share,
                            color: isDark ? Colors.blue.shade400 : Colors.blue.shade700,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Delete button
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
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.orange),
              SizedBox(width: 8),
              Text(loc.deleteQuestion),
            ],
          ),
          content: Text(
            loc.deleteQuestionConfirm,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: Text(loc.cancel, style: TextStyle(color: Colors.grey.shade600)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(loc.delete),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFromHistory(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text(loc.questionDeletedSuccessfully),
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
  final ScreenshotController _screenshotController = ScreenshotController();

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
    // Dismiss keyboard first (especially important for iOS)
    FocusScope.of(context).unfocus();

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

  Future<void> _shareQuestionAnswer() async {
    try {
      // Capture the screenshot
      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to capture image. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get the temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/qa_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // Share the image
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Wisdom from Saints',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Check if this is AnandMoyiMa or Baba Neeb Karori and disable Ask AI feature
    if (widget.saintId == 'anandmoyima' || widget.saintId == 'baba_neeb_karori') {
      final String unavailableMessage = widget.saintId == 'anandmoyima'
          ? loc.askAINotAvailableForAnandmoyima
          : loc.askAINotAvailableForBabaNeebKarori;

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
                  loc.askAIFeatureDisabled,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  unavailableMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  loc.comingSoon,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.orange[300] : Colors.deepOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  loc.exploreOtherTabs,
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
                            loc.askYourSpiritualQuestion,
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
                        loc.typeYourQuestionBelow,
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
                          hintText: loc.questionPlaceholder,
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
                                    loc.gettingWisdomFromSaints,
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
                                    hasText ? loc.askAISpiritualFriend : loc.enterQuestionToAsk,
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
                              ? loc.readyToAsk
                              : (hasText ? (_loading ? loc.processing : loc.loading) : loc.typeYourQuestionFirst),
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
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    margin: EdgeInsets.only(top: 24),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
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
                        // Question section
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.blue.shade700 : Colors.blue.shade200
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.question_answer,
                                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Question:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                _controller.text,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark ? Colors.grey[200] : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        // Answer section
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
                              'Answer:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          _answer!,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: isDark ? Colors.grey[200] : Colors.green.shade800,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Banner image at bottom
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            isDark
                                ? 'assets/images/quotesbanner_dark.jpg'
                                : 'assets/images/quotesbanner.jpg',
                            width: double.infinity,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 80,
                                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                                child: Center(
                                  child: Text(
                                    'Saints Speak',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Action buttons below the screenshot area
              if (_answer != null)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.share),
                          label: Text('Share as Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.blue.shade600 : Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _shareQuestionAnswer,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.flag_outlined),
                          label: Text('Flag'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
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
                                          Text(loc.flagSubmittedThankYou),
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
