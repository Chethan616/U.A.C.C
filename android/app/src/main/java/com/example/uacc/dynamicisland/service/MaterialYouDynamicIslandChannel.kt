package com.example.uacc.dynamicisland.service

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class MaterialYouDynamicIslandChannel(private val context: Context) : MethodCallHandler {
    companion object {
        private const val CHANNEL = "com.example.uacc/material_you_dynamic_island"
        private const val TAG = "DynamicIslandChannel"
    }

    private var channel: MethodChannel? = null

    fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
        Log.d(TAG, "MaterialYou Dynamic Island Channel configured")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "show" -> {
                    val text = call.argument<String>("text") ?: "Dynamic Island"
                    showDynamicIsland(text)
                    result.success(true)
                }
                "hide" -> {
                    hideDynamicIsland()
                    result.success(true)
                }
                "expand" -> {
                    expandDynamicIsland()
                    result.success(true)
                }
                "shrink" -> {
                    shrinkDynamicIsland()
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    result.success(checkOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "checkAccessibilityPermission" -> {
                    result.success(checkAccessibilityPermission())
                }
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling method call: ${call.method}", e)
            result.error("ERROR", "Failed to handle method call: ${e.message}", e)
        }
    }

    private fun showDynamicIsland(text: String) {
        Log.d(TAG, "Show Dynamic Island: $text")
        val service = IslandOverlayService.instance
        service?.showIsland()
    }

    private fun hideDynamicIsland() {
        Log.d(TAG, "Hide Dynamic Island")
        val service = IslandOverlayService.instance
        service?.hideIsland()
    }

    private fun expandDynamicIsland() {
        Log.d(TAG, "Expand Dynamic Island")
        val service = IslandOverlayService.instance
        service?.expand()
    }

    private fun shrinkDynamicIsland() {
        Log.d(TAG, "Shrink Dynamic Island")
        val service = IslandOverlayService.instance
        service?.shrink()
    }

    private fun checkOverlayPermission(): Boolean {
        return Settings.canDrawOverlays(context)
    }

    private fun requestOverlayPermission() {
        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    private fun checkAccessibilityPermission(): Boolean {
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)

        while (colonSplitter.hasNext()) {
            val componentName = ComponentName.unflattenFromString(colonSplitter.next())
            if (componentName != null && 
                componentName.packageName == context.packageName &&
                componentName.className == IslandOverlayService::class.java.name) {
                return true
            }
        }
        return false
    }

    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }
}