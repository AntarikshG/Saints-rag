# Badge System - Quick Reference

## Point Values
| Action | Points | Frequency |
|--------|--------|-----------|
| Read Quote | **5 points** | Once per unique quote |
| Read Article | **20 points** | Once per unique article |
| Ask Question | **10 points** | Every question |
| Share Quote | **30 points** | Every share (Distribution of knowledge) |

## Badge Tiers
| Badge | Icon | Points Required | Color |
|-------|------|-----------------|-------|
| Bronze | 🥉 | 0-99 | Bronze/Copper |
| Silver | 🥈 | 100-299 | Silver |
| Gold | 🏆 | 300-599 | Gold |
| Platinum | ⭐ | 600-999 | Platinum/White |
| Diamond | 💎 | 1000+ | Cyan/Diamond |

## Example Journeys to Each Badge

### Path to Silver Badge (100 points)
- **Option 1**: Read 20 quotes (20 × 5 = 100)
- **Option 2**: Read 5 articles (5 × 20 = 100)
- **Option 3**: Ask 10 questions (10 × 10 = 100)
- **Option 4**: Share 4 quotes (4 × 30 = 120)
- **Option 5 (Recommended)**: Mix of 10 quotes + 2 articles + 3 questions = 80 points

### Path to Gold Badge (300 points)
- **Option 1**: Read 15 articles (15 × 20 = 300)
- **Option 2**: Read 30 quotes + 10 articles (150 + 200 = 350)
- **Option 3**: Read 10 articles + ask 10 questions (200 + 100 = 300)

### Path to Platinum Badge (600 points)
- **Option 1**: Read 30 articles (30 × 20 = 600)
- **Option 2**: Read 20 articles + 20 quotes + 10 questions (400 + 100 + 100 = 600)
- **Option 3**: Mix of all activities for balanced learning

### Path to Diamond Badge (1000 points)
- **Option 1**: Read 50 articles (50 × 20 = 1000)
- **Option 2**: Read 40 articles + 20 quotes + 10 questions (800 + 100 + 100 = 1000)
- **Recommended**: Engage with all content types regularly over time

## Display Locations

### 1. App Bar Badge (Always Visible)
```
Location: Top-right corner of home screen
Format: [Icon] [Points]
Example: 🥉 25
```

### 2. Drawer Badge (Detailed View)
```
Location: Top of drawer menu (after header)
Shows: 
- Badge name and icon
- Current points
- Progress bar
- Points to next badge
- How to earn points guide
```

## Implementation Details

### Storage
- Points stored in: `SharedPreferences` with key `user_points`
- Read quotes tracked in: `read_quotes` key
- Read articles tracked in: `read_articles` key
- Persistent across app sessions

### Point Awarding Logic
```
When user reads a quote:
  ├─ Check if quote was previously read
  ├─ If new → Award 5 points + Mark as read
  └─ If already read → No points awarded

When user reads an article:
  ├─ Check if article was previously read
  ├─ If new → Award 20 points + Mark as read
  └─ If already read → No points awarded

When user asks a question:
  └─ Award 10 points (every time)

When user shares a quote:
  └─ Award 30 points (every time - Distribution of knowledge!)
```

### Files Involved
- `badge_service.dart` - Core logic
- `badge_widget.dart` - UI components
- `main.dart` - Integration in home & quotes/articles
- `ask_ai_page.dart` - Integration in Q&A
- `notification_service.dart` - Read tracking helpers

## Maintenance Notes

### To Modify Point Values
Edit `badge_service.dart`:
```dart
static const int POINTS_READ_QUOTE = 5;
static const int POINTS_READ_ARTICLE = 20;
static const int POINTS_ASK_QUESTION = 10;
static const int POINTS_SHARE_QUOTE = 30;
```

### To Add New Badge Tier
Edit badge thresholds in `badge_service.dart`:
```dart
static const int BRONZE_THRESHOLD = 0;
static const int SILVER_THRESHOLD = 100;
static const int GOLD_THRESHOLD = 300;
static const int PLATINUM_THRESHOLD = 600;
static const int DIAMOND_THRESHOLD = 1000;
// Add new: RUBY_THRESHOLD = 1500;
```

### To Change Badge Icons
Edit `getBadgeInfo()` method in `badge_service.dart`:
```dart
icon: '🥉', // Change to desired emoji
```

## Testing Commands

```bash
# Reset points to zero (for testing)
# Add this method to badge_service.dart:
static Future<void> resetPoints() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('user_points', 0);
}

# Add points manually (for testing)
static Future<void> addTestPoints(int points) async {
  await addPoints(points);
}
```

## Performance Notes
- Badge calculations are lightweight (no network calls)
- Points load from local storage (fast)
- UI updates are reactive and smooth
- No impact on app startup time

---

**Version**: 1.0  
**Last Updated**: January 2026  
**Status**: ✅ Production Ready
