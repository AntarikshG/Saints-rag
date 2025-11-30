import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_service.dart';
import 'epub_reader.dart';
import 'pdf_reader.dart'; // Add PDF reader import
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
    _downloadSampleBooksOnceIfNeeded();
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

  Future<void> _downloadSampleBooksOnceIfNeeded() async {
    // Only download sample books if they haven't been downloaded before
    try {
      print('Checking if sample spiritual books need to be downloaded...');
      await BookService.downloadSampleBooksOnce();
      print('Sample books check completed!');

      // Reload the books list to show the newly added books
      await _loadBooks();
    } catch (e) {
      print('Error checking sample books: $e');
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

  Future<void> _downloadDefaultBooks(String saint) async {
    // Default book URLs for different saints - including URLs that don't end with .epub
    final Map<String, List<Map<String, String>>> defaultBooks = {
      'sivananda': [
        {
          'url': 'https://www.dlshq.org/download2/hinduismbk.epub',
          'title': 'Bliss Divine',
        },
        {
          'url': 'https://www.dlshq.org/download2/japa.epub',
          'title': 'Japa Yoga',
        },
        {
          'url': 'https://www.dlshq.org/download2/meditation.epub',
          'title': 'Concentration and Meditation',
        },
        {
          'url': 'https://www.dlshq.org/download2/sadhana.epub',
          'title': 'Sadhana',
        },
        {
          'url': 'https://www.dlshq.org/download2/yoga.epub',
          'title': 'Science of Pranayama',
        },
        {
          'url': 'https://www.dlshq.org/download2/practice.epub',
          'title': 'Practice of Yoga',
        },
      ],
      'vivekananda': [
        {
          'url': 'https://www.gutenberg.org/ebooks/2346.epub.images',
          'title': 'Complete Works of Swami Vivekananda Vol 1',
        },
        {
          'url': 'https://www.gutenberg.org/ebooks/2347.epub.images',
          'title': 'Complete Works of Swami Vivekananda Vol 2',
        },
        {
          'url': 'https://www.gutenberg.org/ebooks/2348.epub.images',
          'title': 'Complete Works of Swami Vivekananda Vol 3',
        },
        {
          'url': 'https://www.gutenberg.org/ebooks/2349.epub3.images',
          'title': 'Complete Works of Swami Vivekananda Vol 4',
        },
        {
          'url': 'https://www.gutenberg.org/files/2346/2346-h.zip',
          'title': 'Raja Yoga (Alternative)',
        },
      ],
      'yogananda': [
        {
          'url': 'https://www.gutenberg.org/ebooks/7452.epub3.images',
          'title': 'Autobiography of a Yogi',
        },
        {
          'url': 'https://archive.org/download/AutobiographyOfAYogi_534/Autobiography%20of%20a%20Yogi.epub',
          'title': 'Autobiography of a Yogi (Alternative)',
        },
        {
          'url': 'https://www.ananda.org/free-inspiration/books/whispers-from-eternity/download/',
          'title': 'Whispers from Eternity',
        },
      ],
      'ramana': [
        {
          'url': 'https://archive.org/download/WhoAmI-RamanaMaharshi/Who%20Am%20I%20-%20Ramana%20Maharshi.epub',
          'title': 'Who Am I?',
        },
        {
          'url': 'https://www.sriramanamaharshi.org/downloadbooks/who_am_i',
          'title': 'Who Am I? (Official)',
        },
        {
          'url': 'https://archive.org/download/BeAsYouAreRamanaMaharshi/Be%20As%20You%20Are%20-%20Ramana%20Maharshi.epub',
          'title': 'Be As You Are',
        },
        {
          'url': 'https://www.sriramanamaharshi.org/downloadbooks/talks_with_ramana',
          'title': 'Talks with Ramana Maharshi',
        },
      ],
      'buddha': [
        {
          'url': 'https://www.gutenberg.org/ebooks/2017.epub3.images',
          'title': 'The Dhammapada',
        },
        {
          'url': 'https://archive.org/download/dhammapada_buddhist_teachings/dhammapada.epub',
          'title': 'Dhammapada (Archive)',
        },
        {
          'url': 'https://www.buddhanet.net/pdf_file/buddha-teach.epub',
          'title': 'What the Buddha Taught',
        },
      ],
      'krishna': [
        {
          'url': 'https://www.gutenberg.org/ebooks/2388.epub.images',
          'title': 'The Bhagavad Gita',
        },
        {
          'url': 'https://archive.org/download/BhagavadGitaAsItIs/Bhagavad%20Gita%20As%20It%20Is.epub',
          'title': 'Bhagavad Gita As It Is',
        },
        {
          'url': 'https://www.sacred-texts.com/hin/gita/download/gita.epub',
          'title': 'The Bhagavad Gita (Sacred Texts)',
        },
      ],
      'eckhart': [
        {
          'url': 'https://www.gutenberg.org/ebooks/4041.epub3.images',
          'title': 'Meister Eckhart\'s Sermons',
        },
        {
          'url': 'https://archive.org/download/eckhartsermons/eckhart_sermons.epub',
          'title': 'The Complete Mystical Works',
        },
      ],
      'rumi': [
        {
          'url': 'https://www.gutenberg.org/ebooks/2500.epub.images',
          'title': 'The Masnavi',
        },
        {
          'url': 'https://archive.org/download/rumipoetry/rumi_complete_poems.epub',
          'title': 'The Complete Poems of Rumi',
        },
        {
          'url': 'https://www.sufibooks.org/downloads/rumi_spiritual_verses',
          'title': 'Spiritual Verses',
        },
      ],
      'teresa': [
        {
          'url': 'https://www.gutenberg.org/ebooks/8120.epub3.images',
          'title': 'The Interior Castle',
        },
        {
          'url': 'https://archive.org/download/teresaavila/interior_castle.epub',
          'title': 'The Interior Castle (Archive)',
        },
      ],
    };

    final booksToDownload = defaultBooks[saint] ?? [];

    for (final bookInfo in booksToDownload) {
      try {
        // Check if this book already exists by searching for the title
        final existingBooks = await BookService.searchBooks(bookInfo['title']!);
        bool hasRealBook = existingBooks.any((book) => !book.filePath.startsWith('sample_'));

        if (!hasRealBook) {
          print('Downloading default book: ${bookInfo['title']}');
          await BookService.downloadBookFromUrl(bookInfo['url']!);
        }
      } catch (e) {
        print('Could not download ${bookInfo['title']}: $e');
        // Continue with other books even if one fails
      }
    }

    _loadBooks(); // Refresh the list after downloading books
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

    // Enhanced URL validation - support various EPUB and PDF sources
    bool isValidUrl = false;

    // Check for direct EPUB files
    if (url.toLowerCase().endsWith('.epub')) {
      isValidUrl = true;
    }
    // Check for direct PDF files
    else if (url.toLowerCase().endsWith('.pdf')) {
      isValidUrl = true;
    }
    // Check for Gutenberg EPUB/PDF links
    else if (url.contains('gutenberg.org') && (url.contains('.epub') || url.contains('.pdf') || url.contains('ebooks'))) {
      isValidUrl = true;
    }
    // Check for Archive.org EPUB/PDF links
    else if (url.contains('archive.org') && (url.toLowerCase().contains('.epub') || url.toLowerCase().contains('.pdf'))) {
      isValidUrl = true;
    }
    // Check for other common book hosting patterns
    else if (url.contains('.epub') || url.contains('.pdf') ||
             (url.contains('download') && (url.contains('epub') || url.contains('pdf') || url.contains('book')))) {
      isValidUrl = true;
    }

    if (!isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL must point to an EPUB or PDF file, or be from a supported book source'),
          duration: Duration(seconds: 4),
        ),
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
      } else if (e.toString().contains('Failed to process')) {
        errorMessage = 'Invalid file format';
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
    // Check the file extension to determine the reader
    String fileExtension = book.filePath.split('.').last.toLowerCase();
    if (fileExtension == 'epub') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EpubReaderPage(book: book),
        ),
      );
    } else if (fileExtension == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfReaderPage(book: book), // Open PDF reader
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unsupported file type: ${book.filePath}')),
      );
    }
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
                  hintText: 'Enter EPUB or PDF URL (e.g., https://example.com/book.epub)',
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
                          'Sample URLs:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    SelectableText(
                      'EPUB: https://www.dlshq.org/download2/hinduismbk.epub',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(height: 2),
                    SelectableText(
                      'PDF: https://www.gutenberg.org/files/2346/2346-pdf.pdf',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Copy and paste any sample URL above.',
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
                'Both EPUB and PDF files are supported. The book will be downloaded and added to your library.',
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
              child: Text('Use EPUB Sample'),
            ),
            TextButton(
              onPressed: () {
                _urlController.text = 'https://www.gutenberg.org/files/2346/2346-pdf.pdf';
              },
              child: Text('Use PDF Sample'),
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
    // Check the file extension to determine the reader
    String fileExtension = book.filePath.split('.').last.toLowerCase();
    if (fileExtension == 'epub') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EpubReaderPage(book: book),
        ),
      ).then((_) {
        _loadAllBooks(); // Refresh when returning from reader
      });
    } else if (fileExtension == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfReaderPage(book: book), // Open PDF reader
        ),
      ).then((_) {
        _loadAllBooks(); // Refresh when returning from reader
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unsupported file type: ${book.filePath}')),
      );
    }
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
