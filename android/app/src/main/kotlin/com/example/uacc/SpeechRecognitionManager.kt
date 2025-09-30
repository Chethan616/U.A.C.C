package com.example.uacc

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.Log
import java.util.*
import kotlin.collections.ArrayList

class SpeechRecognitionManager(private val context: Context) {
    
    companion object {
        private const val TAG = "SpeechRecognitionManager"
        private const val MIN_RESTART_DELAY = 1500L
        private const val MAX_RESTART_DELAY = 12000L
        private const val MAX_CONSECUTIVE_RESTARTS = 5
        private const val EXTENDED_COOLDOWN = 8000L
        private const val MAX_TRANSCRIPT_LENGTH = 500
    }
    
    private var speechRecognizer: SpeechRecognizer? = null
    private var recognitionIntent: Intent? = null
    private var isListening = false
    private var currentTranscript = StringBuilder()
    private var transcriptCallback: ((String, Boolean) -> Unit)? = null
    private var lastFinalTranscript: String? = null
    private var consecutiveErrors = 0
    private var restartAttempts = 0
    private var lastResultTimestamp = 0L
    private val systemAudioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var isSystemToneSuppressed = false
    private var priorSystemMuteState: Boolean? = null
    
    // Handler for managing restart delays
    private val mainHandler = Handler(Looper.getMainLooper())
    private var restartRunnable: Runnable? = null
    private val toneRestoreRunnable = Runnable { restoreRecognizerTone() }
    
    // Call audio manager for proper call audio routing
    private val callAudioManager = CallAudioManager(context)
    private var isCallAudioActive = false
    
    init {
        setupSpeechRecognizer()
    }
    
    private fun setupSpeechRecognizer() {
        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            Log.e(TAG, "Speech recognition not available on this device")
            return
        }
        
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
        speechRecognizer?.setRecognitionListener(createRecognitionListener())
        
        // Create recognition intent
        recognitionIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, context.packageName)
            
            // Optimize for call transcription
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 6000L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 6000L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 20000L)
            
            // Enable better call audio recognition
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, false) // Use online for better accuracy
            putExtra("android.speech.extra.EXTRA_ADDITIONAL_LANGUAGES", arrayOf("en-US"))
            putExtra(RecognizerIntent.EXTRA_SECURE, false) // Allow during calls if supported
        }
        
        Log.d(TAG, "Speech recognizer initialized")
    }
    
    fun startListening(callback: (String, Boolean) -> Unit) {
        if (isListening) {
            Log.w(TAG, "Already listening")
            return
        }
        
        transcriptCallback = callback
        currentTranscript.clear()
        lastFinalTranscript = null
        
        // Check if we're in a call and configure audio accordingly
        val inCall = callAudioManager.isInCall()
        Log.d(TAG, "Starting speech recognition - In call: $inCall")
        
        if (inCall) {
            // Request call audio access for in-call transcription
            isCallAudioActive = callAudioManager.requestCallAudioAccess()
            if (isCallAudioActive) {
                Log.d(TAG, "Call audio access granted - ${callAudioManager.getAudioRoutingInfo()}")
            } else {
                Log.w(TAG, "Call audio access denied, proceeding with limited functionality")
            }
        }
        
        startRecognition()
    }
    
    fun stopListening() {
        if (!isListening) return
        
        isListening = false
        cancelRestart()
        
        speechRecognizer?.stopListening()
        restoreRecognizerTone()
        
        // Release call audio access if it was active
        if (isCallAudioActive) {
            callAudioManager.releaseCallAudioAccess()
            isCallAudioActive = false
            Log.d(TAG, "Call audio access released")
        }
        
        Log.d(TAG, "Speech recognition stopped")
    }
    
    private fun startRecognition() {
        if (speechRecognizer == null) {
            setupSpeechRecognizer()
        }
        
        try {
            isListening = true
            suppressRecognizerTone()
            speechRecognizer?.startListening(recognitionIntent)
            Log.d(TAG, "Started speech recognition")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start speech recognition", e)
            isListening = false
            restoreRecognizerTone()
            scheduleRestart()
        }
    }
    
    private fun scheduleRestart(errorCode: Int? = null) {
        if (!isListening) return
        
        cancelRestart()
        
        val now = SystemClock.elapsedRealtime()
    val inCall = callAudioManager.isInCall()

        val backoffFactor = 1L shl minOf(consecutiveErrors, 3)
        val baseDelay = when (errorCode) {
            SpeechRecognizer.ERROR_NO_MATCH -> 2200L
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> 2800L
            SpeechRecognizer.ERROR_NETWORK,
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> 4200L
            null -> 1800L
            else -> 3200L
        }

        var delay = (baseDelay * backoffFactor).coerceIn(MIN_RESTART_DELAY, MAX_RESTART_DELAY)

        if (inCall && errorCode in setOf(SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT)) {
            val timeSinceResult = if (lastResultTimestamp == 0L) Long.MAX_VALUE else now - lastResultTimestamp
            val throttleDelay = if (timeSinceResult > EXTENDED_COOLDOWN) {
                (EXTENDED_COOLDOWN + consecutiveErrors * 2000L).coerceAtMost(MAX_RESTART_DELAY * 2)
            } else {
                EXTENDED_COOLDOWN
            }
            delay = maxOf(delay, throttleDelay)
            Log.d(TAG, "Call active; throttling restart to ${delay}ms (last result ${timeSinceResult}ms ago)")
        }

        if (restartAttempts >= MAX_CONSECUTIVE_RESTARTS) {
            delay = maxOf(delay, EXTENDED_COOLDOWN)
            Log.w(TAG, "Too many restarts in succession. Applying cooldown of ${delay}ms")
            restartAttempts = 0
        }

        restartAttempts++

        restartRunnable = Runnable {
            if (isListening) {
                Log.d(TAG, "Restarting speech recognition after ${delay}ms (error=$errorCode)")
                startRecognition()
            }
        }

        mainHandler.postDelayed(restartRunnable!!, delay)
    }
    
    private fun cancelRestart() {
        restartRunnable?.let { runnable ->
            mainHandler.removeCallbacks(runnable)
            restartRunnable = null
        }
    }

    private fun suppressRecognizerTone() {
        if (isSystemToneSuppressed) return
        try {
            priorSystemMuteState = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                systemAudioManager.isStreamMute(AudioManager.STREAM_SYSTEM)
            } else {
                null
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                systemAudioManager.adjustStreamVolume(
                    AudioManager.STREAM_SYSTEM,
                    AudioManager.ADJUST_MUTE,
                    AudioManager.FLAG_REMOVE_SOUND_AND_VIBRATE
                )
            } else {
                @Suppress("DEPRECATION")
                systemAudioManager.setStreamMute(AudioManager.STREAM_SYSTEM, true)
            }

            isSystemToneSuppressed = true
            mainHandler.removeCallbacks(toneRestoreRunnable)
            mainHandler.postDelayed(toneRestoreRunnable, 7000L)
        } catch (e: Exception) {
            Log.w(TAG, "Unable to mute system tone", e)
        }
    }

    private fun restoreRecognizerTone() {
        if (!isSystemToneSuppressed) return
        try {
            mainHandler.removeCallbacks(toneRestoreRunnable)

            val shouldUnmute = priorSystemMuteState?.let { !it } ?: true

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (shouldUnmute) {
                    systemAudioManager.adjustStreamVolume(
                        AudioManager.STREAM_SYSTEM,
                        AudioManager.ADJUST_UNMUTE,
                        0
                    )
                }
            } else {
                @Suppress("DEPRECATION")
                systemAudioManager.setStreamMute(AudioManager.STREAM_SYSTEM, false)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Unable to restore system tone", e)
        } finally {
            priorSystemMuteState = null
            isSystemToneSuppressed = false
        }
    }
    
    private fun createRecognitionListener(): RecognitionListener {
        return object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                val routingInfo = callAudioManager.getAudioRoutingInfo()
                Log.d(TAG, "Ready for speech - Audio routing: $routingInfo")
                restoreRecognizerTone()
            }
            
            override fun onBeginningOfSpeech() {
                Log.d(TAG, "Beginning of speech detected")
                
                // Verify audio routing is optimal for call transcription
                if (isCallAudioActive && !callAudioManager.isAudioRoutingOptimal()) {
                    Log.w(TAG, "Audio routing may not be optimal for call transcription")
                }
            }
            
            override fun onRmsChanged(rmsdB: Float) {
                // Audio level changed - could be used for visualization
            }
            
            override fun onBufferReceived(buffer: ByteArray?) {
                // Audio buffer received
            }
            
            override fun onEndOfSpeech() {
                Log.d(TAG, "End of speech")
            }
            
            override fun onError(error: Int) {
                val errorMessage = when (error) {
                    SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                    SpeechRecognizer.ERROR_CLIENT -> "Client side error"
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                    SpeechRecognizer.ERROR_NETWORK -> "Network error"
                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                    SpeechRecognizer.ERROR_NO_MATCH -> "No speech match"
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
                    SpeechRecognizer.ERROR_SERVER -> "Server error"
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Speech timeout"
                    else -> "Unknown error ($error)"
                }
                
                // Add call-specific context to error logging
                val inCall = callAudioManager.isInCall()
                val audioInfo = if (isCallAudioActive) callAudioManager.getAudioRoutingInfo() else "No call audio"
                
                Log.e(TAG, "Speech recognition error: $errorMessage (In call: $inCall, Audio: $audioInfo)")
                restoreRecognizerTone()
                consecutiveErrors++
                
                // Handle call-specific audio errors
                when (error) {
                    SpeechRecognizer.ERROR_AUDIO -> {
                        if (inCall && isCallAudioActive) {
                            Log.w(TAG, "Audio error during call - attempting audio routing fix")
                            // Try to re-establish call audio access
                            callAudioManager.releaseCallAudioAccess()
                            isCallAudioActive = callAudioManager.requestCallAudioAccess()
                        }
                    }
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> {
                        Log.e(TAG, "Microphone permission denied - check app permissions")
                        isListening = false
                        return
                    }
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> {
                        Log.w(TAG, "Speech recognizer busy - will retry")
                        isListening = false
                        return
                    }
                }
                
                // Don't restart on certain errors
                when (error) {
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS,
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> {
                        // Stop listening on permission or busy errors
                        isListening = false
                    }
                    SpeechRecognizer.ERROR_NO_MATCH,
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> {
                        // These are normal, restart immediately
                        if (isListening) scheduleRestart(error)
                    }
                    else -> {
                        // Network or other errors, restart with delay
                        if (isListening) scheduleRestart(error)
                    }
                }
            }
            
            override fun onResults(results: Bundle?) {
                handleRecognitionResults(results, false)
                
                // Automatically restart for continuous listening
                if (isListening) {
                    scheduleRestart()
                }
            }
            
            override fun onPartialResults(results: Bundle?) {
                handleRecognitionResults(results, true)
            }
            
            override fun onEvent(eventType: Int, params: Bundle?) {
                Log.d(TAG, "Speech recognition event: $eventType")
            }
        }
    }
    
    private fun handleRecognitionResults(results: Bundle?, isPartial: Boolean) {
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (matches.isNullOrEmpty()) return
        
        val recognizedText = matches[0]
        if (recognizedText.isBlank()) return
        
        Log.d(TAG, if (isPartial) "Partial result: $recognizedText" else "Final result: $recognizedText")
        if (!isPartial) {
            consecutiveErrors = 0
            restartAttempts = 0
            restoreRecognizerTone()
        }
        lastResultTimestamp = SystemClock.elapsedRealtime()
        
        if (!isPartial) {
            if (recognizedText == lastFinalTranscript) {
                Log.d(TAG, "Duplicate final result ignored")
                return
            }
            lastFinalTranscript = recognizedText
            if (currentTranscript.isNotEmpty()) {
                currentTranscript.append(" ")
            }
            currentTranscript.append(recognizedText)

            if (currentTranscript.length > MAX_TRANSCRIPT_LENGTH) {
                val excessLength = currentTranscript.length - MAX_TRANSCRIPT_LENGTH
                currentTranscript.delete(0, excessLength)
            }
        }

        val textToSend = if (isPartial) recognizedText else recognizedText
        transcriptCallback?.invoke(textToSend, isPartial)
    }
    
    fun getCurrentTranscript(): String {
        return currentTranscript.toString()
    }
    
    fun clearTranscript() {
        currentTranscript.clear()
        lastFinalTranscript = null
        transcriptCallback?.invoke("", true)
    }
    
    fun cleanup() {
        stopListening()
        
        speechRecognizer?.destroy()
        speechRecognizer = null
        
        // Clean up call audio resources
        if (isCallAudioActive) {
            callAudioManager.releaseCallAudioAccess()
            isCallAudioActive = false
        }
        
        transcriptCallback = null
        lastFinalTranscript = null
        consecutiveErrors = 0
        restartAttempts = 0
        lastResultTimestamp = 0L
        restoreRecognizerTone()
        
        Log.d(TAG, "Speech recognition manager cleaned up")
    }
    
    /**
     * Get current audio status for debugging
     */
    fun getAudioStatus(): String {
        return "Listening: $isListening, Call audio active: $isCallAudioActive, " +
               "In call: ${callAudioManager.isInCall()}, ${callAudioManager.getAudioRoutingInfo()}"
    }
    
    /**
     * Force audio reconfiguration (useful when call state changes)
     */
    fun reconfigureAudio() {
        if (isListening) {
            val inCall = callAudioManager.isInCall()
            Log.d(TAG, "Reconfiguring audio - In call: $inCall")
            
            if (inCall && !isCallAudioActive) {
                // We're now in a call but don't have call audio access
                isCallAudioActive = callAudioManager.requestCallAudioAccess()
                Log.d(TAG, "Requested call audio access: $isCallAudioActive")
            } else if (!inCall && isCallAudioActive) {
                // Call ended, release call audio access
                callAudioManager.releaseCallAudioAccess()
                isCallAudioActive = false
                Log.d(TAG, "Released call audio access (call ended)")
            }
        }
    }
    
    fun isCurrentlyListening(): Boolean {
        return isListening
    }
}