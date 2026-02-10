# Tamil Saints Directory

This directory is reserved for Tamil language saint files.

## Structure

Each saint file should follow this naming convention:
- `saintname_ta.dart`

## Example Structure

```dart
// saintname_ta.dart
// Tamil quotes and articles for Saint Name
// புனிதர் பெயருக்கான தமிழ் மேற்கோள்கள் மற்றும் கட்டுரைகள்

import '../articlesquotes_ta.dart';

final saintnameSaintTa = Saint(
  'saintname',
  'புனிதர் பெயர்',
  'assets/images/saintname.jpg',
  [
    'தமிழ் மேற்கோள் 1',
    'தமிழ் மேற்கோள் 2',
    // Add more quotes...
  ],
  [
    Article(
      'கட்டுரை தலைப்பு',
      'கட்டுரை உள்ளடக்கம்...'
    ),
    // Add more articles...
  ],
);
```

## Adding Saints

To add a new saint:

1. Create a new file following the naming convention above
2. Import it in `articlesquotes_ta.dart`
3. Add the saint to the `saintsTa` list in `articlesquotes_ta.dart`

## Notes

- All text content should be in Tamil (தமிழ்)
- The saint ID (first parameter) should match the English version
- Image paths should match existing saint images
- Follow the same quote and article structure as other language files
