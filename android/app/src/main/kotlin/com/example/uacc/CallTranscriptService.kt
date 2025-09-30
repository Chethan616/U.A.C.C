package com.example.uacc

import android.app.Service
import android.content.Intent
import android.os.IBinder
import io.flutter.Log

/**
 * Simple service to handle speech recognition and send transcripts to Dynamic Island
 */
class CallTranscriptService : Service() {
    
    companion object {
        private const val TAG = "CallTranscriptService"
    }
    
    private var speechRecognitionManager: SpeechRecognitionManager? = null
    private var isTranscribing = false
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "CallTranscriptService created")
        speechRecognitionManager = SpeechRecognitionManager(this)
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.getStringExtra("action")
        
        when (action) {
            "startTranscription" -> {
                startTranscription()
            }
            "stopTranscription" -> {
                stopTranscription()
            }
        }
        
        return START_NOT_STICKY // Don't restart if killed
    }
    
    private fun startTranscription() {
        if (isTranscribing) return
        
        Log.d(TAG, "Starting call transcription for Dynamic Island")
        
        lastFinalTranscript = null

        speechRecognitionManager?.startListening { transcript, isPartial ->
            // Send transcript directly to Dynamic Island
            sendTranscriptToIsland(transcript, isPartial)
        }
        
        isTranscribing = true
    }
    
    private fun stopTranscription() {
        if (!isTranscribing) return
        
        Log.d(TAG, "Stopping call transcription")
        
        speechRecognitionManager?.stopListening()
        isTranscribing = false
    lastFinalTranscript = null
        
        // Send stop signal to Dynamic Island
        val stopIntent = Intent(this, com.example.uacc.dynamicisland.service.IslandOverlayService::class.java)
        stopIntent.putExtra("action", "stopTranscript")
        startService(stopIntent)
        
        // Stop this service
        stopSelf()
    }
    
    private var lastFinalTranscript: String? = null

    private fun sendTranscriptToIsland(transcript: String, isPartial: Boolean) {
        try {
            if (transcript.isBlank()) {
                Log.d(TAG, "Ignoring blank transcript update")
                return
            }

            if (!isPartial && transcript == lastFinalTranscript) {
                Log.d(TAG, "Ignoring duplicate final transcript")
                return
            }

            if (!isPartial) {
                lastFinalTranscript = transcript
            }

            val intent = Intent(this, com.example.uacc.dynamicisland.service.IslandOverlayService::class.java)
            intent.putExtra("action", "addTranscriptMessage")
            intent.putExtra("text", transcript)
            intent.putExtra("speakerType", "OUTGOING") // Default to outgoing
            intent.putExtra("isPartial", isPartial)
            
            startService(intent)
            val logType = if (isPartial) "Partial" else "Final"
            Log.d(TAG, "Sent $logType transcript to Dynamic Island: ${transcript.take(30)}...")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send transcript to Dynamic Island", e)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "CallTranscriptService destroyed")
        
        speechRecognitionManager?.cleanup()
        speechRecognitionManager = null
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
}