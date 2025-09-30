package com.example.uacc

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import com.example.uacc.dynamicisland.model.NotificationPlugin
import com.example.uacc.dynamicisland.model.PluginManager
import com.example.uacc.dynamicisland.service.IslandOverlayService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job

class UACCNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "UACCNotificationListener"
        private var instance: UACCNotificationListenerService? = null
        private var eventSink: EventChannel.EventSink? = null
        
        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
        }
        
        fun getInstance(): UACCNotificationListenerService? = instance
    }
    
    private val serviceScope = CoroutineScope(Dispatchers.Main + Job())

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "UACCNotificationListenerService created")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "UACCNotificationListenerService destroyed")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val notification = sbn.notification
            val packageName = sbn.packageName
            
            // Skip system and self notifications
            if (packageName == "android" || packageName == "com.android.systemui" || 
                packageName == this.packageName) {
                return
            }

            val notificationData = JSONObject().apply {
                put("id", sbn.key)
                put("packageName", packageName)
                put("appName", getAppName(packageName))
                put("title", notification.extras?.getString("android.title") ?: "")
                put("text", notification.extras?.getString("android.text") ?: "")
                put("bigText", notification.extras?.getString("android.bigText") ?: "")
                put("subText", notification.extras?.getString("android.subText") ?: "")
                put("timestamp", sbn.postTime)
                put("category", notification.category ?: "")
                put("priority", notification.priority)
                put("isOngoing", notification.flags and android.app.Notification.FLAG_ONGOING_EVENT != 0)
                put("isGroupSummary", notification.flags and android.app.Notification.FLAG_GROUP_SUMMARY != 0)
            }

            // Send to Flutter for UI updates
            eventSink?.success(mapOf(
                "type" to "notification_posted",
                "data" to notificationData.toString()
            ))

            // 🚀 TRIGGER BACKGROUND PROCESSING: Start background service for AI analysis
            triggerBackgroundProcessing(notificationData)

            // Create NotificationPlugin for Dynamic Island
            IslandOverlayService.instance?.let { overlayService ->
                val notificationPlugin = NotificationPlugin(sbn, overlayService, serviceScope)
                notificationPlugin.isActive = true
                
                // Add to plugin manager
                PluginManager.addPlugin(notificationPlugin)
                
                // Show the dynamic island
                overlayService.showIsland()
                PluginManager.refreshActivePlugins(overlayService)
            }

            Log.d(TAG, "✅ Notification posted & background processing triggered: ${notificationData.getString("title")}")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        try {
            eventSink?.success(mapOf(
                "type" to "notification_removed",
                "id" to sbn.key
            ))
            
            // Remove the corresponding NotificationPlugin from Dynamic Island
            val pluginId = "notification_${sbn.postTime}"
            PluginManager.removePlugin(pluginId)
            
            // If no more active plugins, hide the island
            IslandOverlayService.instance?.let { overlayService ->
                PluginManager.refreshActivePlugins(overlayService)
                if (PluginManager.activePlugins.isEmpty()) {
                    overlayService.hideIsland()
                }
            }
            
            Log.d(TAG, "Notification removed: ${sbn.key}")
        } catch (e: Exception) {
            Log.e(TAG, "Error removing notification", e)
        }
    }

    private fun getAppName(packageName: String): String {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    fun getAllActiveNotifications(): JSONArray {
        val notifications = JSONArray()
        try {
            activeNotifications?.forEach { sbn ->
                val notification = sbn.notification
                val packageName = sbn.packageName
                
                // Skip system notifications
                if (packageName == "android" || packageName == "com.android.systemui" || 
                    packageName == this.packageName) {
                    return@forEach
                }

                val notificationData = JSONObject().apply {
                    put("id", sbn.key)
                    put("packageName", packageName)
                    put("appName", getAppName(packageName))
                    put("title", notification.extras?.getString("android.title") ?: "")
                    put("text", notification.extras?.getString("android.text") ?: "")
                    put("bigText", notification.extras?.getString("android.bigText") ?: "")
                    put("subText", notification.extras?.getString("android.subText") ?: "")
                    put("timestamp", sbn.postTime)
                    put("category", notification.category ?: "")
                    put("priority", notification.priority)
                    put("isOngoing", notification.flags and android.app.Notification.FLAG_ONGOING_EVENT != 0)
                    put("isGroupSummary", notification.flags and android.app.Notification.FLAG_GROUP_SUMMARY != 0)
                }
                notifications.put(notificationData)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting active notifications", e)
        }
        return notifications
    }

    fun dismissNotification(notificationKey: String) {
        try {
            super.cancelNotification(notificationKey)
            Log.d(TAG, "Dismissed notification: $notificationKey")
        } catch (e: Exception) {
            Log.e(TAG, "Error dismissing notification: $notificationKey", e)
        }
    }

    fun dismissAllNotifications(): Int {
        var cancelledCount = 0
        try {
            activeNotifications?.forEach { sbn ->
                val packageName = sbn.packageName
                
                // Skip system notifications and ongoing notifications
                if (packageName != "android" && packageName != "com.android.systemui" && 
                    packageName != this.packageName &&
                    sbn.notification.flags and android.app.Notification.FLAG_ONGOING_EVENT == 0) {
                    
                    try {
                        super.cancelNotification(sbn.key)
                        cancelledCount++
                        Log.d(TAG, "Dismissed notification: ${sbn.key}")
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to dismiss notification: ${sbn.key}", e)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error dismissing all notifications", e)
        }
        return cancelledCount
    }

    /**
     * 🚀 BACKGROUND PROCESSING: Trigger Flutter background notification processor
     * This method starts the background processing service when a new notification arrives
     */
    private fun triggerBackgroundProcessing(notificationData: JSONObject) {
        try {
            // Start background processing service
            val intent = Intent(this, BackgroundNotificationProcessingService::class.java).apply {
                action = "PROCESS_NOTIFICATION"
                putExtra("notification_data", notificationData.toString())
            }
            
            // Start as foreground service to ensure it runs in background
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            
            Log.d(TAG, "🚀 Background processing service started for: ${notificationData.getString("appName")}")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to trigger background processing", e)
            
            // Fallback: Send directly to Flutter method channel
            sendToFlutterBackgroundProcessor(notificationData)
        }
    }

    /**
     * Fallback method to send notification directly to Flutter background processor
     */
    private fun sendToFlutterBackgroundProcessor(notificationData: JSONObject) {
        try {
            // Send via method channel for background processing
            eventSink?.success(mapOf(
                "type" to "background_process_notification", 
                "data" to notificationData.toString()
            ))
            
            Log.d(TAG, "📱 Fallback: Sent notification to Flutter background processor")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send to Flutter background processor", e)
        }
    }
}