package com.example.uacc

import android.accessibilityservice.AccessibilityService
import android.animation.Animator
import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat

/**
 * MaterialYou Dynamic Island Service using Native Views
 * Creates perfect pill shape with proper rounded corners using custom drawable
 */
class MaterialYouDynamicIslandNativeService : AccessibilityService() {
    
    companion object {
        const val TAG = "MaterialYouDynamicIsland"
        const val OVERLAY_DURATION = 3000L // 3 seconds
        private var instance: MaterialYouDynamicIslandNativeService? = null
        fun getInstance(): MaterialYouDynamicIslandNativeService? = instance
    }

    private lateinit var windowManager: WindowManager
    private var currentOverlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    
    // Dynamic Island states
    private enum class IslandState { CLOSED, OPENED }
    private var currentState = IslandState.CLOSED
    
    // Dimensions (in DP)
    private val closedWidth = 126 // Exact MaterialYou width
    private val closedHeight = 37  // Exact MaterialYou height  
    private val openedWidth = 358  // Exact MaterialYou expanded width
    private val openedHeight = 84  // Exact MaterialYou expanded height
    
    // Colors - Material You Dynamic theming
    private val backgroundColor = Color.parseColor("#1C1C1E") // Dark background
    private val textColor = Color.WHITE
    private val accentColor = Color.parseColor("#007AFF") // iOS blue accent

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        
        registerCallStateReceiver()
        Log.d(TAG, "MaterialYou Dynamic Island Native Service Connected")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        hideCurrentOverlay()
        try {
            unregisterReceiver(callStateReceiver)
        } catch (e: Exception) {
            // Receiver was not registered
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Handle accessibility events if needed
    }

    override fun onInterrupt() {
        // Handle service interruptions
    }

    // Call state receiver
    private val callStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                "CALL_STATE_CHANGED" -> {
                    val callState = intent.getStringExtra("callState") ?: ""
                    val phoneNumber = intent.getStringExtra("phoneNumber")
                    val callerName = intent.getStringExtra("callerName")
                    
                    when (callState) {
                        "INCOMING" -> {
                            showDynamicIsland(
                                "call",
                                "Incoming Call",
                                callerName ?: phoneNumber ?: "Unknown"
                            )
                        }
                        "OUTGOING" -> {
                            showDynamicIsland(
                                "call", 
                                "Calling",
                                callerName ?: phoneNumber ?: "Unknown"
                            )
                        }
                        "ACTIVE" -> {
                            showDynamicIsland(
                                "call",
                                "Call Active", 
                                callerName ?: phoneNumber ?: "Unknown"
                            )
                        }
                    }
                }
                "NOTIFICATION_POSTED" -> {
                    val title = intent.getStringExtra("title") ?: ""
                    val content = intent.getStringExtra("content") ?: ""
                    showDynamicIsland("notification", title, content)
                }
            }
        }
    }

    private fun registerCallStateReceiver() {
        val filter = IntentFilter().apply {
            addAction("CALL_STATE_CHANGED")
            addAction("NOTIFICATION_POSTED")
        }
        
        // Use RECEIVER_NOT_EXPORTED for internal broadcasts
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(callStateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(callStateReceiver, filter)
        }
    }

    /**
     * Show Dynamic Island with perfect pill shape
     */
    private fun showDynamicIsland(type: String, title: String, content: String) {
        Log.d(TAG, "Showing Dynamic Island: type=$type, title=$title, content=$content")
        
        hideCurrentOverlay()
        
        try {
            val layoutFlags = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY or
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
            
            val layoutParams = WindowManager.LayoutParams(
                dpToPx(closedWidth),
                dpToPx(closedHeight),
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                layoutFlags,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                y = dpToPx(20)
            }
            
            // Create the Dynamic Island view
            val islandView = createDynamicIslandView(type, title, content)
            
            Log.d(TAG, "Dynamic Island native overlay created")
            windowManager.addView(islandView, layoutParams)
            currentOverlayView = islandView
            
            // Animate to expanded state
            animateToExpanded(islandView, type, title, content)
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create native overlay", e)
        }
    }

    /**
     * Create the Dynamic Island view with perfect pill shape
     */
    private fun createDynamicIslandView(type: String, title: String, content: String): View {
        val container = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        
        // Main island background with perfect pill shape
        val islandBackground = View(this).apply {
            id = View.generateViewId()
            background = createPillDrawable(backgroundColor)
            elevation = dpToPx(8).toFloat()
        }
        
        container.addView(islandBackground, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))
        
        return container
    }

    /**
     * Create perfect pill-shaped drawable - matches MaterialYou exactly
     */
    private fun createPillDrawable(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            setColor(color)
            // Set corner radius to half the height for perfect pill shape
            // This is the key to achieving the proper pill appearance
            cornerRadius = dpToPx(closedHeight / 2).toFloat()
            
            // Add subtle gradient for MaterialYou effect
            gradientType = GradientDrawable.LINEAR_GRADIENT
            orientation = GradientDrawable.Orientation.TOP_BOTTOM
            val darkColor = manipulateColor(color, 0.9f)
            val lightColor = manipulateColor(color, 1.1f)
            colors = intArrayOf(lightColor, color, darkColor)
            
            // Add subtle stroke for definition
            setStroke(dpToPx(1), manipulateColor(color, 1.2f))
        }
    }

    /**
     * Animate to expanded state with proper pill shape maintained
     */
    private fun animateToExpanded(view: View, type: String, title: String, content: String) {
        currentState = IslandState.OPENED
        
        // Get layout params
        val layoutParams = view.layoutParams as WindowManager.LayoutParams
        val background = view.findViewById<View>(view.id)
        
        // Animate dimensions
        val widthAnimator = ValueAnimator.ofInt(dpToPx(closedWidth), dpToPx(openedWidth))
        val heightAnimator = ValueAnimator.ofInt(dpToPx(closedHeight), dpToPx(openedHeight))
        
        widthAnimator.addUpdateListener { animator ->
            layoutParams.width = animator.animatedValue as Int
            windowManager.updateViewLayout(view, layoutParams)
            
            // Update corner radius to maintain pill shape
            val currentWidth = animator.animatedValue as Int
            val currentHeight = layoutParams.height
            val cornerRadius = minOf(currentWidth, currentHeight) / 2f
            
            (background.background as? GradientDrawable)?.cornerRadius = cornerRadius
        }
        
        heightAnimator.addUpdateListener { animator ->
            layoutParams.height = animator.animatedValue as Int
            windowManager.updateViewLayout(view, layoutParams)
            
            // Update corner radius to maintain pill shape
            val currentWidth = layoutParams.width
            val currentHeight = animator.animatedValue as Int
            val cornerRadius = minOf(currentWidth, currentHeight) / 2f
            
            (background.background as? GradientDrawable)?.cornerRadius = cornerRadius
        }
        
        // Add content when expanded
        heightAnimator.addUpdateListener { animator ->
            if (animator.animatedFraction > 0.5f && (view as FrameLayout).childCount == 1) {
                addExpandedContent(view as FrameLayout, type, title, content)
            }
        }
        
        val animatorSet = AnimatorSet().apply {
            playTogether(widthAnimator, heightAnimator)
            duration = 600 // MaterialYou animation duration
            interpolator = DecelerateInterpolator()
        }
        
        animatorSet.addListener(object : Animator.AnimatorListener {
            override fun onAnimationStart(animation: Animator) {}
            override fun onAnimationEnd(animation: Animator) {
                // Auto-dismiss after delay
                handler.postDelayed({ hideCurrentOverlay() }, OVERLAY_DURATION)
            }
            override fun onAnimationCancel(animation: Animator) {}
            override fun onAnimationRepeat(animation: Animator) {}
        })
        
        animatorSet.start()
    }

    /**
     * Add content to expanded Dynamic Island
     */
    private fun addExpandedContent(container: FrameLayout, type: String, title: String, content: String) {
        val contentLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dpToPx(16), dpToPx(8), dpToPx(16), dpToPx(8))
        }
        
        // Title text
        val titleView = TextView(this).apply {
            text = title
            setTextColor(textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            gravity = Gravity.CENTER
        }
        
        // Content text
        val contentView = TextView(this).apply {
            text = content
            setTextColor(manipulateColor(textColor, 0.8f))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
            maxLines = 2
        }
        
        contentLayout.addView(titleView)
        contentLayout.addView(contentView)
        
        container.addView(contentLayout, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
            Gravity.CENTER
        ))
    }

    /**
     * Hide current overlay with animation
     */
    fun hideCurrentOverlay() {
        currentOverlayView?.let { view ->
            try {
                windowManager.removeView(view)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to remove overlay view", e)
            }
            currentOverlayView = null
            currentState = IslandState.CLOSED
        }
    }

    /**
     * Utility functions
     */
    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    private fun manipulateColor(color: Int, factor: Float): Int {
        val r = (Color.red(color) * factor).coerceIn(0f, 255f).toInt()
        val g = (Color.green(color) * factor).coerceIn(0f, 255f).toInt()
        val b = (Color.blue(color) * factor).coerceIn(0f, 255f).toInt()
        return Color.rgb(r, g, b)
    }
}