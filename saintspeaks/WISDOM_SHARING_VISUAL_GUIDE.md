# Wisdom Sharing Dialog - Visual Design

## Dialog Preview (Text-Based Mockup)

```
┌─────────────────────────────────────────────┐
│                                             │
│              ╭─────────╮                    │
│              │  🔗     │  ← Gradient Circle │
│              │         │     (Amber→Orange) │
│              ╰─────────╯                    │
│                                             │
│          Share the Wisdom                   │
│                                             │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │         "                            │  │
│  │                                      │  │
│  │  Knowledge is the highest form      │  │
│  │  of charity.                        │  │
│  │                                      │  │
│  │     — Swami Vivekananda             │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  When we share wisdom, we don't lose       │
│  it—we multiply its power.                 │
│                                             │
│  Through this app, every insight you       │
│  share can guide someone, uplift a mind,   │
│  and spark positive change.                │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ ✨ Practice Gyaana Dāna—give what   │  │
│  │    enlightens!                       │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  Share the quotes from this app with       │
│  your friends or set your WhatsApp         │
│  status to spread wisdom daily.            │
│                                             │
├─────────────────────────────────────────────┤
│                                             │
│     [Maybe Later]        [Got it! 🚀]     │
│                                             │
└─────────────────────────────────────────────┘
```

## Color Scheme

### Icon Container
- Gradient: Amber 400 → Orange 600
- Shape: Circle (80x80)
- Icon: Share icon, white, size 40

### Vivekananda Quote Box
- Background: Orange 50
- Border: Orange 200
- Text: Brown 800, italic
- Icon: Format quote, Deep Orange 400

### Gyaana Dāna Emphasis Box
- Background: Gradient (Amber 100 → Orange 100)
- Icon: Auto awesome, Deep Orange 700
- Text: Deep Orange 900, bold

### Buttons
- "Maybe Later": Grey 600, text button
- "Got it!": Deep Orange background, white text, elevated

## Responsive Features

✅ **Light Mode**: Uses light background colors  
✅ **Dark Mode**: Automatically adjusts text and background  
✅ **Small Screens**: SingleChildScrollView for scrolling  
✅ **Large Screens**: Centered and properly sized  
✅ **RTL Support**: Text alignment adjusts automatically  

## User Interaction Flow

```
User opens app after 7 days
         ↓
2 second delay
         ↓
Dialog fades in with animation
         ↓
User reads the message
         ↓
┌─────────────┬──────────────┐
│             │              │
│ Maybe Later │   Got it!    │
│             │              │
└─────────────┴──────────────┘
         ↓                ↓
    Dismissed        Acknowledged
         ↓                ↓
Shows again in 7 days   Shows again in 7 days
```

## Timing Behavior

```
Timeline:
─────────────────────────────────────────────────►
Day 0                 Day 7             Day 14
  │                     │                  │
Install              First             Second
  │                  Prompt             Prompt
  │                     │                  │
  └─────────────────────┴──────────────────┘
        7 days              7 days
```

## Multi-Language Support

### English 🇺🇸
"Share the Wisdom"

### Hindi 🇮🇳
"ज्ञान साझा करें"

### German 🇩🇪
"Teilen Sie die Weisheit"

### Kannada 🇮🇳
"ಜ್ಞಾನವನ್ನು ಹಂಚಿಕೊಳ್ಳಿ"

## Accessibility Features

✅ Screen reader compatible  
✅ High contrast text  
✅ Large touch targets (buttons)  
✅ Clear visual hierarchy  
✅ Non-modal (can be dismissed)  
✅ Keyboard navigation support  

## Integration with App Features

### Existing Share Functionality
```
Quote Page
    ↓
[Share Button]
    ↓
Beautiful Image Generated
    ↓
Share via WhatsApp/Social Media
    ↓
+30 Badge Points! 🎉
```

The wisdom sharing dialog reminds users about this feature!

## Dialog Animation

```
Entrance:
  - Fade in (0 → 100% opacity)
  - Scale slightly (0.95 → 1.0)
  - Duration: 300ms
  - Curve: easeOut

Exit:
  - Fade out (100% → 0% opacity)
  - Scale slightly (1.0 → 0.95)
  - Duration: 200ms
  - Curve: easeIn
```

## Best Practices Followed

✅ Non-intrusive (2-second delay)  
✅ Clear value proposition  
✅ Emotional connection (Vivekananda quote)  
✅ Simple call-to-action  
✅ Easy to dismiss  
✅ Respects user choice  
✅ Culturally sensitive  
✅ Spiritually aligned  

## Technical Implementation

```dart
WisdomSharingService.showWisdomSharingDialog(context)
    ↓
Check context.mounted
    ↓
Build AlertDialog with:
  - Rounded corners (24px)
  - Title (Icon + Text)
  - Scrollable content
  - Two action buttons
    ↓
Show with showDialog()
    ↓
Wait for user interaction
    ↓
Pop dialog and mark as shown
```

## Performance Notes

- Lazy-loaded (only when needed)
- Minimal memory footprint
- No network calls required
- Instant response to user actions
- Efficient SharedPreferences usage

---

**Visual Design Status**: ✅ Complete
**Accessibility**: ✅ Compliant
**Localization**: ✅ All languages
**Theme Support**: ✅ Light & Dark
**Platform**: ✅ iOS & Android
