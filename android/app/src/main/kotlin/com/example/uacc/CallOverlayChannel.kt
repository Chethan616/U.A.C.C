package com.example.uacc

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.Log
import com.example.uacc.dynamicisland.service.IslandOverlayService
import com.example.uacc.dynamicisland.model.SpeakerType

object CallOverlayChannel {
    
    private const val METHOD_CHANNEL = "com.example.uacc/call_overlay"
    private const val EVENT_CHANNEL = "com.example.uacc/call_overlay_events"
    private const val TAG = "CallOverlayChannel"
    
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    
    fun setupChannels(flutterEngine: FlutterEngine, context: Context) {
        this.context = context
        
        // Setup method channel for Flutter -> Native calls
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            handleMethodCall(call, result, context)
        }
        
        // Setup event channel for Native -> Flutter events
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(TAG, "Event channel listener attached")
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
                Log.d(TAG, "Event channel listener detached")
            }
        })
        
        Log.d(TAG, "Platform channels initialized")
    }
    
    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result, context: Context) {
        when (call.method) {
            "startOverlayService" -> {
                try {
                    // Dynamic Island uses AccessibilityService - user needs to enable it manually
                    Log.d(TAG, "Dynamic Island service start requested")
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to handle Dynamic Island service start", e)
                    result.error("SERVICE_ERROR", "Failed to handle Dynamic Island service start", e.message)
                }
            }
            
            "stopOverlayService" -> {
                try {
                    // Dynamic Island AccessibilityService management
                    Log.d(TAG, "Dynamic Island service stop requested")
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to handle Dynamic Island service stop", e)
                    result.error("SERVICE_ERROR", "Failed to handle Dynamic Island service stop", e.message)
                }
            }
            
            "checkOverlayPermission" -> {
                val hasPermission = Settings.canDrawOverlays(context)
                result.success(hasPermission)
            }
            
            "requestOverlayPermission" -> {
                try {
                    val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to open overlay permission settings", e)
                    result.error("PERMISSION_ERROR", "Failed to open overlay permission settings", e.message)
                }
            }
            
            "expandDynamicIsland" -> {
                sendEvent("expandDynamicIsland", emptyMap<String, Any>())
                result.success(true)
            }
            
            "collapseDynamicIsland" -> {
                sendEvent("collapseDynamicIsland", emptyMap<String, Any>())
                result.success(true)
            }
            
            "updateTranscript" -> {
                val transcript = call.argument<String>("transcript") ?: ""
                sendEvent("transcriptUpdate", mapOf("transcript" to transcript))
                result.success(true)
            }
            
            "clearTranscript" -> {
                try {
                    IslandOverlayService.instance?.clearTranscript()
                    sendEvent("transcriptUpdate", mapOf("transcript" to ""))
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to clear transcript", e)
                    result.error("TRANSCRIPT_ERROR", "Failed to clear transcript", e.message)
                }
            }
            
            "startCallTranscript" -> {
                try {
                    IslandOverlayService.instance?.startCallTranscript()
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start call transcript", e)
                    result.error("TRANSCRIPT_ERROR", "Failed to start call transcript", e.message)
                }
            }
            
            "stopCallTranscript" -> {
                try {
                    IslandOverlayService.instance?.stopCallTranscript()
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to stop call transcript", e)
                    result.error("TRANSCRIPT_ERROR", "Failed to stop call transcript", e.message)
                }
            }
            
            "addTranscriptMessage" -> {
                try {
                    val text = call.argument<String>("text") ?: ""
                    val speakerTypeStr = call.argument<String>("speakerType") ?: "OUTGOING"
                    val isPartial = call.argument<Boolean>("isPartial") ?: false
                    
                    val speakerType = when (speakerTypeStr.uppercase()) {
                        "INCOMING" -> SpeakerType.INCOMING
                        "OUTGOING" -> SpeakerType.OUTGOING 
                        "SYSTEM" -> SpeakerType.SYSTEM
                        else -> SpeakerType.OUTGOING
                    }
                    
                    IslandOverlayService.instance?.addTranscriptMessage(text, speakerType, isPartial)
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to add transcript message", e)
                    result.error("TRANSCRIPT_ERROR", "Failed to add transcript message", e.message)
                }
            }
            
            "getServiceStatus" -> {
                // This would need to be implemented to check if service is running
                result.success(mapOf(
                    "isServiceRunning" to false, // TODO: Implement actual check
                    "isOverlayVisible" to false,
                    "isTranscribing" to false
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
    
    fun sendOverlayStateChanged(isVisible: Boolean, isExpanded: Boolean = false) {
        sendEvent("overlayStateChanged", mapOf(
            "isVisible" to isVisible,
            "isExpanded" to isExpanded,
            "timestamp" to System.currentTimeMillis()
        ))
    }
    
    fun sendTranscriptionStateChanged(isTranscribing: Boolean) {
        sendEvent("transcriptionStateChanged", mapOf(
            "isTranscribing" to isTranscribing,
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
        Log.d(TAG, "Sent event: $eventType")
    }
    
    fun cleanup() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        
        eventSink = null
        context = null
        
        Log.d(TAG, "Platform channels cleaned up")
    }
}