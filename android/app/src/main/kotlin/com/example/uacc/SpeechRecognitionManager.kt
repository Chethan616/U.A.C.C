package com.example.uacc

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.Log
import java.util.*
import kotlin.collections.ArrayList

class SpeechRecognitionManager(private val context: Context) {
    
    companion object {
        private const val TAG = "SpeechRecognitionManager"
        private const val RESTART_DELAY = 1000L // 1 second delay before restarting
        private const val MAX_TRANSCRIPT_LENGTH = 500
    }
    
    private var speechRecognizer: SpeechRecognizer? = null
    private var recognitionIntent: Intent? = null
    private var isListening = false
    private var currentTranscript = StringBuilder()
    private var transcriptCallback: ((String) -> Unit)? = null
    
    // Handler for managing restart delays
    private val mainHandler = Handler(Looper.getMainLooper())
    private var restartRunnable: Runnable? = null
    
    // Audio manager for handling audio focus
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    
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
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1500L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 1500L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 15000L)
        }
        
        Log.d(TAG, "Speech recognizer initialized")
    }
    
    fun startListening(callback: (String) -> Unit) {
        if (isListening) {
            Log.w(TAG, "Already listening")
            return
        }
        
        transcriptCallback = callback
        currentTranscript.clear()
        
        // Request audio focus for call transcription
        val audioFocusResult = audioManager.requestAudioFocus(
            null,
            AudioManager.STREAM_VOICE_CALL,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
        )
        
        if (audioFocusResult != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            Log.w(TAG, "Audio focus not granted, continuing anyway")
        }
        
        startRecognition()
    }
    
    fun stopListening() {
        if (!isListening) return
        
        isListening = false
        cancelRestart()
        
        speechRecognizer?.stopListening()
        
        // Release audio focus
        audioManager.abandonAudioFocus(null)
        
        Log.d(TAG, "Speech recognition stopped")
    }
    
    private fun startRecognition() {
        if (speechRecognizer == null) {
            setupSpeechRecognizer()
        }
        
        try {
            isListening = true
            speechRecognizer?.startListening(recognitionIntent)
            Log.d(TAG, "Started speech recognition")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start speech recognition", e)
            isListening = false
            scheduleRestart()
        }
    }
    
    private fun scheduleRestart() {
        if (!isListening) return // Don't restart if we're not supposed to be listening
        
        cancelRestart()
        
        restartRunnable = Runnable {
            if (isListening) {
                Log.d(TAG, "Restarting speech recognition")
                startRecognition()
            }
        }
        
        mainHandler.postDelayed(restartRunnable!!, RESTART_DELAY)
    }
    
    private fun cancelRestart() {
        restartRunnable?.let { runnable ->
            mainHandler.removeCallbacks(runnable)
            restartRunnable = null
        }
    }
    
    private fun createRecognitionListener(): RecognitionListener {
        return object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                Log.d(TAG, "Ready for speech")
            }
            
            override fun onBeginningOfSpeech() {
                Log.d(TAG, "Beginning of speech")
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
                
                Log.e(TAG, "Speech recognition error: $errorMessage")
                
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
                        if (isListening) scheduleRestart()
                    }
                    else -> {
                        // Network or other errors, restart with delay
                        if (isListening) scheduleRestart()
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
            // Final result - append to transcript
            if (currentTranscript.isNotEmpty()) {
                currentTranscript.append(" ")
            }
            currentTranscript.append(recognizedText)
            
            // Trim transcript if it gets too long
            if (currentTranscript.length > MAX_TRANSCRIPT_LENGTH) {
                val excessLength = currentTranscript.length - MAX_TRANSCRIPT_LENGTH
                currentTranscript.delete(0, excessLength)
            }
        }
        
        // Send current transcript (partial results show immediate feedback)
        val textToSend = if (isPartial) {
            // For partial results, show current transcript + partial text
            if (currentTranscript.isNotEmpty()) {
                "$currentTranscript $recognizedText"
            } else {
                recognizedText
            }
        } else {
            currentTranscript.toString()
        }
        
        transcriptCallback?.invoke(textToSend)
    }
    
    fun getCurrentTranscript(): String {
        return currentTranscript.toString()
    }
    
    fun clearTranscript() {
        currentTranscript.clear()
        transcriptCallback?.invoke("")
    }
    
    fun cleanup() {
        stopListening()
        
        speechRecognizer?.destroy()
        speechRecognizer = null
        
        transcriptCallback = null
        
        Log.d(TAG, "Speech recognition manager cleaned up")
    }
    
    fun isCurrentlyListening(): Boolean {
        return isListening
    }
}