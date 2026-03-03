// articlesquotes_mr.dart
// Marathi translations of saints, quotes, and articles data for the app.
// अॅपसाठी संत, उद्धरणे आणि लेख डेटाचे मराठी भाषांतर.

// Import the base classes from articlesquotes.dart (shared across all languages)
import 'articlesquotes.dart' show Article, Saint;
export 'articlesquotes.dart' show Article, Saint;

// Import all individual Marathi saint files
import 'saints_mr/vivekananda_mr.dart';
import 'saints_mr/sivananda_mr.dart';
import 'saints_mr/yogananda_mr.dart';
import 'saints_mr/ramana_mr.dart';
import 'saints_mr/ramakrishna_mr.dart';
import 'saints_mr/anandmoyima_mr.dart';
import 'saints_mr/nisargadatta_mr.dart';
import 'saints_mr/neem_karoli_baba_mr.dart';
import 'saints_mr/shankaracharya_mr.dart';
import 'saints_mr/sitaramdas_omkarnath_mr.dart';
import 'saints_mr/tapovan_maharaj_mr.dart';

// Create the Marathi saints list from individual saint files
final saintsMr = <Saint>[
  vivekanandaSaintMr,
  sivanandaSaintMr,
  yoganandaSaintMr,
  ramanaSaintMr,
  ramakrishnaSaintMr,
  anandmoyimaSaintMr,
  nisargadattaSaintMr,
  neemKaroliBabaSaintMr,
  shankaracharyaSaintMr,
  sitaramdasSaintMr,
  tapovanMaharajSaintMr,
];


