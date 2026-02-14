import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_service.dart';
import 'config_service.dart';
import 'epub_reader.dart';
import 'pdf_reader.dart';
import 'package:file_picker/file_picker.dart';

class BooksLibraryPage extends StatefulWidget {
  @override
  _BooksLibraryPageState createState() => _BooksLibraryPageState();
}

class _BooksLibraryPageState extends State<BooksLibraryPage> {
  List<Book> _books = [];
  List<BookMetadata> _availableBooks = [];
  bool _isLoading = true;
  bool _isLoadingAvailableBooks = true;
  TextEditingController _urlController = TextEditingController();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  Map<String, bool> _downloadingBooks = {}; // Track which books are downloading
  Map<String, double> _bookDownloadProgress = {}; // Track download progress per book

  // Add sample books download tracking
  StreamSubscription<bool>? _sampleDownloadInProgressSub;
  StreamSubscription<double>? _sampleDownloadProgressSub;
  StreamSubscription<String>? _currentDownloadingBookSub;
  bool _isSampleBooksDownloading = false;
  double _sampleDownloadProgress = 0.0;
  String _currentDownloadingBook = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadAvailableBooksFromConfig();
    _setupSampleDownloadListeners();
    // REMOVED: _downloadSampleBooksOnceIfNeeded(); // No longer auto-download
  }

  @override
  void dispose() {
    _urlController.dispose();
    _sampleDownloadInProgressSub?.cancel();
    _sampleDownloadProgressSub?.cancel();
    _currentDownloadingBookSub?.cancel();
    super.dispose();
  }

  void _setupSampleDownloadListeners() {
    // Listen for sample download start/stop
    _sampleDownloadInProgressSub = BookService.sampleDownloadInProgressStream.listen((inProgress) {
      if (mounted) {
        setState(() {
          _isSampleBooksDownloading = inProgress;
        });

        if (inProgress) {
          // Show SnackBar when downloads start
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading sample books to your library...'),
              duration: Duration(days: 1), // Keep it until dismissed
              backgroundColor: Colors.blue,
              action: SnackBarAction(
                label: 'Hide',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        } else {
          // Hide current SnackBar and show completion message
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sample books added to your library!'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
          // Reload books to show newly downloaded ones
          _loadBooks();
        }
      }
    });

    // Listen for sample download progress
    _sampleDownloadProgressSub = BookService.sampleDownloadProgressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _sampleDownloadProgress = progress;
        });
      }
    });

    // Listen for current downloading book name
    _currentDownloadingBookSub = BookService.currentDownloadingBookStream.listen((bookName) {
      if (mounted) {
        setState(() {
          _currentDownloadingBook = bookName;
        });
      }
    });
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final books = await BookService.getAllBooks();
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

  // NEW: Load available books from config
  Future<void> _loadAvailableBooksFromConfig() async {
    setState(() {
      _isLoadingAvailableBooks = true;
    });

    try {
      final booksMetadata = await BookService.getBooksMetadataFromConfig();
      setState(() {
        _availableBooks = booksMetadata;
        _isLoadingAvailableBooks = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAvailableBooks = false;
      });
      print('Error loading available books: $e');
    }
  }

  // NEW: Refresh books metadata
  Future<void> _refreshBooksMetadata() async {
    setState(() {
      _isLoadingAvailableBooks = true;
    });

    try {
      // Clear cache and reload
      await BookService.clearBooksMetadataCache();
      final booksMetadata = await BookService.getBooksMetadataFromConfig();

      setState(() {
        _availableBooks = booksMetadata;
        _isLoadingAvailableBooks = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Book list refreshed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoadingAvailableBooks = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // NEW: Download a book from available books metadata
  Future<void> _downloadBookFromMetadata(BookMetadata metadata) async {
    // Check if already downloading
    if (_downloadingBooks[metadata.id] == true) {
      return;
    }

    // Check if already downloaded
    final isDownloaded = await BookService.bookExistsByTitle(metadata.title, metadata.author);
    if (isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${metadata.title} is already in your library')),
      );
      return;
    }

    setState(() {
      _downloadingBooks[metadata.id] = true;
      _bookDownloadProgress[metadata.id] = 0.0;
    });

    try {
      await BookService.downloadBookFromUrl(
        metadata.url,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _bookDownloadProgress[metadata.id] = progress;
            });
          }
        },
      );

      // Reload books list
      await _loadBooks();

      if (mounted) {
        setState(() {
          _downloadingBooks[metadata.id] = false;
          _bookDownloadProgress.remove(metadata.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${metadata.title} downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingBooks[metadata.id] = false;
          _bookDownloadProgress.remove(metadata.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${metadata.title}: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _downloadSampleBooksOnceIfNeeded() async {
    // Download sample books if they haven't been downloaded before
    try {
      print('Checking if sample books need to be downloaded for library...');
      await BookService.downloadSampleBooksOnce();
      print('Sample books check for library completed!');

      // Reload the books list to show the newly added books
      await _loadBooks();
    } catch (e) {
      print('Error checking sample books in library: $e');
      // Show error to user if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sample books. You can add books manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _downloadBookFromUrl(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

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
      Navigator.pop(context); // Close the add book dialog
      _loadBooks();
    } catch (e) {
      String errorMessage = 'Error downloading book: $e';
      Color backgroundColor = Colors.red;

      if (e.toString().contains('already exists in your library') ||
          e.toString().contains('already been downloaded')) {
        errorMessage = 'Book already exists in your library';
        backgroundColor = Colors.orange;
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

  Future<void> _pickLocalFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final book = await BookService.addBookFromFile(file);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added "${book.title}"'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context); // Close the add book dialog
        _loadBooks();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding book: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (book.filePath.toLowerCase().endsWith('.epub')) {
            return EpubReaderPage(book: book);
          } else if (book.filePath.toLowerCase().endsWith('.pdf')) {
            return PdfReaderPage(book: book);
          } else {
            return Container(); // Fallback for unknown file types
          }
        },
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
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Book', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Choose how you want to add a book:', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 20),

                    // Add from URL section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('From URL', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              labelText: 'EPUB URL',
                              hintText: 'https://example.com/book.epub',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.link),
                            ),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isDownloading ? null : () {
                                _downloadBookFromUrl(_urlController.text.trim());
                              },
                              icon: _isDownloading
                                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(Icons.download),
                              label: Text(_isDownloading ? 'Downloading...' : 'Download'),
                            ),
                          ),
                          if (_isDownloading) ...[
                            SizedBox(height: 8),
                            LinearProgressIndicator(value: _downloadProgress),
                            SizedBox(height: 4),
                            Text(_downloadStatus, style: TextStyle(fontSize: 12)),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: 16),
                    Text('OR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 16),

                    // Add from device section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.folder, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('From Device', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _pickLocalFile,
                              icon: Icon(Icons.upload_file),
                              label: Text('Choose EPUB/PDF File'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _urlController.clear();
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Books Library',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepOrange.shade600,
                Colors.orange.shade500,
              ],
            ),
          ),
        ),
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.add, size: 26),
              onPressed: _showAddBookDialog,
              tooltip: 'Add Book',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sample books download progress banner
          if (_isSampleBooksDownloading)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
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
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Adding sample books to your library...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentDownloadingBook.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.book, color: Colors.white.withOpacity(0.9), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentDownloadingBook,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.95),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_sampleDownloadProgress > 0) ...[
                    SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _sampleDownloadProgress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Progress: ${(_sampleDownloadProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Main content area
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _books.isEmpty
                    ? _buildEmptyState()
                    : _buildBooksList(),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepOrange.shade400,
              Colors.orange.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddBookDialog,
          child: Icon(Icons.add, size: 32),
          tooltip: 'Add New Book',
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 20),
            // Empty library message with gradient background
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepOrange.shade50,
                    Colors.orange.shade50,
                    Colors.amber.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated book stack icon
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_stories,
                      size: 60,
                      color: Colors.deepOrange,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Your Library Awaits',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade800,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Start your spiritual journey by adding\nyour first book to the collection',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: _showAddBookDialog,
                    icon: Icon(Icons.add_circle_outline),
                    label: Text('Add Your First Book'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Available Books section - ALWAYS SHOW
            if (_availableBooks.isNotEmpty) ...[
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.orange.shade50.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.15),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with gradient background
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.deepOrange.shade400,
                            Colors.orange.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.cloud_download,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Books',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap to download and read',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh, color: Colors.white),
                            onPressed: _isLoadingAvailableBooks ? null : _refreshBooksMetadata,
                            tooltip: 'Refresh book list',
                          ),
                        ],
                      ),
                    ),
                    // Books list
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_isLoadingAvailableBooks)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                                ),
                              ),
                            )
                          else
                            ..._availableBooks.map((metadata) {
                              final isDownloaded = _books.any((book) =>
                                book.title == metadata.title && book.author == metadata.author);
                              return _buildAvailableBookCard(metadata, isDownloaded);
                            }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ] else if (_isLoadingAvailableBooks)
              Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No available books to download',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksList() {
    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // My Library section
            if (_books.isNotEmpty)
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.deepOrange.shade700,
                      Colors.orange.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.library_books,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY LIBRARY',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${_books.length} book${_books.length != 1 ? 's' : ''} downloaded',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Books list
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.orange.shade50.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openBook(book),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Enhanced book cover with shadow
                            Hero(
                              tag: 'book_${book.id}',
                              child: Container(
                                width: 60,
                                height: 85,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: Offset(2, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: book.coverPath != null && File(book.coverPath!).existsSync()
                                      ? Image.file(
                                          File(book.coverPath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.deepOrange.shade100,
                                              child: Icon(Icons.menu_book, color: Colors.deepOrange, size: 32),
                                            ),
                                        )
                                      : Container(
                                          color: Colors.deepOrange.shade100,
                                          child: Icon(Icons.menu_book, color: Colors.deepOrange, size: 32),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.title,
                                    style: GoogleFonts.playfairDisplay(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey.shade900,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (book.author.isNotEmpty) ...[
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            book.author,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (book.progress > 0) ...[
                                    SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: book.progress,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                                        minHeight: 6,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.bookmark, size: 12, color: Colors.deepOrange),
                                        SizedBox(width: 4),
                                        Text(
                                          '${(book.progress * 100).toInt()}% completed',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.deepOrange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.more_vert, color: Colors.grey.shade700),
                              ),
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deleteBook(book);
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text('Delete Book', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Available Books section
            if (_availableBooks.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.orange.shade50.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.15),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with gradient background
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.deepOrange.shade400,
                            Colors.orange.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.cloud_download,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Books',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap to download and read',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh, color: Colors.white),
                            onPressed: _isLoadingAvailableBooks ? null : _refreshBooksMetadata,
                            tooltip: 'Refresh book list',
                          ),
                        ],
                      ),
                    ),
                    // Books list
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_isLoadingAvailableBooks)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                                ),
                              ),
                            )
                          else
                            ..._availableBooks.map((metadata) {
                              final isDownloaded = _books.any((book) =>
                                book.title == metadata.title && book.author == metadata.author);
                              return _buildAvailableBookCard(metadata, isDownloaded);
                            }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  // Widget to display available book card with download button
  Widget _buildAvailableBookCard(BookMetadata metadata, bool isDownloaded) {
    final isDownloading = _downloadingBooks[metadata.id] == true;
    final downloadProgress = _bookDownloadProgress[metadata.id] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white,
            Colors.orange.shade50.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Book icon with gradient background
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepOrange.shade300,
                      Colors.orange.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.menu_book, size: 32, color: Colors.white),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            metadata.author,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (metadata.description.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Text(
                        metadata.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isDownloading) ...[
                      SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: downloadProgress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                          minHeight: 6,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Downloading... ${(downloadProgress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12),
              if (isDownloaded)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Added',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isDownloading)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _downloadBookFromMetadata(metadata),
                  icon: Icon(Icons.download, size: 18),
                  label: Text('Get', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
