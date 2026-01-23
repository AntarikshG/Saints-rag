// articlesquotes_de.dart
// German translations of saints, quotes, and articles data for the app.
// Deutsche Übersetzungen von Heiligen, Zitaten und Artikeln für die App.

// Import the base classes from articlesquotes.dart (shared across all languages)
export 'articlesquotes.dart' show Article, Saint;

// Import all individual German saint files
import 'saints_de/vivekananda_de.dart';
import 'saints_de/sivananda_de.dart';
import 'saints_de/yogananda_de.dart';
import 'saints_de/ramana_de.dart';
import 'saints_de/shankaracharya_de.dart';
import 'saints_de/anandmoyima_de.dart';
import 'saints_de/nisargadatta_de.dart';
import 'saints_de/neem_karoli_baba_de.dart';
import 'saints_de/tapovan_maharaj_de.dart';
import 'saints_de/ramakrishna_de.dart';


// Create the German saints list from individual saint files
final saintsDe = [
  vivekanandaSaintDe,
  sivanandaSaintDe,
  yoganandaSaintDe,
  ramanaSaintDe,
  shankaracharyaSaintDe,
  anandmoyimaSaintDe,
  nisargadattaSaintDe,
  neem_karoli_babaSaintDe,
  ramakrishnaSaintDe,
  tapovanMaharajSaintDe,
];
