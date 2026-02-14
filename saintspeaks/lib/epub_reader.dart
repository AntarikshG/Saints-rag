import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:epubx/epubx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_html/flutter_html.dart';
import 'book_service.dart';

class EpubReaderPage extends StatefulWidget {
  final Book book;

  EpubReaderPage({required this.book});

  @override
  _EpubReaderPageState createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  EpubBook? _epubBook;
  bool _isLoading = true;
  String _error = '';

  // Enhanced reading settings with better defaults
  double _fontSize = 18.0;
  Color _backgroundColor = const Color(0xFFFDF6E3); // Sepia background
  Color _textColor = const Color(0xFF3C3C3C); // Dark gray text
  String _fontFamily = 'System Default';
  double _lineHeight = 1.6;
  double _brightness = 1.0;
  bool _isDarkTheme = false;
  double _wordSpacing = 1.0;
  double _letterSpacing = 0.3;
  EdgeInsets _textPadding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0);
  TextAlign _textAlign = TextAlign.left; // Default to left alignment for better readability

  // Theme presets
  Map<String, Map<String, dynamic>> _themePresets = {
    'light': {
      'backgroundColor': const Color(0xFFFFFFFF),
      'textColor': const Color(0xFF2C2C2C),
      'name': 'Light'
    },
    'sepia': {
      'backgroundColor': const Color(0xFFFDF6E3),
      'textColor': const Color(0xFF3C3C3C),
      'name': 'Sepia'
    },
    'dark': {
      'backgroundColor': const Color(0xFF1E1E1E),
      'textColor': const Color(0xFFE0E0E0),
      'name': 'Dark'
    },
    'night': {
      'backgroundColor': const Color(0xFF000000),
      'textColor': const Color(0xFFB0B0B0),
      'name': 'Night'
    },
  };

  String _currentTheme = 'sepia';

  // Optimized page-by-page navigation
  List<String> _chapters = [];
  int _currentChapterIndex = 0;
  List<EpubChapter> _epubChapters = [];
  bool _showControls = false;
  bool _showSettings = false;

  // Chapter-to-page mapping for accurate navigation
  Map<int, String> _chapterContent = {};
  List<String> _chapterTitles = [];
  Map<String, int> _filenameToChapterIndex = {}; // Map filename to chapter index for link navigation
  ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0.0;

  // Performance optimization variables
  Timer? _progressSaveTimer;
  bool _hasUnsavedProgress = false;

  // Search
  TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _showSearchResults = false;

  // Bookmarks
  List<Bookmark> _bookmarks = [];

  // Text-to-Speech functionality
  FlutterTts? _flutterTts;
  bool _isTtsPlaying = false;
  bool _isTtsPaused = false;
  bool _isTtsInitialized = false;
  bool _showTtsControls = false; // Add this line
  double _ttsRate = 0.5;
  double _ttsPitch = 1.0;
  String _selectedLanguage = 'en-US';
  String? _selectedVoice; // Add selected voice variable
  List<dynamic> _availableLanguages = [];
  List<dynamic> _availableVoices = [];

  // Filtered TTS languages - English, Hindi, Kannada, Sanskrit, Tamil, Telugu, Malayalam, Marathi, and German variants
  final Map<String, String> _supportedTtsLanguages = {
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'en-IN': 'English (India)',
    'hi-IN': 'Hindi (India)',
    'kn-IN': 'Kannada (India)',
    'sa-IN': 'Sanskrit (India)',
    'ta-IN': 'Tamil (India)',
    'te-IN': 'Telugu (India)',
    'ml-IN': 'Malayalam (India)',
    'mr-IN': 'Marathi (India)',
    'de-DE': 'German (Germany)',
    'de-AT': 'German (Austria)',
    'de-CH': 'German (Switzerland)',
  };

  // Filtered voices based on supported languages
  List<Map<String, dynamic>> _filteredVoices = [];

  // TTS reading state - Enhanced for chunk-based reading
  // Enhanced TTS variables for chunk-based reading
  List<String> _textChunks = [];
  int _currentChunkIndex = 0;
  bool _isReadingChunks = false;
  Timer? _chunkTimer;

  // Enhanced TTS state management for pause/resume and position control
  int _savedChunkIndex = 0; // For resuming from paused position
  List<TextSpan> _highlightedTextSpans = []; // For highlighting current reading position

  // Add variables for better text synchronization
  Timer? _scrollSyncTimer; // Timer for delayed scroll synchronization

  // Available font options with both system and Google fonts
  Map<String, Map<String, dynamic>> _fontOptions = {
    'System Default': {'isSystemFont': true, 'fontFamily': null},
    'Serif': {'isSystemFont': true, 'fontFamily': 'serif'},
    'Times New Roman': {'isSystemFont': true, 'fontFamily': 'Times New Roman'},
    'Merriweather': {'isSystemFont': false, 'fontFamily': 'Merriweather'},
    'Crimson Text': {'isSystemFont': false, 'fontFamily': 'Crimson Text'},
    'Libre Baskerville': {'isSystemFont': false, 'fontFamily': 'Libre Baskerville'},
    'Source Serif Pro': {'isSystemFont': false, 'fontFamily': 'Source Serif Pro'},
    'Lora': {'isSystemFont': false, 'fontFamily': 'Lora'},
    // Add fonts that support Hindi/Devanagari
    'Noto Sans': {'isSystemFont': false, 'fontFamily': 'Noto Sans'},
    'Noto Serif': {'isSystemFont': false, 'fontFamily': 'Noto Serif'},
    'Mukti': {'isSystemFont': false, 'fontFamily': 'Mukti'},
    'Hind': {'isSystemFont': false, 'fontFamily': 'Hind'},
    'Poppins': {'isSystemFont': false, 'fontFamily': 'Poppins'},
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBookmarks();
    _loadBook();
    _currentChapterIndex = widget.book.currentChapter;


    // Set immersive mode for better reading experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Listen to scroll changes for better progress tracking
    _scrollController.addListener(() {
      _scrollPosition = _scrollController.offset;
      _saveReadingProgressDebounced();
    });

    // Initialize Text-to-Speech after the first frame is rendered
    // This ensures Flutter engine is fully initialized, especially important for iOS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flutterTts = FlutterTts();
      _initializeTts();
    });
  }

  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    _chunkTimer?.cancel(); // Clean up chunk timer
    if (_hasUnsavedProgress) {
      _saveReadingProgressImmediate();
    }
    // Dispose TTS resources
    if (_flutterTts != null) {
      _flutterTts!.stop();
      _flutterTts = null;
    }
    _searchController.dispose();
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadBook() async {
    try {
      if (widget.book.filePath.isEmpty) {
        throw Exception('Book file path is empty');
      }

      final file = File(widget.book.filePath);
      if (!await file.exists()) {
        throw Exception('Book file not found at: ${widget.book.filePath}');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Book file is empty');
      }

      print('Loading EPUB file: ${widget.book.filePath} (${fileSize} bytes)');

      final bytes = await file.readAsBytes();

      EpubBook? book;
      try {
        print('Parsing EPUB with epubx package...');
        book = await EpubReader.readBook(bytes);
        print('EPUB parsed successfully');
      } catch (epubError) {
        print('EPUB parsing error: $epubError');
        throw Exception('Invalid EPUB file format: $epubError');
      }

      if (book.Content == null) {
        throw Exception('EPUB file has no readable content');
      }

      setState(() {
        _epubBook = book;
        _isLoading = false;
      });

      await _extractChapters();
      await _loadLastReadPosition();

    } catch (e) {
      print('Exception loading EPUB: $e');
      setState(() {
        _error = 'Failed to load book: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _extractChapters() async {
    try {
      _chapters.clear();
      _chapterContent.clear();
      _chapterTitles.clear();
      _filenameToChapterIndex.clear(); // Clear the filename to chapter index map

      if (_epubBook!.Chapters != null && _epubBook!.Chapters!.isNotEmpty) {
        _epubChapters = _epubBook!.Chapters!;
        print('Found ${_epubChapters.length} chapters in EPUB');

        for (int i = 0; i < _epubChapters.length; i++) {
          final chapter = _epubChapters[i];
          final title = chapter.Title ?? 'Chapter ${i + 1}';
          _chapterTitles.add(title);

          final htmlContent = chapter.HtmlContent ?? '';
          final preparedContent = _prepareHtmlContent(htmlContent);
          _chapterContent[i] = preparedContent;

          // Map chapter filename to index for link navigation
          // Try multiple approaches to get the filename
          List<String> possibleFilenames = [];

          // Approach 1: Try Anchor property if it exists
          try {
            if (chapter.Anchor != null && chapter.Anchor!.isNotEmpty) {
              possibleFilenames.add(chapter.Anchor!);
            }
          } catch (e) {
            // Anchor property might not exist
          }

          // Approach 2: Try to extract from SubChapters if they exist
          try {
            if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
              for (var subChapter in chapter.SubChapters!) {
                if (subChapter.Anchor != null && subChapter.Anchor!.isNotEmpty) {
                  possibleFilenames.add(subChapter.Anchor!);
                }
              }
            }
          } catch (e) {
            // SubChapters might not exist
          }

          // Approach 3: Default filename
          possibleFilenames.add('chapter_${i + 1}');
          possibleFilenames.add('Chapter${i + 1}');
          possibleFilenames.add('ch${i + 1}');
          possibleFilenames.add('chap${i + 1}');

          // Map all possible filenames to this chapter index
          for (String filename in possibleFilenames) {
            _filenameToChapterIndex[filename] = i;
          }

          print('Mapped chapter $i with ${possibleFilenames.length} filename variations: ${possibleFilenames.join(", ")}');
        }
      } else {
        // Fallback: extract from HTML files
        if (_epubBook!.Content?.Html?.isNotEmpty == true) {
          final htmlFiles = _epubBook!.Content!.Html!;
          int chapterIndex = 0;

          for (final htmlFile in htmlFiles.entries) {
            try {
              final htmlContentFile = htmlFile.value;
              final htmlContent = htmlContentFile.Content ?? '';
              if (htmlContent.isNotEmpty) {
                _chapterTitles.add('Chapter ${chapterIndex + 1}');
                final preparedContent = _prepareHtmlContent(htmlContent);
                _chapterContent[chapterIndex] = preparedContent;
                chapterIndex++;

                // Map chapter filename to index for link navigation
                _filenameToChapterIndex[htmlFile.key] = chapterIndex - 1;
              }
            } catch (e) {
              print('Error processing HTML file ${htmlFile.key}: $e');
              continue;
            }
          }
        }
      }

      if (_chapterContent.isEmpty) {
        _chapterTitles.add('Error Page');
        _chapterContent[0] = 'Unable to extract readable content from this EPUB file.';
      }

      print('Extracted ${_chapterContent.length} chapters successfully');

    } catch (e) {
      print('Error extracting chapters: $e');
      _chapterTitles.add('Error Page');
      _chapterContent[0] = 'Error processing book content: ${e.toString()}';
    }
  }

  String _prepareHtmlContent(String html) {
    if (html.isEmpty) return '<p>No content available</p>';

    try {
      // Only remove scripts and comments for security, preserve all formatting
      String prepared = html
          .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, multiLine: true, dotAll: true), '')
          .replaceAll(RegExp(r'<!--.*?-->', multiLine: true, dotAll: true), '');

      // Wrap content in a div for proper styling if not already wrapped
      if (!prepared.trim().startsWith('<')) {
        prepared = '<div>$prepared</div>';
      }

      print('HTML content prepared: ${html.length} chars -> ${prepared.length} chars');
      return prepared;

    } catch (e) {
      print('Error preparing HTML content: $e');
      return '<p>Error processing content: ${e.toString()}</p>';
    }
  }

  // Extract plain text from HTML for TTS
  String _extractPlainTextFromHtml(String html) {
    if (html.isEmpty) return '';

    try {
      String text = html;

      // Remove scripts, styles, and comments
      text = text
          .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, multiLine: true, dotAll: true), '')
          .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, multiLine: true, dotAll: true), '')
          .replaceAll(RegExp(r'<!--.*?-->', multiLine: true, dotAll: true), '');

      // Handle block elements - replace with newlines
      text = text
          .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
          .replaceAll(RegExp(r'<br[^>]*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
          .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');

      // Remove ALL remaining HTML tags
      text = text.replaceAll(RegExp(r'<[^>]+>'), '');

      // Decode HTML entities
      text = text
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&apos;', "'")
          .replaceAll('&mdash;', '—')
          .replaceAll('&ndash;', '–')
          .replaceAll('&hellip;', '…')
          .replaceAll('&lsquo;', ''')
          .replaceAll('&rsquo;', ''')
          .replaceAll('&ldquo;', '"')
          .replaceAll('&rdquo;', '"');

      // Clean up whitespace
      text = text
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .replaceAll(RegExp(r' *\n *'), '\n')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();

      return text;
    } catch (e) {
      print('Error extracting plain text from HTML: $e');
      return '';
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Existing settings
      _fontSize = prefs.getDouble('epub_font_size') ?? 18.0;
      _fontFamily = prefs.getString('epub_font_family') ?? 'System Default';
      _lineHeight = prefs.getDouble('epub_line_height') ?? 1.6;
      _brightness = prefs.getDouble('epub_brightness') ?? 1.0;
      _wordSpacing = prefs.getDouble('epub_word_spacing') ?? 1.0;
      _letterSpacing = prefs.getDouble('epub_letter_spacing') ?? 0.3;
      _currentTheme = prefs.getString('epub_theme') ?? 'sepia';

      // Load text alignment preference
      final alignmentString = prefs.getString('epub_text_align') ?? 'left';
      _textAlign = _parseTextAlign(alignmentString);

      // TTS settings - load from saved preferences
      _ttsRate = prefs.getDouble('epub_tts_rate') ?? 0.5;
      _ttsPitch = prefs.getDouble('epub_tts_pitch') ?? 1.0;
      _selectedLanguage = prefs.getString('epub_tts_language') ?? 'en-US';
      _selectedVoice = prefs.getString('epub_tts_voice');

      // IMPORTANT: Always reset text padding to default for each book
      // This prevents width shrinkage issues when switching between books
      _textPadding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0);

      // Add UI preferences
      _showTtsControls = prefs.getBool('epub_show_tts_controls') ?? false;

      _applyTheme(_currentTheme);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Existing settings
    await prefs.setDouble('epub_font_size', _fontSize);
    await prefs.setString('epub_font_family', _fontFamily);
    await prefs.setDouble('epub_line_height', _lineHeight);
    await prefs.setDouble('epub_brightness', _brightness);
    await prefs.setDouble('epub_word_spacing', _wordSpacing);
    await prefs.setDouble('epub_letter_spacing', _letterSpacing);
    await prefs.setString('epub_theme', _currentTheme);

    // Save text alignment preference
    await prefs.setString('epub_text_align', _textAlignToString(_textAlign));

    // TTS settings - save to preferences
    await prefs.setDouble('epub_tts_rate', _ttsRate);
    await prefs.setDouble('epub_tts_pitch', _ttsPitch);
    await prefs.setString('epub_tts_language', _selectedLanguage);
    if (_selectedVoice != null) {
      await prefs.setString('epub_tts_voice', _selectedVoice!);
    }

    // Add text padding settings (corrected - don't divide by 2)
    await prefs.setDouble('epub_padding_horizontal', _textPadding.horizontal);
    await prefs.setDouble('epub_padding_vertical', _textPadding.vertical);

    // Add UI preferences
    await prefs.setBool('epub_show_tts_controls', _showTtsControls);
  }

  void _applyTheme(String themeName) {
    if (_themePresets.containsKey(themeName)) {
      final theme = _themePresets[themeName]!;
      setState(() {
        _currentTheme = themeName;
        _backgroundColor = theme['backgroundColor'] as Color;
        _textColor = theme['textColor'] as Color;
        _isDarkTheme = themeName == 'dark' || themeName == 'night';
      });
      _saveSettings();
    }
  }

  Future<void> _loadLastReadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedChapterIndex = prefs.getInt('last_chapter_${widget.book.id}') ?? 0;
    final savedScrollPosition = prefs.getDouble('last_scroll_${widget.book.id}') ?? 0.0;

    setState(() {
      _currentChapterIndex = savedChapterIndex.clamp(0, _chapterContent.length - 1);
    });

    // Restore scroll position after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(savedScrollPosition);
      }
    });
  }

  Future<void> _saveLastReadPosition() async {
    if (widget.book.id != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_chapter_${widget.book.id}', _currentChapterIndex);
      await prefs.setDouble('last_scroll_${widget.book.id}', _scrollPosition);
    }
  }

  Future<void> _loadBookmarks() async {
    if (widget.book.id != null) {
      _bookmarks = await BookService.getBookmarks(widget.book.id!);
      setState(() {});
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      _showSettings = false;
      _showSearchResults = false;
    });
  }

  void _nextChapter() {
    if (_currentChapterIndex < _chapterContent.length - 1) {
      // Stop TTS if playing and clear highlighting
      if (_isTtsPlaying || _isTtsPaused) {
        _stopTtsReading();
      }

      setState(() {
        _currentChapterIndex++;
      });
      // Scroll to top of new chapter
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
      _saveReadingProgressDebounced();
    }
  }

  void _previousChapter() {
    if (_currentChapterIndex > 0) {
      // Stop TTS if playing and clear highlighting
      if (_isTtsPlaying || _isTtsPaused) {
        _stopTtsReading();
      }

      setState(() {
        _currentChapterIndex--;
      });
      // Scroll to top of new chapter
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
      _saveReadingProgressDebounced();
    }
  }

  void _addBookmark() async {
    if (widget.book.id != null) {
      final bookmark = Bookmark(
        chapterIndex: _currentChapterIndex,
        chapterTitle: _chapterTitles[_currentChapterIndex],
        position: _scrollPosition,
        createdAt: DateTime.now(),
      );

      await BookService.addBookmark(widget.book.id!, bookmark);
      await _loadBookmarks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bookmark added!'),
            backgroundColor: _isDarkTheme ? Colors.grey[800] : Colors.green,
          ),
        );
      }
    }
  }

  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _isDarkTheme
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.orange.shade800, Colors.orange.shade900],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.orange.shade400, Colors.orange.shade600],
                      ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmarks, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bookmarks',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _bookmarks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: (_isDarkTheme ? Colors.orange : Colors.orange.shade100).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.bookmark_border,
                              size: 64,
                              color: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No bookmarks yet',
                            style: _getTextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _textColor.withAlpha((0.7 * 255).round()),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              'Tap the bookmark button to save your current reading position',
                              textAlign: TextAlign.center,
                              style: _getTextStyle(
                                fontSize: 14,
                                color: _textColor.withAlpha((0.5 * 255).round()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _bookmarks.length,
                      itemBuilder: (context, index) {
                        final bookmark = _bookmarks[index];
                        final isCurrentPosition = bookmark.chapterIndex == _currentChapterIndex;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: isCurrentPosition
                                ? LinearGradient(
                                    colors: _isDarkTheme
                                        ? [Colors.orange.shade900.withOpacity(0.3), Colors.orange.shade800.withOpacity(0.2)]
                                        : [Colors.orange.shade50, Colors.orange.shade100],
                                  )
                                : null,
                            color: isCurrentPosition ? null : (_isDarkTheme ? Colors.grey[850] : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrentPosition
                                  ? Colors.orange
                                  : _textColor.withOpacity(0.1),
                              width: isCurrentPosition ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isCurrentPosition
                                    ? Colors.orange.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: isCurrentPosition ? 8 : 4,
                                offset: Offset(0, isCurrentPosition ? 4 : 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: isCurrentPosition
                                    ? LinearGradient(
                                        colors: [Colors.orange.shade400, Colors.orange.shade600],
                                      )
                                    : null,
                                color: isCurrentPosition ? null : (_isDarkTheme ? Colors.grey[700] : Colors.grey[300]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.bookmark,
                                color: isCurrentPosition ? Colors.white : _textColor.withOpacity(0.7),
                                size: 24,
                              ),
                            ),
                            title: Text(
                              bookmark.chapterTitle,
                              style: _getTextStyle(
                                fontWeight: isCurrentPosition ? FontWeight.bold : FontWeight.w500,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.menu_book,
                                      size: 14,
                                      color: _textColor.withAlpha((0.6 * 255).round()),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Chapter ${bookmark.chapterIndex + 1}',
                                      style: _getTextStyle(
                                        fontSize: 12,
                                        color: _textColor.withAlpha((0.7 * 255).round()),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: _textColor.withAlpha((0.6 * 255).round()),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(bookmark.createdAt),
                                      style: _getTextStyle(
                                        fontSize: 12,
                                        color: _textColor.withAlpha((0.6 * 255).round()),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'delete' && bookmark.id != null) {
                                  await _deleteBookmark(bookmark.id!);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                              icon: Icon(
                                Icons.more_vert,
                                color: _textColor.withAlpha((0.6 * 255).round()),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _jumpToBookmark(bookmark);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _jumpToBookmark(Bookmark bookmark) {
    // Stop TTS if playing and clear highlighting
    if (_isTtsPlaying || _isTtsPaused) {
      _stopTtsReading();
    }

    setState(() {
      _currentChapterIndex = bookmark.chapterIndex.clamp(0, _chapterContent.length - 1);
    });

    // Navigate to bookmark position after chapter loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && bookmark.position > 0) {
        _scrollController.animateTo(
          bookmark.position,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    _saveReadingProgressDebounced();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigated to bookmark: ${bookmark.chapterTitle}'),
          backgroundColor: _isDarkTheme ? Colors.grey[800] : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteBookmark(int bookmarkId) async {
    await BookService.deleteBookmark(bookmarkId);
    await _loadBookmarks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bookmark deleted'),
          backgroundColor: _isDarkTheme ? Colors.grey[800] : Colors.red,
        ),
      );
    }
  }

  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _isDarkTheme
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey.shade800, Colors.grey.shade900],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
                      ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Table of Contents',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _chapterTitles.length,
                itemBuilder: (context, index) {
                  final isCurrentChapter = index == _currentChapterIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isCurrentChapter
                          ? LinearGradient(
                              colors: _isDarkTheme
                                  ? [Colors.orange.shade900.withOpacity(0.3), Colors.orange.shade800.withOpacity(0.2)]
                                  : [Colors.deepOrange.shade50, Colors.orange.shade50],
                            )
                          : null,
                      color: isCurrentChapter ? null : (_isDarkTheme ? Colors.grey[850] : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentChapter
                            ? (_isDarkTheme ? Colors.orange : Colors.deepOrange)
                            : _textColor.withOpacity(0.1),
                        width: isCurrentChapter ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isCurrentChapter
                              ? (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.2)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: isCurrentChapter ? 8 : 4,
                          offset: Offset(0, isCurrentChapter ? 4 : 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: isCurrentChapter
                              ? LinearGradient(
                                  colors: _isDarkTheme
                                      ? [Colors.orange.shade700, Colors.orange.shade900]
                                      : [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
                                )
                              : null,
                          color: isCurrentChapter ? null : (_isDarkTheme ? Colors.grey[700] : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrentChapter ? Colors.white : _textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        _chapterTitles[index],
                        style: TextStyle(
                          fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.w500,
                          color: _textColor,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isCurrentChapter
                          ? Icon(
                              Icons.play_circle_filled,
                              color: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                              size: 24,
                            )
                          : Icon(
                              Icons.chevron_right,
                              color: _textColor.withOpacity(0.5),
                            ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _jumpToChapter(index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _jumpToChapter(int chapterIndex) {
    final targetIndex = chapterIndex.clamp(0, _chapterContent.length - 1);

    // Stop TTS if playing and clear highlighting
    if (_isTtsPlaying || _isTtsPaused) {
      _stopTtsReading();
    }

    setState(() {
      _currentChapterIndex = targetIndex;
    });

    // Scroll to top of new chapter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });

    _saveReadingProgressDebounced();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _showSearchResults = false;
      });
      return;
    }

    final results = <SearchResult>[];
    final searchQuery = query.toLowerCase();

    for (int i = 0; i < _chapterContent.length; i++) {
      final content = _chapterContent[i]!.toLowerCase();
      final originalContent = _chapterContent[i]!;

      int index = content.indexOf(searchQuery);
      while (index != -1) {
        final start = (index - 50).clamp(0, content.length);
        final end = (index + searchQuery.length + 50).clamp(0, content.length);
        final excerpt = originalContent.substring(start, end);

        results.add(SearchResult(
          chapterIndex: i,
          chapterTitle: _chapterTitles[i],
          excerpt: '...$excerpt...',
          position: index,
        ));

        index = content.indexOf(searchQuery, index + 1);
      }
    }

    setState(() {
      _searchResults = results;
      _showSearchResults = true;
    });
  }

  // Handle EPUB internal link navigation
  void _handleLinkTap(String? url) {
    if (url == null || url.isEmpty) {
      print('Link tap: empty URL');
      return;
    }

    print('Link tapped: $url');

    try {
      // Parse the URL to extract filename and anchor
      String filename = url;
      String? anchor;

      // Remove any leading slash or path
      if (filename.contains('/')) {
        filename = filename.split('/').last;
      }

      // Split filename and anchor if present
      if (filename.contains('#')) {
        final parts = filename.split('#');
        filename = parts[0];
        if (parts.length > 1) {
          anchor = parts[1];
        }
      }

      print('Parsed - Filename: $filename, Anchor: $anchor');

      // Try to find the chapter by exact filename match
      int? targetChapterIndex = _filenameToChapterIndex[filename];

      // If no exact match, try partial matching (some EPUBs have different extensions or versions)
      if (targetChapterIndex == null) {
        // Try without extension
        final filenameWithoutExt = filename.replaceAll(RegExp(r'\.(html?|xhtml)$'), '');

        for (var entry in _filenameToChapterIndex.entries) {
          final key = entry.key;
          final keyWithoutExt = key.replaceAll(RegExp(r'\.(html?|xhtml)$'), '');

          if (key == filename ||
              keyWithoutExt == filenameWithoutExt ||
              key.contains(filenameWithoutExt) ||
              filenameWithoutExt.contains(keyWithoutExt)) {
            targetChapterIndex = entry.value;
            print('Found partial match: $key -> Chapter $targetChapterIndex');
            break;
          }
        }
      }

      if (targetChapterIndex != null &&
          targetChapterIndex >= 0 &&
          targetChapterIndex < _chapterContent.length) {
        // Navigate to the chapter using page flip animation
        _jumpToChapter(targetChapterIndex);

        // Show feedback
        final chapterTitle = _chapterTitles.isNotEmpty && targetChapterIndex < _chapterTitles.length
            ? _chapterTitles[targetChapterIndex]
            : 'Chapter ${targetChapterIndex + 1}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📖 Jumped to: $chapterTitle'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        print('✅ Successfully navigated to chapter $targetChapterIndex');
      } else {
        print('❌ Chapter not found for filename: $filename');
        print('Available filenames: ${_filenameToChapterIndex.keys.join(", ")}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find linked chapter: $filename'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error handling link: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error following link'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveReadingProgressImmediate() async {
    if (_chapterContent.isNotEmpty && widget.book.id != null) {
      final progress = (_currentChapterIndex + 1) / _chapterContent.length;
      await BookService.updateReadingProgress(
        widget.book.id!,
        _currentChapterIndex,
        progress.clamp(0.0, 1.0),
      );
      await _saveLastReadPosition();
      _hasUnsavedProgress = false;
    }
  }

  void _saveReadingProgressDebounced() {
    _hasUnsavedProgress = true;
    _progressSaveTimer?.cancel();

    _progressSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveReadingProgressImmediate();
    });
  }

  // Helper method to get TextStyle with proper font handling
  TextStyle _getTextStyle({
    required double fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? height,
    double? wordSpacing,
    double? letterSpacing,
  }) {
    final fontOption = _fontOptions[_fontFamily];

    if (fontOption == null || fontOption['isSystemFont'] == true) {
      // Use system font
      return TextStyle(
        fontSize: fontSize,
        color: color ?? _textColor,
        fontWeight: fontWeight,
        height: height ?? _lineHeight,
        wordSpacing: wordSpacing ?? _wordSpacing,
        letterSpacing: letterSpacing ?? _letterSpacing,
        fontFamily: fontOption?['fontFamily'],
      );
    } else {
      // Use Google Font
      try {
        return GoogleFonts.getFont(
          fontOption['fontFamily'],
          fontSize: fontSize,
          color: color ?? _textColor,
          fontWeight: fontWeight,
          height: height ?? _lineHeight,
          wordSpacing: wordSpacing ?? _wordSpacing,
          letterSpacing: letterSpacing ?? _letterSpacing,
        );
      } catch (e) {
        // Fallback to system font if Google Font fails
        return TextStyle(
          fontSize: fontSize,
          color: color ?? _textColor,
          fontWeight: fontWeight,
          height: height ?? _lineHeight,
          wordSpacing: wordSpacing ?? _wordSpacing,
          letterSpacing: letterSpacing ?? _letterSpacing,
        );
      }
    }
  }

  // Helper methods to convert TextAlign to/from String for SharedPreferences
  String _textAlignToString(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return 'left';
      case TextAlign.right:
        return 'right';
      case TextAlign.center:
        return 'center';
      case TextAlign.justify:
        return 'justify';
      default:
        return 'left';
    }
  }

  TextAlign _parseTextAlign(String alignString) {
    switch (alignString) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  // Get filtered TTS languages (only US, IN, UK)
  List<String> _getFilteredLanguages() {
    final allowedLanguages = ['en-US', 'en-IN', 'en-GB'];
    final filtered = <String>[];

    for (var language in _availableLanguages) {
      final langStr = language.toString();
      if (allowedLanguages.contains(langStr)) {
        filtered.add(langStr);
      }
    }

    // If no filtered languages found, add defaults
    if (filtered.isEmpty) {
      filtered.addAll(allowedLanguages);
    }

    return filtered;
  }

  Future<void> _initializeTts() async {
    try {
      print('TTS: Initializing Text-to-Speech...');

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

            // Start a timer to continue with next chunk (small delay for stability)
            _chunkTimer = Timer(Duration(milliseconds: 500), () {
              if (_isReadingChunks && _isTtsPlaying) {
                _speakCurrentChunk();
              }
            });
          } else {
            // Finished reading entire chapter
            print('TTS: Finished reading entire chapter');
            setState(() {
              _isTtsPlaying = false;
              _isTtsPaused = false;
              _isReadingChunks = false;
              _currentChunkIndex = 0;
              _highlightedTextSpans.clear(); // Clear highlighting when finished
            });

            // Show completion message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Finished reading chapter: ${_chapterTitles.isNotEmpty ? _chapterTitles[_currentChapterIndex] : 'Chapter ${_currentChunkIndex + 1}'}'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      });

      _flutterTts!.setCancelHandler(() {
        print('TTS: Cancelled speaking');
        if (mounted) {
          setState(() {
            _isTtsPlaying = false;
            _isTtsPaused = false;
            _highlightedTextSpans.clear(); // Clear highlighting when cancelled
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
            _highlightedTextSpans.clear(); // Clear highlighting on error
          });

          String errorMessage = 'Text-to-Speech Error';
          if (msg.toString().contains('-8')) {
            errorMessage = 'TTS synthesis error. Try changing language or restart app.';
          } else if (msg.toString().contains('-5')) {
            errorMessage = 'TTS language not supported. Please install TTS data.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _reinitializeTts(),
              ),
            ),
          );
        }
      });

      // Get available languages and voices
      _availableLanguages = await _flutterTts!.getLanguages;
      _availableVoices = await _flutterTts!.getVoices;

      print('TTS: Available languages: $_availableLanguages');
      print('TTS: Available voices: ${_availableVoices.length}');

      // Filter voices for supported languages only
      _filterVoicesForSupportedLanguages();

      // Ensure selected language is supported
      if (!_supportedTtsLanguages.containsKey(_selectedLanguage)) {
        _selectedLanguage = 'en-US'; // Default to US English
      }

      // Set default TTS settings
      await _flutterTts!.setLanguage(_selectedLanguage);
      await _flutterTts!.setSpeechRate(_ttsRate);
      await _flutterTts!.setPitch(_ttsPitch);

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

  void _filterVoicesForSupportedLanguages() {
    _filteredVoices.clear();

    for (var voice in _availableVoices) {
      try {
        // Safely convert Map<Object?, Object?> to Map<String, dynamic>
        final voiceData = Map<String, dynamic>.from(voice as Map);
        final locale = voiceData['locale']?.toString() ?? '';

        // Only include voices for our supported languages
        if (_supportedTtsLanguages.containsKey(locale)) {
          _filteredVoices.add({
            'name': voiceData['name']?.toString() ?? 'Default',
            'locale': locale,
          });
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
        await _saveSettings(); // Save TTS settings

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
          await _saveSettings(); // Save TTS settings

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('TTS voice changed to $voiceName'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error changing TTS voice: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change TTS voice'),
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
        await _saveSettings(); // Save TTS settings
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
        await _saveSettings(); // Save TTS settings
      } catch (e) {
        print('Error changing TTS pitch: $e');
      }
    }
  }

  // Missing TTS methods implementation
  Future<void> _speakCurrentChunk() async {
    if (_flutterTts == null || !_isTtsInitialized || _textChunks.isEmpty) {
      print('TTS: Cannot speak - not initialized or no chunks available');
      return;
    }

    if (_currentChunkIndex >= _textChunks.length) {
      print('TTS: No more chunks to speak');
      return;
    }

    try {
      final chunk = _textChunks[_currentChunkIndex];
      print('TTS: Speaking chunk ${_currentChunkIndex + 1}/${_textChunks.length}');

      // Update highlighting to show current chunk
      _updateTextHighlighting();

      await _flutterTts!.speak(chunk);
    } catch (e) {
      print('TTS: Error speaking chunk: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('TTS Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reinitializeTts() async {
    print('TTS: Reinitializing Text-to-Speech...');

    setState(() {
      _isTtsInitialized = false;
      _isTtsPlaying = false;
      _isTtsPaused = false;
    });

    // Stop any ongoing TTS
    if (_flutterTts != null) {
      try {
        await _flutterTts!.stop();
      } catch (e) {
        print('TTS: Error stopping during reinitialization: $e');
      }
    }

    // Recreate TTS instance
    _flutterTts = FlutterTts();

    // Reinitialize
    await _initializeTts();
  }

  void _previousTtsChunk() {
    if (_isReadingChunks && _currentChunkIndex > 0) {
      setState(() {
        _currentChunkIndex--;
      });

      // Stop current speech and speak previous chunk
      _flutterTts?.stop().then((_) {
        _speakCurrentChunk();
      });

      print('TTS: Moving to previous chunk ${_currentChunkIndex + 1}/${_textChunks.length}');
    }
  }

  Future<void> _pauseTtsReading() async {
    if (_flutterTts != null && _isTtsPlaying) {
      try {
        await _flutterTts!.pause();

        // Keep highlighting visible when paused
        // setState(() {
        //   _highlightedTextSpans.clear();
        // });

        print('TTS: Paused reading');
      } catch (e) {
        print('TTS: Error pausing: $e');
      }
    }
  }

  Future<void> _resumeTtsReading() async {
    if (_flutterTts != null && _isTtsPaused) {
      try {
        // Update highlighting before resuming
        _updateTextHighlighting();

        // For some TTS engines, we need to speak again instead of resume
        if (_isReadingChunks && _currentChunkIndex < _textChunks.length) {
          await _speakCurrentChunk();
        }
        print('TTS: Resumed reading');
      } catch (e) {
        print('TTS: Error resuming: $e');
        // Fallback: restart current chunk
        if (_isReadingChunks) {
          await _speakCurrentChunk();
        }
      }
    }
  }

  Future<void> _startTtsReading() async {
    if (_flutterTts == null || !_isTtsInitialized) {
      await _reinitializeTts();
      if (!_isTtsInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TTS not available. Please check your device settings.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Prepare text chunks from current chapter
    final currentHtmlContent = _chapterContent[_currentChapterIndex] ?? '';
    if (currentHtmlContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No text available to read'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Extract plain text from HTML for TTS
    final plainText = _extractPlainTextFromHtml(currentHtmlContent);
    if (plainText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No readable text found in chapter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Split content into chunks (by sentences or paragraphs)
    _textChunks = _splitTextIntoChunks(plainText);
    _currentChunkIndex = 0;

    setState(() {
      _isReadingChunks = true;
    });

    await _speakCurrentChunk();
    print('TTS: Started reading chapter with ${_textChunks.length} chunks');
  }

  Future<void> _stopTtsReading() async {
    if (_flutterTts != null) {
      try {
        await _flutterTts!.stop();

        // Cancel any pending chunk timers
        _chunkTimer?.cancel();

        setState(() {
          _isTtsPlaying = false;
          _isTtsPaused = false;
          _isReadingChunks = false;
          _currentChunkIndex = 0;
          _highlightedTextSpans.clear(); // Clear highlighting when stopping
        });

        print('TTS: Stopped reading');
      } catch (e) {
        print('TTS: Error stopping: $e');
      }
    }
  }

  // Method to update text highlighting for current chunk being read
  void _updateTextHighlighting() {
    if (!_isReadingChunks || _textChunks.isEmpty || _currentChunkIndex >= _textChunks.length) {
      setState(() {
        _highlightedTextSpans.clear();
      });
      return;
    }

    // Get the full text content
    final currentHtmlContent = _chapterContent[_currentChapterIndex] ?? '';
    final plainText = _extractPlainTextFromHtml(currentHtmlContent);

    if (plainText.isEmpty) {
      return;
    }

    // Create text spans with highlighting for current chunk
    List<TextSpan> spans = [];

    // Build the full text by iterating through chunks and marking the current one
    int textPosition = 0;

    for (int i = 0; i < _textChunks.length; i++) {
      final chunk = _textChunks[i].trim();
      if (chunk.isEmpty) continue;

      // Find the chunk in the remaining text
      final searchStart = textPosition;
      final chunkIndex = plainText.indexOf(chunk, searchStart);

      if (chunkIndex >= 0) {
        // Add any text before this chunk (if not already added)
        if (chunkIndex > textPosition) {
          final beforeText = plainText.substring(textPosition, chunkIndex);
          if (beforeText.trim().isNotEmpty) {
            spans.add(TextSpan(
              text: beforeText,
              style: _getTextStyle(fontSize: _fontSize),
            ));
          }
        }

        // Add the chunk with highlighting if it's the current one being read
        if (i == _currentChunkIndex) {
          spans.add(TextSpan(
            text: chunk,
            style: _getTextStyle(
              fontSize: _fontSize,
              color: _isDarkTheme ? Colors.black : Colors.white,
            ).copyWith(
              backgroundColor: _isDarkTheme ? Colors.yellow.shade400 : Colors.orange.shade300,
              fontWeight: FontWeight.w600,
              height: 1.8, // Increased line height for better visibility
            ),
          ));
        } else {
          spans.add(TextSpan(
            text: chunk,
            style: _getTextStyle(fontSize: _fontSize),
          ));
        }

        textPosition = chunkIndex + chunk.length;
      } else {
        // If chunk not found, skip it
        print('TTS: Warning - chunk $i not found in text');
      }
    }

    // Add any remaining text after all chunks
    if (textPosition < plainText.length) {
      final remainingText = plainText.substring(textPosition);
      if (remainingText.trim().isNotEmpty) {
        spans.add(TextSpan(
          text: remainingText,
          style: _getTextStyle(fontSize: _fontSize),
        ));
      }
    }

    // If we couldn't build proper spans, fall back to simple highlighting
    if (spans.isEmpty && _currentChunkIndex < _textChunks.length) {
      final currentChunk = _textChunks[_currentChunkIndex];
      spans = [
        TextSpan(
          text: plainText,
          style: _getTextStyle(fontSize: _fontSize),
          children: [
            TextSpan(
              text: '\n\n[Currently reading: ${currentChunk.substring(0, math.min(50, currentChunk.length))}...]',
              style: _getTextStyle(
                fontSize: _fontSize * 0.9,
                color: _isDarkTheme ? Colors.yellow : Colors.orange,
              ).copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ];
    }

    setState(() {
      _highlightedTextSpans = spans;
    });
  }

  void _nextTtsChunk() {
    if (_isReadingChunks && _currentChunkIndex < _textChunks.length - 1) {
      setState(() {
        _currentChunkIndex++;
      });

      // Stop current speech and speak next chunk
      _flutterTts?.stop().then((_) {
        _speakCurrentChunk();
      });

      print('TTS: Moving to next chunk ${_currentChunkIndex + 1}/${_textChunks.length}');
    }
  }

  Future<void> _startReadingFromText(String searchText) async {
    if (searchText.isEmpty) return;

    // Find the chapter containing the search text
    int foundChapterIndex = -1;
    for (int i = 0; i < _chapterContent.length; i++) {
      if (_chapterContent[i]!.toLowerCase().contains(searchText.toLowerCase())) {
        foundChapterIndex = i;
        break;
      }
    }

    if (foundChapterIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text not found in current book'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to the found chapter
    setState(() {
      _currentChapterIndex = foundChapterIndex;
    });

    // Start TTS from that chapter
    await _startTtsReading();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started reading from: "${searchText.substring(0, math.min(30, searchText.length))}..."'),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<String> _splitTextIntoChunks(String text) {
    List<String> chunks = [];

    // First try to split by paragraphs
    List<String> paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    for (String paragraph in paragraphs) {
      // If paragraph is too long, split by sentences
      if (paragraph.length > 500) {
        List<String> sentences = paragraph.split(RegExp(r'[.!?]+\s*')).where((s) => s.trim().isNotEmpty).toList();
        for (String sentence in sentences) {
          if (sentence.trim().isNotEmpty) {
            chunks.add(sentence.trim() + '.');
          }
        }
      } else {
        chunks.add(paragraph.trim());
      }
    }

    // If no chunks found, split by sentences as fallback
    if (chunks.isEmpty) {
      chunks = text.split(RegExp(r'[.!?]+\s*')).where((s) => s.trim().isNotEmpty).toList();
    }

    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: _isDarkTheme
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey.shade900, Colors.grey.shade800, Colors.black],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.deepOrange.shade50, Colors.orange.shade50, Colors.white],
                  ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _isDarkTheme ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isDarkTheme ? Colors.orange : Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading EPUB...',
                        style: _getTextStyle(fontSize: 16, color: _textColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: _isDarkTheme
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
                    ),
            ),
          ),
          iconTheme: IconThemeData(color: _textColor),
          title: Text(
            'Error',
            style: _getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: _isDarkTheme
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey.shade900, Colors.grey.shade800, Colors.black],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.deepOrange.shade50, Colors.orange.shade50, Colors.white],
                  ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isDarkTheme ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Failed to load book',
                      style: _getTextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error,
                      textAlign: TextAlign.center,
                      style: _getTextStyle(fontSize: 14, color: _textColor.withAlpha((0.7 * 255).round())),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text('Go Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Main content with brightness adjustment
          Opacity(
            opacity: _brightness,
            child: SafeArea(
              child: _buildMainContent(),
            ),
          ),

          // TTS Controls Bar (shown when TTS is active or controls are explicitly shown)
          if (_showTtsControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildTtsControlsPanel(),
            ),

          // Reading controls (shown on tap)
          if (_showControls)
            _buildControlsOverlay(),

          // Settings panel
          if (_showSettings)
            _buildSettingsPanel(),

          // Search results
          if (_showSearchResults)
            _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // Ensure we have valid content and chapter index
    if (_chapterContent.isEmpty || _currentChapterIndex < 0 || _currentChapterIndex >= _chapterContent.length) {
      return Center(
        child: GestureDetector(
          onTap: _toggleControls,
          child: Text(
            'No content available',
            style: _getTextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // Get current chapter content with validation
    String currentContent = _chapterContent[_currentChapterIndex] ?? '';
    String currentTitle = _chapterTitles.isNotEmpty && _currentChapterIndex < _chapterTitles.length
        ? _chapterTitles[_currentChapterIndex]
        : 'Chapter ${_currentChapterIndex + 1}';

    // If content is empty or too short, show error
    if (currentContent.trim().isEmpty) {
      return Center(
        child: GestureDetector(
          onTap: _toggleControls,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber,
                size: 48,
                color: _textColor.withOpacity(0.6),
              ),
              SizedBox(height: 16),
              Text(
                'Chapter content is empty',
                style: _getTextStyle(fontSize: 16, color: _textColor.withOpacity(0.8)),
              ),
              SizedBox(height: 8),
              Text(
                'Try navigating to another chapter',
                style: _getTextStyle(fontSize: 14, color: _textColor.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Use stable key that doesn't change frequently
            key: Key('chapter_content_${widget.book.id ?? 'unknown'}'),
            controller: _scrollController,
            padding: _textPadding,
            physics: AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chapter title
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text(
                      currentTitle,
                      style: _getTextStyle(
                        fontSize: _fontSize + 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Main text content with proper width constraints
                  Container(
                    width: double.infinity,
                    child: _buildTextContent(currentContent, constraints.maxWidth),
                  ),

                  const SizedBox(height: 100), // Bottom padding for controls
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextContent(String content, double maxWidth) {
    try {
      // Validate content before rendering
      if (content.trim().isEmpty) {
        return Container(
          width: maxWidth,
          child: Text(
            'No readable content in this chapter.',
            style: _getTextStyle(fontSize: _fontSize, color: _textColor.withOpacity(0.7)),
          ),
        );
      }

      // Create a stable container with fixed width constraints
      return Container(
        width: maxWidth,
        constraints: BoxConstraints(
          minWidth: maxWidth,
          maxWidth: maxWidth,
        ),
        child: _buildTextWidget(content),
      );
    } catch (e) {
      print('Error rendering text content: $e');
      // Fallback rendering with proper width constraints
      return Container(
        width: maxWidth,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Rendering Error',
              style: _getTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There was an issue displaying this chapter. Content length: ${content.length} characters.',
              style: _getTextStyle(fontSize: 14, color: _textColor.withOpacity(0.7)),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Force refresh of the content
                  _highlightedTextSpans.clear();
                });
              },
              child: Text('Retry Display'),
            ),
          ],
        ),
      );
    }
  }

  // Separate method for building the actual text widget
  Widget _buildTextWidget(String htmlContent) {
    // Use a stable key that doesn't change during TTS playback
    const stableKey = ValueKey('stable_html_content');

    // Check if we have TTS highlighting active (show during both playing and paused states)
    if (_highlightedTextSpans.isNotEmpty && (_isTtsPlaying || _isTtsPaused)) {
      // For TTS, we still use SelectableText.rich for highlighting
      return SelectableText.rich(
        TextSpan(children: _highlightedTextSpans),
        key: ValueKey('tts_highlighted_content'),
        textAlign: _textAlign,
        style: _getTextStyle(fontSize: _fontSize),
      );
    }

    // Regular HTML rendering with proper formatting preserved
    return Html(
      key: stableKey,
      data: htmlContent,
      style: {
        // Apply user's font settings to all text
        "body": Style(
          fontSize: FontSize(_fontSize),
          color: _textColor,
          lineHeight: LineHeight(_lineHeight),
          fontFamily: _getFontFamily(),
          letterSpacing: _letterSpacing,
          wordSpacing: _wordSpacing,
          textAlign: _getTextAlignForHtml(),
          padding: HtmlPaddings.zero,
          margin: Margins.zero,
        ),
        "p": Style(
          margin: Margins(bottom: Margin(_fontSize * 0.8)),
          textAlign: _getTextAlignForHtml(),
        ),
        "h1": Style(
          fontSize: FontSize(_fontSize * 1.8),
          fontWeight: FontWeight.bold,
          margin: Margins(top: Margin(_fontSize), bottom: Margin(_fontSize * 0.5)),
        ),
        "h2": Style(
          fontSize: FontSize(_fontSize * 1.6),
          fontWeight: FontWeight.bold,
          margin: Margins(top: Margin(_fontSize * 0.8), bottom: Margin(_fontSize * 0.4)),
        ),
        "h3": Style(
          fontSize: FontSize(_fontSize * 1.4),
          fontWeight: FontWeight.bold,
          margin: Margins(top: Margin(_fontSize * 0.6), bottom: Margin(_fontSize * 0.3)),
        ),
        "h4": Style(
          fontSize: FontSize(_fontSize * 1.2),
          fontWeight: FontWeight.bold,
        ),
        "h5": Style(
          fontSize: FontSize(_fontSize * 1.1),
          fontWeight: FontWeight.bold,
        ),
        "h6": Style(
          fontSize: FontSize(_fontSize),
          fontWeight: FontWeight.bold,
        ),
        "em": Style(fontStyle: FontStyle.italic),
        "i": Style(fontStyle: FontStyle.italic),
        "strong": Style(fontWeight: FontWeight.bold),
        "b": Style(fontWeight: FontWeight.bold),
        "a": Style(
          color: _isDarkTheme ? Colors.lightBlue.shade300 : Colors.blue.shade700,
          textDecoration: TextDecoration.underline,
        ),
        "blockquote": Style(
          margin: Margins(left: Margin(_fontSize), right: Margin(_fontSize)),
          padding: HtmlPaddings.only(left: _fontSize * 0.8),
          border: Border(left: BorderSide(color: _textColor.withOpacity(0.3), width: 3)),
          fontStyle: FontStyle.italic,
        ),
        "code": Style(
          fontFamily: 'monospace',
          backgroundColor: _textColor.withOpacity(0.1),
          padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
        ),
        "pre": Style(
          fontFamily: 'monospace',
          backgroundColor: _textColor.withOpacity(0.05),
          padding: HtmlPaddings.all(_fontSize * 0.8),
          margin: Margins(top: Margin(_fontSize * 0.5), bottom: Margin(_fontSize * 0.5)),
        ),
        "ul": Style(
          margin: Margins(left: Margin(_fontSize * 1.5)),
          padding: HtmlPaddings.zero,
        ),
        "ol": Style(
          margin: Margins(left: Margin(_fontSize * 1.5)),
          padding: HtmlPaddings.zero,
        ),
        "li": Style(
          margin: Margins(bottom: Margin(_fontSize * 0.3)),
        ),
      },
      // Handle link taps for internal EPUB navigation
      onLinkTap: (url, attributes, element) {
        _handleLinkTap(url);
      },
    );
  }

  // Helper method to get text align for Html widget
  TextAlign _getTextAlignForHtml() {
    return _textAlign;
  }

  // Helper method to get font family string
  String? _getFontFamily() {
    final fontOption = _fontOptions[_fontFamily];
    if (fontOption == null || fontOption['isSystemFont'] == true) {
      return fontOption?['fontFamily'];
    } else {
      // For Google Fonts, return the family name
      return fontOption['fontFamily'];
    }
  }

  Widget _buildTtsControlsPanel() {
    if (!_isTtsInitialized) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _isDarkTheme
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey.shade800.withOpacity(0.95), Colors.grey.shade900.withOpacity(0.95)],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0.95), Colors.grey.shade50.withOpacity(0.95)],
                ),
          border: Border(top: BorderSide(color: _textColor.withAlpha((0.1 * 255).round()))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.15 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: _textColor.withAlpha((0.7 * 255).round()), size: 20),
            const SizedBox(width: 8),
            Text('TTS is initializing...', style: _getTextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: _isDarkTheme
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey.shade800.withOpacity(0.95), Colors.grey.shade900.withOpacity(0.95)],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withOpacity(0.95), Colors.grey.shade50.withOpacity(0.95)],
              ),
        border: Border(top: BorderSide(color: _textColor.withAlpha((0.1 * 255).round()))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.15 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TTS Status and Progress
          if (_isReadingChunks && _textChunks.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkTheme
                      ? [Colors.orange.shade900.withOpacity(0.3), Colors.orange.shade800.withOpacity(0.2)]
                      : [Colors.deepOrange.shade50, Colors.orange.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.volume_up, color: _isDarkTheme ? Colors.orange : Colors.deepOrange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reading ${_currentChunkIndex + 1} of ${_textChunks.length} segments',
                          style: _getTextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_currentChunkIndex + 1) / _textChunks.length,
                            backgroundColor: _textColor.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isDarkTheme ? Colors.orange : Colors.deepOrange,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // TTS Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous chunk
              _buildTtsIconButton(
                icon: Icons.skip_previous,
                onPressed: _isReadingChunks ? _previousTtsChunk : null,
                tooltip: 'Previous segment',
              ),

              // Play/Pause button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isTtsPlaying
                      ? LinearGradient(
                          colors: _isDarkTheme
                              ? [Colors.orange.shade700, Colors.orange.shade900]
                              : [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
                        )
                      : null,
                  boxShadow: _isTtsPlaying
                      ? [
                          BoxShadow(
                            color: (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: IconButton(
                  icon: Icon(
                    _isTtsPlaying ? Icons.pause_circle_filled :
                    _isTtsPaused ? Icons.play_circle_filled : Icons.play_circle_outline,
                    color: _isTtsPlaying ? Colors.white : (_isDarkTheme ? Colors.orange : Colors.deepOrange),
                    size: 40,
                  ),
                  onPressed: () {
                    if (_isTtsPlaying) {
                      _pauseTtsReading();
                    } else if (_isTtsPaused) {
                      _resumeTtsReading();
                    } else {
                      _startTtsReading();
                    }
                  },
                  tooltip: _isTtsPlaying ? 'Pause' : 'Play',
                ),
              ),

              // Stop button
              _buildTtsIconButton(
                icon: Icons.stop_circle,
                onPressed: _isTtsPlaying || _isTtsPaused ? _stopTtsReading : null,
                tooltip: 'Stop',
                color: Colors.red,
              ),

              // Next chunk
              _buildTtsIconButton(
                icon: Icons.skip_next,
                onPressed: _isReadingChunks ? _nextTtsChunk : null,
                tooltip: 'Next segment',
              ),

              // Hide TTS controls
              _buildTtsIconButton(
                icon: Icons.keyboard_arrow_down,
                onPressed: () {
                  setState(() {
                    _showTtsControls = false;
                  });
                },
                tooltip: 'Hide controls',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build TTS icon buttons with consistent styling
  Widget _buildTtsIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    Color? color,
  }) {
    final buttonColor = color ?? (_isDarkTheme ? Colors.orange : Colors.deepOrange);
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null ? buttonColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: onPressed != null ? buttonColor.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: onPressed != null ? buttonColor : Colors.grey),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Column(
      children: [
        // Top controls with gradient
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            gradient: _isDarkTheme
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey.shade900.withOpacity(0.95), Colors.grey.shade800.withOpacity(0.95)],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.90)],
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.15 * 255).round()),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: _isDarkTheme ? Colors.orange : Colors.deepOrange),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.book.title,
                  style: _getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.search, color: _textColor),
                onPressed: () {
                  setState(() {
                    _showSearchResults = !_showSearchResults;
                    _showSettings = false;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.bookmark_add, color: _textColor),
                onPressed: _addBookmark,
              ),
              IconButton(
                icon: Icon(Icons.settings, color: _textColor),
                onPressed: () {
                  setState(() {
                    _showSettings = !_showSettings;
                    _showSearchResults = false;
                  });
                },
              ),
            ],
          ),
        ),

        Spacer(),

        // Bottom controls with gradient
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: _isDarkTheme
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey.shade800.withOpacity(0.95), Colors.grey.shade900.withOpacity(0.95)],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(0.90), Colors.white.withOpacity(0.95)],
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.15 * 255).round()),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TTS Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.record_voice_over,
                    label: 'TTS',
                    onPressed: () {
                      setState(() {
                        _showTtsControls = !_showTtsControls;
                      });
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.list,
                    label: 'Contents',
                    onPressed: _showTableOfContents,
                  ),
                  _buildControlButton(
                    icon: Icons.bookmarks,
                    label: 'Bookmarks',
                    onPressed: _showBookmarks,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Chapter navigation
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _currentChapterIndex > 0 ? _previousChapter : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDarkTheme ? Colors.grey[700] : Colors.grey[300],
                        foregroundColor: _textColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Chapter ${_currentChapterIndex + 1} of ${_chapterContent.length}',
                      textAlign: TextAlign.center,
                      style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _currentChapterIndex < _chapterContent.length - 1 ? _nextChapter : null,
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDarkTheme ? Colors.grey[700] : Colors.grey[300],
                        foregroundColor: _textColor,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              // Reading progress
              const SizedBox(height: 12),
              if (_chapterContent.isNotEmpty)
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_currentChapterIndex + 1) / _chapterContent.length,
                          backgroundColor: _textColor.withAlpha((0.2 * 255).round()),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isDarkTheme ? Colors.orange : Colors.deepOrange,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${((_currentChapterIndex + 1) / _chapterContent.length * 100).round()}% complete',
                      style: _getTextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build control buttons with consistent styling
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: _isDarkTheme ? Colors.orange : Colors.deepOrange),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: _getTextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha((0.6 * 255).round()),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.3 * 255).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: _isDarkTheme
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.orange.shade800, Colors.orange.shade900],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
                          ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reading Settings',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _showSettings = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Theme selection
                        Text(
                          'Theme',
                          style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _themePresets.entries.map((entry) {
                            final themeName = entry.key;
                            final themeData = entry.value;
                            final isSelected = _currentTheme == themeName;

                            return GestureDetector(
                              onTap: () => _applyTheme(themeName),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: themeData['backgroundColor'] as Color,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? (_isDarkTheme ? Colors.orange : Colors.deepOrange)
                                        : Colors.grey.shade400,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                                      ),
                                    if (isSelected) const SizedBox(width: 6),
                                    Text(
                                      themeData['name'] as String,
                                      style: TextStyle(
                                        color: themeData['textColor'] as Color,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Font size
                        _buildSettingCard(
                          title: 'Font Size',
                          value: '${_fontSize.round()}px',
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                              inactiveTrackColor: _textColor.withOpacity(0.2),
                              thumbColor: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                              overlayColor: (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                            ),
                            child: Slider(
                              value: _fontSize,
                              min: 12,
                              max: 32,
                              divisions: 20,
                              onChanged: (value) {
                                setState(() {
                                  _fontSize = value;
                                });
                              },
                              onChangeEnd: (value) => _saveSettings(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Font family
                        _buildSettingCard(
                          title: 'Font Family',
                          child: DropdownButtonFormField<String>(
                            value: _fontFamily,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _textColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _fontOptions.keys.map((fontName) {
                              return DropdownMenuItem(
                                value: fontName,
                                child: Text(fontName, style: _getTextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _fontFamily = value;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Line height
                        _buildSettingCard(
                          title: 'Line Height',
                          value: _lineHeight.toStringAsFixed(1),
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                              inactiveTrackColor: _textColor.withOpacity(0.2),
                              thumbColor: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                              overlayColor: (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                            ),
                            child: Slider(
                              value: _lineHeight,
                              min: 1.0,
                              max: 2.5,
                              divisions: 15,
                              onChanged: (value) {
                                setState(() {
                                  _lineHeight = value;
                                });
                              },
                              onChangeEnd: (value) => _saveSettings(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Brightness
                        _buildSettingCard(
                          title: 'Brightness',
                          value: '${(_brightness * 100).round()}%',
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                              inactiveTrackColor: _textColor.withOpacity(0.2),
                              thumbColor: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                              overlayColor: (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                            ),
                            child: Slider(
                              value: _brightness,
                              min: 0.3,
                              max: 1.0,
                              onChanged: (value) {
                                setState(() {
                                  _brightness = value;
                                });
                              },
                              onChangeEnd: (value) => _saveSettings(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Text Alignment
                        _buildSettingCard(
                          title: 'Text Alignment',
                          child: DropdownButtonFormField<TextAlign>(
                            value: _textAlign,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _textColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: TextAlign.left,
                                child: Row(
                                  children: [
                                    Icon(Icons.format_align_left, size: 18, color: _textColor),
                                    const SizedBox(width: 8),
                                    Text('Left', style: _getTextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: TextAlign.center,
                                child: Row(
                                  children: [
                                    Icon(Icons.format_align_center, size: 18, color: _textColor),
                                    const SizedBox(width: 8),
                                    Text('Center', style: _getTextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: TextAlign.right,
                                child: Row(
                                  children: [
                                    Icon(Icons.format_align_right, size: 18, color: _textColor),
                                    const SizedBox(width: 8),
                                    Text('Right', style: _getTextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: TextAlign.justify,
                                child: Row(
                                  children: [
                                    Icon(Icons.format_align_justify, size: 18, color: _textColor),
                                    const SizedBox(width: 8),
                                    Text('Justify', style: _getTextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _textAlign = value;
                                });
                                _saveSettings();
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                  // TTS Settings Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (_isDarkTheme ? Colors.grey[800] : Colors.grey[100])?.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _textColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TTS Header
                        Row(
                          children: [
                            Icon(Icons.record_voice_over, color: _textColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Text-to-Speech Settings',
                              style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // TTS Language Selection
                        Text(
                          'Language',
                          style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _supportedTtsLanguages.containsKey(_selectedLanguage) ? _selectedLanguage : 'en-US',
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _supportedTtsLanguages.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value, style: _getTextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _changeTtsLanguage(value);
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        // TTS Voice Selection (only show if voices available for selected language)
                        if (_getVoicesForLanguage(_selectedLanguage).isNotEmpty) ...[
                          Text(
                            'Voice',
                            style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedVoice,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            hint: Text('Select Voice', style: _getTextStyle(fontSize: 14)),
                            items: _getVoicesForLanguage(_selectedLanguage).map((voice) {
                              final voiceName = voice['name'] as String;
                              return DropdownMenuItem(
                                value: voiceName,
                                child: Text(voiceName, style: _getTextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _changeTtsVoice(value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // TTS Speed/Rate
                        Text(
                          'Speech Speed: ${(_ttsRate * 100).round()}%',
                          style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Slider(
                          value: _ttsRate,
                          min: 0.1,
                          max: 1.0,
                          divisions: 18,
                          onChanged: (value) {
                            setState(() {
                              _ttsRate = value;
                            });
                          },
                          onChangeEnd: (value) => _changeTtsRate(value),
                        ),

                        const SizedBox(height: 12),

                        // TTS Pitch
                        Text(
                          'Voice Pitch: ${(_ttsPitch * 100).round()}%',
                          style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Slider(
                          value: _ttsPitch,
                          min: 0.5,
                          max: 2.0,
                          divisions: 30,
                          onChanged: (value) {
                            setState(() {
                              _ttsPitch = value;
                            });
                          },
                          onChangeEnd: (value) => _changeTtsPitch(value),
                        ),

                        const SizedBox(height: 16),

                        // TTS Test Button
                        if (_isTtsInitialized)
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  String testText;
                                  if (_selectedLanguage.startsWith('hi')) {
                                    testText = 'यह एक परीक्षण है।';
                                  } else if (_selectedLanguage.startsWith('kn')) {
                                    testText = 'ಇದು ಒಂದು ಪರೀಕ್ಷೆಯಾಗಿದೆ.';
                                  } else if (_selectedLanguage.startsWith('sa')) {
                                    testText = 'इदं परीक्षणम् अस्ति।';
                                  } else if (_selectedLanguage.startsWith('ta')) {
                                    testText = 'இது ஒரு சோதனை.';
                                  } else if (_selectedLanguage.startsWith('te')) {
                                    testText = 'ఇది ఒక పరీక్ష.';
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
                                backgroundColor: _isDarkTheme ? Colors.grey[700] : Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else
                          Center(
                            child: Text(
                              'TTS not initialized',
                              style: _getTextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Close Settings Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showSettings = false;
                        });
                      },
                      child: Text('Close Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDarkTheme ? Colors.grey[700] : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
      ),
    ),
  );
}

  Widget _buildSearchResults() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha((0.5 * 255).round()),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.3 * 255).round()),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.search, color: _textColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search in Book',
                        style: _getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: _textColor),
                      onPressed: () {
                        setState(() {
                          _showSearchResults = false;
                          _searchResults.clear();
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Search input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Enter search term...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: _performSearch,
                  style: _getTextStyle(fontSize: 14),
                ),

                const SizedBox(height: 16),

                // Search results
                if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                  Text(
                    'No results found',
                    style: _getTextStyle(fontSize: 14, color: Colors.orange),
                  )
                else if (_searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          title: Text(
                            result.chapterTitle,
                            style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            result.excerpt,
                            style: _getTextStyle(fontSize: 12, color: _textColor.withAlpha((0.7 * 255).round())),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            setState(() {
                              _currentChapterIndex = result.chapterIndex;
                              _showSearchResults = false;
                            });
                            _scrollController.jumpTo(0);
                            _saveReadingProgressDebounced();

                            // Start TTS from search result if available
                            if (_isTtsInitialized) {
                              final searchText = _searchController.text;
                              if (searchText.isNotEmpty) {
                                _startReadingFromText(searchText);
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ));
  }

  // Helper method to build setting cards with consistent styling
  Widget _buildSettingCard({
    required String title,
    String? value,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (_isDarkTheme ? Colors.grey[800] : Colors.grey[50])?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (value != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_isDarkTheme ? Colors.orange : Colors.deepOrange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: _getTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isDarkTheme ? Colors.orange : Colors.deepOrange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class SearchResult {
  final int chapterIndex;
  final String chapterTitle;
  final String excerpt;
  final int position;

  SearchResult({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.excerpt,
    required this.position,
  });
}
