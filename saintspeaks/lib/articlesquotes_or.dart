// articlesquotes_or.dart
// Odia translations of saints, quotes, and articles data for the app.
// ଓଡ଼ିଆ ଅନୁବାଦ - ସାଧୁ, ଉକ୍ତି ଏବଂ ପ୍ରବନ୍ଧ

// Import the base classes from articlesquotes.dart (shared across all languages)
export 'articlesquotes.dart' show Article, Saint;

// Import all individual Odia saint files
import 'saints_or/vivekananda_or.dart';
import 'saints_or/sivananda_or.dart';
import 'saints_or/yogananda_or.dart';
import 'saints_or/ramana_or.dart';
import 'saints_or/shankaracharya_or.dart';
import 'saints_or/anandmoyima_or.dart';
import 'saints_or/nisargadatta_or.dart';
import 'saints_or/neem_karoli_baba_or.dart';
import 'saints_or/tapovan_maharaj_or.dart';
import 'saints_or/ramakrishna_or.dart';
import 'saints_or/sitaramdas_omkarnath_or.dart';


// Create the Odia saints list from individual saint files
final saintsOr = [
  vivekanandaSaintOr,
  sivanandaSaintOr,
  yoganandaSaintOr,
  ramanaSaintOr,
  shankaracharyaSaintOr,
  anandmoyimaSaintOr,
  nisargadattaSaintOr,
  neemKaroliBabaSaintOr,
  tapovanMaharajSaintOr,
  ramakrishnaSaintOr,
  sitaramdasOmkarnathSaintOr,
];
