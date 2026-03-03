# Quick Copy Reference Guide

This guide shows you exactly which lines to copy from articlesquotes.dart to each saint file.

## Line Numbers Reference

Open `articlesquotes.dart` and copy the following sections:

### 1. Vivekananda (vivekananda_en.dart)
- **Lines to copy**: 20-183
- **What to copy**: Everything inside the Saint() constructor (id, name, image, quotes array, articles array)
- **Target file**: `saints/vivekananda_en.dart`
- Replace the placeholder quotes and articles with the full data

### 2. Sivananda (sivananda_en.dart)
- **Lines to copy**: 184-317
- **Target file**: `saints/sivananda_en.dart`

### 3. Yogananda (yogananda_en.dart)
- **Lines to copy**: 318-454
- **Target file**: `saints/yogananda_en.dart`

### 4. Ramana Maharshi (ramana_en.dart)
- **Lines to copy**: 455-490
- **Target file**: `saints/ramana_en.dart`

### 5. Shankaracharya (shankaracharya_en.dart)
- **Lines to copy**: 491-561
- **Target file**: `saints/shankaracharya_en.dart`

### 6. Anandamayi Ma (anandmoyima_en.dart)
- **Lines to copy**: 562-632
- **Target file**: `saints/anandmoyima_en.dart`

### 7. Nisargadatta (nisargadatta_en.dart)
- **Lines to copy**: 633-711
- **Target file**: `saints/nisargadatta_en.dart`

### 8. Neem Karoli Baba (neem_karoli_baba_en.dart)
- **Lines to copy**: 712-918
- **Target file**: `saints/neem_karoli_baba_en.dart`

## How to Copy

For each saint:

1. Open `articlesquotes.dart` in your editor
2. Find the line numbers mentioned above
3. Copy the entire Saint() constructor content
4. Open the corresponding `_en.dart` file in the `saints/` folder
5. Replace the placeholder content with what you copied
6. Make sure the structure is:
   ```dart
   final saintVariableName = Saint(
     'id',
     'Name',
     'image/path',
     [ /* quotes here */ ],
     [ /* articles here */ ],
   );
   ```

## Testing

After copying all data:

1. Make sure no syntax errors appear
2. Update your app to use `saintsEn` from `articlesquotes_en.dart` instead of `saints` from `articlesquotes.dart`
3. Run the app and verify all saints display correctly

## Example

Here's what vivekananda_en.dart should look like after copying (showing structure only):

```dart
import '../articlesquotes.dart';

final vivekanandaSaint = Saint(
  'vivekananda',
  'Swami Vivekananda',
  'assets/images/vivekananda.jpg',
  [
    'Arise, awake, and stop not till the goal is reached.',
    'Take up one idea. Make that one idea your life — think of it, dream of it, live on that idea.',
    // ... paste all remaining quotes from articlesquotes.dart
  ],
  [
    Article(
      heading: 'Swami Vivekananda: Short life sketch',
      body: 'The great secret of true success...',
    ),
    // ... paste all remaining articles from articlesquotes.dart
  ],
);
```
