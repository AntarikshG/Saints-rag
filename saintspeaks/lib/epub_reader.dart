import 'dart:io';
import 'dart:async';
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

    // Initialize Text-to-Speech
    _flutterTts = FlutterTts();
    _initializeTts();
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

    // Remove scripts, styles, and other non-content elements
    String cleaned = html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, multiLine: true, dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, multiLine: true, dotAll: true), '')
        .replaceAll(RegExp(r'<meta[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<link[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<!--.*?-->', multiLine: true, dotAll: true), '');

    // Clean up HTML entities
    cleaned = cleaned
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");

    // Normalize whitespace but preserve paragraph structure
    cleaned = cleaned
        .replaceAll(RegExp(r'\s*<br[^>]*>\s*', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'\s*</p>\s*<p[^>]*>\s*', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '')
        .replaceAll('</p>', '\n\n')
        .replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '')
        .replaceAll('</div>', '\n')
        .replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n');

    // Remove remaining HTML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');

    // Normalize whitespace
    cleaned = cleaned
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n[ \t]+'), '\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return cleaned;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('epub_font_size') ?? 18.0;
      _fontFamily = prefs.getString('epub_font_family') ?? 'System Default';
      _lineHeight = prefs.getDouble('epub_line_height') ?? 1.6;
      _brightness = prefs.getDouble('epub_brightness') ?? 1.0;
      _wordSpacing = prefs.getDouble('epub_word_spacing') ?? 1.0;
      _letterSpacing = prefs.getDouble('epub_letter_spacing') ?? 0.3;
      _currentTheme = prefs.getString('epub_theme') ?? 'sepia';

      _applyTheme(_currentTheme);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('epub_font_size', _fontSize);
    await prefs.setString('epub_font_family', _fontFamily);
    await prefs.setDouble('epub_line_height', _lineHeight);
    await prefs.setDouble('epub_brightness', _brightness);
    await prefs.setDouble('epub_word_spacing', _wordSpacing);
    await prefs.setDouble('epub_letter_spacing', _letterSpacing);
    await prefs.setString('epub_theme', _currentTheme);
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
      dynamic engines = await _flutterTts!.getEngines;
      print('TTS: Available engines: $engines');

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
                content: Text('Finished reading chapter: ${_chapterTitles.isNotEmpty ? _chapterTitles[_currentChapterIndex] : 'Chapter ${_currentChapterIndex + 1}'}'),
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

      // Set default TTS settings
      await _flutterTts!.setLanguage(_selectedLanguage);
      await _flutterTts!.setSpeechRate(_ttsRate);
      await _flutterTts!.setPitch(_ttsPitch);

      if (_selectedVoice != null) {
        await _flutterTts!.setVoice({"name": _selectedVoice!, "locale": _selectedLanguage});
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

  Future<void> _reinitializeTts() async {
    print('TTS: Reinitializing...');
    if (_flutterTts != null) {
      await _flutterTts!.stop();
    }
    setState(() {
      _isTtsInitialized = false;
      _isTtsPlaying = false;
      _isTtsPaused = false;
    });
    await _initializeTts();
  }

  // Enhanced TTS methods for chunk-based reading with highlighting
  void _startTtsReading() {
    if (!_isTtsInitialized || _chapterContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text-to-Speech not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _showTtsControls = true;
    });

    final currentChapterText = _chapterContent[_currentChapterIndex] ?? '';
    if (currentChapterText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No text to read in current chapter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prepare text chunks for reading
    _prepareTextChunks(currentChapterText);

    setState(() {
      _isReadingChunks = true;
      _currentChunkIndex = 0;
    });

    _speakCurrentChunk();
  }

  void _startReadingFromText(String searchText) {
    if (!_isTtsInitialized || _chapterContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text-to-Speech not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentChapterText = _chapterContent[_currentChapterIndex] ?? '';
    if (currentChapterText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No text to read in current chapter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Find the position of search text in the chapter
    final searchIndex = currentChapterText.toLowerCase().indexOf(searchText.toLowerCase());
    if (searchIndex == -1) {
      // If search text not found, start from beginning
      _startTtsReading();
      return;
    }

    // Extract text from search position onwards
    final textFromSearch = currentChapterText.substring(searchIndex);

    // Prepare text chunks starting from search position
    _prepareTextChunks(textFromSearch);

    setState(() {
      _isReadingChunks = true;
      _currentChunkIndex = 0;
    });

    _speakCurrentChunk();

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting reading from search result'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _prepareTextChunks(String text) {
    _textChunks.clear();

    // Split text into sentences for better highlighting and pausing
    final sentences = text.split(RegExp(r'[.!?]+\s+'));

    // Group sentences into chunks of reasonable size (2-3 sentences per chunk)
    List<String> currentChunk = [];

    for (String sentence in sentences) {
      sentence = sentence.trim();
      if (sentence.isEmpty) continue;

      currentChunk.add(sentence);

      // If chunk has 2-3 sentences or is getting long, create a chunk
      if (currentChunk.length >= 2 || currentChunk.join(' ').length > 200) {
        _textChunks.add(currentChunk.join('. ') + '.');
        currentChunk.clear();
      }
    }

    // Add remaining sentences as final chunk
    if (currentChunk.isNotEmpty) {
      _textChunks.add(currentChunk.join('. ') + '.');
    }

    print('TTS: Prepared ${_textChunks.length} text chunks for reading');
  }

  void _speakCurrentChunk() async {
    if (_currentChunkIndex >= _textChunks.length || !_isReadingChunks) {
      return;
    }

    final chunkText = _textChunks[_currentChunkIndex];
    print('TTS: Speaking chunk ${_currentChunkIndex + 1}/${_textChunks.length}: ${chunkText.substring(0, 50)}...');

    // Update highlighting to show current chunk
    _updateTextHighlighting();

    try {
      await _flutterTts!.speak(chunkText);
    } catch (e) {
      print('TTS: Error speaking chunk: $e');
      _stopTtsReading();
    }
  }

  void _updateTextHighlighting() {
    // Simplified highlighting - only update if TTS is actively playing
    if (!_isTtsPlaying || _chapterContent.isEmpty || _currentChunkIndex >= _textChunks.length) {
      return;
    }

    // Use a simpler approach without heavy calculations
    setState(() {
      // Clear highlighting to prevent UI freezing - we'll use a simpler indicator
      _highlightedTextSpans.clear();
    });
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
    _scrollSyncTimer?.cancel(); // Cancel any pending scroll operations
    if (_flutterTts != null) {
      _flutterTts!.stop();
    }
    setState(() {
      _isTtsPlaying = false;
      _isTtsPaused = false;
      _isReadingChunks = false;
      _currentChunkIndex = 0;
      _highlightedTextSpans.clear();
      _showTtsControls = false; // Hide TTS controls when stopped
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

      // Start reading from previous chunk after a short delay
      Timer(Duration(milliseconds: 300), () {
        if (_isReadingChunks) {
          _speakCurrentChunk();
        }
      });
    }
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
              child: _chapterContent.isNotEmpty
                  ? Stack(
                      children: [
                        // Main scrollable content
                        GestureDetector(
                          onTap: _toggleControls,
                          behavior: HitTestBehavior.deferToChild, // Allow scroll gestures to pass through
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: _textPadding,
                            physics: AlwaysScrollableScrollPhysics(), // Ensure scrolling is always enabled
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Chapter title
                                if (_chapterTitles.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24.0),
                                    child: Text(
                                      _chapterTitles[_currentChapterIndex],
                                      style: _getTextStyle(
                                        fontSize: _fontSize + 4,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                // Main text content with highlighting
                                _highlightedTextSpans.isNotEmpty
                                    ? RichText(
                                        text: TextSpan(children: _highlightedTextSpans),
                                        textAlign: TextAlign.justify,
                                      )
                                    : Text(
                                        _chapterContent[_currentChapterIndex] ?? '',
                                        style: _getTextStyle(fontSize: _fontSize),
                                        textAlign: TextAlign.justify,
                                      ),

                                const SizedBox(height: 100), // Bottom padding for controls
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: GestureDetector(
                        onTap: _toggleControls,
                        child: Text(
                          'No content available',
                          style: _getTextStyle(fontSize: 16),
                        ),
                      ),
                    ),
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
              if (_isTtsInitialized)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _isDarkTheme ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isTtsPlaying || _isTtsPaused ? Icons.stop : Icons.play_arrow,
                          color: _isTtsPlaying || _isTtsPaused ? Colors.red : Colors.green,
                          size: 32,
                        ),
                        onPressed: _isTtsPlaying || _isTtsPaused ? _stopTtsReading : _startTtsReading,
                      ),
                      if (_isTtsPlaying || _isTtsPaused) ...[
                        IconButton(
                          icon: Icon(
                            _isTtsPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.orange,
                            size: 28,
                          ),
                          onPressed: _isTtsPlaying ? _pauseTtsReading : _resumeTtsReading,
                        ),
                      ],
                      Expanded(
                        child: Text(
                          _isTtsPlaying || _isTtsPaused
                              ? 'Reading: ${_currentChunkIndex + 1}/${_textChunks.length}'
                              : 'Text-to-Speech',
                          style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

              // Navigation controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.list, color: _textColor),
                        onPressed: _showTableOfContents,
                      ),
                      IconButton(
                        icon: Icon(Icons.bookmarks, color: _textColor),
                        onPressed: _showBookmarks,
                      ),
                    ],
                  ),

                  // Chapter navigation
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: _textColor),
                        onPressed: _currentChapterIndex > 0 ? _previousChapter : null,
                      ),
                      Text(
                        '${_currentChapterIndex + 1} / ${_chapterContent.length}',
                        style: _getTextStyle(fontSize: 14),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: _textColor),
                        onPressed: _currentChapterIndex < _chapterContent.length - 1 ? _nextChapter : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTtsControlsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (_isDarkTheme ? Colors.grey[900] : Colors.white)?.withAlpha((0.95 * 255).round()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Text-to-Speech',
                style: _getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close, color: _textColor),
                onPressed: () => setState(() => _showTtsControls = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isTtsInitialized)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous, color: _textColor),
                  onPressed: _currentChunkIndex > 0 ? _previousTtsChunk : null,
                ),
                IconButton(
                  icon: Icon(
                    _isTtsPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.orange,
                    size: 32,
                  ),
                  onPressed: _isTtsPlaying ? _pauseTtsReading : (_isTtsPaused ? _resumeTtsReading : _startTtsReading),
                ),
                IconButton(
                  icon: Icon(Icons.stop, color: Colors.red),
                  onPressed: _stopTtsReading,
                ),
                IconButton(
                  icon: Icon(Icons.skip_next, color: _textColor),
                  onPressed: _currentChunkIndex < _textChunks.length - 1 ? _nextTtsChunk : null,
                ),
              ],
            )
          else
            Text('TTS is initializing...', style: _getTextStyle(fontSize: 14)),
          if (_isTtsPlaying || _isTtsPaused)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Reading chunk: ${_currentChunkIndex + 1}/${_textChunks.length}',
                style: _getTextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      color: Colors.black.withAlpha((0.3 * 255).round()),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _textColor.withAlpha((0.3 * 255).round()),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isDarkTheme ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: _textColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reading Settings',
                          style: _getTextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: _textColor),
                        onPressed: () => setState(() => _showSettings = false),
                      ),
                    ],
                  ),
                ),

                // Settings content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildThemeSelector(),
                      const SizedBox(height: 24),
                      _buildFontSettings(),
                      const SizedBox(height: 24),
                      _buildTtsSettings(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme',
          style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _themePresets.entries.map((entry) {
            final isSelected = _currentTheme == entry.key;
            return GestureDetector(
              onTap: () => _applyTheme(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: entry.value['backgroundColor'] as Color,
                  border: Border.all(
                    color: isSelected
                        ? (_isDarkTheme ? Colors.orange : Colors.blue)
                        : Colors.grey.withAlpha((0.3 * 255).round()),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.value['name'] as String,
                  style: TextStyle(
                    color: entry.value['textColor'] as Color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFontSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Font Settings',
          style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Font size slider
        Text('Font Size: ${_fontSize.round()}pt'),
        Slider(
          value: _fontSize,
          min: 12.0,
          max: 32.0,
          divisions: 20,
          onChanged: (value) {
            setState(() => _fontSize = value);
            _saveSettings();
          },
        ),

        const SizedBox(height: 16),

        // Line height slider
        Text('Line Height: ${_lineHeight.toStringAsFixed(1)}x'),
        Slider(
          value: _lineHeight,
          min: 1.0,
          max: 2.5,
          divisions: 15,
          onChanged: (value) {
            setState(() => _lineHeight = value);
            _saveSettings();
          },
        ),

        const SizedBox(height: 16),

        // Brightness slider
        Text('Brightness: ${(_brightness * 100).round()}%'),
        Slider(
          value: _brightness,
          min: 0.3,
          max: 1.0,
          divisions: 7,
          onChanged: (value) {
            setState(() => _brightness = value);
            _saveSettings();
          },
        ),
      ],
    );
  }

  Widget _buildTtsSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text-to-Speech',
          style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        if (_isTtsInitialized) ...[
          // Voice Selection
          Text('Voice Selection'),
          const SizedBox(height: 8),
          _buildVoiceSelector(),
          const SizedBox(height: 16),

          // TTS Rate
          Text('Speech Rate: ${(_ttsRate * 100).round()}%'),
          Slider(
            value: _ttsRate,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: (value) async {
              setState(() => _ttsRate = value);
              await _flutterTts?.setSpeechRate(value);
            },
          ),

          const SizedBox(height: 16),

          // TTS Pitch
          Text('Pitch: ${_ttsPitch.toStringAsFixed(1)}x'),
          Slider(
            value: _ttsPitch,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (value) async {
              setState(() => _ttsPitch = value);
              await _flutterTts?.setPitch(value);
            },
          ),

          const SizedBox(height: 16),

          // Language Selection
          Text('Language'),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedLanguage,
            isExpanded: true,
            items: _getFilteredLanguages().map<DropdownMenuItem<String>>((language) {
              String displayName = language;
              // Make display names more user-friendly
              switch (language) {
                case 'en-US':
                  displayName = 'English (US)';
                  break;
                case 'en-IN':
                  displayName = 'English (India)';
                  break;
                case 'en-GB':
                  displayName = 'English (UK)';
                  break;
              }
              return DropdownMenuItem<String>(
                value: language,
                child: Text(displayName, style: _getTextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (String? newLanguage) async {
              if (newLanguage != null) {
                setState(() => _selectedLanguage = newLanguage);
                await _flutterTts?.setLanguage(newLanguage);
                // Reset voice when language changes
                _selectedVoice = null;
                await _updateAvailableVoices();
              }
            },
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Text-to-Speech is initializing...',
              style: _getTextStyle(fontSize: 14, color: Colors.orange),
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceSelector() {
    if (_availableVoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Loading voices...',
          style: _getTextStyle(fontSize: 14, color: _textColor.withAlpha((0.7 * 255).round())),
        ),
      );
    }

    // Categorize voices by gender
    List<Map<String, dynamic>> maleVoices = [];
    List<Map<String, dynamic>> femaleVoices = [];
    List<Map<String, dynamic>> otherVoices = [];

    for (var voice in _availableVoices) {
      if (voice is Map<String, dynamic>) {
        String voiceName = voice['name']?.toString() ?? '';
        String voiceNameLower = voiceName.toLowerCase();

        if (voiceNameLower.contains('male') && !voiceNameLower.contains('female')) {
          maleVoices.add(voice);
        } else if (voiceNameLower.contains('female') || voiceNameLower.contains('woman')) {
          femaleVoices.add(voice);
        } else {
          // Try to categorize by common naming patterns
          if (voiceNameLower.contains('man') || voiceNameLower.contains('boy') ||
              voiceNameLower.contains('alex') || voiceNameLower.contains('tom') ||
              voiceNameLower.contains('john') || voiceNameLower.contains('david')) {
            maleVoices.add(voice);
          } else if (voiceNameLower.contains('woman') || voiceNameLower.contains('girl') ||
                     voiceNameLower.contains('mary') || voiceNameLower.contains('susan') ||
                     voiceNameLower.contains('anna') || voiceNameLower.contains('sarah')) {
            femaleVoices.add(voice);
          } else {
            otherVoices.add(voice);
          }
        }
      }
    }

    return Column(
      children: [
        // Male voices section
        if (maleVoices.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.man, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text('Male Voices', style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...maleVoices.map((voice) => _buildVoiceOption(voice)).toList(),
          const SizedBox(height: 12),
        ],

        // Female voices section
        if (femaleVoices.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.pink.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.woman, color: Colors.pink, size: 20),
                const SizedBox(width: 8),
                Text('Female Voices', style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...femaleVoices.map((voice) => _buildVoiceOption(voice)).toList(),
          const SizedBox(height: 12),
        ],

        // Other voices section
        if (otherVoices.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.record_voice_over, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text('Other Voices', style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...otherVoices.map((voice) => _buildVoiceOption(voice)).toList(),
        ],
      ],
    );
  }

  Widget _buildVoiceOption(Map<String, dynamic> voice) {
    String voiceName = voice['name']?.toString() ?? 'Unknown Voice';
    String voiceLocale = voice['locale']?.toString() ?? '';
    bool isSelected = _selectedVoice == voiceName;

    return GestureDetector(
      onTap: () async {
        setState(() => _selectedVoice = voiceName);
        await _flutterTts?.setVoice({"name": voiceName, "locale": voiceLocale});

        // Test the voice with a short sample
        await _flutterTts?.speak("Hello, this is how I sound.");
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withAlpha((0.2 * 255).round()) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.withAlpha((0.3 * 255).round()),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.orange : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voiceName,
                    style: _getTextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (voiceLocale.isNotEmpty)
                    Text(
                      voiceLocale,
                      style: _getTextStyle(
                        fontSize: 12,
                        color: _textColor.withAlpha((0.6 * 255).round()),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.play_arrow, color: Colors.orange, size: 20),
              onPressed: () async {
                // Test voice without changing selection
                await _flutterTts?.setVoice({"name": voiceName, "locale": voiceLocale});
                await _flutterTts?.speak("This is a voice preview.");
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAvailableVoices() async {
    try {
      _availableVoices = await _flutterTts!.getVoices;
      setState(() {});
    } catch (e) {
      print('Error updating available voices: $e');
    }
  }

  Widget _buildSearchResults() {
    return Container(
      color: Colors.black.withAlpha((0.3 * 255).round()),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header with search
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isDarkTheme ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: _textColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search in book...',
                            border: InputBorder.none,
                            hintStyle: _getTextStyle(fontSize: 16, color: _textColor.withAlpha((0.6 * 255).round())),
                          ),
                          style: _getTextStyle(fontSize: 16),
                          onChanged: _performSearch,
                          onSubmitted: _performSearch,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: _textColor),
                        onPressed: () => setState(() => _showSearchResults = false),
                      ),
                    ],
                  ),
                ),

                // Results
                Expanded(
                  child: _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.trim().isEmpty
                                ? 'Enter text to search'
                                : 'No results found',
                            style: _getTextStyle(fontSize: 16, color: _textColor.withAlpha((0.6 * 255).round())),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              title: Text(
                                result.chapterTitle,
                                style: _getTextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                result.excerpt,
                                style: _getTextStyle(fontSize: 12, color: _textColor.withAlpha((0.7 * 255).round())),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.play_circle_outline, color: Colors.orange),
                                onPressed: () {
                                  setState(() {
                                    _showSearchResults = false;
                                    _showControls = false;
                                  });
                                  _jumpToChapter(result.chapterIndex);
                                  _startReadingFromText(_searchController.text);
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  _currentChapterIndex = result.chapterIndex;
                                  _showSearchResults = false;
                                  _showControls = false;
                                });

                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _scrollController.jumpTo(0);
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Helper classes
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
