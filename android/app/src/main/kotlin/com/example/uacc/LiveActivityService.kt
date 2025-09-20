package com.example.uacc

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.os.IBinder
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.Log

class LiveActivityService : Service() {
    
    companion object {
        private const val TAG = "LiveActivityService"
        private const val ONGOING_NOTIFICATION_ID = 2001
        private const val CHANNEL_ID = "call_transcription_channel"
        
        fun startService(context: Context) {
            val intent = Intent(context, LiveActivityService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, LiveActivityService::class.java)
            context.stopService(intent)
        }
    }
    
    private var telephonyManager: TelephonyManager? = null
    private var phoneStateListener: PhoneStateListener? = null
    private var speechRecognitionManager: SpeechRecognitionManager? = null
    private var isCallActive = false
    private var currentTranscript = ""
    private var notificationManager: NotificationManagerCompat? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "LiveActivityService created")
        
        // Initialize managers
        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        speechRecognitionManager = SpeechRecognitionManager(this)
        notificationManager = NotificationManagerCompat.from(this)
        
        // Create notification channel
        createNotificationChannel()
        
        // Set up phone state listener
        setupPhoneStateListener()
        
        // Start as foreground service with initial notification
        try {
            startForeground(ONGOING_NOTIFICATION_ID, createInitialNotification())
        } catch (e: SecurityException) {
            Log.e(TAG, "Failed to start foreground service - missing permissions", e)
            stopSelf()
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "LiveActivityService started")
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "LiveActivityService destroyed")
        
        // Clean up
        telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE)
        speechRecognitionManager?.cleanup()
        
        // Remove ongoing notification
        notificationManager?.cancel(ONGOING_NOTIFICATION_ID)
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Call Transcription",
                android.app.NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Live call transcription like Zomato delivery tracking"
                setShowBadge(false)
                // Important: This makes it appear as ongoing activity like screen recording
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createInitialNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Call Transcription Ready")
            .setContentText("Waiting for phone calls...")
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentIntent(pendingIntent)
            .setOngoing(false) // Not ongoing until call starts
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    private fun setupPhoneStateListener() {
        phoneStateListener = object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                super.onCallStateChanged(state, phoneNumber)
                
                when (state) {
                    TelephonyManager.CALL_STATE_OFFHOOK -> {
                        if (!isCallActive) {
                            Log.d(TAG, "Call started - showing live activity")
                            isCallActive = true
                            showCallTranscriptionActivity()
                            startTranscription()
                        }
                    }
                    TelephonyManager.CALL_STATE_IDLE -> {
                        if (isCallActive) {
                            Log.d(TAG, "Call ended - hiding live activity")
                            isCallActive = false
                            hideCallTranscriptionActivity()
                            stopTranscription()
                        }
                    }
                    TelephonyManager.CALL_STATE_RINGING -> {
                        Log.d(TAG, "Incoming call ringing")
                    }
                }
            }
        }
        
        try {
            telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
            Log.d(TAG, "Phone state listener registered")
        } catch (e: SecurityException) {
            Log.e(TAG, "Failed to register phone state listener", e)
        }
    }
    
    private fun showCallTranscriptionActivity() {
        // This creates the ongoing activity like Zomato delivery or screen recording
        updateNotification(
            title = "📞 Call in Progress",
            text = "🎤 Transcribing...",
            isOngoing = true
        )
    }
    
    private fun hideCallTranscriptionActivity() {
        // Remove the ongoing activity
        updateNotification(
            title = "Call Transcription Ready",
            text = "Waiting for phone calls...",
            isOngoing = false
        )
        currentTranscript = ""
    }
    
    private fun startTranscription() {
        speechRecognitionManager?.startListening { transcript ->
            currentTranscript = transcript
            updateTranscriptionNotification(transcript)
            
            // Send to Flutter
            LiveActivityChannel.sendTranscriptUpdate(transcript)
        }
    }
    
    private fun stopTranscription() {
        speechRecognitionManager?.stopListening()
        currentTranscript = ""
        LiveActivityChannel.sendTranscriptUpdate("")
    }
    
    private fun updateTranscriptionNotification(transcript: String) {
        val displayText = if (transcript.isNotEmpty()) {
            "🗣️ \"${transcript.take(50)}${if (transcript.length > 50) "..." else ""}\""
        } else {
            "🎤 Listening..."
        }
        
        updateNotification(
            title = "📞 Call Transcription",
            text = displayText,
            isOngoing = true
        )
    }
    
    private fun updateNotification(title: String, text: String, isOngoing: Boolean) {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Create custom notification layout
        val customView = RemoteViews(packageName, R.layout.notification_live_activity)
        customView.setTextViewText(R.id.title_text, title)
        customView.setTextViewText(R.id.transcript_text, text)
        
        // Show/hide recording indicator
        customView.setViewVisibility(
            R.id.recording_indicator, 
            if (isOngoing) android.view.View.VISIBLE else android.view.View.GONE
        )
        
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(if (isOngoing) android.R.drawable.ic_media_play else android.R.drawable.ic_menu_call)
            .setContentIntent(pendingIntent)
            .setOngoing(isOngoing) // This makes it appear like Zomato/Screen recording
            .setPriority(if (isOngoing) NotificationCompat.PRIORITY_DEFAULT else NotificationCompat.PRIORITY_LOW)
            .setCategory(if (isOngoing) NotificationCompat.CATEGORY_CALL else NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle()) // Use custom view style
            .setCustomContentView(customView) // Set custom layout
            .apply {
                if (isOngoing && currentTranscript.isNotEmpty()) {
                    // Create expanded custom view for more content
                    val expandedView = RemoteViews(packageName, R.layout.notification_live_activity_expanded)
                    expandedView.setTextViewText(R.id.expanded_transcript_text, currentTranscript)
                    
                    // Set up button click
                    val buttonIntent = PendingIntent.getActivity(
                        this@LiveActivityService, 2, intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    expandedView.setOnClickPendingIntent(R.id.view_in_app_button, buttonIntent)
                    
                    setCustomBigContentView(expandedView)
                }
                
                // Add color tint for ongoing activity (makes it look like system notifications)
                if (isOngoing) {
                    color = resources.getColor(android.R.color.holo_red_dark, null)
                }
            }
            .build()
        
        notificationManager?.notify(ONGOING_NOTIFICATION_ID, notification)
    }
}