import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'articlesquotes_en.dart';
import 'articlesquotes_hi.dart';
import 'articlesquotes_bn.dart';
import 'articlesquotes_de.dart';
import 'articlesquotes_kn.dart';
import 'notification_service.dart';

class BookmarkedQuotesPage extends StatefulWidget {
  @override
  _BookmarkedQuotesPageState createState() => _BookmarkedQuotesPageState();
}

class _BookmarkedQuotesPageState extends State<BookmarkedQuotesPage> {
  Set<String> _bookmarkedQuotes = {};
  List<Map<String, String>> _allQuotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarkedQuotes();
  }

  Future<void> _loadBookmarkedQuotes() async {
    final bookmarked = await ReadStatusService.getBookmarkedQuotes();
    final languageCode = Localizations.localeOf(context).languageCode;

    // Get all quotes from all saints
    final allQuotes = <Map<String, String>>[];

    // Get the appropriate saints list based on language
    List<dynamic> saintsList;
    switch (languageCode) {
      case 'hi':
        saintsList = saintsHi;
        break;
      case 'bn':
        saintsList = saintsBn;
        break;
      case 'de':
        saintsList = saintsDe;
        break;
      case 'kn':
        saintsList = saintsKn;
        break;
      default:
        saintsList = saintsEn;
    }

    // Collect all bookmarked quotes from the appropriate language
    for (final saint in saintsList) {
      for (final quote in saint.quotes) {
        final quoteId = '${saint.name}|||$quote';
        if (bookmarked.contains(quoteId)) {
          allQuotes.add({
            'quote': quote,
            'saint': saint.name,
            'image': saint.image,
            'id': quoteId,
          });
        }
      }
    }

    setState(() {
      _bookmarkedQuotes = bookmarked;
      _allQuotes = allQuotes;
      _loading = false;
    });
  }

  Future<void> _removeBookmark(String quoteId) async {
    await ReadStatusService.removeBookmark(quoteId);
    setState(() {
      _bookmarkedQuotes.remove(quoteId);
      _allQuotes.removeWhere((quote) => quote['id'] == quoteId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quote removed from bookmarks')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Bookmarked Quotes',
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
                Colors.orange.shade100.withOpacity(0.9),
                Colors.deepOrange.shade50.withOpacity(0.9),
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
            colors: [
              Colors.orange.shade50,
              Colors.white,
            ],
          ),
        ),
        child: _loading
          ? Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                  strokeWidth: 3,
                ),
              ),
            )
          : _allQuotes.isEmpty
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
                          Icons.bookmark_border,
                          size: 60,
                          color: Colors.orange.shade300,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No bookmarked quotes yet',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Start bookmarking your favorite quotes!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    SizedBox(height: 100), // Space for AppBar
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.all(16),
                        itemCount: _allQuotes.length,
                        separatorBuilder: (context, index) => SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final quote = _allQuotes[index];
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(20),
                              shadowColor: Colors.orange.withOpacity(0.3),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white, Colors.orange.shade50],
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 25,
                                              backgroundColor: Colors.white,
                                              child: CircleAvatar(
                                                radius: 22,
                                                backgroundImage: quote['image']!.startsWith('assets/')
                                                    ? AssetImage(quote['image']!) as ImageProvider
                                                    : NetworkImage(quote['image']!),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              quote['saint']!,
                                              style: GoogleFonts.playfairDisplay(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.orange.shade800,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.bookmark,
                                                color: Colors.orange.shade700,
                                                size: 22,
                                              ),
                                              onPressed: () => _removeBookmark(quote['id']!),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.orange.shade100),
                                        ),
                                        child: Text(
                                          '"${quote['quote']!}"',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                            height: 1.5,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
}
