import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_service.dart';

class PdfReaderPage extends StatefulWidget {
  final Book book;

  const PdfReaderPage({Key? key, required this.book}) : super(key: key);

  @override
  _PdfReaderPageState createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  late PdfViewerController _pdfViewerController;
  bool _showControls = false;
  bool _showBookmarks = false;
  List<Bookmark> _bookmarks = [];
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _saveReadingProgress();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookService.getBookmarks(widget.book.id!);
    setState(() {
      _bookmarks = bookmarks;
    });
  }

  Future<void> _saveReadingProgress() async {
    if (_totalPages > 0) {
      final progress = _currentPage / _totalPages;
      await BookService.updateReadingProgress(
        widget.book.id!,
        0, // PDF doesn't have chapters
        progress,
      );
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _addBookmark() async {
    final bookmark = Bookmark(
      chapterIndex: 0,
      chapterTitle: 'Page $_currentPage',
      position: _currentPage.toDouble(),
      createdAt: DateTime.now(),
      note: 'Bookmark at page $_currentPage',
    );

    await BookService.addBookmark(widget.book.id!, bookmark);
    await _loadBookmarks();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark added')),
    );
  }

  void _jumpToBookmark(Bookmark bookmark) {
    _pdfViewerController.jumpToPage(bookmark.position.toInt());
    setState(() {
      _showBookmarks = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.title,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            onPressed: _addBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: () => setState(() => _showBookmarks = !_showBookmarks),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleControls,
            child: SfPdfViewer.file(
              File(widget.book.filePath),
              controller: _pdfViewerController,
              onPageChanged: (PdfPageChangedDetails details) {
                setState(() {
                  _currentPage = details.newPageNumber;
                });
                _saveReadingProgress();
              },
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _totalPages = details.document.pages.count;
                });

                // Navigate to last read page after document is loaded
                if (widget.book.progress > 0 && _totalPages > 0) {
                  Future.delayed(Duration(milliseconds: 200), () {
                    final lastPage = (widget.book.progress * _totalPages)
                        .round()
                        .clamp(1, _totalPages);
                    if (lastPage > 1) {
                      _pdfViewerController.jumpToPage(lastPage);
                      setState(() {
                        _currentPage = lastPage;
                      });
                      print(
                          'PDF: Navigating to last read page: $lastPage of $_totalPages (${(widget.book.progress * 100).toStringAsFixed(1)}%)');
                    }
                  });
                }
              },
            ),
          ),

          // Controls overlay
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Page $_currentPage of $_totalPages',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          '${(_currentPage / _totalPages * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pdfViewerController.previousPage(),
                          icon: const Icon(Icons.navigate_before),
                          label: const Text('Previous'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _pdfViewerController.nextPage(),
                          icon: const Icon(Icons.navigate_next),
                          label: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Bookmarks panel
          if (_showBookmarks)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.7,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bookmarks',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _showBookmarks = false),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _bookmarks.length,
                        itemBuilder: (context, index) {
                          final bookmark = _bookmarks[index];
                          return ListTile(
                            leading: const Icon(Icons.bookmark),
                            title: Text(bookmark.chapterTitle),
                            subtitle: Text(bookmark.note ?? ''),
                            onTap: () => _jumpToBookmark(bookmark),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await BookService.deleteBookmark(bookmark.id!);
                                await _loadBookmarks();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
