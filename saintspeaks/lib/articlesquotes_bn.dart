// articlesquotes_bn.dart
// Bengali translations of saints, quotes, and articles data for the app.
// বাংলা অনুবাদ - সাধু, উক্তি এবং প্রবন্ধ

// Import the base classes from articlesquotes.dart (shared across all languages)
export 'articlesquotes.dart' show Article, Saint;

// Import all individual Bengali saint files
import 'saints_bn/vivekananda_bn.dart';
import 'saints_bn/sivananda_bn.dart';
import 'saints_bn/yogananda_bn.dart';
import 'saints_bn/ramana_bn.dart';
import 'saints_bn/shankaracharya_bn.dart';
import 'saints_bn/anandmoyima_bn.dart';
import 'saints_bn/nisargadatta_bn.dart';
import 'saints_bn/neem_karoli_baba_bn.dart';
import 'saints_bn/tapovan_maharaj_bn.dart';
import 'saints_bn/ramakrishna_bn.dart';


// Create the Bengali saints list from individual saint files
final saintsBn = [
  vivekanandaSaintBn,
  sivanandaSaintBn,
  yoganandaSaintBn,
  ramanaSaintBn,
  shankaracharyaSaintBn,
  anandmoyimaSaintBn,
  nisargadattaSaintBn,
  neemKaroliBabaSaintBn,
  tapovanMaharajSaintBn,
  ramakrishnaSaintBn,
];

