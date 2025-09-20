package com.example.uacc

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.telephony.TelephonyManager
import io.flutter.Log

class CallStateReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "CallStateReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received broadcast: ${intent.action}")
        
        when (intent.action) {
            TelephonyManager.ACTION_PHONE_STATE_CHANGED -> {
                handlePhoneStateChange(context, intent)
            }
            Intent.ACTION_BOOT_COMPLETED -> {
                handleBootCompleted(context)
            }
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                handlePackageReplaced(context)
            }
        }
    }
    
    private fun handlePhoneStateChange(context: Context, intent: Intent) {
        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
        
        Log.d(TAG, "Phone state changed: $state, number: $phoneNumber")
        
        // Send call state to platform channel
        LiveActivityChannel.sendCallStateChanged(state ?: "unknown", phoneNumber)
        
        when (state) {
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                // Call is active - start live activity service
                startLiveActivityService(context)
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                // Call ended - service will handle cleanup automatically
                Log.d(TAG, "Call ended - service will handle cleanup")
            }
            TelephonyManager.EXTRA_STATE_RINGING -> {
                // Incoming call - prepare service but don't show activity yet
                Log.d(TAG, "Incoming call ringing")
            }
        }
    }
    
    private fun handleBootCompleted(context: Context) {
        Log.d(TAG, "Device boot completed")
        
        // Auto-start live activity service on boot
        try {
            LiveActivityService.startService(context)
            Log.d(TAG, "Auto-started live activity service on boot")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to auto-start live activity service on boot", e)
        }
    }
    
    private fun handlePackageReplaced(context: Context) {
        Log.d(TAG, "Package replaced/updated")
        
        // Restart service after app update
        try {
            LiveActivityService.startService(context)
            Log.d(TAG, "Restarted live activity service after package update")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart live activity service after package update", e)
        }
    }
    
    private fun startLiveActivityService(context: Context) {
        try {
            LiveActivityService.startService(context)
            Log.d(TAG, "Started live activity service for active call")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start live activity service", e)
            LiveActivityChannel.sendError(
                "SERVICE_ERROR", 
                "Failed to start live activity service", 
                e.message
            )
        }
    }
}