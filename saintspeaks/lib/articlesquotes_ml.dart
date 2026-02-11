// articlesquotes_ml.dart
// Malayalam translations of saints, quotes, and articles data for the app.
// ആപ്പിനായുള്ള വിശുദ്ധന്മാർ, ഉദ്ധരണികൾ, ലേഖനങ്ങൾ എന്നിവയുടെ മലയാളം വിവർത്തനം.

// Import the base classes from articlesquotes.dart (shared across all languages)
import 'articlesquotes.dart' show Article, Saint;
export 'articlesquotes.dart' show Article, Saint;

// Import all individual Malayalam saint files
import 'saints_ml/anandmoyima_ml.dart';
import 'saints_ml/neem_karoli_baba_ml.dart';
import 'saints_ml/nisargadatta_ml.dart';
import 'saints_ml/ramakrishna_ml.dart';
import 'saints_ml/ramana_ml.dart';
import 'saints_ml/shankaracharya_ml.dart';
import 'saints_ml/sitaramdas_omkarnath_ml.dart';
import 'saints_ml/sivananda_ml.dart';
import 'saints_ml/tapovan_maharaj_ml.dart';
import 'saints_ml/vivekananda_ml.dart';
import 'saints_ml/yogananda_ml.dart';

// Create the Malayalam saints list from individual saint files
final saintsMl = <Saint>[
  anandmoyimaSaint,
  neemKaroliBabaSaint,
  nisargadattaSaint,
  ramakrishnaSaint,
  ramanaSaint,
  shankaracharyaSaint,
  sitaramdasSaint,
  sivanandaSaint,
  tapovanMaharajSaint,
  vivekanandaSaint,
  yoganandaSaint,
];
