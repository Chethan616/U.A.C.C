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
        
        // Send call state to platform channel for Flutter
        CallStateChannel.sendCallStateChanged(state ?: "unknown", phoneNumber)
        
        when (state) {
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                // Call is active - start Dynamic Island transcript service
                Log.d(TAG, "Call is active - starting Dynamic Island transcript service")
                startTranscriptService(context)
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                // Call ended - stop Dynamic Island transcript service
                Log.d(TAG, "Call ended - stopping Dynamic Island transcript service")
                stopTranscriptService(context)
            }
            TelephonyManager.EXTRA_STATE_RINGING -> {
                // Incoming call - prepare service but don't show island yet
                Log.d(TAG, "Incoming call ringing - preparing service")
            }
        }
    }
    
    private fun handleBootCompleted(context: Context) {
        Log.d(TAG, "Device boot completed - Dynamic Island ready")
    }
    
    private fun handlePackageReplaced(context: Context) {
        Log.d(TAG, "Package replaced/updated - Dynamic Island ready")
    }
    
    private fun startTranscriptService(context: Context) {
        try {
            // Check if we have overlay permission first
            if (!Settings.canDrawOverlays(context)) {
                Log.w(TAG, "Cannot start transcript service - missing overlay permission")
                return
            }
            
            // Start Dynamic Island overlay service with transcript plugin
            val islandIntent = Intent(context, com.example.uacc.dynamicisland.service.IslandOverlayService::class.java)
            islandIntent.putExtra("action", "startTranscript")
            context.startService(islandIntent)
            
            // Start call transcript service for speech recognition
            val transcriptIntent = Intent(context, CallTranscriptService::class.java)
            transcriptIntent.putExtra("action", "startTranscription")
            context.startService(transcriptIntent)
            
            Log.d(TAG, "🏝️ Started Dynamic Island transcript service for live call transcription")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start Dynamic Island transcript service", e)
        }
    }
    
    private fun stopTranscriptService(context: Context) {
        try {
            // Stop call transcript service
            val transcriptIntent = Intent(context, CallTranscriptService::class.java)
            transcriptIntent.putExtra("action", "stopTranscription")
            context.startService(transcriptIntent)
            
            // Stop Dynamic Island transcript
            val islandIntent = Intent(context, com.example.uacc.dynamicisland.service.IslandOverlayService::class.java)
            islandIntent.putExtra("action", "stopTranscript")
            context.startService(islandIntent)
            
            Log.d(TAG, "🏝️ Stopped Dynamic Island transcript service")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop Dynamic Island transcript service", e)
        }
    }
}