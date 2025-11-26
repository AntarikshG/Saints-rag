import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_service.dart';
import 'epub_reader.dart';
import 'l10n/app_localizations.dart';

class BooksTab extends StatefulWidget {
  final String saintId;
  final String saintName;

  BooksTab({required this.saintId, required this.saintName});

  @override
  _BooksTabState createState() => _BooksTabState();
}

class _BooksTabState extends State<BooksTab> {
  List<Book> _books = [];
  bool _isLoading = true;
  TextEditingController _urlController = TextEditingController();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _addSampleBooksIfNeeded();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load books specific to this saint
      final books = await BookService.getBooksForSaint(widget.saintName);
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading books: $e')),
      );
    }
  }

  Future<void> _addSampleBooksIfNeeded() async {
    // Add sample books for Swami Sivananda
    if (widget.saintName.toLowerCase().contains('sivananda')) {
      try {
        await BookService.addSampleBooksForSivananda();
        // Also try to download the actual EPUB from the provided URL
        await _downloadSampleBook();
      } catch (e) {
        print('Error adding sample books: $e');
      }
    }
  }

  Future<void> _downloadSampleBook() async {
    const sampleUrl = 'https://www.dlshq.org/download2/hinduismbk.epub';
    try {
      // Check if this book already exists
      final existingBooks = await BookService.searchBooks('Bliss Divine');
      bool hasRealBook = existingBooks.any((book) => !book.filePath.startsWith('sample_'));

      if (!hasRealBook) {
        await BookService.downloadBookFromUrl(sampleUrl);
        _loadBooks(); // Refresh the list
      }
    } catch (e) {
      print('Could not download sample book: $e');
      // This is fine, we'll fall back to the placeholder
    }
  }

  Future<void> _downloadBook(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    // Validate URL format
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    // Check if URL points to an EPUB file
    if (!url.toLowerCase().endsWith('.epub')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL must point to an EPUB file (.epub)')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Starting download...';
    });

    try {
      final book = await BookService.downloadBookFromUrl(
        url,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
            _downloadStatus = 'Downloading... ${(progress * 100).toInt()}%';
          });
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully downloaded "${book.title}"'),
          backgroundColor: Colors.green,
        ),
      );

      _urlController.clear();
      _loadBooks(); // Refresh the book list
    } catch (e) {
      String errorMessage = 'Error downloading book: $e';
      Color backgroundColor = Colors.red;

      // Check for specific error types to show better messages
      if (e.toString().contains('already exists in your library') ||
          e.toString().contains('already been downloaded')) {
        errorMessage = 'Book already exists in your library';
        backgroundColor = Colors.orange;
      } else if (e.toString().contains('HTTP')) {
        errorMessage = 'Failed to download: Network error';
      } else if (e.toString().contains('Failed to process EPUB')) {
        errorMessage = 'Invalid EPUB file format';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: backgroundColor,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
        _downloadStatus = '';
      });
    }
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EpubReaderPage(book: book),
      ),
    );
  }

  void _deleteBook(Book book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Book'),
          content: Text('Are you sure you want to delete "${book.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await BookService.deleteBook(book.id!);
                Navigator.pop(context);
                _loadBooks();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Book deleted successfully')),
                );
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddBookDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Book from URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'Enter EPUB URL (e.g., https://example.com/book.epub)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Sample URL:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    SelectableText(
                      'https://www.dlshq.org/download2/hinduismbk.epub',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to copy this sample URL and paste it above.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Only EPUB files are supported. The book will be downloaded and added to your library.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (_isDownloading) ...[
                SizedBox(height: 16),
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _downloadStatus,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isDownloading ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _urlController.text = 'https://www.dlshq.org/download2/hinduismbk.epub';
              },
              child: Text('Use Sample URL'),
            ),
            TextButton(
              onPressed: _isDownloading
                  ? null
                  : () {
                      _downloadBook(_urlController.text);
                      Navigator.pop(context);
                    },
              child: _isDownloading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Download Book'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookCard(Book book) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openBook(book),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Book cover placeholder
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepOrange.shade300),
                ),
                child: book.coverPath != null && File(book.coverPath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(book.coverPath!), fit: BoxFit.cover),
                      )
                    : Icon(Icons.menu_book, size: 30, color: Colors.deepOrange),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (book.progress > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress: ${(book.progress * 100).toInt()}%',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: book.progress,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                          ),
                        ],
                      ),
                    if (book.lastRead != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Last read: ${book.lastRead!.day}/${book.lastRead!.month}/${book.lastRead!.year}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'delete') {
                    _deleteBook(book);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepOrange.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              ),
              SizedBox(height: 16),
              Text('Loading books...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.deepOrange.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          // Header with add book button
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.saintName} Books',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_books.length} book${_books.length != 1 ? 's' : ''} in your library',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddBookDialog,
                  icon: Icon(Icons.add, size: 20),
                  label: Text('Add Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          // Books list
          Expanded(
            child: _books.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.library_books,
                            size: 64,
                            color: Colors.orange.shade300,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'No books yet',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Add your first book by tapping "Add Book" above',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddBookDialog,
                          icon: Icon(Icons.add),
                          label: Text('Add Your First Book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadBooks,
                    child: ListView.builder(
                      padding: EdgeInsets.only(bottom: 16),
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        return _buildBookCard(_books[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Books Library Page (accessible from main menu)
class AllBooksLibraryPage extends StatefulWidget {
  @override
  _AllBooksLibraryPageState createState() => _AllBooksLibraryPageState();
}

class _AllBooksLibraryPageState extends State<AllBooksLibraryPage> {
  List<Book> _allBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllBooks();
  }

  Future<void> _loadAllBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final books = await BookService.getAllBooks();
      setState(() {
        _allBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load books: $e')),
      );
    }
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EpubReaderPage(book: book),
      ),
    ).then((_) {
      _loadAllBooks(); // Refresh when returning from reader
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'My Books Library',
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
                Colors.deepOrange.shade100.withValues(alpha: 0.9),
                Colors.orange.shade50.withValues(alpha: 0.9),
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
            colors: [Colors.deepOrange.shade50, Colors.white],
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                    ),
                    SizedBox(height: 16),
                    Text('Loading your library...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              )
            : _allBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.library_books,
                            size: 80,
                            color: Colors.orange.shade300,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Your Library is Empty',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Visit any saint\'s page and add books\nto start building your digital library',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(height: 100), // Space for AppBar
                      Container(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.library_books, color: Colors.deepOrange, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Digital Library',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange.shade800,
                                    ),
                                  ),
                                  Text(
                                    '${_allBooks.length} book${_allBooks.length != 1 ? 's' : ''} downloaded',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadAllBooks,
                          child: GridView.builder(
                            padding: EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _allBooks.length,
                            itemBuilder: (context, index) {
                              final book = _allBooks[index];
                              return Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _openBook(book),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.white, Colors.orange.shade50],
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            margin: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              color: Colors.grey.shade200,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withValues(alpha: 0.3),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: book.coverImagePath != null && File(book.coverImagePath!).existsSync()
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.file(
                                                      File(book.coverImagePath!),
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.book,
                                                    size: 48,
                                                    color: Colors.deepOrange.shade400,
                                                  ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  book.title,
                                                  style: GoogleFonts.playfairDisplay(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.deepOrange.shade800,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  book.author,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Spacer(),
                                                if (book.readingProgress > 0) ...[
                                                  LinearProgressIndicator(
                                                    value: book.readingProgress,
                                                    backgroundColor: Colors.grey.shade300,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    '${(book.readingProgress * 100).toInt()}% read',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.deepOrange.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
}
