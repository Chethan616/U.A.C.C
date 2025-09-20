package com.example.uacc

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.view.Gravity
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import io.flutter.Log

class CallOverlayService : Service() {
    
    companion object {
        private const val TAG = "CallOverlayService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "call_overlay_channel"
        
        fun startService(context: Context) {
            if (!Settings.canDrawOverlays(context)) {
                Log.e(TAG, "Overlay permission not granted")
                return
            }
            
            val intent = Intent(context, CallOverlayService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, CallOverlayService::class.java)
            context.stopService(intent)
        }
    }
    
    private var windowManager: WindowManager? = null
    private var dynamicIslandView: DynamicIslandView? = null
    private var telephonyManager: TelephonyManager? = null
    private var phoneStateListener: PhoneStateListener? = null
    private var speechRecognitionManager: SpeechRecognitionManager? = null
    private var isCallActive = false
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "CallOverlayService created")
        
        // Initialize managers
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        speechRecognitionManager = SpeechRecognitionManager(this)
        
        // Create notification channel
        createNotificationChannel()
        
        // Set up phone state listener
        setupPhoneStateListener()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "CallOverlayService started")
        
        // Start foreground service
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Check if we can draw overlays
        if (!Settings.canDrawOverlays(this)) {
            Log.e(TAG, "Cannot draw overlays - permission denied")
            stopSelf()
            return START_NOT_STICKY
        }
        
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "CallOverlayService destroyed")
        
        // Remove overlay
        removeOverlay()
        
        // Clean up phone state listener
        telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE)
        
        // Clean up speech recognition
        speechRecognitionManager?.cleanup()
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Call Overlay Service",
                android.app.NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Service for Dynamic Island call transcription"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Dynamic Island Active")
            .setContentText("Call transcription service running")
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    private fun setupPhoneStateListener() {
        phoneStateListener = object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                super.onCallStateChanged(state, phoneNumber)
                
                when (state) {
                    TelephonyManager.CALL_STATE_OFFHOOK -> {
                        // Call is active
                        if (!isCallActive) {
                            Log.d(TAG, "Call started - showing overlay")
                            isCallActive = true
                            showOverlay()
                            startTranscription()
                        }
                    }
                    TelephonyManager.CALL_STATE_IDLE -> {
                        // Call ended
                        if (isCallActive) {
                            Log.d(TAG, "Call ended - hiding overlay")
                            isCallActive = false
                            hideOverlay()
                            stopTranscription()
                        }
                    }
                    TelephonyManager.CALL_STATE_RINGING -> {
                        // Incoming call - don't show overlay yet
                        Log.d(TAG, "Incoming call ringing")
                    }
                }
            }
        }
        
        // Register phone state listener
        try {
            telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
            Log.d(TAG, "Phone state listener registered")
        } catch (e: SecurityException) {
            Log.e(TAG, "Failed to register phone state listener", e)
        }
    }
    
    private fun showOverlay() {
        if (dynamicIslandView != null) return
        
        try {
            // Create Dynamic Island view
            dynamicIslandView = DynamicIslandView(this).apply {
                setOnExpandClickListener {
                    // Handle expand/collapse
                    toggle()
                }
                setOnTranscriptUpdateListener { transcript ->
                    // Send transcript to Flutter via platform channel
                    CallOverlayChannel.sendTranscriptUpdate(transcript)
                }
            }
            
            // Create window layout parameters
            val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                layoutFlag,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                x = 0
                y = 100 // Position from top
            }
            
            // Add view to window manager
            windowManager?.addView(dynamicIslandView, params)
            
            Log.d(TAG, "Dynamic Island overlay shown")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show overlay", e)
            dynamicIslandView = null
        }
    }
    
    private fun hideOverlay() {
        dynamicIslandView?.let { view ->
            try {
                windowManager?.removeView(view)
                dynamicIslandView = null
                Log.d(TAG, "Dynamic Island overlay hidden")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to hide overlay", e)
            }
        }
    }
    
    private fun removeOverlay() {
        hideOverlay()
    }
    
    private fun startTranscription() {
        speechRecognitionManager?.startListening { transcript ->
            // Update Dynamic Island with new transcript
            dynamicIslandView?.updateTranscript(transcript)
            
            // Send to Flutter
            CallOverlayChannel.sendTranscriptUpdate(transcript)
        }
    }
    
    private fun stopTranscription() {
        speechRecognitionManager?.stopListening()
        dynamicIslandView?.clearTranscript()
        CallOverlayChannel.sendTranscriptUpdate("")
    }
}