# German Language Support - Testing Checklist

## Pre-Testing
- [ ] Run `flutter pub get` to ensure all dependencies are updated
- [ ] Run `flutter clean` and `flutter pub get` if any issues occur
- [ ] Build the app: `flutter build apk` (Android) or `flutter build ios` (iOS)

## Testing Checklist

### 1. Language Selection
- [ ] Open the app
- [ ] Tap on the hamburger menu icon
- [ ] Tap on "Language" / "Sprache" / "भाषा"
- [ ] Verify three language options appear:
  - [ ] English
  - [ ] Hindi (हिंदी)
  - [ ] German (Deutsch)
- [ ] Select "Deutsch" (German)
- [ ] Verify the dialog closes and UI updates to German

### 2. Main Screen (Home)
- [ ] Verify app title shows "Motivierende Heilige" or similar German text
- [ ] Verify "Inspirierende Heilige Indiens" appears as subtitle
- [ ] Verify menu button shows German tooltip
- [ ] Verify all saint names are displayed (in English as per requirement)

### 3. Saint Detail Screen
After selecting a saint:
- [ ] Verify tabs show in German:
  - "Zitate" (Quotes)
  - "Artikel" (Articles)
  - "Fragen - KI-gestützt" (Ask - AI Powered)
  - "Verlauf" (History)
- [ ] Verify quote bookmarking works
- [ ] Verify quote sharing shows German messages

### 4. Menu Items
- [ ] "Menü" (Menu)
- [ ] "Sprache" (Language)
- [ ] "Design auswählen" (Select Theme)
- [ ] "Spirituelles Tagebuch" (Spiritual Diary)
- [ ] "Spendieren Sie mir einen Kaffee" (Buy Me A Coffee)
- [ ] "Zitat des Tages" (Quote of the Day)
- [ ] "Meine Bücherbibliothek" (My Books Library)
- [ ] "App bewerten & teilen" (Rate & Share App)
- [ ] "Tägliche Benachrichtigungen festlegen" (Set Daily Notifications)
- [ ] "Kontakt" (Contact)
- [ ] "So verwenden Sie die App" (How to use the App)

### 5. Theme Selection
- [ ] Open theme dialog
- [ ] Verify options show in German:
  - "System"
  - "Hell" (Light)
  - "Dunkel" (Dark)

### 6. Ask AI Feature
- [ ] Navigate to Ask tab
- [ ] Verify placeholder text: "z.B., Wie kann ich inneren Frieden finden?"
- [ ] Type a question in German or English
- [ ] Verify loading message: "Weisheit von Heiligen erhalten..."
- [ ] Verify error messages show in German if server is down

### 7. History Feature
- [ ] Navigate to History tab
- [ ] If empty, verify: "Keine vorherigen Fragen." (No previous questions)
- [ ] If has history, verify delete confirmation in German:
  - "Frage löschen?" (Delete Question?)
  - "Sind Sie sicher..." (Are you sure...)
  - "Abbrechen" (Cancel)
  - "Löschen" (Delete)

### 8. Bookmarked Quotes
- [ ] Open bookmarked quotes from menu
- [ ] Verify title: "Gespeicherte Zitate" (Bookmarked Quotes)

### 9. Quote of the Day
- [ ] Open Quote of the Day
- [ ] Verify title: "Zitat des Tages"
- [ ] Verify share functionality works

### 10. Share & Rate Dialog
- [ ] Navigate to Rate & Share from menu
- [ ] Verify dialog content in German:
  - "Spiritualität verbreiten" (Spread Spirituality)
  - "Bewerten Sie uns mit 5 Sternen" (Rate us 5 stars)
  - "Mit Freunden & Familie teilen" (Share with friends & family)
  - Buttons: "Später" (Later), "Teilen" (Share), "5⭐ bewerten" (Rate 5⭐)

### 11. Contact Page
- [ ] Open Contact from menu
- [ ] Verify German translated content appears
- [ ] Verify email link works

### 12. Persistence Testing
- [ ] Change language to German
- [ ] Close the app completely
- [ ] Reopen the app
- [ ] Verify language is still German

### 13. Edge Cases
- [ ] Test with device set to German locale
- [ ] Test with device set to other locales
- [ ] Verify no crashes or missing translations
- [ ] Check for any untranslated strings (should all be in German)

### 14. Cross-Language Testing
- [ ] Switch from English to German and back
- [ ] Switch from Hindi to German and back
- [ ] Verify smooth transitions without crashes
- [ ] Verify UI updates immediately after language change

## Known Limitations
✅ Saints names, quotes, and articles remain in English (as per requirement)
✅ German users will see English content for saints data
✅ UI and navigation are fully translated to German

## If Issues Found
1. Check console for errors
2. Run `flutter clean && flutter pub get`
3. Verify all files are saved
4. Rebuild the app
5. Check that device supports the German locale

---

**Date Created:** January 23, 2026
**Status:** Ready for testing
