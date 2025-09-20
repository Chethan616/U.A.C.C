package com.example.uacc

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.app.Notification
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream
import android.util.Base64

class NotificationManager(private val context: Context) {
    
    private val mockNotifications = listOf(
        mapOf(
            "id" to "1",
            "packageName" to "com.google.android.gms",
            "appName" to "Gmail",
            "appIcon" to null,
            "title" to "New email from John Doe",
            "content" to "Meeting scheduled for tomorrow at 10 AM",
            "timestamp" to System.currentTimeMillis() - 15 * 60 * 1000, // 15 mins ago
            "isRead" to false,
            "bigText" to "Meeting scheduled for tomorrow at 10 AM. Please review the agenda and prepare your quarterly report.",
            "subText" to "Work",
            "priority" to "HIGH"
        ),
        mapOf(
            "id" to "2",
            "packageName" to "com.whatsapp",
            "appName" to "WhatsApp",
            "appIcon" to null,
            "title" to "Mom",
            "content" to "Don't forget to call me tonight!",
            "timestamp" to System.currentTimeMillis() - 60 * 60 * 1000, // 1 hour ago
            "isRead" to false,
            "bigText" to null,
            "subText" to null,
            "priority" to "NORMAL"
        ),
        mapOf(
            "id" to "3",
            "packageName" to "com.zomato.app",
            "appName" to "Zomato",
            "appIcon" to null,
            "title" to "Order Update",
            "content" to "Your order is being prepared and will be delivered in 25 minutes",
            "timestamp" to System.currentTimeMillis() - 2 * 60 * 60 * 1000, // 2 hours ago
            "isRead" to true,
            "bigText" to "Your order #ZOM123456 is being prepared by the restaurant and will be delivered in approximately 25 minutes.",
            "subText" to "Delivery",
            "priority" to "HIGH"
        ),
        mapOf(
            "id" to "4",
            "packageName" to "com.paytm",
            "appName" to "Paytm",
            "appIcon" to null,
            "title" to "Payment Reminder",
            "content" to "Your electricity bill of ₹2,450 is due tomorrow",
            "timestamp" to System.currentTimeMillis() - 3 * 60 * 60 * 1000, // 3 hours ago
            "isRead" to false,
            "bigText" to "Your electricity bill of ₹2,450 is due tomorrow. Pay now to avoid late charges.",
            "subText" to "Bills",
            "priority" to "URGENT"
        ),
        mapOf(
            "id" to "5",
            "packageName" to "com.google.android.calendar",
            "appName" to "Calendar",
            "appIcon" to null,
            "title" to "Meeting in 30 minutes",
            "content" to "Team standup meeting with Alex, Sarah, and Mike",
            "timestamp" to System.currentTimeMillis() - 30 * 60 * 1000, // 30 mins ago
            "isRead" to false,
            "bigText" to null,
            "subText" to "Work Meeting",
            "priority" to "HIGH"
        ),
        mapOf(
            "id" to "6",
            "packageName" to "com.phonepe.app",
            "appName" to "PhonePe",
            "appIcon" to null,
            "title" to "Transaction Successful",
            "content" to "₹500 sent to Ramesh Kumar",
            "timestamp" to System.currentTimeMillis() - 4 * 60 * 60 * 1000,
            "isRead" to true,
            "bigText" to null,
            "subText" to "Payment",
            "priority" to "NORMAL"
        ),
        mapOf(
            "id" to "7",
            "packageName" to "com.spotify.music",
            "appName" to "Spotify",
            "appIcon" to null,
            "title" to "Your Weekly Mix is ready",
            "content" to "New songs based on your recent listening",
            "timestamp" to System.currentTimeMillis() - 6 * 60 * 60 * 1000,
            "isRead" to false,
            "bigText" to null,
            "subText" to "Music",
            "priority" to "LOW"
        )
    )
    
    fun getNotifications(limit: Int): List<Map<String, Any?>> {
        // For now, return mock data since implementing notification listener requires special permissions
        return mockNotifications.take(limit)
    }
    
    fun getNotificationStats(): Map<String, Int> {
        val now = System.currentTimeMillis()
        val startOfDay = now - (now % (24 * 60 * 60 * 1000))
        
        var todayNotifications = 0
        var totalNotifications = mockNotifications.size
        var unreadNotifications = 0
        var importantNotifications = 0
        
        for (notification in mockNotifications) {
            val timestamp = notification["timestamp"] as Long
            val isRead = notification["isRead"] as Boolean
            val priority = notification["priority"] as String
            
            if (timestamp >= startOfDay) {
                todayNotifications++
            }
            
            if (!isRead) {
                unreadNotifications++
            }
            
            if (priority == "HIGH" || priority == "URGENT") {
                importantNotifications++
            }
        }
        
        return mapOf(
            "todayNotifications" to todayNotifications,
            "totalNotifications" to totalNotifications,
            "unreadNotifications" to unreadNotifications,
            "importantNotifications" to importantNotifications
        )
    }
    
    fun summarizeNotifications(notifications: List<Map<String, Any?>>): Map<String, String> {
        // Simple AI-like summarization logic
        val appGroups = notifications.groupBy { it["appName"] }
        val priorityGroups = notifications.groupBy { it["priority"] }
        
        val summary = StringBuilder()
        
        // Email updates
        appGroups["Gmail"]?.let { emails ->
            if (emails.isNotEmpty()) {
                summary.append("📧 **Email Updates**: ${emails.size} new message${if (emails.size > 1) "s" else ""}")
                emails.firstOrNull()?.let { email ->
                    summary.append(" including one from ${email["title"]}")
                }
                summary.append(".\n\n")
            }
        }
        
        // Messages
        appGroups["WhatsApp"]?.let { messages ->
            if (messages.isNotEmpty()) {
                summary.append("💬 **Messages**: ${messages.size} WhatsApp message${if (messages.size > 1) "s" else ""}")
                messages.firstOrNull()?.let { message ->
                    summary.append(" from ${message["title"]}")
                }
                summary.append(".\n\n")
            }
        }
        
        // Food/Delivery updates
        appGroups["Zomato"]?.let { orders ->
            if (orders.isNotEmpty()) {
                summary.append("🍔 **Food Delivery**: Order status update - delivery in progress.\n\n")
            }
        }
        
        // Payment reminders
        val paymentApps = listOf("Paytm", "PhonePe", "GPay")
        val paymentNotifications = notifications.filter { paymentApps.contains(it["appName"]) }
        if (paymentNotifications.isNotEmpty()) {
            summary.append("💳 **Payments**: ${paymentNotifications.size} payment notification${if (paymentNotifications.size > 1) "s" else ""}")
            paymentNotifications.find { it["priority"] == "URGENT" }?.let {
                summary.append(" - urgent bill payment required")
            }
            summary.append(".\n\n")
        }
        
        // Calendar events
        appGroups["Calendar"]?.let { events ->
            if (events.isNotEmpty()) {
                summary.append("📅 **Calendar**: ${events.size} upcoming event${if (events.size > 1) "s" else ""}")
                events.firstOrNull()?.let { event ->
                    summary.append(" - ${event["content"]}")
                }
                summary.append(".\n\n")
            }
        }
        
        // Priority actions
        val urgentNotifications = priorityGroups["URGENT"] ?: emptyList()
        val highNotifications = priorityGroups["HIGH"] ?: emptyList()
        
        if (urgentNotifications.isNotEmpty() || highNotifications.isNotEmpty()) {
            summary.append("🔔 **Priority Actions Needed**: ")
            val actions = mutableListOf<String>()
            urgentNotifications.forEach { actions.add(it["title"].toString()) }
            highNotifications.take(2).forEach { actions.add(it["title"].toString()) }
            summary.append(actions.joinToString(", "))
            summary.append(".")
        }
        
        return mapOf("summary" to summary.toString())
    }
    
    fun markNotificationAsRead(notificationId: String): Boolean {
        // In a real implementation, this would mark the notification as read
        return true
    }
    
    fun hasNotificationPermission(): Boolean {
        // Check if app has notification listener permission
        return false // For now, return false since we're using mock data
    }
    
    fun requestNotificationPermission(): Boolean {
        // In a real implementation, this would request notification listener permission
        return true
    }
}