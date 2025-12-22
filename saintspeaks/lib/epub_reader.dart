import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:epubx/epubx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'book_service.dart';

class EpubReaderPage extends StatefulWidget {
  final Book book;

  EpubReaderPage({required this.book});

  @override
  _EpubReaderPageState createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  EpubBook? _epubBook;
  PageController _pageController = PageController();
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

  // Filtered TTS languages - only English and Hindi variants from UK, India, and US
  final Map<String, String> _supportedTtsLanguages = {
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'en-IN': 'English (India)',
    'hi-IN': 'Hindi (India)',
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
    _pageController.dispose();
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

      if (_epubBook!.Chapters != null && _epubBook!.Chapters!.isNotEmpty) {
        _epubChapters = _epubBook!.Chapters!;
        print('Found ${_epubChapters.length} chapters in EPUB');

        for (int i = 0; i < _epubChapters.length; i++) {
          final chapter = _epubChapters[i];
          final title = chapter.Title ?? 'Chapter ${i + 1}';
          _chapterTitles.add(title);

          final htmlContent = chapter.HtmlContent ?? '';
          final cleanContent = _cleanAndFormatHtmlContent(htmlContent);
          _chapterContent[i] = cleanContent;
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
                final cleanContent = _cleanAndFormatHtmlContent(htmlContent);
                _chapterContent[chapterIndex] = cleanContent;
                chapterIndex++;
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

  String _cleanAndFormatHtmlContent(String html) {
    if (html.isEmpty) return '';

    try {
      // Remove scripts, styles, and other non-content elements
      String cleaned = html
          .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, multiLine: true, dotAll: true), '')
          .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, multiLine: true, dotAll: true), '')
          .replaceAll(RegExp(r'<meta[^>]*>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<link[^>]*>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<!--.*?-->', multiLine: true, dotAll: true), '');

      // Clean up HTML entities first (more comprehensive)
      cleaned = cleaned
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

      // Handle numeric HTML entities safely
      cleaned = cleaned.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
        try {
          final code = int.parse(match.group(1)!);
          // Only convert valid Unicode code points
          if (code > 0 && code <= 0x10FFFF) {
            return String.fromCharCode(code);
          }
          return ' '; // Replace invalid codes with space
        } catch (e) {
          return ' '; // Replace problematic entities with space
        }
      });

      cleaned = cleaned.replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (match) {
        try {
          final code = int.parse(match.group(1)!, radix: 16);
          // Only convert valid Unicode code points
          if (code > 0 && code <= 0x10FFFF) {
            return String.fromCharCode(code);
          }
          return ' '; // Replace invalid codes with space
        } catch (e) {
          return ' '; // Replace problematic entities with space
        }
      });

      // Handle block elements properly to preserve paragraph structure
      cleaned = cleaned
          .replaceAll(RegExp(r'\s*<br[^>]*>\s*', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'\s*</p>\s*<p[^>]*>\s*', caseSensitive: false), '\n\n')
          .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n\n')
          .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
          .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
          .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');

      // Remove remaining HTML tags
      cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), ' ');

      // Normalize whitespace while preserving paragraph breaks
      cleaned = cleaned
          // Replace multiple spaces/tabs with single space
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          // Clean up spaces around newlines
          .replaceAll(RegExp(r' *\n *'), '\n')
          // Replace multiple newlines with double newlines (paragraph breaks)
          .replaceAll(RegExp(r'\n{3,}'), '\n\n');

      // Split into lines for better processing
      List<String> lines = cleaned.split('\n');

      // Process each line to remove problematic characters
      List<String> processedLines = [];
      for (String line in lines) {
        String processedLine = line
            .trim()
            // Remove zero-width characters that can cause display issues
            .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
            // Remove control characters except newlines and tabs
            .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
            // Remove any remaining invisible characters that might cause issues
            .replaceAll(RegExp(r'[\u180E\u2000-\u200A\u2028\u2029\u205F\u3000]'), ' ');

        // Only add non-empty lines
        if (processedLine.isNotEmpty) {
          processedLines.add(processedLine);
        }
      }

      // Rejoin lines with proper spacing
      cleaned = processedLines.join('\n')
          .replaceAll(RegExp(r'\n\n+'), '\n\n') // Normalize paragraph spacing
          .trim();

      // Final validation - ensure we don't return corrupted content
      if (cleaned.isEmpty || cleaned.length < 3) {
        return 'Content could not be processed properly. Please try a different chapter.';
      }

      // Check for potential encoding issues that might cause single character display
      if (cleaned.split(' ').length < 3 && cleaned.length < 50) {
        return 'Content appears corrupted. Raw length: ${html.length} characters. Please try refreshing or check the EPUB file.';
      }

      print('Content processing: Original ${html.length} chars -> Cleaned ${cleaned.length} chars');
      return cleaned;

    } catch (e) {
      print('Error cleaning HTML content: $e');
      return 'Error processing content: ${e.toString()}. Original content length: ${html.length} characters.';
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

      // TTS settings - use default values only, don't save/load
      _ttsRate = 0.5;
      _ttsPitch = 1.0;
      _selectedLanguage = 'en-US';
      _selectedVoice = null;

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

    // TTS settings - removed, use default values only

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
      setState(() {
        _currentChapterIndex++;
      });
      _scrollController.jumpTo(0);
      _saveReadingProgressDebounced();
    }
  }

  void _previousChapter() {
    if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
      });
      _scrollController.jumpTo(0);
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
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkTheme ? Colors.grey[800] : Colors.orange,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bookmarks, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bookmarks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
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
                          Icon(
                            Icons.bookmark_border,
                            size: 64,
                            color: _textColor.withAlpha((0.5 * 255).round()),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookmarks yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: _textColor.withAlpha((0.7 * 255).round()),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the bookmark button to save your current position',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _textColor.withAlpha((0.5 * 255).round()),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _bookmarks.length,
                      itemBuilder: (context, index) {
                        final bookmark = _bookmarks[index];
                        final isCurrentPosition = bookmark.chapterIndex == _currentChapterIndex;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCurrentPosition
                                ? (_isDarkTheme ? Colors.orange[900]?.withAlpha((0.3 * 255).round()) : Colors.orange[50])
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _textColor.withAlpha((0.1 * 255).round()),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCurrentPosition
                                    ? Colors.orange
                                    : (_isDarkTheme ? Colors.grey[600] : Colors.grey[400]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.bookmark,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              bookmark.chapterTitle,
                              style: TextStyle(
                                fontWeight: isCurrentPosition ? FontWeight.bold : FontWeight.w500,
                                color: _textColor,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Chapter ${bookmark.chapterIndex + 1}',
                                  style: TextStyle(
                                    color: _textColor.withAlpha((0.7 * 255).round()),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Added: ${_formatDate(bookmark.createdAt)}',
                                  style: TextStyle(
                                    color: _textColor.withAlpha((0.5 * 255).round()),
                                    fontSize: 11,
                                  ),
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
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkTheme ? Colors.grey[800] : Colors.blue,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.list, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Table of Contents',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _chapterTitles.length,
                itemBuilder: (context, index) {
                  final isCurrentChapter = index == _currentChapterIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCurrentChapter ? (_isDarkTheme ? Colors.grey[700] : Colors.blue[50]) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isCurrentChapter ? Colors.blue : Colors.grey,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        _chapterTitles[index],
                        style: TextStyle(
                          fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                          color: _textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
    setState(() {
      _currentChapterIndex = chapterIndex.clamp(0, _chapterContent.length - 1);
    });
    _scrollController.jumpTo(0);
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
        // Removed _saveSettings() call - TTS settings use defaults only

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
          // Removed _saveSettings() call - TTS settings use defaults only

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
        // Removed _saveSettings() call - TTS settings use defaults only
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
        // Removed _saveSettings() call - TTS settings use defaults only
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
        print('TTS: Paused reading');
      } catch (e) {
        print('TTS: Error pausing: $e');
      }
    }
  }

  Future<void> _resumeTtsReading() async {
    if (_flutterTts != null && _isTtsPaused) {
      try {
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
    final currentContent = _chapterContent[_currentChapterIndex] ?? '';
    if (currentContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No text available to read'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Split content into chunks (by sentences or paragraphs)
    _textChunks = _splitTextIntoChunks(currentContent);
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
        });

        print('TTS: Stopped reading');
      } catch (e) {
        print('TTS: Error stopping: $e');
      }
    }
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: _isDarkTheme ? Colors.orange : Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading EPUB...',
                style: _getTextStyle(fontSize: 16, color: _textColor),
              ),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: _textColor),
          title: Text(
            'Error',
            style: _getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load book',
                  style: _getTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: _getTextStyle(fontSize: 14, color: _textColor.withAlpha((0.7 * 255).round())),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Go Back'),
                ),
              ],
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
  Widget _buildTextWidget(String content) {
    // Use a stable key that doesn't change during TTS playback
    const stableKey = ValueKey('stable_text_content');

    // Check if we have TTS highlighting active
    if (_highlightedTextSpans.isNotEmpty && _isTtsPlaying) {
      return RichText(
        key: stableKey,
        text: TextSpan(children: _highlightedTextSpans),
        textAlign: TextAlign.justify,
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }

    // Regular text rendering with stable key
    return Text(
      content,
      key: stableKey,
      style: _getTextStyle(fontSize: _fontSize),
      textAlign: TextAlign.justify,
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  Widget _buildTtsControlsPanel() {
    if (!_isTtsInitialized) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (_isDarkTheme ? Colors.grey[900] : Colors.white)?.withAlpha((0.95 * 255).round()),
          border: Border(top: BorderSide(color: _textColor.withAlpha((0.1 * 255).round()))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: _textColor.withAlpha((0.7 * 255).round()), size: 20),
            SizedBox(width: 8),
            Text('TTS is initializing...', style: _getTextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (_isDarkTheme ? Colors.grey[900] : Colors.white)?.withAlpha((0.95 * 255).round()),
        border: Border(top: BorderSide(color: _textColor.withAlpha((0.1 * 255).round()))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TTS Status and Progress
          if (_isReadingChunks && _textChunks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.volume_up, color: _textColor, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reading ${_currentChunkIndex + 1} of ${_textChunks.length} segments',
                      style: _getTextStyle(fontSize: 12),
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
              IconButton(
                icon: Icon(Icons.skip_previous, color: _textColor),
                onPressed: _isReadingChunks ? _previousTtsChunk : null,
                tooltip: 'Previous segment',
              ),

              // Play/Pause button
              IconButton(
                icon: Icon(
                  _isTtsPlaying ? Icons.pause_circle_filled :
                  _isTtsPaused ? Icons.play_circle_filled : Icons.play_circle_outline,
                  color: _isTtsPlaying ? Colors.orange : _textColor,
                  size: 32,
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

              // Stop button
              IconButton(
                icon: Icon(Icons.stop_circle, color: Colors.red),
                onPressed: _isTtsPlaying || _isTtsPaused ? _stopTtsReading : null,
                tooltip: 'Stop',
              ),

              // Next chunk
              IconButton(
                icon: Icon(Icons.skip_next, color: _textColor),
                onPressed: _isReadingChunks ? _nextTtsChunk : null,
                tooltip: 'Next segment',
              ),

              // Hide TTS controls
              IconButton(
                icon: Icon(Icons.keyboard_arrow_down, color: _textColor),
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

  Widget _buildControlsOverlay() {
    return Column(
      children: [
        // Top controls
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: (_isDarkTheme ? Colors.grey[900] : Colors.white)?.withAlpha((0.95 * 255).round()),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).round()),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: _textColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
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

        // Bottom controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (_isDarkTheme ? Colors.grey[900] : Colors.white)?.withAlpha((0.95 * 255).round()),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).round()),
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TTS Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.record_voice_over, color: _textColor),
                    onPressed: () {
                      setState(() {
                        _showTtsControls = !_showTtsControls;
                      });
                    },
                    tooltip: 'Text-to-Speech',
                  ),
                  IconButton(
                    icon: Icon(Icons.list, color: _textColor),
                    onPressed: _showTableOfContents,
                    tooltip: 'Table of Contents',
                  ),
                  IconButton(
                    icon: Icon(Icons.bookmarks, color: _textColor),
                    onPressed: _showBookmarks,
                    tooltip: 'Bookmarks',
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
                    LinearProgressIndicator(
                      value: (_currentChapterIndex + 1) / _chapterContent.length,
                      backgroundColor: _textColor.withAlpha((0.2 * 255).round()),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isDarkTheme ? Colors.orange : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${((_currentChapterIndex + 1) / _chapterContent.length * 100).round()}% complete',
                      style: _getTextStyle(fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel() {
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.settings, color: _textColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reading Settings',
                          style: _getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: _textColor),
                        onPressed: () {
                          setState(() {
                            _showSettings = false;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Theme selection
                  Text(
                    'Theme',
                    style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _themePresets.entries.map((entry) {
                      final themeName = entry.key;
                      final themeData = entry.value;
                      final isSelected = _currentTheme == themeName;

                      return GestureDetector(
                        onTap: () => _applyTheme(themeName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: themeData['backgroundColor'] as Color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            themeData['name'] as String,
                            style: TextStyle(
                              color: themeData['textColor'] as Color,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Font size
                  Text(
                    'Font Size: ${_fontSize.round()}px',
                    style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Slider(
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

                  const SizedBox(height: 16),

                  // Font family
                  Text(
                    'Font Family',
                    style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _fontFamily,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

                  const SizedBox(height: 16),

                  // Line height
                  Text(
                    'Line Height: ${_lineHeight.toStringAsFixed(1)}',
                    style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Slider(
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

                  const SizedBox(height: 16),

                  // Brightness
                  Text(
                    'Brightness: ${(_brightness * 100).round()}%',
                    style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Slider(
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

                  const SizedBox(height: 24),

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
                                  final testText = _selectedLanguage.startsWith('hi')
                                      ? 'यह एक परीक्षण है।'
                                      : 'This is a test of text-to-speech.';
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
        ),
      ),);
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
