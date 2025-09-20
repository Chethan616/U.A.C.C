package com.example.uacc.services

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.telephony.TelephonyCallback
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor
import android.content.ContentResolver
import android.provider.ContactsContract
import android.database.Cursor
import android.net.Uri
import kotlinx.coroutines.*

class CallMonitoringManager(
    private val context: Context,
    private val methodChannel: MethodChannel,
    private val eventChannel: EventChannel
) {
    
    private var telephonyManager: TelephonyManager? = null
    private var phoneStateListener: PhoneStateListener? = null
    private var telephonyCallback: TelephonyCallback? = null
    private var eventSink: EventChannel.EventSink? = null
    private var lastKnownState: Int = TelephonyManager.CALL_STATE_IDLE
    private var lastKnownNumber: String? = null
    
    companion object {
        // `const` is only allowed for primitives and String. Use a regular val for array.
        private val REQUIRED_PERMISSIONS = arrayOf(
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.READ_CALL_LOG,
            Manifest.permission.READ_CONTACTS,
            Manifest.permission.SYSTEM_ALERT_WINDOW
        )
    }

    init {
        telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        setupEventChannel()
        setupMethodChannel()
    }

    private fun setupEventChannel() {
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                startCallMonitoring()
            }

            override fun onCancel(arguments: Any?) {
                stopCallMonitoring()
                eventSink = null
            }
        })
    }

    private fun setupMethodChannel() {
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermissions" -> {
                    result.success(hasRequiredPermissions())
                }
                "requestPermissions" -> {
                    // Note: Permission requests need to be handled by the main Activity
                    result.success(hasRequiredPermissions())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasRequiredPermissions(): Boolean {
        return REQUIRED_PERMISSIONS.all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun startCallMonitoring() {
        if (!hasRequiredPermissions()) {
            sendCallStateEvent("PERMISSION_DENIED", null, null)
            return
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Android 12+ (API 31+) - Use TelephonyCallback
                telephonyCallback = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                    override fun onCallStateChanged(state: Int) {
                        handleCallStateChange(state, null)
                    }
                }
                telephonyManager?.registerTelephonyCallback(
                    context.mainExecutor,
                    telephonyCallback!!
                )
            } else {
                // Android 11 and below - Use PhoneStateListener
                phoneStateListener = object : PhoneStateListener() {
                    override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                        handleCallStateChange(state, phoneNumber)
                    }
                }
                telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
            }
            
            println("Call monitoring started")
        } catch (e: Exception) {
            println("Error starting call monitoring: ${e.message}")
            sendCallStateEvent("ERROR", null, e.message)
        }
    }

    private fun stopCallMonitoring() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                telephonyCallback?.let { callback ->
                    telephonyManager?.unregisterTelephonyCallback(callback)
                }
            } else {
                phoneStateListener?.let { listener ->
                    telephonyManager?.listen(listener, PhoneStateListener.LISTEN_NONE)
                }
            }
            
            phoneStateListener = null
            telephonyCallback = null
            println("Call monitoring stopped")
        } catch (e: Exception) {
            println("Error stopping call monitoring: ${e.message}")
        }
    }

    private fun handleCallStateChange(state: Int, phoneNumber: String?) {
        // Prevent duplicate events
        if (state == lastKnownState && phoneNumber == lastKnownNumber) {
            return
        }
        
        lastKnownState = state
        lastKnownNumber = phoneNumber
        
        val stateString = when (state) {
            TelephonyManager.CALL_STATE_IDLE -> "IDLE"
            TelephonyManager.CALL_STATE_RINGING -> "RINGING"
            TelephonyManager.CALL_STATE_OFFHOOK -> "OFFHOOK"
            else -> "UNKNOWN"
        }

        println("Call state changed: $stateString, Number: $phoneNumber")

        // Get caller name asynchronously
        if (phoneNumber != null && phoneNumber.isNotEmpty()) {
            CoroutineScope(Dispatchers.IO).launch {
                val callerName = getContactName(phoneNumber)
                withContext(Dispatchers.Main) {
                    sendCallStateEvent(stateString, phoneNumber, callerName)
                }
            }
        } else {
            sendCallStateEvent(stateString, phoneNumber, null)
        }
    }

    private fun sendCallStateEvent(callState: String, phoneNumber: String?, callerName: String?) {
        val eventData = mapOf(
            "callState" to callState,
            "phoneNumber" to phoneNumber,
            "callerName" to callerName,
            "timestamp" to System.currentTimeMillis()
        )
        
        eventSink?.success(eventData)
        println("Sent call state event: $eventData")
    }

    private fun getContactName(phoneNumber: String): String? {
        if (!hasContactsPermission()) return null
        
        return try {
            val uri = Uri.withAppendedPath(
                ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                Uri.encode(phoneNumber)
            )
            
            val cursor: Cursor? = context.contentResolver.query(
                uri,
                arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME),
                null,
                null,
                null
            )
            
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                    if (nameIndex >= 0) {
                        return it.getString(nameIndex)
                    }
                }
            }
            null
        } catch (e: Exception) {
            println("Error getting contact name: ${e.message}")
            null
        }
    }

    private fun hasContactsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CONTACTS
        ) == PackageManager.PERMISSION_GRANTED
    }

    fun cleanup() {
        stopCallMonitoring()
        eventSink = null
    }
}