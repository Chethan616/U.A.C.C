package com.example.uacc

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import org.json.JSONObject

/**
 * 🚀 Background Notification Processing Service
 * 
 * This service runs in the background to handle notification processing
 * without requiring the main app to be open. It communicates with Flutter's
 * background processor to perform AI analysis and create tasks automatically.
 */
class BackgroundNotificationProcessingService : Service() {

    companion object {
        private const val TAG = "BackgroundNotificationProcessor"
        private const val NOTIFICATION_CHANNEL_ID = "background_processing_channel"
        private const val FOREGROUND_NOTIFICATION_ID = 1001
        private const val WAKELOCK_TAG = "UACCApp:BackgroundProcessing"
        
        // Method channel for communicating with Flutter background processor
        private const val BACKGROUND_METHOD_CHANNEL = "com.example.uacc/background_processor"
    }

    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var serviceScope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "🚀 Background Notification Processing Service created")
        
        createNotificationChannel()
        acquireWakeLock()
        initializeFlutterEngine()
        startForeground(FOREGROUND_NOTIFICATION_ID, createForegroundNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "📱 Background service command received: ${intent?.action}")

        when (intent?.action) {
            "PROCESS_NOTIFICATION" -> {
                val notificationData = intent.getStringExtra("notification_data")
                if (notificationData != null) {
                    processNotificationInBackground(notificationData)
                } else {
                    Log.w(TAG, "⚠️ No notification data provided")
                }
            }
            "STOP_SERVICE" -> {
                Log.d(TAG, "🛑 Stopping background processing service")
                stopSelf()
            }
        }

        // Return START_STICKY to restart the service if killed by the system
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null // This is a background service, no binding needed
    }

    /**
     * Initialize Flutter engine for background processing
     */
    private fun initializeFlutterEngine() {
        try {
            Log.d(TAG, "🔧 Initializing Flutter engine for background processing...")
            
            flutterEngine = FlutterEngine(this).apply {
                dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )
            }

            // Set up method channel for communication with Flutter
            methodChannel = MethodChannel(
                flutterEngine!!.dartExecutor.binaryMessenger,
                BACKGROUND_METHOD_CHANNEL
            )

            Log.d(TAG, "✅ Flutter engine initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to initialize Flutter engine", e)
        }
    }

    /**
     * Process notification in background using Flutter background processor
     */
    private fun processNotificationInBackground(notificationDataJson: String) {
        serviceScope.launch {
            try {
                Log.d(TAG, "🔄 Processing notification in background...")
                
                val notificationData = JSONObject(notificationDataJson)
                val appName = notificationData.getString("appName")
                
                // Prepare notification data for Flutter processing
                val flutterNotificationData = mapOf(
                    "id" to notificationData.getString("id"),
                    "packageName" to notificationData.getString("packageName"),
                    "appName" to appName,
                    "title" to notificationData.getString("title"),
                    "content" to notificationData.getString("text"),
                    "bigText" to notificationData.optString("bigText", ""),
                    "subText" to notificationData.optString("subText", null),
                    "timestamp" to notificationData.getLong("timestamp"),
                    "priority" to when (notificationData.getInt("priority")) {
                        2 -> "HIGH"
                        1 -> "HIGH"
                        0 -> "NORMAL"
                        -1 -> "LOW"
                        -2 -> "LOW"
                        else -> "NORMAL"
                    }
                )
                
                // Update foreground notification to show current processing
                updateForegroundNotification("Processing: $appName")
                
                // Send to Flutter background processor via method channel
                withContext(Dispatchers.Main) {
                    methodChannel?.invokeMethod("processNotificationBackground", flutterNotificationData, object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            Log.d(TAG, "✅ Background processing completed for: $appName")
                            
                            // Check if tasks were created
                            val processingResult = result as? Map<*, *>
                            val tasksCreated = processingResult?.get("tasksCreated") as? Boolean ?: false
                            val eventsCreated = processingResult?.get("eventsCreated") as? Boolean ?: false
                            
                            if (tasksCreated || eventsCreated) {
                                Log.d(TAG, "🎉 Background processing created tasks/events for: $appName")
                                showSuccessNotification(appName, tasksCreated, eventsCreated)
                            }
                            
                            // Reset foreground notification
                            updateForegroundNotification("Background Processing Active")
                        }
                        
                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                            Log.e(TAG, "❌ Background processing failed: $errorMessage")
                            updateForegroundNotification("Background Processing Active")
                        }
                        
                        override fun notImplemented() {
                            Log.w(TAG, "⚠️ Background processing method not implemented")
                            updateForegroundNotification("Background Processing Active")
                        }
                    })
                }
                
                Log.d(TAG, "📤 Sent notification to Flutter background processor: $appName")
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error in background processing", e)
                updateForegroundNotification("Background Processing Active")
            }
        }
    }

    /**
     * Show success notification when tasks/events are created
     */
    private fun showSuccessNotification(appName: String, tasksCreated: Boolean, eventsCreated: Boolean) {
        try {
            val message = when {
                tasksCreated && eventsCreated -> "Task & Event created from $appName"
                tasksCreated -> "Task created from $appName notification"
                eventsCreated -> "Event created from $appName notification"
                else -> return
            }
            
            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_task)
                .setContentTitle("UACC Background Processing")
                .setContentText(message)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setAutoCancel(true)
                .build()
                
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(System.currentTimeMillis().toInt(), notification)
            
            Log.d(TAG, "🔔 Success notification shown: $message")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to show success notification", e)
        }
    }

    /**
     * Create notification channel for Android O+
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Background Processing",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Handles background AI analysis and task creation from notifications"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Create foreground notification for the service
     */
    private fun createForegroundNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("UACC Background Processing")
            .setContentText("Background Processing Active")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setShowWhen(false)
            .build()
    }

    /**
     * Update foreground notification content
     */
    private fun updateForegroundNotification(text: String) {
        try {
            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle("UACC Background Processing")
                .setContentText(text)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setShowWhen(false)
                .build()

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(FOREGROUND_NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to update foreground notification", e)
        }
    }

    /**
     * Acquire wake lock to prevent the device from sleeping during processing
     */
    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                WAKELOCK_TAG
            ).apply {
                acquire(10 * 60 * 1000L) // 10 minutes max
            }
            Log.d(TAG, "🔒 Wake lock acquired")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to acquire wake lock", e)
        }
    }

    /**
     * Release wake lock
     */
    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    Log.d(TAG, "🔓 Wake lock released")
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to release wake lock", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "🛑 Background Notification Processing Service destroyed")
        
        releaseWakeLock()
        serviceScope.cancel()
        
        // Clean up Flutter engine
        flutterEngine?.destroy()
        
        Log.d(TAG, "🧹 Background service cleanup completed")
    }
}