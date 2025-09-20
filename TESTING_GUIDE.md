# UACC - Universal AI Call Companion

## 🚀 Latest Updates (Real Data Integration)

The app has been completely upgraded to use **real data** from your device and Google services:

### ✅ What's New:
1. **Real Call Logs**: Now fetches actual call history from your device
2. **Real Notifications**: Displays actual notifications from your system
3. **Google Tasks Integration**: Syncs with your Google Tasks
4. **Google Calendar Integration**: Connects to your Google Calendar
5. **Live Call Monitoring**: Automatically detects and shows live activities during phone calls
6. **Enhanced Permissions**: Proper system-level permissions for full functionality

---

## 🎯 Key Features

### 📱 Call Management
- **Real Call Logs**: View your actual call history with contact names and photos
- **Call Statistics**: Daily, weekly, and monthly call analytics
- **Live Call Activities**: OxygenOS-style dynamic island during calls
- **Contact Integration**: Names and photos from your contacts

### 🔔 Smart Notifications
- **Real Notification Feed**: View actual system notifications
- **AI Categorization**: Automatic grouping by importance and type
- **Priority Filtering**: Focus on what matters most
- **Read/Unread Status**: Track notification states

### ✅ Task Management
- **Google Tasks Sync**: Real-time synchronization with Google Tasks
- **Task Statistics**: Pending, completed, and overdue task counts
- **Due Date Tracking**: Visual indicators for urgent tasks
- **Offline Support**: Local storage with cloud sync

### 📅 Calendar Integration
- **Google Calendar**: Full integration with your Google Calendar
- **Event Display**: Upcoming events and appointments
- **Real-time Updates**: Automatic synchronization

---

## 🛠 Setup Instructions

### Prerequisites
1. Android device (API level 21+)
2. Google account for Tasks/Calendar integration
3. Required permissions (automatically requested)

### Installation
1. Build the APK:
   ```bash
   flutter build apk --release
   ```

2. Install on device:
   ```bash
   flutter install
   ```

### First-Time Setup
1. **Grant Permissions**: The app will request necessary permissions
   - Phone access (for call logs)
   - Contacts (for caller names)
   - Notifications (for system notifications)
   - System overlay (for live activities)

2. **Sign in to Google**: For Tasks and Calendar integration
   - Tap the profile tab
   - Sign in with your Google account
   - Allow access to Tasks and Calendar

3. **Enable Live Activities**: 
   - Go to device Settings > Apps > UACC > Display over other apps
   - Enable the permission for call overlays

---

## 🧪 Testing Features

### Test Live Call Activities
1. Open the app
2. Go to Dashboard tab
3. Tap the floating "Quick Add" button
4. Tap "Test Call" to simulate an incoming call
5. Watch for the live activity overlay (like OxygenOS dynamic island)

### Test Real Data
1. **Call Logs**: Make a few calls, then check the Calls tab
2. **Notifications**: Check the Notifications tab for real system notifications
3. **Tasks**: Sign in to Google and check the Tasks tab for your actual tasks
4. **Calendar**: View the Calendar widget for real events

---

## 📋 Permissions Explained

### Required Permissions
- **READ_PHONE_STATE**: Monitor call state changes
- **READ_CALL_LOG**: Access call history
- **READ_CONTACTS**: Get caller names and photos
- **SYSTEM_ALERT_WINDOW**: Show call overlays
- **POST_NOTIFICATIONS**: Display app notifications
- **READ_CALENDAR/WRITE_CALENDAR**: Google Calendar integration
- **INTERNET**: Google services and data sync

### Optional Permissions
- **RECORD_AUDIO**: Future call recording features
- **WRITE_EXTERNAL_STORAGE**: Export data features

---

## 🔧 Troubleshooting

### Live Activities Not Showing
1. Check if "Display over other apps" permission is granted
2. Ensure the app is not in battery optimization
3. Try the "Test Call" feature first

### Google Integration Issues
1. Ensure you're signed in with a valid Google account
2. Check internet connectivity
3. Verify Google Tasks/Calendar APIs are enabled

### Call Logs Not Loading
1. Grant phone and contacts permissions
2. Make sure the app has access to call logs
3. Try refreshing by pulling down on the calls list

### Notifications Not Showing
1. Enable notification access in Settings
2. Grant notification listener permission
3. Check if the app can access system notifications

---

## 🏗 Architecture

### Flutter Services
- `CallLogService`: Real Android call log integration
- `NotificationService`: System notification access
- `TaskService`: Google Tasks API integration  
- `CalendarService`: Google Calendar API integration
- `CallMonitoringService`: Live call state monitoring
- `LiveActivityService`: OxygenOS-style overlays

### Android Native Components
- `CallLogManager.kt`: Native call log access
- `NotificationManager.kt`: System notification reader
- `TaskManager.kt`: Local task storage
- `CallMonitoringManager.kt`: Phone state listener
- `LiveActivityChannel.kt`: Platform channel communication

---

## 🔮 Future Enhancements

### Planned Features
- **AI Call Summaries**: Automatic call transcription and summarization
- **Smart Automation**: Rule-based actions based on calls/notifications
- **Call Recording**: With proper permissions and legal compliance
- **Voice Assistant**: AI-powered call companion
- **Cross-Device Sync**: Multi-device synchronization

### Performance Improvements
- Background optimization
- Battery usage minimization
- Faster data loading
- Enhanced caching

---

## 🐛 Known Issues

1. **First Launch**: Some permissions may need manual enabling in system settings
2. **Battery Optimization**: App may need whitelisting for background operation
3. **Android 12+**: Additional notification permissions may be required
4. **Google Auth**: First-time setup requires stable internet connection

---

## 📱 Device Compatibility

### Tested Devices
- Android 8.0+ (API 26+)
- OnePlus devices (OxygenOS integration tested)
- Samsung Galaxy series
- Google Pixel devices

### Minimum Requirements
- Android 5.0+ (API 21+)
- 2GB RAM
- 100MB storage space
- Internet connection for Google services

---

## 🤝 Contributing

Feel free to contribute to this project by:
1. Reporting bugs
2. Suggesting new features
3. Submitting pull requests
4. Improving documentation

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Create an issue in the repository
3. Test with the built-in "Test Call" feature first

---

**Enjoy your enhanced call and notification experience! 🎉**