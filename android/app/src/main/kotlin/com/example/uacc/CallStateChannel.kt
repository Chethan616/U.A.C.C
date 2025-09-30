package com.example.uacc

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

object CallStateChannel {
    
    private const val METHOD_CHANNEL = "com.example.uacc/call_state"
    private const val EVENT_CHANNEL = "com.example.uacc/call_state_events"
    private const val TAG = "CallStateChannel"
    
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    
    fun setupChannels(flutterEngine: FlutterEngine, context: Context) {
        // Setup method channel for Flutter -> Native calls
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getCallState" -> {
                    // Return current call state
                    result.success("IDLE")
                }
                else -> result.notImplemented()
            }
        }
        
        // Setup event channel for Native -> Flutter events
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }
    
    fun sendCallStateUpdate(callState: String, phoneNumber: String? = null, callerName: String? = null) {
        val eventData = mapOf(
            "callState" to callState,
            "phoneNumber" to phoneNumber,
            "callerName" to callerName,
            "timestamp" to System.currentTimeMillis()
        )
        eventSink?.success(eventData)
    }
    
    fun sendCallStateChanged(callState: String, phoneNumber: String? = null) {
        sendCallStateUpdate(callState, phoneNumber)
    }
    
    fun cleanup() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        
        eventSink = null
    }
}