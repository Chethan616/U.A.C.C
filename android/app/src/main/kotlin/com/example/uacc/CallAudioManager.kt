package com.example.uacc

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.telecom.CallAudioState
import android.telephony.TelephonyManager
import io.flutter.Log

/**
 * CallAudioManager handles proper audio routing and session management
 * for accessing call audio during active phone calls.
 * 
 * This manager addresses Android's restrictions on microphone access
 * during phone calls by properly configuring audio sessions and routing.
 */
class CallAudioManager(private val context: Context) {
    
    companion object {
        private const val TAG = "CallAudioManager"
    }
    
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
    
    private var audioFocusRequest: AudioFocusRequest? = null
    private var originalMode: Int = AudioManager.MODE_NORMAL
    private var wasOnSpeaker: Boolean = false
    
    /**
     * Request audio focus and configure audio routing for call transcript
     */
    fun requestCallAudioAccess(): Boolean {
        return try {
            Log.d(TAG, "Requesting call audio access")
            
            // Save original audio state
            originalMode = audioManager.mode
            wasOnSpeaker = audioManager.isSpeakerphoneOn
            
            // Configure audio for call transcription
            configureAudioForTranscription()
            
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request call audio access", e)
            false
        }
    }
    
    /**
     * Release audio focus and restore original audio configuration
     */
    fun releaseCallAudioAccess() {
        try {
            Log.d(TAG, "Releasing call audio access")
            
            // Release audio focus
            releaseAudioFocus()
            
            // Restore original audio configuration
            restoreOriginalAudioConfiguration()
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release call audio access", e)
        }
    }
    
    /**
     * Check if we're currently in a phone call
     */
    fun isInCall(): Boolean {
        return try {
            val callState = telephonyManager.callState
            val isInCall = callState == TelephonyManager.CALL_STATE_OFFHOOK
            Log.d(TAG, "Call state check: $callState, isInCall: $isInCall")
            isInCall
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check call state", e)
            false
        }
    }
    
    /**
     * Configure audio routing optimized for call transcription
     */
    private fun configureAudioForTranscription() {
        try {
            // Request audio focus for call transcription
            requestAudioFocus()
            
            // Configure audio mode for in-call communication
            if (isInCall()) {
                // During a call, set mode to IN_COMMUNICATION for better access
                audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
                
                // Enable speakerphone temporarily to route audio through speaker
                // This allows the microphone to pick up both sides of conversation
                if (!audioManager.isSpeakerphoneOn) {
                    audioManager.isSpeakerphoneOn = true
                    Log.d(TAG, "Enabled speakerphone for better audio capture")
                }
            } else {
                // Not in call, use normal communication mode
                audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
            }
            
            Log.d(TAG, "Audio configured for transcription - Mode: ${audioManager.mode}, Speaker: ${audioManager.isSpeakerphoneOn}")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to configure audio for transcription", e)
        }
    }
    
    /**
     * Request audio focus for call transcription
     */
    private fun requestAudioFocus() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Use AudioFocusRequest for API 26+
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
                
                audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                    .setAudioAttributes(audioAttributes)
                    .setAcceptsDelayedFocusGain(false)
                    .setOnAudioFocusChangeListener { focusChange ->
                        handleAudioFocusChange(focusChange)
                    }
                    .build()
                
                val result = audioManager.requestAudioFocus(audioFocusRequest!!)
                Log.d(TAG, "Audio focus request result: $result")
                
            } else {
                // Legacy audio focus for older Android versions
                val result = audioManager.requestAudioFocus(
                    { focusChange -> handleAudioFocusChange(focusChange) },
                    AudioManager.STREAM_VOICE_CALL,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
                )
                Log.d(TAG, "Legacy audio focus request result: $result")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request audio focus", e)
        }
    }
    
    /**
     * Release audio focus
     */
    private fun releaseAudioFocus() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && audioFocusRequest != null) {
                val result = audioManager.abandonAudioFocusRequest(audioFocusRequest!!)
                Log.d(TAG, "Audio focus release result: $result")
                audioFocusRequest = null
            } else {
                val result = audioManager.abandonAudioFocus(null)
                Log.d(TAG, "Legacy audio focus release result: $result")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release audio focus", e)
        }
    }
    
    /**
     * Handle changes in audio focus
     */
    private fun handleAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT -> {
                Log.d(TAG, "Audio focus gained")
            }
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                Log.d(TAG, "Audio focus lost")
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                Log.d(TAG, "Audio focus lost - can duck")
            }
        }
    }
    
    /**
     * Restore original audio configuration
     */
    private fun restoreOriginalAudioConfiguration() {
        try {
            // Restore original audio mode
            audioManager.mode = originalMode
            
            // Restore speakerphone state only if we changed it
            if (audioManager.isSpeakerphoneOn != wasOnSpeaker) {
                audioManager.isSpeakerphoneOn = wasOnSpeaker
            }
            
            Log.d(TAG, "Audio configuration restored - Mode: ${audioManager.mode}, Speaker: ${audioManager.isSpeakerphoneOn}")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restore audio configuration", e)
        }
    }
    
    /**
     * Get current audio routing information for debugging
     */
    fun getAudioRoutingInfo(): String {
        return try {
            "Mode: ${audioManager.mode}, " +
            "Speaker: ${audioManager.isSpeakerphoneOn}, " +
            "Bluetooth: ${audioManager.isBluetoothScoOn}, " +
            "Wired headset: ${audioManager.isWiredHeadsetOn}, " +
            "Call state: ${telephonyManager.callState}"
        } catch (e: Exception) {
            "Error getting audio info: ${e.message}"
        }
    }
    
    /**
     * Enable/disable speakerphone mode
     */
    fun setSpeakerphoneOn(enabled: Boolean) {
        try {
            audioManager.isSpeakerphoneOn = enabled
            Log.d(TAG, "Speakerphone ${if (enabled) "enabled" else "disabled"}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set speakerphone", e)
        }
    }
    
    /**
     * Check if audio routing is optimal for transcription
     */
    fun isAudioRoutingOptimal(): Boolean {
        return try {
            val mode = audioManager.mode
            val isOptimal = mode == AudioManager.MODE_IN_COMMUNICATION || 
                           mode == AudioManager.MODE_IN_CALL
            
            Log.d(TAG, "Audio routing optimal: $isOptimal (mode: $mode)")
            isOptimal
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check audio routing", e)
            false
        }
    }
}