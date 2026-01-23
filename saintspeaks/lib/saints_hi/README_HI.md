# Saints Data (Hindi) - Refactoring

## Overview
The Hindi saints data has been split into individual files for better maintainability. Each saint now has their own file in the `lib/saints_hi/` directory.

## File Structure

```
lib/
├── articlesquotes.dart          # Base classes (Article, Saint)
├── articlesquotes_hi.dart       # New Hindi version (imports all saints)
└── saints_hi/
    ├── vivekananda_hi.dart
    ├── sivananda_hi.dart
    ├── yogananda_hi.dart
    ├── ramana_hi.dart
    ├── shankaracharya_hi.dart
    ├── anandmoyima_hi.dart
    ├── nisargadatta_hi.dart
    └── neem_karoli_baba_hi.dart
```

## Hindi Saint Files

Each saint file contains:
- Hindi quotes
- Hindi articles  
- Uses the `SaintHi` and `ArticleHi` classes from `articlesquotes_hi.dart`

## Usage

Import the main Hindi file which includes all saints:
```dart
import 'articlesquotes_hi.dart';
```

The main `articlesquotes_hi.dart` file imports all individual saint files and exports a `saintsHi` list containing all Hindi saints.

## Notes

- Similar structure to English saint files
- Maintains backward compatibility
- Each file is self-contained with imports
