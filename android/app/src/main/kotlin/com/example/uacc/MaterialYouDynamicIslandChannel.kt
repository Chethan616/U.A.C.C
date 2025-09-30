package com.example.uacc

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import android.net.Uri
import android.os.Build
import android.util.Log

class MaterialYouDynamicIslandChannel(private val activity: FlutterActivity) {
    
    companion object {
        private const val CHANNEL = "com.example.uacc/material_you_dynamic_island"
        private const val TAG = "MaterialYouDynamicIslandChannel"
    }
    
    private var methodChannel: MethodChannel? = null
    
    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }
    
    private fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val service = MaterialYouDynamicIslandNativeService.getInstance()
        
        when (call.method) {
            "checkPermissions" -> {
                result.success(checkPermissions())
            }
            
            "requestOverlayPermission" -> {
                requestOverlayPermission()
                result.success(true)
            }
            
            "requestAccessibilityPermission" -> {
                requestAccessibilityPermission()
                result.success(true)
            }
            
            "show" -> {
                val title = call.argument<String>("title") ?: "Dynamic Island"
                val subtitle = call.argument<String>("subtitle") ?: ""
                val type = call.argument<String>("type") ?: "default"
                
                showDynamicIsland(type, title, subtitle)
                result.success(true)
            }
            
            "hide" -> {
                service?.hideCurrentOverlay()
                result.success(true)
            }
            
            "updateContent" -> {
                val title = call.argument<String>("title") ?: ""
                val subtitle = call.argument<String>("subtitle") ?: ""
                val type = call.argument<String>("type") ?: "default"
                
                showDynamicIsland(type, title, subtitle)
                result.success(true)
            }
            
            "showIncomingCall" -> {
                val callerName = call.argument<String>("callerName") ?: "Unknown"
                val callerNumber = call.argument<String>("callerNumber") ?: ""
                
                showDynamicIsland("call", "Incoming Call", callerName)
                result.success(true)
            }
            
            "showOngoingCall" -> {
                val callerName = call.argument<String>("callerName") ?: "Unknown"
                val duration = call.argument<String>("duration") ?: "00:00"
                
                showDynamicIsland("call", "Call Active", "$callerName • $duration")
                result.success(true)
            }
            
            "showNotification" -> {
                val appName = call.argument<String>("appName") ?: ""
                val content = call.argument<String>("content") ?: ""
                
                showDynamicIsland("notification", appName, content)
                result.success(true)
            }
            
            "isServiceRunning" -> {
                result.success(service != null)
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun checkPermissions(): Map<String, Boolean> {
        return mapOf(
            "overlay" to canDrawOverlays(),
            "accessibility" to isAccessibilityServiceEnabled()
        )
    }
    
    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(activity)
        } else {
            true
        }
    }
    
    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceName = "${activity.packageName}/${MaterialYouDynamicIslandNativeService::class.java.name}"
        val enabledServices = Settings.Secure.getString(
            activity.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(serviceName) == true
    }
    
    private fun showDynamicIsland(type: String, title: String, content: String) {
        val service = MaterialYouDynamicIslandNativeService.getInstance()
        if (service != null) {
            val intent = Intent("NOTIFICATION_POSTED").apply {
                putExtra("title", title)
                putExtra("content", content)
                putExtra("type", type)
            }
            service.sendBroadcast(intent)
        } else {
            Log.w(TAG, "Dynamic Island native service not available")
        }
    }
    
    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(activity)) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${activity.packageName}")
            )
            activity.startActivity(intent)
        }
    }
    
    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        activity.startActivity(intent)
    }
}