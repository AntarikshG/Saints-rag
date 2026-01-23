// articlesquotes_kn.dart
// Kannada placeholders of saints, quotes, and articles data for the app.

// Export base classes
export 'articlesquotes.dart' show Article, Saint;

// Import all individual Kannada saint files
import 'saints_kn/vivekananda_kn.dart';
import 'saints_kn/sivananda_kn.dart';
import 'saints_kn/yogananda_kn.dart';
import 'saints_kn/ramana_kn.dart';
import 'saints_kn/shankaracharya_kn.dart';
import 'saints_kn/anandmoyima_kn.dart';
import 'saints_kn/nisargadatta_kn.dart';
import 'saints_kn/neem_karoli_baba_kn.dart';
import 'saints_kn/tapovan_maharaj_kn.dart';
import 'saints_kn/ramakrishna_kn.dart';

// Create the Kannada saints list from individual saint files
final saintsKn = [
  vivekanandaSaintKn,
  sivanandaSaintKn,
  yoganandaSaintKn,
  ramanaSaintKn,
  shankaracharyaSaintKn,
  anandmoyimaSaintKn,
  nisargadattaSaintKn,
  neem_karoli_babaSaintKn,
  ramakrishnaSaintKn,
  tapovanMaharajSaintKn,
];
