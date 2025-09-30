# Firebase Exports for Web Dashboard

This folder contains services to export all Cairo app data to Firebase collections, making it accessible for your friend's web dashboard.

## 📊 Exported Collections

### 1. **Notifications** (`notifications`)
- App notifications with AI analysis
- Categorized by app type (Social, Financial, etc.)
- Includes sentiment analysis and suggested actions
- Real-time export when new notifications arrive

### 2. **Call Transcripts** (`call_transcripts`)
- Call logs with duration and contact info
- AI-generated summaries and key points
- Transcript placeholders (upgrade for real transcription)
- Categorized by call type (Business, Personal, etc.)

### 3. **Tasks** (`tasks`)
- Google Tasks integration
- Priority levels and due dates
- Auto-categorization (Work, Personal, Health, etc.)
- Completion status and timestamps

### 4. **Events** (`events`)
- Calendar events and appointments
- Location and attendee information
- Categorized events with priorities
- Recurring event support

### 5. **Metadata** (`user_metadata`)
- Dashboard statistics and sync info
- Export timestamps and counts
- App version and configuration

## 🚀 Quick Setup

### In your main app (main.dart):
```dart
import 'firebaseExports/firebase_exports.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize export system
  await FirebaseExportCoordinator.initialize();
  
  // Schedule automatic exports
  FirebaseExportCoordinator.scheduleAutoExport();
  
  runApp(MyApp());
}
```

### Manual Export (for testing):
```dart
// Export all data once
await FirebaseExportCoordinator.exportAllData();

// Export only recent data (last 7 days)
await FirebaseExportCoordinator.exportRecentData();

// Get export statistics for dashboard
final stats = await FirebaseExportCoordinator.getExportStatistics();
print('Total notifications: ${stats['notifications']['total_notifications']}');
```

### Individual Service Usage:
```dart
// Export specific data types
await NotificationExportService.exportAllNotifications();
await CallTranscriptExportService.exportAllCallTranscripts();
await TaskExportService.exportAllTasks();
await EventExportService.exportAllEvents();
```

## 📱 Real-Time Exports

The system automatically exports new data as it arrives:
- New notifications → Instant export to Firebase
- New calls → Export after call ends
- Task changes → Real-time sync with Google Tasks
- Calendar updates → Automatic event sync

## 🌐 Web Dashboard Access

Your friend can access the data using Firebase Web SDK:

```javascript
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Get all notifications
const notificationsSnapshot = await getDocs(collection(db, 'notifications'));
const notifications = notificationsSnapshot.docs.map(doc => ({
  id: doc.id,
  ...doc.data()
}));

// Get dashboard stats
const statsDoc = await getDoc(doc(db, 'user_metadata', 'dashboard_stats'));
const dashboardStats = statsDoc.data();
```

## 📊 Data Structure Examples

### Notification Document:
```json
{
  "id": "notification_123",
  "app_name": "WhatsApp",
  "title": "New Message",
  "body": "Hello from John",
  "category": "Social",
  "timestamp": "2024-01-15T10:30:00Z",
  "priority": "medium",
  "ai_summary": "Message received from contact",
  "sentiment": "Positive",
  "requires_action": false
}
```

### Task Document:
```json
{
  "id": "task_456",
  "title": "Complete project report",
  "description": "Finish the Q4 analysis",
  "due_date": "2024-01-20T17:00:00Z",
  "is_completed": false,
  "priority": "high",
  "category": "Work",
  "tags": ["urgent", "report"]
}
```

### Call Transcript Document:
```json
{
  "contact_name": "John Doe",
  "phone_number": "+1234567890",
  "timestamp": "2024-01-15T09:15:00Z",
  "duration_seconds": 180,
  "is_incoming": true,
  "summary": "Discussed project timeline",
  "sentiment": "Positive",
  "category": "Business"
}
```

## 🔧 Configuration

### Export Schedule:
- **Full Export**: Every 24 hours
- **Recent Data**: Every 1 hour
- **Real-time**: Instant for notifications and critical data

### Data Retention:
- Default: 30 days of exported data
- Configurable via `cleanupOldData()` method
- Web dashboard can access all retained data

## 🔐 Security & Permissions

Ensure your Firebase Security Rules allow read access for the web dashboard:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to exported collections
    match /notifications/{document} {
      allow read: if request.auth != null;
    }
    match /tasks/{document} {
      allow read: if request.auth != null;
    }
    match /call_transcripts/{document} {
      allow read: if request.auth != null;
    }
    match /events/{document} {
      allow read: if request.auth != null;
    }
    match /user_metadata/{document} {
      allow read: if request.auth != null;
    }
  }
}
```

## 🎯 Dashboard Features Your Friend Can Build

With this exported data, the web dashboard can show:

1. **📊 Analytics Dashboard**
   - Notification trends and categories
   - Call duration statistics
   - Task completion rates
   - Calendar event density

2. **📱 Notification Insights**
   - Most active apps
   - Sentiment analysis over time
   - Action item recommendations
   - Spam/important classification

3. **📞 Communication Analytics**
   - Call patterns and frequency
   - Top contacts and duration
   - Business vs personal call ratio
   - Peak communication times

4. **✅ Productivity Metrics**
   - Task completion trends
   - Priority distribution
   - Overdue task alerts
   - Category-wise productivity

5. **📅 Schedule Overview**
   - Upcoming events and conflicts
   - Meeting density heatmaps
   - Location-based event clustering
   - Recurring event patterns

## 🚨 Troubleshooting

### Export Issues:
```dart
// Check export status
if (FirebaseExportCoordinator.isExporting) {
  print('Export in progress...');
}

// Get detailed statistics
final stats = await FirebaseExportCoordinator.getExportStatistics();
if (stats.containsKey('error')) {
  print('Export error: ${stats['error']}');
}
```

### Manual Data Cleanup:
```dart
// Clean up data older than 15 days
await FirebaseExportCoordinator.cleanupOldData(daysToKeep: 15);
```

### Reset Export System:
```dart
// Re-initialize if needed
await FirebaseExportCoordinator.initialize();
```

## 📞 Support

For any issues with the export system or web dashboard integration, the exported data follows standard Firebase document structures that are easy to query and analyze.

All timestamps are in UTC format and data includes proper indexing for efficient dashboard queries.