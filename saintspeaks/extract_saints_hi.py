#!/usr/bin/env python3
"""
Script to extract individual Hindi saint data from articlesquotes_hi.dart
and create separate files in saints_hi directory.
"""

import os
import re

# Read the original file
with open('lib/articlesquotes_hi.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Define saint boundaries based on the line numbers from grep search
saints_data = [
    ('vivekananda', 21, 170),
    ('sivananda', 171, 300),
    ('yogananda', 301, 426),
    ('ramana', 427, 459),
    ('shankaracharya', 460, 530),
    ('anandmoyima', 531, 601),
    ('nisargadatta', 602, 681),
    ('neem_karoli_baba', 682, 891)
]

# Split content into lines
lines = content.split('\n')

# Create saints_hi directory if it doesn't exist
os.makedirs('lib/saints_hi', exist_ok=True)

# Extract each saint's data
for saint_id, start_line, end_line in saints_data:
    # Extract the saint's data (line numbers are 1-based)
    saint_lines = lines[start_line-1:end_line]

    # Join the lines
    saint_content = '\n'.join(saint_lines)

    # Remove the leading/trailing SaintHi(...) and closing parenthesis
    # Find the actual saint data
    # The saint data starts with SaintHi( and we need to extract just the content

    # Create the file with proper import
    file_content = f'''// {saint_id}_hi.dart
// Hindi quotes and articles for {saint_id}

import '../articlesquotes_hi.dart';

final {saint_id}SaintHi = {saint_content.strip()}
  {',' if not saint_content.strip().endswith(',') else ''}
'''.replace('  SaintHi(', 'SaintHi(')

    # Handle the last saint which has the closing bracket for the list
    if saint_id == 'neem_karoli_baba':
        file_content = file_content.replace('\n];\n', '\n')
        file_content = file_content.rstrip().rstrip(',').rstrip(')').rstrip() + '\n);'
    else:
        file_content = file_content.rstrip().rstrip(',').rstrip(')').rstrip() + '\n);'

    # Write to file
    output_file = f'lib/saints_hi/{saint_id}_hi.dart'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(file_content)

    print(f"Created {output_file}")

print("\nAll Hindi saint files created successfully!")
