import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'dart:async';
import 'articlesquotes.dart';
import 'articlesquotes_en.dart';
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
import 'package:flutter_tts/flutter_tts.dart';
// Book reading imports
import 'books_library.dart';
import 'books_tab.dart';
import 'rating_share_service.dart';
import 'ekadashi_service.dart';
import 'ask_ai_page.dart';
import 'user_profile_service.dart';
import 'articlesquotes_de.dart';
import 'articlesquotes_kn.dart';
import 'bookmarked_quotes_page.dart';
import 'quote_of_the_day_page.dart';
import 'spiritual_diary_page.dart';
import 'notification_settings_page.dart';
import 'badge_service.dart';
import 'badge_widget.dart';

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

class ArticlePage extends StatefulWidget {
  final String heading;
  final String body;
  ArticlePage({required this.heading, required this.body});

  @override
  _ArticlePageState createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  // TTS functionality
  FlutterTts? _flutterTts;
  bool _isTtsPlaying = false;
  bool _isTtsPaused = false;
  bool _isTtsInitialized = false;
  bool _showTtsControls = false;
  double _ttsRate = 0.5;
  double _ttsPitch = 1.0;
  String _selectedLanguage = 'en-US';
  String? _selectedVoice;
  List<dynamic> _availableLanguages = [];
  List<dynamic> _availableVoices = [];

  // Supported TTS languages map for Article - English, Hindi, Kannada, and German
  final Map<String, String> _supportedTtsLanguages = {
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'en-IN': 'English (India)',
    'hi-IN': 'Hindi (India)',
    'kn-IN': 'Kannada (India)',
    'de-DE': 'German (Germany)',
    'de-AT': 'German (Austria)',
    'de-CH': 'German (Switzerland)',
  };

  // Filtered voices based on supported languages
  List<Map<String, dynamic>> _filteredVoices = [];

  // TTS reading state - chunk-based reading
  List<String> _textChunks = [];
  int _currentChunkIndex = 0;
  bool _isReadingChunks = false;
  Timer? _chunkTimer;
  int _savedChunkIndex = 0;

  // Text display settings
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _loadTtsSettings();
  }

  @override
  void dispose() {
    _stopTtsReading();
    _flutterTts?.stop();
    _chunkTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTtsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ttsRate = prefs.getDouble('article_tts_rate') ?? 0.5;
      _ttsPitch = prefs.getDouble('article_tts_pitch') ?? 1.0;
      _selectedLanguage = prefs.getString('article_tts_language') ?? 'en-US';
      _selectedVoice = prefs.getString('article_tts_voice');
      _fontSize = prefs.getDouble('article_font_size') ?? 18.0;
    });
    await _initializeTts();
  }

  Future<void> _saveTtsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('article_tts_rate', _ttsRate);
    await prefs.setDouble('article_tts_pitch', _ttsPitch);
    await prefs.setString('article_tts_language', _selectedLanguage);
    if (_selectedVoice != null) {
      await prefs.setString('article_tts_voice', _selectedVoice!);
    }
    await prefs.setDouble('article_font_size', _fontSize);
  }

  Future<void> _initializeTts() async {
    try {
      print('TTS: Initializing Text-to-Speech for Article...');

      if (_flutterTts == null) {
        print('TTS: FlutterTts instance is null, cannot initialize');
        return;
      }

      // For Android, check if TTS is available
      // Note: getEngines is Android-only, skip on iOS
      if (Platform.isAndroid) {
        try {
          dynamic engines = await _flutterTts!.getEngines;
          print('TTS: Available engines: $engines');
        } catch (e) {
          print('TTS: Could not get engines (expected on iOS): $e');
        }
      }

      // Set up TTS handlers
      _flutterTts!.setStartHandler(() {
        print('TTS: Started speaking');
        if (mounted) {
          setState(() {
            _isTtsPlaying = true;
            _isTtsPaused = false;
          });
        }
      });

      _flutterTts!.setCompletionHandler(() {
        print('TTS: Completed speaking chunk ${_currentChunkIndex + 1}/${_textChunks.length}');
        if (mounted) {
          if (_isReadingChunks && _currentChunkIndex < _textChunks.length - 1) {
            // Move to next chunk
            _currentChunkIndex++;
            print('TTS: Moving to next chunk ${_currentChunkIndex + 1}/${_textChunks.length}');

            _chunkTimer = Timer(Duration(milliseconds: 500), () {
              if (_isReadingChunks && _isTtsPlaying) {
                _speakCurrentChunk();
              }
            });
          } else {
            // Finished reading entire article
            print('TTS: Finished reading entire article');
            setState(() {
              _isTtsPlaying = false;
              _isTtsPaused = false;
              _isReadingChunks = false;
              _currentChunkIndex = 0;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Finished reading article'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
      });

      _flutterTts!.setCancelHandler(() {
        print('TTS: Cancelled speaking');
        if (mounted) {
          setState(() {
            _isTtsPlaying = false;
            _isTtsPaused = false;
          });
        }
      });

      _flutterTts!.setPauseHandler(() {
        print('TTS: Paused speaking');
        if (mounted) {
          setState(() {
            _isTtsPlaying = false;
            _isTtsPaused = true;
          });
        }
      });

      _flutterTts!.setContinueHandler(() {
        print('TTS: Continued speaking');
        if (mounted) {
          setState(() {
            _isTtsPlaying = true;
            _isTtsPaused = false;
          });
        }
      });

      _flutterTts!.setErrorHandler((msg) {
        print('TTS: Error - $msg');
        if (mounted) {
          setState(() {
            _isTtsPlaying = false;
            _isTtsPaused = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('TTS Error: Please check your device TTS settings'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });

      // Set initial TTS properties
      await _flutterTts!.setLanguage(_selectedLanguage);
      await _flutterTts!.setSpeechRate(_ttsRate);
      await _flutterTts!.setPitch(_ttsPitch);

      // Get available languages
      _availableLanguages = await _flutterTts!.getLanguages;
      print('TTS: Available languages: $_availableLanguages');

      // Get available voices
      _availableVoices = await _flutterTts!.getVoices;
      print('TTS: Available voices count: ${_availableVoices.length}');

      // Filter voices for supported languages only
      _filterVoicesForSupportedLanguages();

      // Ensure selected language is supported
      if (!_supportedTtsLanguages.containsKey(_selectedLanguage)) {
        _selectedLanguage = 'en-US'; // Default to US English
      }

      // Set voice if available and matches the selected language
      if (_selectedVoice != null && _filteredVoices.isNotEmpty) {
        final matchingVoice = _filteredVoices.firstWhere(
          (voice) => voice['name'] == _selectedVoice && voice['locale'] == _selectedLanguage,
          orElse: () => {},
        );

        if (matchingVoice.isNotEmpty) {
          await _flutterTts!.setVoice({
            "name": matchingVoice['name'],
            "locale": matchingVoice['locale']
          });
        }
      }

      setState(() {
        _isTtsInitialized = true;
      });

      print('TTS: Initialization completed successfully');
    } catch (e) {
      print('TTS: Initialization failed: $e');
      setState(() {
        _isTtsInitialized = false;
      });
    }
  }

  void _startTtsReading() {
    if (!_isTtsInitialized || widget.body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text-to-Speech is not ready. Please wait or check device settings.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Split article body into chunks (sentences or paragraphs)
    _textChunks = _splitTextIntoChunks(widget.body);
    _currentChunkIndex = 0;
    _isReadingChunks = true;

    print('TTS: Starting to read article. Total chunks: ${_textChunks.length}');

    setState(() {
      _isTtsPlaying = true;
      _isTtsPaused = false;
    });

    _speakCurrentChunk();
  }

  List<String> _splitTextIntoChunks(String text) {
    // Split by sentences and paragraphs, keeping chunks reasonably sized
    List<String> chunks = [];

    // First split by paragraphs
    List<String> paragraphs = text.split('\n\n');

    for (String paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      // If paragraph is short enough, add as is
      if (paragraph.length <= 500) {
        chunks.add(paragraph.trim());
      } else {
        // Split long paragraphs by sentences
        List<String> sentences = paragraph.split(RegExp(r'[.!?]+\s+'));
        String currentChunk = '';

        for (String sentence in sentences) {
          if (sentence.trim().isEmpty) continue;

          if ((currentChunk + sentence).length <= 500) {
            currentChunk += (currentChunk.isEmpty ? '' : '. ') + sentence.trim();
          } else {
            if (currentChunk.isNotEmpty) {
              chunks.add(currentChunk);
            }
            currentChunk = sentence.trim();
          }
        }

        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk);
        }
      }
    }

    return chunks;
  }

  void _speakCurrentChunk() async {
    if (_currentChunkIndex >= _textChunks.length || !_isReadingChunks) {
      return;
    }

    final chunkText = _textChunks[_currentChunkIndex];
    print('TTS: Speaking chunk ${_currentChunkIndex + 1}/${_textChunks.length}');

    try {
      await _flutterTts!.speak(chunkText);
    } catch (e) {
      print('TTS: Error speaking chunk: $e');
      _stopTtsReading();
    }
  }

  void _pauseTtsReading() {
    if (_isTtsPlaying && _flutterTts != null) {
      _flutterTts!.pause();
      _chunkTimer?.cancel();
      setState(() {
        _savedChunkIndex = _currentChunkIndex;
      });
    }
  }

  void _resumeTtsReading() {
    if (_isTtsPaused && _flutterTts != null) {
      setState(() {
        _currentChunkIndex = _savedChunkIndex;
        _isReadingChunks = true;
      });
      _speakCurrentChunk();
    }
  }

  void _stopTtsReading() {
    _chunkTimer?.cancel();
    if (_flutterTts != null) {
      _flutterTts!.stop();
    }
    setState(() {
      _isTtsPlaying = false;
      _isTtsPaused = false;
      _isReadingChunks = false;
      _currentChunkIndex = 0;
      _showTtsControls = false;
    });
  }

  void _nextTtsChunk() {
    if (_isReadingChunks && _currentChunkIndex < _textChunks.length - 1) {
      _flutterTts?.stop(); // This will trigger completion handler to move to next chunk
    }
  }

  void _previousTtsChunk() {
    if (_isReadingChunks && _currentChunkIndex > 0) {
      _currentChunkIndex = (_currentChunkIndex - 1).clamp(0, _textChunks.length - 1);
      _flutterTts?.stop();

      Timer(Duration(milliseconds: 300), () {
        if (_isReadingChunks) {
          _speakCurrentChunk();
        }
      });
    }
  }

  List<String> _getFilteredLanguages() {
    // Return a curated list of common languages
    final commonLanguages = ['en-US', 'hi-IN', 'en-IN', 'en-GB'];
    return _availableLanguages
        .where((lang) => commonLanguages.contains(lang))
        .cast<String>()
        .toList();
  }

  Future<void> _updateAvailableVoices() async {
    try {
      _availableVoices = await _flutterTts!.getVoices;
      _filterVoicesForSupportedLanguages();
      setState(() {});
    } catch (e) {
      print('Error updating available voices: $e');
    }
  }

  void _filterVoicesForSupportedLanguages() {
    _filteredVoices.clear();

    // Track seen voice names per locale to prevent duplicates
    final seenVoices = <String, Set<String>>{};

    for (var voice in _availableVoices) {
      try {
        // Safely convert Map<Object?, Object?> to Map<String, dynamic>
        final voiceData = Map<String, dynamic>.from(voice as Map);
        final locale = voiceData['locale']?.toString() ?? '';
        final voiceName = voiceData['name']?.toString() ?? 'Default';

        // Only include voices for our supported languages
        if (_supportedTtsLanguages.containsKey(locale)) {
          // Initialize the set for this locale if not exists
          seenVoices.putIfAbsent(locale, () => <String>{});

          // Only add if we haven't seen this voice name for this locale
          if (!seenVoices[locale]!.contains(voiceName)) {
            seenVoices[locale]!.add(voiceName);
            _filteredVoices.add({
              'name': voiceName,
              'locale': locale,
            });
          }
        }
      } catch (e) {
        print('TTS: Error processing voice data: $e');
        // Skip this voice if there's an error
        continue;
      }
    }

    print('TTS: Filtered ${_filteredVoices.length} voices for supported languages');
  }

  List<Map<String, dynamic>> _getVoicesForLanguage(String language) {
    return _filteredVoices
        .where((voice) => voice['locale'] == language)
        .toList();
  }

  Future<void> _changeTtsLanguage(String language) async {
    if (_flutterTts != null && _supportedTtsLanguages.containsKey(language)) {
      try {
        await _flutterTts!.setLanguage(language);
        setState(() {
          _selectedLanguage = language;
          _selectedVoice = null; // Reset voice when language changes
        });
        await _saveTtsSettings(); // Save TTS settings

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS language changed to ${_supportedTtsLanguages[language]}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Error changing TTS language: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change TTS language'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeTtsVoice(String voiceName) async {
    if (_flutterTts != null) {
      try {
        final matchingVoice = _filteredVoices.firstWhere(
          (voice) => voice['name'] == voiceName && voice['locale'] == _selectedLanguage,
          orElse: () => {},
        );

        if (matchingVoice.isNotEmpty) {
          await _flutterTts!.setVoice({
            "name": matchingVoice['name'],
            "locale": matchingVoice['locale']
          });

          setState(() {
            _selectedVoice = voiceName;
          });
          await _saveTtsSettings();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice changed to $voiceName'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error changing TTS voice: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change voice'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeTtsRate(double rate) async {
    if (_flutterTts != null) {
      try {
        await _flutterTts!.setSpeechRate(rate);
        setState(() {
          _ttsRate = rate;
        });
        await _saveTtsSettings();
      } catch (e) {
        print('Error changing TTS rate: $e');
      }
    }
  }

  Future<void> _changeTtsPitch(double pitch) async {
    if (_flutterTts != null) {
      try {
        await _flutterTts!.setPitch(pitch);
        setState(() {
          _ttsPitch = pitch;
        });
        await _saveTtsSettings();
      } catch (e) {
        print('Error changing TTS pitch: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.heading),
        actions: [
          // TTS control button
          IconButton(
            icon: Icon(
              _isTtsPlaying ? Icons.volume_up : Icons.volume_off,
              color: _isTtsPlaying ? Colors.orange : null,
            ),
            onPressed: () {
              setState(() {
                _showTtsControls = !_showTtsControls;
              });
            },
            tooltip: 'Text-to-Speech',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    widget.body,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: _fontSize,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 80), // Space for TTS controls
                ],
              ),
            ),
          ),

          // TTS Controls Overlay
          if (_showTtsControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: SafeArea(
                  child: _buildTtsControlPanel(),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _showTtsControls && _isTtsInitialized
          ? FloatingActionButton(
              onPressed: _isTtsPlaying
                  ? _pauseTtsReading
                  : (_isTtsPaused ? _resumeTtsReading : _startTtsReading),
              backgroundColor: Colors.orange,
              child: Icon(
                _isTtsPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Widget _buildTtsControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Text-to-Speech',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => setState(() => _showTtsControls = false),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Playback controls
          if (_isTtsInitialized) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous),
                  onPressed: _currentChunkIndex > 0 ? _previousTtsChunk : null,
                  iconSize: 32,
                ),
                IconButton(
                  icon: Icon(
                    _isTtsPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.orange,
                  ),
                  onPressed: _isTtsPlaying
                      ? _pauseTtsReading
                      : (_isTtsPaused ? _resumeTtsReading : _startTtsReading),
                  iconSize: 48,
                ),
                IconButton(
                  icon: Icon(Icons.stop_circle),
                  onPressed: (_isTtsPlaying || _isTtsPaused) ? _stopTtsReading : null,
                  color: Colors.red,
                  iconSize: 32,
                ),
                IconButton(
                  icon: Icon(Icons.skip_next),
                  onPressed: _currentChunkIndex < _textChunks.length - 1
                      ? _nextTtsChunk
                      : null,
                  iconSize: 32,
                ),
              ],
            ),

            if (_isTtsPlaying || _isTtsPaused)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    'Progress: ${_currentChunkIndex + 1}/${_textChunks.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),

            Divider(),

            // Language selection
            Text('Language', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _supportedTtsLanguages.containsKey(_selectedLanguage) ? _selectedLanguage : 'en-US',
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _supportedTtsLanguages.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value, style: TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _changeTtsLanguage(value);
                }
              },
            ),

            SizedBox(height: 16),

            // Voice Selection (only show if voices available for selected language)
            if (_getVoicesForLanguage(_selectedLanguage).isNotEmpty) ...[
              Text('Voice', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final availableVoices = _getVoicesForLanguage(_selectedLanguage);
                  final availableVoiceNames = availableVoices.map((v) => v['name'] as String).toList();

                  // Validate that _selectedVoice exists in available voices, otherwise set to null
                  final validatedVoice = (_selectedVoice != null && availableVoiceNames.contains(_selectedVoice))
                      ? _selectedVoice
                      : null;

                  return DropdownButtonFormField<String>(
                    initialValue: validatedVoice,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: Text('Select Voice', style: TextStyle(fontSize: 14)),
                    items: availableVoices.map((voice) {
                      final voiceName = voice['name'] as String;
                      return DropdownMenuItem(
                        value: voiceName,
                        child: Text(voiceName, style: TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _changeTtsVoice(value);
                      }
                    },
                  );
                },
              ),
              SizedBox(height: 16),
            ],

            // Speed control
            Text('Speech Speed: ${(_ttsRate * 100).round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Slider(
              value: _ttsRate,
              min: 0.1,
              max: 1.0,
              divisions: 18,
              onChanged: (value) {
                setState(() => _ttsRate = value);
              },
              onChangeEnd: (value) => _changeTtsRate(value),
            ),

            SizedBox(height: 12),

            // Pitch control
            Text('Voice Pitch: ${(_ttsPitch * 100).round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Slider(
              value: _ttsPitch,
              min: 0.5,
              max: 2.0,
              divisions: 30,
              onChanged: (value) {
                setState(() => _ttsPitch = value);
              },
              onChangeEnd: (value) => _changeTtsPitch(value),
            ),

            SizedBox(height: 16),

            // TTS Test Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    String testText;
                    if (_selectedLanguage.startsWith('hi')) {
                      testText = 'यह एक परीक्षण है।';
                    } else if (_selectedLanguage.startsWith('kn')) {
                      testText = 'ಇದು ಒಂದು ಪರೀಕ್ಷೆಯಾಗಿದೆ.';
                    } else if (_selectedLanguage.startsWith('de')) {
                      testText = 'Dies ist ein Test der Sprachausgabe.';
                    } else {
                      testText = 'This is a test of text-to-speech.';
                    }
                    await _flutterTts!.speak(testText);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('TTS test failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: Icon(Icons.play_arrow),
                label: Text('Test Voice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),

            // Font size control
            Text('Font Size: ${_fontSize.round()}'),
            Slider(
              value: _fontSize,
              min: 14.0,
              max: 28.0,
              divisions: 7,
              onChanged: (value) {
                setState(() => _fontSize = value);
              },
              onChangeEnd: (value) => _saveTtsSettings(),
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Text-to-Speech is initializing...'),
              ),
            ),
        ],
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
  // Add global navigator key to enable navigation from notifications
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        // Pass the navigator key for notification tap handling
        await NotificationService.initialize(context, navigatorKey: MyApp.navigatorKey);

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
      navigatorKey: MyApp.navigatorKey,
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
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('de'), Locale('kn')],
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
  final GlobalKey<BadgeWidgetState> _badgeKey = GlobalKey<BadgeWidgetState>();

  // Helper method to get saints list based on language
  List<dynamic> _getSaintsForLanguage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return saintsHi;
      case 'de':
        return saintsDe;
      case 'kn':
        return saintsKn;
      default:
        return saintsEn;
    }
  }

  void _refreshBadge() {
    _badgeKey.currentState?.refresh();
  }

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
    final languageCode = Localizations.localeOf(context).languageCode;
    final List<dynamic> saintList = _getSaintsForLanguage(languageCode);
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
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: BadgeWidget(key: _badgeKey, showDetails: false),
          ),
        ],
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
                  // Badge display in drawer
                  BadgeWidget(showDetails: true, userName: widget.userName),
                  Divider(
                    color: brightness == Brightness.dark
                        ? Colors.white24
                        : Colors.black12,
                    thickness: 1,
                    height: 1,
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
                  _buildDrawerItem(context, Icons.notifications_active, loc.setDailyNotifications, () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationSettingsPage()),
                    );
                  }),
                  // Only show "Buy me a coffee" option on Android
                  if (Platform.isAndroid)
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
                    ).then((_) => _refreshBadge()),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: brightness == Brightness.dark
                                  ? Colors.orange.shade900
                                  : Colors.deepOrange.shade50,
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
                              color: brightness == Brightness.dark
                                  ? Colors.orange.shade300
                                  : Colors.deepOrange.shade700,
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
                              color: brightness == Brightness.dark
                                  ? Colors.orange.shade900
                                  : Colors.deepOrange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: brightness == Brightness.dark
                                  ? Colors.orange.shade300
                                  : Colors.deepOrange.shade700,
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
                    color: brightness == Brightness.dark
                        ? Colors.orange.shade300
                        : Colors.deepOrange.shade800,
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
                          colors: brightness == Brightness.dark
                              ? [
                                  Colors.grey.shade800,
                                  Colors.grey.shade900,
                                ]
                              : [
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
                        ).then((_) => _refreshBadge()),
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
                                  color: brightness == Brightness.dark
                                      ? Colors.orange.shade300
                                      : Colors.deepOrange.shade800,
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
            _buildLanguageOption(loc.german, Locale('de'), context),
            _buildLanguageOption(loc.kannada, Locale('kn'), context),
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

// Custom painter for mindmap connecting lines
class MindMapLinesPainter extends CustomPainter {
  final bool isDark;

  MindMapLinesPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.deepOrange.withOpacity(0.5)
          : Colors.deepOrange.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw lines from center to top options (Quotes and Articles)
    // Top left (Quotes)
    canvas.drawLine(
      Offset(centerX, centerY - 30),
      Offset(centerX - 80, 40),
      paint,
    );

    // Top right (Articles)
    canvas.drawLine(
      Offset(centerX, centerY - 30),
      Offset(centerX + 80, 40),
      paint,
    );

    // Draw lines from center to bottom options (Ask AI, History, Books)
    // Bottom left (Ask AI)
    canvas.drawLine(
      Offset(centerX, centerY + 30),
      Offset(centerX - 110, size.height - 40),
      paint,
    );

    // Bottom center (History)
    canvas.drawLine(
      Offset(centerX, centerY + 30),
      Offset(centerX, size.height - 40),
      paint,
    );

    // Bottom right (Books)
    canvas.drawLine(
      Offset(centerX, centerY + 30),
      Offset(centerX + 110, size.height - 40),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    _markInitialQuoteAsRead();
  }

  Future<void> _markInitialQuoteAsRead() async {
    // Mark the initial quote as read when the page opens
    final quote = widget.quotes[widget.initialIndex];
    final id = _quoteId(quote);
    final wasAlreadyRead = await ReadStatusService.wasQuoteRead(id);
    await ReadStatusService.markQuoteRead(id);
    setState(() {
      _readQuotes.add(id);
    });
    // Award points only if this is the first time reading
    if (!wasAlreadyRead) {
      await BadgeService.awardQuotePoints();
    }
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
    final languageCode = Localizations.localeOf(context).languageCode;
    String saintNameForId;

    // Get saint name from appropriate language list
    List<dynamic> saintsList;
    switch (languageCode) {
      case 'hi':
        saintsList = saintsHi;
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

    if (languageCode != 'en') {
      final saint = saintsList.firstWhere((s) => s.id == widget.saintId, orElse: () => saintsList[0] as Saint);
      saintNameForId = saint.name;
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

      // Award points for sharing (distribution of knowledge)
      await BadgeService.awardSharePoints();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.stars, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Quote shared! +${BadgeService.POINTS_SHARE_QUOTE} points earned! 🎉'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share quote')),
      );
    }
  }

  Future<void> _copyQuote(String quote) async {
    final textToCopy = '"$quote"\n\n— ${widget.saintName}';

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
            final wasAlreadyRead = await ReadStatusService.wasQuoteRead(id);
            await ReadStatusService.markQuoteRead(id);
            setState(() {
              _readQuotes.add(id);
            });
            // Award points only if this is the first time reading
            if (!wasAlreadyRead) {
              await BadgeService.awardQuotePoints();
            }
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
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionButton(
                          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          label: isBookmarked ? 'Bookmarked' : 'Bookmark',
                          onPressed: () => _toggleBookmark(quote),
                          color: isBookmarked ? Colors.orange : Colors.grey,
                        ),
                        _buildActionButton(
                          icon: Icons.copy,
                          label: 'Copy',
                          onPressed: () => _copyQuote(quote),
                          color: Colors.green,
                        ),
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

class _SaintPageState extends State<SaintPage> {
  late Database db;
  List<Map<String, dynamic>> history = [];
  bool _useHindi = false;

  // Helper function to get English saint name based on saint ID
  String getEnglishSaintName(String saintId) {
    // Handle the special "ALL" case
    if (saintId == "ALL") {
      return "All";
    }

    final englishSaint = saintsEn.firstWhere(
      (saint) => saint.id == saintId,
      orElse: () => saintsEn[0] as Saint, // fallback to first saint if not found
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(saintName),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    Colors.grey.shade900,
                    Colors.grey.shade800,
                    Colors.grey.shade900,
                  ]
                : [
                    Colors.orange.shade50,
                    Colors.white,
                    Colors.orange.shade50,
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                SizedBox(height: 20),

                // Top row - 2 options (Quotes and Articles)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMindMapOption(
                        context: context,
                        icon: Icons.format_quote,
                        label: loc.quotes,
                        color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
                        onTap: () => _navigateToTab(context, 0, loc),
                      ),
                      _buildMindMapOption(
                        context: context,
                        icon: Icons.article,
                        label: loc.articles,
                        color: isDark ? Colors.blue.shade300 : Colors.blue,
                        onTap: () => _navigateToTab(context, 1, loc),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Center - Saint Image with decorative lines
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Connecting lines
                    CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 280),
                      painter: MindMapLinesPainter(isDark: isDark),
                    ),

                    // Saint Image
                    Hero(
                      tag: 'saint_${saintId}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(isDark ? 0.6 : 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.grey.shade700 : Colors.white,
                            width: 5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundImage: AssetImage(saintImage),
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                        ),
                      ),
                    ),

                    // Saint name badge below image
                    Positioned(
                      bottom: 20,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [Colors.deepOrange.shade400, Colors.orange.shade300]
                                : [Colors.deepOrange, Colors.orange],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(isDark ? 0.5 : 0.4),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          saintName,
                          style: GoogleFonts.playfairDisplay(
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 30),

                // Bottom row - 3 options (Ask AI, History, Books)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMindMapOption(
                        context: context,
                        icon: Icons.chat_bubble_outline,
                        label: loc.ask,
                        color: isDark ? Colors.green.shade300 : Colors.green,
                        onTap: () => _navigateToTab(context, 2, loc),
                      ),
                      _buildMindMapOption(
                        context: context,
                        icon: Icons.history,
                        label: loc.history,
                        color: isDark ? Colors.orange.shade300 : Colors.orange,
                        onTap: () => _navigateToTab(context, 3, loc),
                      ),
                      _buildMindMapOption(
                        context: context,
                        icon: Icons.menu_book,
                        label: 'Books',
                        color: isDark ? Colors.red.shade300 : Colors.red,
                        onTap: () => _navigateToTab(context, 4, loc),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMindMapOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 100,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.4 : 0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(isDark ? 0.5 : 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [color.withOpacity(0.7), color.withOpacity(0.9)]
                      : [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(isDark ? 0.5 : 0.4),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(BuildContext context, int tabIndex, AppLocalizations loc) {
    final saintId = widget.saint.id;
    final saintName = widget.saint.name;
    final saintImage = widget.saint.image;
    final saintQuotes = widget.saint.quotes;
    final saintArticles = widget.saint.articles;

    Widget page;
    String title;

    switch (tabIndex) {
      case 0:
        page = QuotesTab(
          quotes: saintQuotes,
          image: saintImage,
          saintName: saintName,
          saintId: saintId,
        );
        title = loc.quotes;
        break;
      case 1:
        page = ArticlesTab(
          articles: saintArticles as List<Article>,
        );
        title = loc.articles;
        break;
      case 2:
        page = AskTab(
          onSubmit: (q, a) => _addQnA(q, a),
          saintId: saintId,
          userName: widget.userName,
        );
        title = loc.ask;
        break;
      case 3:
        page = HistoryTab(history: history);
        title = loc.history;
        break;
      case 4:
        page = BooksTab(saintId: saintId, saintName: saintName);
        title = 'Books';
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('$saintName - $title'),
          ),
          body: page,
        ),
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
    final languageCode = Localizations.localeOf(context).languageCode;
    String saintNameForId;

    // Get saint name from appropriate language list
    List<dynamic> saintsList;
    switch (languageCode) {
      case 'hi':
        saintsList = saintsHi;
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

    if (languageCode != 'en') {
      // Find the saint name in the current language using the saint ID
      final saint = saintsList.firstWhere((s) => s.id == widget.saintId, orElse: () => saintsList[0] as Saint);
      saintNameForId = saint.name;
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
    final brightness = Theme.of(context).brightness;
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
          colors: brightness == Brightness.dark
              ? [Colors.grey.shade900, Colors.black]
              : [Colors.deepOrange.shade50, Colors.white],
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
                    colors: brightness == Brightness.dark
                        ? (isRead
                            ? [Colors.grey.shade800, Colors.grey.shade900]
                            : [Colors.grey.shade800, Colors.grey.shade800])
                        : (isRead
                            ? [Colors.white, Colors.grey.shade50]
                            : [Colors.white, Colors.orange.shade50]),
                  ),
                  border: isRead
                      ? null
                      : Border.all(
                          color: brightness == Brightness.dark
                              ? Colors.orange.shade700
                              : Colors.deepOrange.shade100,
                          width: 1,
                        ),
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
                                  color: brightness == Brightness.dark
                                      ? (isRead
                                          ? Colors.grey.shade400
                                          : Colors.orange.shade300)
                                      : (isRead
                                          ? Colors.grey.shade700
                                          : Colors.deepOrange.shade800),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: brightness == Brightness.dark
                                    ? (isBookmarked
                                        ? Colors.orange.shade900
                                        : Colors.grey.shade800)
                                    : (isBookmarked
                                        ? Colors.orange.shade100
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                  color: brightness == Brightness.dark
                                      ? (isBookmarked ? Colors.orange.shade300 : Colors.grey.shade400)
                                      : (isBookmarked ? Colors.orange.shade700 : Colors.grey.shade600),
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
              final wasAlreadyRead = await ReadStatusService.wasArticleRead(id);
              await ReadStatusService.markArticleRead(id);
              setState(() {
                _readArticles.add(id);
              });
              // Award points only if this is the first time reading
              if (!wasAlreadyRead) {
                await BadgeService.awardArticlePoints();
              }
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
    final languageCode = locale.languageCode;
    // Hindi has its own video, others use English video
    final expectedVideoId = languageCode == 'hi' ? '-xgEbJzLs5k' : '7OXjZOvLW0Y';

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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          loc.buyMeACoffee,
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
                          text: '☕ ${loc.buyMeACoffee}',
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
                                  final isHindi = Localizations.localeOf(context).languageCode == 'hi';
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
                                final isHindi = Localizations.localeOf(context).languageCode == 'hi';
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
                        Localizations.localeOf(context).languageCode == 'hi' ? loc.supportTextHi : loc.supportTextEn,
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

