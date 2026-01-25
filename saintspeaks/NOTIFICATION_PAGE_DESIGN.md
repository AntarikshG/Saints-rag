# Notification Settings Page - Visual Design

## 🎨 Page Layout Description

```
┌──────────────────────────────────────────────────┐
│  ← [Back]    Set Daily Notifications             │  <- AppBar (Orange gradient)
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                                                  │
│                    🔔                            │  <- Large notification icon
│               (Bell Icon)                        │     in orange circle
│                                                  │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│  ℹ️  Daily Wisdom Notifications                  │  <- White card with
│                                                  │     orange border
│  Enable daily notifications to receive           │
│  inspiring wisdom quotes from saints twice       │
│  every day:                                      │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │  ☀️  8:00 AM  •  Morning Wisdom           │ │  <- Morning slot
│  │     Start your day with inspiration       │ │     (Gray card)
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │  🌙  8:00 PM  •  Evening Guidance         │ │  <- Evening slot
│  │     End your day with reflection          │ │     (Gray card)
│  └────────────────────────────────────────────┘ │
│                                                  │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│  ⚠️  Important: Enable Notifications            │  <- Yellow/amber warning
│                                                  │     card with border
│  Please grant notification permissions in your  │
│  app settings to receive daily wisdom quotes.   │
│  If you don't see notifications, check your     │
│  device's app permissions and notification      │
│  settings.                                       │
│                                                  │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                                                  │
│      📅  Enable Daily Notifications              │  <- Large orange button
│                                                  │     with icon
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                                                  │
│      📤  Send Test Notification                  │  <- Outlined button
│                                                  │     (white with orange
└──────────────────────────────────────────────────┘     border)

┌──────────────────────────────────────────────────┐
│  ✓  Daily notifications scheduled successfully! │  <- Success message
│                                                  │     (green box)
└──────────────────────────────────────────────────┘     Shows after scheduling
```

## 🎨 Color Scheme

### Primary Colors:
- **Deep Orange**: `#FF6D00` - Primary buttons, icons
- **Orange Accent**: `#FFB74D` - Gradients, borders
- **White**: `#FFFFFF` - Cards, backgrounds
- **Amber Warning**: `#FFC107` - Warning/notice card
- **Green Success**: `#4CAF50` - Success messages

### Gradient Backgrounds:
- **AppBar**: Deep Orange 100 → Orange 50 (with opacity)
- **Page Background**: Deep Orange 50 → White
- **Cards**: White → Orange 50

## 📐 Layout Specifications

### Spacing:
- **Page padding**: 20px all sides
- **Card padding**: 20-24px
- **Element spacing**: 16-30px vertical
- **Button height**: 56-60px

### Typography (Google Fonts):
- **Headers**: Playfair Display (Bold, 22-24px)
- **Body**: Noto Sans (Regular/Bold, 14-16px)
- **Time indicators**: Noto Sans (Bold, 16px)

### Icons:
- **Main icon**: 60px bell icon
- **Time icons**: 26px (sun/moon)
- **Warning icon**: 28px
- **Button icons**: 24px

### Borders & Shadows:
- **Cards**: 2px solid borders with 15px blur shadow
- **Buttons**: 15px rounded corners with elevation
- **Icon container**: Circle with 10px border radius

## 🎬 Animations & Interactions

### Button States:
```
Normal State:
┌─────────────────────────────────────┐
│  📅  Enable Daily Notifications     │
└─────────────────────────────────────┘

Loading State:
┌─────────────────────────────────────┐
│  ⏳  Scheduling...                  │  <- Shows spinner
└─────────────────────────────────────┘

After Success:
┌─────────────────────────────────────┐
│  📅  Enable Daily Notifications     │
└─────────────────────────────────────┘
       ↓
┌─────────────────────────────────────┐
│  ✓  Daily notifications scheduled!  │  <- Green success box appears
└─────────────────────────────────────┘
```

### Snackbar (Test Notification):
```
┌─────────────────────────────────────────┐
│  ✓  Test notification sent! Check       │  <- Green snackbar
│     your notification panel.            │     from bottom
└─────────────────────────────────────────┘
```

## 📱 Responsive Design

### Phone (Portrait):
- Single column layout
- Cards full width with margins
- Stacked buttons
- Scrollable content

### Tablet (Landscape):
- Same layout but wider cards
- Centered content with max-width
- More padding for breathing room

## ♿ Accessibility Features

- **High Contrast**: Orange on white, clear text
- **Clear Icons**: Universal symbols (bell, sun, moon, warning)
- **Readable Fonts**: Large, clear typography
- **Touch Targets**: Buttons 48px+ height
- **Screen Reader**: Proper labels and tooltips
- **Visual Hierarchy**: Size, color, and spacing guide the eye

## 🌍 Multi-Language Support

All text elements support localization:
- Page title: "Set Daily Notifications"
- Instructions and descriptions
- Button labels
- Success/error messages
- Time labels (Morning Wisdom, Evening Guidance)

Currently supported:
- 🇬🇧 English
- 🇮🇳 Hindi (हिंदी)
- 🇩🇪 German (Deutsch)
- 🇮🇳 Kannada (ಕನ್ನಡ)

## 📊 Component Breakdown

### 1. Header Icon Component
```dart
Container with:
- Circular shape
- Deep orange background
- 25px padding
- Bell icon (60px)
- Shadow effect
```

### 2. Main Info Card Component
```dart
Container with:
- White background
- Orange border (2px)
- Rounded corners (20px)
- Inner padding (24px)
- Title with info icon
- Description text
- Two time slot cards nested
```

### 3. Time Slot Card Component
```dart
Container with:
- Gray background (#F5F5F5)
- Rounded corners (12px)
- Gray border
- Icon + Time + Label + Description
- Horizontal layout
```

### 4. Permission Notice Component
```dart
Container with:
- Amber background (#FFF9E6)
- Amber border
- Warning icon
- Bold title
- Detailed description
- Horizontal row layout
```

### 5. Action Buttons
```dart
ElevatedButton (Primary):
- Deep orange background
- White text
- Icon + Text
- Rounded corners (15px)
- Elevation shadow
- Loading state support

OutlinedButton (Secondary):
- White background
- Orange border (2px)
- Orange text
- Icon + Text
- Rounded corners (15px)
```

### 6. Status Message Component
```dart
Container (Conditional):
- Green/Red background (based on status)
- Matching border
- Icon (check/error)
- Status text
- Rounded corners (12px)
```

## 🎯 User Journey Flow

```
Menu Item Tap
      ↓
Page Opens (Beautiful gradient appears)
      ↓
User Reads Information
  - Sees 2 daily notifications explained
  - Reads permission notice
      ↓
User Decision:
      ↓
Option A: Test First
  → Taps "Send Test Notification"
  → Sees green snackbar
  → Checks notification panel
  → Returns to page
  → Taps "Enable Daily Notifications"
      ↓
Option B: Enable Directly
  → Taps "Enable Daily Notifications"
  → Sees loading spinner
  → Sees success message
  → Done!
      ↓
User Receives 2 Quotes Daily at 8 AM & 8 PM
```

## 💡 Design Philosophy

1. **Clarity First**: User knows exactly what they're getting
2. **Trust Building**: Clear permission notice builds confidence
3. **Progressive Disclosure**: Information revealed in logical order
4. **Visual Hierarchy**: Most important info stands out
5. **Feedback Loop**: Every action has clear visual response
6. **Beautiful & Spiritual**: Design reflects app's purpose
7. **Accessible**: Works for all users regardless of ability

This design transforms a simple test notification button into a comprehensive, beautiful, and informative settings page that users will love! 🙏✨
