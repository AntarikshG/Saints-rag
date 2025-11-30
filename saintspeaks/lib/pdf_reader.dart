import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'book_service.dart';

class PdfReaderPage extends StatefulWidget {
  final Book book;

  const PdfReaderPage({Key? key, required this.book}) : super(key: key);

  @override
  _PdfReaderPageState createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> with WidgetsBindingObserver {
  PDFViewController? _pdfViewController;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  final Completer<PDFViewController> _controller = Completer<PDFViewController>();

  @override
  void initState() {
    super.initState();
    _loadLastReadPosition();
  }

  Future<void> _loadLastReadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentPage = prefs.getInt('pdf_last_page_${widget.book.id}') ?? 0;
      });
    } catch (e) {
      print('Error loading last read position: $e');
    }
  }

  Future<void> _saveReadingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pdf_last_page_${widget.book.id}', _currentPage);
      if (_totalPages > 0) {
        await BookService.updateReadingProgress(
          widget.book.id!,
          0,
          _currentPage / _totalPages,
        );
      }
    } catch (e) {
      print('Error saving reading progress: $e');
    }
  }

  @override
  void dispose() {
    _saveReadingProgress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: () {
              _pdfViewController?.setPage(0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_currentPage > 0) {
                _pdfViewController?.setPage(_currentPage - 1);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              if (_currentPage < _totalPages - 1) {
                _pdfViewController?.setPage(_currentPage + 1);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: () {
              _pdfViewController?.setPage(_totalPages - 1);
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.book.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: _currentPage,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (_pages) {
              setState(() {
                _totalPages = _pages!;
                _isLoading = false;
              });
            },
            onError: (error) {
              setState(() {
                _error = error.toString();
                _isLoading = false;
              });
              print(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                _error = '$page: ${error.toString()}';
                _isLoading = false;
              });
              print('$page: ${error.toString()}');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _controller.complete(pdfViewController);
              _pdfViewController = pdfViewController;
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page!;
              });
              _saveReadingProgress();
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading PDF: $_error',
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Page ${_currentPage + 1} of $_totalPages'),
            ],
          ),
        ),
      ),
    );
  }
}

