package com.example.uacc

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.Log

object LiveActivityChannel {
    
    private const val LIVE_ACTIVITY_CHANNEL = "com.example.uacc/live_activity"
    private const val LIVE_ACTIVITY_EVENTS = "com.example.uacc/live_activity_events"
    private const val CALL_LOG_CHANNEL = "com.example.uacc/call_logs"
    private const val NOTIFICATION_CHANNEL = "com.example.uacc/notifications"
    private const val TASK_CHANNEL = "com.example.uacc/tasks"
    private const val CALENDAR_CHANNEL = "com.example.uacc/calendar"
    private const val TAG = "CallStateChannel"
    
    private var liveActivityMethodChannel: MethodChannel? = null
    private var callLogMethodChannel: MethodChannel? = null
    private var notificationMethodChannel: MethodChannel? = null
    private var taskMethodChannel: MethodChannel? = null
    private var calendarMethodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    
    // Manager instances
    private var callLogManager: CallLogManager? = null
    private var notificationManager: NotificationManager? = null
    private var taskManager: TaskManager? = null
    
    fun setupChannels(flutterEngine: FlutterEngine, context: Context) {
        this.context = context
        
        // Initialize managers
        callLogManager = CallLogManager(context)
        notificationManager = NotificationManager(context)
        taskManager = TaskManager(context)
        
        // Setup live activity method channel
        liveActivityMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LIVE_ACTIVITY_CHANNEL)
        liveActivityMethodChannel?.setMethodCallHandler { call, result ->
            handleLiveActivityCall(call, result, context)
        }
        
        // Setup call log method channel
        callLogMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_LOG_CHANNEL)
        callLogMethodChannel?.setMethodCallHandler { call, result ->
            handleCallLogCall(call, result)
        }
        
        // Setup notification method channel
        notificationMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
        notificationMethodChannel?.setMethodCallHandler { call, result ->
            handleNotificationCall(call, result)
        }
        
        // Setup task method channel
        taskMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TASK_CHANNEL)
        taskMethodChannel?.setMethodCallHandler { call, result ->
            handleTaskCall(call, result)
        }
        
        // Setup calendar method channel (placeholder)
        calendarMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALENDAR_CHANNEL)
        calendarMethodChannel?.setMethodCallHandler { call, result ->
            handleCalendarCall(call, result)
        }
        
        // Setup event channel for Native -> Flutter events
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, LIVE_ACTIVITY_EVENTS)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(TAG, "Live activity event channel listener attached")
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
                Log.d(TAG, "Live activity event channel listener detached")
            }
        })
        
        Log.d(TAG, "All platform channels initialized")
    }
    
    private fun handleLiveActivityCall(call: MethodCall, result: MethodChannel.Result, context: Context) {
        when (call.method) {
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun handleCallLogCall(call: MethodCall, result: MethodChannel.Result) {
        val manager = callLogManager ?: run {
            result.error("MANAGER_ERROR", "CallLogManager not initialized", null)
            return
        }
        
        when (call.method) {
            "getCallLogs" -> {
                try {
                    val limit = call.argument<Int>("limit") ?: 100
                    val callLogs = manager.getCallLogs(limit)
                    result.success(callLogs)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to get call logs", e)
                    result.error("CALL_LOG_ERROR", "Failed to get call logs", e.message)
                }
            }
            
            "getCallStats" -> {
                try {
                    val stats = manager.getCallStats()
                    result.success(stats)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to get call stats", e)
                    result.error("CALL_LOG_ERROR", "Failed to get call stats", e.message)
                }
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun handleNotificationCall(call: MethodCall, result: MethodChannel.Result) {
        val manager = notificationManager ?: run {
            result.error("MANAGER_ERROR", "NotificationManager not initialized", null)
            return
        }
        
        when (call.method) {
            "getNotifications" -> {
                try {
                    val limit = call.argument<Int>("limit") ?: 100
                    val notifications = manager.getNotifications(limit)
                    result.success(notifications)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to get notifications", e)
                    result.error("NOTIFICATION_ERROR", "Failed to get notifications", e.message)
                }
            }
            
            "getNotificationStats" -> {
                try {
                    val stats = manager.getNotificationStats()
                    result.success(stats)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to get notification stats", e)
                    result.error("NOTIFICATION_ERROR", "Failed to get notification stats", e.message)
                }
            }
            
            "summarizeNotifications" -> {
                try {
                    val notifications = call.argument<List<Map<String, Any?>>>("notifications") ?: emptyList()
                    val summary = manager.summarizeNotifications(notifications)
                    result.success(summary)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to summarize notifications", e)
                    result.error("NOTIFICATION_ERROR", "Failed to summarize notifications", e.message)
                }
            }
            
            "markNotificationAsRead" -> {
                try {
                    val notificationId = call.argument<String>("notificationId") ?: ""
                    val success = manager.markNotificationAsRead(notificationId)
                    result.success(success)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to mark notification as read", e)
                    result.error("NOTIFICATION_ERROR", "Failed to mark notification as read", e.message)
                }
            }
            
            "hasNotificationPermission" -> {
                try {
                    val hasPermission = manager.hasNotificationPermission()
                    result.success(hasPermission)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to check notification permission", e)
                    result.error("NOTIFICATION_ERROR", "Failed to check notification permission", e.message)
                }
            }
            
            "requestNotificationPermission" -> {
                try {
                    val granted = manager.requestNotificationPermission()
                    result.success(granted)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to request notification permission", e)
                    result.error("NOTIFICATION_ERROR", "Failed to request notification permission", e.message)
                }
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun handleTaskCall(call: MethodCall, result: MethodChannel.Result) {
        val manager = taskManager ?: run {
            result.error("MANAGER_ERROR", "TaskManager not initialized", null)
            return
        }
        
        when (call.method) {
            "getTasks" -> {
                try {
                    val tasks = manager.getTasks()
                    result.success(tasks)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to get tasks", e)
                    result.error("TASK_ERROR", "Failed to get tasks", e.message)
                }
            }
            
            "createTask" -> {
                try {
                    val taskData = call.arguments as? Map<String, Any?> ?: emptyMap()
                    val newTask = manager.createTask(taskData)
                    result.success(newTask)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to create task", e)
                    result.error("TASK_ERROR", "Failed to create task", e.message)
                }
            }
            
            "updateTask" -> {
                try {
                    val taskData = call.arguments as? Map<String, Any?> ?: emptyMap()
                    val success = manager.updateTask(taskData)
                    result.success(success)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to update task", e)
                    result.error("TASK_ERROR", "Failed to update task", e.message)
                }
            }
            
            "deleteTask" -> {
                try {
                    val taskId = call.argument<String>("taskId") ?: ""
                    val success = manager.deleteTask(taskId)
                    result.success(success)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to delete task", e)
                    result.error("TASK_ERROR", "Failed to delete task", e.message)
                }
            }
            
            "getTaskStats" -> {
                try {
                    val stats = manager.getTaskStats()
                    result.success(stats)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to get task stats", e)
                    result.error("TASK_ERROR", "Failed to get task stats", e.message)
                }
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun handleCalendarCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getEvents" -> {
                // Mock calendar events for now
                result.success(emptyList<Map<String, Any?>>())
            }
            
            "getCalendarStats" -> {
                // Mock calendar stats
                result.success(mapOf(
                    "todayEvents" to 3,
                    "weekEvents" to 12,
                    "monthEvents" to 28,
                    "upcomingEvents" to 8,
                    "overdueEvents" to 1
                ))
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    // Methods for sending events from Native to Flutter
    fun sendTranscriptUpdate(transcript: String) {
        sendEvent("transcriptUpdate", mapOf(
            "transcript" to transcript,
            "timestamp" to System.currentTimeMillis()
        ))
    }
    
    fun sendCallStateChanged(callState: String, phoneNumber: String? = null) {
        val eventData = mutableMapOf<String, Any>(
            "callState" to callState,
            "timestamp" to System.currentTimeMillis()
        )
        
        phoneNumber?.let { eventData["phoneNumber"] = it }
        
        sendEvent("callStateChanged", eventData)
    }
    
    fun sendActivityStateChanged(isActive: Boolean) {
        sendEvent("activityStateChanged", mapOf(
            "isActive" to isActive,
            "timestamp" to System.currentTimeMillis()
        ))
    }
    
    fun sendError(errorType: String, errorMessage: String, errorDetails: String? = null) {
        val eventData = mutableMapOf<String, Any>(
            "errorType" to errorType,
            "errorMessage" to errorMessage,
            "timestamp" to System.currentTimeMillis()
        )
        
        errorDetails?.let { eventData["errorDetails"] = it }
        
        sendEvent("error", eventData)
    }
    
    private fun sendEvent(eventType: String, data: Map<String, Any>) {
        val eventData = mutableMapOf<String, Any>(
            "type" to eventType
        )
        eventData.putAll(data)
        
        eventSink?.success(eventData)
        Log.d(TAG, "Sent live activity event: $eventType")
    }
    
    fun cleanup() {
        liveActivityMethodChannel?.setMethodCallHandler(null)
        liveActivityMethodChannel = null
        
        callLogMethodChannel?.setMethodCallHandler(null)
        callLogMethodChannel = null
        
        notificationMethodChannel?.setMethodCallHandler(null)
        notificationMethodChannel = null
        
        taskMethodChannel?.setMethodCallHandler(null)
        taskMethodChannel = null
        
        calendarMethodChannel?.setMethodCallHandler(null)
        calendarMethodChannel = null
        
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        
        eventSink = null
        context = null
        
        callLogManager = null
        notificationManager = null
        taskManager = null
        
        Log.d(TAG, "All platform channels cleaned up")
    }
}