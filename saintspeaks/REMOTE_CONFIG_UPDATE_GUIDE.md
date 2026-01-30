# Remote Config Update Guide

## 📝 What You Need to Do

Update your remote configuration file to include the app version field.

## 🔗 Config File Location

`https://raw.githubusercontent.com/AntarikshG/configuration/main/saintsapp.json`

## ✏️ Required Change

Add the `latest_app_version` field to your JSON configuration:

```json
{
  "gradio_server_running": true,
  "gradio_server_link": "https://your-gradio-server.com",
  "latest_app_version": "2.2.0",
  "ekadashi_data": {
    "2025-01-13": "Putrada Ekadashi",
    "2025-01-28": "Shattila Ekadashi",
    "2025-02-11": "Jaya Ekadashi",
    ...existing ekadashi dates...
  }
}
```

## 🎯 Current Version

Your app's current version (from pubspec.yaml): **2.2.0**

Set the config to: `"latest_app_version": "2.2.0"`

## 🚀 When You Release New Version

### Example: Releasing version 2.3.0

1. **Update pubspec.yaml:**
   ```yaml
   version: 2.3.0+10
   ```

2. **Build and publish** to app stores

3. **Update remote config:**
   ```json
   "latest_app_version": "2.3.0"
   ```

4. **That's it!** All users on version 2.2.0 or lower will see update notifications weekly.

## 📊 Version Comparison Examples

The system uses semantic versioning:

- `2.3.0` > `2.2.0` ✅ (Shows notification)
- `2.2.1` > `2.2.0` ✅ (Shows notification)
- `2.2.0` = `2.2.0` ❌ (No notification)
- `2.1.9` < `2.2.0` ❌ (No notification - user already has newer version)

## 🧪 Testing the Feature

### To test immediately:

1. **Set a higher version in config:**
   ```json
   "latest_app_version": "2.3.0"
   ```

2. **Run your app** (current version is 2.2.0)

3. **You should see:** A notification saying "Version 2.3.0 is now available..."

4. **Tap the notification** → Opens app store

### To test again (bypass 7-day wait):

Add this temporary code in your app and run:
```dart
await AppVersionService.clearUpdateCheckHistory();
```

Then restart the app.

## 📱 What Users Will See

**Notification Title:** 🎉 New Version Available!

**Notification Message:** Version X.X.X is now available with new saints and features. Tap to update now!

**When Tapped:**
- Android users → Google Play Store
- iOS users → Apple App Store

## ⏰ Notification Frequency

- First notification: Immediately when update is detected
- Subsequent notifications: Every 7 days
- Stops when: User updates to the latest version

## ✅ Checklist

- [ ] Add `latest_app_version` field to remote config
- [ ] Set it to current version (`"2.2.0"`)
- [ ] Commit and push the config file
- [ ] Verify the config is accessible at the URL
- [ ] Test by setting a higher version number
- [ ] Confirm notification appears
- [ ] Test tapping notification opens app store

## 🎉 Benefits

✨ Encourages users to update  
✨ Promotes new features and saints  
✨ Increases user engagement  
✨ Non-intrusive (weekly reminders only)  
✨ Easy to manage (single config field)  

---

**Need Help?** Check the main implementation document: `APP_VERSION_UPDATE_IMPLEMENTATION.md`
