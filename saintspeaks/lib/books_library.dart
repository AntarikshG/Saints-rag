import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_service.dart';
import 'epub_reader.dart';
import 'pdf_reader.dart';
import 'package:file_picker/file_picker.dart';

class BooksLibraryPage extends StatefulWidget {
  @override
  _BooksLibraryPageState createState() => _BooksLibraryPageState();
}

class _BooksLibraryPageState extends State<BooksLibraryPage> {
  List<Book> _books = [];
  bool _isLoading = true;
  TextEditingController _urlController = TextEditingController();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

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
    _setupSampleDownloadListeners();
    _downloadSampleBooksOnceIfNeeded();
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
        title: Text('My Books Library', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddBookDialog,
            tooltip: 'Add Book',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sample books download progress banner
          if (_isSampleBooksDownloading)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Adding sample books to your library...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentDownloadingBook.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      'Currently downloading: $_currentDownloadingBook',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                  if (_sampleDownloadProgress > 0) ...[
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _sampleDownloadProgress,
                      backgroundColor: Colors.blue.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Progress: ${(_sampleDownloadProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookDialog,
        child: Icon(Icons.add),
        tooltip: 'Add New Book',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No books in your library',
            style: GoogleFonts.playfairDisplay(fontSize: 24, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first book to get started',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddBookDialog,
            icon: Icon(Icons.add),
            label: Text('Add Book'),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: book.coverPath != null && File(book.coverPath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(book.coverPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.book, color: Colors.grey),
                      ),
                    )
                  : Icon(Icons.book, color: Colors.grey),
            ),
            title: Text(
              book.title,
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (book.author.isNotEmpty)
                  Text(book.author, style: TextStyle(color: Colors.grey.shade600)),
                SizedBox(height: 4),
                if (book.progress > 0)
                  LinearProgressIndicator(
                    value: book.progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                  ),
                if (book.progress > 0)
                  SizedBox(height: 4),
                if (book.progress > 0)
                  Text(
                    '${(book.progress * 100).toInt()}% completed',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
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
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ];
              },
            ),
            onTap: () => _openBook(book),
          ),
        );
      },
    );
  }
}
