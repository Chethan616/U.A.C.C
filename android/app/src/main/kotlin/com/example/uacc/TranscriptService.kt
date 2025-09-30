package com.example.uacc

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import android.widget.LinearLayout
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.LayoutInflater
import androidx.core.app.NotificationCompat
import android.os.Build

class TranscriptService : Service() {
    companion object {
        var instance: TranscriptService? = null
        private const val NOTIFICATION_ID = 12345
        private const val CHANNEL_ID = "TRANSCRIPT_SERVICE_CHANNEL"
    }

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var textView: TextView? = null
    private var googleDataView: LinearLayout? = null
    private var userInfoView: LinearLayout? = null
    
    // Google Workspace data
    private var isSignedInToGoogle = false
    private var userEmail = ""
    private var userName = ""
    private var userPhotoUrl = ""
    private var currentMeetings = mutableListOf<Map<String, Any>>()
    private var upcomingEvents = mutableListOf<Map<String, Any>>()
    private var dueTodayTasks = mutableListOf<Map<String, Any>>()
    private var overdueTasks = mutableListOf<Map<String, Any>>()
    
    private var lastTranscriptUpdate = System.currentTimeMillis()

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        showFloatingView()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "ACTION_STOP") {
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }
        
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    fun startTranscription() {
        // TODO: Implement floating pill functionality
    }

    fun stopTranscription() {
        // TODO: Implement cleanup
        stopSelf()
    }

    fun updateTranscript(text: String) {
        textView?.post {
            textView?.text = "Live: $text"
            lastTranscriptUpdate = System.currentTimeMillis()
            updateFloatingViewVisibility()
        }
    }
    
    fun onGoogleSignIn(email: String, name: String, photoUrl: String) {
        isSignedInToGoogle = true
        userEmail = email
        userName = name
        userPhotoUrl = photoUrl
        
        updateGoogleDataDisplay()
    }
    
    fun onGoogleSignOut() {
        isSignedInToGoogle = false
        userEmail = ""
        userName = ""
        userPhotoUrl = ""
        currentMeetings.clear()
        upcomingEvents.clear()
        dueTodayTasks.clear()
        overdueTasks.clear()
        
        updateGoogleDataDisplay()
    }
    
    fun updateFloatingPillData(data: Map<String, Any>) {
        // Update Google Workspace data
        currentMeetings.clear()
        upcomingEvents.clear()
        dueTodayTasks.clear()
        overdueTasks.clear()
        
        (data["currentMeetings"] as? List<Map<String, Any>>)?.let { 
            currentMeetings.addAll(it) 
        }
        (data["upcomingEvents"] as? List<Map<String, Any>>)?.let { 
            upcomingEvents.addAll(it) 
        }
        (data["dueTodayTasks"] as? List<Map<String, Any>>)?.let { 
            dueTodayTasks.addAll(it) 
        }
        (data["overdueTasks"] as? List<Map<String, Any>>)?.let { 
            overdueTasks.addAll(it) 
        }
        
        updateGoogleDataDisplay()
    }
    
    private fun showFloatingView() {
        try {
            windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            
            // Create floating view layout
            floatingView = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(16, 16, 16, 16)
                setBackgroundResource(android.R.drawable.dialog_holo_dark_frame)
            }
            
            // Add transcript text view
            textView = TextView(this).apply {
                text = "UACC - Floating Pill Ready"
                textSize = 14f
                setTextColor(android.graphics.Color.WHITE)
            }
            (floatingView as LinearLayout).addView(textView)
            
            // Add Google data container
            googleDataView = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                visibility = View.GONE
            }
            (floatingView as LinearLayout).addView(googleDataView)
            
            // Setup window parameters
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.TRANSLUCENT
            )
            
            params.gravity = Gravity.TOP or Gravity.END
            params.x = 50
            params.y = 200
            
            windowManager?.addView(floatingView, params)
        } catch (e: Exception) {
            println("Error showing floating view: ${e.message}")
        }
    }
    
    private fun hideFloatingView() {
        try {
            floatingView?.let { view ->
                windowManager?.removeView(view)
            }
            floatingView = null
            textView = null
            googleDataView = null
        } catch (e: Exception) {
            println("Error hiding floating view: ${e.message}")
        }
    }
    
    private fun updateFloatingViewVisibility() {
        val timeSinceUpdate = System.currentTimeMillis() - lastTranscriptUpdate
        val shouldShow = timeSinceUpdate < 10000 || isSignedInToGoogle // Show for 10 seconds after update or if Google signed in
        
        floatingView?.visibility = if (shouldShow) View.VISIBLE else View.GONE
    }
    
    private fun updateGoogleDataDisplay() {
        googleDataView?.post {
            googleDataView?.removeAllViews()
            
            if (isSignedInToGoogle) {
                // Add user info
                val userText = TextView(this).apply {
                    text = "📧 $userName"
                    textSize = 12f
                    setTextColor(android.graphics.Color.CYAN)
                }
                googleDataView?.addView(userText)
                
                // Add current meetings
                if (currentMeetings.isNotEmpty()) {
                    val meetingText = TextView(this).apply {
                        text = "🔴 Meeting: ${currentMeetings.first()["title"]}"
                        textSize = 12f
                        setTextColor(android.graphics.Color.RED)
                    }
                    googleDataView?.addView(meetingText)
                }
                
                // Add upcoming events
                if (upcomingEvents.isNotEmpty()) {
                    val eventText = TextView(this).apply {
                        text = "📅 Next: ${upcomingEvents.first()["title"]}"
                        textSize = 12f
                        setTextColor(android.graphics.Color.YELLOW)
                    }
                    googleDataView?.addView(eventText)
                }
                
                // Add due tasks
                if (dueTodayTasks.isNotEmpty()) {
                    val taskText = TextView(this).apply {
                        text = "✅ Task: ${dueTodayTasks.first()["title"]}"
                        textSize = 12f
                        setTextColor(android.graphics.Color.GREEN)
                    }
                    googleDataView?.addView(taskText)
                }
                
                // Add overdue tasks
                if (overdueTasks.isNotEmpty()) {
                    val overdueText = TextView(this).apply {
                        text = "⚠️ Overdue: ${overdueTasks.first()["title"]}"
                        textSize = 12f
                        setTextColor(android.graphics.Color.MAGENTA)
                    }
                    googleDataView?.addView(overdueText)
                }
                
                googleDataView?.visibility = View.VISIBLE
            } else {
                googleDataView?.visibility = View.GONE
            }
            
            updateFloatingViewVisibility()
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "UACC Transcript Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Floating transcript and Google Workspace integration"
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("UACC Active")
            .setContentText("Floating pill and Google integration running")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    fun getTranscriptHistory(): List<String> {
        return emptyList()
    }

    override fun onDestroy() {
        super.onDestroy()
        hideFloatingView()
        instance = null
    }
}