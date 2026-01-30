# Bengali Saints Translations (বাংলা অনুবাদ)

## Overview
This folder contains Bengali translations of quotes and articles from various saints and spiritual leaders. The translations are designed to make spiritual wisdom accessible to Bengali-speaking users.

## Structure
Each saint has a dedicated file following the naming pattern: `{saint_name}_bn.dart`

## Saints Included
1. **Swami Vivekananda** - স্বামী বিবেকানন্দ (`vivekananda_bn.dart`)
2. **Swami Sivananda** - স্বামী শিবানন্দ (`sivananda_bn.dart`)
3. **Adi Shankaracharya** - আদি শঙ্করাচার্য (`shankaracharya_bn.dart`)
4. **Anandamayi Ma** - আনন্দময়ী মা (`anandmoyima_bn.dart`)
5. **Paramahansa Yogananda** - পরমহংস যোগানন্দ (`yogananda_bn.dart`)
6. **Ramana Maharshi** - রমণ মহর্ষি (`ramana_bn.dart`)
7. **Nisargadatta Maharaj** - নিসর্গদত্ত মহারাজ (`nisargadatta_bn.dart`)
8. **Neem Karoli Baba** - নিম করোলি বাবা (`neem_karoli_baba_bn.dart`)
9. **Ramakrishna Paramahamsa** - রামকৃষ্ণ পরমহংস (`ramakrishna_bn.dart`)
10. **Tapovan Maharaj** - তপোবন মহারাজ (`tapovan_maharaj_bn.dart`)

## Translation Guidelines

### General Principles
- Maintain the spiritual essence and meaning of the original text
- Use clear, accessible Bengali that resonates with modern readers
- Preserve key Sanskrit/spiritual terms where appropriate (e.g., "ধ্যান" for meditation, "মোক্ষ" for liberation)
- Ensure cultural sensitivity and respect for the spiritual teachings

### Bengali Script Considerations
- Use proper Bengali diacritics (মাত্রা)
- Pay attention to conjunct characters (যুক্তাক্ষর)
- Maintain consistency in transliterating Sanskrit terms
- Use appropriate honorifics (e.g., জী, মহারাজ, স্বামী)

### File Structure
Each saint file should follow this structure:

```dart
// Bengali translations for [Saint Name]
const List<String> {saint}QuotesBn = [
  'Quote 1 in Bengali',
  'Quote 2 in Bengali',
  // ... more quotes
];

class ArticleBn {
  final String heading;
  final String body;
  ArticleBn({required this.heading, required this.body});
}

final List<ArticleBn> {saint}ArticlesBn = [
  ArticleBn(
    heading: 'Article Heading in Bengali',
    body: 'Article body in Bengali...',
  ),
  // ... more articles
];
```

## Implementation Status

| Saint | Quotes | Articles | Status |
|-------|--------|----------|--------|
| Vivekananda | ⏳ Pending | ⏳ Pending | 🔲 TODO |
| Sivananda | ⏳ Pending | ⏳ Pending | 🔲 TODO |
| Shankaracharya | ⏳ Pending | ⏳ Pending | 🔲 TODO |
| Anandamayi Ma | ⏳ Pending | ⏳ Pending | 🔲 TODO |
| Yogananda | ⏳ Pending | ⏳ Pending | 🔲 TODO |
| Ramana Maharshi | ⏳ Pending | ⏳ Pending | 🔲 TODO |
| Nisargadatta | ⏳ Pending | ⏳ Pending | 🔲 TODO |
| Neem Karoli Baba | ⏳ Pending | ⏳ Pending | 🔲 TODO |
| Ramakrishna | ⏳ Pending | ⏳ Pending | 🔲 TODO |
| Tapovan Maharaj | ⏳ Pending | ⏳ Pending | 🔲 TODO |

## Translation Priority
Given the Bengali cultural context, the following saints may have special significance:
1. **Ramakrishna Paramahamsa** - Born in Bengal, taught in Bengali
2. **Swami Vivekananda** - Disciple of Ramakrishna, Bengali origin
3. **Anandamayi Ma** - Born in Bengal, spoke Bengali
4. **Shankaracharya** - Classical Advaita philosophy
5. Other saints in order of popularity

## Next Steps
1. ✅ Created folder structure and empty files
2. 🔲 Translate Ramakrishna quotes and articles (High Priority - Bengali saint)
3. 🔲 Translate Vivekananda quotes and articles (High Priority - Bengali saint)
4. 🔲 Translate Anandamayi Ma quotes and articles (High Priority - Bengali saint)
5. 🔲 Translate remaining saints
6. 🔲 Create `articlesquotes_bn.dart` aggregator file
7. 🔲 Update main app to support Bengali saint content
8. 🔲 Test Bengali text rendering and layout
9. 🔲 Review translations with native Bengali speakers

## Notes for Translators
- **Ramakrishna Paramahamsa** already taught extensively in Bengali - original Bengali texts may be available
- **Anandamayi Ma** also spoke in Bengali - look for authentic Bengali sources
- For Sanskrit-heavy philosophical texts (Shankaracharya), maintain balance between traditional terminology and accessibility
- Consider the regional Bengali dialect - aim for standard Bengali (সাধু ভাষা or চলিত ভাষা based on content)

## Resources
- Reference existing Hindi translations in `/saints_hi/` for guidance
- Original English content in `/saints/`
- German translations in `/saints_de/` for structural reference
- Kannada translations in `/saints_kn/` for structural reference

## Contact
For translation questions or cultural context, please reach out to the development team.

---
**Status**: 🟡 In Progress - Files created, translations pending
**Last Updated**: January 28, 2026
**Language**: Bengali (বাংলা)
