// articlesquotes_hi.dart
// Hindi translations of saints, quotes, and articles data for the app.

// Import the base classes from articlesquotes.dart (shared across all languages)
export 'articlesquotes.dart' show Article, Saint;

// Import all individual Hindi saint files
import 'saints_hi/vivekananda_hi.dart';
import 'saints_hi/sivananda_hi.dart';
import 'saints_hi/yogananda_hi.dart';
import 'saints_hi/ramana_hi.dart';
import 'saints_hi/shankaracharya_hi.dart';
import 'saints_hi/anandmoyima_hi.dart';
import 'saints_hi/nisargadatta_hi.dart';
import 'saints_hi/neem_karoli_baba_hi.dart';
import 'saints_hi/tapovan_maharaj_hi.dart';
import 'saints_hi/ramakrishna_hi.dart';
import 'saints_hi/sitaramdas_omkarnath_hi.dart';


// Create the Hindi saints list from individual saint files
final saintsHi = [
  vivekanandaSaintHi,
  sivanandaSaintHi,
  yoganandaSaintHi,
  ramanaSaintHi,
  shankaracharyaSaintHi,
  anandmoyimaSaintHi,
  nisargadattaSaintHi,
  neem_karoli_babaSaintHi,
  tapovanMaharajSaintHi,
  ramakrishnaSaintHi,
  sitaramdasSaintHi,
];
