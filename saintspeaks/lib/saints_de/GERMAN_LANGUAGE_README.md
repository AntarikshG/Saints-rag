# German Language Support - Deutsche Sprachunterstützung

This document describes the German language implementation for the Saints app.

## Overview - Überblick

German language support has been added to the Saints app, following the same structure as the Hindi language implementation. The German files contain the saint names and structural elements translated to German, while quotes and articles remain in English as placeholders for future translation.

## File Structure - Dateistruktur

### Main File - Hauptdatei

- `lib/articlesquotes_de.dart` - Main German file that imports all individual saint files

### Individual Saint Files - Einzelne Heiligendateien

Located in `lib/saints_de/`:

1. `vivekananda_de.dart` - Swami Vivekananda
2. `sivananda_de.dart` - Swami Sivananda
3. `yogananda_de.dart` - Paramhansa Yogananda
4. `ramana_de.dart` - Maharishi Ramana
5. `shankaracharya_de.dart` - Shankaracharya
6. `anandmoyima_de.dart` - Anandamayi Ma
7. `nisargadatta_de.dart` - Nisargadatta Maharaj
8. `neem_karoli_baba_de.dart` - Neem Karoli Baba

## Class Structure - Klassenstruktur

### ArticleDe Class
```dart
class ArticleDe {
  final String id;
  final String heading;
  final String body;
  Article({required this.id, required this.heading, required this.body});
}
```

### SaintDe Class
```dart
class SaintDe {
  final String id;
  final String name;
  final String image;
  final List<String> quotes;
  final List<ArticleDe> articles;
  SaintDe(this.id, this.name, this.image, this.quotes, this.articles);
}
```

## Translation Status - Übersetzungsstatus

### ✅ Completed - Abgeschlossen
- File structure created
- Class definitions
- Import statements
- Saint names (kept in original form)
- File headers with German comments

### 📝 Pending Translation - Ausstehende Übersetzung

The following content remains in English and needs to be translated to German:

1. **Quotes (Zitate)** - All saint quotes in each file
2. **Articles (Artikel)** - All article headings and bodies
   - Article headings should be translated
   - Article bodies should be translated

## How to Add Translations - Übersetzungen hinzufügen

### For Quotes - Für Zitate

Replace English quotes with German translations in each saint file:

```dart
// Before - Vorher
[
  'Arise, awake, and stop not till the goal is reached.',
]

// After - Nachher
[
  'Erhebe dich, erwache und höre nicht auf, bis das Ziel erreicht ist.',
]
```

### For Articles - Für Artikel

Replace both heading and body with German translations:

```dart
// Before - Vorher
Article(
    id: 'vivekananda_life',
    heading: 'Swami Vivekananda: Short life sketch',
    body: 'The great secret of true success...'
),

// After - Nachher
Article(
    id: 'vivekananda_life',
    heading: 'Swami Vivekananda: Kurze Lebensskizze',
    body: 'Das große Geheimnis des wahren Erfolgs...'
),
```

## Integration Steps - Integrationsschritte

To integrate German language support into the app:

1. **Import the German file** in your localization system:
   ```dart
   import 'package:your_app/articlesquotes_de.dart';
   ```

2. **Update language selector** to include German:
   ```dart
   'en': saintsEn,
   'hi': saintsHi,
   'de': saintsDe,  // Add this
   ```

3. **Update l10n.yaml** configuration to include German locale

4. **Add German translations** for UI strings in your l10n folder

## Testing - Testen

After adding translations, test the following:

1. ✅ All German files compile without errors
2. ✅ Saint data loads correctly in German mode
3. 📝 Quotes display properly (after translation)
4. 📝 Articles display properly (after translation)
5. 📝 Special characters (ä, ö, ü, ß) render correctly

## Notes - Hinweise

- Image paths remain the same across all languages
- Saint IDs remain unchanged for consistency
- Article IDs remain in English for easier reference
- Follow the same pattern as Hindi implementation for consistency

## Translation Guidelines - Übersetzungsrichtlinien

When translating:

1. **Maintain spiritual terminology** - Keep Sanskrit/spiritual terms when appropriate
2. **Respect cultural context** - Some concepts may not have direct German equivalents
3. **Be consistent** - Use the same terms for recurring concepts
4. **Keep formatting** - Preserve line breaks, paragraphs, and special characters
5. **Test thoroughly** - Verify all special characters render correctly

## File Example - Dateibeispiel

Complete structure of a German saint file:

```dart
// saint_name_de.dart
// German file for Saint Name
// Deutsche Datei für Heiliger Name

import '../articlesquotes_de.dart';

final saintNameDe = SaintDe(
  'saint_id',
  'Saint Name',
  'assets/images/saint.jpg',
  [
    'German quote 1',
    'German quote 2',
    // ... more quotes
  ],
  [
    Article(
        id: 'article_id',
        heading: 'German Heading',
        body: 'German article body...'
    ),
    // ... more articles
  ],
);
```

## Contributors - Mitwirkende

- Initial structure: AI Assistant
- Translations: [To be added - Hinzuzufügen]

## License - Lizenz

Same as main project

---

**Last Updated - Zuletzt aktualisiert:** January 23, 2026
