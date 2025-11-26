import 'dart:io';
import 'dart:convert'; // Add this import for jsonEncode/jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:epubx/epubx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'book_service.dart';
import 'table_of_contents.dart';

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

  // Reading settings
  double _fontSize = 16.0;
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black;
  String _fontFamily = 'Roboto';
  double _lineHeight = 1.5;
  double _brightness = 1.0;
  bool _isDarkTheme = false;
  bool _isNightMode = false; // Enhanced night mode flag

  // Night mode presets
  Map<String, Map<String, dynamic>> _themePresets = {
    'light': {
      'backgroundColor': Colors.white,
      'textColor': Colors.black87,
      'brightness': 1.0,
      'isNight': false,
    },
    'sepia': {
      'backgroundColor': Color(0xFFF4ECD8),
      'textColor': Color(0xFF5C4B37),
      'brightness': 0.9,
      'isNight': false,
    },
    'dark': {
      'backgroundColor': Color(0xFF2E2E2E),
      'textColor': Colors.white70,
      'brightness': 0.8,
      'isNight': true,
    },
    'night': {
      'backgroundColor': Color(0xFF1A1A1A),
      'textColor': Color(0xFFE0E0E0),
      'brightness': 0.7,
      'isNight': true,
    },
  };

  String _currentTheme = 'light';

  // Page-by-page navigation
  List<String> _pages = [];
  int _currentPageIndex = 0;
  int _currentChapterIndex = 0;
  List<EpubChapter> _chapters = [];
  bool _showControls = false;
  bool _showSettings = false;
  bool _showChaptersList = false;

  // Search
  TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _showSearchResults = false;

  // Bookmarks and Highlights
  List<Bookmark> _bookmarks = [];
  List<Highlight> _highlights = [];
  bool _isSelecting = false;
  String _selectedText = '';

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load settings first to get theme
    _loadBookmarks();
    _loadHighlights();
    _loadBook(); // Load book first, then position will be restored after pages are generated
    _currentChapterIndex = widget.book.currentChapter;

    // Auto-hide system UI for immersive reading
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadBook() async {
    try {
      final file = File(widget.book.filePath);
      final bytes = await file.readAsBytes();
      final book = await EpubReader.readBook(bytes);

      setState(() {
        _epubBook = book;
        if (book.Chapters != null && book.Chapters!.isNotEmpty) {
          _chapters = book.Chapters!;
        } else {
          final found = <EpubChapter>[];
          final spineItems = book.Schema?.Package?.Spine?.Items;
          final manifestItems = book.Schema?.Package?.Manifest?.Items;
          final chaptersList = book.Chapters;

          if (spineItems != null) {
            for (final item in spineItems) {
              final idRef = item.IdRef;

              EpubManifestItem? manifestItem;
              if (manifestItems != null) {
                for (final m in manifestItems) {
                  if (m.Id == idRef) {
                    manifestItem = m;
                    break;
                  }
                }
              }

              final href = manifestItem?.Href;

              EpubChapter? chapterByContent;
              if (chaptersList != null) {
                for (final c in chaptersList) {
                  final filename = c.ContentFileName;
                  if (filename != null && (filename == href || filename == href?.split('/')?.last)) {
                    chapterByContent = c;
                    break;
                  }
                }
              }

              if (chapterByContent != null) {
                found.add(chapterByContent);
              }
            }
          }

          _chapters = found;
        }
        _isLoading = false;
      });

      _generatePages();
    } catch (e) {
      setState(() {
        _error = 'Failed to load book: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLastReadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPageIndex = prefs.getInt('last_page_${widget.book.id}') ?? 0;
    final savedChapterIndex = prefs.getInt('last_chapter_${widget.book.id}') ?? 0;

    setState(() {
      _currentPageIndex = savedPageIndex;
      _currentChapterIndex = savedChapterIndex;
    });
  }

  Future<void> _saveLastReadPosition() async {
    if (widget.book.id != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_page_${widget.book.id}', _currentPageIndex);
      await prefs.setInt('last_chapter_${widget.book.id}', _currentChapterIndex);
    }
  }

  Future<void> _generatePages() async {
    if (_chapters.isEmpty) return;

    final pages = <String>[];

    for (final chapter in _chapters) {
      final htmlContent = chapter.HtmlContent ?? '';
      if (htmlContent.isNotEmpty) {
        // Split content into pages based on estimated screen capacity
        final cleanContent = _cleanHtmlContent(htmlContent);
        final chapterPages = _splitContentIntoPages(cleanContent);
        pages.addAll(chapterPages);
      }
    }

    // Load the last read position after pages are generated
    await _loadLastReadPosition();

    setState(() {
      _pages = pages;
      // Ensure current page is within bounds
      _currentPageIndex = _currentPageIndex.clamp(0, _pages.length - 1);
    });

    if (_pages.isNotEmpty && _currentPageIndex > 0) {
      // Navigate to the saved page position
      await Future.delayed(Duration(milliseconds: 100)); // Small delay to ensure UI is ready
      _pageController.animateToPage(
        _currentPageIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _cleanHtmlContent(String html) {
    // Clean HTML content while preserving paragraph structure
    return html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, multiLine: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, multiLine: true), '')
        // Convert common HTML entities
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        // Normalize whitespace but keep paragraph structure
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _splitContentIntoPages(String content) {
    final pages = <String>[];

    // Split by paragraphs to maintain structure
    final paragraphs = content.split(RegExp(r'</p>|<br[^>]*>', caseSensitive: false));
    final wordsPerPage = _calculateWordsPerPage();

    String currentPage = '';
    int currentWordCount = 0;

    for (String paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) continue;

      // Clean up paragraph but keep basic structure
      String cleanParagraph = paragraph
          .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '')
          .trim();

      if (cleanParagraph.isEmpty) continue;

      final words = cleanParagraph.split(' ');

      // If adding this paragraph would exceed page limit, start new page
      if (currentWordCount > 0 && currentWordCount + words.length > wordsPerPage) {
        if (currentPage.trim().isNotEmpty) {
          pages.add('<div style="line-height: ${_lineHeight};">' + currentPage + '</div>');
        }
        currentPage = '';
        currentWordCount = 0;
      }

      // Add paragraph with proper spacing
      if (currentPage.isNotEmpty) {
        currentPage += '<br><br>';
      }
      currentPage += '<p>' + cleanParagraph + '</p>';
      currentWordCount += words.length;
    }

    // Add remaining content
    if (currentPage.trim().isNotEmpty) {
      pages.add('<div style="line-height: ${_lineHeight};">' + currentPage + '</div>');
    }

    return pages.isEmpty ? ['<p>No content available</p>'] : pages;
  }

  int _calculateWordsPerPage() {
    // Estimate words per page based on font size and screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height - 200; // Account for UI elements
    final availableWidth = screenSize.width - 64; // Account for padding

    final linesPerPage = (availableHeight / (_fontSize * _lineHeight)).floor();
    final charactersPerLine = (availableWidth / (_fontSize * 0.6)).floor();
    final wordsPerLine = (charactersPerLine / 6).floor(); // Average word length

    return (linesPerPage * wordsPerLine).clamp(50, 500);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('epub_font_size') ?? 16.0;
      _fontFamily = prefs.getString('epub_font_family') ?? 'Roboto';
      _lineHeight = prefs.getDouble('epub_line_height') ?? 1.5;
      _brightness = prefs.getDouble('epub_brightness') ?? 1.0;
      _isDarkTheme = prefs.getBool('epub_dark_theme') ?? false;
      _isNightMode = prefs.getBool('epub_night_mode') ?? false;

      // Apply theme colors based on dark theme setting
      if (_isDarkTheme) {
        _backgroundColor = Color(prefs.getInt('epub_bg_color') ?? Color(0xFF1E1E1E).value);
        _textColor = Color(prefs.getInt('epub_text_color') ?? Colors.white.value);
      } else {
        _backgroundColor = Color(prefs.getInt('epub_bg_color') ?? Colors.white.value);
        _textColor = Color(prefs.getInt('epub_text_color') ?? Colors.black.value);
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('epub_font_size', _fontSize);
    await prefs.setString('epub_font_family', _fontFamily);
    await prefs.setDouble('epub_line_height', _lineHeight);
    await prefs.setDouble('epub_brightness', _brightness);
    await prefs.setBool('epub_dark_theme', _isDarkTheme);
    await prefs.setBool('epub_night_mode', _isNightMode);
    await prefs.setInt('epub_bg_color', _backgroundColor.value);
    await prefs.setInt('epub_text_color', _textColor.value);
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList('bookmarks_${widget.book.id}') ?? [];
    setState(() {
      _bookmarks = bookmarksJson.map((json) => Bookmark.fromJson(json)).toList();
    });
  }

  Future<void> _loadHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = prefs.getStringList('highlights_${widget.book.id}') ?? [];
    setState(() {
      _highlights = highlightsJson.map((json) => Highlight.fromJson(json)).toList();
    });
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = _bookmarks.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList('bookmarks_${widget.book.id}', bookmarksJson);
  }

  Future<void> _saveHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = _highlights.map((h) => h.toJson()).toList();
    await prefs.setStringList('highlights_${widget.book.id}', highlightsJson);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      _showSettings = false;
      _showChaptersList = false;
      _showSearchResults = false;
    });
  }

  void _nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      setState(() {
        _currentPageIndex++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateReadingProgress();
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateReadingProgress();
    }
  }

  void _updateReadingProgress() {
    if (_pages.isNotEmpty && widget.book.id != null) {
      final progress = _currentPageIndex / _pages.length;
      BookService.updateReadingProgress(
        widget.book.id!,
        _currentChapterIndex,
        progress.clamp(0.0, 1.0),
      );
      _saveLastReadPosition(); // Save current position
    }
  }

  void _addBookmark() {
    final bookmark = Bookmark(
      chapterIndex: _currentPageIndex,
      chapterTitle: 'Page ${_currentPageIndex + 1}',
      position: _currentPageIndex.toDouble(),
      createdAt: DateTime.now(),
    );

    setState(() {
      _bookmarks.add(bookmark);
    });

    _saveBookmarks();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bookmark added!')),
    );
  }

  void _showTableOfContents() {
    if (_epubBook != null) {
      _showTableOfContentsDialog();
    }
  }

  void _showTableOfContentsDialog() {
    final chapters = _extractChapters();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.list, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Table of Contents',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: chapters.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No table of contents available',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = chapters[index];
                          final isCurrentChapter = index == _currentChapterIndex;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentChapter
                                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              border: isCurrentChapter
                                  ? Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: isCurrentChapter
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
                                chapter,
                                style: TextStyle(
                                  fontWeight: isCurrentChapter
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isCurrentChapter
                                      ? Theme.of(context).primaryColor
                                      : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isCurrentChapter
                                  ? Icon(
                                      Icons.play_circle_filled,
                                      color: Theme.of(context).primaryColor,
                                    )
                                  : const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.of(context).pop();
                                _jumpToChapter(index);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _extractChapters() {
    final List<String> chapters = [];

    try {
      // Try to get navigation from NCX first (better structure)
      final navigation = _epubBook?.Schema?.Navigation;
      if (navigation?.NavMap?.Points != null) {
        for (final navPoint in navigation!.NavMap!.Points!) {
          final title = navPoint.NavigationLabels?.isNotEmpty == true
              ? navPoint.NavigationLabels!.first.Text ?? 'Chapter ${chapters.length + 1}'
              : 'Chapter ${chapters.length + 1}';

          chapters.add(title);
        }
      }

      // Fallback to chapters list if NCX navigation is not available
      if (chapters.isEmpty && _epubBook?.Chapters != null) {
        for (int i = 0; i < _epubBook!.Chapters!.length; i++) {
          final chapter = _epubBook!.Chapters![i];
          String title = chapter.Title ?? 'Chapter ${i + 1}';

          // Clean up the title
          title = title.trim();
          if (title.isEmpty) {
            title = 'Chapter ${i + 1}';
          }

          chapters.add(title);
        }
      }

      // Last resort: create generic chapter list
      if (chapters.isEmpty) {
        // Try to extract from spine
        final spine = _epubBook?.Schema?.Package?.Spine?.Items;
        if (spine != null) {
          for (int i = 0; i < spine.length; i++) {
            chapters.add('Chapter ${i + 1}');
          }
        }
      }
    } catch (e) {
      print('Error extracting chapters: $e');
    }

    return chapters;
  }

  void _jumpToChapter(int chapterIndex) {
    if (chapterIndex >= 0 && chapterIndex < _chapters.length) {
      setState(() {
        _currentChapterIndex = chapterIndex;
      });

      // Find the page index for this chapter
      int pageIndex = 0;
      for (int i = 0; i < chapterIndex; i++) {
        final chapterContent = _chapters[i].HtmlContent ?? '';
        final cleanContent = _cleanHtmlContent(chapterContent);
        final chapterPages = _splitContentIntoPages(cleanContent);
        pageIndex += chapterPages.length;
      }

      setState(() {
        _currentPageIndex = pageIndex.clamp(0, _pages.length - 1);
      });

      _pageController.animateToPage(
        _currentPageIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      _updateReadingProgress();
    }
  }

  void _addHighlight(String text, Color color) {
    final highlight = Highlight(
      pageIndex: _currentPageIndex,
      text: text,
      color: color,
      createdAt: DateTime.now(),
    );

    setState(() {
      _highlights.add(highlight);
      _isSelecting = false;
      _selectedText = '';
    });

    _saveHighlights();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text highlighted!')),
    );
  }

  void _showHighlightDialog(String selectedText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Highlight Text'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select highlight color:'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHighlightColorButton(Colors.yellow, selectedText),
                _buildHighlightColorButton(Colors.green.shade200, selectedText),
                _buildHighlightColorButton(Colors.blue.shade200, selectedText),
                _buildHighlightColorButton(Colors.pink.shade200, selectedText),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightColorButton(Color color, String text) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _addHighlight(text, color);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    if (_pages.isEmpty) {
      return Center(child: Text('No content available'));
    }

    return Container(
      color: _backgroundColor.withValues(alpha: _brightness),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
          _updateReadingProgress();
        },
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: _toggleControls,
            onLongPress: () {
              // Enable text selection mode
              setState(() {
                _isSelecting = true;
              });
            },
            child: Container(
              padding: EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Html(
                        data: _pages[index],
                        style: {
                          "body": Style(
                            fontFamily: _fontFamily,
                            fontSize: FontSize(_fontSize),
                            color: _textColor,
                            lineHeight: LineHeight(_lineHeight),
                            backgroundColor: _backgroundColor.withValues(alpha: _brightness),
                          ),
                        },
                      ),
                    ),
                  ),
                  // Page indicator
                  Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      '${index + 1} of ${_pages.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      top: _showControls ? 0 : -100,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                widget.book.title,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.bookmark_add, color: Colors.white),
              onPressed: _addBookmark,
            ),
            IconButton(
              icon: Icon(Icons.toc, color: Colors.white),
              onPressed: _showTableOfContents,
              tooltip: 'Table of Contents',
            ),
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showSearchResults = !_showSearchResults;
                  _showSettings = false;
                  _showChaptersList = false;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                  _showSearchResults = false;
                  _showChaptersList = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      bottom: _showControls ? 0 : -100,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            Container(
              margin: EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Page ${_currentPageIndex + 1} of ${_pages.length}',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${(_currentPageIndex / _pages.length * 100).toInt()}%',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _pages.isEmpty ? 0 : _currentPageIndex / _pages.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                  ),
                ],
              ),
            ),
            // Navigation controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: _currentPageIndex > 0 ? _previousPage : null,
                ),
                IconButton(
                  icon: Icon(Icons.list, color: Colors.white),
                  onPressed: () => _showBookmarksDialog(),
                ),
                IconButton(
                  icon: Icon(Icons.highlight, color: Colors.white),
                  onPressed: () => _showHighlightsDialog(),
                ),
                IconButton(
                  icon: Icon(Icons.skip_next, color: Colors.white),
                  onPressed: _currentPageIndex < _pages.length - 1 ? _nextPage : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      right: _showSettings ? 0 : -300,
      top: 100,
      bottom: 100,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: _isDarkTheme ? Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: Offset(-5, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkTheme ? Color(0xFF404040) : Colors.grey.shade100,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.settings,
                    color: _isDarkTheme ? Colors.white : Colors.black87,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Reading Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Font size
                  Text(
                    'Font Size',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                  Slider(
                    value: _fontSize,
                    min: 12.0,
                    max: 24.0,
                    divisions: 12,
                    label: _fontSize.round().toString(),
                    activeColor: Colors.deepOrange,
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value;
                      });
                      _saveSettings();
                      _generatePages(); // Regenerate pages with new font size
                    },
                  ),
                  SizedBox(height: 16),

                  // Line height
                  Text(
                    'Line Spacing',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                  Slider(
                    value: _lineHeight,
                    min: 1.0,
                    max: 2.0,
                    divisions: 10,
                    label: _lineHeight.toStringAsFixed(1),
                    activeColor: Colors.deepOrange,
                    onChanged: (value) {
                      setState(() {
                        _lineHeight = value;
                      });
                      _saveSettings();
                    },
                  ),
                  SizedBox(height: 16),

                  // Brightness (only for dark themes)
                  if (_isDarkTheme) ...[
                    Text(
                      'Brightness',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Slider(
                      value: _brightness,
                      min: 0.3,
                      max: 1.0,
                      divisions: 7,
                      label: '${(_brightness * 100).round()}%',
                      activeColor: Colors.deepOrange,
                      onChanged: (value) {
                        setState(() {
                          _brightness = value;
                        });
                        _saveSettings();
                      },
                    ),
                    SizedBox(height: 16),
                  ],

                  // Theme presets
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),

                  // Theme preset buttons
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildThemePresetButton(
                              'Light',
                              Colors.white,
                              Colors.black,
                              Icons.light_mode,
                              'light',
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildThemePresetButton(
                              'Dark',
                              Color(0xFF1E1E1E),
                              Colors.white,
                              Icons.dark_mode,
                              'dark',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildThemePresetButton(
                              'Sepia',
                              Color(0xFFF5F5DC),
                              Color(0xFF5D4037),
                              Icons.auto_stories,
                              'sepia',
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildThemePresetButton(
                              'Night',
                              Colors.black,
                              Color(0xFFE0E0E0),
                              Icons.nightlight_round,
                              'night',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Font family
                  Text(
                    'Font',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isDarkTheme ? Colors.grey.shade600 : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _fontFamily,
                        isExpanded: true,
                        dropdownColor: _isDarkTheme ? Color(0xFF404040) : Colors.white,
                        style: TextStyle(
                          color: _isDarkTheme ? Colors.white : Colors.black87,
                        ),
                        items: [
                          'Roboto',
                          'Open Sans',
                          'Lato',
                          'Playfair Display',
                          'Merriweather',
                          'Georgia',
                        ].map((font) => DropdownMenuItem(
                          value: font,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(font),
                          ),
                        )).toList(),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePresetButton(String name, Color bg, Color text, IconData icon, String preset) {
    final isSelected = _backgroundColor.value == bg.value && _textColor.value == text.value;

    return GestureDetector(
      onTap: () => _applyThemePreset(preset),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepOrange : Colors.grey.shade400,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.deepOrange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: text,
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                color: text,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bookmarks'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: _bookmarks.isEmpty
              ? Center(child: Text('No bookmarks yet'))
              : ListView.builder(
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = _bookmarks[index];
                    return ListTile(
                      title: Text(bookmark.chapterTitle),
                      subtitle: Text('Added ${bookmark.createdAt.day}/${bookmark.createdAt.month}/${bookmark.createdAt.year}'),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentPageIndex = bookmark.position.toInt().clamp(0, _pages.length - 1);
                        });
                        _pageController.animateToPage(
                          _currentPageIndex,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHighlightsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Highlights'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: _highlights.isEmpty
              ? Center(child: Text('No highlights yet'))
              : ListView.builder(
                  itemCount: _highlights.length,
                  itemBuilder: (context, index) {
                    final highlight = _highlights[index];
                    return ListTile(
                      title: Text(
                        highlight.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(backgroundColor: highlight.color.withValues(alpha: 0.3)),
                      ),
                      subtitle: Text('Page ${highlight.pageIndex + 1}'),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentPageIndex = highlight.pageIndex.clamp(0, _pages.length - 1);
                        });
                        _pageController.animateToPage(
                          _currentPageIndex,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
      if (_isDarkTheme) {
        _backgroundColor = Color(0xFF1E1E1E);
        _textColor = Colors.white;
      } else {
        _backgroundColor = Colors.white;
        _textColor = Colors.black;
      }
    });
    _saveSettings();
  }

  void _applyThemePreset(String preset) {
    setState(() {
      switch (preset) {
        case 'light':
          _isDarkTheme = false;
          _backgroundColor = Colors.white;
          _textColor = Colors.black;
          break;
        case 'dark':
          _isDarkTheme = true;
          _backgroundColor = Color(0xFF1E1E1E);
          _textColor = Colors.white;
          break;
        case 'sepia':
          _isDarkTheme = false;
          _backgroundColor = Color(0xFFF5F5DC);
          _textColor = Color(0xFF5D4037);
          break;
        case 'night':
          _isDarkTheme = true;
          _backgroundColor = Colors.black;
          _textColor = Color(0xFFE0E0E0);
          break;
      }
    });
    _saveSettings();
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              ),
              SizedBox(height: 16),
              Text('Loading book...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_error, textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          _buildPageContent(),
          _buildControlsOverlay(),
          _buildBottomControls(),
          _buildSettingsPanel(),
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

class Bookmark {
  final int chapterIndex;
  final String chapterTitle;
  final double position;
  final DateTime createdAt;

  Bookmark({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.position,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'chapterIndex': chapterIndex,
      'chapterTitle': chapterTitle,
      'position': position,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromJson(String json) {
    final data = jsonDecode(json);
    return Bookmark(
      chapterIndex: data['chapterIndex'],
      chapterTitle: data['chapterTitle'],
      position: data['position'],
      createdAt: DateTime.parse(data['createdAt']),
    );
  }
}

class Highlight {
  final int? id;
  final int pageIndex;
  final String text;
  final Color color;
  final DateTime createdAt;
  final String? note;

  Highlight({
    this.id,
    required this.pageIndex,
    required this.text,
    required this.color,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pageIndex': pageIndex,
      'text': text,
      'color': color.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory Highlight.fromMap(Map<String, dynamic> map) {
    return Highlight(
      id: map['id'],
      pageIndex: map['pageIndex'],
      text: map['text'],
      color: Color(map['color']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      note: map['note'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Highlight.fromJson(String source) => Highlight.fromMap(jsonDecode(source));
}
