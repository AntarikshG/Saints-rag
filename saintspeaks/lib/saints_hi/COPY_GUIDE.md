# हिंदी संतों की फ़ाइलें बनाने की गाइड
# Guide to Creating Hindi Saint Files

## Overview
This guide will help you extract saint data from the original `articlesquotes_hi.dart` file and create separate files for each saint.

## Saint Line Ranges in articlesquotes_hi.dart

Based on the structure of the file, here are the line numbers for each saint:

1. **Vivekananda (विवेकानंद)** - Lines 21-170
2. **Sivananda (शिवानंद)** - Lines 171-300
3. **Yogananda (योगानंद)** - Lines 301-426
4. **Ramana Maharshi (रमण महर्षि)** - Lines 427-459
5. **Shankaracharya (शंकराचार्य)** - Lines 460-530
6. **Anandamayi Ma (आनंदमयी माँ)** - Lines 531-601
7. **Nisargadatta (निसर्गदत्त)** - Lines 602-681
8. **Neem Karoli Baba (नीम करोली बाबा)** - Lines 682-891

## File Template

Each saint file should follow this structure:

```dart
// saint_name_hi.dart
// Hindi quotes and articles for Saint Name

import '../articlesquotes_hi.dart';

final saintNameSaintHi = Saint(
  'saint_id',
  'संत का नाम',
  'assets/images/saint_image.jpg',
  [
    // Paste all quotes here
  ],
  [
    // Paste all articles here
  ],
);
```

## Steps to Create Each File

### Step 1: Open the original file
Open `lib/articlesquotes_hi.dart` in your editor.

### Step 2: Extract saint data
For each saint, copy the lines indicated above. The data starts with `Saint(` and ends with `),`.

### Step 3: Create new file
Create a new file in `lib/saints_hi/` directory with the appropriate name:
- `vivekananda_hi.dart`
- `sivananda_hi.dart`
- `yogananda_hi.dart`
- `ramana_hi.dart`
- `shankaracharya_hi.dart`
- `anandmoyima_hi.dart`
- `nisargadatta_hi.dart`
- `neem_karoli_baba_hi.dart`

### Step 4: Add imports and wrap data
Add the import statement at the top:
```dart
import '../articlesquotes_hi.dart';
```

Wrap the saint data in a variable:
```dart
final saintNameSaintHi = /* paste Saint(...) data here */;
```

### Step 5: Update main file
After all individual files are created, update `articlesquotes_hi.dart` to import them:

```dart
// Import all saint files
import 'saints_hi/vivekananda_hi.dart';
import 'saints_hi/sivananda_hi.dart';
import 'saints_hi/yogananda_hi.dart';
import 'saints_hi/ramana_hi.dart';
import 'saints_hi/shankaracharya_hi.dart';
import 'saints_hi/anandmoyima_hi.dart';
import 'saints_hi/nisargadatta_hi.dart';
import 'saints_hi/neem_karoli_baba_hi.dart';

// Create saints list
final saintsHi = [
  vivekanandaSaintHi,
  sivanandaSaintHi,
  yoganandaSaintHi,
  ramanaSaintHi,
  shankaracharyaSaintHi,
  anandmoyimaSaintHi,
  nisargadattaSaintHi,
  neem_karoli_babaSaintHi,
];
```

## Variable Naming Convention

Follow this pattern for naming the saint variables:
- Vivekananda → `vivekanandaSaintHi`
- Sivananda → `sivanandaSaintHi`
- Yogananda → `yoganandaSaintHi`
- Ramana → `ramanaSaintHi`
- Shankaracharya → `shankaracharyaSaintHi`
- Anandamayi Ma → `anandmoyimaSaintHi`
- Nisargadatta → `nisargadattaSaintHi`
- Neem Karoli Baba → `neem_karoli_babaSaintHi`

## Notes

- Make sure to maintain the exact formatting and structure
- Don't forget to remove the trailing comma from the last article in each saint's data
- Test compilation after creating each file to catch errors early
- The `articlesquotes_hi.dart` file should only contain the class definitions and imports after refactoring

## Verification

After completing all files, verify:
1. All 8 saint files exist in `saints_hi/` directory
2. Each file has proper imports
3. The main `articlesquotes_hi.dart` imports all saints
4. The app compiles without errors
5. All saints are visible in the app
