# Badge Points Refresh Fix

## Problem
The points displayed in the BadgeWidget on the main page AppBar were not updating when users earned points by reading quotes or articles. The correct count was shown in the drawer menu, but the AppBar badge remained stale until the app was restarted.

## Root Cause
The BadgeWidget in the AppBar was created once and never refreshed. When users navigated to saint pages and earned points, they would return to the HomePage, but the BadgeWidget state was not updated.

## Solution

### 1. Made BadgeWidget State Public
**File: `lib/badge_widget.dart`**
- Renamed `_BadgeWidgetState` to `BadgeWidgetState` (removed underscore prefix)
- This allows external code to reference the state class for GlobalKey usage
- The `refresh()` method was already public and can be called to reload points

### 2. Added GlobalKey and Refresh Method to HomePage
**File: `lib/main.dart`**
- Added `GlobalKey<BadgeWidgetState> _badgeKey` to `_HomePageState`
- Added `_refreshBadge()` method that calls `_badgeKey.currentState?.refresh()`
- Assigned the key to the BadgeWidget in the AppBar

### 3. Refresh Badge on Navigation Return
**File: `lib/main.dart`**
- Added `.then((_) => _refreshBadge())` callbacks to:
  - Navigation to SaintPage (line ~1716)
  - Navigation to QuoteOfTheDayPage (line ~1540)

## Changes Made

### badge_widget.dart
```dart
// Changed from:
_BadgeWidgetState createState() => _BadgeWidgetState();
class _BadgeWidgetState extends State<BadgeWidget> {

// To:
BadgeWidgetState createState() => BadgeWidgetState();
class BadgeWidgetState extends State<BadgeWidget> {
```

### main.dart
```dart
// Added to _HomePageState:
final GlobalKey<BadgeWidgetState> _badgeKey = GlobalKey<BadgeWidgetState>();

void _refreshBadge() {
  _badgeKey.currentState?.refresh();
}

// Updated AppBar:
child: BadgeWidget(key: _badgeKey, showDetails: false),

// Updated navigation calls:
Navigator.push(...).then((_) => _refreshBadge())
```

## How It Works

1. When the HomePage is created, a GlobalKey is assigned to the BadgeWidget in the AppBar
2. When users navigate to saint pages or quote pages, the navigation returns a Future
3. When the navigation completes (user returns to HomePage), the `.then()` callback executes
4. The callback calls `_refreshBadge()`, which invokes the BadgeWidget's `refresh()` method
5. The refresh method reloads points from SharedPreferences and updates the UI

## Testing

To verify the fix works:
1. Launch the app and note the current points in the AppBar
2. Navigate to any saint page
3. Read a new quote (swipe through quotes)
4. Press back to return to the main page
5. The points in the AppBar should now be updated (+5 points per quote)

## Benefits

- Points are now always up-to-date on the main page
- No need to reopen the drawer to see updated points
- Consistent user experience
- Minimal performance impact (only refreshes when returning from navigation)
