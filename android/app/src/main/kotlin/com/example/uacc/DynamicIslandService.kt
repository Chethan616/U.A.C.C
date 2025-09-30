package com.example.uacc

import android.animation.ValueAnimator
import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.*
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.core.app.NotificationCompat

class DynamicIslandService : Service() {
    
    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: FrameLayout
    private lateinit var pillContainer: FrameLayout
    private lateinit var contentLayout: LinearLayout
    private lateinit var iconView: ImageView
    private lateinit var textView: TextView
    
    private var expanded = false
    private var currentAnimator: ValueAnimator? = null
    private var jiggleAnimator: ValueAnimator? = null
    
    // Animation parameters (initialized in onCreate to avoid using resources before context is ready)
    private var collapsedWidth: Int = 0
    private var expandedWidth: Int = 0
    private var pillHeight: Int = 0
    private var cornerRadius: Int = 0
    
    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "dynamic_island_channel"
        private const val ANIMATION_DURATION_MS = 450L // iOS-like smooth duration
    }

    override fun onCreate() {
        super.onCreate()
        // Initialize dp-based sizes here — resources are available after onCreate
        collapsedWidth = dpToPx(120)
        expandedWidth = dpToPx(320)
        pillHeight = dpToPx(54)
        cornerRadius = dpToPx(27f)
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        createFloatingView()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createForegroundNotification()
        try {
            startForeground(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            android.util.Log.w("DynamicIslandService", "startForeground failed: ${'$'}{e.message}")
            e.printStackTrace()
            // If startForeground fails, avoid crashing the host app — stop service gracefully
            stopSelf()
            return START_NOT_STICKY
        }

        // Handle intents
        intent?.let { handleIntent(it) }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                // Use reflection to avoid compile-time dependency on NotificationChannel symbols
                val LOG_TAG = "DynamicIslandService:Reflection"
                val nmObj = getSystemService(Context.NOTIFICATION_SERVICE)
                if (nmObj == null) {
                    android.util.Log.w(LOG_TAG, "NotificationManager is null, cannot create channel")
                    return
                }

                // Resolve NotificationChannel class and ctor
                val channelCls = try {
                    Class.forName("android.app.NotificationChannel")
                } catch (cnfe: ClassNotFoundException) {
                    android.util.Log.w(LOG_TAG, "NotificationChannel class not found: ${cnfe.message}")
                    null
                }

                if (channelCls == null) {
                    // No NotificationChannel runtime class available (very old device?) - nothing to do
                    android.util.Log.w(LOG_TAG, "NotificationChannel class unavailable, skipping channel creation")
                    return
                }

                val ctor = try {
                    channelCls.getConstructor(String::class.java, CharSequence::class.java, Int::class.javaPrimitiveType)
                } catch (e: Exception) {
                    android.util.Log.w(LOG_TAG, "NotificationChannel constructor not found: ${e.message}")
                    null
                }

                if (ctor == null) {
                    android.util.Log.w(LOG_TAG, "Unable to obtain NotificationChannel constructor, skipping channel creation")
                    return
                }

                // IMPORTANCE_LOW is 2
                val channel = try {
                    ctor.newInstance(CHANNEL_ID, "Dynamic Island", 2)
                } catch (e: Exception) {
                    android.util.Log.w(LOG_TAG, "Failed to instantiate NotificationChannel: ${e.message}")
                    e.printStackTrace()
                    null
                }

                if (channel == null) {
                    android.util.Log.w(LOG_TAG, "Channel instance is null, aborting reflective createNotificationChannel")
                    return
                }

                // Find createNotificationChannel method on the NotificationManager instance class
                try {
                    val nmClass = nmObj.javaClass
                    val createMethod = try {
                        nmClass.getMethod("createNotificationChannel", channelCls)
                    } catch (nsme: NoSuchMethodException) {
                        android.util.Log.i(LOG_TAG, "createNotificationChannel not found on ${nmClass.name}: ${nsme.message}")
                        null
                    }

                    if (createMethod != null) {
                        android.util.Log.i(LOG_TAG, "Invoking createNotificationChannel on ${nmClass.name} - method=$createMethod")
                        try {
                            createMethod.invoke(nmObj, channel)
                            android.util.Log.i(LOG_TAG, "createNotificationChannel invoked successfully on ${nmClass.name}")
                        } catch (invEx: Exception) {
                            android.util.Log.w(LOG_TAG, "Invocation of createNotificationChannel failed: ${invEx.message}")
                            invEx.printStackTrace()
                        }
                    } else {
                        // If method isn't found on the concrete class, try the NotificationManager base class
                        try {
                            val notifManagerCls = Class.forName("android.app.NotificationManager")
                            val baseCreateMethod = try {
                                notifManagerCls.getMethod("createNotificationChannel", channelCls)
                            } catch (e: Exception) {
                                android.util.Log.w(LOG_TAG, "createNotificationChannel not found on NotificationManager base class: ${e.message}")
                                null
                            }

                            if (baseCreateMethod != null) {
                                android.util.Log.i(LOG_TAG, "Invoking createNotificationChannel on NotificationManager base class - method=$baseCreateMethod")
                                try {
                                    baseCreateMethod.invoke(nmObj, channel)
                                    android.util.Log.i(LOG_TAG, "createNotificationChannel invoked successfully via base class")
                                } catch (invEx: Exception) {
                                    android.util.Log.w(LOG_TAG, "Invocation via base class failed: ${invEx.message}")
                                    invEx.printStackTrace()
                                }
                            } else {
                                android.util.Log.w(LOG_TAG, "createNotificationChannel method not found via reflection on any candidate class")
                            }
                        } catch (inner2: Exception) {
                            android.util.Log.w(LOG_TAG, "Failed to invoke createNotificationChannel reflectively: ${inner2.message}")
                            inner2.printStackTrace()
                        }
                    }
                } catch (inner: Exception) {
                    android.util.Log.w(LOG_TAG, "Unexpected error during reflective channel creation: ${inner.message}")
                    inner.printStackTrace()
                }
            } catch (e: Exception) {
                android.util.Log.w("DynamicIslandService", "createNotificationChannel reflection failed: ${e.message}")
                e.printStackTrace()
            }
        }
    }

    private fun createForegroundNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Dynamic Island Active")
            .setContentText("Providing live activities and notifications")
            .setSmallIcon(android.R.drawable.ic_notification_overlay)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .build()
    }

    private fun createFloatingView() {
        // Main container with glassmorphism effect
        floatingView = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                collapsedWidth,
                pillHeight
            )
            setBackgroundColor(Color.TRANSPARENT)
            
            // Apply blur effect for Android 12+ (API 31+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                setRenderEffect(
                    RenderEffect.createBlurEffect(
                        15f, 15f, Shader.TileMode.CLAMP
                    )
                )
            }
        }
        
        // Glass background layer - semi-transparent with gradient
        val glassBackground = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            background = createGlassmorphismBackground()
            
            // Add subtle elevation shadow
            elevation = dpToPx(8).toFloat()
            
            // Ensure rounded corners are clipped
            outlineProvider = ViewOutlineProvider.BACKGROUND
            clipToOutline = true
        }
        
        // Pill container with enhanced glass effect
        pillContainer = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            // Inner glass layer for depth
            background = createInnerGlassEffect()
            setPadding(dpToPx(2), dpToPx(2), dpToPx(2), dpToPx(2))
        }
        
        // Content layout
        contentLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            setPadding(dpToPx(12), dpToPx(6), dpToPx(12), dpToPx(6))
            
            // Subtle inner glow for content
            background = createContentGlow()
        }
        
        // Icon with enhanced styling
        iconView = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                dpToPx(24), dpToPx(24)
            ).apply {
                marginEnd = dpToPx(8)
            }
            setImageResource(android.R.drawable.ic_menu_call)
            scaleType = ImageView.ScaleType.CENTER_INSIDE
            
            // Add subtle shadow to icon
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                outlineAmbientShadowColor = Color.BLACK
                outlineSpotShadowColor = Color.BLACK
            }
        }
        
        // Text with glass effect styling
        textView = TextView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f
            )
            textSize = 14f
            setTextColor(Color.WHITE)
            text = "Live Activity"
            maxLines = 1
            gravity = Gravity.CENTER_VERTICAL
            
            // Add text shadow for glass effect
            setShadowLayer(4f, 0f, 2f, Color.argb(80, 0, 0, 0))
        }
        
        // Assemble the glass hierarchy
        contentLayout.addView(iconView)
        contentLayout.addView(textView)
        pillContainer.addView(contentLayout)
        glassBackground.addView(pillContainer)
        floatingView.addView(glassBackground)
        
        // Window parameters with proper transparency
        val params = WindowManager.LayoutParams(
            collapsedWidth,
            pillHeight,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED, // Enable hardware acceleration for blur
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = dpToPx(50)
        }
        
        // Add touch handling
        setupTouchHandling()
        
        // Add to window manager
        windowManager.addView(floatingView, params)
    }
    
    private fun createGlassmorphismBackground(): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = this@DynamicIslandService.cornerRadius.toFloat()
            
            // iOS-like glass gradient with proper transparency
            colors = intArrayOf(
                Color.argb(120, 255, 255, 255),  // Light transparent white at top
                Color.argb(80, 200, 200, 200),   // Medium gray-white
                Color.argb(60, 100, 100, 100),   // Darker toward middle
                Color.argb(140, 40, 40, 50)      // Dark transparent base
            )
            orientation = GradientDrawable.Orientation.TOP_BOTTOM
            
            // Subtle border for glass rim effect
            setStroke(dpToPx(1), Color.argb(100, 255, 255, 255))
        }
    }

    private fun createInnerGlassEffect(): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = (this@DynamicIslandService.cornerRadius - 2).toFloat()
            
            // Inner glass layer for depth
            colors = intArrayOf(
                Color.argb(60, 255, 255, 255),   // Inner highlight
                Color.argb(20, 255, 255, 255),   // Fade to transparent
                Color.argb(10, 0, 0, 0),         // Subtle dark
                Color.argb(40, 0, 0, 0)          // Bottom shadow
            )
            orientation = GradientDrawable.Orientation.TOP_BOTTOM
            
            // Inner border for glass depth
            setStroke(1, Color.argb(60, 255, 255, 255))
        }
    }

    private fun createContentGlow(): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = (this@DynamicIslandService.cornerRadius - 4).toFloat()
            
            // Subtle content glow
            colors = intArrayOf(
                Color.argb(20, 255, 255, 255),   // Top glow
                Color.argb(5, 255, 255, 255),    // Center fade
                Color.TRANSPARENT,                // Bottom transparent
                Color.TRANSPARENT
            )
            orientation = GradientDrawable.Orientation.TOP_BOTTOM
        }
    }

    private fun setupTouchHandling() {
        var initialX = 0f
        var initialY = 0f
        var initialTouchX = 0f
        var initialTouchY = 0f
        var startClickTime = 0L
        
        floatingView.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = floatingView.x
                    initialY = floatingView.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    startClickTime = System.currentTimeMillis()
                    true
                }
                
                MotionEvent.ACTION_UP -> {
                    val clickDuration = System.currentTimeMillis() - startClickTime
                    val deltaX = kotlin.math.abs(event.rawX - initialTouchX)
                    val deltaY = kotlin.math.abs(event.rawY - initialTouchY)
                    
                    if (clickDuration < 200 && deltaX < 10 && deltaY < 10) {
                        // Handle tap
                        onPillTapped()
                    }
                    true
                }
                
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = event.rawX - initialTouchX
                    val deltaY = event.rawY - initialTouchY
                    
                    val params = floatingView.layoutParams as WindowManager.LayoutParams
                    params.x = (initialX + deltaX).toInt()
                    params.y = (initialY + deltaY).toInt()
                    windowManager.updateViewLayout(floatingView, params)
                    true
                }
                
                else -> false
            }
        }
    }
    
    private fun onPillTapped() {
        // Toggle expansion
        expanded = !expanded
        animateToState(expanded)
        
        // Additional subtle jiggle for user feedback
        Handler(Looper.getMainLooper()).postDelayed({
            triggerLiquidJiggle()
        }, 100) // Slight delay for natural feel
    }
    
    private fun animateToState(expand: Boolean) {
        val startWidth = if (expand) collapsedWidth else expandedWidth
        val endWidth = if (expand) expandedWidth else collapsedWidth
        
        currentAnimator?.cancel()
        currentAnimator = ValueAnimator.ofInt(startWidth, endWidth).apply {
            duration = ANIMATION_DURATION_MS
            // iOS-like smooth easing instead of bounce
            interpolator = DecelerateInterpolator(1.5f)
            
            addUpdateListener { animator ->
                val width = animator.animatedValue as Int
                val params = floatingView.layoutParams as WindowManager.LayoutParams
                params.width = width
                windowManager.updateViewLayout(floatingView, params)
            }
            
            start()
        }
        
        // Add subtle jiggle effect during expansion/collapse
        triggerLiquidJiggle()
    }

    private fun triggerLiquidJiggle() {
        jiggleAnimator?.cancel()
        
        // Create subtle liquid jiggle with scaleX stretch and inverse scaleY compression
        jiggleAnimator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 350L // Slightly faster than main animation
            interpolator = DecelerateInterpolator(2.0f)
            
            addUpdateListener { animator ->
                val progress = animator.animatedValue as Float
                val jigglePhase = kotlin.math.sin(progress * kotlin.math.PI.toFloat()).toFloat()
                
                // Subtle scaleX stretch (1.03 max) and inverse scaleY compression (0.97 min)
                val scaleX = 1f + (jigglePhase * 0.03f)  // 3% stretch maximum
                val scaleY = 1f - (jigglePhase * 0.03f)  // 3% compression maximum
                
                // Apply the liquid jiggle transformation
                floatingView.scaleX = scaleX
                floatingView.scaleY = scaleY
                
                // Add subtle rotation for more liquid feel (very minimal)
                floatingView.rotation = jigglePhase * 0.5f  // 0.5 degree max rotation
            }
            
            addListener(object : android.animation.Animator.AnimatorListener {
                override fun onAnimationStart(animation: android.animation.Animator) {}
                override fun onAnimationCancel(animation: android.animation.Animator) {}
                override fun onAnimationRepeat(animation: android.animation.Animator) {}
                override fun onAnimationEnd(animation: android.animation.Animator) {
                    // Reset to original state smoothly
                    floatingView.animate()
                        .scaleX(1f)
                        .scaleY(1f)
                        .rotation(0f)
                        .setDuration(100)
                        .start()
                }
            })
            
            start()
        }
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.getStringExtra("action") ?: return
        
        when (action) {
            "show" -> {
                val text = intent.getStringExtra("text") ?: "Dynamic Island"
                showWithText(text)
            }
            
            "showIncomingCall" -> {
                val callerName = intent.getStringExtra("callerName") ?: "Unknown"
                val callerNumber = intent.getStringExtra("callerNumber") ?: ""
                showIncomingCall(callerName, callerNumber)
            }
            
            "showOngoingCall" -> {
                val callerName = intent.getStringExtra("callerName") ?: "Unknown"
                val duration = intent.getStringExtra("duration") ?: "00:00"
                showOngoingCall(callerName, duration)
            }
            
            "showLiveTranscript" -> {
                val transcript = intent.getStringExtra("transcript") ?: ""
                val speaker = intent.getStringExtra("speaker") ?: "Unknown"
                showLiveTranscript(transcript, speaker)
            }
            
            "updateText" -> {
                val text = intent.getStringExtra("text") ?: ""
                updateText(text)
            }
            
            "hide" -> {
                hide()
            }
        }
    }
    
    private fun showWithText(text: String) {
        textView.text = text
        iconView.setImageResource(android.R.drawable.ic_dialog_info)
        makeVisible()
    }
    
    private fun showIncomingCall(callerName: String, callerNumber: String) {
        val displayText = if (callerNumber.isNotEmpty()) "$callerName\n$callerNumber" else callerName
        textView.text = displayText
        textView.maxLines = 2
        iconView.setImageResource(android.R.drawable.ic_menu_call)
        
        // Auto-expand for incoming calls
        expanded = true
        animateToState(true)
        makeVisible()
    }
    
    private fun showOngoingCall(callerName: String, duration: String) {
        textView.text = "$callerName\n$duration"
        textView.maxLines = 2
        iconView.setImageResource(android.R.drawable.ic_menu_call)
        makeVisible()
    }
    
    private fun showLiveTranscript(transcript: String, speaker: String) {
        textView.text = "$speaker\n$transcript"
        textView.maxLines = 3
        iconView.setImageResource(android.R.drawable.ic_btn_speak_now)
        
        // Auto-expand for transcripts
        expanded = true
        animateToState(true)
        makeVisible()
    }
    
    private fun updateText(text: String) {
        textView.text = text
    }
    
    private fun makeVisible() {
        floatingView.visibility = View.VISIBLE
        floatingView.alpha = 1f
    }
    
    private fun hide() {
        // Animate out and stop service
        floatingView.animate()
            .alpha(0f)
            .scaleX(0.8f)
            .scaleY(0.8f)
            .setDuration(300)
            .withEndAction {
                try {
                    windowManager.removeView(floatingView)
                } catch (e: Exception) {
                    // View already removed
                }
                stopSelf()
            }
            .start()
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            currentAnimator?.cancel()
            jiggleAnimator?.cancel()
            windowManager.removeView(floatingView)
        } catch (e: Exception) {
            // View already removed or service destroyed
        }
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }

    private fun dpToPx(dp: Float): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }
}