import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
    final fileName = uri.pathSegments.last;

    // Check if book already exists by URL
    if (await bookExists(url)) {
      throw Exception('This book has already been downloaded');
    }

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to download book: HTTP ${response.statusCode}');
    }

    // Get application documents directory
    final documentsDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${documentsDir.path}/books');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${booksDir.path}/${timestamp}_$fileName';

    // Save file
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    // Parse EPUB to extract metadata
    try {
      final epubBook = await EpubReader.readBook(response.bodyBytes);
      final title = epubBook.Title ?? 'Unknown Title';
      final author = epubBook.Author ?? 'Unknown Author';

      // Check if book exists by title and author
      if (await bookExistsByTitle(title, author)) {
        // Delete the downloaded file since it's a duplicate
        await file.delete();
        throw Exception('A book with the same title and author already exists in your library');
      }

      // Extract cover image if available
      String? coverPath;
      try {
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
      throw Exception('Failed to process EPUB file: $e');
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
    // This method is called from BooksTab for backward compatibility
    // We'll create a sample book entry if needed
    try {
      final existingBooks = await searchBooks('Sivananda');
      if (existingBooks.isEmpty) {
        // Create a placeholder book entry for Sivananda
        final sampleBook = Book(
          title: 'Bliss Divine',
          author: 'Swami Sivananda',
          filePath: 'sample_sivananda_bliss_divine.epub', // Placeholder path
          dateAdded: DateTime.now(),
        );
        await addBook(sampleBook);
      }
    } catch (e) {
      print('Error adding sample books: $e');
    }
  }
}
