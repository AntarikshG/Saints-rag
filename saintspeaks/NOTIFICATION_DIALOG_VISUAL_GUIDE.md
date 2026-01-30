# Notification Permission Dialog - Visual Flow

## First Time User Experience

### Step 1: App Launch
```
┌─────────────────────────────┐
│                             │
│   App Initializes...        │
│   (No permission prompt)    │
│                             │
└─────────────────────────────┘
```

### Step 2: Name Dialog (If First Time)
```
┌─────────────────────────────┐
│         👤                  │
│   Enter your name           │
│                             │
│  Help the spiritual saints  │
│  personalize their wisdom   │
│  just for you               │
│                             │
│  [Name Input Field]         │
│                             │
│  [Skip for now] [Save]      │
└─────────────────────────────┘
```

### Step 3: Notification Permission Dialog (NEW!)
```
┌─────────────────────────────────────┐
│              🔔                     │
│     (Orange gradient icon)          │
│                                     │
│   Daily Spiritual Wisdom            │
│                                     │
│  Receive inspiring quotes from      │
│  saints twice daily - once in the   │
│  morning to start your day with     │
│  wisdom, and once in the evening    │
│  for reflection.                    │
│                                     │
│  🌅 Morning wisdom to guide         │
│     your day                        │
│  🌙 Evening reflection for          │
│     inner peace                     │
│                                     │
│  This feature enriches your         │
│  spiritual journey and is highly    │
│  recommended!                       │
│                                     │
│  [Maybe Later] [Enable Notifications]│
└─────────────────────────────────────┘
```

### Step 4A: User Clicks "Enable Notifications"
```
┌─────────────────────────────┐
│   System Permission Dialog  │
│                             │
│  Allow "Talk with Saints"   │
│  to send you notifications? │
│                             │
│  [Don't Allow]  [Allow]     │
└─────────────────────────────┘
```
✅ Notifications scheduled!
✅ User will receive morning (8 AM) and evening (8 PM) quotes

### Step 4B: User Clicks "Maybe Later"
```
No system dialog shown
User can enable later from:
Menu → Set Daily Notifications
```

## Subsequent App Launches
```
┌─────────────────────────────┐
│                             │
│   App Launches              │
│   ✓ No dialogs shown        │
│   ✓ Notifications continue  │
│     (if previously enabled) │
│                             │
└─────────────────────────────┘
```

## Key Features

### Dialog Design
- **Icon**: Orange gradient circle with notification bell icon
- **Title**: "Daily Spiritual Wisdom" (localized)
- **Message**: Clear explanation with emojis for visual appeal
- **Buttons**: 
  - "Maybe Later" (gray, left) - Non-destructive
  - "Enable Notifications" (orange, right) - Primary action
- **Non-dismissible**: User must choose an option

### Timing
- Shows AFTER name dialog (if first time)
- 500ms delay between dialogs for smooth UX
- Only shows once (tracked in SharedPreferences)

### Localization
All text is localized in:
- 🇬🇧 English
- 🇮🇳 Hindi (हिंदी)
- 🇩🇪 German (Deutsch)
- 🇮🇳 Kannada (ಕನ್ನಡ)

## Testing Instructions

### To Test First-Time Flow:
1. Delete app from device
2. Reinstall app
3. Launch app
4. Should see name dialog first
5. After entering name (or skipping), should see notification dialog
6. Choose option and verify behavior

### To Reset and Test Again:
Clear app data or reinstall app

### To Test Later Enabling:
1. Choose "Maybe Later" initially
2. Go to Menu → Set Daily Notifications
3. Send test notification to enable feature
