// articlesquotes.dart
// Contains saints, quotes, and articles data for the app.

class Article {
  final String? id; // Optional unique identifier for the article
  final String heading;
  final String body;
  Article({this.id, required this.heading, required this.body});
}

class Saint {
  final String id;
  final String name;
  final String image;
  final List<String> quotes;
  final List<Article> articles;
  Saint(this.id, this.name, this.image, this.quotes, this.articles);
}

