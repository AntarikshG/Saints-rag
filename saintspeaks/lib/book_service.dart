import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:epubx/epubx.dart';
import 'package:image/image.dart' as img;

class Book {
  final int? id;
  final String title;
  final String author;
  final String filePath;
  final String? coverPath;
  final String? coverImagePath; // Alternative name for cover
  final DateTime dateAdded;
  final DateTime? lastRead;
  final int currentChapter;
  final double progress;
  final double readingProgress; // Alternative name for progress

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.coverPath,
    this.coverImagePath,
    required this.dateAdded,
    this.lastRead,
    this.currentChapter = 0,
    this.progress = 0.0,
    this.readingProgress = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'coverPath': coverPath ?? coverImagePath,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
      'lastRead': lastRead?.millisecondsSinceEpoch,
      'currentChapter': currentChapter,
      'progress': progress != 0.0 ? progress : readingProgress,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    final progressValue = map['progress'] ?? 0.0;
    return Book(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      filePath: map['filePath'],
      coverPath: map['coverPath'],
      coverImagePath: map['coverPath'], // Use same path for both
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['dateAdded']),
      lastRead: map['lastRead'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastRead'])
          : null,
      currentChapter: map['currentChapter'] ?? 0,
      progress: progressValue,
      readingProgress: progressValue, // Use same value for both
    );
  }

  Book copyWith({
    int? id,
    String? title,
    String? author,
    String? filePath,
    String? coverPath,
    String? coverImagePath,
    DateTime? dateAdded,
    DateTime? lastRead,
    int? currentChapter,
    double? progress,
    double? readingProgress,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      coverPath: coverPath ?? this.coverPath,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      dateAdded: dateAdded ?? this.dateAdded,
      lastRead: lastRead ?? this.lastRead,
      currentChapter: currentChapter ?? this.currentChapter,
      progress: progress ?? this.progress,
      readingProgress: readingProgress ?? this.readingProgress,
    );
  }
}

class Bookmark {
  final int? id;
  final int chapterIndex;
  final String chapterTitle;
  final double position;
  final DateTime createdAt;
  final String? note;

  Bookmark({
    this.id,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.position,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapterIndex': chapterIndex,
      'chapterTitle': chapterTitle,
      'position': position,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'],
      chapterIndex: map['chapterIndex'],
      chapterTitle: map['chapterTitle'],
      position: map['position'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      note: map['note'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Bookmark.fromJson(String source) => Bookmark.fromMap(json.decode(source));
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

class BookService {
  static Database? _database;
  static const String _databaseName = 'books.db';
  static const int _databaseVersion = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        filePath TEXT NOT NULL UNIQUE,
        coverPath TEXT,
        dateAdded INTEGER NOT NULL,
        lastRead INTEGER,
        currentChapter INTEGER DEFAULT 0,
        progress REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        chapterIndex INTEGER NOT NULL,
        chapterTitle TEXT NOT NULL,
        position REAL NOT NULL,
        createdAt INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');
  }

  // Book operations
  static Future<int> addBook(Book book) async {
    final db = await database;
    return await db.insert('books', book.toMap());
  }

  static Future<List<Book>> getAllBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      orderBy: 'lastRead DESC, dateAdded DESC',
    );
    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  static Future<Book?> getBook(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Book.fromMap(maps.first);
    }
    return null;
  }

  static Future<void> updateBook(Book book) async {
    final db = await database;
    await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  static Future<void> deleteBook(int id) async {
    final db = await database;
    await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateReadingProgress(int bookId, int currentChapter, double progress) async {
    final db = await database;
    await db.update(
      'books',
      {
        'currentChapter': currentChapter,
        'progress': progress,
        'lastRead': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  // Bookmark operations
  static Future<int> addBookmark(int bookId, Bookmark bookmark) async {
    final db = await database;
    final bookmarkMap = bookmark.toMap();
    bookmarkMap['bookId'] = bookId;
    return await db.insert('bookmarks', bookmarkMap);
  }

  static Future<List<Bookmark>> getBookmarks(int bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Bookmark.fromMap(maps[i]));
  }

  static Future<void> deleteBookmark(int bookmarkId) async {
    final db = await database;
    await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [bookmarkId],
    );
  }

  // Utility methods
  static Future<bool> bookExists(String filePath) async {
    final db = await database;
    final result = await db.query(
      'books',
      where: 'filePath = ?',
      whereArgs: [filePath],
    );
    return result.isNotEmpty;
  }

  static Future<bool> bookExistsByTitle(String title, String author) async {
    final db = await database;
    final result = await db.query(
      'books',
      where: 'title = ? AND author = ?',
      whereArgs: [title, author],
    );
    return result.isNotEmpty;
  }

  static Future<List<Book>> searchBooks(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'title LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'lastRead DESC, dateAdded DESC',
    );
    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  static Future<List<Book>> getBooksForSaint(String saintName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'author LIKE ?',
      whereArgs: ['%$saintName%'],
      orderBy: 'lastRead DESC, dateAdded DESC',
    );
    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  static Future<Book> downloadBookFromUrl(
    String url, {
    Function(double)? onProgress,
  }) async {
    final uri = Uri.parse(url);

    // Check if book already exists by URL
    if (await bookExists(url)) {
      throw Exception('This book has already been downloaded');
    }

    // Create HTTP client with headers to handle different sources
    final client = http.Client();

    try {
      // Add headers to handle various download sources
      final request = http.Request('GET', uri);
      request.headers.addAll({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'application/epub+zip,application/pdf,application/octet-stream,*/*',
        'Accept-Language': 'en-US,en;q=0.9',
      });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        throw Exception('Failed to download book: HTTP ${streamedResponse.statusCode}');
      }

      // Check content type to determine file type
      final contentType = streamedResponse.headers['content-type'] ?? '';
      final contentDisposition = streamedResponse.headers['content-disposition'] ?? '';

      // Validate that we're getting a supported file format
      bool isValidFile = false;
      String expectedExtension = '.epub'; // Default

      // Check for EPUB
      if (contentType.contains('epub') ||
          contentType.contains('application/epub+zip') ||
          contentDisposition.contains('.epub') ||
          url.toLowerCase().contains('.epub')) {
        isValidFile = true;
        expectedExtension = '.epub';
      }
      // Check for PDF
      else if (contentType.contains('pdf') ||
               contentType.contains('application/pdf') ||
               contentDisposition.contains('.pdf') ||
               url.toLowerCase().contains('.pdf')) {
        isValidFile = true;
        expectedExtension = '.pdf';
      }
      // Check for generic binary content from trusted sources
      else if (contentType.contains('application/octet-stream') &&
               (url.contains('gutenberg.org') || url.contains('archive.org'))) {
        isValidFile = true;
        // Try to determine from URL
        if (url.toLowerCase().contains('pdf')) {
          expectedExtension = '.pdf';
        } else {
          expectedExtension = '.epub'; // Default to EPUB for trusted sources
        }
      }

      if (!isValidFile) {
        throw Exception('The downloaded file does not appear to be a supported format (EPUB or PDF)');
      }

      // Download the file with progress tracking
      final List<int> bytes = [];
      final contentLength = streamedResponse.contentLength ?? 0;
      int downloadedBytes = 0;

      await for (final chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;

        if (contentLength > 0 && onProgress != null) {
          final progress = downloadedBytes / contentLength;
          onProgress(progress.clamp(0.0, 1.0));
        }
      }

      final response = http.Response.bytes(bytes, streamedResponse.statusCode);

      // Get application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${documentsDir.path}/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      // Generate filename based on URL or content disposition
      String fileName = 'book$expectedExtension';

      if (contentDisposition.isNotEmpty) {
        // Extract filename from Content-Disposition header - simple approach
        if (contentDisposition.contains('filename=')) {
          final startIndex = contentDisposition.indexOf('filename=') + 9;
          var endIndex = contentDisposition.indexOf(';', startIndex);
          if (endIndex == -1) endIndex = contentDisposition.length;
          var extractedName = contentDisposition.substring(startIndex, endIndex).trim();
          // Remove quotes if present
          if (extractedName.startsWith('"') && extractedName.endsWith('"')) {
            extractedName = extractedName.substring(1, extractedName.length - 1);
          }
          if (extractedName.startsWith("'") && extractedName.endsWith("'")) {
            extractedName = extractedName.substring(1, extractedName.length - 1);
          }
          if (extractedName.isNotEmpty) {
            fileName = extractedName;
          }
        }
      } else if (uri.pathSegments.isNotEmpty) {
        // Extract from URL path
        final lastSegment = uri.pathSegments.last;
        if (lastSegment.isNotEmpty && !lastSegment.contains('?')) {
          fileName = lastSegment;
        }
      }

      // Ensure correct extension
      if (!fileName.toLowerCase().endsWith(expectedExtension)) {
        fileName = '$fileName$expectedExtension';
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${booksDir.path}/${timestamp}_$fileName';

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Parse file to extract metadata based on type
      try {
        String title = 'Unknown Title';
        String author = 'Unknown Author';
        String? coverPath;

        if (expectedExtension == '.epub') {
          // Handle EPUB files
          final epubBook = await EpubReader.readBook(response.bodyBytes);
          title = epubBook.Title ?? 'Unknown Title';
          author = epubBook.Author ?? 'Unknown Author';

          // Enhanced EPUB3 cover extraction
          try {
            final cover = epubBook.CoverImage;
            if (cover != null) {
              final jpegBytes = img.encodeJpg(cover);
              final coverFile = File('${booksDir.path}/${timestamp}_cover.jpg');
              await coverFile.writeAsBytes(jpegBytes);
              coverPath = coverFile.path;
            } else {
              // Try alternative method for EPUB3 covers
              final manifestItems = epubBook.Schema?.Package?.Manifest?.Items;
              if (manifestItems != null && manifestItems is Map) {
                final items = manifestItems as Map<String, dynamic>;
                for (final item in items.values) {
                  if (item.Properties?.contains('cover-image') == true ||
                      item.Id?.toLowerCase().contains('cover') == true ||
                      item.Href?.toLowerCase().contains('cover') == true) {
                    try {
                      final imageContent = epubBook.Content?.Images?[item.Href];
                      if (imageContent != null) {
                        final coverFile = File('${booksDir.path}/${timestamp}_cover.jpg');

                        // Handle different image formats
                        if (item.Href?.toLowerCase().endsWith('.jpg') == true ||
                            item.Href?.toLowerCase().endsWith('.jpeg') == true) {
                          await coverFile.writeAsBytes(imageContent.Content!);
                        } else if (item.Href?.toLowerCase().endsWith('.png') == true) {
                          final image = img.decodePng(imageContent.Content!);
                          if (image != null) {
                            final jpegBytes = img.encodeJpg(image);
                            await coverFile.writeAsBytes(jpegBytes);
                          } else {
                            await coverFile.writeAsBytes(imageContent.Content!);
                          }
                        } else {
                          final image = img.decodeImage(imageContent.Content!);
                          if (image != null) {
                            final jpegBytes = img.encodeJpg(image);
                            await coverFile.writeAsBytes(jpegBytes);
                          }
                        }
                        coverPath = coverFile.path;
                        break;
                      }
                    } catch (e) {
                      print('Could not process cover image ${item.Href}: $e');
                    }
                  }
                }
              }
            }
          } catch (e) {
            print('Could not extract cover: $e');
          }
        } else if (expectedExtension == '.pdf') {
          // Handle PDF files - extract title from filename or URL
          if (fileName.isNotEmpty) {
            title = fileName
                .replaceAll('.pdf', '')
                .replaceAll('_', ' ')
                .replaceAll('-', ' ')
                .split(' ')
                .map((word) => word.isNotEmpty
                    ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                    : word)
                .join(' ');
          }

          // Try to extract author from URL patterns
          if (url.contains('gutenberg.org')) {
            author = 'Project Gutenberg';
          } else if (url.contains('archive.org')) {
            author = 'Internet Archive';
          } else {
            author = 'Unknown Author';
          }
        }

        // Check if book exists by title and author
        if (await bookExistsByTitle(title, author)) {
          // Delete the downloaded file since it's a duplicate
          await file.delete();
          throw Exception('A book with the same title and author already exists in your library');
        }

        // Create book record
        final book = Book(
          title: title,
          author: author,
          filePath: filePath,
          coverPath: coverPath,
          dateAdded: DateTime.now(),
        );

        // Add to database
        final bookId = await addBook(book);
        return book.copyWith(id: bookId);

      } catch (e) {
        // Clean up file if there was an error
        await file.delete();
        throw Exception('Failed to process ${expectedExtension.toUpperCase()} file: $e');
      }
    } finally {
      client.close();
    }
  }

  static Future<Book> addBookFromFile(File file) async {
    // Check if file exists
    if (!await file.exists()) {
      throw Exception('File does not exist');
    }

    final filePath = file.path.toLowerCase();
    final isEpub = filePath.endsWith('.epub');
    final isPdf = filePath.endsWith('.pdf');

    // Check if it's a supported file type
    if (!isEpub && !isPdf) {
      throw Exception('File must be an EPUB (.epub) or PDF (.pdf) file');
    }

    // Check if book already exists by file path
    if (await bookExists(file.path)) {
      throw Exception('This book has already been added to your library');
    }

    try {
      String title = 'Unknown Title';
      String author = 'Unknown Author';

      if (isEpub) {
        // Read and parse EPUB
        final bytes = await file.readAsBytes();
        final epubBook = await EpubReader.readBook(bytes);
        title = epubBook.Title ?? 'Unknown Title';
        author = epubBook.Author ?? 'Unknown Author';
      } else if (isPdf) {
        // For PDF files, extract title from filename
        final fileName = file.uri.pathSegments.last;
        title = fileName.replaceAll('.pdf', '').replaceAll('_', ' ').replaceAll('-', ' ');
        // Capitalize each word
        title = title.split(' ').map((word) =>
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word
        ).join(' ');
        author = 'Unknown Author'; // PDF metadata extraction would require additional packages
      }

      // Check if book exists by title and author
      if (await bookExistsByTitle(title, author)) {
        throw Exception('A book with the same title and author already exists in your library');
      }

      // Get application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${documentsDir.path}/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      // Copy file to books directory with unique name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = file.uri.pathSegments.last;
      final newFilePath = '${booksDir.path}/${timestamp}_$fileName';
      final newFile = await file.copy(newFilePath);

      // Extract cover image if available (only for EPUB)
      String? coverPath;
      if (isEpub) {
        try {
          final bytes = await file.readAsBytes();
          final epubBook = await EpubReader.readBook(bytes);
          final cover = epubBook.CoverImage;
          if (cover != null) {
            final jpegBytes = img.encodeJpg(cover);
            final coverFile = File('${booksDir.path}/${timestamp}_cover.jpg');
            await coverFile.writeAsBytes(jpegBytes);
            coverPath = coverFile.path;
          }
        } catch (e) {
          print('Could not extract cover: $e');
        }
      }

      // Create book record
      final book = Book(
        title: title,
        author: author,
        filePath: newFile.path,
        coverPath: coverPath,
        dateAdded: DateTime.now(),
      );

      // Add to database
      final bookId = await addBook(book);
      return book.copyWith(id: bookId);

    } catch (e) {
      throw Exception('Failed to process ${isEpub ? 'EPUB' : 'PDF'} file: $e');
    }
  }

  // Add sample books method for compatibility
  static Future<void> addSampleBooksForSivananda() async {
    await addSampleBooks();
  }

  // Comprehensive method to add all sample books
  static Future<void> addSampleBooks() async {
    final sampleBooks = [
      // Swami Sivananda books
      {
        'title': 'Bhagavad Gita',
        'author': 'Swami Sivananda',
        'url': 'https://www.dlshq.org/download2/bgita.epub',
      },
      {
        'title': 'Brahmacharya',
        'author': 'Swami Sivananda',
        'url': 'https://www.dlshq.org/download2/brahmacharya.pdf',
      },
      {
        'title': 'Thought Power',
        'author': 'Swami Sivananda',
        'url': 'https://www.dlshq.org/download2/thought_power.epub',
      },
      {
        'title': 'Vedanta for Beginners',
        'author': 'Swami Sivananda',
        'url': 'https://www.dlshq.org/download2/vedbegin.pdf',
      },
      // Swami Vivekananda books
      {
        'title': 'Complete Works of Swami Vivekananda',
        'author': 'Swami Vivekananda',
        'url': 'https://www.vedanta-pitt.org/wp-content/uploads/2020/05/Complete_Works_of_Swami_Vivekananda_all_volumes.pdf',
      },
      {
        'title': 'The Gospel of Sri Ramakrishna',
        'author': 'Swami Vivekananda',
        'url': 'https://www.gutenberg.org/ebooks/72368.epub3.images',
      },
      // Paramahansa Yogananda
      {
        'title': 'Autobiography of a Yogi',
        'author': 'Paramahansa Yogananda',
        'url': 'https://www.gutenberg.org/ebooks/7452.epub3.images',
      },
      // Traditional Hindu texts
      {
        'title': 'Hindu Sanskrit Tales',
        'author': 'Traditional',
        'url': 'https://www.gutenberg.org/ebooks/11310.epub3.images',
      },
    ];

    print('Adding sample spiritual books...');

    for (final bookData in sampleBooks) {
      try {
        // Check if book already exists by title and author
        if (await bookExistsByTitle(bookData['title']!, bookData['author']!)) {
          print('Book "${bookData['title']}" by ${bookData['author']} already exists, skipping...');
          continue;
        }

        print('Downloading "${bookData['title']}" by ${bookData['author']}...');

        // Download and add the book
        await downloadBookFromUrl(
          bookData['url']!,
          onProgress: (progress) {
            // You could add progress tracking here if needed
            if (progress == 1.0) {
              print('Downloaded "${bookData['title']}" successfully');
            }
          },
        );

      } catch (e) {
        print('Failed to add "${bookData['title']}" by ${bookData['author']}: $e');

        // If download fails, create a placeholder entry
        try {
          final placeholderBook = Book(
            title: bookData['title']!,
            author: bookData['author']!,
            filePath: 'placeholder_${bookData['title']!.toLowerCase().replaceAll(' ', '_')}.epub',
            dateAdded: DateTime.now(),
          );
          await addBook(placeholderBook);
          print('Added placeholder for "${bookData['title']}"');
        } catch (placeholderError) {
          print('Failed to add placeholder for "${bookData['title']}": $placeholderError');
        }
      }
    }

    print('Sample books setup complete!');
  }

  // Method to download all sample books (can be called separately)
  static Future<void> downloadAllSampleBooks() async {
    await addSampleBooks();
  }

  // Method to get sample book URLs for manual download
  static List<Map<String, String>> getSampleBookUrls() {
    return [
      {
        'title': 'Bhagavad Gita',
        'author': 'Swami Sivananda',
        'url': 'https://www.dlshq.org/download2/bgita.epub',
      },
      {
        'title': 'Brahmacharya',
        'author': 'Swami Sivananda',
        'url': 'https://www.dlshq.org/download2/brahmacharya.pdf',
      },
      {
        'title': 'Thought Power',
        'author': 'Swami Sivananda',
        'url': 'https://www.dlshq.org/download2/thought_power.epub',
      },
      {
        'title': 'Vedanta for Beginners',
        'author': 'Swami Sivananda',
        'url': 'https://www.dlshq.org/download2/vedbegin.pdf',
      },
      {
        'title': 'Complete Works of Swami Vivekananda',
        'author': 'Swami Vivekananda',
        'url': 'https://www.vedanta-pitt.org/wp-content/uploads/2020/05/Complete_Works_of_Swami_Vivekananda_all_volumes.pdf',
      },
      {
        'title': 'The Gospel of Sri Ramakrishna',
        'author': 'Swami Vivekananda',
        'url': 'https://www.gutenberg.org/ebooks/72368.epub3.images',
      },
      {
        'title': 'Autobiography of a Yogi',
        'author': 'Paramahansa Yogananda',
        'url': 'https://www.gutenberg.org/ebooks/7452.epub3.images',
      },
      {
        'title': 'Hindu Sanskrit Tales',
        'author': 'Traditional',
        'url': 'https://www.gutenberg.org/ebooks/11310.epub3.images',
      },
    ];
  }
}
