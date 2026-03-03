// articlesquotes_en.dart
// English version - Contains saints, quotes, and articles data for the app.
// This file imports individual saint files for better organization.

// Import the base classes from articlesquotes.dart
export 'articlesquotes.dart' show Article, Saint;

// Import individual saint files
import 'saints/vivekananda_en.dart';
import 'saints/sivananda_en.dart';
import 'saints/yogananda_en.dart';
import 'saints/ramana_en.dart';
import 'saints/shankaracharya_en.dart';
import 'saints/ramakrishna_en.dart';
import 'saints/anandmoyima_en.dart';
import 'saints/sitaramdas_omkarnath_en.dart';
import 'saints/nisargadatta_en.dart';
import 'saints/neem_karoli_baba_en.dart';
import 'saints/tapovan_maharaj_en.dart';
// Combined list of all saints
final saintsEn = [
  vivekanandaSaint,
  sivanandaSaint,
  yoganandaSaint,
  ramanaSaint,
  shankaracharyaSaint,
  ramakrishnaSaint,
  anandmoyimaSaint,
  nisargadattaSaint,
  neemKaroliBabaSaint,
  tapovanMaharajSaint,
  sitaramdasSaint
];
