// articlesquotes_te.dart
// Telugu translations of saints, quotes, and articles data for the app.
// యాప్ కోసం సంతులు, కోట్స్ మరియు వ్యాసాల డేటా యొక్క తెలుగు అనువాదాలు.

// Import the base classes from articlesquotes.dart (shared across all languages)
import 'articlesquotes.dart' show Article, Saint;
export 'articlesquotes.dart' show Article, Saint;

// Import all individual Telugu saint files
import 'saints_te/vivekananda_te.dart';
import 'saints_te/sivananda_te.dart';
import 'saints_te/yogananda_te.dart';
import 'saints_te/ramana_te.dart';
import 'saints_te/shankaracharya_te.dart';
import 'saints_te/anandmoyima_te.dart';
import 'saints_te/nisargadatta_te.dart';
import 'saints_te/neem_karoli_baba_te.dart';
import 'saints_te/tapovan_maharaj_te.dart';
import 'saints_te/ramakrishna_te.dart';
import 'saints_te/sitaramdas_omkarnath_te.dart';


// Create the Telugu saints list from individual saint files
final saintsTe = <Saint>[
  vivekanandaSaintTe,
  sivanandaSaintTe,
  yoganandaSaintTe,
  ramanaSaintTe,
  shankaracharyaSaintTe,
  anandmoyimaSaintTe,
  nisargadattaSaintTe,
  neemKaroliBabaSaintTe,
  tapovanMaharajSaintTe,
  ramakrishnaSaintTe,
  sitaramdasSaintTe,
];
