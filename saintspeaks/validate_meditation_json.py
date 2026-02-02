#!/usr/bin/env python3
"""
JSON Validator for saintsapp.json
Validates the meditation JSON format and checks for common errors
"""

import json
import sys
from urllib.request import urlopen

CONFIG_URL = "https://raw.githubusercontent.com/AntarikshG/configuration/main/saintsapp.json"

def validate_json_file(file_path=None):
    """Validate JSON from file or URL"""
    print("🔍 JSON Validator for saintsapp.json\n")

    try:
        if file_path:
            print(f"📄 Reading from file: {file_path}")
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        else:
            print(f"🌐 Fetching from URL: {CONFIG_URL}")
            with urlopen(CONFIG_URL) as response:
                content = response.read().decode('utf-8')

        print(f"✓ Content loaded ({len(content)} characters)\n")

        # Parse JSON
        print("🔄 Parsing JSON...")
        data = json.loads(content)
        print("✅ Valid JSON structure!\n")

        # Validate required fields
        print("📋 Checking required fields...")
        required_fields = ['gradio_server_running', 'gradio_server_link', 'latest_app_version']
        for field in required_fields:
            if field in data:
                print(f"  ✓ {field}: {data[field]}")
            else:
                print(f"  ⚠️  {field}: MISSING")

        # Check meditation_data
        print("\n🧘 Checking meditation_data...")
        if 'meditation_data' not in data:
            print("  ⚠️  meditation_data field is missing!")
        elif not isinstance(data['meditation_data'], list):
            print(f"  ❌ meditation_data should be an array, got {type(data['meditation_data'])}")
        elif len(data['meditation_data']) == 0:
            print("  ⚠️  meditation_data is empty (no meditations)")
        else:
            print(f"  ✓ Found {len(data['meditation_data'])} meditation(s)")

            # Validate each meditation
            for i, med in enumerate(data['meditation_data']):
                med_num = i + 1
                print(f"\n  Meditation #{med_num}:")

                # Check required fields
                required_med_fields = ['id', 'name', 'name_hi', 'audio_url', 'duration_minutes']
                missing_fields = []
                for field in required_med_fields:
                    if field not in med:
                        missing_fields.append(field)
                    else:
                        value = med[field]
                        if field == 'duration_minutes':
                            if not isinstance(value, int):
                                print(f"    ⚠️  {field} should be a number, got: {type(value).__name__}")
                            else:
                                print(f"    ✓ {field}: {value}")
                        else:
                            print(f"    ✓ {field}: {value[:50] if len(str(value)) > 50 else value}")

                if missing_fields:
                    print(f"    ❌ Missing required fields: {', '.join(missing_fields)}")

                # Check optional fields
                optional_fields = ['description', 'description_hi', 'category', 'instructor', 'difficulty']
                for field in optional_fields:
                    if field in med:
                        print(f"    ℹ️  {field}: {med[field][:50] if len(str(med[field])) > 50 else med[field]}")

                # Validate audio URL
                if 'audio_url' in med:
                    url = med['audio_url']
                    if not url.startswith('https://'):
                        print(f"    ⚠️  audio_url should use HTTPS: {url}")
                    if not (url.endswith('.mp3') or url.endswith('.m4a') or url.endswith('.wav')):
                        print(f"    ⚠️  audio_url should end with .mp3, .m4a, or .wav: {url}")

        # Check ekadashi_data
        print("\n📅 Checking ekadashi_data...")
        if 'ekadashi_data' in data:
            ekadashi_count = len(data['ekadashi_data'])
            print(f"  ✓ Found {ekadashi_count} Ekadashi date(s)")
            if ekadashi_count > 0:
                print("  Sample dates:")
                for date_key in list(data['ekadashi_data'].keys())[:3]:
                    print(f"    - {date_key}: {data['ekadashi_data'][date_key]}")

        print("\n" + "="*60)
        print("✅ VALIDATION COMPLETE - JSON is valid!")
        print("="*60)
        return True

    except json.JSONDecodeError as e:
        print(f"\n❌ JSON PARSE ERROR:")
        print(f"   Line {e.lineno}, Column {e.colno}")
        print(f"   {e.msg}")
        print(f"\n💡 Common fixes:")
        print("   - Remove trailing commas (e.g., after last item in object/array)")
        print("   - Check for missing commas between items")
        print("   - Ensure all strings use double quotes (not single)")
        print("   - Validate at: https://jsonlint.com/")
        return False

    except Exception as e:
        print(f"\n❌ ERROR: {type(e).__name__}: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Validate local file
        file_path = sys.argv[1]
        validate_json_file(file_path)
    else:
        # Validate remote URL
        validate_json_file()
