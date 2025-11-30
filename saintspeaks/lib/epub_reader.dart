import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:epubx/epubx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  }

  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    if (_hasUnsavedProgress) {
      _saveReadingProgressImmediate();
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
                            color: _textColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookmarks yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: _textColor.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the bookmark button to save your current position',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _textColor.withValues(alpha: 0.5),
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
                                ? (_isDarkTheme ? Colors.orange[900]?.withValues(alpha: 0.3) : Colors.orange[50])
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _textColor.withValues(alpha: 0.1),
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
                                    color: _textColor.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Added: ${_formatDate(bookmark.createdAt)}',
                                  style: TextStyle(
                                    color: _textColor.withValues(alpha: 0.5),
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
                                color: _textColor.withValues(alpha: 0.6),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: Text(widget.book.title),
          backgroundColor: _backgroundColor,
          foregroundColor: _textColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _textColor),
              const SizedBox(height: 16),
              Text(
                'Loading book...',
                style: TextStyle(color: _textColor, fontSize: 16),
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
          title: Text(widget.book.title),
          backgroundColor: _backgroundColor,
          foregroundColor: _textColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: _textColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _showControls ? AppBar(
        title: Text(
          widget.book.title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _showSearchResults = !_showSearchResults;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            onPressed: _addBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: _showBookmarks,
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showTableOfContents,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => setState(() {
              _showSettings = !_showSettings;
            }),
          ),
        ],
      ) : null,
      body: Stack(
        children: [
          // Main reading content
          GestureDetector(
            onTap: _toggleControls,
            child: SafeArea(
              child: _chapterContent.isEmpty ?
                Center(child: Text('No content available', style: TextStyle(color: _textColor))) :
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    padding: _textPadding,
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
                                fontSize: _fontSize + 6,
                                fontWeight: FontWeight.bold,
                                height: _lineHeight,
                              ),
                            ),
                          ),
                        // Chapter content with improved formatting
                        SelectableText(
                          _chapterContent[_currentChapterIndex] ?? 'No content available',
                          style: _getTextStyle(
                            fontSize: _fontSize,
                            height: _lineHeight,
                            wordSpacing: _wordSpacing,
                            letterSpacing: _letterSpacing,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        // Navigation buttons at bottom
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentChapterIndex > 0)
                              ElevatedButton.icon(
                                onPressed: _previousChapter,
                                icon: Icon(Icons.arrow_back),
                                label: Text('Previous'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isDarkTheme ? Colors.grey[700] : Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              )
                            else
                              const SizedBox(),
                            if (_currentChapterIndex < _chapterContent.length - 1)
                              ElevatedButton.icon(
                                onPressed: _nextChapter,
                                icon: Icon(Icons.arrow_forward),
                                label: Text('Next'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isDarkTheme ? Colors.grey[700] : Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              )
                            else
                              const SizedBox(),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
            ),
          ),

          // Progress indicator at bottom
          if (_showControls && _chapterContent.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _backgroundColor.withValues(alpha: 0.9),
                  border: Border(top: BorderSide(color: _textColor.withValues(alpha: 0.2))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Chapter ${_currentChapterIndex + 1} of ${_chapterContent.length}',
                          style: TextStyle(color: _textColor, fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          '${((_currentChapterIndex + 1) / _chapterContent.length * 100).toInt()}%',
                          style: TextStyle(color: _textColor, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_currentChapterIndex + 1) / _chapterContent.length,
                      backgroundColor: _textColor.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isDarkTheme ? Colors.blue[300]! : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Search results overlay
          if (_showSearchResults)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: _backgroundColor.withValues(alpha: 0.95),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Search input
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(color: _textColor),
                                decoration: InputDecoration(
                                  hintText: 'Search in book...',
                                  hintStyle: TextStyle(color: _textColor.withValues(alpha: 0.6)),
                                  prefixIcon: Icon(Icons.search, color: _textColor),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: _textColor.withValues(alpha: 0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: _isDarkTheme ? Colors.blue[300]! : Colors.blue),
                                  ),
                                ),
                                onChanged: _performSearch,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showSearchResults = false;
                                  _searchController.clear();
                                  _searchResults.clear();
                                });
                              },
                              icon: Icon(Icons.close, color: _textColor),
                            ),
                          ],
                        ),
                      ),
                      // Search results
                      Expanded(
                        child: _searchResults.isEmpty
                            ? Center(
                                child: Text(
                                  _searchController.text.isEmpty
                                      ? 'Enter search terms above'
                                      : 'No results found',
                                  style: TextStyle(color: _textColor.withValues(alpha: 0.6)),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final result = _searchResults[index];
                                  return ListTile(
                                    title: Text(
                                      result.chapterTitle,
                                      style: TextStyle(
                                        color: _textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      result.excerpt,
                                      style: TextStyle(color: _textColor.withValues(alpha: 0.8)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () {
                                      _jumpToChapter(result.chapterIndex);
                                      setState(() {
                                        _showSearchResults = false;
                                        _searchController.clear();
                                        _searchResults.clear();
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Settings panel
          if (_showSettings)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.8,
              child: Container(
                color: _backgroundColor,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Settings header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isDarkTheme ? Colors.grey[800] : Colors.blue,
                          border: Border(bottom: BorderSide(color: _textColor.withValues(alpha: 0.2))),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.settings, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              'Reading Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => setState(() => _showSettings = false),
                              icon: Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      // Settings content
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Theme selection
                            Text('Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _themePresets.entries.map((entry) {
                                final isSelected = _currentTheme == entry.key;
                                return ChoiceChip(
                                  label: Text(entry.value['name']),
                                  selected: isSelected,
                                  onSelected: (_) => _applyTheme(entry.key),
                                  selectedColor: _isDarkTheme ? Colors.blue[700] : Colors.blue[200],
                                  backgroundColor: _isDarkTheme ? Colors.grey[700] : Colors.grey[200],
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : _textColor,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            // Font size
                            Text('Font Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor)),
                            Slider(
                              value: _fontSize,
                              min: 12.0,
                              max: 30.0,
                              divisions: 18,
                              label: _fontSize.round().toString(),
                              onChanged: (value) {
                                setState(() => _fontSize = value);
                                _saveSettings();
                              },
                            ),
                            const SizedBox(height: 16),

                            // Line height
                            Text('Line Spacing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor)),
                            Slider(
                              value: _lineHeight,
                              min: 1.0,
                              max: 2.5,
                              divisions: 15,
                              label: _lineHeight.toStringAsFixed(1),
                              onChanged: (value) {
                                setState(() => _lineHeight = value);
                                _saveSettings();
                              },
                            ),
                            const SizedBox(height: 16),

                            // Font family
                            Text('Font', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _fontOptions.keys.map((font) {
                                final fontOption = _fontOptions[font]!;
                                return ChoiceChip(
                                  label: Text(
                                    font,
                                    style: fontOption['isSystemFont'] == true
                                        ? TextStyle(fontFamily: fontOption['fontFamily'])
                                        : (fontOption['fontFamily'] != null
                                            ? ((){
                                                try {
                                                  return GoogleFonts.getFont(fontOption['fontFamily']);
                                                } catch (e) {
                                                  return const TextStyle();
                                                }
                                              })()
                                            : const TextStyle()),
                                  ),
                                  selected: _fontFamily == font,
                                  onSelected: (_) {
                                    setState(() => _fontFamily = font);
                                    _saveSettings();
                                  },
                                  selectedColor: _isDarkTheme ? Colors.blue[700] : Colors.blue[200],
                                  backgroundColor: _isDarkTheme ? Colors.grey[700] : Colors.grey[200],
                                  labelStyle: TextStyle(
                                    color: _fontFamily == font ? Colors.white : _textColor,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            // Word spacing
                            Text('Word Spacing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor)),
                            Slider(
                              value: _wordSpacing,
                              min: 0.5,
                              max: 2.0,
                              divisions: 15,
                              label: _wordSpacing.toStringAsFixed(1),
                              onChanged: (value) {
                                setState(() => _wordSpacing = value);
                                _saveSettings();
                              },
                            ),
                            const SizedBox(height: 16),

                            // Letter spacing
                            Text('Letter Spacing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor)),
                            Slider(
                              value: _letterSpacing,
                              min: -0.5,
                              max: 2.0,
                              divisions: 25,
                              label: _letterSpacing.toStringAsFixed(1),
                              onChanged: (value) {
                                setState(() => _letterSpacing = value);
                                _saveSettings();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
