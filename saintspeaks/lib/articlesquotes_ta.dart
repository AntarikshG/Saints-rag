// articlesquotes_ta.dart
// Tamil translations of saints, quotes, and articles data for the app.
// செயலிக்கான புனிதர்கள், மேற்கோள்கள் மற்றும் கட்டுரை தரவுகளின் தமிழ் மொழிபெயர்ப்புகள்.

// Import the base classes from articlesquotes.dart (shared across all languages)
import 'articlesquotes.dart' show Article, Saint;
export 'articlesquotes.dart' show Article, Saint;

// Import all individual Tamil saint files
import 'saints_ta/vivekananda_ta.dart';
import 'saints_ta/sivananda_ta.dart';
import 'saints_ta/yogananda_ta.dart';
import 'saints_ta/ramana_ta.dart';
import 'saints_ta/shankaracharya_ta.dart';
import 'saints_ta/anandmoyima_ta.dart';
import 'saints_ta/nisargadatta_ta.dart';
import 'saints_ta/neem_karoli_baba_ta.dart';
import 'saints_ta/tapovan_maharaj_ta.dart';
import 'saints_ta/ramakrishna_ta.dart';
import 'saints_ta/sitaramdas_omkarnath_ta.dart';


// Create the Tamil saints list from individual saint files
final saintsTa = <Saint>[
  vivekanandaSaintTa,
  sivanandaSaintTa,
  yoganandaSaintTa,
  ramanaSaintTa,
  shankaracharyaSaintTa,
  anandmoyimaSaintTa,
  nisargadattaSaintTa,
  neemKaroliBabaSaintTa,
  tapovanMaharajSaintTa,
  ramakrishnaSaintTa,
  sitaramdasSaintTa,
];
