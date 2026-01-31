// articlesquotes_sa.dart
// Sanskrit translations of saints, quotes, and articles data for the app.

// Import the base classes from articlesquotes.dart (shared across all languages)
export 'articlesquotes.dart' show Article, Saint;

// Import all individual Sanskrit saint files
// Note: Individual saint files need to be created by the user
// Uncomment these imports as you create the corresponding files in saints_sa/ folder

 import 'saints_sa/vivekananda_sa.dart';
 import 'saints_sa/sivananda_sa.dart';
 import 'saints_sa/yogananda_sa.dart';
 import 'saints_sa/ramana_sa.dart';
 import 'saints_sa/shankaracharya_sa.dart';
 import 'saints_sa/anandmoyima_sa.dart';
 import 'saints_sa/nisargadatta_sa.dart';
 import 'saints_sa/neem_karoli_baba_sa.dart';
 import 'saints_sa/tapovan_maharaj_sa.dart';
 import 'saints_sa/ramakrishna_sa.dart';
 import 'saints_sa/sitaramdas_omkarnath_sa.dart';


// Create the Sanskrit saints list from individual saint files
// Uncomment and add saints as you create their files
final saintsSa = [
   vivekanandaSaintSa,
   sivanandaSaintSa,
   yoganandaSaintSa,
   ramanaSaintSa,
   shankaracharyaSaintSa,
   anandmoyimaSaintSa,
   nisargadattaSaintSa,
  neemKaroliBabaSaintSa,
  tapovanMaharajSaintSa,
  ramakrishnaSaintSa,
   sitaramdasSaintSa,
];
