# Quick Reference: Meditation JSON Format 📋

## 🚨 TROUBLESHOOTING: FormatException Error

**If you see this error:**
```
Error fetching meditations: FormatException: Unexpected character (at line 41, character 2)
 "meditation_data": [
 ^
```

**Quick Fix:** This means invalid JSON syntax. Most common causes:

1. **Trailing comma in ekadashi_data** (MOST COMMON):
   ```json
   "ekadashi_data": {
     "2025-01-13": "Putrada Ekadashi",  ← REMOVE THIS COMMA!
   },
   ```

2. **Missing comma between fields**
3. **Double commas (,,)**

**Solution:** 
- Go to https://jsonlint.com/
- Paste your FULL `saintsapp.json` file
- Fix errors shown
- Update GitHub file

See `JSON_FORMAT_ERROR_FIX.md` for detailed troubleshooting guide.

---

## Minimal Example (Required Fields Only)

```json
{
  "meditation_data": [
    {
      "id": "meditation_001",
      "name": "Morning Meditation",
      "name_hi": "प्रातः ध्यान",
      "audio_url": "https://example.com/morning.mp3",
      "duration_minutes": 10
    }
  ]
}
```

## Complete Example (All Fields)

```json
{
  "meditation_data": [
    {
      "id": "meditation_001",
      "name": "Morning Peace Meditation",
      "name_hi": "प्रातः शांति ध्यान",
      "description": "Start your day with inner peace",
      "description_hi": "अपने दिन की शुरुआत आंतरिक शांति के साथ करें",
      "duration_minutes": 10,
      "category": "morning",
      "audio_url": "https://example.com/morning_peace.mp3",
      "instructor": "Swami Sivananda",
      "difficulty": "beginner"
    }
  ]
}
```

## Field Reference

| Field | Type | Required | Example | Notes |
|-------|------|----------|---------|-------|
| `id` | string | ✅ Yes | `"meditation_001"` | Unique identifier |
| `name` | string | ✅ Yes | `"Morning Meditation"` | English name |
| `name_hi` | string | ✅ Yes | `"प्रातः ध्यान"` | Hindi name |
| `audio_url` | string | ✅ Yes | `"https://..."` | Direct MP3 URL |
| `duration_minutes` | integer | ✅ Yes | `10` | Duration in minutes |
| `description` | string | ❌ No | `"Start your day..."` | English description |
| `description_hi` | string | ❌ No | `"अपने दिन की..."` | Hindi description |
| `category` | string | ❌ No | `"morning"` | Category name |
| `instructor` | string | ❌ No | `"Swami Sivananda"` | Teacher name |
| `difficulty` | string | ❌ No | `"beginner"` | Difficulty level |

## Category Options

```json
"category": "morning"     // Morning meditations 🌞
"category": "breathing"   // Breath-focused 💨
"category": "chakra"      // Energy work 🧘
"category": "relaxation"  // Deep relaxation 🛋️
"category": "mantra"      // Mantra-based 🎵
"category": "evening"     // Evening meditations 🌙
"category": "general"     // General meditation
```

## Difficulty Options

```json
"difficulty": "beginner"      // For beginners (green badge)
"difficulty": "intermediate"  // Some experience (orange badge)
"difficulty": "advanced"      // Experienced (red badge)
```

## Sample Data Set (6 Meditations)

```json
{
  "gradio_server_running": true,
  "gradio_server_link": "https://your-server.com",
  "latest_app_version": "2.3.0",
  "ekadashi_data": {
    "2025-01-13": "Putrada Ekadashi"
  },
  "meditation_data": [
    {
      "id": "med_morning_001",
      "name": "Morning Peace",
      "name_hi": "प्रातः शांति",
      "description": "Start your day with inner peace and clarity",
      "description_hi": "अपने दिन की शुरुआत आंतरिक शांति और स्पष्टता के साथ करें",
      "duration_minutes": 10,
      "category": "morning",
      "audio_url": "https://example.com/morning_peace.mp3",
      "instructor": "Swami Sivananda",
      "difficulty": "beginner"
    },
    {
      "id": "med_breathing_001",
      "name": "Breath Awareness",
      "name_hi": "श्वास जागरूकता",
      "description": "Focus on your breath to calm the mind",
      "description_hi": "मन को शांत करने के लिए अपनी सांस पर ध्यान केंद्रित करें",
      "duration_minutes": 15,
      "category": "breathing",
      "audio_url": "https://example.com/breath_awareness.mp3",
      "instructor": "Swami Vivekananda",
      "difficulty": "beginner"
    },
    {
      "id": "med_chakra_001",
      "name": "Chakra Meditation",
      "name_hi": "चक्र ध्यान",
      "description": "Balance your energy centers",
      "description_hi": "अपने ऊर्जा केंद्रों को संतुलित करें",
      "duration_minutes": 20,
      "category": "chakra",
      "audio_url": "https://example.com/chakra_balance.mp3",
      "instructor": "Paramahansa Yogananda",
      "difficulty": "intermediate"
    },
    {
      "id": "med_relaxation_001",
      "name": "Deep Relaxation",
      "name_hi": "गहन विश्राम",
      "description": "Release tension and achieve profound relaxation",
      "description_hi": "तनाव मुक्त करें और गहन विश्राम प्राप्त करें",
      "duration_minutes": 25,
      "category": "relaxation",
      "audio_url": "https://example.com/deep_relaxation.mp3",
      "instructor": "Ramana Maharshi",
      "difficulty": "intermediate"
    },
    {
      "id": "med_mantra_001",
      "name": "Om Chanting",
      "name_hi": "ॐ जप",
      "description": "Connect with universal consciousness through Om",
      "description_hi": "ॐ के माध्यम से सार्वभौमिक चेतना से जुड़ें",
      "duration_minutes": 12,
      "category": "mantra",
      "audio_url": "https://example.com/om_chanting.mp3",
      "instructor": "Adi Shankaracharya",
      "difficulty": "beginner"
    },
    {
      "id": "med_evening_001",
      "name": "Evening Wind Down",
      "name_hi": "सायंकाल विश्राम",
      "description": "Peaceful meditation to end your day",
      "description_hi": "अपने दिन को समाप्त करने के लिए शांतिपूर्ण ध्यान",
      "duration_minutes": 18,
      "category": "evening",
      "audio_url": "https://example.com/evening_wind_down.mp3",
      "instructor": "Sri Ramakrishna",
      "difficulty": "beginner"
    }
  ]
}
```

## Audio URL Examples

### ✅ Valid URLs:
```
https://example.com/meditation.mp3
https://cdn.example.com/audio/morning.mp3
https://storage.googleapis.com/bucket/file.mp3
https://s3.amazonaws.com/bucket/meditation.m4a
```

### ❌ Invalid URLs:
```
http://unsecure-url.com/file.mp3     // Must be HTTPS
/relative/path/file.mp3               // Must be full URL
file:///local/path.mp3                // Must be remote
```

## ID Naming Convention

Recommended format: `{category}_{type}_{number}`

Examples:
- `med_morning_001`, `med_morning_002`
- `med_breathing_001`, `med_breathing_002`
- `med_chakra_001`
- `med_relaxation_001`
- `med_mantra_001`
- `med_evening_001`

## Hindi Name Examples

| English | Hindi |
|---------|-------|
| Morning Meditation | प्रातः ध्यान |
| Peace Meditation | शांति ध्यान |
| Breath Awareness | श्वास जागरूकता |
| Chakra Meditation | चक्र ध्यान |
| Deep Relaxation | गहन विश्राम |
| Om Chanting | ॐ जप |
| Evening Meditation | सायंकाल ध्यान |
| Guided Meditation | निर्देशित ध्यान |
| Silent Meditation | मौन ध्यान |
| Walking Meditation | चलते हुए ध्यान |

## Duration Guidelines

- **5-10 minutes**: Quick sessions, perfect for beginners
- **10-15 minutes**: Standard practice
- **15-20 minutes**: Deep practice
- **20-30 minutes**: Advanced/experienced practitioners
- **30+ minutes**: Expert level

## Testing Your JSON

### 1. Validate JSON format:
Visit: https://jsonlint.com/
Paste your JSON and click "Validate"

### 2. Test single meditation:
```json
{
  "meditation_data": [
    {
      "id": "test_001",
      "name": "Test Meditation",
      "name_hi": "परीक्षण ध्यान",
      "audio_url": "YOUR_TEST_URL_HERE.mp3",
      "duration_minutes": 5
    }
  ]
}
```

### 3. Verify audio URL:
- Open URL in browser
- Should download/play MP3 file
- Check file size (keep under 50MB)

## Common Mistakes to Avoid

❌ Missing comma between objects:
```json
{
  "id": "med_001"
  "name": "Test"  // ❌ Missing comma
}
```

✅ Correct:
```json
{
  "id": "med_001",
  "name": "Test"  // ✅ Has comma
}
```

❌ Duplicate IDs:
```json
{"id": "med_001", ...},
{"id": "med_001", ...}  // ❌ Same ID
```

❌ Wrong data types:
```json
{
  "duration_minutes": "10"  // ❌ String (should be number)
}
```

✅ Correct:
```json
{
  "duration_minutes": 10  // ✅ Number
}
```

## Quick Start Checklist

- [ ] Create meditation audio files (MP3)
- [ ] Upload to accessible HTTPS server
- [ ] Copy sample JSON from this guide
- [ ] Replace audio URLs with your URLs
- [ ] Customize names, descriptions, instructors
- [ ] Validate JSON at jsonlint.com
- [ ] Update saintsapp.json on GitHub
- [ ] Test in app

## Where to Add This

Update your remote config file:
```
https://raw.githubusercontent.com/AntarikshG/configuration/main/saintsapp.json
```

Add the `meditation_data` array alongside your existing `ekadashi_data`:

```json
{
  "gradio_server_running": true,
  "gradio_server_link": "...",
  "latest_app_version": "2.3.0",
  "ekadashi_data": { ... },
  "meditation_data": [ ... ]  ← Add here
}
```

## Need Help?

Common resources:
- JSON validator: https://jsonlint.com/
- MP3 hosting: AWS S3, Google Cloud Storage, CDN
- Free meditation audio: Creative Commons licensed content
- Hindi translation: Google Translate as starting point

---

**Ready to meditate!** 🧘‍♂️✨
