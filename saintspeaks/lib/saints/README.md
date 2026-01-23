# Saints Data Refactoring Guide

## Overview
The saints data has been split into individual files for better maintainability. Each saint now has their own file in the `lib/saints/` directory.

## File Structure

```
lib/
├── articlesquotes.dart          # Original file (keep as is - contains base classes)
├── articlesquotes_en.dart       # New English version (imports all saints)
└── saints/
    ├── vivekananda_en.dart
    ├── sivananda_en.dart
    ├── yogananda_en.dart
    ├── ramana_en.dart
    ├── shankaracharya_en.dart
    ├── anandmoyima_en.dart
    ├── nisargadatta_en.dart
    └── neem_karoli_baba_en.dart
```

## Instructions for Copying Data

### Step 1: Copy Saint Data from articlesquotes.dart

For each saint, copy their data from `articlesquotes.dart` to the corresponding file:

1. **Vivekananda** (lines ~20-183) → `saints/vivekananda_en.dart`
2. **Sivananda** (lines ~184-317) → `saints/sivananda_en.dart`
3. **Yogananda** (lines ~318-454) → `saints/yogananda_en.dart`
4. **Ramana Maharshi** (lines ~455-490) → `saints/ramana_en.dart`
5. **Shankaracharya** (lines ~491-561) → `saints/shankaracharya_en.dart`
6. **Anandamayi Ma** (lines ~562-632) → `saints/anandmoyima_en.dart`
7. **Nisargadatta** (lines ~633-711) → `saints/nisargadatta_en.dart`
8. **Neem Karoli Baba** (lines ~712-918) → `saints/neem_karoli_baba_en.dart`

### Step 2: Format of Each File

Each saint file should follow this structure:

```dart
import '../articlesquotes.dart';

final saintNameSaint = Saint(
  'saint_id',
  'Saint Display Name',
  'assets/images/saint_image.jpg',
  [
    // Paste all quotes here
    'Quote 1',
    'Quote 2',
    // ... more quotes
  ],
  [
    // Paste all articles here
    Article(
      heading: 'Article Title',
      body: 'Article content...',
    ),
    // ... more articles
  ],
);
```

### Step 3: Update Your App to Use the New Structure

Once you've copied all the data, update your app to import from `articlesquotes_en.dart` instead of `articlesquotes.dart`:

**Before:**
```dart
import 'articlesquotes.dart';
final mySaints = saints;
```

**After:**
```dart
import 'articlesquotes_en.dart';
final mySaints = saintsEn;
```

## Benefits

1. **Easier to maintain**: Each saint's data is in its own file
2. **Better organization**: Clear structure with saints directory
3. **Faster loading**: Can lazy-load saints if needed
4. **Easier collaboration**: Multiple people can work on different saints
5. **Version control**: Smaller diffs when making changes

## Next Steps

1. Copy all saint data from `articlesquotes.dart` to individual files
2. Test that the app works with `articlesquotes_en.dart`
3. Later, create Hindi versions (e.g., `vivekananda_hi.dart`) in the same structure
4. Keep `articlesquotes.dart` as backup until migration is complete

## Notes

- The base classes (Article and Saint) remain in `articlesquotes.dart`
- All individual saint files import from `articlesquotes.dart` to use these classes
- Hindi versions will follow the same pattern with `_hi.dart` suffix
