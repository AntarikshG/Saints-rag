#!/usr/bin/env python3
import os

# List of Hindi saint files
hindi_files = [
    'lib/saints_hi/vivekananda_hi.dart',
    'lib/saints_hi/sivananda_hi.dart',
    'lib/saints_hi/yogananda_hi.dart',
    'lib/saints_hi/ramana_hi.dart',
    'lib/saints_hi/shankaracharya_hi.dart',
    'lib/saints_hi/anandmoyima_hi.dart',
    'lib/saints_hi/nisargadatta_hi.dart',
    'lib/saints_hi/neem_karoli_baba_hi.dart',
]

for filepath in hindi_files:
    print(f'Processing: {filepath}')

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Count replacements
    saint_count = content.count('SaintHi(')
    article_count = content.count('ArticleHi(')

    # Replace
    content = content.replace('SaintHi(', 'Saint(')
    content = content.replace('ArticleHi(', 'Article(')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f'  Replaced {saint_count} SaintHi and {article_count} ArticleHi occurrences')

print('\nAll Hindi files updated successfully!')
